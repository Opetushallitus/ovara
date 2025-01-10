FROM node:20-alpine3.20
RUN apk upgrade --no-cache
RUN apk --no-cache add bash

WORKDIR /root/
COPY ./run.sh ./run.sh
COPY ./install.sh ./install.sh
ADD ./lampi-siirtaja ./lampi-siirtaja
RUN \
  bash install.sh && \
  rm install.sh

ENTRYPOINT ["bash", "/root/run.sh", ""]
