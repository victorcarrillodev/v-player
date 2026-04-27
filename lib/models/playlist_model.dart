
class AppPlaylist {
  final String id;
  String name;
  List<int> songIds;

  AppPlaylist({
    required this.id,
    required this.name,
    required this.songIds,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'songIds': songIds,
      };

  factory AppPlaylist.fromJson(Map<String, dynamic> json) {
    return AppPlaylist(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Playlist',
      songIds: List<int>.from(json['songIds'] ?? []),
    );
  }
}
