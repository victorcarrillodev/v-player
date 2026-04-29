
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';
import 'package:audio_waveforms/audio_waveforms.dart';

enum RepeatMode { off, one, all }

class MusicProvider extends ChangeNotifier {
  static const _channel = MethodChannel('com.example.v_player/media');

  final AudioPlayer _audioPlayer = AudioPlayer();

  List<AppSong> _songs = [];
  List<AppSong> _filteredSongs = [];
  List<AppSong> _currentQueue = [];
  List<AppPlaylist> _playlists = [];
  List<int> _history = [];
  Map<String, int> _playCounts = {};
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
  final List<int> _shuffledIndices = [];
  String _searchQuery = '';

  // Cache for artwork and waveforms
  final Map<int, Uint8List?> _artworkCache = {};
  final Map<int, List<double>> _waveforms = {};

  List<AppSong> get songs => _searchQuery.isEmpty ? _songs : _filteredSongs;
  List<AppSong> get currentQueue => _currentQueue.isEmpty ? songs : _currentQueue;
  List<AppPlaylist> get playlists => _playlists;
  Map<int, List<double>> get waveforms => _waveforms;

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

  MusicProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    await _loadStats();
    await _loadPlaylists();
    await _requestPermissions();
    if (_hasPermission) {
      await loadSongs();
      _currentQueue = _songs; // Default queue
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
    if (!force && _songs.isNotEmpty) {
      return;
    }
    
    _isLoading = true;
    notifyListeners();

    try {
      final List<dynamic> result =
          await _channel.invokeMethod('querySongs') as List<dynamic>;

      _songs = result.map((raw) {
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
    } catch (e) {
      debugPrint('Error loading songs: $e');
    }

    _isLoading = false;
    notifyListeners();
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



      if (queueChanged || _audioPlayer.audioSource == null) {
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
}
