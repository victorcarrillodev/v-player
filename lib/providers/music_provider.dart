import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';
import 'package:audio_waveforms/audio_waveforms.dart';

enum RepeatMode { off, one, all }

class MusicProvider extends ChangeNotifier {
  static const _channel = MethodChannel('com.example.v_player/media');

  final AndroidEqualizer _equalizer = AndroidEqualizer();
  final AndroidLoudnessEnhancer _loudnessEnhancer = AndroidLoudnessEnhancer();
  late final AudioPlayer _audioPlayer;

  List<AppSong> _allSongs = [];
  List<AppSong> _songs = [];
  List<AppSong> _filteredSongs = [];
  List<AppSong> _currentQueue = [];
  List<AppPlaylist> _playlists = [];
  List<int> _history = [];
  Map<String, int> _playCounts = {};
  List<String> _ignoredFolders = [];
  AppSong? _currentSong;
  int _currentIndex = -1;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _hasPermission = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  RepeatMode _repeatMode = RepeatMode.off;
  bool _isShuffling = false;
  Color _dominantColor = const Color(0xFF6C63FF);
  Color _accentColor = const Color(0xFF03DAC6);
  String _searchQuery = '';
  bool _isDummySource = false;

  // Cache for artwork and waveforms
  final Map<int, Uint8List?> _artworkCache = {};
  final Map<int, List<double>> _waveforms = {};

  List<AppSong> get songs => _searchQuery.isEmpty ? _songs : _filteredSongs;
  List<AppSong> get allFoundSongs => _allSongs;
  List<AppSong> get currentQueue => _currentQueue.isEmpty ? songs : _currentQueue;
  List<AppPlaylist> get playlists => _playlists;
  Map<int, List<double>> get waveforms => _waveforms;
  List<String> get ignoredFolders => _ignoredFolders;

  AppPlaylist get historyPlaylist => AppPlaylist(id: 'history', name: 'Historial', songIds: _history);
  
  AppPlaylist get mostPlayedPlaylist {
    final sorted = _playCounts.entries.toList()..sort((a,b) => b.value.compareTo(a.value));
    final ids = sorted.map((e) => int.parse(e.key)).toList();
    return AppPlaylist(id: 'most_played', name: 'Más Reproducido', songIds: ids);
  }

  AppPlaylist get latestAddedPlaylist {
    final latest = List<AppSong>.from(_songs)..sort((a,b) => b.id.compareTo(a.id));
    final ids = latest.map((e) => e.id).toList();
    return AppPlaylist(id: 'latest', name: 'Último Añadido', songIds: ids);
  }
  
  AppPlaylist get favoritesPlaylist {
    return _playlists.firstWhere(
      (p) => p.id == 'favorites',
      orElse: () => AppPlaylist(id: 'favorites', name: 'Favoritos', songIds: []),
    );
  }

  AppPlaylist getPlaylist(String id) {
    return _playlists.firstWhere((p) => p.id == id);
  }

  bool isFavorite(int songId) {
    return favoritesPlaylist.songIds.contains(songId);
  }

  AppSong? get currentSong => _currentSong;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  bool get hasPermission => _hasPermission;
  Duration get currentPosition => _currentPosition;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Duration get totalDuration => _totalDuration;
  RepeatMode get repeatMode => _repeatMode;
  Stream<int?> get audioSessionIdStream => _audioPlayer.androidAudioSessionIdStream;
  int? get audioSessionId => _audioPlayer.androidAudioSessionId;
  bool get isShuffling => _isShuffling;
  Color get dominantColor => _dominantColor;
  Color get accentColor => _accentColor;
  AndroidEqualizer get equalizer => _equalizer;
  AndroidLoudnessEnhancer get loudnessEnhancer => _loudnessEnhancer;

