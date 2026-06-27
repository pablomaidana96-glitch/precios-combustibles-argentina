# ============================================================
# 02_grafico_exploratorio.R
# Gráfico exploratorio: distribución de precios por provincia
# Tipo: boxplot
# Objetivo: identificar dispersión intra-provincial y outliers
# Trabajo Práctico Grupo 2 — Ciencia de Datos para Economía
# ============================================================

library(tidyverse)
library(scales)

# ---- 1. CARGAR DATOS LIMPIOS ----
# (correr 00_descriptivo.R primero)
df_nafta <- read_csv("datos/nafta_super_limpio.csv")

# ---- 2. PREPARAR DATOS ----

# Calcular mediana por provincia (para ordenar el gráfico)
orden_provincias <- df_nafta %>%
  group_by(provincia, region) %>%
  summarise(mediana = median(precio, na.rm = TRUE), .groups = "drop") %>%
  arrange(mediana)

# Reordenar la variable provincia según mediana de precio
df_nafta <- df_nafta %>%
  mutate(
    provincia = factor(provincia, levels = orden_provincias$provincia),
    region    = factor(region,
                       levels = c("Centro", "NEA", "NOA", "Cuyo/Comahue", "Patagonia"))
  ) %>%
  filter(region != "Sin clasificar")

# Paleta de colores por región
colores_region <- c(
  "Centro"       = "#3498DB",   # azul
  "NEA"          = "#E67E22",   # naranja
  "NOA"          = "#E74C3C",   # rojo
  "Cuyo/Comahue" = "#9B59B6",   # violeta
  "Patagonia"    = "#1ABC9C"    # verde agua
)

# Precio promedio nacional (línea de referencia)
precio_nacional <- mean(df_nafta$precio, na.rm = TRUE)

# ---- 3. CONSTRUIR EL GRÁFICO ----
grafico_exploratorio <- ggplot(df_nafta,
                               aes(x = provincia, y = precio, fill = region)) +

  # Línea horizontal: promedio nacional
  geom_hline(
    yintercept = precio_nacional,
    color      = "gray30",
    linewidth  = 0.6,
    linetype   = "dashed"
  ) +

  # Boxplot por provincia
  geom_boxplot(
    outlier.size  = 0.8,
    outlier.alpha = 0.4,
    width         = 0.7,
    color         = "gray30",
    linewidth     = 0.4
  ) +

  # Escala de colores por región
  scale_fill_manual(values = colores_region, name = "Región") +

  # Escala del eje y
  scale_y_continuous(
    labels = label_dollar(prefix = "$", big.mark = "."),
    expand = expansion(mult = c(0.02, 0.06))
  ) +

  # Anotación del promedio nacional
  annotate(
    "text",
    x     = 1,
    y     = precio_nacional * 1.01,
    label = paste0("Promedio nacional: $", format(round(precio_nacional, 0), big.mark = ".")),
    hjust = 0,
    size  = 3,
    color = "gray30"
  ) +

  # Rotar etiquetas del eje x
  coord_flip() +

  # Títulos
  labs(
    title   = "Distribución de precios de nafta súper por provincia",
    subtitle = "Provincias ordenadas por precio mediano | Cada caja muestra el rango intercuartílico",
    caption  = "Fuente: Secretaría de Energía — Resolución 314/2016 | datos.gob.ar",
    x        = NULL,
    y        = "Precio ($/litro)"
  ) +

  # Tema
  theme_minimal(base_size = 11) +
  theme(
    plot.title      = element_text(face = "bold", size = 13,
                                   margin = margin(b = 6)),
    plot.subtitle   = element_text(color = "gray45", size = 9.5,
                                   margin = margin(b = 14)),
    plot.caption    = element_text(color = "gray55", size = 7.5,
                                   margin = margin(t = 12)),
    axis.text.y     = element_text(size = 9),
    axis.text.x     = element_text(size = 9, color = "gray40"),
    panel.grid.major.y = element_blank(),
    panel.grid.major.x = element_line(color = "gray90"),
    panel.grid.minor   = element_blank(),
    legend.position    = "bottom",
    legend.title       = element_text(size = 9, face = "bold"),
    legend.text        = element_text(size = 9),
    plot.margin        = margin(15, 20, 10, 15)
  )

# ---- 4. GUARDAR ----
dir.create("output", showWarnings = FALSE)

ggsave(
  filename = "output/grafico_exploratorio.png",
  plot     = grafico_exploratorio,
  width    = 10,
  height   = 9,
  dpi      = 300,
  bg       = "white"
)

message("Gráfico exploratorio guardado en output/grafico_exploratorio.png")

# Ver el gráfico
print(grafico_exploratorio)

# ---- 5. ANÁLISIS: ¿QUÉ LLAMA LA ATENCIÓN? ----
cat("\n=== PROVINCIAS CON MAYOR DISPERSIÓN ===\n")
df_nafta %>%
  group_by(provincia, region) %>%
  summarise(
    mediana = median(precio, na.rm = TRUE),
    rango_iq = IQR(precio, na.rm = TRUE),
    desvio  = sd(precio, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(rango_iq)) %>%
  print(n = 10)

cat("\n=== OUTLIERS POTENCIALES (precio > Q3 + 1.5*IQR) ===\n")
outliers <- df_nafta %>%
  group_by(provincia) %>%
  mutate(
    q3  = quantile(precio, 0.75, na.rm = TRUE),
    iqr = IQR(precio, na.rm = TRUE),
    es_outlier = precio > q3 + 1.5 * iqr
  ) %>%
  filter(es_outlier) %>%
  select(provincia, region, localidad, bandera, precio) %>%
  arrange(desc(precio))

cat("Total de outliers:", nrow(outliers), "\n")
print(head(outliers, 20))
