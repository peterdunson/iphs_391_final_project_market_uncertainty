library(dplyr)
library(tidyr)
library(lsa)

raw_data <- read.csv("your_file.csv")


# 3. Step 1: Average the Humans (Create the "True Vector")
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

# 4. Step 2: Calculate Daily Disagreement Score
final_results <- model_vectors %>%
   group_by(Date_dec) %>%
   summarise(
      # Create a unique list of models for that day
      Disagreement_Score = {
         # Extract the vectors for the models present on this day
         current_data <- cur_data()
         
         # We need at least 2 models to compare
         if(nrow(current_data) < 2) {
            NA 
         } else {
            # Create a matrix of just the numerical scores
            # Rows = Models, Cols = Dimensions
            mat <- as.matrix(current_data[, c("Equities", "Inflation", "Labor", "Consumer", "Guidance")])
            
            # Transpose so columns are models (required for lsa::cosine)
            mat_t <- t(mat)
            
            # Calculate Cosine Similarity Matrix
            sim_matrix <- cosine(mat_t)
            
            # Convert to Distance (1 - Similarity)
            dist_matrix <- 1 - sim_matrix
            
            # Extract unique pairwise distances (lower triangle of matrix)
            # This gives us the distance between Model A-B, B-C, A-C
            distances <- dist_matrix[lower.tri(dist_matrix)]
            
            # Return the average distance
            mean(distances, na.rm = TRUE)
         }
      }
   )

# 5. View Final Table
print(final_results)

# Optional: Save to CSV for your chart
write.csv(final_results, "daily_disagreement_scores.csv", row.names = FALSE)



