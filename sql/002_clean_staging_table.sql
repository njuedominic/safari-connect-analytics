-- 02_clean_staging_table.sql
-- Purpose: To clean the dirty Safari Connect data in the staging table
-- Rule: SELECT before every UPDATE or DELETE

SET search_path TO safari_connect;

-- 1: passenger_name casing and whitespace
SELECT booking_id, passenger_name, INITCAP(TRIM(passenger_name)) AS cleaned_name
FROM bookings_staging
WHERE passenger_name <> INITCAP(TRIM(passenger_name))
   OR passenger_name <> TRIM(passenger_name);

UPDATE bookings_staging
SET passenger_name = INITCAP(TRIM(passenger_name))
WHERE passenger_name <> INITCAP(TRIM(passenger_name))
   OR passenger_name <> TRIM(passenger_name);

-------------------------------------------------------
-- 2: Clean the passenger_phone numbers
-- Remove non-numeric characters and standardise Kenyan phone format

SELECT booking_id, passenger_phone
FROM bookings_staging
WHERE passenger_phone IS NULL
   OR TRIM(passenger_phone) = ''
   OR passenger_phone ~ '[^0-9+]';

UPDATE bookings_staging
SET passenger_phone = NULL
WHERE passenger_phone IS NULL
   OR TRIM(passenger_phone) = '';

SELECT booking_id, passenger_phone,
       REGEXP_REPLACE(passenger_phone, '[^0-9]', '', 'g') AS digits_only
FROM bookings_staging
WHERE passenger_phone IS NOT NULL;

UPDATE bookings_staging
SET passenger_phone = REGEXP_REPLACE(passenger_phone, '[^0-9]', '', 'g')
WHERE passenger_phone IS NOT NULL;

SELECT booking_id, passenger_phone,
       CASE
           WHEN passenger_phone LIKE '254%' AND LENGTH(passenger_phone) = 12
               THEN '0' || SUBSTRING(passenger_phone FROM 4)
           WHEN passenger_phone LIKE '7%' AND LENGTH(passenger_phone) = 9
               THEN '0' || passenger_phone
           WHEN passenger_phone LIKE '0%' AND LENGTH(passenger_phone) = 10
               THEN passenger_phone
           ELSE passenger_phone
       END AS cleaned_phone
FROM bookings_staging
WHERE passenger_phone IS NOT NULL;

UPDATE bookings_staging
SET passenger_phone =
    CASE
        WHEN passenger_phone LIKE '254%' AND LENGTH(passenger_phone) = 12
            THEN '0' || SUBSTRING(passenger_phone FROM 4)
        WHEN passenger_phone LIKE '7%' AND LENGTH(passenger_phone) = 9
            THEN '0' || passenger_phone
        WHEN passenger_phone LIKE '0%' AND LENGTH(passenger_phone) = 10
            THEN passenger_phone
        ELSE passenger_phone
    END
WHERE passenger_phone IS NOT NULL;
-------------------------------------------------------
-- 3. Gender name standardization

SELECT booking_id, passenger_gender,
       CASE
           WHEN LOWER(TRIM(passenger_gender)) IN ('m', 'male') THEN 'Male'
           WHEN LOWER(TRIM(passenger_gender)) IN ('f', 'female') THEN 'Female'
           ELSE passenger_gender
       END AS cleaned_gender
FROM bookings_staging;

UPDATE bookings_staging
SET passenger_gender =
    CASE
        WHEN LOWER(TRIM(passenger_gender)) IN ('m', 'male') THEN 'Male'
        WHEN LOWER(TRIM(passenger_gender)) IN ('f', 'female') THEN 'Female'
        ELSE passenger_gender
    END;
-------------------------------------------------------
-- 4. Passenger_city, route_from, route_to cleaning
-------------------------------------------------------

SELECT booking_id, passenger_city
FROM bookings_staging
WHERE passenger_city IS NULL
   OR TRIM(passenger_city) = '';

UPDATE bookings_staging
SET passenger_city = 'Unknown'
WHERE passenger_city IS NULL
   OR TRIM(passenger_city) = '';

SELECT booking_id, passenger_city, route_from, route_to
FROM bookings_staging
WHERE passenger_city <> INITCAP(TRIM(passenger_city))
   OR route_from <> INITCAP(TRIM(route_from))
   OR route_to <> INITCAP(TRIM(route_to));

