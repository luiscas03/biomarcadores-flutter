# E5 Dia5 - Final Pack (evidencia web)

Rol: Auditor Tecnico + PM de entregables. Documento basado solo en evidencia web declarada. Si no hay link publico verificable, se marca FALTANTE.

## Evidencia web declarada (sin verificacion)
- Repos:
  - App: https://github.com/luiscas03/biomarcadores-flutter.git
  - FastAPI: https://github.com/luiscas03/glucosa-fastapi.git
- Staging / URLs:
  - https://biomarcadores.vercel.app/health
  - https://biomarcadores.vercel.app/docs
  - https://biomarcadores.vercel.app/api/v1/ppg/measure
  - https://biomarcadores.vercel.app/api/v1/glucose/predict
  - https://glucosa-fastapi.onrender.com/docs
  - https://glucosa-fastapi.onrender.com/api/v1/ppg/measure
  - https://glucosa-fastapi.onrender.com/api/v1/glucose/predict
  - https://rf-glucosamujeres.onrender.com/docs

Nota: Los reportes y capturas existen en .md segun proyecto, pero para auditoria web se requieren links directos (GitHub/Drive/URL publico). Actualmente no hay links directos en este pack.

## E5 - Checklist y evidencia

### E5.1 Prediccion 2-4h (predict-forward + critical_points)
- Que exige: endpoint /api/v1/forecast/predict-forward con prediccion 2-4h y puntos criticos.
- Que entrego: FALTANTE.
- Evidencia (web): FALTANTE.
- Como reproducir: POST real al endpoint y adjuntar JSON publico.
- Estado: FALTANTE.

### E5.2 Alertas (hypo/hyper/rapid/meal/activity)
- Que exige: reglas + persistencia + endpoint de alertas (y push si aplica).
- Que entrego: FALTANTE.
- Evidencia (web): FALTANTE.
- Como reproducir: endpoint + logs/JSON publicos.
- Estado: FALTANTE.

### E5.3 Sync offline-first (cola + reconciliacion)
- Que exige: cola local, sync bidireccional, reconciliacion por timestamp.
- Que entrego: FALTANTE.
- Evidencia (web): FALTANTE.
- Como reproducir: demo offline/online con video publico y logs.
- Estado: FALTANTE.

### E5.4 Deploy full stack (docker-compose + healthchecks)
- Que exige: docker-compose full stack, healthchecks, frontend+api accesibles.
- Que entrego: FALTANTE.
- Evidencia (web): FALTANTE.
- Como reproducir: repo con docker-compose + capturas publicas.
- Estado: FALTANTE.

### E5.5 CI/CD automatizado + monitoreo
- Que exige: pipeline tests->build->deploy y paneles/logs.
- Que entrego: FALTANTE.
- Evidencia (web): FALTANTE.
- Como reproducir: link a pipeline y logs publicos.
- Estado: FALTANTE.

## Re-auditoria E1-E4 (resumen web)

### E1 - Setup + Captura rPPG
- Evidencia web declarada: /health y /docs en Vercel.
- Estado: Parcial (sin capturas ni JSON publico).
- Faltante: links directos a JSON de /health y captura de /docs, CI/CD, ADR y contrato API.

### E2 - Extraccion PPG + senal limpia
- Evidencia web declarada: endpoint /api/v1/ppg/measure (Vercel/Render).
- Estado: Parcial/FALTANTE (sin JSON real ni validacion).
- Faltante: request/response publico, grafica de senal, validacion CHROM 3 tonos.

### E3 - UI + Historico local
- Evidencia web declarada: no hay links publicos.
- Estado: FALTANTE.
- Faltante: video/capturas publicas del flujo completo.

### E4 - ML + Estimacion de glucosa
- Evidencia web declarada: endpoint /api/v1/glucose/predict (Render/Vercel).
- Estado: Parcial/FALTANTE.
- Faltante: JSON real publico de predict, reporte R2/MAE con dataset/split/seed, tests/coverage, model card.

## Scoring (basado solo en evidencia web)
- E1: 15/100 (URLs declaradas, sin evidencia verificable).
- E2: 5/100 (endpoint declarado, sin JSON ni validacion).
- E3: 0/100 (sin evidencia web).
- E4: 5/100 (endpoint declarado, sin metricas ni JSON).
- E5: 0/100 (sin evidencia).
- TOTAL: 25/500.

## Quick Wins para subir puntaje (web)
1) Publicar evidencia en GitHub (o Drive) con links directos:
   - JSON de /health, /openapi.json, /api/v1/ppg/measure, /api/v1/glucose/predict.
2) Subir video del flujo UI y capturas de graficas con tooltips.
3) Subir reporte ML (R2/MAE, dataset, split, seed) y Model Card.
4) Publicar pipeline CI/CD y docker-compose (link directo).

## Guion de demo (5 minutos)
1) Abrir /health y /docs (links publicos).
2) Ejecutar POST real a /api/v1/ppg/measure y mostrar JSON publico.
3) Abrir demo UI (video publico) con flujo completo.
4) Ejecutar POST real a /api/v1/glucose/predict y mostrar JSON publico.
