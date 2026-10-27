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

motr AS (
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

yotr AS (
SELECT
	DISTINCT carrier_code AS carrier_code,
	MIN(delay_year) AS delay_year,
	AVG(monthly_otr) AS yearly_otr
FROM motr
GROUP BY carrier_code, delay_year
ORDER BY carrier_code, delay_year
)

SELECT 
	carrier_code,
	delay_year,
	ROUND(AVG(yearly_otr),2)
FROM yotr
GROUP BY carrier_code, ROLLUP(delay_year)
ORDER BY carrier_code, delay_year NULLS LAST;

/*
SELECT
	DISTINCT carrier_code AS carrier_code,
	MIN(delay_year) AS delay_year,
	ROUND(AVG((1.0-(SUM(arr_del15)::NUMERIC/SUM(arr_flights)::NUMERIC))*100.0) OVER(PARTITION BY carrier_code, delay_year),2) 
		AS yearly_otr
FROM OTT
GROUP BY carrier_code, delay_year
ORDER BY carrier_code, delay_year


SELECT 
	carrier_code,
	delay_year,
	ROUND(AVG(yearly_otr),2)
FROM yotr
GROUP BY carrier_code, ROLLUP(delay_year)
ORDER BY carrier_code, delay_year NULLS LAST;


*/	
-- Cancel Rate for carrier and airports, arr_cancelled/arr_flights

-- Avg Delay Minutes per unit carrier/airport, 

-- Top 3 Delay Causes (sum ranks sort by sum for grand ranking)

-- Top 5 Airports by Performance Change (look at YoY On-timem Cancel rate, delay chages)