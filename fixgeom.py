import sqlite3, sys, struct

# sqlite doesn't have very good blob-handling functions, so this "cleans up" collected geometry WKBs

geomstruct = struct.Struct('<BI')
def do_geom(geom_str):
    geombin = b''
    geomcount = 0
    types = set()
    for geom in geom_str.split(','): # split on commas
        geom = bytes.fromhex(geom) # un-hex
        endian, type = geomstruct.unpack(geom[:geomstruct.size]) # get geometry type
        assert endian == 1 # could be fixed to work with both
        if type in (4,5,6,7): # Multi* or GeometryCollection should be flattened
            count, = struct.unpack('<I', geom[geomstruct.size:geomstruct.size+4])
            geombin += geom[geomstruct.size+4:]
            geomcount += count
            if type == 7: types.add(7) # heterogenous collections can't change type
            else: types.add(type-3) # but Multi* can be merged together
        else:
            geombin += geom
            geomcount += 1
            types.add(type)
    if geomcount == 1: # only one geometry, return it
        return geombin
    if len(types) == 1: # all geo types were the same, merge them into a Multi* if possible
        type = types.pop()
        if type in (1,2,3): return geomstruct.pack(1, type+3)+struct.pack('<I', geomcount)+geombin
    # otherwise, use a GeometryCollection
    return geomstruct.pack(1, 7)+struct.pack('<I', geomcount)+geombin

conn = sqlite3.connect(sys.argv[1])
conn.create_function("do_geom", 1, do_geom)
cur = conn.cursor()
cur.execute('update filtered set "GEOMETRY"=do_geom(geom_str)')
conn.commit()
conn.close()