  MusicProvider() {
    _audioPlayer = AudioPlayer(
      audioPipeline: AudioPipeline(androidAudioEffects: [
        _equalizer,
        _loudnessEnhancer,
      ]),
    );
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    await _loadStats();
    await _loadPlaylists();
    await _loadIgnoredFolders();
    
    // Only check permissions here, don't request them yet
    bool audioGranted = await Permission.audio.isGranted;
    bool storageGranted = await Permission.storage.isGranted;
    _hasPermission = audioGranted || storageGranted;
    
    if (_hasPermission) {
      await loadSongs();
      _currentQueue = _songs; // Default queue
      
      // Initialize Android audio session immediately to wake up the Equalizer
      if (_currentQueue.isNotEmpty && Platform.isAndroid) {
        _isDummySource = true;
        try {
          await _audioPlayer.setAudioSource(
            ConcatenatingAudioSource(children: [
              AudioSource.uri(
                Uri.parse(_currentQueue.first.uri ?? ''),
                tag: MediaItem(
                  id: _currentQueue.first.id.toString(),
                  title: 'Initializing Engine',
                  artist: 'System',
                ),
              )
            ]),
          );
        } catch (_) {}
      }
    }

    // Handle audio focus changes (phone calls, other apps, etc.)
    final session = await AudioSession.instance;
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        // Another app took audio focus - pause
        switch (event.type) {
          case AudioInterruptionType.duck:
            // Lower volume temporarily
            _audioPlayer.setVolume(0.5);
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            _audioPlayer.pause();
            break;
        }
      } else {
        // We regained audio focus
        switch (event.type) {
          case AudioInterruptionType.duck:
            _audioPlayer.setVolume(1.0);
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            // Only resume if we were playing before
            if (_isPlaying) _audioPlayer.play();
            break;
        }
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _updateWidgetUI();
      notifyListeners();
    });

    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && _currentQueue.isNotEmpty && index < _currentQueue.length) {
        _currentIndex = index;
        _currentSong = _currentQueue[index];
        _history.remove(_currentSong!.id);
        _history.insert(0, _currentSong!.id);
        if (_history.length > 200) _history.removeLast();
        _playCounts[_currentSong!.id.toString()] = (_playCounts[_currentSong!.id.toString()] ?? 0) + 1;
        _saveStats();
        _updateThemeColors(_currentSong!);
        _extractWaveform(_currentSong!);
        _updateWidgetUI();
        notifyListeners();
      }
    });

    _audioPlayer.positionStream.listen((pos) {
      _currentPosition = pos;
      // Removed notifyListeners() to prevent UI freezing (massive performance gain)
    });

    _audioPlayer.durationStream.listen((dur) {
      if (dur != null) {
        _totalDuration = dur;
        notifyListeners();
      }
    });

    // Skip broken/unreadable files automatically
    _audioPlayer.playbackEventStream.listen((_) {}, onError: (Object e, StackTrace st) {
      debugPrint('Playback error: $e');
      _audioPlayer.seekToNext();
    });

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _requestPermissions() async {
    PermissionStatus audioStatus = await Permission.audio.request();
    PermissionStatus storageStatus = await Permission.storage.request();
    // Android 13+ requires explicit notification permission for media controls
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    _hasPermission = audioStatus.isGranted || storageStatus.isGranted;
    notifyListeners();
  }

  Future<void> loadSongs({bool force = false}) async {
    if (!_hasPermission) {
      await _requestPermissions();
    }
    
    if (!_hasPermission) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    if (!force && _songs.isNotEmpty) {
      return;
    }
    
    _isLoading = true;
    notifyListeners();

    try {
      final List<dynamic> result =
          await _channel.invokeMethod('querySongs') as List<dynamic>;

      _allSongs = result.map((raw) {
        final map = Map<String, dynamic>.from(raw as Map);
        return AppSong(
          id: map['id'] as int,
          title: map['title'] as String? ?? 'Unknown',
          artist: map['artist'] as String? ?? 'Unknown Artist',
          album: map['album'] as String? ?? 'Unknown Album',
          uri: map['uri'] as String?,
          data: map['data'] as String?,
          duration: map['duration'] as int? ?? 0,
          albumId: map['albumId'] as int? ?? 0,
        );
      }).toList();
      _applyFolderFilter();
    } catch (e) {
      debugPrint('Error loading songs: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void _applyFolderFilter() {
    if (_ignoredFolders.isEmpty) {
      _songs = List.from(_allSongs);
    } else {
      _songs = _allSongs.where((song) {
        if (song.data == null) return true; // Si no tiene ruta, no la ignoramos
        final path = song.data!;
        // Verificar si la ruta del archivo empieza con alguna de las carpetas ignoradas
        for (String folder in _ignoredFolders) {
          if (path.startsWith(folder)) return false; // Ignorada
        }
        return true;
      }).toList();
    }
    
    // Actualizar también la lista filtrada por búsqueda si hay una búsqueda activa
    if (_searchQuery.isNotEmpty) {
      search(_searchQuery);
    }
    notifyListeners();
  }

  Future<void> _loadIgnoredFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('ignored_folders') ?? '[]';
    _ignoredFolders = List<String>.from(jsonDecode(jsonStr));
  }

  Future<void> toggleIgnoredFolder(String folderPath) async {
    if (_ignoredFolders.contains(folderPath)) {
      _ignoredFolders.remove(folderPath);
    } else {
      _ignoredFolders.add(folderPath);
    }
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('ignored_folders', jsonEncode(_ignoredFolders));
    _applyFolderFilter();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final histJson = prefs.getString('history') ?? '[]';
    _history = List<int>.from(jsonDecode(histJson));
    final countsJson = prefs.getString('play_counts') ?? '{}';
    final countsMap = jsonDecode(countsJson) as Map<String, dynamic>;
    _playCounts = countsMap.map((k, v) => MapEntry(k, v as int));
  }

  Future<void> _saveStats() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('history', jsonEncode(_history));
    prefs.setString('play_counts', jsonEncode(_playCounts));
  }

  Future<void> _loadPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final String? playlistsJson = prefs.getString('playlists');
    if (playlistsJson != null) {
      final List<dynamic> decoded = jsonDecode(playlistsJson);
      _playlists = decoded.map((e) => AppPlaylist.fromJson(e)).toList();
    } else {
      _playlists = [
        AppPlaylist(id: 'favorites', name: 'Favoritos', songIds: []),
      ];
      _savePlaylists();
    }
  }

  Future<void> _savePlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_playlists.map((e) => e.toJson()).toList());
    await prefs.setString('playlists', encoded);
    notifyListeners();
  }

  void toggleFavorite(int songId) {
    AppPlaylist fav = favoritesPlaylist;
    if (!fav.songIds.contains(songId)) {
      fav.songIds.add(songId);
    } else {
      fav.songIds.remove(songId);
    }
    // Update list if newly created
    if (!_playlists.any((p) => p.id == 'favorites')) {
      _playlists.insert(0, fav);
    }
    _savePlaylists();
  }

  String createPlaylist(String name, {List<int>? initialSongs}) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _playlists.add(AppPlaylist(id: id, name: name, songIds: initialSongs != null ? List<int>.from(initialSongs) : []));
    _savePlaylists();
    return id;
  }

  void deletePlaylist(String playlistId) {
    _playlists.removeWhere((p) => p.id == playlistId);
    _savePlaylists();
  }

  void addSongToPlaylist(String playlistId, int songId) {
    final playlist = _playlists.firstWhere((p) => p.id == playlistId);
    if (!playlist.songIds.contains(songId)) {
      playlist.songIds.add(songId);
      _savePlaylists();
    }
  }

  void removeSongFromPlaylist(String playlistId, int songId) {
    final playlist = _playlists.firstWhere((p) => p.id == playlistId);
    if (playlist.songIds.contains(songId)) {
      playlist.songIds.remove(songId);
      _savePlaylists();
    }
  }

  Future<void> playPlaylist(AppPlaylist playlist, {int startIndex = 0}) async {
    final queue = playlist.songIds
        .map((id) => _songs.cast<AppSong?>().firstWhere((s) => s?.id == id, orElse: () => null))
        .where((s) => s != null)
        .cast<AppSong>()
        .toList();
        
    if (queue.isNotEmpty) {
      _currentQueue = queue;
      _isShuffling = false; 
      await playSong(queue[startIndex], startIndex);
    }
  }

  Future<void> playSong(AppSong song, int index, {List<AppSong>? queueContext}) async {
    try {
      bool queueChanged = false;
      if (queueContext != null && queueContext != _currentQueue) {
         _currentQueue = queueContext;
         queueChanged = true;
      } else if (_currentQueue.isEmpty && _songs.isNotEmpty) {
         _currentQueue = _songs;
         queueChanged = true;
      } else if (queueContext == null && !_currentQueue.contains(song)) {
         _currentQueue = _songs;
         queueChanged = true;
      }



      if (queueChanged || _audioPlayer.audioSource == null || _isDummySource) {
        _isDummySource = false;
        final audioSource = ConcatenatingAudioSource(
          children: _currentQueue.map((s) {
            // Use the standard album art content URI that Android's media notification can resolve
            final albumArtUri = Uri.parse(
              'content://media/external/audio/albumart/${s.albumId}',
            );
            return AudioSource.uri(
              Uri.parse(s.uri ?? ''),
              tag: MediaItem(
                id: s.id.toString(),
                album: s.album,
                title: s.title,
                artist: s.artist,
                duration: Duration(milliseconds: s.duration),
                artUri: albumArtUri,
                extras: {
                  'albumId': s.albumId,
                },
              ),
            );
          }).where((s) => s.uri != Uri.parse('')).toList(),
        );

        await _audioPlayer.setAudioSource(audioSource, initialIndex: index, initialPosition: Duration.zero);
      } else {
        await _audioPlayer.seek(Duration.zero, index: index);
      }

      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing song: $e');
    }
  }

  Future<void> _updateThemeColors(AppSong song) async {
    try {
      final artwork = await getArtwork(song.id);
      if (artwork != null && artwork.isNotEmpty) {
        final image = MemoryImage(artwork);
        final palette = await PaletteGenerator.fromImageProvider(image);
        _dominantColor =
            palette.dominantColor?.color ?? const Color(0xFF6C63FF);
        _accentColor =
            palette.vibrantColor?.color ?? const Color(0xFF03DAC6);
      } else {
        _dominantColor = const Color(0xFF6C63FF);
        _accentColor = const Color(0xFF03DAC6);
      }
      notifyListeners();
    } catch (_) {
      _dominantColor = const Color(0xFF6C63FF);
      _accentColor = const Color(0xFF03DAC6);
      notifyListeners();
    }
  }

  void togglePlay() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  Future<void> playNext() async {
    await _audioPlayer.seekToNext();
  }

  void queueNext(AppSong song) {
    if (_currentQueue.isEmpty) {
      _currentQueue = [song];
      playSong(song, 0);
    } else {
      final insertIndex = _currentIndex + 1;
      _currentQueue.insert(insertIndex, song);
      if (_audioPlayer.audioSource is ConcatenatingAudioSource) {
        final source = _audioPlayer.audioSource as ConcatenatingAudioSource;
        final audioSource = AudioSource.uri(
          Uri.parse(song.uri ?? ''),
          tag: MediaItem(
            id: song.id.toString(),
            album: song.album,
            title: song.title,
            artist: song.artist,
            duration: Duration(milliseconds: song.duration),
            artUri: Uri.parse('content://media/external/audio/albumart/${song.albumId}'),
            extras: {'albumId': song.albumId},
          ),
        );
        source.insert(insertIndex, audioSource);
      }
    }
    notifyListeners();
  }

  Future<void> deleteSong(AppSong song) async {
    // Intentar borrar primero usando dart:io
    bool deleted = false;
    
    if (song.data != null && song.data!.isNotEmpty) {
      final file = File(song.data!);
      if (file.existsSync()) {
        try {
          file.deleteSync();
          deleted = true;
        } catch (e) {
          // Si falla, probablemente sea Android 11+ y necesitamos manageExternalStorage
          if (await Permission.manageExternalStorage.isDenied) {
            final status = await Permission.manageExternalStorage.request();
            if (status.isGranted) {
              try {
                file.deleteSync();
                deleted = true;
              } catch (e2) {
                // If it still fails, fallback to native
              }
            }
          }
        }
      } else {
        // file doesn't exist, maybe it was already deleted natively or externally
        deleted = true; 
      }
    }

    if (!deleted) {
      // Fallback a Native ContentResolver si dart:io falla o no es accesible
      try {
        if (song.uri != null && song.uri!.isNotEmpty) {
          final result = await _channel.invokeMethod('deleteSong', {'uri': song.uri});
          if (result == true) deleted = true;
        }
      } on PlatformException catch (e) {
        if (e.code == 'SECURITY_EXCEPTION') {
          throw Exception('Permiso denegado por el sistema Android para borrar este archivo. En Android 11+, ve a Configuración y otorga el permiso de "Acceso a todos los archivos" a la app.');
        }
        throw Exception(e.message ?? 'Error desconocido al borrar');
      }
    }

    if (!deleted) {
      throw Exception('No se pudo encontrar el archivo en el almacenamiento del sistema o no hay permisos suficientes para borrarlo.');
    }

    _songs.removeWhere((s) => s.id == song.id);
    _filteredSongs.removeWhere((s) => s.id == song.id);
    for (var p in _playlists) {
      p.songIds.remove(song.id);
    }
    _savePlaylists();
    
    if (_currentQueue.contains(song)) {
       final idx = _currentQueue.indexOf(song);
       _currentQueue.removeAt(idx);
       if (_audioPlayer.audioSource is ConcatenatingAudioSource) {
          final source = _audioPlayer.audioSource as ConcatenatingAudioSource;
          if (idx < source.length) {
             source.removeAt(idx);
          }
       }
    }
    notifyListeners();
  }

  Future<void> playPrevious() async {
    if (_currentPosition.inSeconds > 3) {
      await _audioPlayer.seek(Duration.zero);
    } else {
      await _audioPlayer.seekToPrevious();
    }
  }

  void toggleRepeat() {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        _audioPlayer.setLoopMode(LoopMode.all);
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        _audioPlayer.setLoopMode(LoopMode.one);
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        _audioPlayer.setLoopMode(LoopMode.off);
        break;
    }
    notifyListeners();
  }

  Future<void> playShuffledQueue(List<AppSong> shuffled) async {
    if (shuffled.isEmpty) return;
    _currentQueue = shuffled;
    // Set audio source to the new shuffled queue natively
    await playSong(shuffled[0], 0, queueContext: shuffled);
  }

  void toggleShuffle() {
    _isShuffling = !_isShuffling;
    _audioPlayer.setShuffleModeEnabled(_isShuffling);
    notifyListeners();
  }

  void seekTo(Duration position) {
    _audioPlayer.seek(position);
  }

  void search(String query) {
    _searchQuery = query.toLowerCase();
    if (_searchQuery.isEmpty) {
      _filteredSongs = [];
    } else {
      _filteredSongs = _songs.where((s) {
        return s.title.toLowerCase().contains(_searchQuery) ||
            s.artist.toLowerCase().contains(_searchQuery) ||
            s.album.toLowerCase().contains(_searchQuery);
      }).toList();
    }
    notifyListeners();
  }

  Future<Uint8List?> getArtwork(int id) async {
    if (_artworkCache.containsKey(id)) {
      return _artworkCache[id];
    }
    try {
      final song = _songs.firstWhere((s) => s.id == id);
      final result = await _channel.invokeMethod('queryArtwork', {
        'id': id,
        'uri': song.uri,
      });
      final bytes =
          result != null ? Uint8List.fromList(List<int>.from(result as List)) : null;
      _artworkCache[id] = bytes;
      return bytes;
    } catch (e) {
      _artworkCache[id] = null;
      return null;
    }
  }

  Future<void> _extractWaveform(AppSong song) async {
    if (_waveforms.containsKey(song.id)) return;
    if (song.data == null || song.data!.isEmpty) return;

    try {
      final controller = PlayerController();
      // Calculate samples to get roughly 20-30 frames per second.
      // 1 sample every 40 milliseconds (25 fps).
      final int desiredSamples = (song.duration > 0) ? (song.duration ~/ 40) : 4096;
      
      final data = await controller.extractWaveformData(
        path: song.data!,
        noOfSamples: desiredSamples,
      );
      
      if (data.isNotEmpty) {
        // Normalize the waveform so the highest peak is exactly 1.0
        double maxAmplitude = 0.0;
        for (var amp in data) {
          if (amp.abs() > maxAmplitude) maxAmplitude = amp.abs();
        }
        
        List<double> normalizedData = data;
        if (maxAmplitude > 0.0) {
           normalizedData = data.map((amp) => (amp.abs() / maxAmplitude)).toList();
        }
        
        _waveforms[song.id] = normalizedData;
        notifyListeners();
      }
      controller.dispose();
    } catch (e) {
      debugPrint('Error extracting waveform: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _updateWidgetUI() {
    HomeWidget.saveWidgetData<String>('title', _currentSong?.title ?? 'Not playing');
    HomeWidget.saveWidgetData<String>('artist', _currentSong?.artist ?? 'Unknown Artist');
    HomeWidget.saveWidgetData<bool>('isPlaying', _isPlaying);
    HomeWidget.updateWidget(androidName: 'MusicWidgetProvider');
  }
}
