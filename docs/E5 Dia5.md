# E5 Dia5 - Final Pack (E5 + Re-auditoria E1-E4) — ACTUALIZADO con evidencia local (2026-01-18)

Rol: Auditor Tecnico + PM de entregables.

> Documento basado en la evidencia **del repo** + evidencia **local generada** (archivos `evidence_*.json`).
> Lo faltante se marca como FALTANTE.

## Resumen ejecutivo
- **Estado E5:** FALTANTE (sin evidencia de prediccion 2-4h, alertas, sync offline, deploy full stack, CI/CD o monitoreo).
- **Nueva evidencia local (Audit Client):**
  - GET `/` y GET `/health` y GET `/openapi.json` (status 200).
  - POST `/api/v1/ppg/measure` (status 200) retorna `bpm/confidence/quality/fps/method` + `signal/timestamps`.
- **Re-auditoria E1-E4:** E1 y E2 pasan de “sin JSON real” a “con JSON real” (aun faltan video/validaciones). E3 sigue Parcial. E4 sigue FALTANTE.

## Evidencia disponible (inventario rapido)

### Evidencia local generada (recomendado adjuntar en `audit_pack/evidence/`)
- `evidence_root_request.json` + `evidence_root_response.json`
- `evidence_health_request.json` + `evidence_health_response.json`
- `evidence_openapi.json_request.json` + `evidence_openapi.json_response.json`
- `evidence_api_v1_ppg_measure_request.json` + `evidence_api_v1_ppg_measure_response.json`
- `evidence_ppg_summary.json` (resumen ligero de PPG)

**Nota de seguridad:** los `evidence_*_request.json` deben quedar **sanitizados** (ej. `X-API-Key = "<REDACTED>"`). Evita adjuntar archivos con la API key real.

### Evidencia repo / staging (ya declarada)
- Reportes diarios: `docs/E2 Día2.md`, `docs/E3 Día3.md`, `docs/E4 Día4.md`.
- Capturas UI: `docs/images/dashboard_design.jpeg`, `docs/images/measure_screen.jpeg`, `docs/images/scan_screen.jpeg`, `docs/images/Resultado.jpeg`, `docs/images/Historico.jpeg`.
- URLs staging declaradas:
  - `https://biomarcadores.vercel.app/health`
  - `https://biomarcadores.vercel.app/docs`
  - `https://biomarcadores.vercel.app/api/v1/ppg/measure`
  - `https://biomarcadores.vercel.app/api/v1/glucose/predict`
  - `https://glucosa-fastapi.onrender.com/docs`
  - `https://glucosa-fastapi.onrender.com/api/v1/ppg/measure`
  - `https://glucosa-fastapi.onrender.com/api/v1/glucose/predict`

## E5 - Checklist y evidencia

### E5.1 Prediccion 2-4h (endpoint predict-forward + critical_points)
- Que exige: endpoint `/api/v1/forecast/predict-forward` con prediccion 2-4h y puntos criticos.
- Que entrego: FALTANTE.
- Evidencia: FALTANTE.
- Como reproducir: ejecutar POST real al endpoint y adjuntar JSON.
- Estado: FALTANTE.

### E5.2 Alertas (hypo/hyper/rapid/meal/activity)
- Que exige: reglas + persistencia + endpoint de alertas (y push si aplica).
- Que entrego: FALTANTE.
- Evidencia: FALTANTE.
- Como reproducir: ejecutar endpoint de alertas con payload real y adjuntar JSON/logs.
- Estado: FALTANTE.

### E5.3 Sync offline-first (cola + reconciliacion)
- Que exige: cola local, sync bidireccional, reconciliacion por timestamp.
- Que entrego: FALTANTE.
- Evidencia: FALTANTE.
- Como reproducir: demo offline/online y logs de sync.
- Estado: FALTANTE.

### E5.4 Deploy full stack en staging (docker-compose, healthchecks)
- Que exige: docker-compose full stack, healthchecks, frontend+api accesibles.
- Que entrego: FALTANTE.
- Evidencia: FALTANTE.
- Como reproducir: `docker-compose up` + capturas de /health y UI.
- Estado: FALTANTE.

### E5.5 CI/CD automatizado + monitoreo/logs
- Que exige: pipeline tests->build->deploy y paneles/logs.
- Que entrego: FALTANTE.
- Evidencia: FALTANTE.
- Como reproducir: link a pipeline y evidencia de ejecucion exitosa.
- Estado: FALTANTE.

## Re-auditoria E1-E4 (remediacion)

### E1 - Setup + Captura rPPG
- Evidencia actual:
  - URLs declaradas en `docs/E3 Día3.md` y capturas UI en `docs/images`.
  - **Evidencia local (JSON real):**
    - Root (`GET /`):

