import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/song_model.dart';
import 'artwork_widget.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../screens/player_screen.dart';

class VMusicSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onMorePressed;

  const VMusicSectionHeader({
    super.key,
    required this.title,
    this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
            onPressed: onMorePressed,
          ),
        ],
      ),
    );
  }
}

class ActionGrid extends StatelessWidget {
  const ActionGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 6,
        children: const [
          _ActionButton(label: 'Aleatorio', icon: Icons.shuffle_rounded),
          _ActionButton(label: 'Historial', icon: Icons.history_rounded),
          _ActionButton(label: 'Más reproducido', icon: Icons.trending_up_rounded),
          _ActionButton(label: 'Último añadido', icon: Icons.add_box_rounded),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;

  const _ActionButton({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class VMusicSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool isCircle;

  const VMusicSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
    this.isCircle = false,
  });

  @override
  State<VMusicSkeleton> createState() => _VMusicSkeletonState();
}

class _VMusicSkeletonState extends State<VMusicSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.1, end: 0.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(_animation.value),
            borderRadius: widget.isCircle ? null : BorderRadius.circular(widget.borderRadius),
            shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
          ),
        );
      },
    );
  }
}

class HorizontalArtists extends StatelessWidget {
  final List<AppSong> songs;
  final bool isLoading;
  const HorizontalArtists({super.key, required this.songs, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    if (isLoading || songs.isEmpty) {
      return SizedBox(
        height: 155,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: 5,
          itemBuilder: (context, index) => Container(
            width: 100,
            margin: const EdgeInsets.only(right: 16),
            child: const Column(
              children: [
                VMusicSkeleton(width: 80, height: 80, isCircle: true),
                SizedBox(height: 12),
                VMusicSkeleton(width: 60, height: 12),
              ],
            ),
          ),
        ),
      );
    }

    final artists = songs.map((s) => s.artist).toSet().toList();

    return SizedBox(
      height: 155,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: artists.length,
        itemBuilder: (context, index) {
          final artist = artists[index];
          final firstSong = songs.firstWhere((s) => s.artist == artist);
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.transparent,
                  child: ClipOval(
                    child: ArtworkWidget(song: firstSong, size: 80, borderRadius: 0),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  artist,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MosaicCell {
  final int col;
  final int row;
  final int w;
  final int h;
  final bool isMix;
  const _MosaicCell(this.col, this.row, this.w, this.h, {this.isMix = false});
}

class MixedSuggestions extends StatefulWidget {
  final List<AppSong> songs;
  final bool isLoading;
  const MixedSuggestions({super.key, required this.songs, this.isLoading = false});

  @override
  State<MixedSuggestions> createState() => _MixedSuggestionsState();
}

class _MixedSuggestionsState extends State<MixedSuggestions> {
  List<AppSong> _randomSongs = [];

  static const List<_MosaicCell> _cells = [
    // Block 1
    _MosaicCell(0, 0, 2, 2, isMix: true),
    _MosaicCell(2, 0, 1, 1),
    _MosaicCell(3, 0, 1, 1),
    _MosaicCell(4, 0, 1, 1),
    _MosaicCell(2, 1, 1, 1),
    _MosaicCell(3, 1, 2, 2),
    _MosaicCell(0, 2, 1, 1),
    _MosaicCell(1, 2, 1, 1),
    _MosaicCell(2, 2, 1, 1),
    // Block 2
    _MosaicCell(5, 0, 1, 1),
    _MosaicCell(6, 0, 2, 2),
    _MosaicCell(8, 0, 1, 1),
    _MosaicCell(9, 0, 1, 1),
    _MosaicCell(5, 1, 1, 1),
    _MosaicCell(8, 1, 2, 2),
    _MosaicCell(5, 2, 1, 1),
    _MosaicCell(6, 2, 1, 1),
    _MosaicCell(7, 2, 1, 1),
    // Block 3
    _MosaicCell(10, 0, 2, 2),
    _MosaicCell(12, 0, 1, 1),
    _MosaicCell(13, 0, 1, 1),
    _MosaicCell(14, 0, 1, 1),
    _MosaicCell(12, 1, 2, 2),
    _MosaicCell(14, 1, 1, 1),
    _MosaicCell(10, 2, 1, 1),
    _MosaicCell(11, 2, 1, 1),
    _MosaicCell(14, 2, 1, 1),
  ];

  @override
  void didUpdateWidget(MixedSuggestions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.songs != widget.songs) {
      _shuffle();
    }
  }

  @override
  void initState() {
    super.initState();
    _shuffle();
  }

  void _shuffle() {
    final list = List<AppSong>.from(widget.songs);
    list.shuffle(Random());
    setState(() {
      _randomSongs = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    const double spacing = 8.0;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double viewportWidth = screenWidth - 32;
    final double cw = (viewportWidth - 4 * spacing) / 5;
    final double totalHeight = 3 * cw + 2 * spacing;
    final double totalScrollWidth = 15 * cw + 14 * spacing;

    if (widget.isLoading || widget.songs.isEmpty) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        child: SizedBox(
          height: totalHeight,
          width: totalScrollWidth,
          child: Stack(
            children: _buildSkeletons(cw, spacing),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      child: SizedBox(
        height: totalHeight,
        width: totalScrollWidth,
        child: Stack(
          children: _buildItems(context, cw, spacing),
        ),
      ),
    );
  }

  List<Widget> _buildSkeletons(double cw, double spacing) {
    List<Widget> children = [];
    for (final cell in _cells) {
      double left = cell.col * (cw + spacing);
      double top = cell.row * (cw + spacing);
      double width = cell.w * cw + (cell.w - 1) * spacing;
      double height = cell.h * cw + (cell.h - 1) * spacing;

      if (cell.isMix) {
        children.add(
          Positioned(
            left: left, top: top, width: width, height: height,
            child: const VMusicSkeleton(width: 200, height: 200, borderRadius: 12),
          ),
        );
      } else {
        children.add(
          Positioned(
            left: left, top: top, width: width, height: height,
            child: VMusicSkeleton(width: width, height: height, borderRadius: 8),
          ),
        );
      }
    }
    return children;
  }

  List<Widget> _buildItems(BuildContext context, double cw, double spacing) {
    List<Widget> children = [];
    int songIdx = 0;
    for (final cell in _cells) {
      double left = cell.col * (cw + spacing);
      double top = cell.row * (cw + spacing);
      double width = cell.w * cw + (cell.w - 1) * spacing;
      double height = cell.h * cw + (cell.h - 1) * spacing;

      if (cell.isMix) {
        children.add(
          Positioned(
            left: left, top: top, width: width, height: height,
            child: _buildBigOrangeCard(context),
          ),
        );
      } else {
        if (songIdx < _randomSongs.length) {
          final song = _randomSongs[songIdx];
          children.add(
            Positioned(
              left: left, top: top, width: width, height: height,
              child: GestureDetector(
                onTap: () => _playAndNavigate(context, song),
                child: ArtworkWidget(song: song, size: width, borderRadius: cell.w > 1 ? 12 : 8),
              ),
            ),
          );
          songIdx++;
        }
      }
    }
    return children;
  }

  Widget _buildBigOrangeCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _playShuffledQueue(context),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF5722), Color(0xFFFF7043)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shuffle_rounded, color: Colors.white, size: 32),
            SizedBox(height: 8),
            Text(
              'Mix de\nMúsica',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _playShuffledQueue(BuildContext context) {
    if (_randomSongs.isEmpty) return;
    final provider = context.read<MusicProvider>();
    final shuffled = List<AppSong>.from(widget.songs)..shuffle(Random());
    provider.playShuffledQueue(shuffled);
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const PlayerScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutQuart;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
  }

  void _playAndNavigate(BuildContext context, AppSong song) {
    final int originalIndex = widget.songs.indexOf(song);
    final provider = context.read<MusicProvider>();
    provider.playSong(song, originalIndex != -1 ? originalIndex : 0);
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const PlayerScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutQuart;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
  }
}

class HorizontalAlbums extends StatelessWidget {
  final List<AppSong> songs;
  final bool isLoading;
  const HorizontalAlbums({super.key, required this.songs, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    if (isLoading || songs.isEmpty) {
      return SizedBox(
        height: 195,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: 5,
          itemBuilder: (context, index) => Container(
            width: 130,
            margin: const EdgeInsets.only(right: 16),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VMusicSkeleton(width: 130, height: 130, borderRadius: 12),
                SizedBox(height: 12),
                VMusicSkeleton(width: 100, height: 14),
                SizedBox(height: 6),
                VMusicSkeleton(width: 70, height: 11),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 195,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: songs.length > 10 ? 10 : songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return Container(
            width: 130,
            margin: const EdgeInsets.only(right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _playAndNavigate(context, song, index),
                  child: ArtworkWidget(song: song, size: 130, borderRadius: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  song.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  song.artist,
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _playAndNavigate(BuildContext context, AppSong song, int index) {
    final provider = context.read<MusicProvider>();
    provider.playSong(song, index);
    
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const PlayerScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutQuart;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
  }
}

class PlaylistCard extends StatelessWidget {
  final String title;
  final List<AppSong> songs;
  final bool isLoading;

  const PlaylistCard({super.key, required this.title, required this.songs, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E26),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final int count = isLoading || songs.isEmpty ? 4 : (songs.length > 4 ? 4 : songs.length);
          List<Widget> children = [];
          
          final double orangeWidth = totalWidth * 0.42;
          final double imgSize = 140.0;
          
          final double leftmostLeft = orangeWidth - 25.0; // Overlap under the orange block
          final double rightmostRight = -20.0; // Slight bleed on the right
          final double leftmostRight = totalWidth - leftmostLeft - imgSize;
          
          for (int i = count - 1; i >= 0; i--) {
            double currentRight = -20.0;
            if (count > 1) {
               double t = (count - 1 - i) / (count - 1);
               currentRight = rightmostRight + (leftmostRight - rightmostRight) * t;
            }

            children.add(
              Positioned(
                right: currentRight,
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(-4, 0), // Shadow to the left
                      ),
                    ],
                  ),
                  child: isLoading || songs.isEmpty
                      ? const VMusicSkeleton(width: 140, height: 140, borderRadius: 16)
                      : ArtworkWidget(
                          song: songs[i],
                          size: imgSize,
                          borderRadius: 16,
                        ),
                ),
              ),
            );
          }

          // Orange block
          children.add(
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: orangeWidth,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(4, 0), // Shadow to the right
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          );

          return Stack(
            clipBehavior: Clip.none,
            children: children,
          );
        },
      ),
    );
  }
}

class FavoriteSongTile extends StatelessWidget {
  final AppSong? song;
  final int index;
  final bool isLoading;
  const FavoriteSongTile({super.key, this.song, required this.index, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    if (isLoading || song == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            VMusicSkeleton(width: 55, height: 55, borderRadius: 8),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  VMusicSkeleton(width: 140, height: 16),
                  SizedBox(height: 8),
                  VMusicSkeleton(width: 90, height: 12),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _playAndNavigate(context, song!, index),
            child: ArtworkWidget(song: song, size: 55, borderRadius: 8),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song!.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  song!.artist,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  void _playAndNavigate(BuildContext context, AppSong song, int index) {
    final provider = context.read<MusicProvider>();
    provider.playSong(song, index);
    
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const PlayerScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutQuart;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
  }
}

class VMusicTabBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const VMusicTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      decoration: const BoxDecoration(
        color: Color(0xFF0F111A),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24.0), topRight: Radius.circular(24.0))
      ),
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _TabItem(
            icon: Icons.person_outline_rounded,
            label: 'Para ti',
            isSelected: selectedIndex == 0,
            onTap: () => onTap(0),
          ),
          _TabItem(
            icon: Icons.music_note_rounded,
            label: 'Música',
            isSelected: selectedIndex == 1,
            onTap: () => onTap(1),
          ),
          _TabItem(
            icon: Icons.album_outlined,
            label: 'Álbumes',
            isSelected: selectedIndex == 2,
            onTap: () => onTap(2),
          ),
          _TabItem(
            icon: Icons.person_pin_rounded,
            label: 'Artistas',
            isSelected: selectedIndex == 3,
            onTap: () => onTap(3),
          ),
          _TabItem(
            icon: Icons.playlist_play_rounded,
            label: 'Playlists',
            isSelected: selectedIndex == 4,
            onTap: () => onTap(4),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String? label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({
    required this.icon,
    this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF5722) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF8E92A3),
                size: 26,
              ),
            ),
            if (isSelected && label != null) ...[
              const SizedBox(height: 4),
              Text(
                label!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

