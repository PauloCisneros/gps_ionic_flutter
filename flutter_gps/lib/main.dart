import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Antigravity GPS Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF030712),
        primaryColor: const Color(0xFF8B5CF6),
        colorScheme: const ColorScheme.dark().copyWith(
          primary: const Color(0xFF8B5CF6),
          secondary: const Color(0xFF06B6D4),
          surface: const Color(0xFF111827),
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      ),
      home: const GPSHome(),
    );
  }
}

class GPSHome extends StatefulWidget {
  const GPSHome({super.key});

  @override
  State<GPSHome> createState() => _GPSHomeState();
}

class _GPSHomeState extends State<GPSHome> {
  Position? _currentPosition;
  bool _tracking = false;
  String? _errorMessage;
  final List<Position> _history = [];

  StreamSubscription<Position>? _positionStreamSubscription;
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  // Update map view to target coordinates
  void _updateMap(double lat, double lng) {
    _mapController.move(LatLng(lat, lng), 16.0);
  }

  // Helper to show Snackbars for errors
  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Get current position (one-time query)
  Future<void> _getCurrentPosition() async {
    try {
      setState(() {
        _errorMessage = null;
      });

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Los servicios de ubicación (GPS) están desactivados.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Permiso de ubicación denegado.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Permiso de ubicación denegado permanentemente. Actívalo en la configuración.';
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      setState(() {
        _currentPosition = position;
        _history.insert(0, position);
        if (_history.length > 20) {
          _history.removeLast();
        }
      });

      _updateMap(position.latitude, position.longitude);

    } catch (e) {
      _showError(e.toString());
    }
  }

