drop table if exists filtered;
delete from geometry_columns where f_table_name='filtered';

-- create a new table for the search results
create table filtered as
-- combine OSM objects with identical tags
select name, subject, group_concat(distinct hex("GEOMETRY")) as geom_str, group_concat(distinct osm_id) as osm_id, wd, wdLabel, article
-- subquery to gather objects from all generated tables
from (select name, subject, "GEOMETRY", 'node/'||osm_id as osm_id, all_tags
      from points
      -- bus stops are often "Street & Road" or "Street at Road"; better to put name:etymology on the street/road itself
      where (name is not null and name_etymology_wikidata is null and highway!='bus_stop' and public_transport!='stop_position')
      or (subject is not null and subject_wikidata is null)
      
      union all select name, subject, "GEOMETRY", 'way/'||osm_id as osm_id, all_tags
      from lines
      where (name is not null and name_etymology_wikidata is null)
      or (subject is not null and subject_wikidata is null)
      
      union all select name, subject, "GEOMETRY", 'relation/'||osm_id as osm_id, all_tags
      from multilinestrings
      where (name is not null and name_etymology_wikidata is null)
      or (subject is not null and subject_wikidata is null)
      
      union all select name, subject, "GEOMETRY", 'relation/'||osm_id as osm_id, all_tags
      from multipolygons
      where (name is not null and name_etymology_wikidata is null)
      or (subject is not null and subject_wikidata is null)
      
      union all select name, subject, "GEOMETRY", 'relation/'||osm_id as osm_id, all_tags
      from other_relations
      where (name is not null and name_etymology_wikidata is null and public_transport!='stop_area')
      or (subject is not null and subject_wikidata is null))
-- search for OSM objects where the name/subject matches a person's name...
join people
-- by including the full first name followed by the last name
-- (using "glob" instead of "like" for case-sensitivity)
on name glob '*'||givenNameLabel||' *'||familyNameLabel||'*'
or subject glob givenNameLabel||' *'||familyNameLabel
-- and group together OSM objects that all have the same tags
group by name, subject, wd, wdLabel, article, all_tags;

-- prepare for geometry fixup, and indicate the geo column to GDAL
alter table filtered add column "GEOMETRY" blob;
insert into geometry_columns values ('filtered', 'GEOMETRY', 0, 2, 4326, 'WKB');