```json
{
  "status": 200,
  "ok": true,
  "service": "API Glucosa RF",
  "docs": "/docs",
  "health": "/health"
}
```

    - Health (`GET /health`) — expone features esperadas y columnas:

```json
{
  "status": 200,
  "ok": null,
  "service": null,
  "model": null,
  "pipeline_steps": null,
  "has_named_steps": null,
  "features_esperadas": 38,
  "num_cols": [
    "Edad_Años",
    "ips_codigo",
    "edad",
    "talla",
    "peso",
    "imc",
    "tas",
    "tad",
    "perimetro_abdominal",
    "puntaje_total",
    "Consumo_Cigarrillo",
    "riesgo_dm"
  ],
  "cat_cols": [
    "Grupo_Analito",
    "Regimen",
    "tipo_identificacion",
    "sexo",
    "genero",
    "Etniats",
    "Poblacion_Victima",
    "Condicion_Discapacidad",
    "Zona_Residencia",
    "direccion",
    "telefono",
    "Municipio",
    "ocupacion",
    "regimen",
    "EPS",
    "imc_interpretacion",
    "Obesidad_Grado",
    "realiza_ejercicio",
    "frecuencia_frutas",
    "medicamentos_hta",
    "Niveles_Altos_Glucosa",
    "Dx_Diabetes_Tipo2_Familia",
    "Dm",
    "tipo_dm",
    "Dx Enfermedad Cardiovascular",
    "interpretacion"
  ]
}
```

    - OpenAPI (`GET /openapi.json`) — contratos disponibles (nota: el path `/openapi.json` no suele listarse dentro de `paths`, pero el JSON se descarga OK):

```json
{
  "status": 200,
  "title": "API Glucosa RF",
  "version": "1.0",
  "paths": [
    "/",
    "/health",
    "/predict",
    "/predict_typed",
    "/api/v1/glucose/predict",
    "/api/v1/glucose/predict_typed",
    "/api/v1/ppg/measure"
  ]
}
```

- Estado: Parcial (mejorado con JSON real).
- Faltante clave para puntaje alto:
  - Video con 30fps+ y flash activo (evidencia de captura real).
  - CI/CD, README/ADR, contrato API publicado en staging (no solo local).

### E2 - Extraccion PPG + senal limpia
- Evidencia actual:
  - Estructura de reporte en `docs/E2 Día2.md`.
  - **Evidencia local (JSON real de PPG Measure):**

```json
{
  "status": 200,
  "bpm": 45,
  "confidence": 0,
  "quality": {
    "snr_db": -9.41,
    "motion_pct": 12.02,
    "valid": false
  },
  "fps": 30,
  "method": "CHROM",
  "n_samples": 600,
  "n_timestamps": 600
}
```

  - **Resumen ligero (archivo `evidence_ppg_summary.json`):**

```json
{
  "bpm": 45,
  "confidence": 0,
  "quality": {
    "snr_db": -9.41,
    "motion_pct": 12.02,
    "valid": false
  },
  "fps": 30,
  "method": "CHROM",
  "n_samples": 600
}
```

- Interpretacion rapida:
  - Ya hay respuesta con `bpm/confidence/quality` y `signal/timestamps` (endpoint funcionando).
  - `quality.valid = false` y `snr_db` negativo sugieren que la señal (en este caso sintética o con ruido) no es suficiente para una medicion confiable.

- Estado: Parcial (mejorado con JSON real, falta validacion).
- Faltante clave para puntaje alto:
  - Grafica de señal (100+ puntos) usando `signal` vs `timestamps`.
  - Validacion CHROM con 3 tonos de piel y error <= 5 BPM (y repetir con señal real, no solo sintética).

### E3 - UI + Historico local
- Evidencia actual: capturas en `docs/images` y descripcion en `docs/E3 Día3.md`.
- Estado: Parcial.
- Faltante clave:
  - Video o GIF del flujo completo: dashboard -> medir -> resultado -> guardar -> historico -> filtros -> grafica.
  - Evidencia de persistencia (SQLite con 100+ mediciones) y filtros 24h/7d/30d.

### E4 - ML + Estimacion de glucosa
- Evidencia actual: `docs/E4 Día4.md` reporta R^2=0.280 (no cumple) y faltan tests.
- Estado: FALTANTE.
- Faltante clave:
  - Reporte R^2/MAE con dataset/split/seed.
  - Endpoint `/api/v1/glucose/predict` con request/response completos (igual que hiciste con PPG).
  - Tests + coverage > 80% y Model Card.

