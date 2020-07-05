#!/bin/bash

# Download lists of people
for category in human-rights-activists slavers kkk segregationists confederates; do
    curl "https://query.wikidata.org/sparql" -o ${category}.csv --data-urlencode query@${category}.sparql -H "Accept: text/csv"
done
# Merge some of the people lists together.
# "-u" ensures no duplicates
# "-t ," makes it (mostly) work with CSV
# "-k 4 -r" sorts by the wikidata URL, in reverse: this is so that the header (which isn't actually a URL) comes first
sort -u -t , -k 4 -k 2 -k 1 -r -o legacy-of-racism.csv slavers.csv kkk.csv segregationists.csv confederates.csv

mkdir -p download/california
mkdir -p /tmp/namesearch/california
mkdir -p output/california

# Download a Geofabrik OSM extract for each US state
# "paste -sd" makes a list of states separated by commas
# {} in the cURL path with a comma-separated list makes it download them all, with a persistent connection
# "&" runs the download in parallel with the processing script
curl "https://download.geofabrik.de/north-america/us/{$(paste -sd , states.txt)}-latest.osm.pbf" -o "download/#1-latest.osm.pbf" &
parallel ./filter.sh -- $(cat states.txt)
# ^ Run the processing script once for each state, in parallel per CPU core

# Combine all individual states into results for the whole US
cat output/*-legacy-of-racism.geojsonl output/california/*-legacy-of-racism.geojsonl > output/united-states-legacy-of-racism.geojsonl
cat output/*-human-rights-activists.geojsonl output/california/*-human-rights-activists.geojsonl > output/united-states-human-rights-activists.geojsonl

