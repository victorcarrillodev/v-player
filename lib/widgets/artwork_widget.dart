import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../models/song_model.dart';
import '../theme/app_theme.dart';

class ArtworkWidget extends StatelessWidget {
  final AppSong? song;
  final double size;
  final double borderRadius;
  final bool showShadow;
  final bool isPlaying;

  const ArtworkWidget({
    super.key,
    this.song,
    this.size = 200,
    this.borderRadius = 20,
    this.showShadow = false,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    if (song == null) return _buildContent(null, null);

    final provider = context.read<MusicProvider>();

    return FutureBuilder<Uint8List?>(
      future: provider.getArtwork(song!.id),
      builder: (context, snap) {
        return _buildContent(snap.data, snap.connectionState);
      },
    );
  }

  Widget _buildContent(Uint8List? data, ConnectionState? state) {
    final hasArt = data != null && data.isNotEmpty;

    final inner = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: hasArt
          ? Image.memory(
              data,
              width: size,
              height: size,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            )
          : _buildPlaceholder(),
    );

    if (showShadow) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: inner,
      );
    }

    return SizedBox(width: size, height: size, child: inner);
  }

  Widget _buildPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1E35), Color(0xFF2A1A4A)],
        ),
      ),
      child: Icon(
        Icons.music_note_rounded,
        size: size * 0.4,
        color: AppTheme.primary.withValues(alpha: 0.6),
      ),
    );
  }
}
