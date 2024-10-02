FROM alpine:3.20
RUN apk upgrade --no-cache
RUN apk --no-cache add bash

WORKDIR /root/
COPY ./run.sh ./
COPY ./install.sh ./
RUN \
  bash install.sh && \
  rm install.sh

ENTRYPOINT ["bash", "/root/run.sh"]
