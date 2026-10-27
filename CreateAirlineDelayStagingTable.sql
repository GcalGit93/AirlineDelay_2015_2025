CREATE TABLE StagingAirlineDelay (
	delay_year INTEGER,
	delay_month INTEGER,
	carrier VARCHAR,
	carrier_name VARCHAR,
	airport VARCHAR,
	airport_name VARCHAR,
	arr_flights INTEGER,
	arr_del15 INTEGER,
	carrier_ct NUMERIC,
	weather_ct NUMERIC,
	nas_ct NUMERIC,
	security_ct NUMERIC,
	late_aircraft_ct NUMERIC,
	arr_cancelled INTEGER,
	arr_diverted INTEGER,
	arr_delay INTEGER,
	carrier_delay INTEGER,
	weather_delay INTEGER,
	nas_delay INTEGER,
	security_delay INTEGER,
	late_aircraft_delay INTEGER
);

/*
\copy StagingAirlineDelay(delay_year, delay_month, carrier, carrier_name, airport, 
	airport_name, arr_flights, arr_del15, carrier_ct, weather_ct, nas_ct, security_ct,
	late_aircraft_ct, arr_cancelled, arr_diverted, arr_delay, carrier_delay, weather_delay,
	nas_delay, security_delay, late_aircraft_delay) FROM 'C:\Users\E1cal\Desktop\Competed Projects\AirlineDelay_2015_2025\Airline_Delay_Cause.csv' CSV HEADER;


SELECT *
FROM stagingairlinedelay;
*/
--- DROP TABLE stagingairlinedelay CASCADE