import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const GpsApp());
}

class GpsApp extends StatelessWidget {
  const GpsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GPS Flutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF155EEF),
          primary: const Color(0xFF155EEF),
          secondary: const Color(0xFF0F766E),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F8FB),
        useMaterial3: true,
      ),
      home: const GpsHomePage(),
    );
  }
}

class GpsHomePage extends StatefulWidget {
  const GpsHomePage({super.key});

  @override
  State<GpsHomePage> createState() => _GpsHomePageState();
}

class _GpsHomePageState extends State<GpsHomePage> {
  final LocationSettings _locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 1,
    timeLimit: Duration(seconds: 15),
  );

  StreamSubscription<Position>? _positionSubscription;
  Position? _position;
  LocationPermission? _permission;
  GpsError? _error;
  bool _isLoading = false;

  bool get _isWatching => _positionSubscription != null;

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<bool> _ensureGpsReady() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      setState(() {
        _error = const GpsError(
          title: 'GPS desactivado',
          detail: 'Enciende los servicios de ubicacion y vuelve a intentarlo.',
        );
      });
      return false;
    }

    var permission = await Geolocator.checkPermission();
    setState(() => _permission = permission);

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      setState(() => _permission = permission);
    }

    if (permission == LocationPermission.denied) {
      setState(() {
        _error = const GpsError(
          title: 'Permiso de ubicacion denegado',
          detail: 'La app necesita permiso para mostrar coordenadas GPS.',
        );
      });
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _error = const GpsError(
          title: 'Permiso denegado permanentemente',
          detail: 'Activa el permiso de ubicacion desde los ajustes del dispositivo.',
        );
      });
      return false;
    }

    return true;
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final ready = await _ensureGpsReady();
      if (!ready) return;

      final current = await Geolocator.getCurrentPosition(
        locationSettings: _locationSettings,
      );

      setState(() {
        _position = current;
        _error = null;
      });
    } on TimeoutException {
      setState(() {
        _error = const GpsError(
          title: 'Tiempo de espera agotado',
          detail: 'No se recibieron coordenadas a tiempo. Prueba con mejor senal.',
        );
      });
    } on LocationServiceDisabledException {
      setState(() {
        _error = const GpsError(
          title: 'GPS desactivado',
          detail: 'Enciende los servicios de ubicacion y vuelve a intentarlo.',
        );
      });
    } on PermissionDeniedException {
      setState(() {
        _error = const GpsError(
          title: 'Permiso requerido',
          detail: 'La app no puede acceder a la ubicacion sin permiso.',
        );
      });
    } catch (error) {
      setState(() {
        _error = GpsError(
          title: 'No se pudo leer el GPS',
          detail: error.toString(),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _startWatching() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final ready = await _ensureGpsReady();
      if (!ready) return;

      final stream = Geolocator.getPositionStream(
        locationSettings: _locationSettings,
      );

      final subscription = stream.listen(
        (position) {
          setState(() {
            _position = position;
            _error = null;
          });
        },
        onError: (Object error) {
          setState(() {
            _error = GpsError(
              title: 'Error en seguimiento',
              detail: error.toString(),
            );
          });
        },
      );

      setState(() => _positionSubscription = subscription);
    } catch (error) {
      setState(() {
        _error = GpsError(
          title: 'No se pudo iniciar el seguimiento',
          detail: error.toString(),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _stopWatching() async {
    await _positionSubscription?.cancel();
    setState(() => _positionSubscription = null);
  }

  String get _permissionLabel {
    switch (_permission) {
      case LocationPermission.always:
        return 'Siempre concedido';
      case LocationPermission.whileInUse:
        return 'Concedido en uso';
      case LocationPermission.denied:
        return 'Denegado';
      case LocationPermission.deniedForever:
        return 'Denegado permanente';
      case LocationPermission.unableToDetermine:
        return 'No determinado';
      case null:
        return 'Sin consultar';
    }
  }

  String get _lastUpdate {
    final position = _position;
    if (position == null) return 'Sin lectura todavia';
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(position.timestamp);
  }

  String? get _mapsUrl {
    final position = _position;
    if (position == null) return null;
    return 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS Flutter'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              label: Text(_isWatching ? 'En vivo' : 'Manual'),
              backgroundColor: _isWatching
                  ? colorScheme.secondaryContainer
                  : colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
        bottom: _isLoading ? const PreferredSize(
          preferredSize: Size.fromHeight(4),
          child: LinearProgressIndicator(),
        ) : null,
      ),
      body: ListView(
        children: [
          _HeroPanel(
            onGetLocation: _isLoading ? null : _getCurrentLocation,
            onToggleWatch: _isLoading
                ? null
                : (_isWatching ? _stopWatching : _startWatching),
            isWatching: _isWatching,
          ),
          if (_error != null)
            _ErrorCard(error: _error!),
          _LocationCard(
            position: _position,
            permissionLabel: _permissionLabel,
            lastUpdate: _lastUpdate,
            mapsUrl: _mapsUrl,
          ),
        ],
      ),
      bottomNavigationBar: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Text(
            'Alta precision, timeout de 15s y lectura continua para evidencia de GPS.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF667085), fontSize: 13),
          ),
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.onGetLocation,
    required this.onToggleWatch,
    required this.isWatching,
  });

  final VoidCallback? onGetLocation;
  final VoidCallback? onToggleWatch;
  final bool isWatching;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Color(0xFFE8F3FF), Color(0xFFE6FBF7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(color: Color(0x14152033)),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Chip(
              avatar: Icon(Icons.location_on_outlined, color: colorScheme.primary),
              label: const Text('Flutter'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Lectura GPS con Flutter y geolocator',
              style: TextStyle(
                color: Color(0xFF10213F),
                fontSize: 30,
                fontWeight: FontWeight.w700,
                height: 1.12,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Obtiene coordenadas reales del dispositivo, controla permisos y muestra errores comunes para compararlo luego con Ionic.',
              style: TextStyle(
                color: Color(0xFF4C5B70),
                fontSize: 16,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: onGetLocation,
                  icon: const Icon(Icons.my_location_outlined),
                  label: const Text('Obtener ubicacion'),
                ),
                OutlinedButton.icon(
                  onPressed: onToggleWatch,
                  icon: Icon(isWatching ? Icons.stop : Icons.play_arrow),
                  label: Text(isWatching ? 'Detener' : 'Seguimiento'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error});

  final GpsError error;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_outlined,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    error.title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              error.detail,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.position,
    required this.permissionLabel,
    required this.lastUpdate,
    required this.mapsUrl,
  });

  final Position? position;
  final String permissionLabel;
  final String lastUpdate;
  final String? mapsUrl;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F3FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.navigation_outlined,
                    color: Color(0xFF155EEF),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Coordenadas',
                        style: TextStyle(
                          color: Color(0xFF10213F),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        lastUpdate,
                        style: const TextStyle(color: Color(0xFF667085)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            _InfoRow(label: 'Latitud', value: _formatNumber(position?.latitude)),
            _InfoRow(label: 'Longitud', value: _formatNumber(position?.longitude)),
            _InfoRow(label: 'Precision', value: _formatMeters(position?.accuracy)),
            _InfoRow(label: 'Altitud', value: _formatMeters(position?.altitude)),
            _InfoRow(label: 'Velocidad', value: _formatSpeed(position?.speed)),
            _InfoRow(label: 'Permiso', value: permissionLabel),
            if (mapsUrl != null) ...[
              const Divider(height: 28),
              SelectableText(
                mapsUrl!,
                style: const TextStyle(
                  color: Color(0xFF155EEF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatNumber(double? value) {
    return value == null ? 'No disponible' : value.toStringAsFixed(6);
  }

  String _formatMeters(double? value) {
    return value == null ? 'No disponible' : '${value.toStringAsFixed(1)} m';
  }

  String _formatSpeed(double? value) {
    return value == null ? 'No disponible' : '${(value * 3.6).toStringAsFixed(1)} km/h';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF667085)),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF10213F),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GpsError {
  const GpsError({
    required this.title,
    required this.detail,
  });

  final String title;
  final String detail;
}
