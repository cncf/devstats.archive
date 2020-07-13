#!/bin/bash
install_plugin () {
  echo "Installing ${1}"
  trials=0
  while true
  do
    grafana-cli plugins install "${1}"
    res=$?
    if [ "$res" = "0" ]
    then
      return 0
    fi
    trials=$((trials+1))
    echo "Installing ${1} failed, retrying in ${trials}s"
    sleep $trials
    if [ "$trials" = "10" ]
    then
      echo "Installing ${1} failed, giving up"
      return $res
    fi
  done
  return -1
}
install_plugin grafana-worldmap-panel || exit 1
install_plugin grafana-piechart-panel || exit 2
install_plugin michaeldmoore-annunciator-panel || exit 3
install_plugin briangann-gauge-panel || exit 4
install_plugin natel-discrete-panel || exit 5
install_plugin mtanda-histogram-panel || exit 6
install_plugin michaeldmoore-multistat-panel || exit 7
install_plugin natel-plotly-panel || exit 8
install_plugin grafana-polystat-panel || exit 9
install_plugin snuids-radar-panel || exit 10
install_plugin scadavis-synoptic-panel || exit 11
install_plugin blackmirror1-statusbygroup-panel || exit 12
install_plugin btplc-trend-box-panel || exit 13
install_plugin grafana-clock-panel || exit 14
install_plugin farski-blendstat-panel || exit 15
install_plugin yesoreyeram-boomtable-panel || exit 16
install_plugin digrich-bubblechart-panel || exit 17
install_plugin neocat-cal-heatmap-panel || exit 18
install_plugin petrslavotinek-carpetplot-panel || exit 19
echo 'Plugins installed'
