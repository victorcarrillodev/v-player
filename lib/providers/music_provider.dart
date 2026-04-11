
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';

enum RepeatMode { off, one, all }

class MusicProvider extends ChangeNotifier {
  static const _channel = MethodChannel('com.example.v_player/media');

  final AudioPlayer _audioPlayer = AudioPlayer();

  List<AppSong> _songs = [];
  List<AppSong> _filteredSongs = [];
  List<AppSong> _currentQueue = [];
  List<AppPlaylist> _playlists = [];
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
  List<int> _shuffledIndices = [];
  String _searchQuery = '';

  // Cache for artwork
  final Map<int, Uint8List?> _artworkCache = {};

  List<AppSong> get songs => _searchQuery.isEmpty ? _songs : _filteredSongs;
  List<AppSong> get currentQueue => _currentQueue.isEmpty ? songs : _currentQueue;
  List<AppPlaylist> get playlists => _playlists;
  
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
  Duration get totalDuration => _totalDuration;
  RepeatMode get repeatMode => _repeatMode;
  bool get isShuffling => _isShuffling;
  Color get dominantColor => _dominantColor;
  Color get accentColor => _accentColor;

  MusicProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    await _loadPlaylists();
    await _requestPermissions();
    if (_hasPermission) {
      await loadSongs();
      _currentQueue = _songs; // Default queue
    }

    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      if (state.processingState == ProcessingState.completed) {
        _onSongCompleted();
      }
      notifyListeners();
    });

    _audioPlayer.positionStream.listen((pos) {
      _currentPosition = pos;
      notifyListeners();
    });

    _audioPlayer.durationStream.listen((dur) {
      if (dur != null) {
        _totalDuration = dur;
        notifyListeners();
      }
    });

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _requestPermissions() async {
    PermissionStatus audioStatus = await Permission.audio.request();
    PermissionStatus storageStatus = await Permission.storage.request();
    _hasPermission = audioStatus.isGranted || storageStatus.isGranted;
    notifyListeners();
  }

  Future<void> loadSongs() async {
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

  void createPlaylist(String name) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _playlists.add(AppPlaylist(id: id, name: name, songIds: []));
    _savePlaylists();
  }

  void addSongToPlaylist(String playlistId, int songId) {
    final playlist = _playlists.firstWhere((p) => p.id == playlistId);
    if (!playlist.songIds.contains(songId)) {
      playlist.songIds.add(songId);
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
      if (queueContext != null) {
         _currentQueue = queueContext;
      } else if (_currentQueue.isEmpty && _songs.isNotEmpty) {
         _currentQueue = _songs;
      }

      _currentSong = song;
      _currentIndex = index;
      _isLoading = true;
      notifyListeners();

      if (song.uri != null) {
        await _audioPlayer.setAudioSource(
          AudioSource.uri(Uri.parse(song.uri!)),
        );
        await _audioPlayer.play();
      }
      _isLoading = false;
      notifyListeners();

      _updateThemeColors(song);
    } catch (e) {
      debugPrint('Error playing song: $e');
      _isLoading = false;
      notifyListeners();
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
    final list = currentQueue;
    if (list.isEmpty) return;
    int nextIndex;
    if (_isShuffling && _shuffledIndices.isNotEmpty) {
      final currentShufflePos = _shuffledIndices.indexOf(_currentIndex);
      final nextShufflePos = (currentShufflePos + 1) % _shuffledIndices.length;
      nextIndex = _shuffledIndices[nextShufflePos];
    } else {
      nextIndex = (_currentIndex + 1) % list.length;
    }
    await playSong(list[nextIndex], nextIndex);
  }

  Future<void> playPrevious() async {
    final list = currentQueue;
    if (list.isEmpty) return;
    if (_currentPosition.inSeconds > 3) {
      await _audioPlayer.seek(Duration.zero);
      return;
    }
    int prevIndex;
    if (_isShuffling && _shuffledIndices.isNotEmpty) {
      final currentShufflePos = _shuffledIndices.indexOf(_currentIndex);
      final prevShufflePos =
          (currentShufflePos - 1 + _shuffledIndices.length) %
              _shuffledIndices.length;
      prevIndex = _shuffledIndices[prevShufflePos];
    } else {
      prevIndex = (_currentIndex - 1 + list.length) % list.length;
    }
    await playSong(list[prevIndex], prevIndex);
  }

  void _onSongCompleted() {
    switch (_repeatMode) {
      case RepeatMode.one:
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.play();
        break;
      case RepeatMode.all:
        playNext();
        break;
      case RepeatMode.off:
        if (_currentIndex < currentQueue.length - 1) {
          playNext();
        }
        break;
    }
  }

  void toggleRepeat() {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        break;
    }
    notifyListeners();
  }

  /// Plays a shuffled list of songs starting from index 0.
  Future<void> playShuffledQueue(List<AppSong> shuffled) async {
    if (shuffled.isEmpty) return;
    _isShuffling = true;
    _shuffledIndices = List.generate(shuffled.length, (i) => i);
    _currentQueue = shuffled;
    notifyListeners();
    await playSong(shuffled[0], 0);
  }

  void toggleShuffle() {
    _isShuffling = !_isShuffling;
    if (_isShuffling) {
      _shuffledIndices = List.generate(currentQueue.length, (i) => i)..shuffle();
    }
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

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
