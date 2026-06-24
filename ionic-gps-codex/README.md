# Ionic GPS Codex

Proyecto Ionic + React + Capacitor para implementar GPS.

## Funciones

- Solicita permisos de ubicacion cuando la app corre en Android o iOS.
- Obtiene la ubicacion actual con alta precision.
- Permite iniciar y detener seguimiento en vivo.
- Muestra latitud, longitud, precision, altitud, velocidad y hora de lectura.
- Presenta errores claros cuando el permiso se niega, el GPS esta apagado o se agota el tiempo de espera.
- Incluye enlace para abrir la ubicacion en Google Maps.

## Ejecutar en navegador

```bash
npm install
npm run dev
```

## Preparar Android o iOS

```bash
npm install
npm run build
npx cap sync
npx cap add android
npx cap open android
```

Para iOS se usa `npx cap add ios` y `npx cap open ios` desde macOS.

## Permisos nativos necesarios

Android:

```xml
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-feature android:name="android.hardware.location.gps" />
```

iOS:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Esta app necesita tu ubicacion para mostrar coordenadas GPS.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Esta app necesita tu ubicacion para mostrar coordenadas GPS.</string>
```

Estos permisos se agregan en los proyectos nativos despues de ejecutar `npx cap add android` o `npx cap add ios`.
