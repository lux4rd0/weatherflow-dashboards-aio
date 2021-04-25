#!/bin/bash

##
## WeatherFlow Collector AIO - docker-compose.yml generator
##

##
## Use bash ./generate_docker-compose.sh <<token>> to create a docker-compose.yml file.
##

import_days=$WEATHERFLOW_COLLECTOR_IMPORT_DAYS
token=$WEATHERFLOW_COLLECTOR_TOKEN
loki_client_url=$WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL
logcli_host_url=$WEATHERFLOW_COLLECTOR_LOGCLI_URL

echo "

import_days=${import_days}
token=${token}

"

if [ -z "${import_days}" ]
  then
    echo "WEATHERFLOW_COLLECTOR_IMPORT_DAYS variable not set. Defaulting to 365 days"

import_days="365"

fi

if [ -z "${loki_client_url}" ]
  then
    echo "WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL was not set. No default being set"
fi

if [ -z "$token" ]

then
      echo "Missing authentication token. Please provide your token as a command parameter."
else

url_stations="https://swd.weatherflow.com/swd/rest/stations?token=${token}"

#echo "url_stations=${url_stations}"

url_forecasts="https://swd.weatherflow.com/swd/rest/better_forecast?station_id=${station_id}&token=${token}"

#echo "url_forecasts=${url_forecasts}"

url_observations="https://swd.weatherflow.com/swd/rest/observations/station/${station_id}?token=${token}"

#echo "url_observations=${url_observations}"

response_url_stations=$(curl -si -w "\n%{size_header},%{size_download}" "${url_stations}")

response_url_forecasts=$(curl -si -w "\n%{size_header},%{size_download}" "${url_forecasts}")

response_url_observations=$(curl -si -w "\n%{size_header},%{size_download}" "${url_observations}")

# Extract the response header size
header_size_stations=$(sed -n '$ s/^\([0-9]*\),.*$/\1/ p' <<< "${response_url_stations}")

# Extract the response body size
body_size_stations=$(sed -n '$ s/^.*,\([0-9]*\)$/\1/ p' <<< "${response_url_stations}")

# Extract the response headers
headers_station="${response_url_stations:0:${header_size_stations}}"

# Extract the response body
body_station="${response_url_stations:${header_size_stations}:${body_size_stations}}"

#echo "URL Results"

#echo "${header_size_stations}"

#echo "${body_size_stations}"

#echo "${headers_station}"

#echo "${body_station}"

number_of_stations=$(echo "${body_station}" |jq '.stations | length')

#echo "Number of Stations: ${number_of_stations}"

number_of_stations_minus_one=$((number_of_stations-1))

for station_number in $(seq 0 $number_of_stations_minus_one) ; do

#echo "Station Number Loop: $station_number"

timezone[$station_number]=$(echo "${body_station}" | jq -r .stations[$station_number].timezone)
latitude[$station_number]=$(echo "${body_station}" | jq -r .stations[$station_number].latitude)
longitude[$station_number]=$(echo "${body_station}" | jq -r .stations[$station_number].longitude)
elevation[$station_number]=$(echo "${body_station}" | jq -r .stations[$station_number].station_meta.elevation)
public_name[$station_number]=$(echo "${body_station}" | jq -r .stations[$station_number].public_name)
station_name[$station_number]=$(echo "${body_station}" | jq -r .stations[$station_number].name)

station_name_dc[$station_number]=$(echo "${body_station}" | jq -r .stations[$station_number].name | sed 's/ /\_/g' | sed 's/.*/\L&/' | sed 's|[<>,]||g')
station_id[$station_number]=$(echo "${body_station}" | jq -r .stations[$station_number].station_id)
device_id[$station_number]=$(echo "${body_station}" | jq -r .stations[$station_number].devices[1].device_id)
hub_sn[$station_number]=$(echo "${body_station}" |jq -r .stations[$station_number].devices[0].serial_number)

done

FILE="${PWD}/docker-compose.yml"
if test -f "$FILE"; then

existing_file_timestamp=$(date -r "$FILE" "+%Y%m%d-%H%M%S")

echo "Existing docker-compose.yml file found. Backup up file to $FILE.${existing_file_timestamp}"

mv "$FILE" "$FILE"."${existing_file_timestamp}"

fi

##
## Print docker-compose.yml file
##

##
## Only one UDP per location
##


echo "

networks:
  wxfdashboardsaio: {}
