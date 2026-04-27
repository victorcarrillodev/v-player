import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';
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
            color: isCurrentSong ? null : AppTheme.surface,
            gradient: isCurrentSong
                ? LinearGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.15),
                      AppTheme.accent.withValues(alpha: 0.15)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            border: Border.all(
              color: isCurrentSong
                  ? AppTheme.primary.withValues(alpha: 0.4)
                  : Colors.transparent,
              width: 1,
            ),
            boxShadow: isCurrentSong
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.15),
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
                  style: const TextStyle(
                    color: AppTheme.onSurface,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            subtitle: Text(
              '${song.artist} • ${song.album}',
              style: const TextStyle(
                color: AppTheme.onSurfaceMuted,
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
                        style: const TextStyle(
                          color: AppTheme.onSurfaceMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                const SizedBox(width: 8),
                PopupMenuButton<AppPlaylist>(
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.white54, size: 20),
                  color: AppTheme.surfaceVariant,
                  tooltip: 'Añadir a playlist',
                  onSelected: (AppPlaylist? playlist) {
                    if (playlist == null) return;
                    if (playlist.id == 'create_new') {
                      _showCreateAndAddDialog(context, provider, song);
                      return;
                    }
                    provider.addSongToPlaylist(playlist.id, song.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Añadida a ${playlist.name}')),
                    );
                  },
                  itemBuilder: (context) {
                    final items = provider.playlists.map((p) {
                      return PopupMenuItem<AppPlaylist>(
                        value: p,
                        child: Text(p.name, style: const TextStyle(color: Colors.white)),
                      );
                    }).toList();
                    items.add(
                      PopupMenuItem<AppPlaylist>(
                        value: AppPlaylist(id: 'create_new', name: '+ Crear nueva playlist', songIds: []),
                        child: const GradientMask(child: Text('+ Crear nueva', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      ),
                    );
                    return items;
                  },
                ),
              ],
            ),
            onTap: onTap ?? () => provider.playSong(song, index),
          ),
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
          backgroundColor: AppTheme.surface,
          title: const Text('Crear y añadir', style: TextStyle(color: Colors.white)),
          content: TextField(
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Nombre de la nueva playlist',
              hintStyle: TextStyle(color: Colors.white54),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
            ),
            onChanged: (val) => folderName = val,
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
              color: AppTheme.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
