import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../models/playlist_model.dart';
import '../models/song_model.dart';
import '../theme/app_theme.dart';
import '../widgets/song_tile.dart';
import '../widgets/gradient_mask.dart';

class PlaylistScreen extends StatelessWidget {
  final AppPlaylist playlist;

  const PlaylistScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, _) {
        final List<AppSong> playlistSongs = playlist.songIds
            .map((id) => provider.songs.cast<AppSong?>().firstWhere((s) => s?.id == id, orElse: () => null))
            .where((s) => s != null)
            .cast<AppSong>()
            .toList();

        final bool isCustomPlaylist = int.tryParse(playlist.id) != null;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: Text(playlist.name),
            actions: [
              if (isCustomPlaylist)
                IconButton(
                  icon: const GradientMask(child: Icon(Icons.add_rounded)),
                  onPressed: () => _showAddSongsDialog(context, provider, playlist),
                ),
              IconButton(
                icon: const GradientMask(child: Icon(Icons.play_arrow_rounded)),
                onPressed: () {
                  if (playlistSongs.isNotEmpty) {
                    provider.playPlaylist(playlist);
                  }
                },
              ),
            ],
          ),
          body: playlistSongs.isEmpty
              ? const Center(
                  child: Text(
                    'No hay canciones en esta playlist',
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: playlistSongs.length,
                  itemBuilder: (context, index) {
                    final song = playlistSongs[index];
                    return SongTile(
                      song: song,
                      index: index,
                      onTap: () {
                        provider.playSong(song, index, queueContext: playlistSongs);
                      },
                      trailingAction: isCustomPlaylist ? PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
                        color: AppTheme.surfaceVariant,
                        onSelected: (value) {
                          if (value == 'remove') {
                            provider.removeSongFromPlaylist(playlist.id, song.id);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'remove',
                            child: Text('Eliminar de la playlist', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ) : null,
                    );
                  },
                ),
        );
      },
    );
  }

  void _showAddSongsDialog(BuildContext context, MusicProvider provider, AppPlaylist currentPlaylist) {
    // Keep track of changes temporarily
    final Set<int> selectedSongs = Set<int>.from(currentPlaylist.songIds);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              title: const Text('Agregar canciones', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                height: MediaQuery.of(context).size.height * 0.6,
                child: ListView.builder(
                  itemCount: provider.songs.length,
                  itemBuilder: (context, index) {
                    final song = provider.songs[index];
                    final isSelected = selectedSongs.contains(song.id);
                    return CheckboxListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                      title: Text(song.title, style: const TextStyle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(song.artist, style: const TextStyle(color: Colors.white54), maxLines: 1, overflow: TextOverflow.ellipsis),
                      value: isSelected,
                      activeColor: AppTheme.primary,
                      checkColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            selectedSongs.add(song.id);
                          } else {
                            selectedSongs.remove(song.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
                ),
                Container(
                  decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(100)),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                    onPressed: () {
                      // Apply changes
                      for (var song in provider.songs) {
                        final wasInPlaylist = currentPlaylist.songIds.contains(song.id);
                        final shouldBeInPlaylist = selectedSongs.contains(song.id);
                        if (shouldBeInPlaylist && !wasInPlaylist) {
                          provider.addSongToPlaylist(currentPlaylist.id, song.id);
                        } else if (!shouldBeInPlaylist && wasInPlaylist) {
                          provider.removeSongFromPlaylist(currentPlaylist.id, song.id);
                        }
                      }
                      Navigator.pop(context);
                    },
                    child: const Text('Guardar', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
