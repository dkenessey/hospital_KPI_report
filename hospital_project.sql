-- Creating payers table
CREATE TABLE payers (
    Id VARCHAR(255) PRIMARY KEY NOT NULL,  		-- Primary key of the payer
    Name VARCHAR(100) NOT NULL,  					-- Name of the payer
    Address VARCHAR(255),  							-- Payer's street address
    City VARCHAR(100),  							-- Payer's city
    State_Headquartered CHAR(2), 					-- State abbreviation
    Zip VARCHAR(10),  								-- Street address zip or postal code
    Phone VARCHAR(15));								-- Phone number of payer

SELECT * FROM payers;



--Creating patients table
CREATE TABLE patients (
    Id VARCHAR(255) PRIMARY KEY NOT NULL,              -- Unique Identifier of the patient
    BirthDate DATE,               						-- The date the patient was born
    DeathDate DATE,                        			-- The date the patient died (nullable)
    Prefix VARCHAR(10),                    			-- Name prefix, such as Mr., Mrs., Dr.
    First VARCHAR(50) NOT NULL,           				-- First name of the patient
    Last VARCHAR(50) NOT NULL,            				-- Last name of the patient
    Suffix VARCHAR(10),                    			-- Name suffix, such as PhD, MD, JD (nullable)
    Maiden VARCHAR(50),                    			-- Maiden name of the patient (nullable)
    Marital VARCHAR(50),								-- Marital Status (M=married, S=single)
    Race VARCHAR(100),                     			-- Description of the patient's race
	    Ethnicity VARCHAR(100),                 		-- Description of the patient's ethnicity
    Gender VARCHAR(50),  								-- Gender (M=male, F=female)
    BirthPlace VARCHAR(500),                			-- Town where the patient was born
    Address VARCHAR(500),			         			-- Patient's street address
    City VARCHAR(100),           						-- Patient's address city
    State CHAR(50),			                 			-- Patient's address state (2 letter abbreviation)
    County VARCHAR(100),                     			-- Patient's address county
    Zip VARCHAR(20),			              			-- Patient's zip code
    Lat DECIMAL(9, 6),                        			-- Latitude of patient's address
    Lon DECIMAL(9, 6));									-- Longitude of patient's address

SELECT * FROM patients;



--Creating organizations table
CREATE TABLE organizations (
    Id VARCHAR(255) PRIMARY KEY NOT NULL,               -- Primary key of the organization
    Name VARCHAR(255) NOT NULL,              			 -- Name of the organization
    Address VARCHAR(255) NOT NULL,           			 -- Organization's street address
    City VARCHAR(100) NOT NULL,              			 -- Street address city
    State CHAR(2) NOT NULL,                  			 -- Street address state abbreviation (2 letter)
    Zip VARCHAR(10) NOT NULL,                			 -- Street address zip or postal code
    Lat DECIMAL(9, 6),                       			 -- Latitude of organization's address
    Lon DECIMAL(9, 6));									 -- Longitude of organization's address

SELECT * FROM organizations;



--Creating encounters table
CREATE TABLE encounters (
    Id VARCHAR(255) PRIMARY KEY, 					  	-- Unique Identifier of the encounter
    Start TIMESTAMPTZ NOT NULL,   						-- The date and time the encounter started
    Stop TIMESTAMPTZ,             						-- The date and time the encounter concluded
    Patient VARCHAR(255) REFERENCES patients(Id) ON DELETE CASCADE,  -- Foreign key to the patient
    Organization VARCHAR(255) REFERENCES organizations(Id) ON DELETE CASCADE,  -- Foreign key to the organization
    Payer VARCHAR(255) REFERENCES payers(Id) ON DELETE CASCADE,  -- Foreign key to the payer
    EncounterClass VARCHAR(50) NOT NULL,  				-- The class of the encounter
    Code VARCHAR(50) NOT NULL,            				-- Encounter code from SNOMED-CT
    Description TEXT NOT NULL,            				-- Description of the type of encounter
    Base_Encounter_Cost NUMERIC(10, 2) NOT NULL,  		-- The base cost of the encounter
    Total_Claim_Cost NUMERIC(10, 2) NOT NULL,     		-- The total cost of the encounter
    Payer_Coverage NUMERIC(10, 2) NOT NULL,       		-- The amount of cost covered by the payer
    ReasonCode VARCHAR(50),                       		-- Diagnosis code from SNOMED-CT
    ReasonDescription TEXT);							-- Encounter reason description

SELECT * FROM encounters;



