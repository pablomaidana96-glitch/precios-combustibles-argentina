# ============================================================
# 03_regresion.R
# Regresion lineal multiple - Precios de nafta super 2025
# Trabajo Practico Grupo 2 - Ciencia de Datos para Economia
# Input:  input/nafta_super_2025_limpio.csv
# Output: output/regresion_resultados.txt
# ============================================================

library(tidyverse)

# ---- 1. CARGA ----
df <- read_csv("input/nafta_super_2025_limpio.csv", show_col_types = FALSE)

# Region como factor con Centro como referencia
df <- df %>%
  mutate(region = factor(region, levels = c("Centro", "NEA", "NOA",
                                             "Cuyo/Comahue", "Patagonia")))

cat("Filas cargadas:", nrow(df), "\n")

# ---- 2. VARIABLE DISTANCIA ----
# Calculamos la distancia en km de cada estacion a la refineria mas cercana
# usando la distancia en linea recta entre coordenadas geograficas

refinerias <- tribble(
  ~nombre,         ~lat,      ~lon,
  "La Plata",      -34.9205,  -57.9536,
  "Campana",       -34.1653,  -58.9556,
  "Lujan de Cuyo", -33.0539,  -68.8820,
  "San Lorenzo",   -32.7449,  -60.7326,
  "Campo Duran",   -22.6167,  -63.6833
)

# Funcion de distancia entre dos puntos geograficos (en km)
dist_km <- function(lat1, lon1, lat2, lon2) {
  R <- 6371  # radio de la Tierra en km
  dlat <- (lat2 - lat1) * pi / 180
  dlon <- (lon2 - lon1) * pi / 180
  a <- sin(dlat/2)^2 + cos(lat1*pi/180) * cos(lat2*pi/180) * sin(dlon/2)^2
  2 * R * asin(sqrt(a))
}

# Para cada estacion calculamos la distancia a cada refineria
# y nos quedamos con la minima (refineria mas cercana)
df <- df %>%
  rowwise() %>%
  mutate(
    dist_refineria = min(
      dist_km(latitud, longitud, refinerias$lat[1], refinerias$lon[1]),
      dist_km(latitud, longitud, refinerias$lat[2], refinerias$lon[2]),
      dist_km(latitud, longitud, refinerias$lat[3], refinerias$lon[3]),
      dist_km(latitud, longitud, refinerias$lat[4], refinerias$lon[4]),
      dist_km(latitud, longitud, refinerias$lat[5], refinerias$lon[5])
    )
  ) %>%
  ungroup()

cat("\nDistancia a refineria mas cercana (km):\n")
df %>% summarise(
  promedio = round(mean(dist_refineria), 1),
  mediana  = round(median(dist_refineria), 1),
  minimo   = round(min(dist_refineria), 1),
  maximo   = round(max(dist_refineria), 1)
) %>% print()

# ---- 3. REGRESION LINEAL MULTIPLE ----
# precio ~ region + marca + distancia a refineria
# Usamos las 8 marcas mas frecuentes
top_marcas <- df %>%
  count(empresabandera, sort = TRUE) %>%
  slice_head(n = 8) %>%
  pull(empresabandera)

df_reg <- df %>%
  filter(empresabandera %in% top_marcas) %>%
  mutate(empresabandera = factor(empresabandera))

cat("\nFilas usadas en la regresion:", nrow(df_reg), "\n")

modelo_reg <- lm(precio ~ region + empresabandera + dist_refineria,
                 data = df_reg)

cat("\n=== REGRESION LINEAL MULTIPLE ===\n")
print(summary(modelo_reg))

# ---- 4. GUARDAR RESULTADOS ----
dir.create("output", showWarnings = FALSE)
sink("output/regresion_resultados.txt")
cat("=== REGRESION LINEAL MULTIPLE ===\n")
cat("Variable dependiente: precio ($/litro)\n")
cat("Variables independientes: region, marca/bandera, distancia a refineria\n\n")
print(summary(modelo_reg))
sink()
cat("Resultados guardados en output/regresion_resultados.txt\n")
