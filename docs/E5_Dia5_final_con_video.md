# E5 Día 5 — Entrega Final (E5 + Re-auditoría E1–E4)

**Fecha:** 2026-01-18  
**Rol:** Auditor técnico + PM de entregables  

> Documento construido con base en la **evidencia real generada** (`evidence_*.json`) + evidencia existente del repo (reportes diarios y capturas).  
> Todo lo que no tenga evidencia verificable se marca como **FALTANTE** o **PARCIAL**.

---

---

## 1) Evidencia disponible (inventario)

### 1.1 Evidencia local (Audit Client) — **adjuntar en `audit_pack/evidence/`**
- `evidence_root_request.json` + `evidence_root_response.json`
- `evidence_health_request.json` + `evidence_health_response.json`
- `evidence_openapi.json_request.json` + `evidence_openapi.json_response.json`
- `evidence_api_v1_ppg_measure_request.json` + `evidence_api_v1_ppg_measure_response.json`
- `evidence_ppg_summary.json` *(resumen ligero de PPG; recomendado para auditoría)*

**Nota de seguridad:** los `evidence_*_request.json` deben estar **sanitizados** (ej. `X-API-Key = "<REDACTED>"`).

### 1.2 Evidencia repo / staging (declarada)
- Reportes diarios: `docs/E2 Día2.md`, `docs/E3 Día3.md`, `docs/E4 Día4.md`.
- Capturas UI: `docs/images/*`.
- URLs staging declaradas:
  - `https://glucosa-fastapi.onrender.com/docs`
  - `https://glucosa-fastapi.onrender.com/api/v1/ppg/measure`
  - `https://glucosa-fastapi.onrender.com/api/v1/glucose/predict`

### 1.3 Evidencia remota nueva (Render) — **confirmada por request/response**
- Endpoint: `https://rf-glucosamujeres.onrender.com/predict`
- Request (mínimo):

```json
{
  "edad": 27,
  "peso": 90,
  "talla": 170
}
```

- Response (ejemplo real):

```json
{
  "pred_glucosa_mg_dl": 103.23,
  "imc_usado": 31.14,
  "campos_faltantes_imputados": ["Categoria_Glucosa", "Edad_Años", "tad", "tas"]
}
```

> **Importante para auditoría:** aunque FastAPI puede “coaccionar” strings a número, para evitar dudas **envía números** (no strings) en el request final.

**Pendiente de empaquetado (recomendado):** guardar estos 2 archivos y enlazarlos desde el repo/Drive:
- `evidence_render_predict_request.json`
- `evidence_render_predict_response.json`

---

## 2) Endpoints verificados (con evidencia JSON)

### 2.1 Base local
- Base URL: `http://127.0.0.1:8000`
- Evidencias:
  - Root: `evidence_root_*`
  - Health: `evidence_health_*`
  - OpenAPI: `evidence_openapi.json_*`
  - PPG: `evidence_api_v1_ppg_measure_*` + `evidence_ppg_summary.json`

### 2.2 Base Render (producción demo)
- Base URL: `https://rf-glucosamujeres.onrender.com`
- Endpoint usado:
  - `POST /predict`

> Si Render “duerme”, en demo siempre inicia con **GET `/health`** (si existe) o abre el `/docs` primero.

---

## 3) Re-auditoría E1–E4 (estado actual)

### E1 — Setup + disponibilidad API
**Qué ya cumple (evidencia fuerte):**
- `GET /` devuelve `{ ok:true, service:"API Glucosa RF", ... }` (200).
- `GET /health` devuelve columnas esperadas y estado del pipeline (200).
- `GET /openapi.json` descarga el contrato OpenAPI (200).

**Pendiente para puntaje alto:**
- Video corto (30–90s) mostrando endpoints en staging y/o Render. ✅ *(ver Sección 5)*
- README de reproducción (pasos + comandos).

**Estado:** **PARCIAL (mejorado)**.

---

### E2 — Extracción PPG + medición (endpoint `POST /api/v1/ppg/measure`)
**Evidencia:** `evidence_ppg_summary.json` (resumen) + request/response completos.

Resumen (copiar/pegar directo):

```json
{
  "bpm": 45,
  "confidence": 0,
  "quality": { "snr_db": -9.41, "motion_pct": 12.02, "valid": false },
  "fps": 30,
  "method": "CHROM",
  "n_samples": 600
}
```

**Lectura rápida (para auditor):**
- El endpoint funciona y entrega `bpm/confidence/quality`.
- `quality.valid=false` y `snr_db` negativo indican que esa señal (en este caso) no es confiable.

**Pendiente para puntaje alto:**
- 2–3 ejecuciones con **señal real** (y/o mejor sintética) donde `quality.valid=true`.
- Gráfica `signal` vs `timestamps` (captura o imagen exportada).

**Estado:** **PARCIAL (mejorado)**.

---

### E3 — UI + histórico
**Evidencia existente:** capturas en `docs/images/*` y descripción en `docs/E3 Día3.md`.

**Pendiente para puntaje alto:**
- **Video/GIF** del flujo completo: dashboard → medir → resultado → guardar → histórico → filtros → gráfica. ✅ *(ver Sección 5)*
- Evidencia de persistencia (ej. SQLite/Storage) con datos y filtros 24h/7d/30d.

