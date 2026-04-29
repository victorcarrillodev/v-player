class AppSong {
  final int id;
  final String title;
  final String artist;
  final String album;
  final String? uri;
  final String? data; // Physical file path
  final int duration;
  final int albumId;

  AppSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    this.uri,
    this.data,
    required this.duration,
    required this.albumId,
  });

  String get durationFormatted {
    final minutes = (duration ~/ 1000) ~/ 60;
    final seconds = (duration ~/ 1000) % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