--Creating procedures table
CREATE TABLE procedures (
    Start TIMESTAMPTZ NOT NULL,            			-- Start time of the procedure should be required
    Stop TIMESTAMPTZ,                       			-- Stop time can be nullable
    Patient VARCHAR(255) REFERENCES patients(Id) ON DELETE CASCADE,  -- Foreign key to patient
    Encounter VARCHAR(255) REFERENCES encounters(Id) ON DELETE CASCADE,  -- Foreign key to encounter
    Code VARCHAR(50),              					-- Procedure code
    Description TEXT,              					-- Procedure description
    Base_Cost NUMERIC(10, 2),      					-- Cost of the procedure
    ReasonCode VARCHAR(50),         					-- Diagnosis code
    ReasonDescription TEXT);							-- Procedure reason description

SELECT * FROM procedures
ORDER BY patient, encounter;



--Adding age column to patients table
ALTER TABLE patients
ADD COLUMN age INT;

UPDATE patients
SET age = 
	CASE 
		WHEN deathdate IS NULL THEN EXTRACT(YEAR FROM AGE('2022-01-29'::DATE, birthdate))
        ELSE EXTRACT(YEAR FROM AGE(deathdate, birthdate))
    END;

SELECT age FROM patients;



-- Removing numerics from names in patients table
UPDATE patients
SET first = LEFT(first, LENGTH(first) - 3);

UPDATE patients
SET last = LEFT(last, LENGTH(last) - 3);

UPDATE patients
SET maiden = LEFT(maiden, LENGTH(maiden) - 3);

SELECT first, last, maiden FROM patients;



-- Changing 'ethnicity' column levels
ALTER TABLE patients
RENAME COLUMN ethnicity TO hispanic;

UPDATE patients
SET hispanic = 
	CASE
		WHEN hispanic = 'hispanic' THEN 'yes'
        ELSE 'no'
    END;

SELECT hispanic FROM patients;



-- Changing capitalization in organization table
UPDATE organizations
SET name = INITCAP(LOWER(name));

UPDATE organizations
SET address = INITCAP(LOWER(address));

UPDATE organizations
SET city = INITCAP(LOWER(city));

SELECT * FROM organizations;



--Changing gender to sex
ALTER TABLE patients
RENAME COLUMN gender TO sex;

SELECT sex FROM patients;



--Adding deathdate to encounters table
ALTER TABLE encounters
ADD COLUMN deathdate DATE;

UPDATE encounters e
SET deathdate = pat.deathdate
FROM patients pat
WHERE e.patient = pat.id;

SELECT deathdate FROM encounters;



-- Checking for duplicates in patients table
SELECT 
	id, 
	COUNT(id) AS count
FROM patients
GROUP BY id
HAVING COUNT(*) > 1;



--Checking for duplicates in encounters table
SELECT 
	id, 
	COUNT(id) AS count
FROM encounters
GROUP BY id
HAVING COUNT(*) > 1;



--Checking for duplicates in payers table
SELECT 
	id, 
	COUNT(id) AS count
FROM payers
GROUP BY id
HAVING COUNT(*) > 1;



--Checking for duplicates in procedures table
SELECT 
	encounter, 
	start, 
	stop, 
	code, 
	COUNT(*) AS count
FROM procedures
GROUP BY 
	encounter, 
	start, 
	stop, 
	code
HAVING COUNT(*) > 1;



--Total number of patient visits
SELECT 
	COUNT(*) 
FROM encounters;



--Total number of patient visits by sex
SELECT
	pat.sex,
	COUNT(*) as total_visits
FROM patients pat
INNER JOIN encounters e
	ON pat.id = e.patient
GROUP BY pat.sex;



--Total number of patient visits by race
SELECT
	pat.race,
	COUNT(*) as total_visits
FROM patients pat
INNER JOIN encounters e
	ON pat.id = e.patient
GROUP BY pat.race
ORDER BY total_visits DESC;



--Total number of patient visits by ethnicity
SELECT
	pat.hispanic,
	COUNT(*) as total_visits
FROM patients pat
INNER JOIN encounters e
	ON pat.id = e.patient
GROUP BY pat.hispanic;



--Total number of admissions
SELECT 
	COUNT(*) AS total_admissions
FROM encounters
WHERE encounterclass = 'inpatient';



--Total number of admissions by sex
SELECT 
	pat.sex,
	COUNT(*) AS total_admissions
FROM encounters e
INNER JOIN patients pat
	ON e.patient = pat.id
WHERE e.encounterclass = 'inpatient'
GROUP BY pat.sex;



--Total number of admissions by race
SELECT 
	pat.race,
	COUNT(*) AS total_admissions
FROM encounters e
INNER JOIN patients pat
	ON e.patient = pat.id
WHERE e.encounterclass = 'inpatient'
GROUP BY pat.race
ORDER BY total_admissions DESC;



--Total number of admissions by ethnicity
SELECT 
	pat.hispanic,
	COUNT(*) AS total_admissions
FROM encounters e
INNER JOIN patients pat
	ON e.patient = pat.id
WHERE e.encounterclass = 'inpatient'
GROUP BY pat.hispanic
ORDER BY total_admissions DESC;



