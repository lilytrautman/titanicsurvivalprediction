FROM rocker/r-ver:4.5.1

WORKDIR /app

COPY src/r/install_packages.R .
RUN Rscript install_packages.R

COPY src/r/ ./src/r/
COPY src/data/ ./src/data/

CMD ["Rscript", "src/r/titanic_model.R"]
