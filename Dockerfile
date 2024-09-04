FROM python:alpine3.10

RUN apk --no-cache add curl

WORKDIR /app

# COPY requirements.txt .
# RUN pip install -r requirements.txt

ENV CACHED_LOCATION=/data/

RUN pip install flask loguru --no-cache-dir

COPY main_app.py .

EXPOSE 5000

ENV FLASK_APP=/app/main_app.py
CMD ["flask", "run", "--host=0.0.0.0"]



