import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../widgets/artwork_widget.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, _) {
        final song = provider.currentSong;
        final w = MediaQuery.of(context).size.width;
        final artSize = w * 0.65; // ~65% of screen width

        return Scaffold(
          backgroundColor: const Color(0xFF10121A), // Dark background matching the image
          body: Stack(
            children: [
              // 1. The top orange pull-down banner
              Positioned(
                top: 0,
                left: w / 2 - artSize / 2,
                child: Container(
                  width: artSize,
                  height: MediaQuery.of(context).size.height * 0.45, // Goes down to center
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFF5722), Color(0xFFE44C00)],
                    ),
                  ),
                ),
              ),

              // 2. The glowing rings/aura behind the album
              Positioned(
                top: MediaQuery.of(context).size.height * 0.45 - artSize / 2,
                left: w / 2 - artSize / 2,
                child: _buildGlowingAura(artSize),
              ),

              // 3. Main content
              SafeArea(
                child: Column(
                  children: [
                    // Top Bar (invisible or back button)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    // Space to align album art
                    SizedBox(height: MediaQuery.of(context).size.height * 0.45 - artSize / 2 - 100), // approx

                    // Circular Album Art with orange border to blend
                    Container(
                      width: artSize,
                      height: artSize,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE44C00), // matches the ending gradient color
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4), // inner orange border
                      child: ClipOval(
                        child: ArtworkWidget(
                          song: song,
                          size: artSize - 8,
                          borderRadius: 0,
                          showShadow: false,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Song Info
                    Text(
                      song?.title ?? 'Blinding Lights',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      song?.artist ?? 'The Weekend',
                      style: const TextStyle(
                        color: Color(0xFF8E92A3),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 36),

                    // Top Action Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Row(
                        children: [
                          const Icon(Icons.volume_up_outlined, color: Color(0xFF6E7287), size: 24),
                          const Spacer(),
                          GestureDetector(
                            onTap: provider.toggleRepeat,
                            child: Icon(
                              provider.repeatMode == RepeatMode.one
                                  ? Icons.repeat_one_rounded
                                  : Icons.repeat_rounded,
                              color: provider.repeatMode != RepeatMode.off 
                                  ? Colors.white 
                                  : const Color(0xFF6E7287),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 24),
                          GestureDetector(
                            onTap: provider.toggleShuffle,
                            child: Icon(
                              Icons.shuffle_rounded,
                              color: provider.isShuffling 
                                  ? Colors.white 
                                  : const Color(0xFF6E7287),
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Progress Bar
                    _ProgressBar(provider: provider),

                    const SizedBox(height: 30),

                    // Bottom Player Controls
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.skip_previous_outlined, color: Colors.white),
                            iconSize: 36,
                            onPressed: provider.playPrevious,
                          ),
                          IconButton(
                            icon: Icon(
                              provider.isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                            ),
                            iconSize: 42,
                            onPressed: provider.togglePlay,
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next_outlined, color: Colors.white),
                            iconSize: 36,
                            onPressed: provider.playNext,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Creates the neon overlapping rings
  Widget _buildGlowingAura(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Blue/Cyan wave
          Positioned(
            left: -20, top: 10,
            child: _GlowRing(size: size + 20, color: Colors.cyanAccent, thickness: 3, rotation: 0.1),
          ),
          // Purple wave
          Positioned(
            right: -25, top: 30,
            child: _GlowRing(size: size + 30, color: Colors.purpleAccent, thickness: 4, rotation: -0.2),
          ),
          // Glowing Green wave
          Positioned(
            bottom: -15, left: -10,
            child: _GlowRing(size: size + 15, color: Colors.greenAccent, thickness: 2, rotation: 0.5),
          ),
          // Light blue wave
          Positioned(
            top: -5, right: -15,
            child: _GlowRing(size: size + 10, color: Colors.lightBlueAccent, thickness: 2, rotation: -0.8),
          ),
        ],
      ),
    );
  }
}

class _GlowRing extends StatelessWidget {
  final double size;
  final Color color;
  final double thickness;
  final double rotation;

  const _GlowRing({required this.size, required this.color, required this.thickness, required this.rotation});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.6), width: thickness),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final MusicProvider provider;

  const _ProgressBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final totalMs = provider.totalDuration.inMilliseconds;
    final currentMs = provider.currentPosition.inMilliseconds.clamp(0, totalMs);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _format(provider.currentPosition),
                style: const TextStyle(
                  color: Color(0xFF6E7287),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _format(provider.totalDuration),
                style: const TextStyle(
                  color: Color(0xFF6E7287),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: Colors.white,
            inactiveTrackColor: const Color(0xFF2C3040),
            thumbColor: Colors.white,
            overlayColor: Colors.white.withOpacity(0.2),
          ),
          child: Slider(
            value: (totalMs > 0 ? currentMs / totalMs : 0).toDouble(),
            onChanged: (value) {
              final position = Duration(
                milliseconds: (value * totalMs).toInt(),
              );
              provider.seekTo(position);
            },
          ),
        ),
      ],
    );
  }

  String _format(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
