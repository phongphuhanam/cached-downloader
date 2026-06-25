FROM python:alpine3.10

#RUN apk --no-cache add curl

WORKDIR /app

# COPY requirements.txt .
# RUN pip install -r requirements.txt

ENV CACHED_LOCATION=/data/

RUN pip install flask loguru minato --no-cache-dir

COPY main_app.py .

EXPOSE 5000

ENV FLASK_APP=/app/main_app.py
CMD ["flask", "run", "--host=0.0.0.0"]

# ---- Usage example in your own Dockerfile ----
#
# ADD https://raw.githubusercontent.com/phongphuhanam/cached-downloader/main/cached_download.sh /usr/bin/cached_download
# ADD https://raw.githubusercontent.com/phongphuhanam/cached-downloader/main/cached_unpack.sh /usr/bin/cached_unpack
# ENV CACHE_SERVER_LOC=http://localhost:7575/download
#
# RUN cached_download https://example.com/model.bin /opt/model.bin
# RUN cached_unpack https://example.com/tools.tar.gz /opt/tools/
#
# If the cache server runs on the same machine, build with --network=host
# so the container can reach localhost:7575:
#   docker build --network=host -t myimage .



