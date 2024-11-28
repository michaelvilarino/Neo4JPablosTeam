///CRIAÇÃO DAS CONSTRAINTS

CREATE CONSTRAINT constraint_route_indent
FOR (a:Route)
REQUIRE (a.routeCode) IS NODE KEY;

CREATE CONSTRAINT constraint_airport_indent
FOR (a:Airport)
REQUIRE (a.airport_ident) IS NODE KEY;

CREATE CONSTRAINT constraint_airline_indent
FOR (a:Airline)
REQUIRE (a.airline_code) IS NODE KEY;

///CRIAÇÃO DAS CONSTRAINTS
--------------------------------------------------------------------------------------------------------------------------------------------------

///CRIAÇÃO DO NÓ AIRLINE E ROUTE
LOAD CSV WITH HEADERS FROM 'https://stpslatam.blob.core.windows.net/partners-contest/routes.csv' AS row
WITH row
MERGE (a:Airline {airline_code: row.airline})
SET a.codeShare = row.codeshare,
    a.equipment = row.equipment

MERGE (r:Route {routeCode: row.source_airport + row.destination_apirport})
SET r.source = row.source_airport,
    r.destination = row.destination_apirport

WITH a, r
MERGE (a)-[:SELL]->(r);

///CRIAÇÃO DO NÓ AIRLINE E ROUTE

---------------------------------------------------------------------------------------------------------------------------------------------------

///CRIAÇÃO DO NÓ AIRPORT E O RELACIONAMENTO COM ROUTE
LOAD CSV WITH HEADERS FROM 'https://stpslatam.blob.core.windows.net/partners-contest/world_airports.csv' AS row
with row
MERGE (a:Airport {airport_ident: row.airport_ident})
SET a.x = toFloat(row.latitude_deg),
    a.y = toFloat(row.longitude_deg),
    a.name =  row.name,
    a.runAwaySurface = row.runway_surface,
    a.runAwayLighted = row.runway_lighted,
	a.iata_code = row.iata_code

match(r:Route)
match(a:Airport)
where r.source = a.iata_code
with r,a
MERGE(r)-[:DEPARTURE]->(a);

match(r:Route)
match(a:Airport)
where r.destination = a.iata_code
with r,a
MERGE(r)-[:ARRIVAL]->(a);

///CRIAÇÃO DO NÓ AIRPORT E O RELACIONAMENTO COM ROUTE

---------------------------------------------------------------------------------------------------------------------------------------------------

///ATUALIZAÇÃO DO NÓ ROUTE
LOAD CSV WITH HEADERS FROM 'https://stpslatam.blob.core.windows.net/partners-contest/routes.csv' AS row
WITH row
MERGE (r:Route {routeCode: row.source_airport + row.destination_apirport})
SET  r.distanciaKm = 0,
     r.stop = row.stop
///ATUALIZAÇÃO DO NÓ ROUTE	 
	
---------------------------------------------------------------------------------------------------------------------------------------------------
	
///CRIAÇÃO DO RELACIONAMENTO DO NÓ AIRLINE 		
MATCH (a1:Airline)-[:SELL]->(r:Route)-[:DEPARTURE]->(a_s:Airport)
MATCH (a1)-[:SELL]->(r)-[:ARRIVAL]->(a_d:Airport)
WITH a1, r, a_s, a_d 
     
SET r.distanciaKm = point.distance(point({latitude: a_s.x, longitude: a_s.y}), point({latitude: a_d.x, longitude: a_d.y})) / 1000;

MATCH (a1:Airline)-[:SELL]->(r:Route)-[:DEPARTURE]->(a_s:Airport)
MATCH (a1)-[:SELL]->(r)-[:ARRIVAL]->(a_d:Airport)
WITH r
where r.distanciaKm <= 4000
match (r)
set r:Normal

MATCH (a1:Airline)-[:SELL]->(r:Route)-[:DEPARTURE]->(a_s:Airport)
MATCH (a1)-[:SELL]->(r)-[:ARRIVAL]->(a_d:Airport)
WITH r
where r.distanciaKm > 4000
match (r)
set r:Longa

match (a:Airline) where a.codeShare = 'Y'
    set a:Parceiro
	
match (a:Airline) where a.codeShare IS NULL
    set a:Concorrente
	
///CRIAÇÃO DO RELACIONAMENTO DO NÓ AIRLINE 

------------------------------------------------------------------------------------------------------------------------------------------------------

///CYPHER PARA APRESENTAÇÃO DOS GRAFOS	
	match (a:Concorrente)-[:SELL]->(r:Longa) return a,r limit 50
	match (a:Parceiro)-[:SELL]->(r:Longa) return a,r limit 50
	
	match(a:Concorrente)-[:SELL]-(r:Longa)-[:DEPARTURE]-(s:Airport)
    match(a:Concorrente)-[:SELL]-(r:Longa)-[:ARRIVAL]-(d:Airport)
    return  a,r,d,s limit 50
	
	match(a:Parceiro)-[:SELL]-(r:Longa)-[:DEPARTURE]-(s:Airport)
    match(a:Parceiro)-[:SELL]-(r:Longa)-[:ARRIVAL]-(d:Airport)
    return  a,r,d,s limit 50
	
///CYPHER PARA APRESENTAÇÃO DOS GRAFOS	
	
------------------------------------------------------------------------------------------------------------------------------------------------------