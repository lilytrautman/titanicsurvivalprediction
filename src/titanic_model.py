
import pandas as pd

from pathlib import Path
from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder

# Defining triaing path 
train_path = Path(__file__).parent / "data" / "train.csv"
train_data = pd.read_csv(train_path)

# Looking at the data 
print(f"Rows and columns: {train_data.shape}")
print("\nColumn types and non-missing values:")
train_data.info()

# Missing values 
print("\nMissing values by column:")
print(train_data.isna().sum())

#Duplicate rows
print(f"\nDuplicate rows: {train_data.duplicated().sum()}")

"""After looking at the dat I decided that since age has missing values to use imputation with mean to fill in those. A significant amount of Cabin data was missing so I decided to not use
that as a feature, and only 2 values were missing for embared so I filled those with the most frequent value """

# Defined what features were being used also defined the numeric vs categorial features 
features = ["Pclass", "Sex", "Age", "SibSp", "Parch", "Fare", "Embarked"]
numeric_features = ["Pclass", "Age", "SibSp", "Parch", "Fare"]
categorical_features = ["Sex", "Embarked"]

X = train_data[features]
y = train_data["Survived"]

preprocessor = ColumnTransformer(
    transformers=[
        ("numeric", SimpleImputer(strategy="median"), numeric_features),
        (
            "categorical",
            Pipeline(
                steps=[
                    ("imputer", SimpleImputer(strategy="most_frequent")),
                    ("encoder", OneHotEncoder(handle_unknown="ignore")),
                ]
            ),
            categorical_features,
        ),
    ]
)

model = Pipeline(
    steps=[
        ("preprocessor", preprocessor),
        ("classifier", LogisticRegression(max_iter=1000)),
    ]
)

X_train, X_validation, y_train, y_validation = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y
)

print("\nCleaning and preparing model features:")
print("Imputing missing numeric values with the median (including Age).")
print("Imputing missing Sex and Embarked values with the most frequent value.")
print("One-hot encoding Sex and Embarked; Cabin is not used as a feature.")

model.fit(X_train, y_train)
validation_predictions = model.predict(X_validation)

print(f"\nTraining rows: {len(X_train)}")
print(f"Validation rows: {len(X_validation)}")
print(f"Validation accuracy: {accuracy_score(y_validation, validation_predictions):.3f}")