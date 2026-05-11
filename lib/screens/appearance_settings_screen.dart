import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppearanceSettingsScreen extends StatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  State<AppearanceSettingsScreen> createState() => _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends State<AppearanceSettingsScreen> {
  bool _darkMode = true;
  bool _dynamicColors = true;
  bool _animations = true;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Apariencia',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        titleSpacing: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _buildSectionHeader('Tema'),
          _buildSwitchTile(
            icon: Icons.dark_mode_rounded,
            title: 'Modo Oscuro',
            subtitle: 'Usar el tema oscuro en toda la aplicación',
            value: _darkMode,
            onChanged: (val) => setState(() => _darkMode = val),
            color: Colors.purpleAccent,
          ),
          _buildSwitchTile(
            icon: Icons.color_lens_rounded,
            title: 'Colores Dinámicos',
            subtitle: 'Extraer colores de la portada del álbum',
            value: _dynamicColors,
            onChanged: (val) => setState(() => _dynamicColors = val),
            color: Colors.blueAccent,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Efectos visuales'),
          _buildSwitchTile(
            icon: Icons.animation_rounded,
            title: 'Animaciones de la interfaz',
            subtitle: 'Habilitar transiciones fluidas y efectos',
            value: _animations,
            onChanged: (val) => setState(() => _animations = val),
            color: Colors.greenAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.primary,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color color,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 13,
          ),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primary,
        activeTrackColor: AppTheme.primary.withValues(alpha: 0.4),
        inactiveThumbColor: Colors.grey,
        inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
      ),
    );
  }
}
