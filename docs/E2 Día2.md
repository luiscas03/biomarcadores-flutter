# E2 - Extraccion PPG + Senal limpia (End of Day)


Objetivo del dia: senal rPPG real + endpoint funcionando + pruebas con evidencia.

## Resumen ejecutivo (1-2 lineas)
- Resultado principal:
- Estado general:

## Checklist (DoD del dia)
- [ ] CHROM validado: error +-5 BPM vs pulsometro, funciona en 3 tonos de piel, confidence 0-1.
- [ ] Filtrado + artefactos: bandpass y descarte por movimiento (>10%), SNR > 3 dB.
- [ ] Endpoint `https://biomarcadores.vercel.app/api/v1/ppg/measure` activo: recibe senal, responde bpm/confidence/signal/quality, errores 400 validados.
- [ ] Senal guardada usable (min 100 puntos + timestamps).
- [ ] Tests + documentacion (3+ videos y benchmarks).
- [ ] Evidencia minima: request real + JSON + grafica de senal + 3 videos procesados.

## Criterios numericos clave
- Error BPM <= 5.
- SNR > 3 dB.
- Motion <= 10%.
- Senal minima: 100+ puntos con timestamps.

## Evidencia tecnica (links y capturas)
- FastAPI `https://rf-glucosamujeres.onrender.com/docs`:
- FastAPI `https://rf-glucosamujeres.onrender.com/health`:
- Request real a `https://biomarcadores.vercel.app/api/v1/ppg/measure`:
- Respuesta JSON:
- Grafica rapida de senal:
- Videos de prueba (3):
- Capturas de pantalla (docs/health/grafica/UI):
- Logs relevantes:
- Commit(s):
- Build/CI (si aplica):

## Alcance implementado hoy
- Extraccion rPPG desde app (canales RGB y timestamps):
- Algoritmo CHROM + bandpass + BPM:
- Calculo de SNR + quality:
- Heuristica de movimiento (motion %):
- Persistencia de senal:
- Integracion con backend:

## Fuera de alcance (pendiente)
- 

## Arquitectura / Flujo
1) Captura desde camara -> buffers RGB + timestamps.
2) Preprocesamiento (normalizacion + CHROM).
3) Filtrado bandpass.
4) Estimacion BPM + SNR + motion%.
5) Respuesta del endpoint y persistencia local.

## Implementacion tecnica
- Ubicacion del endpoint:
- Metodo de extraccion: CHROM + bandpass + estimacion BPM.
- Bandpass: rango Hz y metodo (FFT o IIR).
- Manejo de movimiento: umbral de descarte y porcentaje.
- Fuente de FPS: (camera / timestamps / calculado).
- Persistencia de senal: (local / remoto).
- Esquema de respuesta (campos obligatorios):
- Autenticacion (API Key / JWT / none):
- Version de modelo o pipeline:

## Validaciones y errores esperados
- 400 si faltan r/g/b o longitudes no coinciden.
- 400 si menos de 100 muestras.
- 400 si no hay fps ni timestamps.
- 403 si falla API key (si aplica).
- 422 si schema invalido (si aplica).


Promedio error abs:
SNR promedio:
Casos fuera de rango (+-5 BPM):

## Metodologia de validacion
- Dispositivos usados:
- Condiciones de luz:
- Pulsometro de referencia:
- Duracion por muestra:
- Tonos de piel cubiertos:

## Payload y respuesta (ejemplo)
Request:
```json
{
  "r": [123.4, 123.1, "..."],
  "g": [110.2, 109.8, "..."],
  "b": [95.7, 95.2, "..."],
  "fps": 30.0,
  "timestamps": [0.0, 0.033, "..."]
}
```

Respuesta:
```json
{
  "bpm": 72.4,
  "confidence": 0.62,
  "quality": { "snr_db": 4.1, "motion_pct": 6.8, "valid": true },
  "signal": [0.01, 0.02, "..."],
  "timestamps": [0.0, 0.033, "..."],
  "fps": 30.0,
  "method": "CHROM"
}
```

## Benchmarks y rendimiento
- Tiempo promedio por request (ms):
- p50 / p95 (ms):
- Tamano promedio del payload (KB):
- Uso de CPU / memoria (estimado):

## Pruebas realizadas
- Videos reales (listado con condiciones de luz):
  - Caso 1:
  - Caso 2:
  - Caso 3:
- Comparacion con pulsometro:
- Tiempo promedio de respuesta (ms):

## Tests
- Unit tests:
- Integration tests:
- Benchmarks de latencia:



## Notas para E3
- 

## Backlog tecnico relacionado
- Manejar calibracion por tono de piel.
- Ajuste de bandpass por dispositivo.
- Mejoras en detectado de movimiento.

## Evidencia para auditoria
- Commit(s):
- Build/CI:
- Tags / release:
