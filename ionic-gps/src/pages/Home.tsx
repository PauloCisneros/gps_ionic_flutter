import React, { useState, useEffect, useRef } from 'react';
import {
  IonContent,
  IonHeader,
  IonPage,
  IonTitle,
  IonToolbar,
  IonButton,
  IonCard,
  IonCardContent,
  IonCardHeader,
  IonCardTitle,
  IonIcon,
  IonGrid,
  IonRow,
  IonCol,
  IonText,
  IonToast
} from '@ionic/react';
import {
  locationOutline,
  playOutline,
  stopOutline,
  timeOutline,
  compassOutline,
  syncOutline,
  trashOutline,
  alertCircleOutline
} from 'ionicons/icons';
import { Geolocation } from '@capacitor/geolocation';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import './Home.css';

interface GPSData {
  lat: number;
  lng: number;
  accuracy: number;
  timestamp: string;
}

const Home: React.FC = () => {
  const [position, setPosition] = useState<GPSData | null>(null);
  const [tracking, setTracking] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [history, setHistory] = useState<GPSData[]>([]);
  const [showToast, setShowToast] = useState<boolean>(false);

  const mapRef = useRef<L.Map | null>(null);
  const markerRef = useRef<L.Marker | null>(null);
  const watchIdRef = useRef<string | null>(null);

  // Initialize Leaflet Map
  useEffect(() => {
    if (!mapRef.current) {
      mapRef.current = L.map('map', {
        zoomControl: true,
        attributionControl: false
      }).setView([0, 0], 2);

      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19
      }).addTo(mapRef.current);
    }

    return () => {
      if (mapRef.current) {
        mapRef.current.remove();
        mapRef.current = null;
        markerRef.current = null;
      }
      if (watchIdRef.current) {
        Geolocation.clearWatch({ id: watchIdRef.current });
      }
    };
  }, []);

  // Update map view and marker location
  const updateMap = (lat: number, lng: number) => {
    if (!mapRef.current) return;

    mapRef.current.setView([lat, lng], 16);

    if (markerRef.current) {
      markerRef.current.setLatLng([lat, lng]);
    } else {
      const pulseIcon = L.divIcon({
        className: 'custom-pulse-marker',
        html: `
          <div style="
            position: relative;
            width: 16px;
            height: 16px;
            background-color: #06b6d4;
            border-radius: 50%;
            border: 2px solid #ffffff;
            box-shadow: 0 0 10px #06b6d4;
          ">
            <div style="
              position: absolute;
              width: 36px;
              height: 36px;
              background-color: rgba(6, 182, 212, 0.4);
              border-radius: 50%;
              top: -10px;
              left: -10px;
              animation: pulse 1.8s infinite ease-in-out;
            "></div>
          </div>
        `,
        iconSize: [16, 16],
        iconAnchor: [8, 8]
      });

      markerRef.current = L.marker([lat, lng], { icon: pulseIcon }).addTo(mapRef.current);
    }
  };

  // Get current position (One-time)
  const getCurrentPosition = async () => {
    try {
      setError(null);
      const permission = await Geolocation.checkPermissions();
      
      if (permission.location !== 'granted') {
        const request = await Geolocation.requestPermissions();
        if (request.location !== 'granted') {
          throw new Error('Permiso de ubicación denegado. Por favor, actívalo en la configuración.');
        }
      }

      const pos = await Geolocation.getCurrentPosition({
        enableHighAccuracy: true,
        timeout: 15000
      });

      const lat = pos.coords.latitude;
      const lng = pos.coords.longitude;
      const accuracy = pos.coords.accuracy;
      const timestamp = new Date(pos.timestamp).toLocaleTimeString();

      const newData = { lat, lng, accuracy, timestamp };
      setPosition(newData);
      updateMap(lat, lng);

      setHistory(prev => [newData, ...prev.slice(0, 19)]);
    } catch (err: any) {
      console.error(err);
      setError(err.message || 'No se pudo obtener la ubicación. Verifica que el GPS esté encendido.');
      setShowToast(true);
    }
  };

  // Start real-time tracking
  const startTracking = async () => {
    if (tracking) return;
    try {
      setError(null);
      const permission = await Geolocation.checkPermissions();
      
      if (permission.location !== 'granted') {
        const request = await Geolocation.requestPermissions();
        if (request.location !== 'granted') {
          throw new Error('Permiso de ubicación denegado para el rastreo.');
        }
      }

      setTracking(true);

      const id = await Geolocation.watchPosition(
        {
          enableHighAccuracy: true,
          timeout: 15000,
          maximumAge: 0
        },
        (pos, err) => {
          if (err) {
            console.error(err);
            setError(err.message || 'Error en el rastreo GPS en tiempo real.');
            setShowToast(true);
            return;
          }

          if (pos) {
            const lat = pos.coords.latitude;
            const lng = pos.coords.longitude;
            const accuracy = pos.coords.accuracy;
            const timestamp = new Date(pos.timestamp).toLocaleTimeString();

            const newData = { lat, lng, accuracy, timestamp };
            setPosition(newData);
            updateMap(lat, lng);

            setHistory(prev => [newData, ...prev.slice(0, 19)]);
          }
        }
      );

      watchIdRef.current = id;
    } catch (err: any) {
      console.error(err);
      setTracking(false);
      setError(err.message || 'No se pudo iniciar el rastreo GPS.');
      setShowToast(true);
    }
  };

  // Stop tracking
  const stopTracking = async () => {
    if (!tracking) return;
    try {
      if (watchIdRef.current) {
        await Geolocation.clearWatch({ id: watchIdRef.current });
        watchIdRef.current = null;
      }
      setTracking(false);
    } catch (err: any) {
      console.error(err);
      setError('Error al detener el rastreo.');
      setShowToast(true);
    }
  };

  // Clear tracking history logs
  const clearHistory = () => {
    setHistory([]);
  };

  // Determine accuracy level color coding
  const getAccuracyBadge = (accuracy: number) => {
    if (accuracy <= 10) return <span className="accuracy-badge accuracy-high">Alta (&lt;=10m)</span>;
    if (accuracy <= 50) return <span className="accuracy-badge accuracy-medium">Media (&lt;=50m)</span>;
    return <span className="accuracy-badge accuracy-low">Baja (&gt;50m)</span>;
  };

  return (
    <IonPage>
      <IonHeader className="ion-no-border">
        <IonToolbar style={{ '--background': '#030712' }}>
          <IonTitle style={{ paddingLeft: '16px' }}>
            <span className="gradient-title" style={{ fontSize: '1.4rem' }}>Antigravity GPS</span>
          </IonTitle>
        </IonToolbar>
      </IonHeader>

      <IonContent fullscreen className="ion-padding" style={{ '--background': '#030712' }}>
        <div style={{ maxWidth: '800px', margin: '0 auto' }}>
          {/* Welcome Text */}
          <div style={{ padding: '0 16px', marginBottom: '8px' }}>
            <IonText color="light">
              <h2 style={{ fontWeight: 700, margin: '8px 0 4px 0' }}>Panel de Control GPS</h2>
            </IonText>
            <IonText color="medium">
              <p style={{ margin: 0, fontSize: '0.95rem' }}>
                Monitoreo de coordenadas GPS en tiempo real usando Capacitor Geolocation.
              </p>
            </IonText>
          </div>

          {/* Status Display Card */}
          <IonCard className="glass-panel" style={{ margin: '16px 0' }}>
            <IonCardHeader style={{ paddingBottom: '8px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <IonCardTitle style={{ fontSize: '1.2rem', fontWeight: 700, color: '#f3f4f6' }}>
                  Datos de Ubicación
                </IonCardTitle>
                <div className={`status-badge ${tracking ? 'active' : 'inactive'}`}>
                  <span 
                    style={{
                      display: 'inline-block',
                      width: '8px',
                      height: '8px',
                      borderRadius: '50%',
                      backgroundColor: tracking ? '#10b981' : '#ef4444',
                      boxShadow: tracking ? '0 0 8px #10b981' : 'none'
                    }}
                  />
                  {tracking ? 'Rastreando' : 'Inactivo'}
                </div>
              </div>
            </IonCardHeader>
            <IonCardContent>
              {position ? (
                <IonGrid className="ion-no-padding">
                  <IonRow>
                    <IonCol size="12" sizeMd="6" style={{ padding: '8px 0' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                        <IonIcon icon={compassOutline} style={{ color: '#06b6d4', fontSize: '1.4rem' }} />
                        <div>
                          <div style={{ fontSize: '0.8rem', color: '#9ca3af', textTransform: 'uppercase' }}>Latitud</div>
                          <div style={{ fontSize: '1.15rem', fontWeight: 600, color: '#f3f4f6' }}>{position.lat.toFixed(6)}°</div>
                        </div>
                      </div>
                    </IonCol>
                    <IonCol size="12" sizeMd="6" style={{ padding: '8px 0' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                        <IonIcon icon={compassOutline} style={{ color: '#06b6d4', fontSize: '1.4rem' }} />
                        <div>
                          <div style={{ fontSize: '0.8rem', color: '#9ca3af', textTransform: 'uppercase' }}>Longitud</div>
                          <div style={{ fontSize: '1.15rem', fontWeight: 600, color: '#f3f4f6' }}>{position.lng.toFixed(6)}°</div>
                        </div>
                      </div>
                    </IonCol>
                  </IonRow>
                  <IonRow style={{ marginTop: '8px' }}>
                    <IonCol size="12" sizeMd="6" style={{ padding: '8px 0' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                        <IonIcon icon={syncOutline} style={{ color: '#8b5cf6', fontSize: '1.4rem' }} />
                        <div>
                          <div style={{ fontSize: '0.8rem', color: '#9ca3af', textTransform: 'uppercase' }}>Precisión</div>
                          <div style={{ display: 'flex', alignItems: 'center', gap: '8px', marginTop: '2px' }}>
                            <span style={{ fontSize: '1.1rem', fontWeight: 600, color: '#f3f4f6' }}>{position.accuracy.toFixed(1)} m</span>
                            {getAccuracyBadge(position.accuracy)}
                          </div>
                        </div>
                      </div>
                    </IonCol>
                    <IonCol size="12" sizeMd="6" style={{ padding: '8px 0' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                        <IonIcon icon={timeOutline} style={{ color: '#8b5cf6', fontSize: '1.4rem' }} />
                        <div>
                          <div style={{ fontSize: '0.8rem', color: '#9ca3af', textTransform: 'uppercase' }}>Última Actualización</div>
                          <div style={{ fontSize: '1.1rem', fontWeight: 600, color: '#f3f4f6' }}>{position.timestamp}</div>
                        </div>
                      </div>
                    </IonCol>
                  </IonRow>
                </IonGrid>
              ) : (
                <div style={{ textAlign: 'center', padding: '24px 0', color: '#9ca3af' }}>
                  <IonIcon icon={locationOutline} style={{ fontSize: '3rem', color: '#374151', marginBottom: '8px' }} />
                  <div>No hay datos de ubicación disponibles. Haz clic en "Obtener Ubicación" o inicia el rastreo.</div>
                </div>
              )}
            </IonCardContent>
          </IonCard>

          {/* Action Controls */}
          <div style={{ display: 'flex', flexWrap: 'wrap', justifyContent: 'center', gap: '8px', padding: '0 8px' }}>
            <IonButton 
              className="btn-glow-primary"
              disabled={tracking}
              onClick={getCurrentPosition}
            >
              <IonIcon icon={locationOutline} slot="start" />
              Obtener Ubicación
            </IonButton>

            {!tracking ? (
              <IonButton 
                className="btn-glow-secondary"
                onClick={startTracking}
              >
                <IonIcon icon={playOutline} slot="start" />
                Iniciar Rastreo
              </IonButton>
            ) : (
              <IonButton 
                className="btn-glow-danger"
                onClick={stopTracking}
              >
                <IonIcon icon={stopOutline} slot="start" />
                Detener Rastreo
              </IonButton>
            )}
          </div>

          {/* Map View */}
          <div style={{ padding: '0 8px', marginTop: '16px' }}>
            <IonText color="light">
              <h3 style={{ fontWeight: 600, fontSize: '1.1rem', margin: '8px 0' }}>Mapa de Localización</h3>
            </IonText>
            <div id="map" className="map-container"></div>
          </div>

          {/* History Log Section */}
          <IonCard className="glass-panel" style={{ margin: '24px 0 16px 0', padding: '8px' }}>
            <IonCardHeader style={{ padding: '12px 16px', display: 'flex', flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' }}>
              <IonCardTitle style={{ fontSize: '1.1rem', fontWeight: 700, color: '#f3f4f6' }}>
                Historial de Recorrido
              </IonCardTitle>
              {history.length > 0 && (
                <IonButton fill="clear" color="danger" size="small" onClick={clearHistory}>
                  <IonIcon icon={trashOutline} slot="icon-only" />
                </IonButton>
              )}
            </IonCardHeader>
            <IonCardContent style={{ padding: '0 8px 8px 8px' }}>
              {history.length > 0 ? (
                <div className="history-list">
                  {history.map((item, index) => (
                    <div key={index} className="history-item" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <div>
                        <div style={{ color: '#f3f4f6', fontWeight: 500 }}>
                          {item.lat.toFixed(6)}°, {item.lng.toFixed(6)}°
                        </div>
                        <div style={{ fontSize: '0.75rem', color: '#9ca3af', marginTop: '2px' }}>
                          Precisión: {item.accuracy.toFixed(1)}m | Hora: {item.timestamp}
                        </div>
                      </div>
                      <div>
                        {item.accuracy <= 10 ? (
                          <span style={{ color: '#10b981', fontSize: '1.2rem' }}>●</span>
                        ) : item.accuracy <= 50 ? (
                          <span style={{ color: '#f59e0b', fontSize: '1.2rem' }}>●</span>
                        ) : (
                          <span style={{ color: '#ef4444', fontSize: '1.2rem' }}>●</span>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div style={{ textAlign: 'center', padding: '16px 0', color: '#9ca3af', fontSize: '0.9rem' }}>
                  El historial está vacío. Comienza a registrar coordenadas para verlas aquí.
                </div>
              )}
            </IonCardContent>
          </IonCard>
        </div>

        {/* Error Toast */}
        <IonToast
          isOpen={showToast}
          onDidDismiss={() => setShowToast(false)}
          message={error || 'Ha ocurrido un error.'}
          duration={4000}
          color="danger"
          icon={alertCircleOutline}
          buttons={[
            {
              text: 'OK',
              role: 'cancel'
            }
          ]}
        />
      </IonContent>
    </IonPage>
  );
};

export default Home;
