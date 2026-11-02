# Titanic Survival Prediction

This project predicts which Titanic passengers survived using logistic regression. The same model is built twice, once in Python and once in R, and each version runs in its own Docker container.

Each container loads `train.csv`, prints a summary of the data, fills in missing values, trains on 80% of the rows, and prints its accuracy on the other 20%.

## Quick start

You need [Git](https://git-scm.com/downloads), [Docker Desktop](https://www.docker.com/products/docker-desktop/) (open and running), and a free [Kaggle](https://www.kaggle.com/) account.

1. Clone the repo and move into it:

   ```bash
   git clone https://github.com/lilytrautman/titanicsurvivalprediction.git
   cd titanicsurvivalprediction
   ```

   If the pull request has not been merged yet, also run `git checkout development`.

2. Download the data and put it in `src/data/` (see [Download the data](#download-the-data)).

3. Run the Python version:

   ```bash
   docker build -t titanic-python .
   docker run --rm titanic-python
   ```

4. Run the R version:

   ```bash
   docker build -f src/r/Dockerfile -t titanic-r .
   docker run --rm titanic-r
   ```

Run every command from the top-level `titanicsurvivalprediction` folder. The first build of each image downloads its base image, so it can take a few minutes.

## Download the data

The dataset is not stored in this repo, so you need to download it from Kaggle before building either image.

1. Sign in to Kaggle and open the [Titanic competition](https://www.kaggle.com/competitions/titanic).
2. Accept the competition rules if Kaggle asks you to. The download is blocked until you do.
3. Go to the [Data tab](https://www.kaggle.com/competitions/titanic/data) and click **Download All**. This saves a file named `titanic.zip`.
4. Unzip it and move `train.csv` and `test.csv` into `src/data/`. If the zip is in your Downloads folder on macOS or Linux, you can run this from the repo folder:

   ```bash
   unzip ~/Downloads/titanic.zip train.csv test.csv -d src/data
   ```

5. Check that the files are in the right place:

   ```bash
   ls src/data
   ```

   You should see `test.csv` and `train.csv`.

Both models only read `train.csv`. They do not use `test.csv` or the `gender_submission.csv` file that is also in the zip.

The data is copied into each image when it is built, so build the images after adding the files. If you change the files later, rebuild the images.

## Run the Python version

Build the image from the repo folder. This installs the packages listed in `requirements.txt` and copies in the code and data:

```bash
docker build -t titanic-python .
```

Run the model:

```bash
docker run --rm titanic-python
```

The output should end with:

```text
Training rows: 712
Validation rows: 179
Validation accuracy: 0.804
```

## Run the R version

Build the image from the repo folder. The `-f` flag selects the R Dockerfile, and the `.` at the end must stay because the build needs access to both `src/r/` and `src/data/`:

```bash
docker build -f src/r/Dockerfile -t titanic-r .
```

Run the model:

```bash
docker run --rm titanic-r
```

The output should end with:

```text
Training rows: 712
Validation rows: 179
Validation accuracy: 0.821
```

The R model only uses base R, so `install_packages.R` has no packages to install. To add one, put its name in the `packages` list in that file and rebuild the image.

## What the code does

Both versions follow the same steps:

| Step | What happens |
| --- | --- |
| Inspect | Prints the number of rows and columns, column types, missing values, and duplicate rows. |
| Choose features | Uses `Pclass`, `Sex`, `Age`, `SibSp`, `Parch`, `Fare`, and `Embarked`. `Cabin` is left out because 687 of its 891 values are missing. |
| Split | Holds out 20% of the rows for validation, keeping the same share of survivors in both groups. |
| Fill in missing values | Uses the training rows to choose fill values: the median for numeric columns, including `Age`, and the most common value for `Sex` and `Embarked`. |
| Train and score | Fits a logistic regression and prints its accuracy on the validation rows. |

The accuracies differ because Python and R split the rows differently, even with a random seed of 42 in both. scikit-learn also applies regularization by default, while R's `glm` does not.

## Project structure

```text
.
├── Dockerfile              # Python image
├── requirements.txt        # Python packages
├── README.md
└── src
    ├── titanic_model.py    # Python model
    ├── data                # Put train.csv and test.csv here
    └── r
        ├── Dockerfile          # R image
        ├── install_packages.R  # R packages to install
        └── titanic_model.R     # R model
```

## Troubleshooting

| Problem | Fix |
| --- | --- |
| `Cannot connect to the Docker daemon` | Open Docker Desktop, wait for it to finish starting, and try again. |
| A missing `train.csv` error when you run a container, such as `No such file or directory` or `cannot open the connection` | The image was built without the data. Add the files to `src/data/`, then build the image again and rerun it. |
| `failed to read dockerfile` or `not found` during a build | Make sure you are in the top-level repo folder. |
| Kaggle gives a 403 error or won't start the download | Sign in and accept the competition rules. |
