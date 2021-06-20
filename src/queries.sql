/*TO GET THE LAT LON FOR STATIONS unique - (each direction) */

create view station_geoms as (
SELECT haltestelle, max(langengrad) as lon, max(breitengrad) as lat, fahrtrichtung
FROM raw_data_svv
where not haltestelle='-'
group by haltestelle, fahrtrichtung
)

create table station_geoms as (
SELECT haltestelle, min(haltestelle_nr) as station_id, max(langengrad) as lon, max(breitengrad) as lat, fahrtrichtung
FROM raw_data_svv
where not haltestelle='-'
group by haltestelle, fahrtrichtung)

/*__________________________________________
CHANGE TIME columns*/

alter table raw_data_svv 
alter column plan_einfahrtszeit type time without time zone
USING plan_einfahrtszeit::time without time zone

/* clip stations geometry table */
create table stations_sbg as (
select s.*
from station_geoms_clean as s, districts_sbg as d
where ST_Contains(d.geom, s.geometry))

/* create spatial index for geometries */
CREATE INDEX sbg_geoms_ind
  ON stations_sbg
  USING GIST (geometry);


/* pick right station ID from SVV stations dataset to make it joinable with time-series data */
select RIGHT(hafas_bhfno, ) from stations_pos_sbg

/* join SVV stations dataset with clean geometries dataset */
create table stations as(
select a.stg_name, s.fahrtrichtung, s.station_id, stg_x, stg_y
from station_geoms_clean as s
inner join stat_join as a
on s.station_id = a.halt_nr )


/* view predicted for Grafana */
create view view_pred as(
select a.day_hour, a.hour_id, a.haltestelle_nr, a.predicted, a.result, s.stg_name, s.stg_x, s.stg_y
from sample_pred as a
inner join stations as s
on a.haltestelle_nr = s.station_id
order by hour_id asc)

/* test view real for Grafana  */ 
create view test_check as(
select a.day_hour, a.haltestelle_nr, a.delay_class, s.stg_name, s.stg_x, s.stg_y
from sample_pred_check as a
inner join stations as s
on a.haltestelle_nr = s.station_id
where a.day_hour = '2021-03-31 08')

/*union of different months of raw data */
create table raw_bus_data as (
select * from jan21
union 
select * from feb21
union 
select * from mar21
union 
select* from apr21 

order by sendezeitpunkt
);

/* join precipitation data  	TEMPORARY !!!*/
create view data_agg as(
select a.haltestelle_nr, b.day_hour, a.date_id, a.day_id, a.hour_id, a.delay_sec, a.delay_class, a.prev_h_del, a.prev_2h_del, a.prev_day_del,
a.prev_2day_del , a.prev_week_del, a.prev_2week_del, a.prev_3week_del, a.prev_4week_del, a.mean_delay, a.median_delay, a.min_delay, a.max_delay, b.prep_mm
from data_eng as a
left join precipitation as b
on a.day_hour = b.day_hour);


/* Grafana visualization queries */
SELECT
  *
FROM view_pred
where
view_pred.hour_id IN ($Time) /*this where clause refers to the hourly filter*/