--Average length of stay
SELECT 
	CONCAT(
	   EXTRACT(HOUR FROM AVG(stop - start)), ' hour(s), ',
	   EXTRACT(MINUTE FROM AVG(stop - start)), ' minute(s), ',
	   ROUND(EXTRACT(SECOND FROM AVG(stop - start)),0), ' second(s)'
	   ) AS average_length_of_stay
FROM encounters;



--Average length of stay among the admitted
SELECT 
	CONCAT(
		EXTRACT(DAY FROM AVG(stop - start)), ' day(s), ',
   		EXTRACT(HOUR FROM AVG(stop - start)), ' hour(s), ',
   		EXTRACT(MINUTE FROM AVG(stop - start)), ' minute(s), ',
   		ROUND(EXTRACT(SECOND FROM AVG(stop - start)),0), ' second(s)'
   ) AS average_length_of_stay
FROM encounters
WHERE encounterclass = 'inpatient';



--Length of stay by encounter code
SELECT 
	reasoncode, 
	COUNT(*) AS total_encounters,
  	CONCAT(
    	EXTRACT(YEAR FROM AGE(stop, start)), ' year(s), ',
    	EXTRACT(MONTH FROM AGE(stop, start)), ' month(s), ',
    	EXTRACT(DAY FROM AGE(stop, start)), ' day(s), ',
    	EXTRACT(HOUR FROM (stop - start)), ' hour(s), ',
    	EXTRACT(MINUTE FROM (stop - start)), ' minute(s)'
 	 ) AS length_of_stay
FROM encounters
WHERE reasoncode IS NOT NULL
GROUP BY 
	reasoncode, 
	length_of_stay
ORDER BY length_of_stay DESC;



--Top 3 insurers with the highest number of patient visits
SELECT 
	pay.name AS insurance, 
	COUNT(*) AS number_of_visits
FROM payers AS pay
INNER JOIN encounters AS e 
	ON pay.id = e.payer
GROUP BY pay.name
ORDER BY number_of_visits DESC;



--Top 3 counties with the highest number of patients visits
SELECT 
	pat.county AS county, 
	COUNT(*) AS number_of_visits
FROM patients AS pat
INNER JOIN encounters AS e 
	ON pat.id = e.patient
GROUP BY pat.county
ORDER BY number_of_visits DESC;



--Most common visit types
SELECT 
	encounterclass AS encounter_type,
	COUNT(*) AS number_of_visits
FROM encounters
GROUP BY encounter_type
ORDER BY number_of_visits DESC;



--Number of patient visits by year
SELECT 
    CAST(EXTRACT(YEAR FROM start) AS INTEGER) AS year, 
	COUNT(*) AS total_encounters
FROM encounters
GROUP BY year 
ORDER BY year;



--Top 5 most common encounter types
SELECT 
	reasoncode, 
	COUNT(*) AS number_of_visits
FROM encounters
WHERE reasoncode IS NOT NULL
GROUP BY reasoncode
ORDER BY number_of_visits DESC
LIMIT 5;



--Top 3 most common diagnoses by sex
WITH ranked_visits AS (
	SELECT 
    	sex, 
    	reasoncode, 
    	COUNT(*) AS number_of_visits,
    	ROW_NUMBER() OVER (PARTITION BY sex ORDER BY COUNT(*) DESC) AS rn
  	FROM encounters e
  	INNER JOIN patients pat 
		ON e.patient = pat.id
 	WHERE reasoncode IS NOT NULL
  	GROUP BY 
	  	sex, 
		reasoncode)
SELECT 
	sex, 
	reasoncode, 
	number_of_visits
FROM ranked_visits
WHERE rn <= 3
ORDER BY 
	sex, 
	number_of_visits DESC;



--Top 3 most common diagnoses by race
WITH ranked_visits AS (
	SELECT 
    	race, 
    	reasoncode, 
    	COUNT(*) AS number_of_visits,
    	ROW_NUMBER() OVER (PARTITION BY race ORDER BY COUNT(*) DESC) AS rn
  	FROM encounters e
  	INNER JOIN patients pat 
		ON e.patient = pat.id
 	WHERE reasoncode IS NOT NULL
  	GROUP BY 
	  	race, 
		reasoncode)
SELECT 
	race, 
	reasoncode, 
	number_of_visits
FROM ranked_visits
WHERE rn <= 3
ORDER BY 
	race, 
	number_of_visits DESC;



--Top 3 most common diagnoses by race
WITH ranked_visits AS (
	SELECT 
    	hispanic, 
    	reasoncode, 
    	COUNT(*) AS number_of_visits,
    	ROW_NUMBER() OVER (PARTITION BY hispanic ORDER BY COUNT(*) DESC) AS rn
  	FROM encounters e
  	INNER JOIN patients pat 
		ON e.patient = pat.id
 	WHERE reasoncode IS NOT NULL
  	GROUP BY 
	  	hispanic, 
		reasoncode)
