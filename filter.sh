#!/bin/bash

# This script is ran once for each state (passed in the command line

set -x # echo every command issued
state=$1
pbf=download/${state}-latest.osm.pbf

# If the download for this state hasn't started yet, wait for it to finish before continuing
# (there is a race condition here: cURL might create the file before it's finished downloading;
# there's no way AFAICT to detect that)
if [ ! -f ${pbf} ]; then
    while read i; do if [ "$i" = ${state}-latest.osm.pbf ]; then break; fi; done \
       < <(inotifywait -e close_write --format '%f' --quiet download --monitor)
fi

db=/tmp/namesearch/${state}.db
rm -f ${db} # just in case of a failed conversion earlier, overwrite the old
ogr2ogr -gt 65536 -overwrite -oo CONFIG_FILE=osmconf.ini -f sqlite ${db} ${pbf}

for category in human-rights-activists legacy-of-racism; do
    sqlite3 ${db} "drop table if exists people;"
    sqlite3 -csv ${db} ".import ${category}.csv people"
    sqlite3 ${db} < filter.sql # this SQL makes a new table "filtered" with the search results
    python3 fixgeom.py ${db} # fix up geometry
    tmpout=/tmp/namesearch/${state}-${category}.geojsonl
    rm -f ${tmpout} # just in case of a failed conversion earlier, overwrite the old
    ogr2ogr -f GeoJSONSeq ${tmpout} ${db} filtered # convert the "filtered" table to a line-separated GeoJSON
    python3 postprocess.py ${tmpout} output/${state}-${category}.geojsonl # fix up and generate MR coop tasks
    rm ${tmpout}
done

# Some states' SQLite DBs can be >1GB; best not to keep that around in tmpfs
rm ${db}

