FROM amd64/ubuntu:18.04
RUN apt-get update -y && apt-get upgrade -y && apt-get install -y apt-utils ca-certificates openssh-client wget bash libfontconfig vim
RUN wget https://dl.grafana.com/oss/release/grafana_5.4.3_amd64.deb
RUN dpkg -i grafana_5.4.3_amd64.deb
ADD devstats-grafana.tar .
# grafana/img/k8s*
# ICON GA
RUN cp grafana/shared/grafana_start.sh /usr/bin
