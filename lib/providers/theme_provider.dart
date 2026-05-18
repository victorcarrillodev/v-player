import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class _CustomTickerProvider extends TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

enum ColorPaletteType { solid, gradient, neon, changing }

class PaletteItem {
  final String name;
  final Color primary;
  final Color accent;
  final LinearGradient? gradient;
  final Color? glowColor;

  const PaletteItem({
    required this.name,
    required this.primary,
    required this.accent,
    this.gradient,
    this.glowColor,
  });
}

class ChangingPaletteSequence {
  final String name;
  final List<Color> primarySequence;
  final List<Color> accentSequence;

  const ChangingPaletteSequence({
    required this.name,
    required this.primarySequence,
    required this.accentSequence,
  });
}

class ThemeProvider extends ChangeNotifier {
  SharedPreferences? _prefs;
  
  bool _isDarkMode = true;
  bool _dynamicColors = false;
  bool _animationsEnabled = true;
  bool _showBottomNavLabels = true;
  double _artworkBorderRadius = 12.0;
  bool _enableGlassmorphism = true;
  ColorPaletteType _paletteType = ColorPaletteType.solid;
  int _selectedPaletteIndex = 0;

  // Variables para la animación de "Colores Cambiantes"
  Timer? _changingTimer;
  int _changingStep = 0;
  Color? _currentChangingPrimary;
  Color? _currentChangingAccent;
  
  late final _CustomTickerProvider _tickerProvider;
  late final AnimationController _colorAnimController;
  late Animation<Color?> _primaryColorAnim;
  late Animation<Color?> _accentColorAnim;

  // ==== DEFINICIÓN DE PALETAS (Minimo 20 cada uno) ====

  static const List<PaletteItem> solidPalettes = [
    PaletteItem(name: 'Naranja Clásico', primary: Color(0xFFFF5722), accent: Color(0xFFFFB300)),
    PaletteItem(name: 'Azul Océano', primary: Color(0xFF1976D2), accent: Color(0xFF64B5F6)),
    PaletteItem(name: 'Rojo Carmesí', primary: Color(0xFFD32F2F), accent: Color(0xFFFF5252)),
    PaletteItem(name: 'Verde Esmeralda', primary: Color(0xFF388E3C), accent: Color(0xFF69F0AE)),
    PaletteItem(name: 'Morado Real', primary: Color(0xFF7B1FA2), accent: Color(0xFFE040FB)),
    PaletteItem(name: 'Rosa Chicle', primary: Color(0xFFE91E63), accent: Color(0xFFFF80AB)),
    PaletteItem(name: 'Amarillo Sol', primary: Color(0xFFFBC02D), accent: Color(0xFFFFF59D)),
    PaletteItem(name: 'Cian Profundo', primary: Color(0xFF0097A7), accent: Color(0xFF18FFFF)),
    PaletteItem(name: 'Gris Carbón', primary: Color(0xFF424242), accent: Color(0xFF9E9E9E)),
    PaletteItem(name: 'Marrón Tierra', primary: Color(0xFF795548), accent: Color(0xFFD7CCC8)),
    PaletteItem(name: 'Azul Marino', primary: Color(0xFF1A237E), accent: Color(0xFF5C6BC0)),
    PaletteItem(name: 'Verde Lima', primary: Color(0xFFAFEA00), accent: Color(0xFFEEFF41)),
    PaletteItem(name: 'Naranja Óxido', primary: Color(0xFFE64A19), accent: Color(0xFFFF8A65)),
    PaletteItem(name: 'Índigo Místico', primary: Color(0xFF303F9F), accent: Color(0xFF7986CB)),
    PaletteItem(name: 'Lavanda', primary: Color(0xFF9575CD), accent: Color(0xFFD1C4E9)),
    PaletteItem(name: 'Menta', primary: Color(0xFF00BFA5), accent: Color(0xFF64FFDA)),
    PaletteItem(name: 'Ámbar Brillante', primary: Color(0xFFFF8F00), accent: Color(0xFFFFD54F)),
    PaletteItem(name: 'Rosa Fucsia', primary: Color(0xFFC2185B), accent: Color(0xFFF48FB1)),
    PaletteItem(name: 'Azul Acero', primary: Color(0xFF455A64), accent: Color(0xFF90A4AE)),
    PaletteItem(name: 'Oliva Oscuro', primary: Color(0xFF689F38), accent: Color(0xFFAED581)),
  ];

