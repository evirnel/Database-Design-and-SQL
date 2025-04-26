-- Project 2:  Operate Your Own Airline

------------------------------------------------------------------
-- SET UP SCHEMA 
------------------------------------------------------------------

-- Drop existing schema and all its objects if it exists
DROP SCHEMA IF EXISTS project2 CASCADE;

-- Create a new schema
CREATE SCHEMA project2;

-- Set the search path so we can avoid writing a new project table everytime 
SET search_path TO project2;


------------------------------------------------------------------
-- SET UP TABLES 
------------------------------------------------------------------

-- Table for aircrafts
CREATE TABLE aircrafts (
    registration_number varchar(10) PRIMARY KEY, 
    plane_type varchar(50) NOT NULL, 
    total_first_class_seats smallint NOT NULL,
    total_business_seats smallint NOT NULL,
    operating_cost_per_hour int NOT NULL -- Need cost to determine profitability
); 

-- Table for airports
CREATE TABLE airports (
    airport_code varchar(3) PRIMARY KEY, 
    airport_name varchar(100) NOT NULL,
    city varchar(60) NOT NULL,
    country varchar(60) NOT NULL,
    continent varchar(20) NOT NULL,
    airport_timezone varchar(60) NOT NULL -- How you convert flight time into local time
);

-- Add a table for seat configuration for each aircraft
CREATE TABLE seat_configurations (
    aircraft_registration varchar(10),
    seat_number varchar(4),
    service_class varchar(10) NOT NULL CHECK (service_class IN ('First', 'Business')),
    PRIMARY KEY (aircraft_registration, seat_number),
    FOREIGN KEY (aircraft_registration) REFERENCES aircrafts(registration_number) ON UPDATE CASCADE ON DELETE CASCADE
);

-- Flight schedule table, each row is a unique flight instance
-- need flight_id 
CREATE TABLE flightschedule (
    flight_number varchar(10),
    aircraft_registration varchar(10) NOT NULL,
    origin_airport varchar(3) NOT NULL,
    destination_airport varchar(3) NOT NULL,
    departure_time timestamptz NOT NULL,
    arrival_time timestamptz NOT NULL, 
    first_class_fare numeric(10, 2) NOT NULL,
    business_class_fare numeric(10, 2) NOT NULL,
    PRIMARY KEY (flight_number, departure_time),
    FOREIGN KEY (aircraft_registration) REFERENCES aircrafts(registration_number) ON UPDATE CASCADE ON DELETE RESTRICT,
	FOREIGN KEY (origin_airport) REFERENCES airports(airport_code) ON UPDATE CASCADE ON DELETE RESTRICT,
	FOREIGN KEY (destination_airport) REFERENCES airports(airport_code) ON UPDATE CASCADE ON DELETE RESTRICT,
    CHECK (departure_time < arrival_time)
);



-- Passengers table (passport is unique identifier)
DROP TABLE IF EXISTS passengers CASCADE;

-- temporary passenger id

CREATE TABLE passengers (
    passport_number varchar(20),
    passport_country varchar(80),
    first_name varchar(80) NOT NULL,
    last_name varchar(80) NOT NULL,
    email varchar(100),
    phone varchar(30),
    address varchar(255),
    city varchar(80),
    state varchar(2),
    zip varchar(10),
    passport_expire_date date NOT NULL,
    PRIMARY KEY (passport_number, passport_country),
    CHECK (passport_expire_date > current_date)
);


-- SIMPLIFY Reservations table (one per group booking)
-- Need specific flight
-- reser
CREATE TABLE reservations (
    booking_reference varchar(10) PRIMARY KEY,
	flight_number varchar(10),
    departure_time timestamptz,
    booking_date timestamp NOT NULL DEFAULT current_timestamp
);

