-- raw_data_audit.sql
-- Purpose: Perform data quality checks on the raw data in the staging tables.

SET search_path TO safari_connect;

--1. Confirm total number of records in the bookings_staging table
SELECT count(*) AS total_rows
FROM bookings_staging;

--2. Preview the raw data (first 10 rows)
SELECT *
FROM bookings_staging
LIMIT 10;

--3. Check for Passenger name casing errors and whitespace
SELECT booking_id, passenger_name
FROM bookings_staging
WHERE passenger_name <> INITCAP(TRIM(passenger_name))
   OR passenger_name <> TRIM(passenger_name);

--4. Phone number format validation
SELECT booking_id, passenger_phone
FROM bookings_staging
WHERE passenger_phone IS NULL
   OR TRIM(passenger_phone) = ''
   OR passenger_phone LIKE '%-%'
   OR passenger_phone LIKE '+254%'
   OR LENGTH(REGEXP_REPLACE(passenger_phone, '[^0-9]', '', 'g')) NOT IN (9, 10, 12);

--5. Gender inconsistencies
SELECT passenger_gender, COUNT(*) AS records
FROM bookings_staging
GROUP BY passenger_gender
ORDER BY records DESC;

--6. Passenger city casing, whitespace, or missing values
SELECT booking_id, passenger_city
FROM bookings_staging
WHERE passenger_city IS NULL
   OR TRIM(passenger_city) = ''
   OR passenger_city <> INITCAP(TRIM(passenger_city));

--7. Route city casing issues
SELECT booking_id, route_from, route_to
FROM bookings_staging
WHERE route_from <> INITCAP(TRIM(route_from))
   OR route_to <> INITCAP(TRIM(route_to));

-- 8. Variations in vehicle types
SELECT vehicle_type, COUNT(*) AS records
FROM bookings_staging
GROUP BY vehicle_type
ORDER BY records DESC;

-- 9. Driver name casing issues and whitespace issues
SELECT booking_id, driver_name
FROM bookings_staging
WHERE driver_name <> INITCAP(TRIM(driver_name))
   OR driver_name <> TRIM(driver_name);

-- 10. Date formats for depatures
SELECT departure_date, COUNT(*) AS records
FROM bookings_staging
GROUP BY departure_date
ORDER BY departure_date;

-- 11. Variations in seat classes
SELECT seat_class, COUNT(*) AS records
FROM bookings_staging
GROUP BY seat_class
ORDER BY records DESC;

-- 12. Payment method variations
SELECT payment_method, COUNT(*) AS records
FROM bookings_staging
GROUP BY payment_method
ORDER BY records DESC;

-- 13. Booking status variations
SELECT booking_status, COUNT(*) AS records
FROM bookings_staging
GROUP BY booking_status
ORDER BY records DESC;

-- 14. Fare fields stored as text
SELECT booking_id, fare_per_seat, total_fare
FROM bookings_staging
WHERE fare_per_seat ~ '[^0-9.]'
   OR total_fare ~ '[^0-9.]';

-- 15. Invalid trip ratings
SELECT booking_id, booking_status, trip_rating
FROM bookings_staging
WHERE NULLIF(TRIM(trip_rating), '') IS NOT NULL
  AND (
        trip_rating !~ '^[0-9]+$'
        OR trip_rating::INT NOT BETWEEN 1 AND 5
      );

-- 16. Negative or invalid seats booked
SELECT booking_id, seats_booked
FROM bookings_staging
WHERE seats_booked !~ '^-?[0-9]+$'
   OR seats_booked::INT <= 0;

-- 17. Duplicate booking IDs
SELECT booking_id, COUNT(*) AS duplicate_count
FROM bookings_staging
GROUP BY booking_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;