  static final List<PaletteItem> gradientPalettes = [
    _buildGradient('Ocaso', const Color(0xFFFF512F), const Color(0xFFDD2476)),
    _buildGradient('Aurora', const Color(0xFF00C9FF), const Color(0xFF92FE9D)),
    _buildGradient('Galaxia', const Color(0xFF654ea3), const Color(0xFFeaafc8)),
    _buildGradient('Bosque', const Color(0xFF11998e), const Color(0xFF38ef7d)),
    _buildGradient('Mango', const Color(0xFFffe259), const Color(0xFFffa751)),
    _buildGradient('Fuego', const Color(0xFFf12711), const Color(0xFFf5af19)),
    _buildGradient('Océano', const Color(0xFF2193b0), const Color(0xFF6dd5ed)),
    _buildGradient('Amatista', const Color(0xFF9D50BB), const Color(0xFF6E48AA)),
    _buildGradient('Cereza', const Color(0xFFEB3349), const Color(0xFFF45C43)),
    _buildGradient('Hielo', const Color(0xFF1c92d2), const Color(0xFFf2fcfe)),
    _buildGradient('Melón', const Color(0xFFff9966), const Color(0xFFff5e62)),
    _buildGradient('Uva', const Color(0xFF4b6cb7), const Color(0xFF182848)),
    _buildGradient('Medianoche', const Color(0xFF232526), const Color(0xFF414345)),
    _buildGradient('Cítrico', const Color(0xFFFDC830), const Color(0xFFF37335)),
    _buildGradient('Algodón', const Color(0xFFffc3a0), const Color(0xFFffafbd)),
    _buildGradient('Plasma', const Color(0xFF8E2DE2), const Color(0xFF4A00E0)),
    _buildGradient('Jade', const Color(0xFF000000), const Color(0xFF0f9b0f)), // Dark to green
    _buildGradient('Coral', const Color(0xFFff9a9e), const Color(0xFFfecfef)),
    _buildGradient('Tierra', const Color(0xFFe52d27), const Color(0xFFb31217)),
    _buildGradient('Cósmico', const Color(0xFFff00cc), const Color(0xFF333399)),
  ];

  static PaletteItem _buildGradient(String name, Color c1, Color c2) {
    return PaletteItem(
      name: name,
      primary: c1,
      accent: c2,
      gradient: LinearGradient(colors: [c1, c2], begin: Alignment.topLeft, end: Alignment.bottomRight),
    );
  }

  static const List<PaletteItem> neonPalettes = [
    PaletteItem(name: 'Cyberpunk Rosa', primary: Color(0xFFFF00FF), accent: Color(0xFF00FFFF), glowColor: Color(0xFFFF00FF)),
    PaletteItem(name: 'Verde Tóxico', primary: Color(0xFF39FF14), accent: Color(0xFF00FF00), glowColor: Color(0xFF39FF14)),
    PaletteItem(name: 'Azul Eléctrico', primary: Color(0xFF00F0FF), accent: Color(0xFF0000FF), glowColor: Color(0xFF00F0FF)),
    PaletteItem(name: 'Naranja Láser', primary: Color(0xFFFF3131), accent: Color(0xFFFF6600), glowColor: Color(0xFFFF3131)),
    PaletteItem(name: 'Morado Sintético', primary: Color(0xFFBF00FF), accent: Color(0xFFFF00FF), glowColor: Color(0xFFBF00FF)),
    PaletteItem(name: 'Rojo Sangre Neón', primary: Color(0xFFFF0000), accent: Color(0xFFFF3333), glowColor: Color(0xFFFF0000)),
    PaletteItem(name: 'Cian Hacker', primary: Color(0xFF00FFFF), accent: Color(0xFF00FFCC), glowColor: Color(0xFF00FFFF)),
    PaletteItem(name: 'Amarillo Radiactivo', primary: Color(0xFFFFFF00), accent: Color(0xFFCCFF00), glowColor: Color(0xFFFFFF00)),
    PaletteItem(name: 'Rosa Fuerte Neón', primary: Color(0xFFFF1493), accent: Color(0xFFFF69B4), glowColor: Color(0xFFFF1493)),
    PaletteItem(name: 'Azul Hielo Neón', primary: Color(0xFF82CAFF), accent: Color(0xFF00BFFF), glowColor: Color(0xFF82CAFF)),
    PaletteItem(name: 'Verde Matriz', primary: Color(0xFF00FF41), accent: Color(0xFF008F11), glowColor: Color(0xFF00FF41)),
    PaletteItem(name: 'Morado UV', primary: Color(0xFF9D00FF), accent: Color(0xFF6A0DAD), glowColor: Color(0xFF9D00FF)),
    PaletteItem(name: 'Mandarina Neón', primary: Color(0xFFFF9900), accent: Color(0xFFFF6600), glowColor: Color(0xFFFF9900)),
    PaletteItem(name: 'Lima Flúor', primary: Color(0xFFBFFF00), accent: Color(0xFF99FF00), glowColor: Color(0xFFBFFF00)),
    PaletteItem(name: 'Azul Neón Oscuro', primary: Color(0xFF1B03A3), accent: Color(0xFF3A0CA3), glowColor: Color(0xFF3A0CA3)),
    PaletteItem(name: 'Rojo Carmín Neón', primary: Color(0xFFE60000), accent: Color(0xFFFF1A1A), glowColor: Color(0xFFE60000)),
    PaletteItem(name: 'Orquídea Neón', primary: Color(0xFFDA70D6), accent: Color(0xFFFF83FA), glowColor: Color(0xFFDA70D6)),
    PaletteItem(name: 'Aqua Brillante', primary: Color(0xFF00FFFF), accent: Color(0xFF7FFFD4), glowColor: Color(0xFF00FFFF)),
    PaletteItem(name: 'Magenta Pulsante', primary: Color(0xFFFF0090), accent: Color(0xFFD10074), glowColor: Color(0xFFFF0090)),
    PaletteItem(name: 'Plata Luminosa', primary: Color(0xFFE0E0E0), accent: Color(0xFFFFFFFF), glowColor: Color(0xFFFFFFFF)),
  ];

