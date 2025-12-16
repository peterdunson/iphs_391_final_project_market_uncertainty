library(dplyr)
library(tidyr)
library(lsa)
library(ggplot2)

# Read data
raw_data <- read.csv("data.csv")
raw_data <- na.omit(raw_data)

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