## Scoring (basado en evidencia actual)
- E1: 40/100 (URLs + capturas UI + **JSON real** / y /health /openapi; aun falta video + CI/CD + publish staging).
- E2: 35/100 (estructura + **JSON real** /api/v1/ppg/measure; aun falta grafica y validacion CHROM con señal real).
- E3: 45/100 (capturas UI, sin video ni evidencia de persistencia/graficas).
- E4: 5/100 (evidencia de incumplimiento en metricas, sin tests).
- E5: 0/100 (sin evidencia).
- TOTAL: 125/500.

## Quick Wins para +100 puntos (pasos exactos)
1) **PPG completo (E2):**
   - Ya tienes JSON local. Ahora repite en **staging** y adjunta:
     - request/response (sanitizados)
     - grafica de `signal` vs `timestamps`
     - 2-3 ejecuciones con señal real (video) para que `quality.valid` sea true.
2) **Video de UI (E3):**
   - Grabar 1-2 min: dashboard -> medir -> guardar -> historico -> filtros -> grafica.
3) **Salud backend (E1):**
   - Ya tienes JSON local. Ahora captura en staging `/health` y `/docs` con fecha/hora.
4) **ML basico (E4):**
   - Adjuntar reporte R^2/MAE con dataset/split/seed.
   - POST real a `/api/v1/glucose/predict` con JSON completo (request/response sanitizados).

## Guion de demo (5 minutos)
1) Abrir `/health` y `/docs` (Swagger). Captura pantalla.
2) Ejecutar POST real a `/api/v1/ppg/measure` y mostrar JSON + grafica de señal.
3) Abrir app: medir -> resultado -> guardar.
4) Abrir historico: filtros 24h/7d/30d + grafica.
5) Ejecutar POST a `/api/v1/glucose/predict` con JSON completo.

## Links sugeridos para anexos
- Reportes: `docs/E2 Día2.md`, `docs/E3 Día3.md`, `docs/E4 Día4.md`.
- Capturas UI: `docs/images/*`.
- Swagger: `https://biomarcadores.vercel.app/docs`, `https://glucosa-fastapi.onrender.com/docs`.

---

## Anexo A — JSON minimo recomendado para /api/v1/glucose/predict (para evidencia)

> Objetivo: que la auditoria vea **un request real** y su **response real** (con headers sanitizados) igual que hiciste con PPG.

Ejemplo de payload minimo (el mismo que ya probaste):

```json
{
  "tas": 120,
  "tad": 80,
  "edad": 45,
  "peso": 70,
  "talla": 165,
  "perimetro_abdominal": 90,
  "medicamentos_hta": 0,
  "realiza_ejercicio": "si",
  "frecuencia_frutas": "media",
  "ips_codigo": 1
}
```

**Sugerencia para subir puntaje:** vuelve a ejecutar el POST agregando 5 a 10 campos de los que te salen en `campos_faltantes_imputados` (del response de glucose) para demostrar que reduces imputacion (ej. `sexo`, `Zona_Residencia`, `Regimen`, `Municipio`, `EPS`).

Archivos que deberian quedar en `audit_pack/evidence/`:
- `evidence_api_v1_glucose_predict_request.json`
- `evidence_api_v1_glucose_predict_response.json`

---

## Anexo B — Video / GIF (que debe mostrar para auditoria)

Si te piden video o GIF, lo mas efectivo es un **screen recording de 30 a 90 segundos** mostrando flujo completo:

1) Abrir el front (Vercel) o el Audit Client.
2) Hacer **GET /health** (para mostrar que la API esta viva).
3) Ejecutar un **POST /api/v1/ppg/measure** (con PPG sintetico o real) y que salga un resultado.
4) Ejecutar un **POST /api/v1/glucose/predict** (con el JSON minimo de arriba) y que salga `pred_glucosa_mg_dl`.
5) Mostrar que guardas la evidencia (descarga de JSON) o un log/tabla simple (si aplica).

**Tip:** para que Render no se "duerma" en la demo, siempre inicia con `/health` y luego haces los POST.

---

## Anexo C — Estado actual vs. criterios E5 (segun Desglose)

Basado en el documento de desglose, E5 pide (resumen):
- **E5.1** Agente metabolico (recomendaciones contextualizadas).
- **E5.2** Alertas / umbrales basicos.
- **E5.3** Sincronizacion (offline -> online).
- **E5.4** Docker compose (staging local).
- **E5.5** CI/CD (build + deploy automatico).

En este momento tu evidencia fuerte esta en **contrato de API + endpoints vivos** (E1/E2/E4). Para acercarte a 450-500, lo mas importante es:
- Subir el bloque ML de E4 (metricas, modelo, validacion) y que el contrato de API refleje esos outputs.
- Acompanarlo con el video corto mostrando el flujo end-to-end.