SELECT 
	hispanic, 
	reasoncode, 
	number_of_visits
FROM ranked_visits
WHERE rn <= 3
ORDER BY 
	hispanic, 
	number_of_visits DESC;



--Patient Death Rate
SELECT 
	ROUND((COUNT(deathdate) * 100.0 / COUNT(*)),2) AS deceased_percent 
FROM patients;



--Death Rate among admitted patients
SELECT 
	ROUND((COUNT(deathdate) * 100.0 / COUNT(*)),2) AS deceased_percent 
FROM encounters
WHERE encounterclass = 'inpatient';



--Death rate by patient sex
SELECT 
	sex, 
	ROUND((COUNT(deathdate) * 100.0 / COUNT(*)),2) AS deceased_percent 
FROM patients
GROUP BY sex;



--Patient Death Rate by race
SELECT 
	race,
	ROUND((COUNT(deathdate) * 100.0 / COUNT(*)),2) AS deceased_percent 
FROM patients
GROUP BY race
ORDER BY deceased_percent DESC;



--Patient Death Rate by ethnicity
SELECT 
	hispanic,
	ROUND((COUNT(deathdate) * 100.0 / COUNT(*)),2) AS deceased_percent 
FROM patients
GROUP BY hispanic
ORDER BY deceased_percent DESC;



--Decedent sex distribution
WITH total_deceased AS (
	SELECT COUNT(*) AS total_deceased_count
  	FROM patients
  	WHERE deathdate IS NOT NULL),
sex_deceased AS (
	SELECT sex, COUNT(*) AS sex_deceased_count
  	FROM patients
  	WHERE deathdate IS NOT NULL
 	GROUP BY sex)
SELECT 
	sd.sex,
  	ROUND((sd.sex_deceased_count::numeric / td.total_deceased_count::numeric * 100), 2) AS proportion
FROM 
  	sex_deceased sd, 
  	total_deceased td;



--Decedent race distribution
WITH total_deceased AS (
	SELECT COUNT(*) AS total_deceased_count
  	FROM patients
  	WHERE deathdate IS NOT NULL),
race_deceased AS (
	SELECT race, COUNT(*) AS race_deceased_count
  	FROM patients
  	WHERE deathdate IS NOT NULL
 	GROUP BY race)
SELECT 
	rd.race,
  	ROUND((rd.race_deceased_count::numeric / td.total_deceased_count::numeric * 100), 2) AS proportion
FROM 
  	race_deceased rd, 
  	total_deceased td
ORDER BY proportion DESC;



--Death rate by visit type
SELECT 
	encounterclass, 
	ROUND((COUNT(deathdate) * 100.0 / COUNT(*)),2) AS deceased_percent, 
	COUNT(*)
FROM patients AS pat
INNER JOIN encounters AS e 
	ON pat.id = e.patient
GROUP BY encounterclass
ORDER BY deceased_percent DESC;



--Death rate by diagnosis 
SELECT 
	reasoncode, 
	ROUND((COUNT(deathdate) * 100.0 / COUNT(*)),2) AS deceased_percent, 
	COUNT(*)
FROM patients AS pat
INNER JOIN encounters AS e 
	ON pat.id = e.patient
GROUP BY reasoncode
ORDER BY deceased_percent DESC;



--Average procedure length
SELECT 
	CONCAT(
		EXTRACT(DAY FROM AVG(stop - start)), ' day(s), ',
   		EXTRACT(HOUR FROM AVG(stop - start)), ' hour(s), ',
   		EXTRACT(MINUTE FROM AVG(stop - start)), ' minute(s), ',
   		ROUND(EXTRACT(SECOND FROM AVG(stop - start)),0), ' second(s)'
   	) AS average_procedure_length
FROM procedures;



--Average procedure length by sex
SELECT 
	sex,
  	CONCAT(
    	EXTRACT(DAY FROM AVG(stop - start))::text, ' day(s), ',
    	EXTRACT(HOUR FROM AVG(stop - start))::text, ' hour(s), ',
    	EXTRACT(MINUTE FROM AVG(stop - start))::text, ' minute(s), ',
    	ROUND(EXTRACT(SECOND FROM AVG(stop - start)),0)::text, ' second(s)'
  	) AS average_procedure_length
FROM procedures pro
INNER JOIN patients pat
	ON pro.patient = pat.id
GROUP BY sex
ORDER BY average_procedure_length DESC;



--Average procedure length by year
SELECT 
  	EXTRACT(YEAR FROM start) AS year,
  	CONCAT(
   		EXTRACT(DAY FROM AVG(stop - start))::text, ' day(s), ',
    	EXTRACT(HOUR FROM AVG(stop - start))::text, ' hour(s), ',
    	EXTRACT(MINUTE FROM AVG(stop - start))::text, ' minute(s), ',
    	ROUND(EXTRACT(SECOND FROM AVG(stop - start)),0)::text, ' second(s)'
  	) AS average_procedure_length
