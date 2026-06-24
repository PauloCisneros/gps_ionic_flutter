import {
  IonApp,
  IonBadge,
  IonButton,
  IonButtons,
  IonCard,
  IonCardContent,
  IonChip,
  IonContent,
  IonFooter,
  IonHeader,
  IonIcon,
  IonItem,
  IonLabel,
  IonList,
  IonProgressBar,
  IonRouterOutlet,
  IonText,
  IonTitle,
  IonToolbar,
} from '@ionic/react';
import { IonReactRouter } from '@ionic/react-router';
import { Capacitor } from '@capacitor/core';
import {
  Geolocation,
  type CallbackID,
  type Position,
} from '@capacitor/geolocation';
import {
  compassOutline,
  locateOutline,
  locationOutline,
  navigateOutline,
  playOutline,
  stopOutline,
  warningOutline,
} from 'ionicons/icons';
import { useMemo, useRef, useState } from 'react';
import { Redirect, Route } from 'react-router-dom';

type GpsError = {
  title: string;
  detail: string;
};

type PermissionState = 'prompt' | 'prompt-with-rationale' | 'granted' | 'denied';

const gpsOptions = {
  enableHighAccuracy: true,
  timeout: 15000,
  maximumAge: 0,
  minimumUpdateInterval: 3000,
};

function formatNumber(value: number | null, decimals = 6) {
  return value === null ? 'No disponible' : value.toFixed(decimals);
}

function formatOptionalMeters(value: number | null) {
  return value === null ? 'No disponible' : `${value.toFixed(1)} m`;
}

function formatSpeed(value: number | null) {
  return value === null ? 'No disponible' : `${(value * 3.6).toFixed(1)} km/h`;
}

function getPermissionLabel(permission: PermissionState | 'unknown') {
  const labels: Record<PermissionState | 'unknown', string> = {
    granted: 'Concedido',
    denied: 'Denegado',
    prompt: 'Pendiente',
    'prompt-with-rationale': 'Requiere explicacion',
    unknown: 'Sin consultar',
  };

  return labels[permission];
}

function normalizeGpsError(error: unknown): GpsError {
  const fallback = {
    title: 'No se pudo leer el GPS',
    detail: 'Revisa permisos, senal GPS y servicios de ubicacion del dispositivo.',
  };

  if (!error || typeof error !== 'object') {
    return fallback;
  }

  const maybeError = error as { code?: string; message?: string };

  switch (maybeError.code) {
    case 'OS-PLUG-GLOC-0003':
      return {
        title: 'Permiso de ubicacion denegado',
        detail: 'Activa el permiso de ubicacion para esta app desde ajustes del dispositivo.',
      };
    case 'OS-PLUG-GLOC-0007':
      return {
        title: 'GPS desactivado',
        detail: 'Enciende los servicios de ubicacion y vuelve a intentarlo.',
      };
    case 'OS-PLUG-GLOC-0010':
      return {
        title: 'Tiempo de espera agotado',
        detail: 'La app no recibio coordenadas a tiempo. Prueba en un lugar con mejor senal.',
      };
    default:
      return {
        title: fallback.title,
        detail: maybeError.message || fallback.detail,
      };
  }
}

