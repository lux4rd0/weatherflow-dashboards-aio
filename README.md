## About The Project

<center><img src="./images/weatherflow-dashboards-aio-title.png"></center>

**WeatherFlow Dashboards AIO** is an example project put together to help you get up and running quickly with a local-udp, remote-socket, and remote-rest collector to visualize your [WeatherFlow Tempest](https://weatherflow.com/tempest-weather-system/) log streams with Grafana dashboards. 

<center><img src="https://github.com/lux4rd0/weatherflow-collector/blob/main/images/weatherflow-forecast-influxdb.jpg"></center>

This project uses my custom [weatherflow-collector](https://github.com/lux4rd0/weatherflow-collector) and a slightly updated [UDP Python collector](https://github.com/p-doyle/Simple-WeatherFlow-Python-Listener) from [P Doyle](https://github.com/p-doyle/) to collect and transform JSON logs to metrics and publish them to an InfluxDB TSDB.  Several pre-configured [Grafana dashboards](https://grafana.com/oss/grafana/) are provided to visualize WeatherFlow data over time. I also include additional visualizations using WeatherFlow's Cloud APIs to populate forecasts and derived weather metrics.

WeatherFlow Tempest -> WeatherFlow Hub -> UDP Collector (port 50222) InfluxDB <- Grafana Dashboards

remote-socket/remote-rest <- weatherflow-collector -> InfluxDB

## Getting Started

The project is built around a pre-configured Docker stack containing the following containers:

 - [Grafana](https://grafana.com/oss/grafana/)
 - [InfluxDB 1.8](https://docs.influxdata.com/influxdb/v1.8/)
 - [WeatherFlow Collector](https://github.com/lux4rd0/weatherflow-collector)

## Prerequisites

- [Docker](https://docs.docker.com/install)
- [Docker Compose](https://docs.docker.com/compose/install)

## Notice

Like all projects - this is always in a flux state based on trying out new things and seeing what works and what doesn't work. It started as a fun exercise to visualize "what's possible," and I'm experimenting with different collectors and backends. Please expect breaking changes along the way.

## Using

To get started, download one of [the releases](https://github.com/lux4rd0/grafana-weatherflow/releases) from this repository and extract it into an empty directory. For example:

    wget https://github.com/lux4rd0/weatherflow-dashboards-aio/archive/v2.4.0.zip
    unzip v2.4.0.zip
    mv weatherflow-dashboards-aio-2.4.0 weatherflow-dashboards-aio
    cd weatherflow-dashboards-aio

Correct environmental variables need to be set for the containers to function. The following script can be used:

    generate_docker-compose.sh

To use it, you will need to provide your WeatherFlow token as environmental variables.

    WEATHERFLOW_COLLECTOR_IMPORT_DAYS #optional
    WEATHERFLOW_COLLECTOR_TOKEN

An example would be:

    WEATHERFLOW_COLLECTOR_IMPORT_DAYS="365" \
    WEATHERFLOW_COLLECTOR_TOKEN="a22afsa7-0dcc-4918-9f9a-923dfd339f41c" \
    bash ./generate_docker-compose.sh

The following files will be generated for you:

#### docker-compose.yml

Running `docker-compose up -d' will spin up several containers for each of the types of data available to you. (Listed below) If you have more than one hub on your account - please edit the docker-compose.yml file to only have your hub local to your network. If you have more than one device, those will also be added and can remain.

#### Optional:
#### remote-import-<<station_name>>.sh

This script will spin up a docker container to import all of the observed metrics in the WeatherFlow cloud. Having an import function may be helpful if you're starting with this WeatherFlow Collector or if you've reset your InfluxDB database. It essentially loads in over your local UDP data. If you have more than one device, a separate import file will be generated for each.

## Obtaining Your Tempest Authentication Token

You can obtain your authentication token by signing in to the Tempest Web App at tempestwx.com, then go to Settings -> Data Authorizations -> Create Token.

## Data Retention and Storage Locations

Data is stored in InfluxDB in a mounted directory under /data/influxdb. By default, there is no retention policy set.

### Startup

From the above directory, run the docker-compose command after you've generated the docker-compose.yml file:

    docker-compose up -d

This command will start to download the Grafana, InfluxDB, and weatherflow-collector application containers. The" `-d'" command places the containers into "detached" mode *(run containers in the background)*. The configuration also sets each of the containers to auto-start.

*Note, this project has been tested on 64-bit CentOS 7 (centos-release-7-9.2009.1.el7.centos.x86_64) and 32-bit Raspberry Pi 4 (Raspberry Pi OS/January 11th 2021)*

https://github.com/lux4rd0/weatherflow-collector#using

## Grafana Dashboards

Once all of the docker containers have started, point your Web browser to the Grafana page, typically http://hostname:3000/ - with hostname being the name of the server you ran the `docker-compose up -d' command on. The "**WeatherFlow - Overview**" dashboard is defaulted without having to log into Grafana.

Other dashboards may be viewed by selecting the "WeatherFlow Dashboards" drop-down from the top righthand side of the dashboards:

<center><img src="./images/weatherflow-dashboards.jpg"></center>

**WeatherFlow - Today So Far**

<center><img src="./images/weatherflow-weatherflow-today_so_far.jpg"></center>

The last hour over time for Temperature, Relative Humidity, Station Pressure, Accumulated Rain, Solar Radiation, Illuminance, UV, Lightening Strike, and Wind Speed. Rapid Wind Direction and Wind Speed over the last 60 seconds are also updated every 5 seconds (by default). 

**WeatherFlow - Device Details**

<center><img src="./images/weatherflow-weatherflow-device_details.jpg"></center>

Provides the current status for both the Tempest and WeatherFlow hub such as Uptime, Radio Status, RSSI, Reboot Count, I2C Bus Count Error, Radio Version, Network ID, Firmware Version, and Voltage.

<center><img src="./images/weatherflow-weatherflow-device_details-device_status.jpg"></center>

Another panel provides an overview of Sensor Status measurements - either "Sensors OK" or if there were any failures.

<center><img src="./images/weatherflow-weatherflow-device_details-sensor_status.jpg"></center>

There's also RSSI and Battery Voltage over time defaulted to the last seven days.

<center><img src="./images/weatherflow-weatherflow-device_details-battery.jpg"></center>
<center><img src="./images/weatherflow-weatherflow-device_details-rssi.jpg"></center>

## Default Security

This docker-compose stack is designed to be as easy as possible to deploy and go. Anonymous logins have been enabled, and the default user has a **Viewer** role. This setting can be changed to either an **Admin** or **Editor** role by changing the Grafana environmental variable in the `docker-compose.yml` file to:*

    GF_AUTH_ANONYMOUS_ORG_ROLE: Viewer

## Downloading WeatherFlow Grafana Dashboards Individually

The dashboards included in this WeatherFlow Dashboards AIO stack can also be downloaded separately if so desired:

- [WeatherFlow - Overview](https://grafana.com/grafana/dashboards/13938)
- [WeatherFlow - Today So Far](https://grafana.com/grafana/dashboards/13939)
- [WeatherFlow - Device Details](https://grafana.com/grafana/dashboards/13940)

## Roadmap

See the open issues for a list of proposed features (and known issues).

## Contributing

Contributions make the open source community such a fantastic place to learn, inspire, and create. Any contributions you make are greatly appreciated.

- Fork the Project
- Create your Feature Branch (git checkout -b feature/AmazingFeature)
- Commit your changes (git commit -m 'Add some AmazingFeature')
- Push to the Branch (git push origin feature/AmazingFeature)
- Open a Pull Request

## Contact

Dave Schmid - [@lux4rd0](https://twitter.com/lux4rd0) - dave@pulpfree.org
Project Link: https://github.com/lux4rd0/grafana-weatherflow

## Acknowledgements

- Grafana Labs - https://grafana.com/
- Grafana - https://grafana.com/oss/grafana/
- Grafana Dashboard Community - https://grafana.com/grafana/dashboards