FROM procedures
GROUP BY EXTRACT(YEAR FROM start)
ORDER BY year;



--Average procedure length by visit type
SELECT 
	encounterclass,
  	CONCAT(
    	EXTRACT(DAY FROM AVG(pro.stop - pro.start))::text, ' day(s), ',
   		 EXTRACT(HOUR FROM AVG(pro.stop - pro.start))::text, ' hour(s), ',
    	EXTRACT(MINUTE FROM AVG(pro.stop - pro.start))::text, ' minute(s), ',
    	ROUND(EXTRACT(SECOND FROM AVG(pro.stop - pro.start)),0)::text, ' second(s)'
  	) AS average_procedure_length
FROM procedures pro
INNER JOIN encounters e
	ON pro.encounter = e.id
GROUP BY encounterclass
ORDER BY average_procedure_length DESC;



--Average procedure length by procedure type
SELECT 
	code,
	CONCAT(
  		EXTRACT(DAY FROM AVG(stop - start)), ' day(s), ',
   		EXTRACT(HOUR FROM AVG(stop - start)), ' hour(s), ',
   		EXTRACT(MINUTE FROM AVG(stop - start)), ' minute(s), ',
   		ROUND(EXTRACT(SECOND FROM AVG(stop - start)),0), ' second(s)'
   	) AS average_procedure_length,
	COUNT(*)
FROM procedures
GROUP BY code
ORDER BY average_procedure_length DESC;



--Average procedure length by diagnosis
SELECT 
	reasoncode,
	CONCAT(
   		EXTRACT(DAY FROM AVG(stop - start)), ' day(s), ',
   		EXTRACT(HOUR FROM AVG(stop - start)), ' hour(s), ',
   		EXTRACT(MINUTE FROM AVG(stop - start)), ' minute(s), ',
   		ROUND(EXTRACT(SECOND FROM AVG(stop - start)),0), ' second(s)'
   	) AS average_procedure_length,
	COUNT(*)
FROM procedures
GROUP BY reasoncode
ORDER BY average_procedure_length DESC;










--readmissions version1
WITH OrderedEncounters AS (
	SELECT
		patient,
        id,
		reasoncode,
        start,
        stop,
		ROW_NUMBER() OVER(PARTITION BY patient ORDER  BY patient, start, id) AS rn
    FROM encounters 
    WHERE encounterclass = 'inpatient')
SELECT 
	oe1.patient,
    oe1.id,
	oe1.reasoncode,
    oe1.start,
  	oe1.stop,
	oe2.id AS next_visit,
	oe2.start AS next_visit_start,
	oe2.stop AS next_visit_stop,
	oe2.reasoncode AS next_visit_reason,
	EXTRACT(DAY FROM (oe2.start - oe1.stop)) AS day_gap
FROM OrderedEncounters oe1
LEFT JOIN OrderedEncounters oe2
	ON oe1.rn + 1 = oe2.rn
WHERE oe1.patient = oe2.patient
	AND EXTRACT(DAY FROM (oe2.start - oe1.stop)) <= 31
	AND EXTRACT(DAY FROM (oe2.start - oe1.stop)) <> 0
ORDER BY oe1.patient, oe1.start;


--Create readmission table
CREATE TABLE readmissions AS
WITH OrderedEncounters AS (
	SELECT
		e.patient,
        e.id,
		pat.deathdate,
		e.reasoncode,
        e.start,
        e.stop,
        LAG(stop) OVER (PARTITION BY patient ORDER BY patient, start, e.id) AS prev_stop,
        LEAD(start) OVER (PARTITION BY patient ORDER BY patient, start, e.id) AS next_start
    FROM encounters e
	INNER JOIN patients pat
		ON e.patient = pat.id
    WHERE encounterclass = 'inpatient')
SELECT 
	patient,
    id,
	deathdate,
	reasoncode,
    start,
  	stop,
    prev_stop,
    next_start
FROM OrderedEncounters
WHERE 
	prev_stop IS NOT NULL 
	AND start BETWEEN prev_stop + INTERVAL '5 days' AND prev_stop + INTERVAL '31 days'
	AND prev_stop < start;

SELECT * FROM readmissions



--Total readmissions
SELECT 
	COUNT(*) AS readmission_count
FROM readmissions;



--Total readmissions by sex
SELECT 
	pat.sex,
	COUNT(DISTINCT r.patient) AS readmission_count
FROM readmissions r
INNER JOIN patients pat
	ON r.patient = pat.id
GROUP BY pat.sex;



--Total readmissions by race
SELECT 
	pat.race,
	COUNT(DISTINCT r.patient) AS readmission_count