function HomePage() {
  const watchId = useRef<CallbackID | null>(null);
  const [position, setPosition] = useState<Position | null>(null);
  const [permission, setPermission] = useState<PermissionState | 'unknown'>('unknown');
  const [isLoading, setIsLoading] = useState(false);
  const [isWatching, setIsWatching] = useState(false);
  const [error, setError] = useState<GpsError | null>(null);

  const platform = Capacitor.getPlatform();
  const mapUrl = useMemo(() => {
    if (!position) {
      return null;
    }

    const { latitude, longitude } = position.coords;
    return `https://www.google.com/maps/search/?api=1&query=${latitude},${longitude}`;
  }, [position]);

  async function ensurePermission() {
    if (platform === 'web') {
      setPermission('prompt');
      return true;
    }

    const current = await Geolocation.checkPermissions();
    setPermission(current.location);

    if (current.location === 'granted') {
      return true;
    }

    const requested = await Geolocation.requestPermissions({ permissions: ['location'] });
    setPermission(requested.location);

    return requested.location === 'granted';
  }

  async function getCurrentLocation() {
    setIsLoading(true);
    setError(null);

    try {
      const allowed = await ensurePermission();

      if (!allowed) {
        setError({
          title: 'Permiso requerido',
          detail: 'La app necesita permiso de ubicacion para mostrar coordenadas GPS.',
        });
        return;
      }

      const current = await Geolocation.getCurrentPosition(gpsOptions);
      setPosition(current);
    } catch (gpsError) {
      setError(normalizeGpsError(gpsError));
    } finally {
      setIsLoading(false);
    }
  }

  async function startWatching() {
    setIsLoading(true);
    setError(null);

    try {
      const allowed = await ensurePermission();

      if (!allowed) {
        setError({
          title: 'Permiso requerido',
          detail: 'La app necesita permiso de ubicacion para iniciar el seguimiento.',
        });
        return;
      }

      watchId.current = await Geolocation.watchPosition(gpsOptions, (newPosition, watchError) => {
        if (watchError) {
          setError(normalizeGpsError(watchError));
          return;
        }

        if (newPosition) {
          setPosition(newPosition);
          setError(null);
        }
      });
      setIsWatching(true);
    } catch (gpsError) {
      setError(normalizeGpsError(gpsError));
    } finally {
      setIsLoading(false);
    }
  }

  async function stopWatching() {
    if (!watchId.current) {
      return;
    }

    await Geolocation.clearWatch({ id: watchId.current });
    watchId.current = null;
    setIsWatching(false);
  }

  const lastUpdate = position
    ? new Intl.DateTimeFormat('es-EC', {
        dateStyle: 'medium',
        timeStyle: 'medium',
      }).format(new Date(position.timestamp))
    : 'Sin lectura todavia';

  return (
    <>
      <IonHeader translucent>
        <IonToolbar>
          <IonTitle>GPS Ionic</IonTitle>
          <IonButtons slot="end">
            <IonBadge color={isWatching ? 'success' : 'medium'}>
              {isWatching ? 'En vivo' : 'Manual'}
            </IonBadge>
          </IonButtons>
        </IonToolbar>
        {isLoading && <IonProgressBar type="indeterminate" />}
      </IonHeader>

      <IonContent fullscreen className="gps-page">
        <section className="gps-hero">
          <IonChip color="primary">
            <IonIcon icon={locationOutline} />
            <IonLabel>{platform.toUpperCase()}</IonLabel>
          </IonChip>
          <h1>Lectura GPS con Ionic y Capacitor</h1>
          <p>
            Obtiene coordenadas reales del dispositivo, controla permisos y muestra errores comunes
            para compararlo luego con Flutter.
          </p>
          <div className="gps-actions">
            <IonButton onClick={getCurrentLocation} disabled={isLoading} size="default">
              <IonIcon icon={locateOutline} slot="start" />
              Obtener ubicacion
            </IonButton>
            <IonButton
              color={isWatching ? 'danger' : 'secondary'}
              fill="outline"
              onClick={isWatching ? stopWatching : startWatching}
              disabled={isLoading}
            >
              <IonIcon icon={isWatching ? stopOutline : playOutline} slot="start" />
              {isWatching ? 'Detener' : 'Seguimiento'}
            </IonButton>
          </div>
        </section>

        {error && (
          <IonCard color="danger" className="status-card">
            <IonCardContent>
              <div className="error-title">
                <IonIcon icon={warningOutline} />
                <strong>{error.title}</strong>
              </div>
              <p>{error.detail}</p>
            </IonCardContent>
          </IonCard>
        )}

        <IonCard className="location-card">
          <IonCardContent>
            <div className="card-heading">
              <IonIcon icon={navigateOutline} />
              <div>
                <h2>Coordenadas</h2>
                <p>{lastUpdate}</p>
              </div>
            </div>

            <IonList lines="full" className="gps-list">
              <IonItem>
                <IonLabel>
                  <span>Latitud</span>
                  <strong>{formatNumber(position?.coords.latitude ?? null)}</strong>
                </IonLabel>
              </IonItem>
              <IonItem>
                <IonLabel>
                  <span>Longitud</span>
                  <strong>{formatNumber(position?.coords.longitude ?? null)}</strong>
                </IonLabel>
              </IonItem>
              <IonItem>
                <IonLabel>
                  <span>Precision</span>
                  <strong>{formatOptionalMeters(position?.coords.accuracy ?? null)}</strong>
                </IonLabel>
              </IonItem>
              <IonItem>
                <IonLabel>
                  <span>Altitud</span>
                  <strong>{formatOptionalMeters(position?.coords.altitude ?? null)}</strong>
                </IonLabel>
              </IonItem>
              <IonItem>
                <IonLabel>
                  <span>Velocidad</span>
                  <strong>{formatSpeed(position?.coords.speed ?? null)}</strong>
                </IonLabel>
              </IonItem>
              <IonItem>
                <IonLabel>
                  <span>Permiso</span>
                  <strong>{getPermissionLabel(permission)}</strong>
                </IonLabel>
              </IonItem>
            </IonList>

            {mapUrl && (
              <IonButton expand="block" href={mapUrl} target="_blank" rel="noreferrer">
                <IonIcon icon={compassOutline} slot="start" />
                Abrir en Google Maps
              </IonButton>
            )}
          </IonCardContent>
        </IonCard>
      </IonContent>

      <IonFooter>
        <IonToolbar>
          <IonText className="footer-note">
            Alta precision, timeout de 15s y lectura sin cache para evidencia de GPS.
          </IonText>
        </IonToolbar>
      </IonFooter>
    </>
  );
}

export default function App() {
  return (
    <IonApp>
      <IonReactRouter>
        <IonRouterOutlet>
          <Route exact path="/home" component={HomePage} />
          <Route exact path="/">
            <Redirect to="/home" />
          </Route>
        </IonRouterOutlet>
      </IonReactRouter>
    </IonApp>
  );
}
