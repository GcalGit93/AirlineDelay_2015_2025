INSERT INTO carrier_dim (carrier_code, carrier_name)
SELECT DISTINCT carrier AS carrier_code,
	MIN(carrier_name) AS carrier_name
FROM stagingairlinedelay
GROUP BY carrier_code
ON CONFLICT (carrier_code) DO NOTHING;

INSERT INTO airport_dim (airport_code, airport_name)
SELECT DISTINCT airport AS airport_code,
	MIN(airport_name) AS airport_name
FROM stagingairlinedelay
GROUP BY airport_code
ON CONFLICT (airport_code) DO NOTHING;

INSERT INTO flight_date_dim (date_id, delay_year, delay_month, month_name, quarter)
SELECT DISTINCT
	(delay_year*100+delay_month) AS date_id,
	delay_year,
	delay_month,
	TO_CHAR(TO_DATE(delay_month::TEXT, 'MM'), 'Month') as month_name,
	((delay_month-1)/3)+1 AS quarter
FROM stagingairlinedelay
ORDER BY delay_year, delay_month;

INSERT INTO delay_cause_dim (cause_name)
VALUES
('Carrier'),
('Weather'),
('NAS'),
('Security'),
('Late Aircraft')
ON CONFLICT (cause_name) DO NOTHING;

INSERT INTO fact_flights(date_id, carrier_id, airport_id, arr_flights,
	arr_del15, arr_cancelled, arr_diverted, arr_delay)
SELECT
	(s.delay_year*100+s.delay_month) AS date_id,
	c.carrier_id AS carrier_id,
	a.airport_id AS airport_id,
	s.arr_flights,
	s.arr_del15,
	s.arr_cancelled,
	s.arr_diverted,
	s.arr_delay
FROM stagingairlinedelay AS s
JOIN carrier_dim AS c ON
s.carrier = c.carrier_code
JOIN airport_dim AS a ON
s.airport = a.airport_code;

INSERT INTO fact_flight_delays (flight_id, delay_cause_id, delay_count, delay_minutes)
SELECT
	f.flight_id,
	dc.delay_cause_id,
	delays.delay_count,
	delays.delay_minutes
FROM stagingairlinedelay AS s
--- following joins serve to match up serially generated ids to original staging table based on carrier and airport codes as well as flight dates
JOIN carrier_dim AS c 
ON s.carrier = c.carrier_code

JOIN airport_dim AS a
ON s.airport = a.airport_code

JOIN fact_flights AS f
ON f.date_id = (s.delay_year*100+s.delay_month)
AND f.carrier_id = c.carrier_id
AND f.airport_id = a.airport_id
--- This will pivot the delay quantities so they become row entries for each delay going from wide to long 
CROSS JOIN LATERAL (
	VALUES
		('Carrier', s.carrier_ct, s.carrier_delay),
		('Weather', s.weather_ct, s.weather_delay),
		('NAS', s.nas_ct, s.nas_delay),
		('Security', s.security_ct, s.security_delay),
		('Late Aircraft', s.late_aircraft_ct, s.late_aircraft_delay)
) AS delays(cause_name, delay_count, delay_minutes)

JOIN delay_cause_dim AS dc
ON dc.cause_name = delays.cause_name

---WHERE delays.delay_minutes >= 0
---	OR delays.delay_count >= 0; --- this filter will actually filter for each delay cause in the value array. If the particular delay is greater than 0 for particular records, those records are the ones included in the pivot and joined
