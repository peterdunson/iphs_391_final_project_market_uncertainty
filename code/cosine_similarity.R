library(dplyr)
library(tidyr)
library(lsa)
library(ggplot2)

# Read data
raw_data <- read.csv("data/llm_response.csv")

comparison_metrics <- read.csv("data/comparison_metrics.csv")
print(comparison_metrics)

# ===================================================================
# PART 1: ACROSS MODELS - Average prompters, compare models
# ===================================================================

# Step 1: Average across prompters for each model-date combination
model_vectors <- raw_data %>%
   group_by(Date_dec, Model) %>%
   summarise(
      Equities = mean(Equities, na.rm = TRUE),
      Inflation = mean(Inflation, na.rm = TRUE),
      Labor = mean(Labor, na.rm = TRUE),
      Consumer = mean(Consumer, na.rm = TRUE),
      Guidance = mean(Guidance, na.rm = TRUE),
      .groups = "drop"
   )

# Step 2: Calculate across-model disagreement by day
across_model_disagreement <- model_vectors %>%
   group_by(Date_dec) %>%
   summarise(
      Disagreement_Score = {
         current_data <- cur_data()
         
         if(nrow(current_data) < 2) {
            NA 
         } else {
            # Matrix: rows = models, cols = dimensions
            mat <- as.matrix(current_data[, c("Equities", "Inflation", "Labor", "Consumer", "Guidance")])
            
            # Transpose for cosine function (columns = models)
            mat_t <- t(mat)
            
            # Cosine similarity matrix
            sim_matrix <- cosine(mat_t)
            
            # Convert to distance
            dist_matrix <- 1 - sim_matrix
            
            # Average pairwise distance
            distances <- dist_matrix[lower.tri(dist_matrix)]
            mean(distances, na.rm = TRUE)
         }
      },
      .groups = "drop"
   )

# ===================================================================
# PART 2: WITHIN MODELS - Compare prompters within each model
# ===================================================================

# Calculate within-model disagreement (across prompters) - KEEP BY MODEL
within_model_disagreement <- raw_data %>%
   group_by(Date_dec, Model) %>%
   summarise(
      Disagreement_Score = {
         current_data <- cur_data()
         
         if(nrow(current_data) < 2) {
            NA 
         } else {
            # Matrix: rows = prompters, cols = dimensions
            mat <- as.matrix(current_data[, c("Equities", "Inflation", "Labor", "Consumer", "Guidance")])
            
            # Transpose for cosine function
            mat_t <- t(mat)
            
            # Cosine similarity matrix
            sim_matrix <- cosine(mat_t)
            
            # Convert to distance
            dist_matrix <- 1 - sim_matrix
            
            # Average pairwise distance
            distances <- dist_matrix[lower.tri(dist_matrix)]
            mean(distances, na.rm = TRUE)
         }
      },
      .groups = "drop"
   )

# ===================================================================
# PRINT RESULTS
# ===================================================================

cat("\n=== ACROSS MODEL DISAGREEMENT ===\n")
print(across_model_disagreement)

cat("\n=== WITHIN MODEL DISAGREEMENT (by model and date) ===\n")
print(within_model_disagreement)

# ===================================================================
# PLOT 1: ACROSS MODELS
# ===================================================================

ggplot(across_model_disagreement, aes(x = Date_dec, y = Disagreement_Score)) +
   geom_line(linewidth = 1, color = "#E63946") +
   geom_point(size = 3, color = "#E63946") +
   labs(
      title = "Across-Model Disagreement Over Time",
      subtitle = "Cosine Distance Between Models (Averaged Across Prompters)",
      x = "Date (December)",
      y = "Average Cosine Distance"
   ) +
   theme_minimal(base_size = 12) +
   theme(
      plot.title = element_text(face = "bold", size = 14),
      panel.grid.minor = element_blank()
   ) +
   scale_x_continuous(breaks = unique(across_model_disagreement$Date_dec)) +
   scale_y_continuous(limits = c(0, 2), breaks = seq(0, 2, 0.5))

