#!/bin/bash
./apache/www/copy_icons.sh || exit 1
./grafana/create_images.sh || exit 2
./grafana/copy_artwork_icons.sh || exit 3
echo 'Icons updated'
