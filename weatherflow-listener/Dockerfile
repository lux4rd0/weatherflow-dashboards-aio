FROM grafana/promtail:latest

RUN apt-get update && apt-get install -y python

RUN mkdir /weatherflow-listener

COPY start.sh /weatherflow-listener
COPY weatherflow-listener.py /weatherflow-listener

RUN chmod +x /weatherflow-listener/start.sh

ENTRYPOINT ["/weatherflow-listener/start.sh"]
