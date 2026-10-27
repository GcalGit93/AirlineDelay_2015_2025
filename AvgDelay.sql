-- Avg Delay Minutes per unit carrier/airport, 
WITH entity_delay_table AS (
SELECT 
	MIN(f.flight_id) AS flight_id,
	MIN(carrier_code) AS carrier_code,
	MIN(airport_code) AS airport_code,
	MIN(delay_year) AS delay_year,
	MIN(delay_month) AS delay_month,
	SUM(delay_minutes) AS delay_minutes
FROM fact_flight_delays AS fd
JOIN delay_cause_dim AS dc ON
fd.delay_cause_id = dc.delay_cause_id
JOIN fact_flights AS f ON
fd.flight_id = f.flight_id
JOIN carrier_dim AS c ON
f.carrier_id = c.carrier_id
JOIN airport_dim AS a ON
f.airport_id = a.airport_id
JOIN flight_date_dim AS d ON
f.date_id = d.date_id
GROUP BY f.flight_id
),

madc AS (
SELECT 
	MIN(carrier_code) AS carrier_code,
	MIN(delay_year) AS delay_year,
	MIN(delay_month) AS delay_month,
	AVG(delay_minutes) AS avg_delay_minutes_per_carrier_month
FROM entity_delay_table
GROUP BY carrier_code, delay_year, delay_month
ORDER BY carrier_code, delay_year, delay_month
),

yadc AS (
SELECT 
	MIN(carrier_code) AS carrier_code,
	MIN(delay_year) AS delay_year,
	AVG(delay_minutes) AS avg_delay_minutes_per_carrier_year
FROM entity_delay_table
GROUP BY carrier_code, delay_year
ORDER BY carrier_code, delay_year
),

gadc AS (
SELECT 
	MIN(carrier_code) AS carrier_code,
	AVG(delay_minutes) AS avg_delay_minutes_per_carrier_grand
FROM entity_delay_table
GROUP BY carrier_code
ORDER BY carrier_code
),

mada AS (
SELECT 
	MIN(airport_code) AS airport_code,
	MIN(delay_year) AS delay_year,
	MIN(delay_month) AS delay_month,
	AVG(delay_minutes) AS avg_delay_minutes_per_airport_month
FROM entity_delay_table
GROUP BY airport_code, delay_year, delay_month
ORDER BY airport_code, delay_year, delay_month
),

yada AS (
SELECT 
	MIN(airport_code) AS airport_code,
	MIN(delay_year) AS delay_year,
	AVG(delay_minutes) AS avg_delay_minutes_per_airport_year
FROM entity_delay_table
GROUP BY airport_code, delay_year
ORDER BY airport_code, delay_year
),

gada AS (
SELECT 
	MIN(airport_code) AS airport_code,
	AVG(delay_minutes) AS avg_delay_minutes_per_airport_grand
FROM entity_delay_table
GROUP BY airport_code
ORDER BY airport_code
),

/*
SELECT 
	m.carrier_code,
	m.delay_year,
	m.delay_month,
	avg_delay_minutes_per_carrier_month,
	avg_delay_minutes_per_carrier_year,
	avg_delay_minutes_per_carrier_grand
FROM madc AS m
JOIN yadc AS y ON
m.carrier_code = y.carrier_code AND
m.delay_year = y.delay_year
JOIN gadc AS g ON
m.carrier_code = g.carrier_code


SELECT 
	m.airport_code,
	m.delay_year,
	m.delay_month,
	avg_delay_minutes_per_airport_month,
	avg_delay_minutes_per_airport_year,
	avg_delay_minutes_per_airport_grand
FROM mada AS m
JOIN yada AS y ON
m.airport_code = y.airport_code AND
m.delay_year = y.delay_year
JOIN gada AS g ON
m.airport_code = g.airport_code;
*/

yoy_ad AS (
SELECT 
	airport_code,
	delay_year,
	avg_delay_minutes_per_airport_year,
	(avg_delay_minutes_per_airport_year-LAG(avg_delay_minutes_per_airport_year,1) OVER(PARTITION BY airport_code ORDER BY delay_year))/
		NULLIF(LAG(avg_delay_minutes_per_airport_year,1) OVER(PARTITION BY airport_code ORDER BY delay_year),0)*100 AS avg_delay_change_YoY
FROM yada
)

SELECT
	airport_code,
	delay_year,
	avg_delay_minutes_per_airport_year,
	avg_delay_change_YoY,
	SUM(avg_delay_change_YoY) OVER(PARTITION BY airport_code ORDER BY delay_year) AS cum_net_ad_yoy
FROM yoy_ad


