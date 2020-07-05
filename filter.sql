drop table if exists filtered;
delete from geometry_columns where f_table_name='filtered';

create table filtered as
select name, subject, group_concat(distinct hex("GEOMETRY")) as geom_str, group_concat(distinct osm_id) as osm_id, wd, wdLabel, article
from (select name, subject, "GEOMETRY", 'node/'||osm_id as osm_id, all_tags
      from points
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
join people
on name glob '*'||givenNameLabel||' *'||familyNameLabel||'*'
or subject glob givenNameLabel||' *'||familyNameLabel
group by name, subject, wd, wdLabel, article, all_tags
having count("GEOMETRY") < 128;

alter table filtered add column "GEOMETRY" blob;
insert into geometry_columns values ('filtered', 'GEOMETRY', 0, 2, 4326, 'WKB');