**Estado:** **PARCIAL**.

---

### E4 — ML + estimación de glucosa
**Nuevo avance (clave):** ya existe un `POST /predict` en Render con respuesta de glucosa (arriba en 1.3) y aparece en el video demo (Sección 5).

**Pendiente para puntaje alto (lo que más pesa):**
- Reporte de métricas (MAE/RMSE/R²), split y seed.
- `evidence_predict_request.json` + `evidence_predict_response.json` (si pruebas `/predict` en Render)
- `evidence_api_v1_glucose_predict_request.json` + `evidence_api_v1_glucose_predict_response.json` (si pruebas el endpoint versionado `/api/v1/glucose/predict`)
- Tests mínimos (al menos smoke tests del endpoint) y descripción del modelo (Model Card corta).

**Estado:** **PARCIAL (mejorado)**.

---

## 4) E5 — Requerimientos del desglose (qué falta y qué sí se puede “sumar puntos” ya)

> En tu borrador anterior marcabas E5 como **FALTANTE** por no tener forecast/alertas/sync/cicd. (Ver sección “E5 - Checklist y evidencia”.)

### 4.1 Lo que hoy ya suma (sin construir features nuevas)
- Paquete de evidencia JSON ordenado (ya lo tienes).
- Demo grabada (video) mostrando:
  1) `GET /health`
  2) `POST /api/v1/ppg/measure`
  3) `POST /predict` (glucosa)
  4) descarga de `evidence_*.json`

### 4.2 Lo que realmente te pedirán si evalúan E5 como “features”
- **E5.1** Forecast 2–4h (`predict-forward`) + puntos críticos
- **E5.2** Alertas (hypo/hyper/rápidas/comida/actividad)
- **E5.3** Offline-first sync (cola + reconciliación)
- **E5.4** Deploy full stack (docker-compose + healthchecks)
- **E5.5** CI/CD + monitoreo/logs

**Estado:** **PARCIAL (enfoque evidencia).**

---

## 5) Video / GIF (evidencia obligatoria para cerrar alto)

**Link Drive:** `https://drive.google.com/file/d/1wYXPtBucjKQcS_u1NwIsfnKoizIg6MnH/view?usp=sharing`  
**Permisos:** *cualquiera con el enlace puede ver* (si no, el auditor no podrá abrirlo).
**Nombre sugerido:** `E5_demo_end_to_end_2026-01-18.mp4`

**Debe mostrar (30–90s):**
1) Abrir `/docs` o ejecutar `GET /health` (API viva)
2) Ejecutar `POST /api/v1/ppg/measure` y ver JSON
3) Ejecutar `POST /predict` y ver `pred_glucosa_mg_dl`
4) Descargar/mostrar `evidence_*_request.json` y `evidence_*_response.json`

---

## 6) Cómo reproducir (comandos mínimos para auditor)

> Sustituye `<BASE_URL>` por `http://127.0.0.1:8000` o `https://rf-glucosamujeres.onrender.com` según el caso.

### 6.1 Salud
```bash
curl -s <BASE_URL>/health | jq
```

### 6.2 PPG
```bash
curl -s -X POST <BASE_URL>/api/v1/ppg/measure \
  -H 'Content-Type: application/json' \
  -d @evidence_api_v1_ppg_measure_request.json | jq
```

### 6.3 Glucosa (predict)
```bash
curl -s -X POST <BASE_URL>/predict \
  -H 'Content-Type: application/json' \
  -d '{"edad":27,"peso":90,"talla":170}' | jq
```

---

## 7) Puntaje estimado (0 a 500) — basado en evidencia actual

> Estimación orientativa (lo definitivo depende del rubric/auditor).

- **E1:** 50/100 (endpoints + OpenAPI + health con columnas)
- **E2:** 45/100 (PPG endpoint OK + summary; falta validación con señal real + gráfica)
- **E3:** 45/100 (UI en capturas; falta video + persistencia demostrable)
- **E4:** 30/100 (predict de glucosa funcionando; faltan métricas + evidencia formal en archivos)
- **E5:** 20/100 (pack de evidencia + demo; faltan features E5 si el rubric lo exige)

**TOTAL ESTIMADO:** **190/500**

---

## 8) Quick wins (máximo impacto en poco tiempo)

1) **Agregar evidencia formal de Glucosa (E4):**
   - Generar y adjuntar (según endpoint que uses):
     - Si pruebas `/predict` (Render): `evidence_predict_request.json` + `evidence_predict_response.json`
     - Si pruebas `/api/v1/glucose/predict`: `evidence_api_v1_glucose_predict_request.json` + `evidence_api_v1_glucose_predict_response.json`
   - (Si usas Render, pon `<REDACTED>` en headers si aplica.)


3) **Gráfica PPG (E2):**
   - Exportar una imagen con `signal` vs `timestamps` (desde notebook o script simple) + adjuntar.

4) **Reporte ML corto (E4):**
   - Una página con: dataset, split, seed, MAE/RMSE/R² + limitaciones.

---

## Anexo A — JSON mínimo recomendado para `/api/v1/glucose/predict`

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