  static final List<ChangingPaletteSequence> changingPalettes = [
    _buildChanging('Arcoíris Lento', [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.purple]),
    _buildChanging('Luces de Neón', [const Color(0xFFFF00FF), const Color(0xFF00FFFF), const Color(0xFF39FF14)]),
    _buildChanging('Océano Profundo', [const Color(0xFF000080), const Color(0xFF0000CD), const Color(0xFF0000FF), const Color(0xFF00BFFF)]),
    _buildChanging('Atardecer', [const Color(0xFFFF4500), const Color(0xFFFF8C00), const Color(0xFFFFD700), const Color(0xFFFF69B4)]),
    _buildChanging('Bosque Encantado', [const Color(0xFF228B22), const Color(0xFF32CD32), const Color(0xFF00FF7F), const Color(0xFFADFF2F)]),
    _buildChanging('Fuego Ardiente', [const Color(0xFFFF0000), const Color(0xFFFF4500), const Color(0xFFFF8C00), const Color(0xFFB22222)]),
    _buildChanging('Aurora Boreal', [const Color(0xFF00FF00), const Color(0xFF00FA9A), const Color(0xFF48D1CC), const Color(0xFF00FFFF)]),
    _buildChanging('Galaxia Lejana', [const Color(0xFF4B0082), const Color(0xFF8A2BE2), const Color(0xFF9400D3), const Color(0xFF9932CC)]),
    _buildChanging('Algodón de Azúcar', [const Color(0xFFFFB6C1), const Color(0xFFFFC0CB), const Color(0xFF87CEFA), const Color(0xFFB0E0E6)]),
    _buildChanging('Café Tostado', [const Color(0xFF8B4513), const Color(0xFFA0522D), const Color(0xFFD2691E), const Color(0xFFCD853F)]),
    _buildChanging('Cítricos Frescos', [const Color(0xFFFFA500), const Color(0xFFFFFF00), const Color(0xFF9ACD32), const Color(0xFF32CD32)]),
    _buildChanging('Hielo Ártico', [const Color(0xFFF0F8FF), const Color(0xFFE0FFFF), const Color(0xFFAFEEEE), const Color(0xFFB0E0E6)]),
    _buildChanging('Magia Púrpura', [const Color(0xFF800080), const Color(0xFF8B008B), const Color(0xFFDA70D6), const Color(0xFFD8BFD8)]),
    _buildChanging('Desierto Cálido', [const Color(0xFFF4A460), const Color(0xFFD2B48C), const Color(0xFFDEB887), const Color(0xFFF5DEB3)]),
    _buildChanging('Sueño Rosa', [const Color(0xFFFF1493), const Color(0xFFFF69B4), const Color(0xFFFFC0CB), const Color(0xFFDB7093)]),
    _buildChanging('Cielo Despejado', [const Color(0xFF00BFFF), const Color(0xFF1E90FF), const Color(0xFF4169E1), const Color(0xFF87CEEB)]),
    _buildChanging('Primavera', [const Color(0xFF00FF00), const Color(0xFF7FFF00), const Color(0xFFFF69B4), const Color(0xFFFFA500)]),
    _buildChanging('Otoño', [const Color(0xFF8B0000), const Color(0xFFA52A2A), const Color(0xFFD2691E), const Color(0xFFDAA520)]),
    _buildChanging('Noche Estrellada', [const Color(0xFF000080), const Color(0xFF191970), const Color(0xFF483D8B), const Color(0xFF4169E1)]),
    _buildChanging('Metal Líquido', [const Color(0xFF808080), const Color(0xFFA9A9A9), const Color(0xFFC0C0C0), const Color(0xFFD3D3D3)]),
  ];

