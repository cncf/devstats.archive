#!/bin/bash
# ARTWORK
./devel/update_artwork.sh || exit 1
./apache/www/copy_icons.sh || exit 2
./grafana/create_images.sh || exit 3
./grafana/copy_artwork_icons.sh || exit 4
if [ ! -z "$COMPRESS" ]
then
  ./util_sh/compress_pngs.sh
fi
echo 'Icons updated'
