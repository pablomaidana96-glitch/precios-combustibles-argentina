# ============================================================
# 00_descriptivo.R
# Estadísticas descriptivas — Precios de combustible en Argentina
# Trabajo Práctico Grupo 2 — Ciencia de Datos para Economía
# Fuente: Secretaría de Energía, Resolución 314/2016
# Columnas relevantes: provincia, producto, precio, empresabandera,
#                      tipohorario, anio, mes, localidad, latitud, longitud
# ============================================================

library(tidyverse)
library(scales)

# ---- 1. CARGA ----
# Descargar desde datos.gob.ar (archivo histórico):
url_historicos <- "http://datos.energia.gob.ar/dataset/1c181390-5045-475e-94dc-410429be4b17/resource/f8dda0d5-2a9f-4d34-b79b-4e63de3995df/download/precios-historicos.csv"

message("Descargando... puede tardar varios minutos (archivo ~300MB)")
df_raw <- read_csv(url_historicos, locale = locale(encoding = "UTF-8"))

# ---- 2. LIMPIEZA ----
df <- df_raw %>%
  filter(
    producto    == "Nafta (súper) entre 92 y 95 Ron",
    tipohorario == "Diurno",
    anio        == 2025,
    precio      > 200
  ) %>%
  select(provincia, localidad, producto, precio,
         empresabandera, latitud, longitud, anio, mes)

cat("Filas:", nrow(df), "\n")

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

# ---- 4. ESTADÍSTICAS DESCRIPTIVAS ----
precio_nacional <- mean(df$precio)

cat("\n=== RESUMEN GENERAL ===\n")
df %>% summarise(
  n                = n(),
  precio_promedio  = mean(precio),
  precio_mediana   = median(precio),
  desvio           = sd(precio),
  cv_pct           = sd(precio)/mean(precio)*100,
  minimo           = min(precio),
  maximo           = max(precio)
) %>% print()

cat("\n=== POR REGIÓN ===\n")
df %>%
  group_by(region) %>%
  summarise(n=n(), promedio=mean(precio), mediana=median(precio),
            desvio=sd(precio), .groups="drop") %>%
  mutate(vs_nacional_pct = round((promedio/precio_nacional-1)*100, 1)) %>%
  arrange(desc(promedio)) %>%
  print()

cat("\n=== POR PROVINCIA ===\n")
df %>%
  group_by(provincia, region) %>%
  summarise(n=n(), promedio=mean(precio), mediana=median(precio),
            desvio=sd(precio), .groups="drop") %>%
  arrange(desc(promedio)) %>%
  print(n=30)

cat("\n=== POR MARCA (top 8) ===\n")
df %>%
  group_by(empresabandera) %>%
  summarise(n=n(), promedio=mean(precio), .groups="drop") %>%
  arrange(desc(n)) %>% slice_head(n=8) %>% print()

# ---- 5. GUARDAR ----
dir.create("datos", showWarnings=FALSE)
write_csv(df, "datos/nafta_super_2025.csv")
message("Guardado en datos/nafta_super_2025.csv")