FROM readmissions r
INNER JOIN patients pat
	ON r.patient = pat.id
GROUP BY pat.race
ORDER BY readmission_count DESC;



--Total readmissions by ethnicity
SELECT 
	pat.hispanic,
	COUNT(DISTINCT r.patient) AS readmission_count
FROM readmissions r
INNER JOIN patients pat
	ON r.patient = pat.id
GROUP BY pat.hispanic
ORDER BY readmission_count DESC;


	
--Proportion of deceased of all readmissions
WITH readmitted_deceased AS(
	SELECT patient
	FROM readmissions
	WHERE deathdate IS NOT NULL),
total_readmissions AS(
	SELECT patient
	FROM readmissions)
SELECT 
	ROUND((COUNT(DISTINCT rd.patient)::numeric / COUNT(DISTINCT tr.patient)*100),2) AS deceased_percent
FROM readmitted_deceased rd, total_readmissions tr; 



--Readmission rates by sex
WITH sex_readmissions AS (
  	SELECT 
		pat.sex, 
		COUNT(DISTINCT r.patient) AS readmission_count
  	FROM readmissions r
  	INNER JOIN patients pat 
	  	ON pat.id = r.patient
  	GROUP BY pat.sex),
total_readmissions AS (
  	SELECT 
	  	COUNT(DISTINCT r.patient) AS total_readmission_count
  	FROM readmissions r)
SELECT 
	sr.sex,
 	ROUND((sr.readmission_count::numeric / tr.total_readmission_count * 100),2) AS readmission_rate
FROM 
  	sex_readmissions sr, 
  	total_readmissions tr;



--Readmissions by age and sex
SELECT 
	age, 
	sex, 
	COUNT(*) AS readmission_count
FROM readmissions r
INNER JOIN patients AS pat 
	ON r.patient = pat.id
GROUP BY 
	age, 
	sex
ORDER BY readmission_count DESC;



--Readmissions by county of residence 
SELECT 
	pat.county, 
	COUNT(*) AS readmission_count
FROM readmissions r
INNER JOIN patients pat 
	ON r.patient = pat.id
GROUP BY pat.county
ORDER BY readmission_count DESC;



--Readmissions by year
SELECT 
	CAST(EXTRACT(YEAR FROM r.start) AS INTEGER) AS year, 
	COUNT(*) AS readmission_count
FROM readmissions r
GROUP BY year
ORDER BY year;



--Readmissions by insurance
SELECT 
	name, 
	COUNT(DISTINCT r.patient) AS readmission_count
FROM payers pay 
INNER JOIN encounters e 
	ON pay.id = e.payer
INNER JOIN readmissions r 
	ON e.patient = r.patient
GROUP BY name
ORDER BY readmission_count DESC;



--Top 3 most common diagnoses among the readmitted
SELECT 
	reasoncode,
	COUNT(DISTINCT patient) AS readmission_count
FROM readmissions
WHERE reasoncode IS NOT NULL
GROUP BY reasoncode
ORDER BY readmission_count DESC;



--Top 3 most common diagnoses among the readmitted by sex
WITH readmitted_visits AS (
	SELECT 
		pat.sex, 
		e.reasoncode, 
		r.patient
  	FROM readmissions r
  	INNER JOIN encounters e 
	  	ON r.patient = e.patient
  	INNER JOIN patients pat 
	  	ON e.patient = pat.id),
ranked_reasoncodes AS (
  	SELECT 
    	rv.sex, 
    	rv.reasoncode, 
    	COUNT(DISTINCT rv.patient) AS number_of_visits,
    	ROW_NUMBER() OVER (PARTITION BY rv.sex ORDER BY COUNT(*) DESC) AS rn
  	FROM readmitted_visits rv
  	WHERE rv.reasoncode IS NOT NULL
  	GROUP BY rv.sex, rv.reasoncode)
SELECT 
	sex, 
	reasoncode, 
	number_of_visits
FROM ranked_reasoncodes
WHERE rn <= 3
ORDER BY 
	sex, 
	number_of_visits DESC;










--Total visit costs
SELECT 
    ROUND(SUM(total_claim_cost::numeric),2) AS total_claim_cost,
	COUNT(*) AS total_encounters
FROM encounters;



--Total base costs
SELECT 
    ROUND(SUM(base_encounter_cost::numeric),2) AS total_encounter_basecost,
	COUNT(*) AS total_encounters
FROM encounters;



--Total costs covered by insurance
SELECT 
    ROUND(SUM(payer_coverage::numeric),2) AS total_paid_by_insurance,
	COUNT(*) AS total_encounters
FROM encounters;



--Average total cost per visit 
SELECT 
    ROUND(AVG(total_claim_cost::numeric),2) AS avg_total_claim_cost,
	COUNT(*) AS total_encounters
FROM encounters;



