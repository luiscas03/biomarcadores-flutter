# E3 - UI + Historico local (End of Day)

Objetivo del dia: App usable (medir -> ver resultado -> ver historico + graficas) y dejar resueltos los gaps de D1/D2.

## Resumen ejecutivo (1-2 lineas)
- Resultado principal: UI de medicion e historico con graficas y filtros implementado, y backend PPG integrado.
- Estado general: listo para validacion final en dispositivo y evidencia (capturas/video).

## Cierre de brechas D1/D2 (audit)
- D1 Stack mismatch: se mantiene Flutter como frontend core. Backend en Django + FastAPI para rPPG/ML. (resuelto)
- D1 Captura: flash torch activo, indicadores de FPS/estabilidad y gating de captura en app. (resuelto)
- D2 Endpoint PPG: proxy en Django -> FastAPI con `/api/v1/ppg/measure`. (resuelto)
- D2 CHROM validacion: pendiente evidencia formal (BPM vs pulsometro, 3 tonos de piel, SNR). (parcial)
- D2 Visualizacion senal: pendiente captura de grafica de 100 puntos. (parcial)

## Repositorios / Entornos
- App (Flutter): C:\Users\Flutter\biomarcad
- Backend (Django / Vercel): C:\Users\Davide\Documents\Proyectos Python\biomarcadores\app | https://biomarcadores.vercel.app
- FastAPI (Render): C:\Users\Davide\Documents\Glucosa | https://glucosa-fastapi.onrender.com
- Staging / URLs:
  - Django /health: https://biomarcadores.vercel.app/health
  - Django /docs: https://biomarcadores.vercel.app/docs
  - FastAPI /docs: https://glucosa-fastapi.onrender.com/docs
  - FastAPI /api/v1/ppg/measure: https://glucosa-fastapi.onrender.com/api/v1/ppg/measure
  - Repositorio app https://github.com/luiscas03/biomarcadores-flutter.git
  - Repositorio FastApi https://github.com/luiscas03/glucosa-fastapi.git

## Checklist (DoD del dia)
- [x] Medicion con preview en tiempo real, timer, indicadores de luz/estabilidad y boton "capturar" condicionado.
- [x] Almacenamiento local persistente (100+ mediciones sin degradacion, flag synced).
- [x] Historico completo (orden, filtros 24h/7d/30d, busqueda por fecha, estado normal/alerta).
- [x] Graficas 24h/7d/30d con tooltips y bandas de referencia.
- [ ] Responsive + accesible (min WCAG AA, teclado, etc.).
- [ ] Evidencia minima: demo navegable (dashboard -> medir -> guardar -> historico -> filtros -> graficas).

## Evidencia tecnica (links y capturas)
- Demo navegable (video/gif):
- Captura Dashboard: docs/images/dashboard_design.jpeg
- Captura Medicion: docs/images/measure_screen.jpeg
- Captura Historico: (agregar captura actual)
- Captura Graficas: (agregar captura actual)
- Evidencia PPG (JSON real con snr_db): (agregar)
- Logs/CI (si aplica):

## Implementacion UI (E3)
- Pantalla de medicion:
  - Preview camara: CameraPreview con flash torch activo.
  - Timer: 15s con barra de progreso.
  - Indicadores (luz/estabilidad/fps/720p): luz y estabilidad visual, FPS actualizado, resolucion informativa.
  - Boton capturar condicionado: habilita con dedo detectado + FPS >= 20 y sin espera de backend.
- Pantalla de historico:
  - Filtros: 24h / 7d / 30d / Todo
  - Busqueda por fecha: DatePicker
  - Estados (normal/alerta): <70 bajo, >180 alto, resto normal
  - Graficas + tooltips: LineChart con bandas 70/180 y tooltip con fecha

## Persistencia local
- Base: SQLite (sqflite) -> biomarcadores.db (documents dir).
- Tabla: measurements
- Campos guardados: ts, bpm, spo2, glucosa, confidence, snr_db, motion_pct, quality_valid, signal_json, timestamps_json, synced
- Flag synced: presente (pendiente de sync en E5).

## Graficas y bandas de referencia
- Banda baja: 70 mg/dL
- Banda alta: 180 mg/dL
- Tooltip: "glucosa mg/dL + fecha/hora"

## Evidencia pendiente de D2 (para cerrar auditoria)
- JSON real del endpoint `/api/v1/ppg/measure` con bpm/confidence/snr_db/motion_pct.
- Grafica de senal (min 100 puntos) con timestamps.
- Tabla de validacion CHROM (3 casos, error +-5 BPM).

## Flujo usuario (paso a paso)
1) Dashboard -> Medir
2) Coloca dedo -> Capturar
3) Resultado -> Guardar
4) Historico -> Filtros -> Grafica

## Validaciones de UX / Accesibilidad
- Mensajes de error: backend error visible + reintento manual.
- Feedback de carga: indicador "Procesando senal..." durante backend.
- Tamanos de texto / contraste: color contrastado y tamano legible.
- Teclado / enfoque (si aplica):

## Tests
- Unit tests UI:
- Integracion UI:
- Pruebas manuales:


## Evidencia para auditoria
- Commits:
- Tags / release:
- Assets (docs/images):
  - docs/images/dashboard_design.jpeg
  - docs/images/measure_screen.jpeg
  - docs/images/scan_screen.jpeg
  - docs/images/Resultado.jpeg
  - docs/images/Historico.jpeg
