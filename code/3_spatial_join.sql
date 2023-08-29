--add geom column
SELECT 
AddGeometryColumn('public','tweets','geom',4326,'POINT',2)

--populate geom column
update tweets
    set geom = ST_SetSRID(
        ST_MakePoint(
             "x"::double precision,
             "y"::double precision
        ), 4326)
			
--coordinate transform				
ALTER TABLE public."CONUS_counties"
  ALTER COLUMN geom 
  TYPE Geometry(MultiPolygon, 4326) 
  USING ST_Transform(geom, 4326);
			
--spatial join
CREATE TABLE tweets_GEOID
AS
SELECT 
  t.*, 
  cc.GEOID
FROM 
  tweets t,
  public."CONUS_counties" cc
WHERE ST_Intersects(t.geom, cc.geom);

--drop geometry
ALTER TABLE public.tweets_GEOID DROP column geom;

--save outputs PSQL
\copy (Select * From public.tweets_GEOID) To 'tweets_GEOID.csv' With CSV DELIMITER ',' HEADER