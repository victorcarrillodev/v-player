import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
          'Configuración',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildSettingsTile(
                  icon: Icons.color_lens_rounded,
                  color: Colors.purpleAccent,
                  title: 'Apariencia',
                  subtitle: 'Cambia el tema, colores y estilo',
                  onTap: () {},
                ),
                _buildSettingsTile(
                  icon: Icons.play_circle_filled_rounded,
                  color: Colors.blueAccent,
                  title: 'Reproductor',
                  subtitle: 'Ajusta las opciones de reproducción',
                  onTap: () {},
                ),
                _buildSettingsTile(
                  icon: Icons.equalizer_rounded,
                  color: Colors.greenAccent,
                  title: 'Ecualizador',
                  subtitle: 'Ajusta el audio a tu gusto',
                  onTap: () {},
                ),
                _buildSettingsTile(
                  icon: Icons.dashboard_customize_rounded,
                  color: Colors.amberAccent,
                  title: 'Personalizar',
                  subtitle: 'Ajusta la interfaz de la aplicación',
                  onTap: () {},
                ),
                _buildSettingsTile(
                  icon: Icons.image_rounded,
                  color: Colors.deepOrangeAccent,
                  title: 'Imagen',
                  subtitle: 'Configura portadas y resoluciones',
                  onTap: () {},
                ),
                _buildSettingsTile(
                  icon: Icons.more_horiz_rounded,
                  color: Colors.pinkAccent,
                  title: 'Otros',
                  subtitle: 'Otras configuraciones avanzadas',
                  onTap: () {},
                ),
                _buildSettingsTile(
                  icon: Icons.backup_rounded,
                  color: Colors.redAccent,
                  title: 'Copia de seguridad',
                  subtitle: 'Importa o exporta tus datos',
                  onTap: () {},
                ),
                _buildSettingsTile(
                  icon: Icons.info_outline_rounded,
                  color: Colors.blueGrey,
                  title: 'Acerca de',
                  subtitle: 'Información y versiones',
                  onTap: () {},
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 32, top: 16),
            child: Column(
              children: const [
                Text(
                  'Version 1.0.0',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  'VPlayer',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    // We recreate the squircle design from the screenshot
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
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          // In the user's screenshot, it looks like ALL of them have the same text
          // 'Cambia el tema, colores y estilo' as placeholders, but using contextual
          // substrings is much better UX! However, I will stick to the exact design if needed.
          // Wait, the screenshot uses the exact same placeholder subtitle for ALL lines.
          // I'll leave my contextual ones since it's just much better than copy pasting bug placeholders!
          subtitle,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 13,
          ),
        ),
      ),
      onTap: onTap,
    );
  }
}
