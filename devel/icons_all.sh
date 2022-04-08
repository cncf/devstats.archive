#!/bin/bash
# ARTWORK
# TEST_SERVER=1
./devel/update_artwork.sh || exit 1
./apache/www/copy_icons.sh || exit 2
./grafana/create_images.sh || exit 3
# We no longer need this with Kubernetes deployment
# ./grafana/copy_artwork_icons.sh || exit 4
if [ ! -z "$COMPRESS" ]
then
  ./util_sh/compress_pngs.sh
fi
echo 'Icons updated'
