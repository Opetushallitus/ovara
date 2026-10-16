FROM python:3.12-slim-bookworm
RUN apt-get update && \
  apt-get upgrade -y && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /root/
COPY ./dbt-container/run.sh ./
COPY ./dbt-container/install.sh ./
COPY ./dbt-container/build.txt ./
ADD ./dbt ./dbt
RUN \
  bash install.sh && \
  rm install.sh

ENTRYPOINT ["bash", "/root/run.sh"]
