# Biomarcadores - Monitoreo No-Invasivo

Aplicación móvil para el monitoreo de biomarcadores (glucosa, ritmo cardíaco) utilizando tecnologías de visión computacional y sensores del dispositivo.

## 🚀 Características Principales

*   **Dashboard Interactivo**: Visualización en tiempo real de datos de sensores (acelerómetro, pasos).
*   **Medición de Ritmo Cardíaco (rPPG)**: Uso de la cámara y flash para estimar BPM.
*   **Gestión de Historial**: Almacenamiento local de mediciones.
*   **Sincronización Cloud**: Integración con backend Django/Vercel.

## 🛠️ Stack Tecnológico

*   **Frontend**: Flutter (Dart)
*   **Backend**: Django REST Framework (Deploy en Vercel)
*   **Base de Datos Local**: SQLite (sqflite)
*   **Gráficos**: fl_chart

## 📂 Estructura del Proyecto

*   `lib/screens/`: Pantallas principales (Dashboard, Measure, HeartRate).
*   `lib/api/`: Configuración de API y clientes HTTP.
*   `lib/auth/`: Lógica de autenticación (JWT).
*   `docs/images/`: Imágenes de referencia y capturas de pantalla.

## 🏁 Cómo Iniciar

1.  Clonar el repositorio.
2.  Ejecutar `flutter pub get`.
3.  Conectar un dispositivo físico.
4.  Ejecutar `flutter run`.

## 📸 Capturas

*(Coloca tus imágenes en `docs/images/`)*

---
**Versión MVP 1.0**
