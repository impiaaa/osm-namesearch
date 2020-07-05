#!/bin/bash

for category in human-rights-activists slavers kkk segregationists confederates; do
    curl "https://query.wikidata.org/sparql" -o ${category}.csv --data-urlencode query@${category}.sparql -H "Accept: text/csv"
done
sort -u -t , -k 4 -k 2 -k 1 -r -o legacy-of-racism.csv slavers.csv kkk.csv segregationists.csv confederates.csv

mkdir -p download/california
mkdir -p /tmp/namesearch/california
mkdir -p output/california

#curl "https://download.geofabrik.de/north-america/us/{$(paste -sd , states.txt)}-latest.osm.pbf" -o "download/#1-latest.osm.pbf" &
parallel ./filter.sh -- $(cat states.txt)
cat output/*-legacy-of-racism.geojsonl output/california/*-legacy-of-racism.geojsonl > output/united-states-legacy-of-racism.geojsonl
cat output/*-human-rights-activists.geojsonl output/california/*-human-rights-activists.geojsonl > output/united-states-human-rights-activists.geojsonl