# ===================================================================
# PLOT 2: WITHIN MODELS (SEPARATE LINE FOR EACH MODEL)
# ===================================================================

ggplot(within_model_disagreement, aes(x = Date_dec, y = Disagreement_Score, 
                                      color = Model, shape = Model)) +
   geom_line(linewidth = 1) +
   geom_point(size = 3) +
   labs(
      title = "Within-Model Disagreement Over Time",
      subtitle = "Cosine Distance Between Prompters (Separate for Each Model)",
      x = "Date (December)",
      y = "Average Cosine Distance",
      color = "Model",
      shape = "Model"
   ) +
   theme_minimal(base_size = 12) +
   theme(
      legend.position = "bottom",
      plot.title = element_text(face = "bold", size = 14),
      panel.grid.minor = element_blank()
   ) +
   scale_x_continuous(breaks = unique(within_model_disagreement$Date_dec)) +
   scale_y_continuous(limits = c(0, 2), breaks = seq(0, 2, 0.5))
















library(dplyr)
library(tidyr)
library(ggplot2)
library(gridExtra)

# Filter comparison metrics to Dec 11 onwards
comparison_metrics_filtered <- comparison_metrics %>%
   filter(Date_dec >= 11)

# ===================================================================
# CREATE 2x2 PANEL PLOT - NO NORMALIZATION, EQUAL SPACING
# ===================================================================

# Panel 1: Across-Model Disagreement
p1 <- ggplot(across_model_disagreement, aes(x = factor(Date_dec), y = Disagreement_Score, group = 1)) +
   geom_line(linewidth = 1.2, color = "#E63946") +
   geom_point(size = 4, color = "#E63946") +
   labs(
      title = "Across-Model Disagreement",
      x = "Date (December)",
      y = "Cosine Distance"
   ) +
   theme_minimal(base_size = 12) +
   theme(
      plot.title = element_text(face = "bold", size = 14),
      panel.grid.minor = element_blank()
   )

# Panel 2: VIX
p2 <- ggplot(comparison_metrics_filtered, aes(x = factor(Date_dec), y = VIXCLS, group = 1)) +
   geom_line(linewidth = 1.2, color = "#457B9D") +
   geom_point(size = 4, color = "#457B9D") +
   labs(
      title = "VIX (Volatility Index)",
      x = "Date (December)",
      y = "VIX Value"
   ) +
   theme_minimal(base_size = 12) +
   theme(
      plot.title = element_text(face = "bold", size = 14),
      panel.grid.minor = element_blank()
   )

# Panel 3: Citi Surprise Index
p3 <- ggplot(comparison_metrics_filtered, aes(x = factor(Date_dec), y = CITI_SURPRISE_SCORE, group = 1)) +
   geom_line(linewidth = 1.2, color = "#2A9D8F") +
   geom_point(size = 4, color = "#2A9D8F") +
   labs(
      title = "Citi Economic Surprise Index",
      x = "Date (December)",
      y = "Surprise Score"
   ) +
   theme_minimal(base_size = 12) +
   theme(
      plot.title = element_text(face = "bold", size = 14),
      panel.grid.minor = element_blank()
   ) +
   geom_hline(yintercept = 0, linetype = "dashed", alpha = 0.3)

# Panel 4: EPU
p4 <- ggplot(comparison_metrics_filtered, aes(x = factor(Date_dec), y = USEPUINDXD, group = 1)) +
   geom_line(linewidth = 1.2, color = "#F4A261") +
   geom_point(size = 4, color = "#F4A261") +
   labs(
      title = "Economic Policy Uncertainty Index",
      x = "Date (December)",
      y = "EPU Value"
   ) +
   theme_minimal(base_size = 12) +
   theme(
      plot.title = element_text(face = "bold", size = 14),
      panel.grid.minor = element_blank()
   )

