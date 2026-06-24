import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.codex.ionicgps',
  appName: 'Ionic GPS Codex',
  webDir: 'dist',
  server: {
    androidScheme: 'https',
  },
  plugins: {
    Geolocation: {
      enableHighAccuracy: true,
    },
  },
};

export default config;