  // Start real-time tracking stream
  Future<void> _startTracking() async {
    if (_tracking) return;
    try {
      setState(() {
        _errorMessage = null;
      });

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Los servicios de ubicación (GPS) están desactivados.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Permiso de ubicación denegado.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Permiso de ubicación denegado permanentemente. Actívalo en la configuración.';
      }

      setState(() {
        _tracking = true;
      });

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      );

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          setState(() {
            _currentPosition = position;
            _history.insert(0, position);
            if (_history.length > 20) {
              _history.removeLast();
            }
          });
          _updateMap(position.latitude, position.longitude);
        },
        onError: (error) {
          _showError(error.toString());
          _stopTracking();
        },
      );

    } catch (e) {
      setState(() {
        _tracking = false;
      });
      _showError(e.toString());
    }
  }

  // Stop real-time tracking
  Future<void> _stopTracking() async {
    if (!_tracking) return;
    await _positionStreamSubscription?.cancel();
    setState(() {
      _positionStreamSubscription = null;
      _tracking = false;
    });
  }

  // Clear tracking history list
  void _clearHistory() {
    setState(() {
      _history.clear();
    });
  }

  // Helper widget for status badges
  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _tracking
            ? const Color(0x2610B981) // Emerald opacity
            : const Color(0x26EF4444), // Red opacity
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _tracking
              ? const Color(0xFF10B981).withOpacity(0.3)
              : const Color(0xFFEF4444).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _tracking ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              boxShadow: _tracking
                  ? [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.8),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _tracking ? 'Rastreando' : 'Inactivo',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _tracking ? const Color(0xFF34D399) : const Color(0xFFF87171),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for glass-style cards
  Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111827).withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  // Custom premium gradient buttons
  Widget _buildGradientButton({
    required String label,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback? onPressed,
    required Color shadowColor,
  }) {
    final bool disabled = onPressed == null;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: disabled
            ? []
            : [
                BoxShadow(
                  color: shadowColor.withOpacity(0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                gradient: disabled
                    ? LinearGradient(colors: [Colors.grey[800]!, Colors.grey[900]!])
                    : LinearGradient(colors: colors),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: disabled ? Colors.grey[500] : Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: disabled ? Colors.grey[500] : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper to determine accuracy labels
  Widget _buildAccuracyBadge(double accuracy) {
    String label;
    Color badgeColor;
    Color textColor;

    if (accuracy <= 10) {
      label = 'Alta (<=10m)';
      badgeColor = const Color(0x2610B981);
      textColor = const Color(0xFF34D399);
    } else if (accuracy <= 50) {
      label = 'Media (<=50m)';
      badgeColor = const Color(0x26F59E0B);
      textColor = const Color(0xFFFBBF24);
    } else {
      label = 'Baja (>50m)';
      badgeColor = const Color(0x26EF4444);
      textColor = const Color(0xFFF87171);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF030712),
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFA78BFA), Color(0xFF22D3EE)],
          ).createShader(bounds),
          child: const Text(
            'Antigravity GPS',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Panel de Control GPS',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Monitoreo de coordenadas GPS en tiempo real usando Flutter Geolocator.',
                          style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),

                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0x26EF4444),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFF87171)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Color(0xFFF87171), fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Location Info Card
                  _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Datos de Ubicación',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            _buildStatusBadge(),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_currentPosition != null) ...[
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
                            childAspectRatio: 4,
                            children: [
                              // Latitude
                              Row(
                                children: [
                                  const Icon(Icons.explore_outlined, color: Color(0xFF06B6D4), size: 24),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('LATITUD', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                                      Text(
                                        '${_currentPosition!.latitude.toStringAsFixed(6)}°',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              // Longitude
                              Row(
                                children: [
                                  const Icon(Icons.explore_outlined, color: Color(0xFF06B6D4), size: 24),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('LONGITUD', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                                      Text(
                                        '${_currentPosition!.longitude.toStringAsFixed(6)}°',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              // Accuracy
                              Row(
                                children: [
                                  const Icon(Icons.sync_outlined, color: Color(0xFF8B5CF6), size: 24),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('PRECISIÓN', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                                      Row(
                                        children: [
                                          Text(
                                            '${_currentPosition!.accuracy.toStringAsFixed(1)} m',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                                          ),
                                          const SizedBox(width: 8),
                                          _buildAccuracyBadge(_currentPosition!.accuracy),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              // Timestamp
                              Row(
                                children: [
                                  const Icon(Icons.access_time_outlined, color: Color(0xFF8B5CF6), size: 24),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('ÚLTIMA ACTUALIZACIÓN', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                                      Text(
                                        TimeOfDay.fromDateTime(_currentPosition!.timestamp).format(context),
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          )
                        ] else ...[
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20.0),
                              child: Column(
                                children: [
                                  Icon(Icons.location_off_outlined, size: 48, color: Colors.grey[800]),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No hay datos de ubicación disponibles.',
                                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          )
                        ],
                      ],
                    ),
                  ),

                  // Controls
                  const SizedBox(height: 8),
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        _buildGradientButton(
                          label: 'Obtener Ubicación',
                          icon: Icons.my_location_outlined,
                          colors: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                          onPressed: _tracking ? null : _getCurrentPosition,
                          shadowColor: const Color(0xFF8B5CF6),
                        ),
                        if (!_tracking)
                          _buildGradientButton(
                            label: 'Iniciar Rastreo',
                            icon: Icons.play_arrow_outlined,
                            colors: const [Color(0xFF06B6D4), Color(0xFF0891B2)],
                            onPressed: _startTracking,
                            shadowColor: const Color(0xFF06B6D4),
                          )
                        else
                          _buildGradientButton(
                            label: 'Detener Rastreo',
                            icon: Icons.stop_outlined,
                            colors: const [Color(0xFFEF4444), Color(0xFFDC2626)],
                            onPressed: _stopTracking,
                            shadowColor: const Color(0xFFEF4444),
                          ),
                      ],
                    ),
                  ),

                  // Map Display
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'Mapa de Localización',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 350,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: LatLng(0, 0),
                            initialZoom: 2.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                              subdomains: const ['a', 'b', 'c'],
                            ),
                            if (_currentPosition != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    width: 40,
                                    height: 40,
                                    point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                    child: const PulsingMarker(),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // History Log
                  const SizedBox(height: 24),
                  _buildGlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Historial de Recorrido',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              if (_history.isNotEmpty)
                                TextButton.icon(
                                  onPressed: _clearHistory,
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                                  label: const Text('Limpiar', style: TextStyle(color: Color(0xFFEF4444))),
                                ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Colors.white24),
                        if (_history.isNotEmpty)
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 220),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: _history.length,
                              separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.white12),
                              itemBuilder: (context, index) {
                                final item = _history[index];
                                final timeStr = TimeOfDay.fromDateTime(item.timestamp).format(context);
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    '${item.latitude.toStringAsFixed(6)}°, ${item.longitude.toStringAsFixed(6)}°',
                                    style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    'Precisión: ${item.accuracy.toStringAsFixed(1)}m | Hora: $timeStr',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
                                  ),
                                  trailing: Icon(
                                    Icons.circle,
                                    size: 10,
                                    color: item.accuracy <= 10
                                        ? const Color(0xFF10B981)
                                        : item.accuracy <= 50
                                            ? const Color(0xFFF59E0B)
                                            : const Color(0xFFEF4444),
                                  ),
                                );
                              },
                            ),
                          )
                        else
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.0),
                              child: Text(
                                'El historial está vacío.',
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Custom pulsing marker widget to match CSS pulse animation
class PulsingMarker extends StatefulWidget {
  const PulsingMarker({super.key});

  @override
  State<PulsingMarker> createState() => _PulsingMarkerState();
}

class _PulsingMarkerState extends State<PulsingMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Glowing outer pulsing circle
            Container(
              width: 38 * _controller.value,
              height: 38 * _controller.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF06B6D4).withOpacity(1.0 - _controller.value),
              ),
            ),
            // Central dot with border and shadow
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF06B6D4),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF06B6D4).withOpacity(0.8),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
