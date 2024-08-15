/*
CREATE DATABASE ev_db;
USE ev_db;

CREATE TABLE cleaned_ev_data (
    VIN VARCHAR(20),
    County VARCHAR(50),
    City VARCHAR(50),
    State VARCHAR(5),
    Postal_Code INT,
    Model_Year INT,
    Make VARCHAR(50),
    Model VARCHAR(50),
    Electric_Vehicle_Type VARCHAR(50),
    CAFV_Eligibility VARCHAR(100),
    Electric_Range INT,
    Base_MSRP DOUBLE,
    Legislative_District FLOAT,
    DOL_Vehicle_ID INT,
    Vehicle_Location VARCHAR(100),
    Electric_Utility VARCHAR(100),
    Census_Tract VARCHAR(50)
);


SHOW TABLES;

*/

-- Vehicle Registrations by County and City
SELECT County,City ,COUNT(*) AS VehicleCount
FROM cleaned_ev_data
GROUP BY County, City
ORDER BY VehicleCount DESC;


SELECT * FROM ev_db.cleaned_ev_data LIMIT 100;



-- Which vehicle makes and models have the most registrations in the dataset, and how many registrations do they have?
SELECT Make, Model, COUNT(*) AS RegistrationCount
FROM cleaned_ev_data
GROUP BY Make, Model
ORDER BY RegistrationCount DESC
LIMIT 10;


SELECT DOL_VEHICLE_ID , COUNT(*) AS COUNTING 
FROM cleaned_ev_data 
GROUP BY DOL_VEHICLE_ID
HAVING COUNT(*) > 1;

SELECT VIN , COUNT(*) AS COUNTING 
FROM cleaned_ev_data 
GROUP BY VIN
HAVING COUNT(*) > 1 
ORDER BY COUNTING DESC;

DESCRIBE cleaned_ev_data;


/*
-- updating DOL_Vehicle_ID as a primary key 
ALTER TABLE cleaned_ev_data
ADD PRIMARY KEY (DOL_Vehicle_ID);
*/

SELECT DISTINCT Make 
FROM cleaned_ev_data ;

-- Total Makes: Box Format
SELECT COUNT(*) AS TotalMakes
FROM (
  SELECT DISTINCT Make
  FROM cleaned_ev_data
) AS UniqueMakes;


-- Identify the top 5 cities with the highest average Base MSRP for electric vehicles
SELECT City, AVG(Base_MSRP) AS Avg_MSRP
FROM cleaned_ev_data
GROUP BY City
ORDER BY Avg_MSRP DESC
LIMIT 5;



-- the Most Common Electric Vehicle Models by Electric Range
SELECT Model, Make ,Electric_Range, COUNT(*) AS ModelCount
FROM cleaned_ev_data
GROUP BY Model, Make ,Electric_Range
ORDER BY Electric_Range DESC
LIMIT 10;



-- Determine the Top 5 Cities with the Largest Increase in Registrations from the 2023_model 
SELECT City, Model_Year, RegistrationCount, 
       RegistrationCount - LAG(RegistrationCount, 1, 0) OVER (PARTITION BY City ORDER BY Model_Year) AS Increase
FROM (
    SELECT City, Model_Year, COUNT(*) AS RegistrationCount
    FROM cleaned_ev_data
    GROUP BY City, Model_Year
) AS YearlyRegistrations
ORDER BY Increase DESC
LIMIT 5;



-- get the highest electric range for each make, showing only the top entry per make with its DOL_Vehicle_ID, Make, and Model
WITH RankedVehicles AS (
    SELECT 
        DOL_Vehicle_ID,
        Make,
        Model,
        Electric_Range,
        ROW_NUMBER() OVER (PARTITION BY Make ORDER BY Electric_Range DESC) AS rn
    FROM 
        cleaned_ev_data
)
SELECT 
    DOL_Vehicle_ID,
    Make,
    Model,
    Electric_Range
FROM 
    RankedVehicles
WHERE 
    rn = 1
ORDER BY 
    Electric_Range DESC;

    
-- Count how many Tesla models have an electric range of 337
SELECT 
    Make,
    Electric_Range,
    COUNT(*) AS NumberOfModels
FROM 
    cleaned_ev_data
WHERE 
    Make = 'Tesla' AND
    Electric_Range = 337
GROUP BY 
    Make, Electric_Range;
    

