# Análisis de precios de combustibles en Argentina

**Ciencia de Datos para Economía y Negocios — FCE-UBA 2025**  
Grupo 2 · Giganti, Tobías · Maidana, Pablo · Tannenbaum, Ignacio

---

## Descripción

Este trabajo analiza las diferencias regionales en los precios de nafta súper (92–95 RON) en estaciones de servicio de Argentina durante 2025. Se busca explicar por qué los precios varían entre provincias y regiones, considerando factores logísticos, impositivos y de competencia.

**Hipótesis principal:** Los precios de los combustibles presentan diferencias significativas entre regiones de Argentina, explicadas por la distancia a los centros de refinación, el nivel de competencia local y las diferencias impositivas provinciales.

**Fuente de datos:** Secretaría de Energía — Resolución 314/2016 ([datos.gob.ar](https://datos.gob.ar))

---

## Nota sobre la base de datos cruda (*)

El archivo `precios-historicosULTIMO.csv` no está incluido en este repositorio porque supera el límite de tamaño de GitHub (~300MB). Se puede descargar directamente desde:

**URL de descarga:**  
http://datos.energia.gob.ar/dataset/1c181390-5045-475e-94dc-410429be4b17/resource/f8dda0d5-2a9f-4d34-b79b-4e63de3995df/download/precios-historicos.csv

Una vez descargado, guardar el archivo en la carpeta `raw/` con el nombre `precios-historicosULTIMO.csv` antes de correr los scripts.

---

## Estructura del repositorio

```
ECONOMETRIA/
├── raw/
│   └── precios-historicosULTIMO.csv        # Base cruda — descargar desde URL arriba (*)
├── input/
│   └── nafta_super_2025_limpio.csv         # Base filtrada y limpia (output de 01_limpieza.R)
├── output/
│   ├── grafico_comunicacional.png          # Gráfico comunicacional
│   ├── grafico_exploratorio.png            # Gráfico exploratorio / boxplot
│   ├── grafico_anova.png                   # Gráfico de precios promedio por región
│   ├── grafico_variacion_interanual.png    # Evolución de precios 2017–2025
│   ├── anova_resultados.txt                # Resultados del ANOVA y supuestos
│   ├── tukey_resultados.txt                # Test post-hoc de Tukey
│   ├── regresion_resultados.txt            # Resultados de la regresión lineal
│   └── variacion_interanual_resultados.txt # Tabla de variación interanual
├── scripts/
│   ├── 00_descriptivo.R                    # Estadísticas descriptivas
│   ├── 01_limpieza.R                       # Limpieza y preparación de datos
│   ├── 02_anova.R                          # ANOVA por región + test de Tukey
│   ├── 03_regresion.R                      # Regresión lineal múltiple
│   ├── 04_variacion_interanual.R           # Análisis de variación interanual
│   ├── 05_grafico_comunicacional.R         # Gráfico comunicacional
│   └── 06_grafico_exploratorio.R           # Gráfico exploratorio / boxplot
├── presentacion_final.pptx                 # Presentación de la entrega final
└── README.md
```

---

## Orden de ejecución de los scripts

Antes de correr cualquier script, establecer el directorio de trabajo en R:

```r
setwd("ruta/a/ECONOMETRIA")
```

Los scripts deben correrse en el siguiente orden:

| Orden | Script | Descripción | Input | Output |
|-------|--------|-------------|-------|--------|
| 1 | `scripts/00_descriptivo.R` | Estadísticas descriptivas generales y por región | `raw/precios-historicosULTIMO.csv` | Salida en consola |
| 2 | `scripts/01_limpieza.R` | Filtra la base cruda, elimina errores de carga y outliers | `raw/precios-historicosULTIMO.csv` | `input/nafta_super_2025_limpio.csv` |
| 3 | `scripts/02_anova.R` | ANOVA de precio por región + test de Tukey | `input/nafta_super_2025_limpio.csv` | `output/grafico_anova.png`, `output/anova_resultados.txt`, `output/tukey_resultados.txt` |
| 4 | `scripts/03_regresion.R` | Regresión lineal: precio ~ región + marca + distancia | `input/nafta_super_2025_limpio.csv` | `output/regresion_resultados.txt` |
| 5 | `scripts/04_variacion_interanual.R` | Evolución de precios por región 2017–2025 | `raw/precios-historicosULTIMO.csv` | `output/grafico_variacion_interanual.png`, `output/variacion_interanual_resultados.txt` |
| 6 | `scripts/05_grafico_comunicacional.R` | Gráfico comunicacional de precios por región | `input/nafta_super_2025_limpio.csv` | `output/grafico_comunicacional.png` |
| 7 | `scripts/06_grafico_exploratorio.R` | Boxplot de distribución de precios por provincia | `input/nafta_super_2025_limpio.csv` | `output/grafico_exploratorio.png` |

---

## Paquetes de R requeridos

Instalar antes de correr los scripts:

```r
install.packages(c("tidyverse", "scales"))
```

---

## Decisiones metodológicas clave

- **Filtro de producto:** Se trabajó únicamente con nafta súper (92–95 RON) en horario diurno para evitar comparar precios de distintos productos o tarifas nocturnas.
- **Filtro de año:** Se usó 2025 como corte transversal.
- **Limpieza de outliers:** Se eliminaron registros con precios fuera del rango $800–$2.500/litro. Los valores superiores a $5.000 son errores de tipeo (precio sin punto decimal). Los 5 registros sin coordenadas geográficas también fueron eliminados.
- **Regionalización:** Las 24 provincias fueron agrupadas en 5 regiones geográficas: Centro, NEA, NOA, Cuyo/Comahue y Patagonia.
- **Variable distancia:** Se calculó la distancia en línea recta de cada estación a la refinería más cercana entre las 5 principales del país.
- **Categoría de referencia:** En el ANOVA y la regresión, la categoría de referencia es la región Centro y la marca AXION, siguiendo la sugerencia del docente de usar CABA/Centro como benchmark.

---

## Principales hallazgos

- El ANOVA confirma diferencias significativas entre regiones (F = 599,6; p < 2×10⁻¹⁶).
- **Patagonia** tiene los precios más bajos ($1.110 promedio), no los más altos, debido a exenciones impositivas provinciales.
- La regresión explica el 25% de la variación en precios (R² = 0,25). Los factores más relevantes son la región y la marca; la distancia a la refinería tiene efecto positivo pero pequeño.
- Las diferencias regionales son **estables en el tiempo** (2017–2025), lo que indica que no son diferencias puntuales sino que se mantienen a lo largo de los años.
