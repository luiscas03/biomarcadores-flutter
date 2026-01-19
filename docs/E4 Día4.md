# E4 - ML + Estimacion de glucosa (End of Day)

Objetivo del dia: modelo de glucosa entrenado + endpoint predictivo + reproducibilidad con evidencia y tests.

## Resumen ejecutivo (1-2 lineas)
- Resultado principal:
- Estado general:

## Dependencias previas (E2/E3)
- rPPG estable y validado (E2): CHROM + SNR/motion con evidencia.
- UI lista con historico y graficas (E3): flujo medir -> guardar -> historico.
- Endpoint PPG activo en FastAPI/Django como base para features.

## Repositorios / Entornos
- App (Flutter): C:\Users\Flutter\biomarcad
- Backend (Django / Vercel): C:\Users\Davide\Documents\Proyectos Python\biomarcadores\app | https://biomarcadores.vercel.app
- FastAPI (Render): C:\Users\Modelo_Predicccion | https://glucosa-fastapi.onrender.com
- Staging / URLs:
  - Django /health: https://biomarcadores.vercel.app/health
  - Django /docs: https://biomarcadores.vercel.app/docs
  - Django /api/v1/glucose/predict: https://biomarcadores.vercel.app/api/v1/glucose/predict
  - FastAPI /docs: https://glucosa-fastapi.onrender.com/docs
  - FastAPI /api/v1/ppg/measure: https://glucosa-fastapi.onrender.com/api/v1/ppg/measure
  - FastAPI /predict: https://glucosa-fastapi.onrender.com/predict
  - FastAPI /api/v1/glucose/predict: https://glucosa-fastapi.onrender.com/api/v1/glucose/predict
  - Repositorio app: https://github.com/luiscas03/biomarcadores-flutter.git
  - Repositorio FastApi: https://github.com/luiscas03/glucosa-fastapi.git

## Checklist (DoD del dia)
- [ ] Modelo XGBoost entrenado con 1,000+ muestras (R² > 0.70, MAE < 20 mg/dL).
- [ ] Feature engineering 15+ features con manejo de NaN y tests.
- [ ] API `/api/v1/glucose/predict` < 500ms, valida inputs y retorna valor + confianza + rango + status + recomendacion.
- [ ] Swagger actualizado con schema de request/response.
- [ ] Tests unit + integration + performance, coverage > 80% en prediccion.
- [ ] Model Card + pipeline documentado + versiones pinned + seed fijo.
- [ ] Evidencia minima: metricas (R²/MAE), modelo versionado, endpoint respondiendo, tests verdes.

## Criterios numericos clave
- R² > 0.70
- MAE < 20 mg/dL
- Latencia endpoint < 500ms
- Cobertura tests prediccion > 80%
-- https://drive.google.com/file/d/1Q3l13BxUDx8LJkLe_RbNZJzOAUXkJdJR/view?usp=sharing

## Evidencia tecnica (links y capturas)
- Endpoint predict `/api/v1/glucose/predict` (URL): https://glucosa-fastapi.onrender.com/api/v1/glucose/predict
- Swagger /docs: https://glucosa-fastapi.onrender.com/docs
- Request real + respuesta JSON:
- Reporte de metricas (R²/MAE):
- Model Card:
- Commit(s):
- Build/CI (si aplica):

## Dataset y feature engineering
- Fuente del dataset (link / ruta):
- Tamano dataset (n):
- Split train/val/test:
- Features (15+): (listar)
- Manejo de NaN / outliers:
- Normalizacion / escalado:
- Seed fija:

## Entrenamiento y evaluacion
- Algoritmo: XGBoost (params principales):
- Baseline vs modelo final:
- R² / MAE (train/val/test):
- Validacion cruzada (si aplica):
- Guardado y versionado del modelo:

## API /api/v1/glucose/predict
- Validaciones de input:
- Schema request:
- Schema response:
- Confianza y rango (definicion):
- Status + recomendacion (reglas):
- Latencia (p50/p95):

## Tests
- Unit tests:
- Integration tests:
- Performance tests:
- Cobertura:

## Model Card (minimo)
- Uso previsto:
- Limitaciones:
- Datos de entrenamiento:
- Metricas:
- Version del modelo:

## Revision del proyecto actual (verificado)
- Backend Django: agrega proxy `api/v1/glucose/predict` hacia FastAPI (nuevo).
- FastAPI (Glucosa): agrega alias `POST /api/v1/glucose/predict` (nuevo) ademas de `/predict` y `/predict_typed`.
- Respuesta de `/predict` solo devuelve `pred_glucosa_mg_dl`, `imc_usado`, `campos_faltantes_imputados`; falta confianza, rango, status y recomendacion.
- Modelo cargado por defecto: `modelo_gradient_boosting_2.joblib` (no XGBoost). El informe menciona Random Forest.
- Tests/coverage: no hay carpeta de tests ni referencias a pytest/coverage en el repo FastAPI.
- Metricas: en `A1_C1_V1.ipynb` aparece `R² (test) = 0.280`, por debajo de 0.70.

## Estado vs E4 (gap actual)
- ML existente, pero no cumple criterios de E4 (tipo de modelo, metricas, tests, contracto de respuesta).
- Endpoint operativo en Render, pero falta contrato `/api/v1/glucose/predict` con campos requeridos.
- Sin evidencia formal de reproducibilidad (seed fija, versiones pinned, model card).

## Acciones para subir porcentaje (prioridad)
1) Modelo y metricas:
   - Entrenar XGBoost con 1,000+ muestras.
   - Loggear R² y MAE en test (objetivo R² > 0.70, MAE < 20).
2) Feature engineering:
   - Definir 15+ features y documentarlas.
   - Manejo NaN con tests unitarios.
3) Endpoint:
   - Respuesta incluir: valor, confianza, rango, status, recomendacion.
   - Validaciones estrictas y tiempos < 500ms.
4) Testing y coverage:
   - Unit + integration + performance.
   - Coverage > 80% en prediccion.
5) Reproducibilidad:
   - Seed fija, versions pinned, model card y pipeline documentado.

## Evidencia minima para mejorar E4
- Reporte de metricas (R²/MAE) con dataset y split.
- Modelo versionado (joblib con hash/version).
- Endpoint `/api/v1/glucose/predict` respondiendo con contrato completo.
- Tests verdes con coverage reportado.

## Evidencia minima (lista para enviar)
- Metricas finales: R² = ___ / MAE = ___ (dataset: ___, split: ___, n=___).
- Modelo versionado: archivo ___, hash/versión ___.
- Endpoint funcionando: request/response real adjunto + status 200.
- Swagger actualizado: link y captura.
- Tests: comando ejecutado + coverage ___%.
- Model Card: link / archivo adjunto.

## Keepalive (Render free)
- Workflow GitHub Actions que hace ping cada 15 min:
  - `https://glucosa-fastapi.onrender.com/health`
  - `https://biomarcadores.vercel.app/health`

## Riesgos / pendientes
- 

## Evidencia para auditoria
- Commits:
- Tags / release:
