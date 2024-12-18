#!/bin/bash
cd "${0%/*}"
docker build --progress=plain -t ovara-lampi-siirtaja .
cd -