services:
  wxfdashboardsaio_grafana:
    container_name: wxfdashboardsaio_grafana
    environment:
      GF_AUTH_ANONYMOUS_ENABLED: \"true\"
      GF_AUTH_ANONYMOUS_ORG_ROLE: Viewer
      GF_AUTH_BASIC_ENABLED: \"true\"
      GF_AUTH_DISABLE_LOGIN_FORM: \"false\"
      GF_DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH: /var/lib/grafana/dashboards/weatherflow_collector/weatherflow_collector-overview-influxdb.json
    image: grafana/grafana:7.5.4
    networks:
      wxfdashboardsaio:
    ports:
    - protocol: tcp
      published: 3000
      target: 3000
    restart: always
    volumes:
    - ./config/grafana/provisioning/datasources:/etc/grafana/provisioning/datasources:ro
    - ./config/grafana/provisioning/dashboards:/etc/grafana/provisioning/dashboards:ro
    - ./config/grafana/dashboards:/var/lib/grafana/dashboards:ro
  wxfdashboardsaio_influxdb:
    container_name: wxfdashboardsaio_influxdb
    environment:
      INFLUXDB_ADMIN_PASSWORD: Gk372Qm70E0xGVIcUpSyRiwqfAyhuwkS
      INFLUXDB_ADMIN_USER: admin
      INFLUXDB_DATA_ENGINE: tsm1
      INFLUXDB_DB: weatherflow
      INFLUXDB_MONITOR_STORE_DATABASE: _internal
      INFLUXDB_MONITOR_STORE_ENABLED: \"true\"
      INFLUXDB_REPORTING_DISABLED: \"true\"
      INFLUXDB_USER: weatherflow
      INFLUXDB_USER_PASSWORD: x8egQTrf4bGl8Cs3XGyF1yE0b06pfgJe
    image: influxdb:1.8
    networks:
      wxfdashboardsaio:
    ports:
    - protocol: tcp
      published: 8086
      target: 8086
    restart: always
    volumes:
    - ./data/influxdb:/var/lib/influxdb:rw

" > docker-compose.yml


## Loop through each device

for station_number in $(seq 0 $number_of_stations_minus_one) ; do

##
## Check import scripts
##

FILE[$station_number]="${PWD}/remote-import-${station_name_dc[$station_number]}.sh"
if test -f "${FILE[$station_number]}"; then

existing_file_timestamp[$station_number]=$(date -r "${FILE[$station_number]}" "+%Y%m%d-%H%M%S")

echo "Existing ${FILE[$station_number]} file found. Backup up file to ${FILE[$station_number]}.${existing_file_timestamp[$station_number]}"

mv "${FILE[$station_number]}" "${FILE[$station_number]}"."${existing_file_timestamp[$station_number]}"

fi

echo "

device_id: ${device_id[$station_number]}
timezone: ${timezone[$station_number]}
latitude: ${latitude[$station_number]}
longitude: ${longitude[$station_number]}
elevation: ${elevation[$station_number]}
station_name: ${station_name[$station_number]}
station_id: ${station_id[$station_number]}
public_name: ${public_name[$station_number]}
hub_sn: ${hub_sn[$station_number]}

"