--Average total cost per visit by sex
SELECT 
    pat.sex,
	ROUND(AVG(total_claim_cost::numeric),2) AS avg_total_claim_cost,
	COUNT(*) AS total_encounters
FROM encounters e
INNER JOIN patients pat
	ON e.patient = pat.id
GROUP BY pat.sex;



--Average total cost per visit by race
SELECT 
    pat.race,
	ROUND(AVG(total_claim_cost::numeric),2) AS avg_total_claim_cost,
	COUNT(*) AS total_encounters
FROM encounters e
INNER JOIN patients pat
	ON e.patient = pat.id
GROUP BY pat.race
ORDER BY avg_total_claim_cost DESC;



--Average total cost per visit by ethnicity
SELECT 
    pat.hispanic,
	ROUND(AVG(total_claim_cost::numeric),2) AS avg_total_claim_cost,
	COUNT(*) AS total_encounters
FROM encounters e
INNER JOIN patients pat
	ON e.patient = pat.id
GROUP BY pat.hispanic
ORDER BY avg_total_claim_cost DESC;



--Average base cost per visit 
SELECT 
    ROUND(AVG(base_encounter_cost::numeric),2) AS avg_base_cost,
	COUNT(*) AS total_encounters
FROM encounters;



--Average base cost per visit by sex
SELECT 
	pat.sex,
    ROUND(AVG(base_encounter_cost::numeric),2) AS avg_base_cost,
	COUNT(*) AS total_encounters
FROM encounters e
INNER JOIN patients pat
	ON e.patient = pat.id
GROUP BY pat.sex;



--Average base cost per visit by race
SELECT 
	pat.race,
    ROUND(AVG(base_encounter_cost::numeric),2) AS avg_base_cost,
	COUNT(*) AS total_encounters
FROM encounters e
INNER JOIN patients pat
	ON e.patient = pat.id
GROUP BY pat.race
ORDER BY avg_base_cost DESC;



--Average base cost per visit by ethnicity
SELECT 
	pat.hispanic,
    ROUND(AVG(base_encounter_cost::numeric),2) AS avg_base_cost,
	COUNT(*) AS total_encounters
FROM encounters e
INNER JOIN patients pat
	ON e.patient = pat.id
GROUP BY pat.hispanic
ORDER BY avg_base_cost DESC;



--Average cost covered by insurance per visit 
SELECT 
    ROUND(AVG(payer_coverage::numeric),2) AS avg_payer_coverage,
	COUNT(*) AS total_encounters
FROM encounters;



--Average cost covered by insurance per visit by sex
SELECT 
	pat.sex,
    ROUND(AVG(payer_coverage::numeric),2) AS avg_payer_coverage,
	COUNT(*) AS total_encounters
FROM encounters e
INNER JOIN patients pat
	ON e.patient = pat.id
GROUP BY pat.sex;



--Average cost covered by insurance per visit by race
SELECT 
	pat.race,
    ROUND(AVG(payer_coverage::numeric),2) AS avg_payer_coverage,
	COUNT(*) AS total_encounters
FROM encounters e
INNER JOIN patients pat
	ON e.patient = pat.id
GROUP BY pat.race
ORDER BY avg_payer_coverage DESC;



--Average base cost, total claim cost, and payer coverage per encounter by year
SELECT 
    CAST(EXTRACT(YEAR FROM start) AS INTEGER) AS year, 
    ROUND(AVG(base_encounter_cost::numeric),2) AS avg_base_cost,
    ROUND(AVG(total_claim_cost::numeric),2) AS avg_total_claim_cost,
    ROUND(AVG(payer_coverage::numeric),2) AS avg_payer_coverage,
	COUNT(*) AS total_encounters
FROM encounters
GROUP BY year 
ORDER BY year;  



--Average cost covered by insurance
SELECT 
	ROUND(AVG(payer_coverage::numeric/total_claim_cost::numeric) * 100,2) as avg_percent_covered
FROM encounters
WHERE total_claim_cost > 0;



--Average cost covered by insurance by sex
SELECT 
	pat.sex,
	ROUND(AVG(payer_coverage::numeric/total_claim_cost::numeric) * 100,2) as avg_percent_covered
FROM encounters e
INNER JOIN patients pat
	ON e.patient = pat.id
WHERE total_claim_cost > 0
GROUP BY pat.sex;



--Average cost covered by insurance by race
SELECT 
	pat.race,
	ROUND(AVG(payer_coverage::numeric/total_claim_cost::numeric) * 100,2) as avg_percent_covered,
	COUNT(*)
FROM encounters e
INNER JOIN patients pat
	ON e.patient = pat.id
WHERE total_claim_cost > 0
GROUP BY pat.race
ORDER BY avg_percent_covered DESC;



