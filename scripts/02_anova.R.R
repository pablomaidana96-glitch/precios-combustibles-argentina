# ============================================================
# 02_anova.R
# ANOVA de precios de nafta super por region - Argentina 2025
# Trabajo Practico Grupo 2 - Ciencia de Datos para Economia
# Input:  input/nafta_super_2025_limpio.csv
# Output: output/grafico_anova.png
#         output/anova_resultados.txt
# ============================================================

library(tidyverse)

# ---- 1. CARGA ----
df <- read_csv("input/nafta_super_2025_limpio.csv", show_col_types = FALSE)

# Region como factor con Centro como referencia
df <- df %>%
  mutate(region = factor(region, levels = c("Centro", "NEA", "NOA",
                                             "Cuyo/Comahue", "Patagonia")))

cat("Filas cargadas:", nrow(df), "\n")

# ---- 2. ANOVA ----
cat("\n=== ANOVA: precio ~ region ===\n")
modelo_anova <- aov(precio ~ region, data = df)
print(summary(modelo_anova))

# ---- 3. VERIFICACION DE SUPUESTOS ----
cat("\n=== SUPUESTOS DEL ANOVA ===\n")

# Verificamos normalidad de residuos con un histograma
residuos <- residuals(modelo_anova)

cat("Resumen de los residuos:\n")
summary(residuos)

# Guardamos el histograma de residuos
dir.create("output", showWarnings = FALSE)
png("output/histograma_residuos.png", width = 800, height = 500)
hist(residuos,
     main = "Distribucion de residuos del ANOVA",
     xlab = "Residuos",
     ylab = "Frecuencia",
     col = "#2C7BB6",
     border = "white")
dev.off()

cat("Con mas de 10.000 observaciones, el ANOVA es robusto a la falta de\n")
cat("normalidad perfecta por el Teorema Central del Limite.\n")

# ---- 4. TEST POST-HOC DE TUKEY ----
cat("\n=== TEST POST-HOC DE TUKEY ===\n")
cat("Identifica que pares de regiones difieren significativamente:\n\n")
tukey <- TukeyHSD(modelo_anova)
print(tukey)

# ---- 5. GUARDAR RESULTADOS ----
sink("output/anova_resultados.txt")
cat("=== ANOVA: precio ~ region ===\n\n")
print(summary(modelo_anova))
cat("\n=== TEST POST-HOC DE TUKEY ===\n\n")
print(tukey)
sink()
cat("\nResultados guardados en output/anova_resultados.txt\n")

# ---- 6. GRAFICO ----
promedios <- df %>%
  group_by(region) %>%
  summarise(
    promedio  = mean(precio),
    error_std = sd(precio) / sqrt(n()),
    .groups   = "drop"
  ) %>%
  arrange(desc(promedio))

p <- ggplot(promedios, aes(x = reorder(region, promedio), y = promedio)) +
  geom_col(fill = "#2C7BB6", width = 0.6) +
  geom_errorbar(aes(ymin = promedio - error_std,
                    ymax = promedio + error_std),
                width = 0.2, color = "gray30") +
  geom_text(aes(label = paste0("$", round(promedio, 0))),
            hjust = -0.2, size = 3.5) +
  coord_flip() +
  labs(
    title   = "Precio promedio de nafta super por region - Argentina 2025",
    subtitle = "Las barras de error representan el error estandar de la media",
    x       = "Region",
    y       = "Precio promedio ($/litro)",
    caption = "Fuente: Secretaria de Energia, Resolucion 314/2016"
  ) +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"))

ggsave("output/grafico_anova.png", p, width = 8, height = 5, dpi = 150)
message("Grafico guardado en output/grafico_anova.png")