# Combine into 2x2 grid
grid.arrange(p1, p2, p3, p4, ncol = 2)

# ===================================================================
# SEPARATE PLOT: WITHIN-MODEL DISAGREEMENT
# ===================================================================

p_within <- ggplot(within_model_disagreement, aes(x = factor(Date_dec), y = Disagreement_Score, 
                                                  color = Model, shape = Model, group = Model)) +
   geom_line(linewidth = 1.2) +
   geom_point(size = 4) +
   labs(
      title = "Within-Model Disagreement (by Model)",
      subtitle = "Cosine Distance Between Prompters for Each Model",
      x = "Date (December)",
      y = "Cosine Distance",
      color = "Model",
      shape = "Model"
   ) +
   theme_minimal(base_size = 12) +
   theme(
      plot.title = element_text(face = "bold", size = 14),
      panel.grid.minor = element_blank(),
      legend.position = "bottom"
   )

# Display the within-model plot
print(p_within)













#
library(pheatmap)

# ===================================================================
# PREPARE CORRELATION MATRICES FOR HEATMAP
# ===================================================================

# 1. Across-Model Disagreement correlations
correlation_across <- across_model_disagreement %>%
   select(Date_dec, Across_Model = Disagreement_Score) %>%
   left_join(
      comparison_metrics_filtered %>% 
         select(Date_dec, VIX = VIXCLS, Citi_Surprise = CITI_SURPRISE_SCORE, EPU = USEPUINDXD),
      by = "Date_dec"
   )

cor_across <- cor(correlation_across[, -1], use = "pairwise.complete.obs")

# Extract just the row with Across_Model correlations
cor_across_row <- cor_across["Across_Model", c("VIX", "Citi_Surprise", "EPU"), drop = FALSE]

# 2. Within-Model Disagreement correlations (by individual model)
cor_within_list <- list()
for(model_name in unique(within_model_disagreement$Model)) {
   model_data <- within_model_disagreement %>%
      filter(Model == model_name) %>%
      select(Date_dec, Model_Disagreement = Disagreement_Score) %>%
      left_join(
         comparison_metrics_filtered %>% 
            select(Date_dec, VIX = VIXCLS, Citi_Surprise = CITI_SURPRISE_SCORE, EPU = USEPUINDXD),
         by = "Date_dec"
      )
   
   cor_model <- cor(model_data[, -1], use = "pairwise.complete.obs")
   cor_within_list[[model_name]] <- cor_model["Model_Disagreement", c("VIX", "Citi_Surprise", "EPU")]
}

# Combine into matrix
cor_within_matrix <- do.call(rbind, cor_within_list)

# ===================================================================
# PLOT HEATMAPS
# ===================================================================

# Heatmap 1: Across-Model
pheatmap(cor_across_row,
         cluster_rows = FALSE,
         cluster_cols = FALSE,
         display_numbers = TRUE,
         number_format = "%.2f",
         number_color = "black",
         color = colorRampPalette(c("blue", "white", "red"))(100),
         breaks = seq(-1, 1, length.out = 101),
         main = "Across-Model Disagreement Correlations",
         fontsize = 12,
         fontsize_number = 14)

# Heatmap 2: Within-Model (each model separately)
pheatmap(cor_within_matrix,
         cluster_rows = FALSE,
         cluster_cols = FALSE,
         display_numbers = TRUE,
         number_format = "%.2f",
         number_color = "black",
         color = colorRampPalette(c("blue", "white", "red"))(100),
         breaks = seq(-1, 1, length.out = 101),
         main = "Within-Model Disagreement Correlations (by Model)",
         fontsize = 12,
         fontsize_number = 14)


cat("\n=== ACROSS-MODEL DISAGREEMENT CORRELATIONS ===\n")
print(round(cor_across_row, 3))

cat("\n=== WITHIN-MODEL DISAGREEMENT CORRELATIONS (BY MODEL) ===\n")
print(round(cor_within_matrix, 3))