UPDATE bookings_staging
SET passenger_city = INITCAP(TRIM(passenger_city)),
    route_from = INITCAP(TRIM(route_from)),
    route_to = INITCAP(TRIM(route_to));

-------------------------------------------------------
-- 5. Vehicle type standardization
SELECT vehicle_type, COUNT(*) AS records
FROM bookings_staging
GROUP BY vehicle_type
ORDER BY records DESC;

UPDATE bookings_staging
SET vehicle_type =
    CASE
        WHEN LOWER(TRIM(vehicle_type)) = 'bus' THEN 'Bus'
        WHEN LOWER(TRIM(vehicle_type)) = 'matatu' THEN 'Matatu'
        WHEN LOWER(TRIM(vehicle_type)) = 'minibus' THEN 'Minibus'
        ELSE INITCAP(TRIM(vehicle_type))
    END;

-------------------------------------------------------
-- 6. Driver_name casing and whitespace cleaning
SELECT booking_id, driver_name, INITCAP(TRIM(driver_name)) AS cleaned_driver_name
FROM bookings_staging
WHERE driver_name <> INITCAP(TRIM(driver_name))
   OR driver_name <> TRIM(driver_name);

UPDATE bookings_staging
SET driver_name = INITCAP(TRIM(driver_name))
WHERE driver_name <> INITCAP(TRIM(driver_name))
   OR driver_name <> TRIM(driver_name);

-------------------------------------------------------
--7.  departure_date standardisation to YYYY-MM-DD
-- DD/MM/YYYY e.g. 15/09/2024
SELECT booking_id, departure_date,
       TO_CHAR(TO_DATE(departure_date, 'DD/MM/YYYY'), 'YYYY-MM-DD') AS cleaned_date
FROM bookings_staging
WHERE departure_date ~ '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$';

UPDATE bookings_staging
SET departure_date = TO_CHAR(TO_DATE(departure_date, 'DD/MM/YYYY'), 'YYYY-MM-DD')
WHERE departure_date ~ '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$';

-- MM-DD-YYYY e.g. 09-25-2024
SELECT booking_id, departure_date,
       TO_CHAR(TO_DATE(departure_date, 'MM-DD-YYYY'), 'YYYY-MM-DD') AS cleaned_date
FROM bookings_staging
WHERE departure_date ~ '^[0-9]{1,2}-[0-9]{1,2}-[0-9]{4}$';

UPDATE bookings_staging
SET departure_date = TO_CHAR(TO_DATE(departure_date, 'MM-DD-YYYY'), 'YYYY-MM-DD')
WHERE departure_date ~ '^[0-9]{1,2}-[0-9]{1,2}-[0-9]{4}$';

-- DD-MM-YY e.g. 20-09-24
SELECT booking_id, departure_date,
       TO_CHAR(TO_DATE(departure_date, 'DD-MM-YY'), 'YYYY-MM-DD') AS cleaned_date
FROM bookings_staging
WHERE departure_date ~ '^[0-9]{1,2}-[0-9]{1,2}-[0-9]{2}$';

UPDATE bookings_staging
SET departure_date = TO_CHAR(TO_DATE(departure_date, 'DD-MM-YY'), 'YYYY-MM-DD')
WHERE departure_date ~ '^[0-9]{1,2}-[0-9]{1,2}-[0-9]{2}$';

-------------------------------------------------------
-- 8: seat_class standardisation


SELECT seat_class, COUNT(*) AS records
FROM bookings_staging
GROUP BY seat_class
ORDER BY records DESC;

UPDATE bookings_staging
SET seat_class =
    CASE
        WHEN LOWER(TRIM(seat_class)) IN ('eco', 'economy', 'economy class') THEN 'Economy'
        WHEN LOWER(TRIM(seat_class)) IN ('bus', 'business', 'business class') THEN 'Business'
        ELSE INITCAP(TRIM(seat_class))
    END;


------------------------------------------------------------
--9. payment_method standardisation

SELECT payment_method, COUNT(*) AS records
FROM bookings_staging
GROUP BY payment_method
ORDER BY records DESC;

UPDATE bookings_staging
SET payment_method =
    CASE
        WHEN LOWER(REPLACE(TRIM(payment_method), '-', '')) IN ('mpesa', 'm pesa') THEN 'M-Pesa'
        WHEN LOWER(TRIM(payment_method)) = 'cash' THEN 'Cash'
        WHEN LOWER(TRIM(payment_method)) = 'card' THEN 'Card'
        ELSE INITCAP(TRIM(payment_method))
    END;


