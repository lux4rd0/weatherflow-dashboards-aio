#!/bin/bash

##
## WeatherFlow Dashboards Grafana - build.sh
##

docker build --no-cache . -t lux4rd0/weatherflow-dashboards-grafana:latest-arm64 -t lux4rd0/weatherflow-dashboards-grafana:$1-arm64 -t docker01.tylephony.com:5000/lux4rd0/weatherflow-dashboards-grafana:latest-arm64 -t docker01.tylephony.com:5000/lux4rd0/weatherflow-dashboards-grafana:$1-arm64
docker push docker01.tylephony.com:5000/lux4rd0/weatherflow-dashboards-grafana:latest-arm64
docker push docker01.tylephony.com:5000/lux4rd0/weatherflow-dashboards-grafana:$1-arm64
docker push lux4rd0/weatherflow-dashboards-grafana:latest-arm64
docker push lux4rd0/weatherflow-dashboards-grafana:$1-arm64

