FROM alpine:3.20
RUN apk upgrade --no-cache
RUN apk --no-cache add bash

WORKDIR /root/
COPY ./dbt-container/run.sh ./
COPY ./dbt-container/install.sh ./
COPY ./dbt-container/build.txt ./
ADD ./dbt ./dbt
RUN \
  bash install.sh && \
  rm install.sh

ENTRYPOINT ["bash", "/root/run.sh", ""]
