import 'dart:async';

import 'dart:math';
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
                child: AudioVisualizerAura(artSize: artSize),
              ),

              // 3. Main content
              SafeArea(
                child: Column(
                  children: [
                    // Top Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
                            onPressed: () => Navigator.pop(context),
                          ),
                          IconButton(
                            icon: const Icon(Icons.queue_music_rounded, color: Colors.white, size: 28),
                            onPressed: () => _showQueueModal(context, provider),
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
                          IconButton(
                            icon: Icon(
                              song != null && provider.isFavorite(song.id) 
                                ? Icons.favorite_rounded 
                                : Icons.favorite_border_rounded,
                              color: song != null && provider.isFavorite(song.id)
                                ? const Color(0xFFFF5722)
                                : const Color(0xFF6E7287),
                            ),
                            iconSize: 28,
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              if (song != null) provider.toggleFavorite(song.id);
                            },
                          ),
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

  void _showQueueModal(BuildContext context, MusicProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2130),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Lista de reproducción actual',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.currentQueue.length,
                  itemBuilder: (context, index) {
                    final s = provider.currentQueue[index];
                    final isPlaying = provider.currentSong?.id == s.id;
                    return ListTile(
                      leading: isPlaying 
                          ? const Icon(Icons.volume_up_rounded, color: Color(0xFFFF5722))
                          : Padding(
                              padding: const EdgeInsets.only(left: 8.0, top: 4),
                              child: Text('${index + 1}', style: const TextStyle(color: Colors.white54, fontSize: 16)),
                            ),
                      title: Text(s.title, style: TextStyle(color: isPlaying ? const Color(0xFFFF5722) : Colors.white, fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal)),
                      subtitle: Text(s.artist, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      onTap: () {
                        provider.playSong(s, index, queueContext: provider.currentQueue);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AudioVisualizerAura extends StatefulWidget {
  final double artSize;
  const AudioVisualizerAura({super.key, required this.artSize});

  @override
  State<AudioVisualizerAura> createState() => _AudioVisualizerAuraState();
}

class _AudioVisualizerAuraState extends State<AudioVisualizerAura> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  
  // Simulated rhythm variables
  late AnimationController _pulseController;
  double _currentAmplitude = 0.1;
  double _targetAmplitude = 0.1;
  Timer? _rhythmTimer;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat();

    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _pulseController.addListener(() {
      setState(() {});
    });

    _rhythmTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      final provider = context.read<MusicProvider>();
      if (provider.isPlaying) {
        _currentAmplitude = _currentAmplitude + (_targetAmplitude - _currentAmplitude) * _pulseController.value;
        _targetAmplitude = 1.0 + Random().nextDouble() * 0.05; // 6% random pulse
        _pulseController.forward(from: 0.0);
      } else {
        if (_targetAmplitude != 1.0 || _currentAmplitude != 1.0) {
          _currentAmplitude = _currentAmplitude + (_targetAmplitude - _currentAmplitude) * _pulseController.value;
          _targetAmplitude = 1.0;
          _pulseController.forward(from: 0.0);
        }
      }
    });
  }

  @override
  void dispose() {
    _rhythmTimer?.cancel();
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, _) {
        final rhythmScale = _currentAmplitude + (_targetAmplitude - _currentAmplitude) * Curves.easeOut.transform(_pulseController.value);

        return AnimatedBuilder(
          animation: _rotationController,
          builder: (context, child) {
            final v = _rotationController.value;
            return SizedBox(
              width: widget.artSize,
              height: widget.artSize,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                scale: provider.isPlaying ? 1.0 : 0.8, // Shrinks when paused
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 800),
                  opacity: provider.isPlaying ? 1.0 : 0.0, // Fades out when paused
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                       // Capa 1: Morphing Blob (Cyan/Blue)
                       _buildBlob(
                         color: const Color(0x4D00BCD4),
                         scale: 1.08 * rhythmScale, // Rotates forward
                         rotation: v * 2 * pi, 
                         radius: BorderRadius.only(
                           topLeft: Radius.circular(widget.artSize * (0.47 + 0.05 * sin(v * 2 * pi))),
                           topRight: Radius.circular(widget.artSize * (0.47 + 0.05 * cos(v * 2 * pi + pi/4))),
                           bottomLeft: Radius.circular(widget.artSize * (0.47 + 0.05 * cos(v * 2 * pi - pi/4))),
                           bottomRight: Radius.circular(widget.artSize * (0.47 - 0.05 * sin(v * 2 * pi))),
                         ),
                       ),
                       // Capa 2: Morphing Blob (Purple)
                       _buildBlob(
                         color: const Color(0x66E040FB),
                         scale: 1.05 * rhythmScale, // Rotates backward, faster
                         rotation: -(v * 2 * pi * 1.5), 
                         radius: BorderRadius.only(
                           topLeft: Radius.circular(widget.artSize * (0.48 - 0.04 * cos(v * 2 * pi))),
                           topRight: Radius.circular(widget.artSize * (0.48 + 0.04 * sin(v * 2 * pi))),
                           bottomLeft: Radius.circular(widget.artSize * (0.48 + 0.04 * cos(v * 2 * pi))),
                           bottomRight: Radius.circular(widget.artSize * (0.48 - 0.04 * sin(v * 2 * pi))),
                         ),
                       ),
                       // Capa 3: Morphing Blob (Orange Accent)
                       _buildBlob(
                         color: const Color(0x80FFAB40),
                         scale: 1.02 * rhythmScale, // Rotates forward, slower
                         rotation: v * 2 * pi * 0.8, 
                         radius: BorderRadius.only(
                           topLeft: Radius.circular(widget.artSize * (0.49 + 0.03 * sin(v * 2 * pi))),
                           topRight: Radius.circular(widget.artSize * (0.49 + 0.03 * cos(v * 2 * pi))),
                           bottomLeft: Radius.circular(widget.artSize * (0.49 - 0.03 * cos(v * 2 * pi))),
                           bottomRight: Radius.circular(widget.artSize * (0.49 - 0.03 * sin(v * 2 * pi))),
                         ),
                       ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBlob({
    required Color color,
    required double scale,
    required double rotation,
    required BorderRadius radius,
  }) {
    return Transform.scale(
      scale: scale,
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          width: widget.artSize,
          height: widget.artSize,
          decoration: BoxDecoration(
            color: color,
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
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
            overlayColor: Colors.white.withValues(alpha: 0.2),
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
