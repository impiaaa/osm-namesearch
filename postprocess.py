import sys, json
out = open(sys.argv[2], 'w')
for line in open(sys.argv[1]):
    feature = json.loads(line)
    props = feature["properties"]

    wdNames = props["wdLabel"].split()
    osmNames = props["name"].split()
    if props["name"].endswith("Lane") and wdNames[-1] == "Lane":
        continue
    if wdNames[0] not in osmNames:
        continue
    if '.' not in wdNames[-1]:
        if wdNames[-1] not in osmNames:
            continue
        osmMiddle = osmNames[osmNames.index(wdNames[0])+1:osmNames.index(wdNames[-1])]
        wdMiddle = wdNames[1:-1]
        if len(osmMiddle) == len(wdMiddle) and [n[0] for n in osmMiddle] != [n[0] for n in wdMiddle]:
            continue

    del props["geom_str"]
    wd = props["wd"]
    wd = wd[wd.rfind("/")+1:]
    
    tagsToAdd = {}
    if props["name"]: tagsToAdd["name:etymology:wikidata"] = wd
    else: del props["name"]
    if props["subject"]: tagsToAdd["subject:wikidata"] = wd
    else: del props["subject"]
    
    props["link"] = props["article"] if props["article"] else props["wd"]
    del props["article"], props["wd"]
    
    osmids = tuple(set(props.pop("osm_id").split(',')))
    props["id"] = hash(osmids+(wd,))
    props["osm_link"] = "https://www.openstreetmap.org/"+osmids[0]
    
    #print(json.dumps(feature, separators=(",", ":")), file=out)
    #continue
    print(json.dumps({"type": "FeatureCollection",
        "features": [feature],
        "cooperativeWork": {
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

