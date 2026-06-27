# ============================================================
# 01_limpieza.R
# Limpieza y preparación de datos — Precios de nafta súper 2025
# Trabajo Práctico Grupo 2 — Ciencia de Datos para Economía
# Input:  raw/precios-historicosULTIMO.csv
# Output: input/nafta_super_2025_limpio.csv
# ============================================================

library(tidyverse)

# ---- 1. CARGA ----
df_raw <- read_delim(
  "raw/precios-historicosULTIMO.csv",
  delim     = ";",
  locale    = locale(encoding = "UTF-8"),
  show_col_types = FALSE
)

cat("Filas totales en la base cruda:", nrow(df_raw), "\n")

# ---- 2. FILTRO INICIAL ----
# Nos quedamos con nafta súper, horario diurno, año 2025
df <- df_raw %>%
  filter(
    producto    == "Nafta (súper) entre 92 y 95 Ron",
    tipohorario == "Diurno",
    anio        == 2025
  ) %>%
  select(provincia, localidad, empresabandera,
         precio, mes, anio, latitud, longitud, geojson)

cat("Filas tras filtro de producto/año:", nrow(df), "\n")

# ---- 3. REGIONES ----
regiones <- tribble(
  ~provincia,             ~region,
  "BUENOS AIRES",         "Centro",
  "CAPITAL FEDERAL",      "Centro",
  "CORDOBA",              "Centro",
  "ENTRE RIOS",           "Centro",
  "SANTA FE",             "Centro",
  "CHACO",                "NEA",
  "CORRIENTES",           "NEA",
  "FORMOSA",              "NEA",
  "MISIONES",             "NEA",
  "CATAMARCA",            "NOA",
  "JUJUY",                "NOA",
  "LA RIOJA",             "NOA",
  "SALTA",                "NOA",
  "SANTIAGO DEL ESTERO",  "NOA",
  "TUCUMAN",              "NOA",
  "LA PAMPA",             "Cuyo/Comahue",
  "MENDOZA",              "Cuyo/Comahue",
  "NEUQUEN",              "Cuyo/Comahue",
  "RIO NEGRO",            "Cuyo/Comahue",
  "SAN JUAN",             "Cuyo/Comahue",
  "SAN LUIS",             "Cuyo/Comahue",
  "CHUBUT",               "Patagonia",
  "SANTA CRUZ",           "Patagonia",
  "TIERRA DEL FUEGO",     "Patagonia"
)

df <- df %>% left_join(regiones, by = "provincia")

# ---- 4. DETECCIÓN DE OUTLIERS Y ERRORES DE CARGA ----

# Diagnóstico de la distribución de precios
cat("\n=== DISTRIBUCIÓN DE PRECIOS (antes de limpiar) ===\n")
cat("Mínimo:  ", min(df$precio), "\n")
cat("Máximo:  ", max(df$precio), "\n")
cat("Mediana: ", median(df$precio), "\n")
cat("Media:   ", round(mean(df$precio), 1), "\n")

# Hay precios de millones: son errores de tipeo (falta el punto decimal)
# Por ejemplo: 17990000 debería ser 1799.00
# Los precios reales de nafta súper en 2025 estuvieron entre ~$900 y ~$2000/litro
cat("\nPrecios mayores a $5000 (errores de carga):\n")
df %>% filter(precio > 5000) %>% count() %>% print()

cat("\nPrecios menores a $800 (posibles errores):\n")
df %>% filter(precio < 800) %>% count() %>% print()

# ---- 5. LIMPIEZA ----

# Criterio: precios razonables entre $800 y $2500 por litro
# Justificación: en 2025 la nafta súper en Argentina estuvo en ese rango.
# Los valores > $5000 son errores de tipeo (sin punto decimal).
# Los valores < $800 aparecen en meses anteriores (con filtro precio > 200
# del script original se colaban algunos).

n_antes <- nrow(df)

df_limpio <- df %>%
  filter(precio >= 800, precio <= 2500) %>%
  filter(!is.na(latitud), !is.na(longitud))   # eliminamos los 5 sin coordenadas

n_despues <- nrow(df_limpio)

cat("\n=== RESULTADO DE LA LIMPIEZA ===\n")
cat("Filas antes de limpiar: ", n_antes, "\n")
cat("Filas eliminadas:       ", n_antes - n_despues, "\n")
cat("Filas después de limpiar:", n_despues, "\n")
cat("Porcentaje eliminado:   ", round((n_antes - n_despues)/n_antes*100, 1), "%\n")

# ---- 6. ESTADÍSTICAS POST-LIMPIEZA ----
cat("\n=== ESTADÍSTICAS POST-LIMPIEZA ===\n")
df_limpio %>%
  summarise(
    n               = n(),
    precio_promedio = round(mean(precio), 1),
    mediana         = median(precio),
    desvio          = round(sd(precio), 1),
    minimo          = min(precio),
    maximo          = max(precio)
  ) %>% print()

cat("\n=== POR REGIÓN (post-limpieza) ===\n")
df_limpio %>%
  group_by(region) %>%
  summarise(
    n        = n(),
    promedio = round(mean(precio), 1),
    mediana  = median(precio),
    desvio   = round(sd(precio), 1),
    .groups  = "drop"
  ) %>%
  arrange(desc(promedio)) %>%
  print()

# ---- 7. GUARDAR ----
dir.create("input", showWarnings = FALSE)
write_csv(df_limpio, "input/nafta_super_2025_limpio.csv")
message("Guardado en input/nafta_super_2025_limpio.csv")