-- START  
-- First, find the highest electric range for each make and count how many models have this range
WITH HighestRangePerMake AS (
    SELECT 
        Make,
        MAX(Electric_Range) AS MaxRange
    FROM 
        cleaned_ev_data
    GROUP BY 
        Make
),
-- Rank vehicles within each make based on electric range and count the number of models with the maximum range
RankedVehicles AS (
    SELECT 
        d.DOL_Vehicle_ID,
        d.Make,
        d.Model,
        d.Electric_Range,
        r.MaxRange,
        ROW_NUMBER() OVER (PARTITION BY d.Make ORDER BY d.Electric_Range DESC) AS rn,
        COUNT(*) OVER (PARTITION BY d.Make, d.Electric_Range) AS CountAtMaxRange
    FROM 
        cleaned_ev_data d
    JOIN 
        HighestRangePerMake r
    ON 
        d.Make = r.Make AND d.Electric_Range = r.MaxRange
)
-- Select the top entry per make with the highest electric range and count of models having the same range
SELECT 
    DOL_Vehicle_ID,
    Make,
    Model,
    Electric_Range,
    CountAtMaxRange
FROM 
    RankedVehicles
WHERE 
    rn = 1
ORDER BY 
    Electric_Range DESC;
-- END



-- Find the most common electric vehicle type in each city with a count greater than 50
WITH VehicleTypeCounts AS (
    SELECT 
        City,
        Electric_Vehicle_Type,
        COUNT(*) AS TypeCount
    FROM 
        cleaned_ev_data
    GROUP BY 
        City, Electric_Vehicle_Type
),
RankedTypes AS (
    SELECT
        City,
        Electric_Vehicle_Type,
        TypeCount,
        ROW_NUMBER() OVER (PARTITION BY City ORDER BY TypeCount DESC) AS rn
    FROM 
        VehicleTypeCounts
)
SELECT
    City,
    Electric_Vehicle_Type,
    TypeCount
FROM
    RankedTypes
WHERE
    rn = 1
    AND TypeCount > 50  -- Filter to show only cities where the most common type count is greater than 50
ORDER BY
   TypeCount Desc;


SELECT * FROM cleaned_ev_data ;

-- electric vehicle types by total count
SELECT 
    Electric_Vehicle_Type,
    COUNT(*) AS VehicleCount
FROM 
    cleaned_ev_data
GROUP BY 
    Electric_Vehicle_Type
ORDER BY 
    VehicleCount DESC;


-- FOR VISUALIZATION 

-- 1
-- What is the trend of new electric vehicle registrations over the model_years?  : Line Graph Time series
SELECT Model_Year, COUNT(*) AS RegistrationCount
FROM cleaned_ev_data
WHERE Model_Year BETWEEN 2013 AND 2023
GROUP BY Model_Year
ORDER BY Model_Year DESC;


-- 2
-- c :  pie chart 
SELECT 
    Electric_Vehicle_Type,
    COUNT(*) AS VehicleCount
FROM 
    cleaned_ev_data
GROUP BY 
    Electric_Vehicle_Type
ORDER BY 
    VehicleCount DESC;
    
    
    
 
-- 3
-- City-Level Analysis of Electric Vehicle Registrations and Features : Tree MAP 
SELECT 
    City,
    COUNT(*) AS TotalRegistrations,
    AVG(Base_MSRP) AS AvgMSRP,
    AVG(Electric_Range) AS AvgElectricRange,
    COUNT(DISTINCT Make) AS NumberOfMakes,
    SUM(CASE WHEN Model_Year = 2023 THEN 1 ELSE 0 END) AS RecentRegistrations
FROM 
    cleaned_ev_data
WHERE 
    City IS NOT NULL
GROUP BY 
    City
HAVING 
    TotalRegistrations > 2500 -- more than 2500 total registrations
ORDER BY 
    TotalRegistrations DESC;

SELECT * FROM cleaned_ev_data ;

-- 4 box format
-- Count the total number of vehicle registrations
-- Calculate the total Base MSRP for all vehicles
SELECT
  (SELECT COUNT(*) FROM cleaned_ev_data) AS TotalVehicleRegistrations,
  (SELECT SUM(Base_MSRP) FROM cleaned_ev_data) AS TotalBaseMSRP;



-- 5
-- Analysis of Top Electric Vehicle Models by AvgMSRP  horizontal bar chart 
WITH top_models AS (
    SELECT Model
    FROM cleaned_ev_data
    WHERE Base_MSRP > 0
    GROUP BY Model
    ORDER BY COUNT(*) DESC
    LIMIT 10
)
SELECT m.Make, m.Model, AVG(m.Base_MSRP) AS AvgMSRP, AVG(m.Electric_Range) AS AvgRange
FROM cleaned_ev_data m
JOIN top_models ON m.Model = top_models.Model
WHERE m.Base_MSRP > 0
GROUP BY m.Make, m.Model
ORDER BY AvgMSRP DESC;

-- 6 
-- Which electric utility companies serve the most vehicles, and how many vehicles do they serve? Bar chart
SELECT Electric_Utility, COUNT(*) AS VehicleCount
FROM cleaned_ev_data
GROUP BY Electric_Utility
ORDER BY VehicleCount DESC
LIMIT 3;

