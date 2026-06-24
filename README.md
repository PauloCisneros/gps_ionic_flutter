# Informe de Pruebas: Apps de GPS (Codex vs Antigravity)

Este repositorio documenta el desarrollo y las pruebas de rendimiento de cuatro aplicaciones móviles enfocadas en servicios de geolocalización, utilizando tecnologías híbridas (Ionic) y nativas (Flutter).

## 1. Capturas de Pantalla de las Aplicaciones

| App (Codex) | App (Antigravity) |
| :--- | :--- |
| **Ionic:**<br><img width="250" alt="Ionic Codex" src="https://github.com/user-attachments/assets/5f387626-1ddd-4b76-86ce-0938dd8374b9" /> | **Ionic:**<br><img width="250" alt="Ionic Antigravity" src="https://github.com/user-attachments/assets/5d7193a4-b7d2-47c9-8ee0-27880c7a5015" /> |
| **Flutter:**<br><img width="250" alt="Flutter Codex" src="https://github.com/user-attachments/assets/e3d0cb37-eb14-4fa2-8b34-c865aa2406e5" /> | **Flutter:**<br><img width="250" alt="Flutter Antigravity" src="https://github.com/user-attachments/assets/1ae51289-311d-4af3-9d71-a7f0e040199c" /> |

---

## 2. Informe Comparativo

A continuación, se presenta la tabla comparativa de rendimiento y desarrollo.

| Criterio | Ionic (Codex) | Flutter (Codex) | Ionic (Antigravity) | Flutter (Antigravity) |
| :--- | :--- | :--- | :--- | :--- |
| **Tiempo de Carga** |Se ejecuta rápido |Se ejecuta rápido |Se ejecuta rápido |Se ejecuta rápido |
| **Precisión GPS** |16.0m |17.1m |100m |28.5m |
| **Facilidad de Dev** |Fácil |Fácil |Fácil |Fácil |
| **Tamaño APK** |5.13 mb |47.69 mb |5.65 mb |48.8 mb |

### Video en tik tok

https://vm.tiktok.com/ZSCN3rV4c/

---

## 3. Instrucciones para el usuario

### Requisitos previos
* [Node.js](https://nodejs.org/) (para Ionic)
* [Flutter SDK](https://flutter.dev/) (para Flutter)
* [Git](https://git-scm.com/)

### Cómo ejecutar los proyectos
1. **Clonar:** `git clone https://github.com/PauloCisneros/gps_ionic_flutter.git`
2. **Ionic:** Entra a la carpeta y ejecuta:
   ```bash
   npm install
   npx cap sync

3. **Flutter: Entra a los proyectos y ejecuta:**
   ```bash
   flutter pub get
