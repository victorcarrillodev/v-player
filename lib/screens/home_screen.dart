import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/vmusic_widgets.dart';
import '../widgets/artwork_widget.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                // Custom App Bar
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.search_rounded, color: Colors.white, size: 28),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'V',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Music',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.cast_rounded, color: Colors.white, size: 26),
                            SizedBox(width: 16),
                            Icon(Icons.settings_outlined, color: Colors.white, size: 26),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Content that stays visible or is specific to "Para ti"
                if (_selectedIndex == 0) ...[
                  // Quick Action Grid
                  const SliverToBoxAdapter(child: ActionGrid()),

                  // Sugerencias
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const VMusicSectionHeader(title: 'Sugerencias'),
                        MixedSuggestions(
                          songs: provider.songs,
                          isLoading: provider.isLoading,
                        ),
                      ],
                    ),
                  ),

                  // Artistas (Circular)
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const VMusicSectionHeader(title: 'Artistas'),
                        HorizontalArtists(
                          songs: provider.songs,
                          isLoading: provider.isLoading,
                        ),
                      ],
                    ),
                  ),

                  // Artistas (Square/Albums)
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const VMusicSectionHeader(title: 'Artistas'),
                        HorizontalAlbums(
                          songs: provider.songs,
                          isLoading: provider.isLoading,
                        ),
                      ],
                    ),
                  ),

                  // Listas de Reproduccion
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const VMusicSectionHeader(title: 'Listas de Reproduccion'),
                        PlaylistCard(
                          title: 'Chill',
                          songs: provider.songs,
                          isLoading: provider.isLoading,
                        ),
                        PlaylistCard(
                          title: 'Relax',
                          songs: provider.songs,
                          isLoading: provider.isLoading,
                        ),
                      ],
                    ),
                  ),

                  // Favoritos
                  const SliverToBoxAdapter(
                    child: VMusicSectionHeader(title: 'Favoritos'),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return FavoriteSongTile(
                          song: index < provider.songs.length ? provider.songs[index] : null,
                          index: index,
                          isLoading: provider.isLoading,
                        );
                      },
                      childCount: provider.isLoading 
                          ? 5 
                          : (provider.songs.length > 10 ? 10 : provider.songs.length),
                    ),
                  ),

                  // Empty State Action
                  if (!provider.isLoading && provider.songs.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            const Text(
                              'No se encontró música en el dispositivo',
                              style: TextStyle(color: Colors.white54),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: provider.loadSongs,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Refrescar biblioteca'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],


                // Tab Specific Content for other tabs
                if (_selectedIndex != 0)
                   SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Text(
                        ['Sobre ti', 'Música', 'Álbumes', 'Artistas', 'Playlists'][_selectedIndex],
                        style: const TextStyle(color: Colors.white54, fontSize: 18),
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
          // Dynamic height based on whether a song is playing
          bottomNavigationBar: SizedBox(
            height: provider.currentSong != null ? 145 : 85,
            child: Stack(
              children: [
                // Mini Player (Only shown when a song is active)
                if (provider.currentSong != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
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
                      },
                      child: Container(
                        height: 75,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFF5722), Color(0xFFFF7043)],
                          ),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: ArtworkWidget(
                                song: provider.currentSong,
                                size: 52,
                                borderRadius: 0,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    provider.currentSong?.title ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    provider.currentSong?.artist ?? '',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 13,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                provider.isPlaying
                                    ? Icons.pause_circle_outline_rounded
                                    : Icons.play_circle_outline_rounded,
                                color: Colors.white,
                                size: 38,
                              ),
                              onPressed: provider.togglePlay,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Tab Navigator (Always shown at bottom)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: VMusicTabBar(
                    selectedIndex: _selectedIndex,
                    onTap: (index) => setState(() => _selectedIndex = index),
                  ),
                ),
              ],
            ),
          ),



        );
      },
    );
  }
}