  static ChangingPaletteSequence _buildChanging(String name, List<Color> colors) {
    return ChangingPaletteSequence(
      name: name,
      primarySequence: colors,
      accentSequence: colors.reversed.toList(),
    );
  }

  // Getters
  bool get isDarkMode => _isDarkMode;
  bool get dynamicColors => _dynamicColors;
  bool get animationsEnabled => _animationsEnabled;
  bool get showBottomNavLabels => _showBottomNavLabels;
  double get artworkBorderRadius => _artworkBorderRadius;
  bool get enableGlassmorphism => _enableGlassmorphism;
  ColorPaletteType get paletteType => _paletteType;
  int get selectedPaletteIndex => _selectedPaletteIndex;

  ThemeProvider() {
    _tickerProvider = _CustomTickerProvider();
    _colorAnimController = AnimationController(vsync: _tickerProvider, duration: const Duration(seconds: 4));
    _colorAnimController.addListener(() {
      _currentChangingPrimary = _primaryColorAnim.value;
      _currentChangingAccent = _accentColorAnim.value;
      notifyListeners();
    });
    
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs!.getBool('isDarkMode') ?? true;
    _dynamicColors = _prefs!.getBool('dynamicColors') ?? false;
    _animationsEnabled = _prefs!.getBool('animationsEnabled') ?? true;
    _showBottomNavLabels = _prefs!.getBool('showBottomNavLabels') ?? true;
    _artworkBorderRadius = _prefs!.getDouble('artworkBorderRadius') ?? 12.0;
    _enableGlassmorphism = _prefs!.getBool('enableGlassmorphism') ?? true;
    
    int pType = _prefs!.getInt('paletteType') ?? 0;
    if (pType >= 0 && pType < ColorPaletteType.values.length) {
      _paletteType = ColorPaletteType.values[pType];
    }
    _selectedPaletteIndex = _prefs!.getInt('selectedPaletteIndex') ?? 0;
    
    _updateTimer();
    notifyListeners();
  }

  void toggleDarkMode(bool val) {
    _isDarkMode = val;
    _prefs?.setBool('isDarkMode', val);
    notifyListeners();
  }

  void toggleDynamicColors(bool val) {
    _dynamicColors = val;
    _prefs?.setBool('dynamicColors', val);
    notifyListeners();
  }

  void toggleAnimations(bool val) {
    _animationsEnabled = val;
    _prefs?.setBool('animationsEnabled', val);
    notifyListeners();
  }

  void toggleBottomNavLabels(bool val) {
    _showBottomNavLabels = val;
    _prefs?.setBool('showBottomNavLabels', val);
    notifyListeners();
  }

  void setArtworkBorderRadius(double val) {
    _artworkBorderRadius = val;
    _prefs?.setDouble('artworkBorderRadius', val);
    notifyListeners();
  }

  void toggleGlassmorphism(bool val) {
    _enableGlassmorphism = val;
    _prefs?.setBool('enableGlassmorphism', val);
    notifyListeners();
  }

  void setPaletteType(ColorPaletteType type) {
    _paletteType = type;
    _selectedPaletteIndex = 0; // Reset index when changing type
    _prefs?.setInt('paletteType', type.index);
    _prefs?.setInt('selectedPaletteIndex', 0);
    _updateTimer();
    notifyListeners();
  }

  void setPaletteIndex(int index) {
    _selectedPaletteIndex = index;
    _prefs?.setInt('selectedPaletteIndex', index);
    _updateTimer();
    notifyListeners();
  }

