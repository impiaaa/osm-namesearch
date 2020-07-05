#!/bin/bash
set -x
state=$1
pbf=download/${state}-latest.osm.pbf
if [ ! -f ${pbf} ]; then
    while read i; do if [ "$i" = ${state}-latest.osm.pbf ]; then break; fi; done \
       < <(inotifywait -e close_write --format '%f' --quiet download --monitor)
fi
db=/tmp/namesearch/${state}.db
rm -f ${db}
ogr2ogr -gt 65536 -overwrite -oo CONFIG_FILE=osmconf.ini -f sqlite ${db} ${pbf}

for category in human-rights-activists legacy-of-racism; do
    sqlite3 ${db} "drop table if exists people;"
    sqlite3 -csv ${db} ".import ${category}.csv people"
    sqlite3 ${db} < filter.sql
    python3 fixgeom.py ${db}
    tmpout=/tmp/namesearch/${state}-${category}.geojsonl
    rm -f ${tmpout}
    ogr2ogr -f GeoJSONSeq ${tmpout} ${db} filtered
    python3 postprocess.py ${tmpout} output/${state}-${category}.geojsonl
    rm ${tmpout}
done

rm ${db}

