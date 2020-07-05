import sys, json

# This script further filters search results, and creates MapRoulette co-op tasks for them.

out = open(sys.argv[2], 'w')
for line in open(sys.argv[1]):
    feature = json.loads(line)
    props = feature["properties"]

    wdNames = props["wdLabel"].split()
    osmNames = props["name"].split()
    
    # "Lane" is a last name, and a common street suffix. Skip these.
    if props["name"].endswith("Lane") and wdNames[-1] == "Lane":
        continue
    
    # Wikidata "given name" includes middle names;
    # check the label to find the real first name, and filter for that
    if wdNames[0] not in osmNames:
        continue
    
    # allow jr., sr., etc.
    if '.' not in wdNames[-1]:
        # The SQL allows partial name matches; filter those out
        if wdNames[-1] not in osmNames:
            continue
        
        # If the OSM object appears to include a middle name
        osmMiddle = osmNames[osmNames.index(wdNames[0])+1:osmNames.index(wdNames[-1])]
        # and Wikidata has the middle name in their label
        wdMiddle = wdNames[1:-1]
        # check to make sure that at least the first initials match.
        if len(osmMiddle) == len(wdMiddle) and [n[0] for n in osmMiddle] != [n[0] for n in wdMiddle]:
            continue

    # sqlite can't drop columns
    del props["geom_str"]
    wd = props["wd"]
    # get just the WD entity ID
    wd = wd[wd.rfind("/")+1:]
    
    # Tags for MR to suggest adding
    tagsToAdd = {}
    if props["name"]: tagsToAdd["name:etymology:wikidata"] = wd
    else: del props["name"]
    if props["subject"]: tagsToAdd["subject:wikidata"] = wd
    else: del props["subject"]
    
    # For the task instructions, a Wikipedia link is preferred, but use the Wikidata link if that isn't available
    props["link"] = props["article"] if props["article"] else props["wd"]
    del props["article"], props["wd"]
    
    osmids = tuple(set(props.pop("osm_id").split(',')))
    # Create a unique task ID, including matched OSM object IDs as well as the matched WD ID
    props["id"] = hash(osmids+(wd,))
    # Only link to one OSM object
    props["osm_link"] = "https://www.openstreetmap.org/"+osmids[0]
    
    #print(json.dumps(feature, separators=(",", ":")), file=out)
    #continue
    # MR requires FeatureCollections
    print(json.dumps({"type": "FeatureCollection",
        "features": [feature],
        "cooperativeWork": { # create a tag fix task
            "meta": {"version": 2, "type": 1},
            "operations": [{
                "operationType": "modifyElement",
                "data": {
                    "id": osmid,
                    "operations": [{
                        "operation": "setTags",
                        "data": tagsToAdd
                    }]
                }
            } for osmid in osmids]
        }
    }, separators=(",", ":")), file=out)
out.close()