  void _updateTimer() {
    _changingTimer?.cancel();
    if (_paletteType == ColorPaletteType.changing && !_dynamicColors) {
      _changingStep = 0;
      // Iniciar primera secuencia inmediatamente
      _tickChangingColor(initial: true);
      _changingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        _tickChangingColor();
      });
    } else {
      _colorAnimController.stop();
      _currentChangingPrimary = null;
      _currentChangingAccent = null;
    }
  }

  void _tickChangingColor({bool initial = false}) {
    if (_selectedPaletteIndex < 0 || _selectedPaletteIndex >= changingPalettes.length) return;
    final seq = changingPalettes[_selectedPaletteIndex];
    
    final nextPrimary = seq.primarySequence[_changingStep % seq.primarySequence.length];
    final nextAccent = seq.accentSequence[_changingStep % seq.accentSequence.length];
    
    if (initial || _currentChangingPrimary == null) {
      _currentChangingPrimary = nextPrimary;
      _currentChangingAccent = nextAccent;
    } else {
      _primaryColorAnim = ColorTween(begin: _currentChangingPrimary, end: nextPrimary).animate(
        CurvedAnimation(parent: _colorAnimController, curve: Curves.easeInOut),
      );
      _accentColorAnim = ColorTween(begin: _currentChangingAccent, end: nextAccent).animate(
        CurvedAnimation(parent: _colorAnimController, curve: Curves.easeInOut),
      );
      _colorAnimController.forward(from: 0.0);
    }
    
    _changingStep++;
    if (initial) notifyListeners();
  }

  @override
  void dispose() {
    _changingTimer?.cancel();
    _colorAnimController.dispose();
    super.dispose();
  }

  // Genera el AppColors actual en base al estado
  AppColors get currentColors {
    // Si estamos en modo dinámico, idealmente obtendríamos los colores desde un Album/Song.
    // Como eso requeriría escuchar al reproductor de música aquí o pasarlo, lo manejaremos 
    // proveyendo un método para sobreescribir temporalmente, o podemos omitirlo y hacerlo a nivel
    // widget. Por ahora definiremos los colores base de la paleta.

    Color basePrimary = const Color(0xFFFF5722);
    Color baseAccent = const Color(0xFFFFB300);
    LinearGradient? currentGradient;
    Color? currentGlow;

    if (_paletteType == ColorPaletteType.solid) {
      if (_selectedPaletteIndex < solidPalettes.length) {
        final p = solidPalettes[_selectedPaletteIndex];
        basePrimary = p.primary;
        baseAccent = p.accent;
      }
    } else if (_paletteType == ColorPaletteType.gradient) {
      if (_selectedPaletteIndex < gradientPalettes.length) {
        final p = gradientPalettes[_selectedPaletteIndex];
        basePrimary = p.primary;
        baseAccent = p.accent;
        currentGradient = p.gradient;
      }
    } else if (_paletteType == ColorPaletteType.neon) {
      if (_selectedPaletteIndex < neonPalettes.length) {
        final p = neonPalettes[_selectedPaletteIndex];
        basePrimary = p.primary;
        baseAccent = p.accent;
        currentGlow = p.glowColor;
      }
    } else if (_paletteType == ColorPaletteType.changing) {
      if (_currentChangingPrimary != null && _currentChangingAccent != null) {
        basePrimary = _currentChangingPrimary!;
        baseAccent = _currentChangingAccent!;
      }
    }

    // Calcular fondos dependiendo del modo oscuro
    Color background = _isDarkMode ? const Color(0xFF141723) : const Color(0xFFF0F2F5);
    Color surface = _isDarkMode ? const Color(0xFF1C1E2D) : const Color(0xFFFFFFFF);
    Color surfaceVariant = _isDarkMode ? const Color(0xFF26293D) : const Color(0xFFE0E0E0);
    Color onSurface = _isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF121212);
    Color onSurfaceMuted = _isDarkMode ? const Color(0xFF8E92A3) : const Color(0xFF757575);

    // Si es tipo neón, oscurecemos un poco más los fondos para que resalte
    if (_paletteType == ColorPaletteType.neon && _isDarkMode) {
      background = const Color(0xFF0A0A0F);
      surface = const Color(0xFF12121A);
      surfaceVariant = const Color(0xFF1C1C26);
    }

    return AppColors(
      background: background,
      surface: surface,
      surfaceVariant: surfaceVariant,
      primary: basePrimary,
      accent: baseAccent,
      onSurface: onSurface,
      onSurfaceMuted: onSurfaceMuted,
      cardGlow: currentGlow?.withValues(alpha: 0.3) ?? basePrimary.withValues(alpha: 0.3),
      primaryGradient: currentGradient ?? LinearGradient(
        colors: [basePrimary, baseAccent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      isNeon: _paletteType == ColorPaletteType.neon,
      neonGlow: currentGlow,
    );
  }
}
