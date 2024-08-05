--create table
CREATE TABLE tweets_zl (
	tweetid VARCHAR(255),
	userid VARCHAR(255),
	postdate TIMESTAMP,
	longitude DOUBLE PRECISION,
	latitude DOUBLE PRECISION,
	hate SMALLINT,
	neg DOUBLE PRECISION,
	neu DOUBLE PRECISION,
	pos DOUBLE PRECISION,
	compound DOUBLE PRECISION
); 

--add geom column
SELECT 
AddGeometryColumn('public','tweets_zl','geom',4326,'POINT',2)


--populate geom column
update tweets_zl
    set geom = ST_SetSRID(
        ST_MakePoint(
             "longitude"::double precision,
             "latitude"::double precision
        ), 4326)
		
		
--coordinate transform OLD				
--ALTER TABLE public."CONUS_counties"
--  ALTER COLUMN geom 
--  TYPE Geometry(MultiPolygon, 4326) 
--  USING ST_Transform(geom, 4326);
		
--coordinate transform				
--ALTER TABLE public."tl_2020_us_county"
--  ALTER COLUMN geom 
--  TYPE Geometry(MultiPolygon, 4326) 
--  USING ST_Transform(geom, 4326);		
		
--spatial join
CREATE TABLE tweets_zl_GEOID
AS
SELECT 
  t.*, 
  cc.GEOID
FROM 
  tweets_zl t,
  public."tl_2020_us_county" cc
WHERE ST_Intersects(t.geom, cc.geom);

--drop geometry
ALTER TABLE public.tweets_zl_GEOID DROP column geom;

--save outputs PSQL
\copy (Select * From public.tweets_zl_GEOID) To '[YOUR PATH]' With CSV DELIMITER ',' HEADER