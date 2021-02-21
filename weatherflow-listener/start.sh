#!/bin/sh

/usr/bin/stdbuf -oL /usr/bin/python /weatherflow-listener/weatherflow-listener.py | /usr/bin/promtail --stdin --client.url http://loki:3100/loki/api/v1/push --client.external-labels=app=weatherflow,hostname=weatherflow
