FROM amazoncorretto:21-alpine-full
RUN apk upgrade --no-cache
RUN apk --no-cache add bash

WORKDIR /root/
COPY ./run.sh ./run.sh
COPY ./install.sh ./install.sh
ADD ./lampi-siirtaja/target/ovara-lampi-siirtaja-jar-with-dependencies.jar ./ovara-lampi-siirtaja.jar
RUN \
  bash install.sh && \
  rm install.sh

ENTRYPOINT ["bash", "/root/run.sh", ""]