--Average visit costs by insurer
SELECT 
	pay.name,
 	ROUND(AVG(base_encounter_cost::numeric),2) AS avg_base_cost,
    ROUND(AVG(total_claim_cost::numeric),2) AS avg_total_claim_cost,
    ROUND(AVG(payer_coverage::numeric),2) AS avg_payer_coverage,
	COUNT(*) AS total_encounters
FROM encounters AS e
INNER JOIN payers AS pay 
	ON e.payer = pay.id
GROUP BY pay.name;



--Averge costs by visit type
SELECT encounterclass,
    ROUND(AVG(base_encounter_cost::numeric),2) AS avg_base_cost,
    ROUND(AVG(total_claim_cost::numeric),2) AS avg_total_claim_cost,
    ROUND(AVG(payer_coverage::numeric),2) AS avg_payer_coverage,
	COUNT(*) AS total_encounters
FROM encounters
GROUP BY encounterclass;



--Average costs by diagnosis
SELECT reasoncode,
    ROUND(AVG(base_encounter_cost::numeric),2) AS avg_base_cost,
	COUNT(*) AS total_encounters
FROM encounters
GROUP BY reasoncode
ORDER BY avg_base_cost DESC; 

SELECT reasoncode,
    ROUND(AVG(total_claim_cost::numeric),2) AS avg_total_claim_cost,
    COUNT(*) AS total_encounters
FROM encounters
GROUP BY reasoncode
ORDER BY avg_total_claim_cost DESC; 

SELECT reasoncode,
    ROUND(AVG(payer_coverage::numeric),2) AS avg_payer_coverage,
	COUNT(*) AS total_encounters
FROM encounters
GROUP BY reasoncode
ORDER BY avg_payer_coverage DESC; 



--Average proportion of costs covered by insurer
SELECT name,
	ROUND(AVG(payer_coverage::numeric/total_claim_cost::numeric) * 100,2) as avg_percent_covered,
	COUNT(*)
FROM encounters AS e
INNER JOIN payers AS pay 
	ON e.payer = pay.id
WHERE total_claim_cost > 0
GROUP BY name
ORDER BY avg_percent_covered DESC;



--Average proportion of costs covered by visit type
SELECT 
	encounterclass,
	ROUND(AVG(payer_coverage::numeric/total_claim_cost::numeric) * 100,2) AS avg_percent_covered,
	COUNT(*)
FROM encounters
WHERE total_claim_cost > 0
GROUP BY encounterclass
ORDER BY avg_percent_covered DESC;



--Average proportion of costs covered by diagnosis
SELECT reasoncode,
	ROUND(AVG(payer_coverage::numeric/total_claim_cost::numeric) * 100,2) as avg_percent_covered,
	COUNT(*) 
FROM encounters
WHERE total_claim_cost > 0
	AND reasoncode IS NOT NULL
GROUP BY reasoncode
ORDER BY avg_percent_covered DESC;



--Total procedure costs
SELECT 
    ROUND(SUM(base_cost::numeric),2) AS procedure_base_cost,
	COUNT(*) AS total_procedures
FROM procedures;



--Average cost per procedure 
SELECT 
    ROUND(AVG(base_cost::numeric),2) AS avg_cost,
	COUNT(*) AS total_procedures
FROM procedures;



--Average procedure cost by sex
SELECT 
	sex, 
	ROUND(AVG(base_cost::numeric),2) AS average_procedure_cost
FROM procedures pro
INNER JOIN patients pat
	ON pro.patient = pat.id
GROUP BY sex
ORDER BY average_procedure_cost DESC;



--Average procedure cost by race
SELECT 
	race, 
	ROUND(AVG(base_cost::numeric),2) AS average_procedure_cost
FROM procedures pro
INNER JOIN patients pat
	ON pro.patient = pat.id
GROUP BY race
ORDER BY average_procedure_cost DESC;



--Average procedure cost by year
SELECT 
  	EXTRACT(YEAR FROM start) AS year,
  	ROUND(AVG(base_cost::numeric),2) AS average_procedure_cost
FROM procedures
GROUP BY year
ORDER BY year;



--Average procedure cost by visit type
SELECT 
  	encounterclass,
  	ROUND(AVG(base_cost::numeric),2) AS average_procedure_cost
FROM procedures pro
INNER JOIN encounters e
	ON pro.encounter = e.id
GROUP BY encounterclass
ORDER BY average_procedure_cost DESC;



--Average procedure cost by procedure type
SELECT code,
	ROUND(AVG(base_cost::numeric),2) AS average_procedure_cost,
	COUNT(*)
FROM procedures
GROUP BY code
ORDER BY average_procedure_cost DESC;



--Average procedure cost by diagnosis
SELECT 
	reasoncode,
	ROUND(AVG(base_cost::numeric),2) AS average_procedure_cost,
	COUNT(*)
FROM procedures
GROUP BY reasoncode
ORDER BY average_procedure_cost DESC;