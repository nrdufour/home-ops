#!/usr/bin/env bash

kubectl scale deploy dashy grafana influxdb kanboard mqtt znc-bouncer --replicas=1

kubectl scale -n database deploy influxdb2 --replicas=1

kubectl scale -n irc deploy marmitton --replicas=1

kubectl scale -n home-automation deploy homeassistant zwave --replicas=1





