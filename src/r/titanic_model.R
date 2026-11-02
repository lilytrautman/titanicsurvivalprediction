

script_arg <- grep("^--file=", commandArgs(), value = TRUE)
if (length(script_arg) > 0) {
  script_dir <- dirname(normalizePath(sub("^--file=", "", script_arg[1])))
} else if (dir.exists(file.path("src", "data"))) {
  script_dir <- file.path("src", "r")
} else {
  script_dir <- "."
}

train_path <- file.path(script_dir, "..", "data", "train.csv")
# Blank strings count as missing, otherwise Embarked and Cabin hide their gaps.
train_data <- read.csv(train_path, stringsAsFactors = FALSE, na.strings = c("NA", ""))

# Inspect the data.
cat("Rows and columns:", nrow(train_data), "x", ncol(train_data), "\n")
cat("\nColumn types and non-missing values:\n")
print(data.frame(
  type = sapply(train_data, function(x) class(x)[1]),
  non_missing = sapply(train_data, function(x) sum(!is.na(x)))
))

cat("\nMissing values by column:\n")
print(colSums(is.na(train_data)))

cat("\nDuplicate rows:", sum(duplicated(train_data)), "\n")

# Use the same features as the Python model; Cabin is excluded.
features <- c("Pclass", "Sex", "Age", "SibSp", "Parch", "Fare", "Embarked")
numeric_features <- c("Pclass", "Age", "SibSp", "Parch", "Fare")
categorical_features <- c("Sex", "Embarked")

# Make a stratified 80/20 train-validation split.
set.seed(42)
rows_by_class <- split(seq_len(nrow(train_data)), train_data$Survived)
training_rows <- unlist(lapply(rows_by_class, function(rows) {
  sample(rows, size = max(1, floor(0.8 * length(rows))))
}))
validation_rows <- setdiff(seq_len(nrow(train_data)), training_rows)

X_train <- train_data[training_rows, features, drop = FALSE]
X_validation <- train_data[validation_rows, features, drop = FALSE]
y_train <- train_data$Survived[training_rows]
y_validation <- train_data$Survived[validation_rows]

# Impute using values learned from the training set only.
for (column in numeric_features) {
  median_value <- median(X_train[[column]], na.rm = TRUE)
  X_train[[column]][is.na(X_train[[column]])] <- median_value
  X_validation[[column]][is.na(X_validation[[column]])] <- median_value
}

for (column in categorical_features) {
  observed <- X_train[[column]][!is.na(X_train[[column]])]
  mode_value <- names(which.max(table(observed)))[1]

  X_train[[column]][is.na(X_train[[column]])] <- mode_value
  X_validation[[column]][is.na(X_validation[[column]])] <- mode_value

  # Treat validation categories not seen during training as the mode.
  unseen <- !X_validation[[column]] %in% observed
  X_validation[[column]][unseen] <- mode_value

  X_train[[column]] <- factor(X_train[[column]])
  X_validation[[column]] <- factor(
    X_validation[[column]],
    levels = levels(X_train[[column]])
  )
}

cat("\nCleaning and preparing model features:\n")
cat("Imputing missing numeric values with the median (including Age).\n")
cat("Imputing missing Sex and Embarked values with the most frequent value.\n")
cat("Using Sex and Embarked as categorical predictors; Cabin is excluded.\n")

# Fit logistic regression and predict survival on the validation set.
model_train <- data.frame(Survived = y_train, X_train)
model <- glm(Survived ~ ., data = model_train, family = binomial())

validation_predictions <- ifelse(
  predict(model, newdata = X_validation, type = "response") >= 0.5,
  1,
  0
)

accuracy <- mean(validation_predictions == y_validation)

cat("\nTraining rows:", nrow(X_train), "\n")
cat("Validation rows:", nrow(X_validation), "\n")
cat(sprintf("Validation accuracy: %.3f\n", accuracy))
