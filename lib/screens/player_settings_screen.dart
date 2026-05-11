import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PlayerSettingsScreen extends StatefulWidget {
  const PlayerSettingsScreen({super.key});

  @override
  State<PlayerSettingsScreen> createState() => _PlayerSettingsScreenState();
}

class _PlayerSettingsScreenState extends State<PlayerSettingsScreen> {
  bool _gaplessPlayback = true;
  bool _crossfade = false;
  bool _pauseOnDisconnect = true;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Reproductor'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingSwitch(
            title: 'Reproducción sin pausas (Gapless)',
            subtitle: 'Evita los silencios entre canciones al cambiar de pista',
            value: _gaplessPlayback,
            onChanged: (val) => setState(() => _gaplessPlayback = val),
            colors: colors,
          ),
          _buildSettingSwitch(
            title: 'Fundido cruzado (Crossfade)',
            subtitle: 'Mezcla suavemente el final de una canción con el inicio de la siguiente',
            value: _crossfade,
            onChanged: (val) => setState(() => _crossfade = val),
            colors: colors,
          ),
          _buildSettingSwitch(
            title: 'Pausar al desconectar auriculares',
            subtitle: 'Pausa automáticamente la música si se desconecta el audio',
            value: _pauseOnDisconnect,
            onChanged: (val) => setState(() => _pauseOnDisconnect = val),
            colors: colors,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required AppColors colors,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: colors.onSurfaceMuted, fontSize: 13),
      ),
      value: value,
      activeTrackColor: colors.primary,
      onChanged: onChanged,
    );
  }
}
