import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CustomizeSettingsScreen extends StatelessWidget {
  const CustomizeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final themeProvider = context.themeProvider;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Personalizar'),
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sección Minimalismo
          _buildSectionHeader('MINIMALISMO', colors),
          _buildSettingSwitch(
            title: 'Mostrar nombres en pestañas',
            subtitle: 'Muestra u oculta los textos en la barra de navegación inferior',
            value: themeProvider.showBottomNavLabels,
            onChanged: (val) => themeProvider.toggleBottomNavLabels(val),
            colors: colors,
          ),
          const SizedBox(height: 24),

          // Sección Estética
          _buildSectionHeader('ESTÉTICA', colors),
          _buildSettingSwitch(
            title: 'Modo Cristal (Glassmorphism)',
            subtitle: 'Aplica un efecto translúcido y borroso en los paneles de la interfaz',
            value: themeProvider.enableGlassmorphism,
            onChanged: (val) => themeProvider.toggleGlassmorphism(val),
            colors: colors,
          ),
          const SizedBox(height: 24),

          // Sección Formas
          _buildSectionHeader('FORMAS Y BORDES', colors),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Redondeo de Portadas',
                      style: TextStyle(color: colors.onSurface, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${themeProvider.artworkBorderRadius.toInt()} px',
                      style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Ajusta qué tan redondeadas quieres que se vean las imágenes de los álbumes.',
                  style: TextStyle(color: colors.onSurfaceMuted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: colors.primary,
                    inactiveTrackColor: colors.surfaceVariant,
                    thumbColor: colors.primary,
                    overlayColor: colors.primary.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    min: 0.0,
                    max: 48.0,
                    divisions: 12,
                    value: themeProvider.artworkBorderRadius,
                    onChanged: (val) => themeProvider.setArtworkBorderRadius(val),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: colors.primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