-- CONNECTING BRIDGE BETWEEN RESERVATIONS AND PASSENGERS
-- Bridge table: reservation_passengers links reservations, passengers, flights, and seats
CREATE TABLE reservation_passengers (
    booking_reference varchar(10),
    passport_number varchar(20),
    passport_country varchar(50),
    seat_number varchar(4) NOT NULL,
    service_class varchar(10) NOT NULL CHECK (service_class IN ('First', 'Business')),
    PRIMARY KEY (booking_reference, passport_number, passport_country),
    FOREIGN KEY (booking_reference) REFERENCES reservations(booking_reference) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (passport_number, passport_country) REFERENCES passengers(passport_number, passport_country) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- Need 3 planes for three routes, or one of the planes from boston won't come back forever and then with fly from cairo to paris back and forth
INSERT INTO aircrafts (registration_number, plane_type, total_first_class_seats, total_business_seats, operating_cost_per_hour) VALUES
('N200AA', 'Airbus A350', 10, 40, 10259), 
('N300AA', 'Boeing 777', 12, 48, 9500),
('N400AA', 'Boeing 747', 12, 48, 9500);

-- Insert 15ish airports
INSERT INTO airports (airport_code, airport_name, city, country, continent, airport_timezone) VALUES
('BOS', 'Logan International Airport', 'Boston', 'USA', 'North America', 'America/New_York'),
('JFK', 'John F. Kennedy International', 'New York', 'USA', 'North America', 'America/New_York'),
('LHR', 'Heathrow Airport', 'London', 'UK', 'Europe', 'Europe/London'),
('CDG', 'Charles de Gaulle', 'Paris', 'France', 'Europe', 'Europe/Paris'),
('NRT', 'Narita International Airport', 'Tokyo', 'Japan', 'Asia', 'Asia/Tokyo'),
('AMS', 'Amsterdam Schiphol', 'Amsterdam', 'Netherlands', 'Europe', 'Europe/Amsterdam'),
('DXB', 'Dubai International', 'Dubai', 'UAE', 'Asia', 'Asia/Dubai'),
('HND', 'Haneda Airport', 'Tokyo', 'Japan', 'Asia', 'Asia/Tokyo'),
('SIN', 'Changi Airport', 'Singapore', 'Singapore', 'Asia', 'Asia/Singapore'),
('JNB', 'O. R. Tambo', 'Johannesburg', 'South Africa', 'Africa', 'Africa/Johannesburg'),
('CAI', 'Cairo International', 'Cairo', 'Egypt', 'Africa', 'Africa/Cairo'),
('GRU', 'Guarulhos', 'Sao Paulo', 'Brazil', 'South America', 'America/Sao_Paulo'),
('SYD', 'Sydney Kingsford Smith', 'Sydney', 'Australia', 'Australia', 'Australia/Sydney'),
('LAX', 'Los Angeles International', 'Los Angeles', 'USA', 'North America', 'America/Los_Angeles'),
('DEL', 'Indira Gandhi', 'Delhi', 'India', 'Asia', 'Asia/Kolkata');

------------------------------------------------------------------
-- CREATING FLIGHTS
------------------------------------------------------------------

-- AUTOGENERATE 150ish flights
-- ONLY SIX FLIGHT NUMBERS (FL001, FL002, etc.)
-- spacing flights too close together, generate evry 7 days 
-- should have 180 flights

-- FL001: Boston (BOS) to London (LHR) - Every other day
INSERT INTO flightschedule (flight_number, aircraft_registration, origin_airport, destination_airport, departure_time, arrival_time, first_class_fare, business_class_fare)
SELECT
    'FL001',
    'N200AA',
    'BOS',
    'LHR',
    departure_time,
    departure_time + interval '6 hours 45 minutes',
    3500.00,
    2200.00
FROM (
    SELECT generate_series(
        '2025-04-22 18:00:00+00'::timestamptz,
        '2025-12-31 18:00:00+00'::timestamptz,
        '7 days'::interval
    ) LIMIT 30
) AS series(departure_time);

-- FL002: London (LHR) to Boston (BOS)
INSERT INTO flightschedule (flight_number, aircraft_registration, origin_airport, destination_airport, departure_time, arrival_time, first_class_fare, business_class_fare)
SELECT
    'FL002',
    'N200AA',
    'LHR',
    'BOS',
    departure_time + interval '12 hours',
    (departure_time + interval '12 hours') + interval '7 hours 15 minutes',
    3500.00,
    2200.00
FROM (
    SELECT generate_series(
        '2025-04-22 18:00:00+00'::timestamptz,
        '2025-12-31 18:00:00+00'::timestamptz,
        '7 days'::interval
    ) LIMIT 30
) AS series(departure_time);


-- FL003: Boston to Tokyo (NRT)
INSERT INTO flightschedule (flight_number, aircraft_registration, origin_airport, destination_airport, departure_time, arrival_time, first_class_fare, business_class_fare)
SELECT
    'FL003',
    'N300AA',
    'BOS',
    'NRT',
    departure_time,
    departure_time + interval '13 hours 30 minutes',
    4200.00,
    2800.00
FROM (
    SELECT generate_series(
        '2025-04-23 07:00:00+00'::timestamptz,
        '2025-12-31 07:00:00+00'::timestamptz,
        '7 days'::interval
    ) LIMIT 30
) AS series(departure_time);

-- FL004: Tokyo (NRT) to Boston
INSERT INTO flightschedule (flight_number, aircraft_registration, origin_airport, destination_airport, departure_time, arrival_time, first_class_fare, business_class_fare)
SELECT
    'FL004',
    'N300AA',
    'NRT',
    'BOS',
    departure_time + interval '10 hours',
    (departure_time + interval '10 hours') + interval '12 hours 45 minutes',
    4200.00,
    2800.00
FROM (
    SELECT generate_series(
        '2025-04-23 07:00:00+00'::timestamptz,
        '2025-12-31 07:00:00+00'::timestamptz,
        '7 days'::interval
    ) LIMIT 30
) AS series(departure_time);

-- FL005: Cairo (CAI) to Paris (CDG)
INSERT INTO flightschedule (flight_number, aircraft_registration, origin_airport, destination_airport, departure_time, arrival_time, first_class_fare, business_class_fare)
SELECT
    'FL005',
    'N400AA',
    'CAI',
    'CDG',
    departure_time,
    departure_time + interval '4 hours 15 minutes',
    2500.00,
    1600.00
FROM (
    SELECT generate_series(
        '2025-04-24 09:00:00+00'::timestamptz,
        '2025-12-31 09:00:00+00'::timestamptz,
        '7 days'::interval
    ) LIMIT 30
) AS series(departure_time);

-- FL006: Paris (CDG) to Cairo (CAI)
INSERT INTO flightschedule (flight_number, aircraft_registration, origin_airport, destination_airport, departure_time, arrival_time, first_class_fare, business_class_fare)
SELECT
    'FL006',
    'N400AA',
    'CDG',
    'CAI',
    departure_time + interval '6 hours',
    (departure_time + interval '6 hours') + interval '4 hours 30 minutes',
    2500.00,
    1600.00
FROM (
    SELECT generate_series(
        '2025-04-24 09:00:00+00'::timestamptz,
        '2025-12-31 09:00:00+00'::timestamptz,
        '7 days'::interval
    ) LIMIT 30
) AS series(departure_time);

------------------------------------------------------------------
-- CREATING PASSENGERS, 1000 PASSENGERS
------------------------------------------------------------------
DROP FUNCTION IF EXISTS faker_person;

CREATE OR REPLACE FUNCTION faker_person()
RETURNS TABLE(
    passport_number varchar(20),
    passport_country varchar(60),
    first_name varchar(60),
    last_name varchar(60),
    email varchar(100),
    phone varchar(30),
    address varchar(255),
    city varchar(60),
    state varchar(2),
    zip varchar(10),
    passport_expire_date date
) LANGUAGE plpython3u AS
$$
from faker import Faker
import random
from datetime import datetime, timedelta
fake = Faker()
passport_num = ''.join(random.choices('0123456789', k=9))
country = fake.country()
first_name = fake.first_name()
last_name = fake.last_name()
email = fake.email()
phone = fake.phone_number()
address = fake.address().replace('\n', ', ')
city = fake.city()
state = fake.state_abbr()
zip_code = fake.zipcode()
today = datetime.now()
years_to_add = random.randint(1, 10)
expire_date = today + timedelta(days=365 * years_to_add)
return [(passport_num, country, first_name, last_name, email, phone, address, city, state, zip_code, expire_date.date())]
$$;


-- To insert 1000 rows
INSERT INTO passengers (
    passport_number, passport_country, first_name, last_name,
    email, phone, address, city, state, zip, passport_expire_date
)SELECT (faker_person()).* FROM generate_series(1,1000);

------------------------------------------------------------------
-- ADDING SEAT CONFIGURATIONS
------------------------------------------------------------------
-- Add seat configurations for each aircraft type
DELETE FROM seat_configurations;

-- Insert First Class seats for N200AA (Airbus A350: 10 First Class seats)
INSERT INTO seat_configurations (aircraft_registration, seat_number, service_class)
SELECT 
    'N200AA', 
    row_num || seat_letter, 
    'First'
FROM 
    generate_series(1, 2) AS row_num,
    unnest(ARRAY['A','B','C','D','E']) AS seat_letter;

-- Insert Business Class seats for N200AA (Airbus A350: 40 Business Class seats)
INSERT INTO seat_configurations (aircraft_registration, seat_number, service_class)
SELECT 
    'N200AA', 
    row_num || seat_letter, 
    'Business'
FROM 
    generate_series(3, 12) AS row_num,
    unnest(ARRAY['A','B','C','D']) AS seat_letter;

-- Insert First Class seats for N300AA (Boeing 777: 12 First Class seats)
INSERT INTO seat_configurations (aircraft_registration, seat_number, service_class)
SELECT 
    'N300AA', 
    row_num || seat_letter, 
    'First'
FROM 
    generate_series(1, 3) AS row_num,
    unnest(ARRAY['A','B','C','D']) AS seat_letter;

-- Insert Business Class seats for N300AA (Boeing 777: 48 Business Class seats)
INSERT INTO seat_configurations (aircraft_registration, seat_number, service_class)
SELECT 
    'N300AA', 
    row_num || seat_letter, 
    'Business'
FROM 
    generate_series(4, 16) AS row_num,
    unnest(ARRAY['A','B','C','D']) AS seat_letter;

-- Insert First Class seats for N400AA (Boeing 747: 12 First Class seats)
INSERT INTO seat_configurations (aircraft_registration, seat_number, service_class)
SELECT 
    'N400AA', 
    row_num || seat_letter, 
    'First'
FROM 
    generate_series(1, 3) AS row_num,
    unnest(ARRAY['A','B','C','D']) AS seat_letter;

-- Insert Business Class seats for N400AA (Boeing 747: 48 Business Class seats)
INSERT INTO seat_configurations (aircraft_registration, seat_number, service_class)
SELECT 
    'N400AA', 
    row_num || seat_letter, 
    'Business'
FROM 
    generate_series(4, 16) AS row_num,
    unnest(ARRAY['A','B','C','D']) AS seat_letter;

-- Check results
SELECT COUNT(*) FROM seat_configurations;
SELECT * FROM seat_configurations LIMIT 10;

------------------------------------------------------------------
-- CREATING AND FILLING RESERVATIONS
------------------------------------------------------------------
-- fill in reservations 
-- Insert into reservations table
-- Clear existing reservations if needed
-- DELETE FROM reservations;

-- Insert reservations the booking_reference(making that my flight_id)
INSERT INTO reservations (booking_reference, flight_number, departure_time, booking_date)
SELECT 
    -- Letter + Number + Letter + Number + Letter + Letter for booking_reference
chr(random(65, 90)) || random(1,9) || chr(random(65,90)) || random(1,9) || chr(random(65,90)) || chr(random(65,90)) AS booking_reference,
    fs.flight_number,
    fs.departure_time,
    (fs.departure_time - (floor(random() * 60) + 1)::int * interval '1 day')::timestamp
FROM flightschedule fs;

-- Assign passengers and seats
WITH reservation_list AS (
    SELECT
        booking_reference,
        flight_number,
        departure_time,
        ROW_NUMBER() OVER (ORDER BY booking_reference) AS reservation_num
    FROM reservations
),
passenger_list AS (
    SELECT
        passport_number,
        passport_country,
        ROW_NUMBER() OVER (ORDER BY passport_number) AS passenger_num
    FROM passengers
),
flight_capacity AS (
    SELECT
        fs.flight_number,
        fs.departure_time,
        COUNT(sc.seat_number) AS total_seats
    FROM flightschedule fs
    JOIN seat_configurations sc ON fs.aircraft_registration = sc.aircraft_registration
    GROUP BY fs.flight_number, fs.departure_time
),
booked_seats AS (
    SELECT
        r.flight_number,
        r.departure_time,
        COUNT(rp.seat_number) AS booked_seats_count
    FROM reservations r
    LEFT JOIN reservation_passengers rp ON r.booking_reference = rp.booking_reference
    GROUP BY r.flight_number, r.departure_time
),
eligible_flights AS (
    SELECT
        fc.flight_number,
        fc.departure_time,
        fc.total_seats,
        COALESCE(bs.booked_seats_count, 0) AS booked_seats_count
    FROM flight_capacity fc
    LEFT JOIN booked_seats bs ON fc.flight_number = bs.flight_number AND fc.departure_time = bs.departure_time
    WHERE (COALESCE(bs.booked_seats_count, 0)::decimal / fc.total_seats) < 1.0  -- Only consider flights that are less than 100% full
),
aircraft_info AS (
    SELECT
        fs.flight_number,
        fs.departure_time,
        fs.aircraft_registration,
        sc.seat_number,
        sc.service_class,
        (
            SELECT COUNT(*)
            FROM seat_configurations sc2
            WHERE sc2.aircraft_registration = sc.aircraft_registration
              AND sc2.service_class = sc.service_class
              AND sc2.seat_number <= sc.seat_number
        ) AS seat_position
    FROM flightschedule fs
    INNER JOIN seat_configurations sc
        ON fs.aircraft_registration = sc.aircraft_registration
    WHERE EXISTS (SELECT 1 FROM eligible_flights ef WHERE fs.flight_number = ef.flight_number AND fs.departure_time = ef.departure_time)
),
seats_to_fill AS (
    SELECT
        ef.flight_number,
        ef.departure_time,
        ef.total_seats,
        ef.booked_seats_count,
        LEAST((ef.total_seats * (0.7 + (random() * 0.3))) - ef.booked_seats_count, (SELECT COUNT(*) FROM passengers))::int AS seats_to_add
    FROM eligible_flights ef
)
INSERT INTO reservation_passengers (
    booking_reference,
    passport_number,
    passport_country,
    seat_number,
    service_class
)
SELECT DISTINCT ON (r.booking_reference, p.passport_number, p.passport_country)
    r.booking_reference,
    p.passport_number,
    p.passport_country,
    ai.seat_number,
    ai.service_class
FROM reservation_list r
JOIN passenger_list p
    ON (r.reservation_num % (SELECT COUNT(*) FROM passengers)) + 1 = p.passenger_num
JOIN aircraft_info ai
    ON r.flight_number = ai.flight_number
   AND r.departure_time = ai.departure_time
   AND (
        CASE
            WHEN ai.service_class = 'First'
            THEN (r.reservation_num % (SELECT COUNT(*) FROM seat_configurations WHERE aircraft_registration = ai.aircraft_registration AND service_class = 'First')) + 1
            ELSE (r.reservation_num % (SELECT COUNT(*) FROM seat_configurations WHERE aircraft_registration = ai.aircraft_registration AND service_class = 'Business')) + 1
        END
    ) = ai.seat_position
JOIN seats_to_fill stf
    ON r.flight_number = stf.flight_number
    AND r.departure_time = stf.departure_time
WHERE stf.seats_to_add > 0
AND (r.reservation_num -1) < stf.seats_to_add -- Limit the number of added passengers to the calculated seats_to_add
;

-- Check results
SELECT COUNT(*) FROM reservations;
SELECT * FROM reservations LIMIT 10;

------------------------------------------------------------------
-- CONNECT PASSENGERS AND FLIGHT RESERVATIONS
------------------------------------------------------------------

-- Do the reservations for each
-- Step 1: Create a common table expression to number reservations
WITH reservation_numbering AS (
    SELECT
        booking_reference,
        flight_number,
        departure_time,
        ROW_NUMBER() OVER (PARTITION BY flight_number, departure_time ORDER BY booking_reference) AS seat_ix,
        ROW_NUMBER() OVER (ORDER BY booking_reference) AS global_rn
    FROM reservations
),
-- Step 2: Get seat configurations for each aircraft
flight_seats AS (
    SELECT
        fs.flight_number,
        fs.departure_time,
        sc.seat_number,
        sc.service_class,
        ROW_NUMBER() OVER (
            PARTITION BY fs.flight_number, fs.departure_time, sc.service_class 
            ORDER BY sc.seat_number
        ) AS seat_position
    FROM flightschedule fs
    JOIN seat_configurations sc ON fs.aircraft_registration = sc.aircraft_registration
),
-- Step 3: Enumerate passengers
passenger_numbering AS (
    SELECT
        passport_number,
        passport_country,
        ROW_NUMBER() OVER (ORDER BY passport_number, passport_country) AS passenger_rn
    FROM passengers
),
-- Step 4: Combine to create assignment
assignment_data AS (
    SELECT
        r.booking_reference,
        p.passport_number,
        p.passport_country,
        -- For first 10-30% of passengers use first class, rest use business
        CASE WHEN p.passenger_rn <= (SELECT COUNT(*) * 0.2 FROM passengers) 
             THEN fs.seat_number 
             ELSE bs.seat_number
        END AS seat_number,
        CASE WHEN p.passenger_rn <= (SELECT COUNT(*) * 0.2 FROM passengers) 
             THEN 'First' 
             ELSE 'Business'
        END AS service_class
    FROM reservation_numbering r
    -- Get passenger based on global ranking
    JOIN passenger_numbering p ON p.passenger_rn = r.global_rn
    -- Get first class seat
    LEFT JOIN (
        SELECT * FROM flight_seats WHERE service_class = 'First'
    ) fs ON fs.flight_number = r.flight_number 
        AND fs.departure_time = r.departure_time 
        AND fs.seat_position = (r.global_rn % 10) + 1
    -- Get business class seat
    LEFT JOIN (
        SELECT * FROM flight_seats WHERE service_class = 'Business'
    ) bs ON bs.flight_number = r.flight_number 
        AND bs.departure_time = r.departure_time 
        AND bs.seat_position = (r.global_rn % 40) + 1
    -- Only assign up to the number of passengers we have
    WHERE r.global_rn <= (SELECT COUNT(*) FROM passengers)
)

-- Insert the data from the assignment_data CTE into the reservation_passengers table
INSERT INTO reservation_passengers (
    booking_reference,
    passport_number,
    passport_country,
    seat_number,
    service_class
)
SELECT
    booking_reference,
    passport_number,
    passport_country,
    seat_number,
    service_class
FROM assignment_data;

-- Check results
SELECT COUNT(*) FROM reservation_passengers;
SELECT * FROM reservation_passengers LIMIT 10;

-- Final Reservations and Passengers with Flight Details

SELECT
    r.booking_reference,
    p.passport_number,
    p.first_name,
    p.last_name,
    fs.flight_number,
    fs.origin_airport,
    fs.destination_airport,
    fs.departure_time,
    fs.arrival_time,
    rp.seat_number,
    rp.service_class
FROM
    reservations r
INNER JOIN
    reservation_passengers rp ON r.booking_reference = rp.booking_reference
INNER JOIN
    passengers p ON rp.passport_number = p.passport_number AND rp.passport_country = p.passport_country
INNER JOIN
    flightschedule fs ON r.flight_number = fs.flight_number AND r.departure_time = fs.departure_time;
	
------------------------------------------------------------------
-- QUERIES
------------------------------------------------------------------

-- Did you, will you make money?
------------------------------------------------------------------
-- Calculate revenue and costs for each flight, then sum up for profitability analysis
SELECT 
    SUM(revenue) AS total_revenue,
    SUM(cost) AS total_cost,
    SUM(revenue) - SUM(cost) AS profit,
    CASE WHEN SUM(revenue) > SUM(cost) THEN 'Yes, profitable' ELSE 'No, unprofitable' END AS is_profitable
FROM (
    -- Calculate revenue and cost per flight
    SELECT 
        fs.flight_number,
        fs.departure_time,
        fs.aircraft_registration,
        -- Revenue from first class passengers
        (SELECT COUNT(*) FROM reservation_passengers rp
         JOIN reservations r ON rp.booking_reference = r.booking_reference
         WHERE r.flight_number = fs.flight_number 
         AND r.departure_time = fs.departure_time
         AND rp.service_class = 'First') * fs.first_class_fare AS first_class_revenue,
        
        -- Revenue from business class passengers
        (SELECT COUNT(*) FROM reservation_passengers rp
         JOIN reservations r ON rp.booking_reference = r.booking_reference
         WHERE r.flight_number = fs.flight_number 
         AND r.departure_time = fs.departure_time
         AND rp.service_class = 'Business') * fs.business_class_fare AS business_class_revenue,
        
        -- Total revenue
        (SELECT COUNT(*) FROM reservation_passengers rp
         JOIN reservations r ON rp.booking_reference = r.booking_reference
         WHERE r.flight_number = fs.flight_number 
         AND r.departure_time = fs.departure_time
         AND rp.service_class = 'First') * fs.first_class_fare
        +
        (SELECT COUNT(*) FROM reservation_passengers rp
         JOIN reservations r ON rp.booking_reference = r.booking_reference
         WHERE r.flight_number = fs.flight_number 
         AND r.departure_time = fs.departure_time
         AND rp.service_class = 'Business') * fs.business_class_fare AS revenue,
        
        -- Cost based on flight duration and aircraft operating cost
        EXTRACT(EPOCH FROM (fs.arrival_time - fs.departure_time))/3600 * 
        (SELECT a.operating_cost_per_hour FROM aircrafts a WHERE a.registration_number = fs.aircraft_registration) AS cost
        
    FROM flightschedule fs
) AS flight_economics;

-- Check results
SELECT COUNT(*) FROM reservation_passengers;
SELECT * FROM flight_economics;

-- How many seats are filled or remaining on a particular flight?
------------------------------------------------------------------

-- I wan to go to London, so I'll look at the flight FL001 (BOSTON TO LONDON)
-- from Boston (BOS) to London (LHR) October 21, 2025 at 14:00 Boston time

SELECT
    fs.flight_number,
    fs.departure_time,
    fs.origin_airport || ' to ' || fs.destination_airport AS route,
    -- Count all possible seats on this aircraft
    COUNT(DISTINCT rp.seat_number) AS seats_filled,
    -- Calculate remaining available seats
    COUNT(DISTINCT sc.seat_number) - COUNT(DISTINCT rp.seat_number) AS seats_remaining
FROM flightschedule fs
-- Join with aircraft to get the plane details
INNER JOIN aircrafts a 
    ON a.registration_number = fs.aircraft_registration
-- Join with seat configurations to get all seats on this aircraft
INNER JOIN seat_configurations sc 
    ON sc.aircraft_registration = a.registration_number
-- Left join with reservations to find bookings for this flight
LEFT JOIN reservations r 
    ON r.flight_number = fs.flight_number
    AND r.departure_time = fs.departure_time
-- Left join with reservation_passengers to find actual seat assignments
LEFT JOIN reservation_passengers rp
    ON rp.booking_reference = r.booking_reference
    AND rp.seat_number = sc.seat_number
-- Specify the Boston to London flight on October 21, 2025
WHERE fs.flight_number = 'FL001'  
AND fs.departure_time = '2025-10-21 14:00:00-04'::timestamptz  
GROUP BY fs.flight_number, fs.departure_time, route;


-- Departure and arrival times in local time zone.
------------------------------------------------------------------
SELECT 
    fs.flight_number,
    origin.airport_code AS origin_code,
    origin.city AS origin_city,
    destination.airport_code AS destination_code,
    destination.city AS destination_city,
    fs.departure_time AT TIME ZONE origin.airport_timezone AS local_departure_time,
    fs.arrival_time AT TIME ZONE destination.airport_timezone AS local_arrival_time,
    EXTRACT(EPOCH FROM (fs.arrival_time - fs.departure_time))/3600 AS flight_duration_hours
FROM flightschedule fs
JOIN airports origin ON fs.origin_airport = origin.airport_code
JOIN airports destination ON fs.destination_airport = destination.airport_code
ORDER BY fs.departure_time;

SELECT * FROM flightschedule 
WHERE flight_number = 'FL001' 
ORDER BY departure_time;
