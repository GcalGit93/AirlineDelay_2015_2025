-- Cancel Rate for carrier and airports, arr_cancelled/arr_flights
WITH CT AS (
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

-- (M)onthly, (Y)early, (G)rand (C)ancelation (R)ates for (C)arriers and (A)irports
mcrc AS (
SELECT 
	carrier_code,
	MIN(delay_year) AS delay_year,
	MIN(delay_month) AS delay_month,
	(SUM(arr_cancelled)::NUMERIC/SUM(arr_flights)::NUMERIC)*100 
		AS monthly_cr
FROM CT
GROUP BY carrier_code, delay_year, delay_month
ORDER BY carrier_code, delay_year, delay_month
),

ycrc AS (
SELECT
	DISTINCT carrier_code AS carrier_code,
	MIN(delay_year) AS delay_year,
	(SUM(arr_cancelled)::NUMERIC/SUM(arr_flights)::NUMERIC)*100 
		AS yearly_cr
FROM CT
GROUP BY carrier_code, delay_year
ORDER BY carrier_code, delay_year
),

gcrc AS (
SELECT
	DISTINCT carrier_code AS carrier_code,
	(SUM(arr_cancelled)::NUMERIC/SUM(arr_flights)::NUMERIC)*100 
		AS grand_cr
FROM CT
GROUP BY carrier_code
ORDER BY carrier_code
),

mcra AS (
SELECT 
	airport_code,
	MIN(delay_year) AS delay_year,
	MIN(delay_month) AS delay_month,
	(SUM(arr_cancelled)::NUMERIC/SUM(arr_flights)::NUMERIC)*100 
		AS monthly_cr
FROM CT
GROUP BY airport_code, delay_year, delay_month
ORDER BY airport_code, delay_year, delay_month
),

ycra AS (
SELECT
	DISTINCT airport_code AS airport_code,
	MIN(delay_year) AS delay_year,
	(SUM(arr_cancelled)::NUMERIC/SUM(arr_flights)::NUMERIC)*100 
		AS yearly_cr
FROM CT
GROUP BY airport_code, delay_year
ORDER BY airport_code, delay_year
),

gcra AS (
SELECT
	DISTINCT airport_code AS airport_code,
	(SUM(arr_cancelled)::NUMERIC/SUM(arr_flights)::NUMERIC)*100 
		AS grand_cr
FROM CT
GROUP BY airport_code
ORDER BY airport_code
),

/*

--- By carrier
SELECT 
	mcrc.carrier_code,
	mcrc.delay_year,
	mcrc.delay_month,
	monthly_cr,
	yearly_cr,
	grand_cr
FROM mcrc
JOIN ycrc ON
mcrc.carrier_code = ycrc.carrier_code AND
mcrc.delay_year = ycrc.delay_year 
JOIN gcrc ON
mcrc.carrier_code = gcrc.carrier_code;

-- By airport
SELECT 
	mcra.airport_code,
	mcra.delay_year,
	mcra.delay_month,
	monthly_cr,
	yearly_cr,
	grand_cr
FROM mcra
JOIN ycra ON
mcra.airport_code = ycra.airport_code AND
mcra.delay_year = ycra.delay_year 
JOIN gcra ON
mcra.airport_code = gcra.airport_code;
*/
-- Top 5 Airports by Performance Change (look at YoY On-time Cancel rate, delay chages)
-- Cancel Rate

yoy_cr AS (
SELECT 
	airport_code,
	delay_year,
	yearly_cr,
	(yearly_cr - (LAG(yearly_cr,1) OVER(PARTITION BY airport_code)))/
		NULLIF((LAG(yearly_cr,1) OVER(PARTITION BY airport_code)),0)*100 AS cr_change_YoY
FROM ycra
)

SELECT
	airport_code,
	delay_year,
	yearly_cr,
	cr_change_YoY,
	SUM(cr_change_YoY) OVER(PARTITION BY airport_code ORDER BY delay_year) AS cum_net_cr_yoy
FROM yoy_cr;