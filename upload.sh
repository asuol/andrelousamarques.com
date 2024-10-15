#!/bin/bash

read -p "BUNNY_API: " BUNNY_API
read -p "BUNNY_STORAGE_API: " BUNNY_STORAGE_API
read -p "BUNNY_STORAGE: " BUNNY_STORAGE
read -p "BUNNY_PULL_ZONE: " BUNNY_PULL_ZONE

bnycdn key set default ${BUNNY_API}
bnycdn key set ${BUNNY_STORAGE} ${BUNNY_STORAGE_API} --type=storages
bnycdn cp -R -s ${BUNNY_STORAGE} ./public /${BUNNY_STORAGE}/
bnycdn pz purge -t ${BUNNY_PULL_ZONE}
