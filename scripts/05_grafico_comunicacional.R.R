# ============================================================
# 01_grafico_comunicacional.R
# Gráfico comunicacional: precio promedio de nafta súper por región
# Tipo: gráfico de barras horizontal (lollipop)
# Mensaje: las regiones más alejadas de las refinerías pagan más
# Trabajo Práctico Grupo 2 — Ciencia de Datos para Economía
# ============================================================

library(tidyverse)
library(scales)
library(ggtext)   # para texto enriquecido en ggplot (instalar si no tienen: install.packages("ggtext"))

# ---- 1. CARGAR DATOS LIMPIOS ----
# (correr 00_descriptivo.R primero para generar este archivo)
df_nafta <- read_csv("datos/nafta_super_limpio.csv")

# ---- 2. CALCULAR PRECIO PROMEDIO POR REGIÓN ----
precio_nacional <- mean(df_nafta$precio, na.rm = TRUE)

resumen_region <- df_nafta %>%
  group_by(region) %>%
  summarise(
    precio_promedio = mean(precio, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  ) %>%
  filter(region != "Sin clasificar") %>%
  mutate(
    diferencia_pct = (precio_promedio / precio_nacional - 1) * 100,
    # Etiqueta para mostrar en el gráfico
    etiqueta = paste0("$", format(round(precio_promedio, 0), big.mark = ".")),
    # Color focal: destacar la región más cara
    es_mas_cara = precio_promedio == max(precio_promedio)
  ) %>%
  arrange(precio_promedio) %>%
  mutate(region = fct_inorder(region))  # mantener orden para ggplot

# ---- 3. PREPARAR COLORES ----
# Paleta: gris para la mayoría, color destacado para la más cara
color_destacado <- "#C0392B"   # rojo para la región más cara
color_normal    <- "#7F8C8D"   # gris para el resto
color_promedio  <- "#2C3E50"   # azul oscuro para la línea de promedio nacional

resumen_region <- resumen_region %>%
  mutate(color = if_else(es_mas_cara, color_destacado, color_normal))

# ---- 4. CONSTRUIR EL GRÁFICO ----
grafico_comunicacional <- ggplot(resumen_region,
                                 aes(x = precio_promedio, y = region)) +

  # Línea vertical: promedio nacional
  geom_vline(
    xintercept = precio_nacional,
    color      = color_promedio,
    linewidth  = 0.8,
    linetype   = "dashed"
  ) +

  # Segmento (palo del lollipop)
  geom_segment(
    aes(x = 0, xend = precio_promedio, y = region, yend = region, color = color),
    linewidth = 1.2
  ) +

  # Punto (cabeza del lollipop)
  geom_point(
    aes(color = color),
    size = 5
  ) +

  # Etiqueta de precio sobre cada punto
  geom_text(
    aes(label = etiqueta, color = color),
    hjust  = -0.25,
    size   = 3.8,
    fontface = "bold"
  ) +

  # Etiqueta de la línea de promedio nacional
  annotate(
    "text",
    x     = precio_nacional,
    y     = 0.5,
    label = paste0("Promedio\nnacional\n$", format(round(precio_nacional, 0), big.mark = ".")),
    color = color_promedio,
    size  = 3.2,
    hjust = 1.1,
    lineheight = 0.9
  ) +

  # Escala de colores manual
  scale_color_identity() +

  # Escala del eje x
  scale_x_continuous(
    labels = label_dollar(prefix = "$", big.mark = "."),
    expand = expansion(mult = c(0, 0.18))
  ) +

  # Títulos y fuente
  labs(
    title    = "Cargar nafta en la Patagonia cuesta significativamente más\nque en el Centro del país",
    subtitle = "Precio promedio de nafta súper por región (en pesos por litro)",
    caption  = "Fuente: Secretaría de Energía — Resolución 314/2016 | datos.gob.ar",
    x        = "Precio promedio ($/litro)",
    y        = NULL
  ) +

  # Tema limpio
  theme_minimal(base_size = 13) +
  theme(
    plot.title       = element_text(face = "bold", size = 14, lineheight = 1.2,
                                    margin = margin(b = 6)),
    plot.subtitle    = element_text(color = "gray40", size = 11,
                                    margin = margin(b = 16)),
    plot.caption     = element_text(color = "gray55", size = 8,
                                    margin = margin(t = 12)),
    axis.text.y      = element_text(size = 12, face = "bold"),
    axis.text.x      = element_text(size = 10, color = "gray50"),
    axis.title.x     = element_text(size = 10, color = "gray50",
                                    margin = margin(t = 8)),
    panel.grid.major.y = element_blank(),
    panel.grid.major.x = element_line(color = "gray90"),
    panel.grid.minor   = element_blank(),
    plot.margin        = margin(20, 30, 15, 20)
  )

# ---- 5. GUARDAR ----
dir.create("output", showWarnings = FALSE)

ggsave(
  filename = "output/grafico_comunicacional.png",
  plot     = grafico_comunicacional,
  width    = 10,
  height   = 6,
  dpi      = 300,
  bg       = "white"
)

message("Gráfico comunicacional guardado en output/grafico_comunicacional.png")

# Ver el gráfico
print(grafico_comunicacional)
