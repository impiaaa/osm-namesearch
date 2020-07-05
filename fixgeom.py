import sqlite3, sys, struct

geomstruct = struct.Struct('<BI')
def do_geom(geom_str):
    geombin = b''
    geomcount = 0
    types = set()
    for geom in geom_str.split(','):
        geom = bytes.fromhex(geom)
        endian, type = geomstruct.unpack(geom[:geomstruct.size])
        assert endian == 1
        if type in (4,5,6,7):
            count, = struct.unpack('<I', geom[geomstruct.size:geomstruct.size+4])
            geombin += geom[geomstruct.size+4:]
            geomcount += count
            if type == 7: types.add(7)
            else: types.add(type-3)
        else:
            geombin += geom
            geomcount += 1
            types.add(type)
    if geomcount == 1:
        return geombin
    if len(types) == 1:
        type = types.pop()
        if type in (1,2,3): return geomstruct.pack(1, type+3)+struct.pack('<I', geomcount)+geombin
    return geomstruct.pack(1, 7)+struct.pack('<I', geomcount)+geombin

conn = sqlite3.connect(sys.argv[1])
conn.create_function("do_geom", 1, do_geom)
cur = conn.cursor()
cur.execute('update filtered set "GEOMETRY"=do_geom(geom_str)')
conn.commit()
conn.close()

