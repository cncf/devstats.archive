#!/bin/bash
grafana-cli plugins install grafana-worldmap-panel || exit 1
grafana-cli plugins install grafana-piechart-panel || exit 2
grafana-cli plugins install michaeldmoore-annunciator-panel || exit 3
grafana-cli plugins install briangann-gauge-panel || exit 4
grafana-cli plugins install natel-discrete-panel || exit 5
grafana-cli plugins install mtanda-histogram-panel || exit 6
grafana-cli plugins install michaeldmoore-multistat-panel || exit 7
grafana-cli plugins install natel-plotly-panel || exit 8
grafana-cli plugins install grafana-polystat-panel || exit 9
grafana-cli plugins install snuids-radar-panel || exit 10
grafana-cli plugins install scadavis-synoptic-panel || exit 11
grafana-cli plugins install blackmirror1-statusbygroup-panel || exit 12
grafana-cli plugins install btplc-trend-box-panel || exit 13
echo 'Plugins installed'
