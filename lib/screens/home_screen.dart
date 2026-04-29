import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:miniplayer/miniplayer.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/vmusic_widgets.dart';
import '../widgets/artwork_widget.dart';
import '../widgets/song_tile.dart';
import '../widgets/gradient_mask.dart';
import '../models/song_model.dart';
import '../models/playlist_model.dart';
import 'player_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MusicProvider>().loadSongs();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, provider, _) {
        final List<AppSong> favoriteSongs = [];
        final favPlaylist = provider.playlists.cast<AppPlaylist?>().firstWhere((p) => p?.id == 'favorites', orElse: () => null);
        if (favPlaylist != null) {
          favoriteSongs.addAll(favPlaylist.songIds
              .map((id) => provider.songs.cast<AppSong?>().firstWhere((s) => s?.id == id, orElse: () => null))
              .where((s) => s != null)
              .cast<AppSong>());
        }

        final screenHeight = MediaQuery.of(context).size.height;
        final maxPlayerHeight = screenHeight;
        final miniHeight = 75.0;

        final mainScaffold = Scaffold(
              backgroundColor: AppTheme.background,
              body: SafeArea(
                bottom: false,
                child: CustomScrollView(
              slivers: [
                // Custom App Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _isSearching
                        ? Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: TextField(
                                    controller: _searchController,
                                    autofocus: true,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'Buscar...',
                                      hintStyle: const TextStyle(color: Colors.white54),
                                      border: InputBorder.none,
                                      icon: const Icon(Icons.search_rounded, color: Colors.white54),
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.close_rounded, color: Colors.white54),
                                        onPressed: () {
                                          if (_searchController.text.isNotEmpty) {
                                            _searchController.clear();
                                            provider.search('');
                                          } else {
                                            setState(() {
                                              _isSearching = false;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    onChanged: (val) => provider.search(val),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.search_rounded, color: Colors.white, size: 28),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setState(() {
                                    _isSearching = true;
                                  });
                                },
                              ),
                              const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GradientMask(
                                    child: Text(
                                      'V',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                      ),
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
                                  const Icon(Icons.cast_rounded, color: Colors.white, size: 26),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 26),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),

                if (_isSearching)
                  if (_searchController.text.isNotEmpty && provider.songs.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'No se encontraron resultados',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final song = provider.songs[index];
                          return SongTile(
                            song: song,
                            index: index,
                            onTap: () {
                              provider.playSong(song, index, queueContext: provider.songs);
                              FocusScope.of(context).unfocus();
                            },
                          );
                        },
                        childCount: provider.songs.length,
                      ),
                    )
                else if (_selectedIndex == 0) ...[
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
                        VMusicSectionHeader(
                          title: 'Artistas',
                          onMorePressed: () => setState(() => _selectedIndex = 3),
                        ),
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
                        VMusicSectionHeader(
                          title: 'Álbumes',
                          onMorePressed: () => setState(() => _selectedIndex = 2),
                        ),
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
                        VMusicSectionHeader(
                          title: 'Listas de Reproduccion',
                          onMorePressed: () => setState(() => _selectedIndex = 4),
                        ),
                        if (provider.playlists.where((p) => p.id != 'favorites').isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                            child: Column(
                              children: [
                                const Icon(Icons.queue_music_rounded, color: Colors.white24, size: 48),
                                const SizedBox(height: 16),
                                const Text(
                                  'Aún no hay listas de reproducción creadas.',
                                  style: TextStyle(color: Colors.white54, fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: () => _showCreatePlaylistDialog(context, provider),
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('Crear Playlist'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...provider.playlists.where((p) => p.id != 'favorites').map((playlist) {
                            final playlistSongs = playlist.songIds
                                .map((id) => provider.songs.cast<AppSong?>().firstWhere((s) => s?.id == id, orElse: () => null))
                                .where((s) => s != null)
                                .cast<AppSong>()
                                .toList();
                            return PlaylistCard(
                              playlist: playlist,
                              title: playlist.name,
                              songs: playlistSongs,
                              isLoading: provider.isLoading,
                            );
                          }),
                      ],
                    ),
                  ),

                  // Favoritos
                  const SliverToBoxAdapter(
                    child: VMusicSectionHeader(title: 'Favoritos'),
                  ),
                  if (!provider.isLoading && favoriteSongs.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Aún no has agregado canciones a favoritos.',
                          style: TextStyle(color: Colors.white54, fontSize: 15),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return FavoriteSongTile(
                            song: provider.isLoading ? null : favoriteSongs[index],
                            index: index,
                            isLoading: provider.isLoading,
                          );
                        },
                        childCount: provider.isLoading 
                            ? 5 
                            : (favoriteSongs.length > 20 ? 20 : favoriteSongs.length),
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
                            Container(
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: ElevatedButton.icon(
                                onPressed: provider.loadSongs,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Refrescar biblioteca'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],


                // Tab Specific Content for other tabs
                if (_selectedIndex == 1)
                  SliverFillRemaining(
                    hasScrollBody: true,
                    child: _buildMusicTab(context, provider),
                  )
                else if (_selectedIndex == 2)
                  SliverFillRemaining(
                    hasScrollBody: true,
                    child: _buildAlbumsTab(context, provider),
                  )
                else if (_selectedIndex == 3)
                  SliverFillRemaining(
                    hasScrollBody: true,
                    child: _buildArtistsTab(context, provider),
                  )
                else if (_selectedIndex == 4)
                  SliverFillRemaining(
                    hasScrollBody: true,
                    child: _buildPlaylistsTab(context, provider),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 200)), // Extra space for miniplayer + tab
              ],
            ),
          ),
          bottomNavigationBar: SizedBox(
            height: 95,
            child: Stack(
              children: [
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

        // Custom Scaffold wrapper to hold Miniplayer above BottomNavigationBar seamlessly
        return Stack(
          children: [
            mainScaffold,
            if (provider.currentSong != null)
              Miniplayer(
                minHeight: 85, // Height of the miniplayer
                maxHeight: screenHeight,
                builder: (height, percentage) {
                  if (percentage > 0.05) {
                    return PlayerScreen(expandPercentage: percentage);
                  }
                  return _buildMiniPlayerRow(provider, percentage);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildMiniPlayerRow(MusicProvider provider, double percentage) {
    return Opacity(
      opacity: (1.0 - percentage * 5).clamp(0.0, 1.0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
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
    );
  }

  // Removed _openPlayer since we use the interactive overlay now

  Widget _buildMusicTab(BuildContext context, MusicProvider provider) {
    if (provider.songs.isEmpty) {
      return const Center(child: Text('No hay música disponible', style: TextStyle(color: Colors.white54)));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16),
      itemCount: provider.songs.length,
      itemBuilder: (context, index) {
        return SongTile(song: provider.songs[index], index: index);
      },
    );
  }

  Widget _buildAlbumsTab(BuildContext context, MusicProvider provider) {
    if (provider.songs.isEmpty) return const SizedBox.shrink();
    
    // Group by album
    final Map<String, List<AppSong>> albums = {};
    for (var song in provider.songs) {
      albums.putIfAbsent(song.album, () => []).add(song);
    }
    final albumList = albums.entries.toList();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: albumList.length,
      itemBuilder: (context, index) {
        final album = albumList[index];
        final firstSong = album.value.first;
        return GestureDetector(
          onTap: () {
            // Option to play all album songs
            provider.playSong(firstSong, 0, queueContext: album.value);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ArtworkWidget(song: firstSong, size: 200, borderRadius: 12),
              ),
              const SizedBox(height: 8),
              Text(album.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('${album.value.length} canciones', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildArtistsTab(BuildContext context, MusicProvider provider) {
    if (provider.songs.isEmpty) return const SizedBox.shrink();

    // Group by artist
    final Map<String, List<AppSong>> artists = {};
    for (var song in provider.songs) {
      artists.putIfAbsent(song.artist, () => []).add(song);
    }
    final artistList = artists.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16),
      itemCount: artistList.length,
      itemBuilder: (context, index) {
        final artist = artistList[index];
        final firstSong = artist.value.first;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.surface,
            child: ClipOval(
               child: ArtworkWidget(song: firstSong, size: 60, borderRadius: 0),
            ),
          ),
          title: Text(artist.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text('${artist.value.length} canciones', style: const TextStyle(color: Colors.white54)),
          onTap: () {
            provider.playSong(firstSong, 0, queueContext: artist.value);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
          },
        );
      },
    );
  }

  Widget _buildPlaylistsTab(BuildContext context, MusicProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tus Playlists',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const GradientMask(child: Icon(Icons.add_box_rounded, color: Colors.white, size: 32)),
                onPressed: () => _showCreatePlaylistDialog(context, provider),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            clipBehavior: Clip.none,
            padding: const EdgeInsets.only(top: 8, bottom: 100),
            itemCount: provider.playlists.length,
            itemBuilder: (context, index) {
              final playlist = provider.playlists[index];
              final playlistSongs = playlist.songIds
                  .map((id) => provider.songs.cast<AppSong?>().firstWhere((s) => s?.id == id, orElse: () => null))
                  .where((s) => s != null)
                  .cast<AppSong>()
                  .toList();

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  PlaylistCard(
                    playlist: playlist,
                    title: playlist.name,
                    songs: playlistSongs,
                    isLoading: provider.isLoading,
                  ),
                  if (playlist.id != 'favorites')
                    Positioned(
                      top: 16,
                      right: 24,
                      child: PopupMenuButton<String>(
                        icon: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
                        ),
                        color: AppTheme.surfaceVariant,
                        elevation: 8,
                        onSelected: (value) {
                          if (value == 'delete') {
                            provider.deletePlaylist(playlist.id);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_rounded, color: Colors.redAccent, size: 20),
                                SizedBox(width: 8),
                                Text('Eliminar Playlist', style: TextStyle(color: Colors.redAccent)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, MusicProvider provider) {
    String folderName = '';
    final Set<int> selectedSongs = {};

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              title: const Text('Nueva Playlist', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: TextField(
                        autofocus: true,
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                        decoration: const InputDecoration(
                          hintText: 'Nombre de la playlist',
                          hintStyle: TextStyle(color: Colors.white54),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary, width: 2)),
                        ),
                        onChanged: (val) => folderName = val,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Agregar canciones',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: provider.songs.length,
                        itemBuilder: (context, index) {
                          final song = provider.songs[index];
                          final isSelected = selectedSongs.contains(song.id);
                          return CheckboxListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                            title: Text(song.title, style: const TextStyle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(song.artist, style: const TextStyle(color: Colors.white54), maxLines: 1, overflow: TextOverflow.ellipsis),
                            value: isSelected,
                            activeColor: AppTheme.primary,
                            checkColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  selectedSongs.add(song.id);
                                } else {
                                  selectedSongs.remove(song.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
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
                        provider.createPlaylist(folderName.trim(), initialSongs: selectedSongs.toList());
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Crear', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
