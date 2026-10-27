CREATE TABLE carrier_dim (
	carrier_id SERIAL PRIMARY KEY, 
	carrier_code VARCHAR UNIQUE,
	carrier_name VARCHAR
);

CREATE TABLE airport_dim (
	airport_id SERIAL PRIMARY KEY,
	airport_code VARCHAR UNIQUE,
	airport_name VARCHAR
);

CREATE TABLE flight_date_dim (
	date_id INT PRIMARY KEY,
	delay_year INT,
	delay_month INT,
	month_name VARCHAR,
	quarter INT
);

CREATE TABLE delay_cause_dim (
	delay_cause_id SERIAL PRIMARY KEY,
	cause_name VARCHAR UNIQUE
);

CREATE TABLE fact_flight_delays (
	delay_id SERIAL PRIMARY KEY,
	flight_id INT,
	delay_cause_id INT REFERENCES delay_cause_dim(delay_cause_id),
	delay_count NUMERIC,
	delay_minutes INT
);

CREATE TABLE fact_flights (
	flight_id SERIAL PRIMARY KEY,
	date_id INT REFERENCES flight_date_dim (date_id),
	carrier_id INT REFERENCES carrier_dim (carrier_id),
	airport_id INT REFERENCES airport_dim (airport_id),
	arr_flights INT,
	arr_del15 INT,
	arr_cancelled INT,
	arr_diverted INT,
	arr_delay INT
);

/*
DROP TABLE fact_flights CASCADE;
DROP TABLE fact_flight_delays CASCADE;
DROP TABLE delay_cause_dim CASCADE;
DROP TABLE flight_date_dim CASCADE;
DROP TABLE airport_dim CASCADE;
DROP TABLE carrier_dim CASCADE;

\copy (SELECT * FROM fact_flights) TO 'C:/Users/E1cal/Desktop/Competed Projects/AirlineDelay_2015_2025/flight_info.csv' CSV HEADER;
*/