#!/bin/bash
cd "${0%/*}"
docker build --progress=plain -t ovara-dbt-runner .
cd -
