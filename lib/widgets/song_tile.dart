import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../models/song_model.dart';
import '../theme/app_theme.dart';
import '../widgets/artwork_widget.dart';

class SongTile extends StatelessWidget {
  final AppSong song;
  final int index;
  final VoidCallback? onTap;

  const SongTile({
    super.key,
    required this.song,
    required this.index,
    this.onTap,
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
            color: isCurrentSong
                ? AppTheme.primary.withOpacity(0.15)
                : AppTheme.surface,
            border: Border.all(
              color: isCurrentSong
                  ? AppTheme.primary.withOpacity(0.4)
                  : Colors.transparent,
              width: 1,
            ),
            boxShadow: isCurrentSong
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.15),
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
            title: Text(
              song.title,
              style: TextStyle(
                color: isCurrentSong ? AppTheme.primary : AppTheme.onSurface,
                fontWeight:
                    isCurrentSong ? FontWeight.w600 : FontWeight.w500,
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
            trailing: Text(
              song.durationFormatted,
              style: TextStyle(
                color: isCurrentSong
                    ? AppTheme.primary
                    : AppTheme.onSurfaceMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: onTap ?? () => provider.playSong(song, index),
          ),
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
