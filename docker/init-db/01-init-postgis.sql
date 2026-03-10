-- Enable PostGIS extension for NextGIS Web
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

-- Grant privileges to nextgisweb user
GRANT ALL PRIVILEGES ON DATABASE nextgisweb TO nextgisweb;
