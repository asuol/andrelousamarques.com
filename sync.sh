#!/bin/sh

read -p "BUNNY_API_KEY: " BUNNY_API_KEY
read -p "BUNNY_PULL_ZONE: " BUNNY_PULL_ZONE
read -p "BUNNY_STORAGE: " BUNNY_STORAGE

make build-site

npx bunny-transfer sync -k ${BUNNY_API_KEY} andrelousamarques/public ${BUNNY_STORAGE}
npx bunny-transfer purge ${BUNNY_PULL_ZONE}
