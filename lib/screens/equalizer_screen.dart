import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../theme/app_theme.dart';

class EqPreset {
  final String name;
  final List<double> gains; // Based on 5 bands
  EqPreset(this.name, this.gains);
}

final List<EqPreset> defaultPresets = [
  EqPreset('Normal', [0.0, 0.0, 0.0, 0.0, 0.0]),
  EqPreset('Bass', [6.0, 4.0, 0.0, -2.0, -4.0]),
  EqPreset('Rock', [5.0, 3.0, -1.0, 3.0, 5.0]),
  EqPreset('Pop', [-2.0, 2.0, 4.0, 2.0, -2.0]),
  EqPreset('Vocal', [-2.0, 0.0, 4.0, 3.0, 1.0]),
  EqPreset('Electro', [5.0, 4.0, -2.0, 2.0, 4.0]),
];

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  String _selectedPreset = 'Custom';
  AndroidEqualizerParameters? _params;
  
  List<double> _baseGains = [];
  double _bassBoostLevel = 0.0;
  bool _initialized = false;

  void _initGains(AndroidEqualizerParameters params) {
    if (!_initialized) {
      _baseGains = params.bands.map((b) => b.gain).toList();
      _initialized = true;
    }
  }

  void _updateNativeGains() {
    if (_params == null) return;
    for (int i = 0; i < _params!.bands.length; i++) {
      double totalGain = _baseGains[i];
      
      // Add independent Bass Boost macro mathematically
      if (i == 0) {
        totalGain += (_bassBoostLevel / 100.0) * _params!.maxDecibels;
      } else if (i == 1) {
        totalGain += ((_bassBoostLevel / 100.0) * _params!.maxDecibels) * 0.5;
      }

      if (totalGain > _params!.maxDecibels) totalGain = _params!.maxDecibels;
      if (totalGain < _params!.minDecibels) totalGain = _params!.minDecibels;

      _params!.bands[i].setGain(totalGain);
    }
  }

  void _applyPreset(EqPreset preset) {
    if (_params == null) return;
    setState(() {
      _selectedPreset = preset.name;
      for (int i = 0; i < _params!.bands.length; i++) {
        if (i < preset.gains.length) {
          _baseGains[i] = preset.gains[i];
        }
      }
    });
    _updateNativeGains();
  }

  void _applyBassBoost(double value) {
    setState(() {
      _bassBoostLevel = value;
    });
    _updateNativeGains();
  }

  String _formatFrequency(double hz) {
    if (hz >= 1000) {
      double k = hz / 1000;
      return k == k.toInt() ? '${k.toInt()}k' : '${k.toStringAsFixed(1)}k';
    }
    return '${hz.toInt()}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final musicProvider = context.read<MusicProvider>();
    final equalizer = musicProvider.equalizer;
    final loudnessEnhancer = musicProvider.loudnessEnhancer;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Ecualizador Studio'),
        centerTitle: true,
      ),
      body: !Platform.isAndroid
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'El ecualizador nativo solo está disponible en dispositivos Android.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.onSurfaceMuted, fontSize: 16),
                ),
              ),
            )
          : FutureBuilder<AndroidEqualizerParameters>(
              future: equalizer.parameters,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Ecualizador no disponible.\n(Asegúrate de ejecutar en Android)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.onSurfaceMuted),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: colors.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Conectando al motor DSP...',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.onSurfaceMuted),
                        ),
                      ],
                    ),
                  );
                }

                _params = snapshot.data!;
                _initGains(_params!);

                return StreamBuilder<bool>(
                  stream: equalizer.enabledStream,
                  initialData: false,
                  builder: (context, enabledSnapshot) {
                    final active = enabledSnapshot.data ?? false;

                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // Control de Energía
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: colors.surfaceVariant.withValues(alpha: 0.5)),
                            ),
                            child: SwitchListTile(
                              title: Text(
                                'Power',
                                style: TextStyle(
                                    color: active ? colors.primary : colors.onSurface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18),
                              ),
                              subtitle: Text(
                                active ? 'Procesamiento activo' : 'Bypass (Audio puro)',
                                style: TextStyle(color: colors.onSurfaceMuted),
                              ),
                              value: active,
                              activeTrackColor: colors.primary,
                              secondary: Icon(
                                Icons.power_settings_new_rounded,
                                color: active ? colors.primary : colors.onSurfaceMuted,
                                size: 32,
                              ),
                              onChanged: (value) async {
                                await equalizer.setEnabled(value);
                                await loudnessEnhancer.setEnabled(value); // Synchronize effects
                              },
                            ),
                          ),
                        ),
                        
                        // Lista de Presets
                        SizedBox(
                          height: 45,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: defaultPresets.length,
                            itemBuilder: (context, index) {
                              final preset = defaultPresets[index];
                              final isSelected = _selectedPreset == preset.name;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(preset.name),
                                  selected: isSelected,
                                  onSelected: active ? (selected) {
                                    if (selected) {
                                      _applyPreset(preset);
                                    }
                                  } : null,
                                  selectedColor: colors.primary.withValues(alpha: 0.2),
                                  labelStyle: TextStyle(
                                    color: isSelected ? colors.primary : colors.onSurfaceMuted,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  backgroundColor: colors.surface,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: isSelected ? colors.primary : colors.surfaceVariant.withValues(alpha: 0.3),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Faders de la Consola
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: active ? 1.0 : 0.4,
                          child: IgnorePointer(
                            ignoring: !active,
                            child: Container(
                              height: 300,
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              padding: const EdgeInsets.only(top: 24, bottom: 16, left: 8, right: 8),
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  )
                                ],
                                border: Border.all(color: colors.surfaceVariant.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: _params!.bands.asMap().entries.map((entry) {
                                  int index = entry.key;
                                  AndroidEqualizerBand band = entry.value;
                                  return _buildFader(band, index, colors);
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Efectos Adicionales
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: active ? 1.0 : 0.4,
                          child: IgnorePointer(
                            ignoring: !active,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                                    child: Text(
                                      'EFECTOS ADICIONALES',
                                      style: TextStyle(
                                        color: colors.onSurfaceMuted,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                  // Loudness Enhancer
                                  Container(
                                    decoration: BoxDecoration(
                                      color: colors.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: colors.surfaceVariant.withValues(alpha: 0.3)),
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Aumento de Volumen',
                                              style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.bold),
                                            ),
                                            StreamBuilder<double>(
                                              stream: loudnessEnhancer.targetGainStream,
                                              initialData: loudnessEnhancer.targetGain,
                                              builder: (context, gainSnapshot) {
                                                return Text(
                                                  '+${(gainSnapshot.data ?? 0).toStringAsFixed(1)} dB',
                                                  style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        StreamBuilder<double>(
                                          stream: loudnessEnhancer.targetGainStream,
                                          initialData: loudnessEnhancer.targetGain,
                                          builder: (context, gainSnapshot) {
                                            return SliderTheme(
                                              data: SliderThemeData(
                                                activeTrackColor: colors.primary,
                                                inactiveTrackColor: colors.background,
                                                thumbColor: colors.primary,
                                                overlayColor: colors.primary.withValues(alpha: 0.2),
                                              ),
                                              child: Slider(
                                                min: 0.0,
                                                max: 15.0, // Limite seguro de aumento
                                                value: (gainSnapshot.data ?? 0).clamp(0.0, 15.0),
                                                onChanged: (value) {
                                                  loudnessEnhancer.setTargetGain(value);
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Bass Boost Macro Independent
                                  Container(
                                    decoration: BoxDecoration(
                                      color: colors.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: colors.surfaceVariant.withValues(alpha: 0.3)),
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Bass Boost (Graves)',
                                              style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              '${_bassBoostLevel.toInt()}%',
                                              style: TextStyle(color: colors.accent, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        SliderTheme(
                                          data: SliderThemeData(
                                            activeTrackColor: colors.accent,
                                            inactiveTrackColor: colors.background,
                                            thumbColor: colors.accent,
                                            overlayColor: colors.accent.withValues(alpha: 0.2),
                                          ),
                                          child: Slider(
                                            min: 0.0,
                                            max: 100.0,
                                            value: _bassBoostLevel.clamp(0.0, 100.0),
                                            onChanged: _applyBassBoost,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildFader(AndroidEqualizerBand band, int index, AppColors colors) {
    // Gradiente de color según la frecuencia (graves a agudos)
    final progress = index / (_params!.bands.length - 1);
    final thumbColor = Color.lerp(colors.accent, colors.primary, progress) ?? colors.primary;
    final displayGain = _baseGains[index];

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pantalla Digital de dB
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: colors.surfaceVariant.withValues(alpha: 0.3)),
            ),
            child: Text(
              '${displayGain > 0 ? '+' : ''}${displayGain.toStringAsFixed(1)}',
              style: TextStyle(
                color: thumbColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Slider Vertical
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 8,
                  activeTrackColor: thumbColor.withValues(alpha: 0.6),
                  inactiveTrackColor: colors.background,
                  thumbColor: thumbColor,
                  overlayColor: thumbColor.withValues(alpha: 0.2),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 4),
                  trackShape: const RoundedRectSliderTrackShape(),
                ),
                child: Slider(
                  min: _params!.minDecibels,
                  max: _params!.maxDecibels,
                  value: displayGain,
                  onChanged: (value) {
                    setState(() {
                      _baseGains[index] = value;
                      _selectedPreset = 'Custom';
                    });
                    _updateNativeGains();
                  },
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          // Etiqueta de Hz
          Text(
            _formatFrequency(band.centerFrequency),
            style: TextStyle(
              color: colors.onSurfaceMuted,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
