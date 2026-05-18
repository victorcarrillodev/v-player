import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';

class IgnoredFoldersScreen extends StatelessWidget {
  const IgnoredFoldersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final musicProvider = context.watch<MusicProvider>();
    
    // Extraer carpetas únicas donde hay audios
    final Set<String> uniqueFolders = {};
    for (var song in musicProvider.allFoundSongs) {
      if (song.data != null && song.data!.isNotEmpty) {
        final dir = File(song.data!).parent.path;
        uniqueFolders.add(dir);
      }
    }
    
    final sortedFolders = uniqueFolders.toList()..sort();
    final ignoredFolders = musicProvider.ignoredFolders;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Carpetas de Audio'),
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'A continuación se muestran todas las carpetas del dispositivo donde se encontraron archivos de audio. Apaga las carpetas que deseas ignorar (ej. notas de voz de WhatsApp).',
              style: TextStyle(color: colors.onSurfaceMuted, fontSize: 14),
            ),
          ),
          Expanded(
            child: sortedFolders.isEmpty
                ? Center(
                    child: Text(
                      'No se encontraron carpetas con audio',
                      style: TextStyle(color: colors.onSurfaceMuted),
                    ),
                  )
                : ListView.builder(
                    itemCount: sortedFolders.length,
                    itemBuilder: (context, index) {
                      final folderPath = sortedFolders[index];
                      final folderName = folderPath.split('/').last;
                      final isIgnored = ignoredFolders.contains(folderPath);
                      
                      return SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          folderName.isEmpty ? '/' : folderName,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontWeight: FontWeight.bold,
                            decoration: isIgnored ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: Text(
                          folderPath,
                          style: TextStyle(color: colors.onSurfaceMuted, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // El Switch está "On" si la carpeta NO está ignorada (es decir, se muestra)
                        value: !isIgnored,
                        activeTrackColor: colors.primary,
                        inactiveTrackColor: colors.surfaceVariant,
                        onChanged: (value) {
                          // Si el usuario lo apaga (value = false), significa que la ignora.
                          musicProvider.toggleIgnoredFolder(folderPath);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