------------------------------------------------------------
-- 10: booking_status standardisation

SELECT booking_status, COUNT(*) AS records
FROM bookings_staging
GROUP BY booking_status
ORDER BY records DESC;

UPDATE bookings_staging
SET booking_status =
    CASE
        WHEN LOWER(TRIM(booking_status)) = 'completed' THEN 'Completed'
        WHEN LOWER(TRIM(booking_status)) = 'cancelled' THEN 'Cancelled'
        WHEN LOWER(TRIM(booking_status)) IN ('no show', 'noshow', 'no-show') THEN 'No Show'
        ELSE INITCAP(TRIM(booking_status))
    END;


------------------------------------------------------------
-- 11: fare_per_seat and total_fare
-- Strip KES and other non-numeric characters


SELECT booking_id, fare_per_seat, total_fare,
       REGEXP_REPLACE(fare_per_seat, '[^0-9.]', '', 'g') AS cleaned_fare_per_seat,
       REGEXP_REPLACE(total_fare, '[^0-9.]', '', 'g') AS cleaned_total_fare
FROM bookings_staging
WHERE fare_per_seat ~ '[^0-9.]'
   OR total_fare ~ '[^0-9.]';

UPDATE bookings_staging
SET fare_per_seat = REGEXP_REPLACE(fare_per_seat, '[^0-9.]', '', 'g'),
    total_fare = REGEXP_REPLACE(total_fare, '[^0-9.]', '', 'g')
WHERE fare_per_seat ~ '[^0-9.]'
   OR total_fare ~ '[^0-9.]';


------------------------------------------------------------
-- 12: trip_rating
-- Invalid ratings like 0 or 6 become NULL

SELECT booking_id, trip_rating
FROM bookings_staging
WHERE NULLIF(TRIM(trip_rating), '') IS NOT NULL
  AND (
        trip_rating !~ '^[0-9]+$'
        OR trip_rating::INT NOT BETWEEN 1 AND 5
      );

UPDATE bookings_staging
SET trip_rating = NULL
WHERE NULLIF(TRIM(trip_rating), '') IS NOT NULL
  AND (
        trip_rating !~ '^[0-9]+$'
        OR trip_rating::INT NOT BETWEEN 1 AND 5
      );

SELECT booking_id, trip_rating
FROM bookings_staging
WHERE TRIM(COALESCE(trip_rating, '')) = '';

UPDATE bookings_staging
SET trip_rating = NULL
WHERE TRIM(COALESCE(trip_rating, '')) = '';


------------------------------------------------------------
--13: remove negative or invalid seats_booked

SELECT booking_id, seats_booked
FROM bookings_staging
WHERE seats_booked !~ '^-?[0-9]+$'
   OR seats_booked::INT <= 0;

DELETE FROM bookings_staging
WHERE seats_booked !~ '^-?[0-9]+$'
   OR seats_booked::INT <= 0;


------------------------------------------------------------
--14: remove duplicate booking_id
-- Keeps the first row and deletes later duplicates

SELECT booking_id, COUNT(*) AS duplicate_count
FROM bookings_staging
GROUP BY booking_id
HAVING COUNT(*) > 1;

DELETE FROM bookings_staging
WHERE ctid IN (
    SELECT ctid
    FROM (
        SELECT ctid,
               booking_id,
               ROW_NUMBER() OVER (
                   PARTITION BY booking_id
                   ORDER BY ctid
               ) AS rn
        FROM bookings_staging
    ) duplicates
    WHERE rn > 1
);


------------------------------------------------------------
-- 15: FINAL CHECKS AFTER CLEANING


SELECT COUNT(*) AS cleaned_row_count
FROM bookings_staging;

SELECT passenger_gender, COUNT(*)
FROM bookings_staging
GROUP BY passenger_gender;

SELECT seat_class, COUNT(*)
FROM bookings_staging
GROUP BY seat_class;

SELECT payment_method, COUNT(*)
FROM bookings_staging
GROUP BY payment_method;

SELECT booking_status, COUNT(*)
FROM bookings_staging
GROUP BY booking_status;

SELECT *
FROM bookings_staging
LIMIT 20;





















