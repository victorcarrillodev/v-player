import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:provider/provider.dart';
import '../models/song_model.dart';
import '../providers/music_provider.dart';
import '../widgets/artwork_widget.dart';
import '../widgets/gradient_mask.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with TickerProviderStateMixin {
  double _dragOffsetX = 0;
  bool _isDragging = false;
  int _swipeDir = 0;
  bool _songChangedMidFlight = false;
  late AnimationController _flipController;

  // Dynamic banner color extracted from artwork
  Color _bannerColor = const Color(0xFFFF5722);
  int? _bannerSongId;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _flipController.addListener(() {
      // At the halfway point (art is edge-on) swap the song
      if (_flipController.value >= 0.5 && !_songChangedMidFlight) {
        _songChangedMidFlight = true;
        final provider = context.read<MusicProvider>();
        if (_swipeDir < 0) provider.playNext();
        else provider.playPrevious();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  Future<void> _updateBannerColor(AppSong? song) async {
    if (song == null || song.id == _bannerSongId) return;
    _bannerSongId = song.id;
    try {
      final provider = context.read<MusicProvider>();
      final bytes = await provider.getArtwork(song.id);
      if (bytes == null || bytes.isEmpty) return;
      final palette = await PaletteGenerator.fromImageProvider(
        MemoryImage(bytes),
        maximumColorCount: 16,
      );
      if (!mounted) return;
      final raw = palette.vibrantColor?.color ??
                  palette.dominantColor?.color;
      if (raw == null) return;
      // Boost saturation & value so it always looks vivid, use COMPLEMENTARY hue
      final hsv = HSVColor.fromColor(raw);
      final complementHue = (hsv.hue + 180.0) % 360.0;
      final vivid = hsv
          .withHue(complementHue)
          .withSaturation(hsv.saturation.clamp(0.60, 1.0))
          .withValue(hsv.value.clamp(0.70, 1.0))
          .toColor();
      setState(() => _bannerColor = vivid);
    } catch (_) {}
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
      Navigator.pop(context);
    }
  }

  void _handleHorizontalDragEnd(
      DragEndDetails details, MusicProvider provider) {
    if (details.primaryVelocity == null) {
      setState(() { _dragOffsetX = 0; _isDragging = false; });
      return;
    }
    if (details.primaryVelocity! < -300) {
      _swipeDir = -1;
      _songChangedMidFlight = false;
      _flipController.forward(from: 0);
    } else if (details.primaryVelocity! > 300) {
      _swipeDir = 1;
      _songChangedMidFlight = false;
      _flipController.forward(from: 0);
    }
    setState(() {
      _dragOffsetX = 0;
      _isDragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, _) {
        final song = provider.currentSong;
        final w = MediaQuery.of(context).size.width;
        final artSize = w * 0.65;

        // Trigger color extraction when song changes (async, idempotent)
        _updateBannerColor(song);

        return GestureDetector(
          // Vertical swipe — down to close
          onVerticalDragEnd: _handleVerticalDragEnd,
          // Horizontal swipe — prev / next
          onHorizontalDragUpdate: (details) {
            setState(() {
              _dragOffsetX += details.delta.dx;
              _isDragging = true;
            });
          },
          onHorizontalDragEnd: (details) =>
              _handleHorizontalDragEnd(details, provider),
          onHorizontalDragCancel: () =>
              setState(() {
                _dragOffsetX = 0;
                _isDragging = false;
              }),
          child: Scaffold(
            backgroundColor: const Color(0xFF10121A),
            body: Stack(
              clipBehavior: Clip.none,
              children: [
                // 0. Morphing blob visualizer — aligned with artwork center
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.45 - artSize * 0.65,
                  left: w / 2 - artSize * 0.65,
                  child: AudioVisualizerAura(artSize: artSize * 1.3, song: song),
                ),

                // 1. Dynamic-color top banner
                Positioned(
                  top: 0,
                  left: w / 2 - artSize / 2,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeInOut,
                    width: artSize,
                    height: MediaQuery.of(context).size.height * 0.45 + artSize / 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _bannerColor,
                          Color.lerp(_bannerColor, Colors.black, 0.18)!,
                        ],
                      ),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(artSize / 2),
                      ),
                    ),
                  ),
                ),

                // 3. Main content
                SafeArea(
                  child: Column(
                    children: [
                      // Top Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.white,
                                  size: 32),
                              onPressed: () => Navigator.pop(context),
                            ),
                            IconButton(
                              icon: const Icon(Icons.queue_music_rounded,
                                  color: Colors.white, size: 28),
                              onPressed: () =>
                                  _showQueueModal(context, provider),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.45 -
                              artSize / 2 -
                              100),

                      // Circular Album Art — flip animation on song change
                      Builder(builder: (_) {
                        final p = _flipController.value;
                        // First half: 0→π/2 (disappear), second half: π/2→0 (appear)
                        final rotY = p < 0.5 ? p * 2 * (pi / 2) : (1.0 - p) * 2 * (pi / 2);
                        // Slide in the swipe direction then back
                        final slideX = _flipController.isAnimating
                            ? _swipeDir * 55.0 * sin(p * pi)
                            : _dragOffsetX.clamp(-60.0, 60.0);
                        return Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..translate(slideX, 0.0, 0.0)
                            ..rotateY(rotY),
                          child: SizedBox(
                            width: artSize,
                            height: artSize,
                            child: Center(
                              child: ClipOval(
                                child: ArtworkWidget(
                                  song: song,
                                  size: artSize - 30,
                                  borderRadius: 0,
                                  showShadow: false,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),

                        Expanded(
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: Column(
                              children: [
                                const SizedBox(height: 36),

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

                                const SizedBox(height: 20),

                                // Top Action Row
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 32),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: song != null &&
                                                provider.isFavorite(song.id)
                                            ? const GradientMask(
                                                child: Icon(Icons.favorite_rounded,
                                                    color: Colors.white))
                                            : const Icon(
                                                Icons.favorite_border_rounded,
                                                color: Color(0xFF6E7287)),
                                        iconSize: 28,
                                        padding: EdgeInsets.zero,
                                        onPressed: () {
                                          if (song != null)
                                            provider.toggleFavorite(song.id);
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

                                const SizedBox(height: 16),

                                // Progress Bar
                                _ProgressBar(provider: provider),

                                const SizedBox(height: 20),

                                // Bottom Player Controls
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 48),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                            Icons.skip_previous_outlined,
                                            color: Colors.white),
                                        iconSize: 36,
                                        onPressed: provider.playPrevious,
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          provider.isPlaying
                                              ? Icons.pause
                                              : Icons.play_arrow,
                                          color: Colors.white,
                                        ),
                                        iconSize: 42,
                                        onPressed: provider.togglePlay,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.skip_next_outlined,
                                            color: Colors.white),
                                        iconSize: 36,
                                        onPressed: provider.playNext,
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(
                                    height: MediaQuery.of(context).padding.bottom + 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

            ],
          ),
        ),
        );
      },
    );
  }

  void _showQueueModal(BuildContext context, MusicProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2130),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Lista de reproducción actual',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
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
                          ? const GradientMask(
                              child: Icon(Icons.volume_up_rounded,
                                  color: Colors.white))
                          : Padding(
                              padding: const EdgeInsets.only(left: 8.0, top: 4),
                              child: Text('${index + 1}',
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 16)),
                            ),
                      title: isPlaying
                          ? GradientMask(
                              child: Text(s.title,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)))
                          : Text(s.title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.normal)),
                      subtitle: Text(s.artist,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                      onTap: () {
                        provider.playSong(s, index,
                            queueContext: provider.currentQueue);
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
  final AppSong? song;
  const AudioVisualizerAura({super.key, required this.artSize, this.song});

  @override
  State<AudioVisualizerAura> createState() => _AudioVisualizerAuraState();
}

class _AudioVisualizerAuraState extends State<AudioVisualizerAura>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  double _ampBass = 0.75;
  double _ampMid = 0.75;
  double _ampTreble = 0.70;
  Timer? _rhythmTimer;

  // Colors extracted from artwork (fallback to app palette)
  Color _c1 = const Color(0xFF00BCD4);
  Color _c2 = const Color(0xFFE040FB);
  Color _c3 = const Color(0xFFFFAB40);
  int? _lastSongId;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    ); // NOT .repeat() here — only starts when music plays

    // Music-reactive loop: 25fps
    // - Playing  → rotation runs + amp pulses organically
    // - Paused   → rotation stops + amp returns smoothly to 1.0
    _rhythmTimer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (!mounted) return;
      final provider = context.read<MusicProvider>();
      final isPlaying = provider.isPlaying;

      if (isPlaying) {
        if (!_rotationController.isAnimating) _rotationController.repeat();

        // Vincular la fase directamente a los ms de la canción para una "sincronización" determinista
        final ms = provider.currentPosition.inMilliseconds;
        final phase = ms / 1000.0 * pi; // Avanza PI cada segundo
        
        // Graves (Bass): Picos fuertes basados en el tiempo de la canción
        double bassPulse = pow(sin(phase * 1.8), 16).toDouble();
        if (sin(phase * 0.4) < -0.3) bassPulse *= 0.1; // Descansos periódicos
        final targetBass = 0.75 + (bassPulse * 0.55); // 0.75 (oculto) a 1.30 (muy visible)
        
        // Medios (Mids): Más constante, fluctuaciones
        double midPulse = (sin(phase * 2.8) * 0.5 + sin(phase * 1.2) * 0.5).abs();
        final targetMid = 0.75 + (midPulse * 0.35); // 0.75 a 1.10
        
        // Agudos (Treble): Picos rápidos, caóticos y de corta duración
        double treblePulse = pow(sin(phase * 6.7), 6).toDouble() * sin(phase * 11.3).abs();
        if (sin(phase * 0.8) > 0.5) treblePulse *= 0.2; 
        final targetTreble = 0.70 + (treblePulse * 0.50); // 0.70 a 1.20

        setState(() {
          _ampBass += (targetBass - _ampBass) * (targetBass > _ampBass ? 0.75 : 0.05);
          _ampMid += (targetMid - _ampMid) * (targetMid > _ampMid ? 0.80 : 0.08);
          _ampTreble += (targetTreble - _ampTreble) * (targetTreble > _ampTreble ? 0.90 : 0.12);
        });
      } else {
        if (_rotationController.isAnimating) _rotationController.stop();

        bool changed = false;
        if ((_ampBass - 0.75).abs() > 0.001) { _ampBass += (0.75 - _ampBass) * 0.08; changed = true; }
        if ((_ampMid - 0.75).abs() > 0.001) { _ampMid += (0.75 - _ampMid) * 0.08; changed = true; }
        if ((_ampTreble - 0.70).abs() > 0.001) { _ampTreble += (0.70 - _ampTreble) * 0.08; changed = true; }
        if (changed) setState(() {});
      }
    });

    _extractColors();
  }

  @override
  void didUpdateWidget(AudioVisualizerAura old) {
    super.didUpdateWidget(old);
    if (widget.song?.id != _lastSongId) _extractColors();
  }

  Future<void> _extractColors() async {
    final song = widget.song;
    if (song == null) return;
    _lastSongId = song.id;
    try {
      final provider = context.read<MusicProvider>();
      final bytes = await provider.getArtwork(song.id);
      if (bytes == null || bytes.isEmpty) return;
      final palette = await PaletteGenerator.fromImageProvider(
        MemoryImage(bytes),
        maximumColorCount: 16,
      );
      if (!mounted) return;
      // Pick up to 3 distinct colors from the palette
      final candidates = [
        palette.vibrantColor?.color,
        palette.lightVibrantColor?.color,
        palette.darkVibrantColor?.color,
        palette.mutedColor?.color,
        palette.lightMutedColor?.color,
        palette.dominantColor?.color,
      ].whereType<Color>().toList();
      setState(() {
        _c1 = candidates.isNotEmpty ? candidates[0] : _c1;
        _c2 = candidates.length > 1 ? candidates[1] : _c2;
        _c3 = candidates.length > 2 ? candidates[2] : _c3;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _rhythmTimer?.cancel();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, _) {
        return AnimatedBuilder(
          animation: _rotationController,
          builder: (context, _) {
            final v = _rotationController.value;
            final tp = 2 * pi;
            return SizedBox(
              width: widget.artSize,
              height: widget.artSize,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 600),
                opacity: provider.isPlaying ? 1.0 : 0.0,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Blob 1 (Graves): Always circular, scales strongly with bass
                    _buildBlob(
                      color: _c1.withValues(alpha: 0.70),
                      scale: _ampBass,
                      rotation: v * tp * 0.5,
                      radius: BorderRadius.circular(widget.artSize),
                    ),
                    // Blob 2 (Medios): Starts circular, stretches/morphs with mids
                    Builder(builder: (context) {
                      final defMid = (_ampMid - 0.75) * 1.5; // Deformation factor (base 0.75)
                      return _buildBlob(
                        color: _c2.withValues(alpha: 0.60),
                        scale: _ampMid,
                        rotation: -(v * tp),
                        radius: BorderRadius.only(
                          topLeft:     Radius.circular(widget.artSize * (0.5 - defMid * sin(v * tp * 2.0).abs()).clamp(0.15, 0.5)),
                          topRight:    Radius.circular(widget.artSize * (0.5 - defMid * cos(v * tp * 2.0).abs()).clamp(0.15, 0.5)),
                          bottomLeft:  Radius.circular(widget.artSize * (0.5 - defMid * cos(v * tp * 2.0 + pi / 4).abs()).clamp(0.15, 0.5)),
                          bottomRight: Radius.circular(widget.artSize * (0.5 - defMid * sin(v * tp * 2.0 + pi / 4).abs()).clamp(0.15, 0.5)),
                        ),
                      );
                    }),
                    // Blob 3 (Agudos): Starts circular, becomes highly spiky and scales with treble
                    Builder(builder: (context) {
                      final defTreble = (_ampTreble - 0.70) * 2.5; // Sharp deformation factor (base 0.70)
                      return _buildBlob(
                        color: _c3.withValues(alpha: 0.55),
                        scale: _ampTreble,
                        rotation: v * tp * 1.8,
                        radius: BorderRadius.only(
                          topLeft:     Radius.circular(widget.artSize * (0.5 - defTreble * sin(v * tp * 3.0).abs()).clamp(0.12, 0.5)),
                          topRight:    Radius.circular(widget.artSize * (0.5 - defTreble * cos(v * tp * 3.0).abs()).clamp(0.12, 0.5)),
                          bottomLeft:  Radius.circular(widget.artSize * (0.5 - defTreble * cos(v * tp * 3.0 + pi / 4).abs()).clamp(0.12, 0.5)),
                          bottomRight: Radius.circular(widget.artSize * (0.5 - defTreble * sin(v * tp * 3.0 + pi / 4).abs()).clamp(0.12, 0.5)),
                        ),
                      );
                    }),
                  ],
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
                color: color.withValues(alpha: 0.40),
                blurRadius: 22,
                spreadRadius: 5,
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

    return StreamBuilder<Duration>(
      stream: provider.positionStream,
      builder: (context, snapshot) {
        final currentPos = snapshot.data ?? provider.currentPosition;
        final currentMs = currentPos.inMilliseconds.clamp(0, totalMs);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _format(currentPos),
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
      },
    );
  }

  String _format(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
