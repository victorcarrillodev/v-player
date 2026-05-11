import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';

class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Apariencia',
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        titleSpacing: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _buildSectionHeader('TEMA PRINCIPAL', colors),
          _buildSwitchTile(
            icon: Icons.dark_mode_rounded,
            title: 'Modo Oscuro',
            subtitle: 'Usar el tema oscuro en toda la aplicación',
            value: themeProvider.isDarkMode,
            onChanged: (val) => themeProvider.toggleDarkMode(val),
            color: Colors.purpleAccent,
            colors: colors,
          ),
          _buildSwitchTile(
            icon: Icons.color_lens_rounded,
            title: 'Colores Dinámicos',
            subtitle: 'Extraer colores de la portada del álbum',
            value: themeProvider.dynamicColors,
            onChanged: (val) => themeProvider.toggleDynamicColors(val),
            color: Colors.blueAccent,
            colors: colors,
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('EFECTOS VISUALES', colors),
          _buildSwitchTile(
            icon: Icons.animation_rounded,
            title: 'Animaciones de la interfaz',
            subtitle: 'Habilitar transiciones fluidas y efectos',
            value: themeProvider.animationsEnabled,
            onChanged: (val) => themeProvider.toggleAnimations(val),
            color: Colors.greenAccent,
            colors: colors,
          ),
          const SizedBox(height: 24),
          Opacity(
            opacity: themeProvider.dynamicColors ? 0.5 : 1.0,
            child: IgnorePointer(
              ignoring: themeProvider.dynamicColors,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('ESTILO DE COLORES', colors),
                  _buildPaletteTabs(context, themeProvider, colors),
                  const SizedBox(height: 16),
                  _buildPaletteGrid(context, themeProvider, colors),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          color: colors.primary,
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
    required AppColors colors,
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
        child: const Icon(Icons.palette, color: Colors.white, size: 24), // Fix valid constant issue
      ),
      title: Text(
        title,
        style: TextStyle(
          color: colors.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: TextStyle(
            color: colors.onSurfaceMuted,
            fontSize: 13,
          ),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: colors.primary,
        activeTrackColor: colors.primary.withValues(alpha: 0.4),
        inactiveThumbColor: Colors.grey,
        inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildPaletteTabs(BuildContext context, ThemeProvider provider, AppColors colors) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: ColorPaletteType.values.map((type) {
          final isSelected = provider.paletteType == type;
          final title = _getPaletteTypeName(type);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(title),
              selected: isSelected,
              onSelected: (val) {
                if (val) provider.setPaletteType(type);
              },
              selectedColor: colors.primary.withValues(alpha: 0.2),
              backgroundColor: colors.surface,
              labelStyle: TextStyle(
                color: isSelected ? colors.primary : colors.onSurfaceMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? colors.primary : colors.surfaceVariant,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getPaletteTypeName(ColorPaletteType type) {
    switch (type) {
      case ColorPaletteType.solid: return 'Sólidos';
      case ColorPaletteType.gradient: return 'Gradientes';
      case ColorPaletteType.neon: return 'Neón';
      case ColorPaletteType.changing: return 'Cambiantes';
    }
  }

  Widget _buildPaletteGrid(BuildContext context, ThemeProvider provider, AppColors colors) {
    int count = 0;
    if (provider.paletteType == ColorPaletteType.solid) {
      count = ThemeProvider.solidPalettes.length;
    } else if (provider.paletteType == ColorPaletteType.gradient) count = ThemeProvider.gradientPalettes.length;
    else if (provider.paletteType == ColorPaletteType.neon) count = ThemeProvider.neonPalettes.length;
    else if (provider.paletteType == ColorPaletteType.changing) count = ThemeProvider.changingPalettes.length;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: count,
      itemBuilder: (context, index) {
        final isSelected = provider.selectedPaletteIndex == index;
        return GestureDetector(
          onTap: () => provider.setPaletteIndex(index),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? colors.onSurface : Colors.transparent,
                width: 3,
              ),
            ),
            padding: const EdgeInsets.all(4),
            child: _buildPaletteCircle(provider.paletteType, index),
          ),
        );
      },
    );
  }

  Widget _buildPaletteCircle(ColorPaletteType type, int index) {
    if (type == ColorPaletteType.solid) {
      final p = ThemeProvider.solidPalettes[index];
      return Container(
        decoration: BoxDecoration(shape: BoxShape.circle, color: p.primary),
      );
    } else if (type == ColorPaletteType.gradient) {
      final p = ThemeProvider.gradientPalettes[index];
      return Container(
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: p.gradient),
      );
    } else if (type == ColorPaletteType.neon) {
      final p = ThemeProvider.neonPalettes[index];
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: p.primary,
          boxShadow: [
            BoxShadow(
              color: p.glowColor ?? p.primary,
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
      );
    } else if (type == ColorPaletteType.changing) {
      final seq = ThemeProvider.changingPalettes[index];
      // Show a mini gradient of the sequence to represent it
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: seq.primarySequence.length >= 2 
                ? seq.primarySequence 
                : [seq.primarySequence.first, seq.primarySequence.first],
          ),
        ),
      );
    }
    return const SizedBox();
  }
}
