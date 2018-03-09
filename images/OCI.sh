#!/bin/bash
rm -f oci-icon-white.png oci-icon-white.svg
wget https://raw.githubusercontent.com/opencontainers/artwork/master/oci/icon/white/oci-icon-white.png
wget https://raw.githubusercontent.com/opencontainers/artwork/master/oci/icon/white/oci-icon-white.svg
mv oci-icon-white.png images/OCI.png
mv oci-icon-white.svg images/OCI.svg