echo "

  weatherflow-collector-${station_name_dc[$station_number]}-local-udp:
    container_name: weatherflow-collector-${station_name_dc[$station_number]}-local-udp
    environment:
      WEATHERFLOW_COLLECTOR_BACKEND_TYPE: influxdb
      WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE: local-udp
      WEATHERFLOW_COLLECTOR_DEBUG: \"false\"
      WEATHERFLOW_COLLECTOR_DOCKER_HEALTHCHECK_ENABLED: \"true\"
      WEATHERFLOW_COLLECTOR_ELEVATION: ${elevation[$station_number]}
      WEATHERFLOW_COLLECTOR_FUNCTION: collector
      WEATHERFLOW_COLLECTOR_HOST_HOSTNAME: $(hostname)
      WEATHERFLOW_COLLECTOR_HUB_SN: ${hub_sn[$station_number]}
      WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD: x8egQTrf4bGl8Cs3XGyF1yE0b06pfgJe
      WEATHERFLOW_COLLECTOR_INFLUXDB_URL: http://wxfdashboardsaio_influxdb:8086/write?db=weatherflow
      WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME: weatherflow
      WEATHERFLOW_COLLECTOR_LATITUDE: ${latitude[$station_number]}
      WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL: ${loki_client_url}
      WEATHERFLOW_COLLECTOR_LONGITUDE: ${longitude[$station_number]}
      WEATHERFLOW_COLLECTOR_PUBLIC_NAME: ${public_name[$station_number]}
      WEATHERFLOW_COLLECTOR_STATION_ID: ${station_id[$station_number]}
      WEATHERFLOW_COLLECTOR_STATION_NAME: ${station_name[$station_number]}
      WEATHERFLOW_COLLECTOR_TIMEZONE: ${timezone[$station_number]}
      WEATHERFLOW_COLLECTOR_TOKEN: ${token}
    image: lux4rd0/weatherflow-collector:latest
    ports:
    - protocol: udp
      published: 50222
      target: 50222
    restart: always
    networks:
      wxfdashboardsaio:
    restart: always
    depends_on:
      - \"wxfdashboardsaio_influxdb\"

  weatherflow-collector-${station_name_dc[$station_number]}-remote-forecast:
    container_name: weatherflow-collector-${station_name_dc[$station_number]}-remote-forecast
    environment:
      WEATHERFLOW_COLLECTOR_BACKEND_TYPE: influxdb
      WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE: remote-forecast
      WEATHERFLOW_COLLECTOR_DEBUG: \"false\"
      WEATHERFLOW_COLLECTOR_DEVICE_ID: ${device_id[$station_number]}
      WEATHERFLOW_COLLECTOR_DOCKER_HEALTHCHECK_ENABLED: \"true\"
      WEATHERFLOW_COLLECTOR_ELEVATION: ${elevation[$station_number]}
      WEATHERFLOW_COLLECTOR_FUNCTION: collector
      WEATHERFLOW_COLLECTOR_FORECAST_INTERVAL: 60
      WEATHERFLOW_COLLECTOR_HOST_HOSTNAME: $(hostname)
      WEATHERFLOW_COLLECTOR_HUB_SN: ${hub_sn[$station_number]}
      WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD: x8egQTrf4bGl8Cs3XGyF1yE0b06pfgJe
      WEATHERFLOW_COLLECTOR_INFLUXDB_URL: http://wxfdashboardsaio_influxdb:8086/write?db=weatherflow
      WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME: weatherflow
      WEATHERFLOW_COLLECTOR_LATITUDE: ${latitude[$station_number]}
      WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL: ${loki_client_url}
      WEATHERFLOW_COLLECTOR_LONGITUDE: ${longitude[$station_number]}
      WEATHERFLOW_COLLECTOR_PUBLIC_NAME: ${public_name[$station_number]}
      WEATHERFLOW_COLLECTOR_REST_INTERVAL: 60
      WEATHERFLOW_COLLECTOR_STATION_ID: ${station_id[$station_number]}
      WEATHERFLOW_COLLECTOR_STATION_NAME: ${station_name[$station_number]}
      WEATHERFLOW_COLLECTOR_TIMEZONE: ${timezone[$station_number]}
      WEATHERFLOW_COLLECTOR_TOKEN: ${token}
    image: lux4rd0/weatherflow-collector:latest
    networks:
      wxfdashboardsaio:
    restart: always
    depends_on:
      - \"wxfdashboardsaio_influxdb\"

  weatherflow-collector-${station_name_dc[$station_number]}-remote-rest:
    container_name: weatherflow-collector-${station_name_dc[$station_number]}-remote-rest
    environment:
      WEATHERFLOW_COLLECTOR_BACKEND_TYPE: influxdb
      WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE: remote-rest
      WEATHERFLOW_COLLECTOR_DEBUG: \"false\"
      WEATHERFLOW_COLLECTOR_DEVICE_ID: ${device_id[$station_number]}
      WEATHERFLOW_COLLECTOR_DOCKER_HEALTHCHECK_ENABLED: \"true\"
      WEATHERFLOW_COLLECTOR_ELEVATION: ${elevation[$station_number]}
      WEATHERFLOW_COLLECTOR_FUNCTION: collector
      WEATHERFLOW_COLLECTOR_HOST_HOSTNAME: $(hostname)
      WEATHERFLOW_COLLECTOR_HUB_SN: ${hub_sn[$station_number]}
      WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD: x8egQTrf4bGl8Cs3XGyF1yE0b06pfgJe
      WEATHERFLOW_COLLECTOR_INFLUXDB_URL: http://wxfdashboardsaio_influxdb:8086/write?db=weatherflow
      WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME: weatherflow
      WEATHERFLOW_COLLECTOR_LATITUDE: ${latitude[$station_number]}
      WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL: ${loki_client_url}
      WEATHERFLOW_COLLECTOR_LONGITUDE: ${longitude[$station_number]}
      WEATHERFLOW_COLLECTOR_PUBLIC_NAME: ${public_name[$station_number]}
      WEATHERFLOW_COLLECTOR_STATION_ID: ${station_id[$station_number]}
      WEATHERFLOW_COLLECTOR_STATION_NAME: ${station_name[$station_number]}
      WEATHERFLOW_COLLECTOR_TIMEZONE: ${timezone[$station_number]}
      WEATHERFLOW_COLLECTOR_TOKEN: ${token}
    image: lux4rd0/weatherflow-collector:latest
    networks:
      wxfdashboardsaio:
    restart: always
    depends_on:
      - \"wxfdashboardsaio_influxdb\"

  weatherflow-collector-${station_name_dc[$station_number]}-remote-socket:
    container_name: weatherflow-collector-${station_name_dc[$station_number]}-remote-socket
    environment:
      WEATHERFLOW_COLLECTOR_BACKEND_TYPE: influxdb
      WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE: remote-socket
      WEATHERFLOW_COLLECTOR_DEBUG: \"false\"
      WEATHERFLOW_COLLECTOR_DEVICE_ID: ${device_id[$station_number]}
      WEATHERFLOW_COLLECTOR_DOCKER_HEALTHCHECK_ENABLED: \"true\"
      WEATHERFLOW_COLLECTOR_ELEVATION: ${elevation[$station_number]}
      WEATHERFLOW_COLLECTOR_FUNCTION: collector
      WEATHERFLOW_COLLECTOR_HOST_HOSTNAME: $(hostname)
      WEATHERFLOW_COLLECTOR_HUB_SN: ${hub_sn[$station_number]}
      WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD: x8egQTrf4bGl8Cs3XGyF1yE0b06pfgJe
      WEATHERFLOW_COLLECTOR_INFLUXDB_URL: http://wxfdashboardsaio_influxdb:8086/write?db=weatherflow
      WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME: weatherflow
      WEATHERFLOW_COLLECTOR_LATITUDE: ${latitude[$station_number]}
      WEATHERFLOW_COLLECTOR_LOKI_CLIENT_URL: ${loki_client_url}
      WEATHERFLOW_COLLECTOR_LONGITUDE: ${longitude[$station_number]}
      WEATHERFLOW_COLLECTOR_PUBLIC_NAME: ${public_name[$station_number]}
      WEATHERFLOW_COLLECTOR_STATION_ID: ${station_id[$station_number]}
      WEATHERFLOW_COLLECTOR_STATION_NAME: ${station_name[$station_number]}
      WEATHERFLOW_COLLECTOR_TIMEZONE: ${timezone[$station_number]}
      WEATHERFLOW_COLLECTOR_TOKEN: ${token}
    image: lux4rd0/weatherflow-collector:latest
    networks:
      wxfdashboardsaio:
    restart: always
    depends_on:
      - \"wxfdashboardsaio_influxdb\"

