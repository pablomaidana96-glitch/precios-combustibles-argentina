# ============================================================
# 04_variacion_interanual.R
# Variación interanual de precios por provincia — Argentina
# Trabajo Práctico Grupo 2 — Ciencia de Datos para Economía
# Input:  raw/precios-historicosULTIMO.csv
# Output: output/grafico_variacion_interanual.png
#         output/variacion_interanual_resultados.txt
# ============================================================

library(tidyverse)

# ---- 1. CARGA ----
# Para este análisis usamos la base completa (todos los años)
# para poder comparar la evolución entre provincias
df_raw <- read_delim(
  "raw/precios-historicosULTIMO.csv",
  delim          = ";",
  locale         = locale(encoding = "UTF-8"),
  show_col_types = FALSE
)

# ---- 2. FILTRO ----
df <- df_raw %>%
  filter(
    producto    == "Nafta (súper) entre 92 y 95 Ron",
    tipohorario == "Diurno",
    precio      >= 10,        # eliminamos errores evidentes
    precio      <= 5000000    # cap para evitar valores absurdos
  ) %>%
  select(provincia, precio, anio, mes)

cat("Filas tras filtro:", nrow(df), "\n")

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

# ---- 4. PRECIO PROMEDIO ANUAL POR REGIÓN ----
precio_anual <- df %>%
  filter(!is.na(region), anio >= 2017) %>%
  group_by(region, anio) %>%
  summarise(precio_prom = mean(precio), .groups = "drop")

cat("\nPrecio promedio anual por región:\n")
precio_anual %>%
  pivot_wider(names_from = anio, values_from = precio_prom) %>%
  print()

# ---- 5. VARIACIÓN INTERANUAL POR REGIÓN ----
variacion <- precio_anual %>%
  arrange(region, anio) %>%
  group_by(region) %>%
  mutate(
    precio_anterior  = lag(precio_prom),
    variacion_pct    = round((precio_prom / precio_anterior - 1) * 100, 1)
  ) %>%
  filter(!is.na(variacion_pct))

cat("\nVariación interanual (%) por región:\n")
variacion %>%
  select(region, anio, variacion_pct) %>%
  pivot_wider(names_from = anio, values_from = variacion_pct) %>%
  print()

# Guardar resultados
dir.create("output", showWarnings = FALSE)
sink("output/variacion_interanual_resultados.txt")
cat("=== VARIACIÓN INTERANUAL POR REGIÓN ===\n\n")
cat("Precio promedio anual:\n")
precio_anual %>%
  pivot_wider(names_from = anio, values_from = precio_prom) %>%
  print()
cat("\nVariación interanual (%):\n")
variacion %>%
  select(region, anio, variacion_pct) %>%
  pivot_wider(names_from = anio, values_from = variacion_pct) %>%
  print()
sink()
cat("Resultados guardados en output/variacion_interanual_resultados.txt\n")

# ---- 6. GRÁFICO ----
colores_region <- c(
  "Centro"        = "#2C7BB6",
  "NEA"           = "#D7191C",
  "NOA"           = "#1A9641",
  "Cuyo/Comahue"  = "#FF7F00",
  "Patagonia"     = "#984EA3"
)

p <- ggplot(precio_anual, aes(x = anio, y = precio_prom,
                               color = region, group = region)) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2.5) +
  scale_color_manual(values = colores_region) +
  scale_y_continuous(labels = scales::comma_format(prefix = "$")) +
  scale_x_continuous(breaks = seq(2017, 2025, 1)) +
  labs(
    title    = "Evolución del precio de nafta súper por región — Argentina 2017–2025",
    subtitle = "Las diferencias entre regiones se mantienen estables a lo largo del tiempo",
    x        = "Año",
    y        = "Precio promedio ($/litro)",
    color    = "Región",
    caption  = "Fuente: Secretaría de Energía, Resolución 314/2016"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title   = element_text(face = "bold"),
    legend.position = "right"
  )

ggsave("output/grafico_variacion_interanual.png", p,
       width = 10, height = 6, dpi = 150)
message("Gráfico guardado en output/grafico_variacion_interanual.png")

# ---- 7. INTERPRETACIÓN ----
cat("\n=== INTERPRETACIÓN ===\n")
cat("Si las líneas son paralelas entre sí a lo largo del tiempo,\n")
cat("significa que todas las regiones aumentaron sus precios en\n")
cat("proporciones similares — las diferencias regionales son estables.\n")
cat("Si alguna región se 'despega' de las demás en algún año,\n")
cat("sugiere un cambio estructural en esa región (nueva política,\n")
cat("cambio impositivo, shock logístico, etc.)\n")
