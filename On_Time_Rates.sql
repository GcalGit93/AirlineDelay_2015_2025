-- On-Time Rate for carrier and airports, (1-(arr_delay/arr_flights))*100
WITH OTT AS (
	SELECT *
	FROM fact_flights AS f
	JOIN carrier_dim AS c ON
	f.carrier_id = c.carrier_id
	JOIN airport_dim AS a ON
	f.airport_id = a.airport_id
	JOIN flight_date_dim AS d ON
	f.date_id = d.date_id
	ORDER BY c.carrier_code
),

-- (M)onthly, (Y)early, (G)rand (O)n-(T)ime (R)ates for (C)arriers and (A)irports
motrc AS (
SELECT 
	carrier_code,
	MIN(delay_year) AS delay_year,
	MIN(delay_month) AS delay_month,
	(1.0-(SUM(arr_del15)::NUMERIC/SUM(arr_flights)::NUMERIC))*100 
		AS monthly_otr
FROM OTT
GROUP BY carrier_code, delay_year, delay_month
ORDER BY carrier_code, delay_year, delay_month
),

yotrc AS (
SELECT
	DISTINCT carrier_code AS carrier_code,
	MIN(delay_year) AS delay_year,
	(1.0-(SUM(arr_del15)::NUMERIC/SUM(arr_flights)::NUMERIC))*100 
		AS yearly_otr
FROM OTT
GROUP BY carrier_code, delay_year
ORDER BY carrier_code, delay_year
),

gotrc AS (
SELECT
	DISTINCT carrier_code AS carrier_code,
	(1.0-(SUM(arr_del15)::NUMERIC/SUM(arr_flights)::NUMERIC))*100 
		AS grand_otr
FROM OTT
GROUP BY carrier_code
ORDER BY carrier_code
),

motra AS (
SELECT 
	airport_code,
	MIN(delay_year) AS delay_year,
	MIN(delay_month) AS delay_month,
	(1.0-(SUM(arr_del15)::NUMERIC/SUM(arr_flights)::NUMERIC))*100 
		AS monthly_otr
FROM OTT
GROUP BY airport_code, delay_year, delay_month
ORDER BY airport_code, delay_year, delay_month
),

yotra AS (
SELECT
	DISTINCT airport_code AS airport_code,
	MIN(delay_year) AS delay_year,
	(1.0-(SUM(arr_del15)::NUMERIC/SUM(arr_flights)::NUMERIC))*100 
		AS yearly_otr
FROM OTT
GROUP BY airport_code, delay_year
ORDER BY airport_code, delay_year
),

gotra AS (
SELECT
	DISTINCT airport_code AS airport_code,
	(1.0-(SUM(arr_del15)::NUMERIC/SUM(arr_flights)::NUMERIC))*100 
		AS grand_otr
FROM OTT
GROUP BY airport_code
ORDER BY airport_code
)

SELECT * FROM gotra
ORDER BY grand_otr DESC

/*
SELECT 
	motrc.carrier_code,
	motrc.delay_year,
	motrc.delay_month,
	monthly_otr,
	yearly_otr,
	grand_otr
FROM motrc
JOIN yotrc ON
motrc.carrier_code = yotrc.carrier_code AND
motrc.delay_year = yotrc.delay_year 
JOIN gotrc ON
motrc.carrier_code = gotrc.carrier_code;

SELECT 
	motra.airport_code,
	motra.delay_year,
	motra.delay_month,
	monthly_otr,
	yearly_otr,
	grand_otr
FROM motra
JOIN yotra ON
motra.airport_code = yotra.airport_code AND
motra.delay_year = yotra.delay_year 
JOIN gotra ON
motra.airport_code = gotra.airport_code;
*/
-- Top 5 Airports by Performance Change (look at YoY On-time Cancel rate, delay chages)
-- On-Time Rate

yoy_otr AS (
SELECT 
	airport_code,
	delay_year,
	yearly_otr,
	((yearly_otr-(LAG(yearly_otr,1) OVER(PARTITION BY airport_code)))/
		(LAG(yearly_otr,1) OVER(PARTITION BY airport_code))*100) AS otr_change_YoY
FROM yotra
)

SELECT
	airport_code,
	delay_year,
	yearly_otr,
	otr_change_YoY,
	SUM(otr_change_YoY) OVER(PARTITION BY airport_code ORDER BY delay_year) AS cum_net_otr_yoy
FROM yoy_otr