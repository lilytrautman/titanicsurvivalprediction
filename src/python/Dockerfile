FROM python:3.12-slim

WORKDIR /app

COPY src/python/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/python/ ./src/python/
COPY src/data/ ./src/data/

CMD ["python", "src/python/titanic_model.py"]
