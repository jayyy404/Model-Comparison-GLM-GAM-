##R version of Final_models.ipynb

# Libraries needed
library(tidyverse)
library(ggplot2)
library(mgcv)  # For GAM models

# Set theme
theme_set(theme_minimal())

# Read and clean data
df <- read.csv("dataset/PHILIPPINES_DATA_19.csv", stringsAsFactors = FALSE)

# Replace missing values
df[df == " " | df == "NA" | df == "NaN" | df == "nan"] <- NA
df <- na.omit(df)

# Convert CR7 to numeric
df$CR7 <- as.numeric(df$CR7)

# Display data info
str(df)

# Create smoker status: 1 = smoker (CR7 > 1), 0 = non-smoker
df$smoker_status <- ifelse(df$CR7 > 1, 1, 0)
head(df$smoker_status)

# Plot 1: Distribution of Smoking Frequency
ggplot(df, aes(x = factor(CR7))) +
  geom_bar(fill = "steelblue") +
  labs(title = "Distribution of Smoking Frequency (Past 30 Days)",
       x = "Number of Days Smoked (CR7)\n0 to 30",
       y = "Count of Respondents") +
  theme_minimal()

# Plot 2: Age Distribution
age_counts <- hist(df$CR1, breaks = 10, plot = FALSE)
max_count <- max(age_counts$counts)

ggplot(df, aes(x = CR1)) +
  geom_histogram(bins = 10, fill = "skyblue", color = "black", alpha = 0.7) +
  geom_density(aes(y = after_stat(count)), color = "blue", size = 1) +
  labs(title = "Age Distribution (CR1)",
       x = "Age",
       y = "Frequency") +
  scale_x_continuous(breaks = seq(floor(min(df$CR1)), ceiling(max(df$CR1)), 1)) +
  annotate("text", x = min(df$CR1), y = max_count * 0.95,
           label = "Range: 11–17+", hjust = 0, size = 4, fontface = "bold",
           color = "black") +
  theme_minimal()

# Plot 3: Gender Distribution
ggplot(df, aes(x = factor(CR2))) +
  geom_bar(fill = "coral") +
  labs(title = "Gender Distribution (CR2)",
       x = "Sex",
       y = "Count") +
  annotate("text", x = 0.5, y = max(table(df$CR2)) * 0.9,
           label = "1 = Male, 2 = Female", hjust = 0) +
  theme_minimal()

# Plot 4: Average Smoking Days by Peer Offer
df %>%
  group_by(CR39) %>%
  summarise(mean_CR7 = mean(CR7, na.rm = TRUE)) %>%
  ggplot(aes(x = factor(CR39), y = mean_CR7)) +
  geom_bar(stat = "identity", fill = "darkgreen") +
  labs(title = "Average Smoking Days by Peer Offer (CR39)",
       x = "Best Friends Offered Tobacco\n(1=Definitely Not, 2=Probably not, 3=Probably yes, 4=Definitely yes)",
       y = "Mean Smoking Days (CR7)") +
  theme_minimal()

# GLM Poisson model
glm_model <- glm(CR7 ~ CR1 + CR2 + PHR3 + PHR4 + CR5 + CR9 + PHR20 + CR39 + PHR31 + PHR44,
                 data = df,
                 family = poisson(link = "log"))

# Print summary
summary(glm_model)

# Coefficient bar chart
coef_df <- data.frame(
  Variable = names(coef(glm_model)),
  Coefficient = coef(glm_model)
)

ggplot(coef_df, aes(x = Variable, y = Coefficient)) +
  geom_bar(stat = "identity", fill = "steelblue") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(title = "GLM Coefficients for Smoking Predictors")

# Poisson GAM on selected predictors
# Convert to numeric and remove NAs
df$CR1 <- as.numeric(df$CR1)
df$CR39 <- as.numeric(df$CR39)
df$CR5 <- as.numeric(df$CR5)

# Create subset with complete cases for GAM variables
gam_data <- df[complete.cases(df[, c("CR7", "CR1", "CR39", "CR5")]), ]

# Check unique values to set appropriate k
cat("Unique values in CR1:", length(unique(gam_data$CR1)), "\n")
cat("Unique values in CR39:", length(unique(gam_data$CR39)), "\n")
cat("Unique values in CR5:", length(unique(gam_data$CR5)), "\n")

# Determine k values (must be < unique values)
k1 <- min(length(unique(gam_data$CR1)) - 1, 5)
k39 <- min(length(unique(gam_data$CR39)) - 1, 4)
k5 <- min(length(unique(gam_data$CR5)) - 1, 3)

cat("Using k values - CR1:", k1, "CR39:", k39, "CR5:", k5, "\n")

# Fit GAM model with appropriate basis dimensions
if(k5 < 3) {
  # If CR5 has too few unique values, use it as linear term
  gam_model <- gam(CR7 ~ s(CR1, k = k1) + s(CR39, k = k39) + CR5,
                   data = gam_data,
                   family = poisson(link = "log"))
} else {
  gam_model <- gam(CR7 ~ s(CR1, k = k1) + s(CR39, k = k39) + s(CR5, k = k5),
                   data = gam_data,
                   family = poisson(link = "log"))
}

# Summary
summary(gam_model)

# Plot GAM effects
par(mfrow = c(3, 1), mar = c(4, 4, 3, 2))
plot(gam_model, select = 1, shade = TRUE, shade.col = "lightblue",
     main = "Effect of Age (CR1)", xlab = "CR1", ylab = "Effect on Smoking Days (CR7)")
plot(gam_model, select = 2, shade = TRUE, shade.col = "lightblue",
     main = "Effect of Peer Offer (CR39)", xlab = "CR39", ylab = "Effect on Smoking Days (CR7)")
plot(gam_model, select = 3, shade = TRUE, shade.col = "lightblue",
     main = "Effect of Tried Smoking (CR5)", xlab = "CR5", ylab = "Effect on Smoking Days (CR7)")
par(mfrow = c(1, 1))

# Coefficient significance plot
coef_summary <- data.frame(
  Variable = names(coef(glm_model)),
  Coefficient = coef(glm_model),
  P_value = summary(glm_model)$coefficients[, 4]
)
coef_summary$Significance <- ifelse(coef_summary$P_value < 0.05, "Significant", "Not Significant")

ggplot(coef_summary, aes(x = Coefficient, y = Variable, fill = Significance)) +
  geom_bar(stat = "identity") +
  geom_vline(xintercept = 0, linetype = "dashed", color = "black") +
  scale_fill_manual(values = c("Significant" = "steelblue", "Not Significant" = "coral")) +
  labs(title = "GLM Coefficients and Significance") +
  theme_minimal()

# Predicted vs Actual
df$Predicted_CR7 <- predict(glm_model, type = "response")

ggplot(df, aes(x = CR7, y = Predicted_CR7)) +
  geom_point(alpha = 0.5, color = "steelblue") +
  geom_abline(intercept = 0, slope = 1, color = "red", linetype = "dashed") +
  labs(title = "Predicted vs Actual CR7",
       x = "Actual CR7",
       y = "Predicted CR7") +
  theme_minimal()

# Residuals Distribution
df$Residuals <- df$CR7 - df$Predicted_CR7

ggplot(df, aes(x = Residuals)) +
  geom_histogram(aes(y = after_stat(density)), bins = 30, fill = "steelblue", alpha = 0.7) +
  geom_density(color = "darkblue", size = 1) +
  labs(title = "Residuals Distribution",
       x = "Residuals",
       y = "Density") +
  theme_minimal()