" >> docker-compose.yml

echo "

docker run --rm \\
  --name=weatherflow-collector-${station_name_dc[$station_number]}-remote-import \\
  -e WEATHERFLOW_COLLECTOR_BACKEND_TYPE=influxdb \\
  -e WEATHERFLOW_COLLECTOR_COLLECTOR_TYPE=remote-import \\
  -e WEATHERFLOW_COLLECTOR_DEBUG=false \\
  -e WEATHERFLOW_COLLECTOR_DEVICE_ID=${device_id[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_DOCKER_HEALTHCHECK_ENABLED=false \\
  -e WEATHERFLOW_COLLECTOR_ELEVATION=${elevation[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_FUNCTION=import \\
  -e WEATHERFLOW_COLLECTOR_HOST_HOSTNAME=$(hostname) \\
  -e WEATHERFLOW_COLLECTOR_HUB_SN=${hub_sn[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_PASSWORD=x8egQTrf4bGl8Cs3XGyF1yE0b06pfgJe \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_URL=http://$(hostname):8086/write?db=weatherflow \\
  -e WEATHERFLOW_COLLECTOR_INFLUXDB_USERNAME=weatherflow \\
  -e WEATHERFLOW_COLLECTOR_LATITUDE=${latitude[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_LONGITUDE=${longitude[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_PUBLIC_NAME=\"${public_name[$station_number]}\" \\
  -e WEATHERFLOW_COLLECTOR_STATION_ID=${station_id[$station_number]} \\
  -e WEATHERFLOW_COLLECTOR_STATION_NAME=\"${station_name[$station_number]}\" \\
  -e WEATHERFLOW_COLLECTOR_TIMEZONE=\"${timezone[$station_number]}\" \\
  -e WEATHERFLOW_COLLECTOR_TOKEN=${token} \\
  -e WEATHERFLOW_COLLECTOR_IMPORT_DAYS=${import_days} \\
  -e TZ=\"${timezone[$station_number]}\" \\
  lux4rd0/weatherflow-collector:latest

" > "${FILE[$station_number]}"

echo "${FILE[$station_number]} file created"

done

echo "
version: '3.3'" >> docker-compose.yml

echo "${PWD}/docker-compose.yml file created"

fi
