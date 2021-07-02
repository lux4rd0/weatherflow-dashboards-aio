#!/bin/bash

##
## WeatherFlow Dashboards Grafana - build.sh
##

docker build --no-cache . -t lux4rd0/weatherflow-dashboards-grafana:latest -t lux4rd0/weatherflow-dashboards-grafana:$1 -t docker01.tylephony.com:5000/lux4rd0/weatherflow-dashboards-grafana:latest -t docker01.tylephony.com:5000/lux4rd0/weatherflow-dashboards-grafana:$1
docker push docker01.tylephony.com:5000/lux4rd0/weatherflow-dashboards-grafana:latest
docker push docker01.tylephony.com:5000/lux4rd0/weatherflow-dashboards-grafana:$1
docker push lux4rd0/weatherflow-dashboards-grafana:latest
docker push lux4rd0/weatherflow-dashboards-grafana:$1

