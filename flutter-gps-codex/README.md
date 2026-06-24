# Flutter GPS Codex

Proyecto Flutter para implementar GPS con el paquete `geolocator`.

## Funciones

- Solicita permiso de ubicacion.
- Verifica si el servicio GPS esta encendido.
- Obtiene ubicacion actual con alta precision.
- Permite iniciar y detener seguimiento en vivo.
- Muestra latitud, longitud, precision, altitud, velocidad y hora.
- Maneja errores comunes: permiso denegado, permiso denegado permanentemente, GPS apagado, timeout y fallo general.
- Genera enlace de Google Maps con las coordenadas.

## Ejecutar

```bash
flutter pub get
flutter run
```

Si faltan carpetas nativas generadas por Flutter en tu equipo:

```bash
flutter create --platforms android,ios,web .
flutter pub get
flutter run
```

## Permisos Android

Archivo: `android/app/src/main/AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-feature android:name="android.hardware.location.gps" android:required="false" />
```

## Permisos iOS

Archivo: `ios/Runner/Info.plist`

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Esta app necesita tu ubicacion para mostrar coordenadas GPS.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Esta app necesita tu ubicacion para mostrar coordenadas GPS.</string>
```

## Evidencia sugerida

Para el informe, toma capturas de:

1. Pantalla inicial sin lectura.
2. Dialogo de permiso de ubicacion.
3. Coordenadas obtenidas.
4. Seguimiento en vivo activo.
5. Error con GPS apagado o permiso denegado.
