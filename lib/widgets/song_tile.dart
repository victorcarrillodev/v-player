
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../models/song_model.dart';
import '../theme/app_theme.dart';
import '../widgets/artwork_widget.dart';
import '../widgets/gradient_mask.dart';

class SongTile extends StatelessWidget {
  final AppSong song;
  final int index;
  final VoidCallback? onTap;
  final Widget? trailingAction;

  const SongTile({
    super.key,
    required this.song,
    required this.index,
    this.onTap,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, _) {
        final isCurrentSong = provider.currentSong?.id == song.id;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isCurrentSong ? null : context.appColors.surface,
            gradient: isCurrentSong
                ? LinearGradient(
                    colors: [
                      context.appColors.primary.withValues(alpha: 0.15),
                      context.appColors.accent.withValues(alpha: 0.15)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            border: Border.all(
              color: isCurrentSong
                  ? context.appColors.primary.withValues(alpha: 0.4)
                  : Colors.transparent,
              width: 1,
            ),
            boxShadow: isCurrentSong
                ? [
                    BoxShadow(
                      color: context.appColors.primary.withValues(alpha: 0.15),
                      blurRadius: 12,
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Stack(
              alignment: Alignment.center,
              children: [
                ArtworkWidget(
                  song: song,
                  size: 52,
                  borderRadius: 10,
                  showShadow: false,
                ),
                if (isCurrentSong && provider.isPlaying)
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.black45,
                    ),
                    child: const _MiniEqualizer(),
                  ),
              ],
            ),
            title: isCurrentSong 
              ? GradientMask(
                  child: Text(
                    song.title,
                    style: const TextStyle(
                      color: Colors.white, // GradientMask needs white base color to correctly apply shader
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : Text(
                  song.title,
                  style: TextStyle(
                    color: context.appColors.onSurface,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            subtitle: Text(
              '${song.artist} • ${song.album}',
              style: TextStyle(
                color: context.appColors.onSurfaceMuted,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: trailingAction ?? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                isCurrentSong
                    ? GradientMask(
                        child: Text(
                          song.durationFormatted,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : Text(
                        song.durationFormatted,
                        style: TextStyle(
                          color: context.appColors.onSurfaceMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.white54, size: 20),
                  onPressed: () => _showSongOptions(context, provider, song),
                ),
              ],
            ),
            onTap: onTap ?? () => provider.playSong(song, index),
          ),
        );
      },
    );
  }

  void _showSongOptions(BuildContext context, MusicProvider provider, AppSong song) {
    final isFav = provider.isFavorite(song.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ArtworkWidget(song: song, size: 48, borderRadius: 8),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(song.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(song.artist, style: const TextStyle(color: Colors.white54, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              ListTile(
                leading: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isFav ? context.appColors.primary : Colors.white),
                title: Text(isFav ? 'Quitar de favoritos' : 'Marcar como favorito', style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  provider.toggleFavorite(song.id);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isFav ? 'Quitado de favoritos' : 'Añadido a favoritos')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add_rounded, color: Colors.white),
                title: const Text('Agregar a una lista', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showAddToPlaylistDialog(context, provider, song);
                },
              ),
              ListTile(
                leading: const Icon(Icons.queue_music_rounded, color: Colors.white),
                title: const Text('Reproducir siguiente', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  provider.queueNext(song);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Añadido para reproducir siguiente')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                title: const Text('Eliminar del dispositivo', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmDialog(context, provider, song);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, MusicProvider provider, AppSong song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Añadir a playlist', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const Divider(color: Colors.white24, height: 1),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(gradient: context.appColors.primaryGradient, shape: BoxShape.circle),
                    child: const Icon(Icons.add_rounded, color: Colors.white),
                  ),
                  title: const Text('Nueva Playlist', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _showCreateAndAddDialog(context, provider, song);
                  },
                ),
                ...provider.playlists.where((p) => p.id != 'favorites' && p.id != 'history' && p.id != 'latest' && p.id != 'most_played').map((p) => ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: context.appColors.surfaceVariant, shape: BoxShape.circle),
                    child: const Icon(Icons.queue_music_rounded, color: Colors.white54),
                  ),
                  title: Text(p.name, style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    provider.addSongToPlaylist(p.id, song.id);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Añadida a ${p.name}')));
                  },
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, MusicProvider provider, AppSong song) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: context.appColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Eliminar canción', style: TextStyle(color: Colors.white)),
          content: Text('¿Estás seguro de que deseas eliminar "${song.title}" del dispositivo? Esta acción no se puede deshacer.', style: const TextStyle(color: Colors.white54)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
            ),
            Container(
              decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(100)),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await provider.deleteSong(song);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Canción eliminada'),
                        behavior: SnackBarBehavior.floating,
                        margin: EdgeInsets.only(bottom: 95, left: 16, right: 16),
                      ));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.only(bottom: 95, left: 16, right: 16),
                        duration: const Duration(seconds: 4),
                      ));
                    }
                  }
                },
                child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCreateAndAddDialog(BuildContext context, MusicProvider provider, AppSong song) {
    String folderName = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: context.appColors.surface,
          title: const Text('Crear y añadir', style: TextStyle(color: Colors.white)),
          content: TextField(
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Nombre de la nueva playlist',
              hintStyle: const TextStyle(color: Colors.white54),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: context.appColors.primary)),
            ),
            onChanged: (val) => folderName = val,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
            ),
            Container(
              decoration: BoxDecoration(gradient: context.appColors.primaryGradient, borderRadius: BorderRadius.circular(100)),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                onPressed: () {
                  if (folderName.trim().isNotEmpty) {
                    final newId = provider.createPlaylist(folderName.trim());
                    provider.addSongToPlaylist(newId, song.id);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Añadida a ${folderName.trim()}')),
                    );
                  }
                },
                child: const Text('Crear', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MiniEqualizer extends StatefulWidget {
  const _MiniEqualizer();

  @override
  State<_MiniEqualizer> createState() => _MiniEqualizerState();
}

class _MiniEqualizerState extends State<_MiniEqualizer>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      final c = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + i * 100),
      );
      c.repeat(reverse: true);
      return c;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controllers[i],
          builder: (_, __) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            width: 4,
            height: 4 + _controllers[i].value * 18,
            decoration: BoxDecoration(
              color: context.appColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
