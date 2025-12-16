library(dplyr)
library(tidyr)
library(lsa)
library(ggplot2)

# Read data
raw_data <- read.csv("data/data.csv")
raw_data <- na.omit(raw_data)

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

# Filter comparison metrics to Dec 11 onwards
comparison_metrics_filtered <- comparison_metrics %>%
   filter(Date_dec >= 11)

print(comparison_metrics_filtered)

# ===================================================================
# MIN-MAX NORMALIZATION USING HISTORICAL RANGES
# ===================================================================

# Define historical min/max for each metric
historical_ranges <- list(
   VIX = c(min = 9, max = 85),  # Using slightly wider than absolute historical
   Citi = c(min = -100, max = 100),
   EPU = c(min = 50, max = 600)
)

# Min-max normalization function
minmax_normalize <- function(x, min_val, max_val) {
   (x - min_val) / (max_val - min_val)
}

# Normalize disagreement scores to [0,1]
across_model_norm <- across_model_disagreement %>%
   mutate(
      Value = Disagreement_Score / 2,  # Convert from [0,2] to [0,1]
      Metric = "Across-Model Disagreement"
   ) %>%
   select(Date_dec, Metric, Value)

# Normalize within-model disagreement (KEEP SEPARATE BY MODEL)
within_model_norm <- within_model_disagreement %>%
   mutate(
      Value = Disagreement_Score / 2,  # Convert from [0,2] to [0,1]
      Metric = Model  # Use model name as the metric
   ) %>%
   select(Date_dec, Metric, Value)

# Normalize comparison metrics using historical ranges
comparison_norm <- comparison_metrics_filtered %>%
   mutate(
      VIX = minmax_normalize(VIXCLS, 
                             historical_ranges$VIX["min"], 
                             historical_ranges$VIX["max"]),
      Citi_Surprise = minmax_normalize(CITI_SURPRISE_SCORE, 
                                       historical_ranges$Citi["min"], 
                                       historical_ranges$Citi["max"]),
      EPU = minmax_normalize(USEPUINDXD, 
                             historical_ranges$EPU["min"], 
                             historical_ranges$EPU["max"])
   ) %>%
   select(Date_dec, VIX, Citi_Surprise, EPU) %>%
   pivot_longer(cols = c(VIX, Citi_Surprise, EPU), 
                names_to = "Metric", 
                values_to = "Value")

# Combine all normalized metrics
all_metrics_norm <- bind_rows(
   across_model_norm,
   within_model_norm,
   comparison_norm
)

cat("\n=== NORMALIZED METRICS (0-1 scale) ===\n")
print(all_metrics_norm)

# ===================================================================
# PLOT 3: ACROSS-MODEL + MARKET METRICS
# ===================================================================

plot_data_across <- all_metrics_norm %>%
   filter(Metric %in% c("Across-Model Disagreement", "VIX", "Citi_Surprise", "EPU"))

ggplot(plot_data_across, aes(x = Date_dec, y = Value, color = Metric, shape = Metric)) +
   geom_line(linewidth = 1.2) +
   geom_point(size = 4) +
   labs(
      title = "Across-Model Disagreement vs Market Uncertainty Metrics",
      subtitle = "All Metrics Normalized to [0,1] Scale Using Historical Min/Max",
      x = "Date (December)",
      y = "Normalized Value (0 = Historical Min, 1 = Historical Max)",
      color = "Metric",
      shape = "Metric"
   ) +
   theme_minimal(base_size = 12) +
   theme(
      legend.position = "bottom",
      plot.title = element_text(face = "bold", size = 14),
      panel.grid.minor = element_blank()
   ) +
   scale_x_continuous(breaks = unique(plot_data_across$Date_dec)) +
   scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
   geom_hline(yintercept = 0.5, linetype = "dashed", alpha = 0.3)

# ===================================================================
# PLOT 4: WITHIN-MODEL (EACH MODEL SEPARATELY) + MARKET METRICS
# ===================================================================

plot_data_within <- all_metrics_norm %>%
   filter(Metric %in% c("Claude Opus 4.5", "GPT 5.1", "Gemini 3 Pro", 
                        "VIX", "Citi_Surprise", "EPU"))

ggplot(plot_data_within, aes(x = Date_dec, y = Value, color = Metric, shape = Metric)) +
   geom_line(linewidth = 1.2) +
   geom_point(size = 4) +
   labs(
      title = "Within-Model Disagreement (by Model) vs Market Uncertainty Metrics",
      subtitle = "All Metrics Normalized to [0,1] Scale Using Historical Min/Max",
      x = "Date (December)",
      y = "Normalized Value (0 = Historical Min, 1 = Historical Max)",
      color = "Metric",
      shape = "Metric"
   ) +
   theme_minimal(base_size = 12) +
   theme(
      legend.position = "bottom",
      plot.title = element_text(face = "bold", size = 14),
      panel.grid.minor = element_blank(),
      legend.text = element_text(size = 9)
   ) +
   scale_x_continuous(breaks = unique(plot_data_within$Date_dec)) +
   scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
   geom_hline(yintercept = 0.5, linetype = "dashed", alpha = 0.3) +
   guides(color = guide_legend(nrow = 2))








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



