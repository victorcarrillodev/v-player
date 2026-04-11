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
        childAspectRatio: 3.2,
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
        height: 140,
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
      height: 140,
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
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
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

class MixedSuggestions extends StatelessWidget {
  final List<AppSong> songs;
  final bool isLoading;
  const MixedSuggestions({super.key, required this.songs, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    const double spacing = 8.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double totalWidth = constraints.maxWidth;
          final double cw = (totalWidth - 4 * spacing) / 5; // Cell width for 5 columns
          final double totalHeight = 3 * cw + 2 * spacing; // Total height for 3 rows

          if (isLoading || songs.isEmpty) {
            return SizedBox(
              height: totalHeight,
              width: totalWidth,
              child: Stack(
                children: [
                   Positioned(
                    left: 0,
                    top: 0,
                    width: 2 * cw + spacing,
                    height: 2 * cw + spacing,
                    child: const VMusicSkeleton(width: 200, height: 200, borderRadius: 12),
                  ),
                  _buildSkeletonItem(2 * cw + 2 * spacing, 0, cw),
                  _buildSkeletonItem(3 * cw + 3 * spacing, 0, cw),
                  _buildSkeletonItem(4 * cw + 4 * spacing, 0, cw),
                  _buildSkeletonItem(2 * cw + 2 * spacing, cw + spacing, cw),
                  Positioned(
                    left: 3 * cw + 3 * spacing,
                    top: cw + spacing,
                    width: 2 * cw + spacing,
                    height: 2 * cw + spacing,
                    child: const VMusicSkeleton(width: 200, height: 200, borderRadius: 12),
                  ),
                  _buildSkeletonItem(0, 2 * cw + 2 * spacing, cw),
                  _buildSkeletonItem(cw + spacing, 2 * cw + 2 * spacing, cw),
                  _buildSkeletonItem(2 * cw + 2 * spacing, 2 * cw + 2 * spacing, cw),
                ],
              ),
            );
          }

          return SizedBox(
            height: totalHeight,
            width: totalWidth,
            child: Stack(
              children: [
                // Mix Card (R0, C0, spans 2x2)
                Positioned(
                  left: 0,
                  top: 0,
                  width: 2 * cw + spacing,
                  height: 2 * cw + spacing,
                  child: _buildBigOrangeCard(),
                ),

                // C1 (R0, C2)
                _buildGridItem(context, songs, 0, 2 * cw + 2 * spacing, 0, cw),
                // C2 (R0, C3)
                _buildGridItem(context, songs, 1, 3 * cw + 3 * spacing, 0, cw),
                // C3 (R0, C4)
                _buildGridItem(context, songs, 2, 4 * cw + 4 * spacing, 0, cw),

                // C4 (R1, C2)
                _buildGridItem(context, songs, 3, 2 * cw + 2 * spacing, cw + spacing, cw),

                // Thug Card (R1, C3, spans 2x2)
                Positioned(
                  left: 3 * cw + 3 * spacing,
                  top: cw + spacing,
                  width: 2 * cw + spacing,
                  height: 2 * cw + spacing,
                  child: _buildTallCard(context, songs, 7),
                ),

                // C5 (R2, C0)
                _buildGridItem(context, songs, 4, 0, 2 * cw + 2 * spacing, cw),
                // C6 (R2, C1)
                _buildGridItem(context, songs, 5, cw + spacing, 2 * cw + 2 * spacing, cw),
                // C7 (R2, C2)
                _buildGridItem(context, songs, 6, 2 * cw + 2 * spacing, 2 * cw + 2 * spacing, cw),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonItem(double left, double top, double size) {
    return Positioned(
      left: left,
      top: top,
      width: size,
      height: size,
      child: VMusicSkeleton(width: size, height: size, borderRadius: 8),
    );
  }

  Widget _buildGridItem(BuildContext context, List<AppSong> songs, int songIndex, double left, double top, double size) {
    if (songIndex >= songs.length) return const SizedBox();
    return Positioned(
      left: left,
      top: top,
      width: size,
      height: size,
      child: GestureDetector(
        onTap: () => _playAndNavigate(context, songs[songIndex], songIndex),
        child: ArtworkWidget(song: songs[songIndex], size: size, borderRadius: 8),
      ),
    );
  }

  Widget _buildBigOrangeCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF5722), Color(0xFFFF7043)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'Mix de\nMúsica',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildTallCard(BuildContext context, List<AppSong> songs, int index) {
    if (index >= songs.length) return Container(decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)));
    return GestureDetector(
      onTap: () => _playAndNavigate(context, songs[index], index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ArtworkWidget(song: songs[index], size: 200, borderRadius: 0),
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

class HorizontalAlbums extends StatelessWidget {
  final List<AppSong> songs;
  final bool isLoading;
  const HorizontalAlbums({super.key, required this.songs, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    if (isLoading || songs.isEmpty) {
      return SizedBox(
        height: 180,
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
      height: 180,
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
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  song.artist,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
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
    if (isLoading || songs.isEmpty) {
      return Container(
        height: 140,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E26),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Container(color: Colors.white.withOpacity(0.05)),
            ),
            Expanded(
              flex: 1,
              child: GridView.count(
                padding: const EdgeInsets.all(4),
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(4, (index) => const Padding(
                  padding: EdgeInsets.all(2),
                  child: VMusicSkeleton(width: 70, height: 70, borderRadius: 4),
                )),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E26),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              color: AppTheme.primary,
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: GridView.count(
              padding: const EdgeInsets.all(2),
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(
                4,
                (index) => Padding(
                  padding: const EdgeInsets.all(1),
                  child: index < songs.length
                      ? ArtworkWidget(song: songs[index], size: 70, borderRadius: 0)
                      : Container(color: Colors.white10),
                ),
              ),
            ),
          ),
        ],
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

