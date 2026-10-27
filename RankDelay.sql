-- Top 3 Delay Causes (sum ranks sort by sum for grand ranking)
WITH entity_delay_table AS (
SELECT 
	f.flight_id,
	carrier_code,
	airport_code,
	delay_year,
	delay_month,
	cause_name,
	delay_minutes
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
),

rdmc AS (
SELECT 
	MIN(carrier_code) AS carrier_code,
	MIN(delay_year) AS delay_year,
	MIN(delay_month) AS delay_month,
	MIN(cause_name) AS cause_name,
	SUM(delay_minutes) AS delay_sum_month,
	DENSE_RANK() OVER(PARTITION BY carrier_code, delay_year, delay_month
		ORDER BY SUM(delay_minutes) DESC) AS delay_rank
FROM entity_delay_table
GROUP BY carrier_code, delay_year, delay_month, cause_name
ORDER BY carrier_code, delay_year, delay_month
),

rdyc AS (
SELECT 
	MIN(carrier_code) AS carrier_code,
	MIN(delay_year) AS delay_year,
	MIN(cause_name) AS cause_name,
	SUM(delay_sum_month) AS delay_sum_year,
	DENSE_RANK() OVER(PARTITION BY carrier_code, delay_year 
		ORDER BY SUM(delay_sum_month) DESC) AS delay_rank
FROM rdmc
GROUP BY carrier_code, delay_year, cause_name
ORDER BY carrier_code, delay_year
),

rdgc AS (
SELECT
	MIN(carrier_code) AS carrier_code,
	MIN(cause_name) AS cause_name,
	SUM(delay_sum_year) AS delay_sum_grand,
	DENSE_RANK() OVER(PARTITION BY carrier_code 
		ORDER BY SUM(delay_sum_year) DESC) AS delay_rank
FROM rdyc
GROUP BY carrier_code, cause_name
),

rdma AS (
SELECT 
	MIN(airport_code) AS airport_code,
	MIN(delay_year) AS delay_year,
	MIN(delay_month) AS delay_month,
	MIN(cause_name) AS cause_name,
	SUM(delay_minutes) AS delay_sum_month,
	DENSE_RANK() OVER(PARTITION BY airport_code, delay_year, delay_month
		ORDER BY SUM(delay_minutes) DESC) AS delay_rank
FROM entity_delay_table
GROUP BY airport_code, delay_year, delay_month, cause_name
ORDER BY airport_code, delay_year, delay_month
),

rdya AS (
SELECT 
	MIN(airport_code) AS airport_code,
	MIN(delay_year) AS delay_year,
	MIN(cause_name) AS cause_name,
	SUM(delay_sum_month) AS delay_sum_year,
	DENSE_RANK() OVER(PARTITION BY airport_code, delay_year 
		ORDER BY SUM(delay_sum_month) DESC) AS delay_rank
FROM rdma
GROUP BY airport_code, delay_year, cause_name
ORDER BY airport_code, delay_year
),

rdga AS (
SELECT
	MIN(airport_code) AS airport_code,
	MIN(cause_name) AS cause_name,
	SUM(delay_sum_year) AS delay_sum_grand,
	DENSE_RANK() OVER(PARTITION BY airport_code 
		ORDER BY SUM(delay_sum_year) DESC) AS delay_rank
FROM rdya
GROUP BY airport_code, cause_name
)

SELECT 
	MIN(cause_name),
	SUM(delay_sum_grand),
	DENSE_RANK() OVER(ORDER BY SUM(delay_sum_grand) DESC) AS delay_rank
FROM rdga
GROUP BY cause_name
-- WHERE delay_rank <= 3

