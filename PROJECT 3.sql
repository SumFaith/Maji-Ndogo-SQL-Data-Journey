USE md_water_services;
DROP TABLE IF EXISTS `auditor_report`;
CREATE TABLE `auditor_report` (
`location_id` VARCHAR(32),
`type_of_water_source` VARCHAR(64),
`true_water_source_score` int DEFAULT NULL,
`statements` VARCHAR(255)
);
SELECT * FROM auditor_report;

-- So first, grab the location_id and true_water_source_score columns from auditor_report
SELECT 
    location_id, true_water_source_score
FROM
    auditor_report;

-- Now, we join the visits table to the auditor_report table. Make sure to grab subjective_quality_score, record_id and location_id
 SELECT
	 a.location_id AS audit_location,
	 a.true_water_source_score,
	 v.location_id AS visit_location,
	 v.record_id
FROM 
	auditor_report a
JOIN
	visits v
ON a.location_id = v.location_id;

-- JOIN the visits table and the water_quality table, using the record_id as the connecting key
SELECT
	 a.location_id AS audit_location,
	 a.true_water_source_score,
	 v.location_id AS visit_location,
	 v.record_id,
     subjective_quality_score
FROM 
	auditor_report a
JOIN
	visits v
ON a.location_id = v.location_id
JOIN
	water_quality wq
ON v.record_id = wq.record_id;

-- Let's leave record_id and rename the scores to surveyor_score and auditor_score to make it clear which scores we're looking at in the results set
SELECT
	 a.location_id AS location_id,
	 v.record_id,
     a.true_water_source_score AS auditor_score,
     wq.subjective_quality_score AS surveyor_score
FROM 
	auditor_report a
JOIN
	visits v
ON a.location_id = v.location_id
JOIN
	water_quality wq
ON v.record_id = wq.record_id;	 

-- A good starting point is to check if the auditor's and exployees' scores agree. There are many ways to do it. We can have aWHERE clause and check if surveyor_score = auditor_score
SELECT 
	 a.location_id AS location_id,
	 v.record_id,
     a.true_water_source_score AS auditor_score,
     wq.subjective_quality_score AS surveyor_score
FROM 
	auditor_report a
JOIN
	visits v
ON a.location_id = v.location_id
JOIN
	water_quality wq
ON v.record_id = wq.record_id
WHERE a.true_water_source_score = wq.subjective_quality_score; 

-- Some of the locations were visited multiple times, so these records are duplicated here. To fix it, we set visits.visit_count= 1 in the WHERE clause. Make sure you reference the alias you used for visits in the join.
SELECT 
	 a.location_id AS location_id,
	 v.record_id,
     a.true_water_source_score AS auditor_score,
     wq.subjective_quality_score AS surveyor_score
FROM 
	auditor_report a
JOIN
	visits v
ON a.location_id = v.location_id
JOIN
	water_quality wq
ON v.record_id = wq.record_id
WHERE v.visit_count = 1 AND 
a.true_water_source_score = wq.subjective_quality_score; 

-- With the duplicates removed I now get 1518. What does this mean considering the auditor visited 1620 sites?
SELECT 
	 a.location_id AS location_id,
	 v.record_id,
     a.true_water_source_score AS auditor_score,
     wq.subjective_quality_score AS surveyor_score
FROM 
	auditor_report a
JOIN
	visits v
ON a.location_id = v.location_id
JOIN
	water_quality wq
ON v.record_id = wq.record_id
WHERE v.visit_count = 1 AND 
a.true_water_source_score != wq.subjective_quality_score;

-- So, to do this, we need to grab the type_of_water_source column from the water_source table and call it survey_source, using thesource_id column to JOIN. Also select the type_of_water_source from the auditor_report table, and call it auditor_source.
SELECT 
	a.location_id AS location_id,
    a.type_of_water_source AS auditor_source,
    ws.type_of_water_source AS surveyor_source,
    v.record_id,
    a.true_water_source_score AS auditor_score,
    wq.subjective_quality_score AS surveyor_score
FROM 
	auditor_report a
JOIN
	visits v
ON a.location_id = v.location_id
JOIN
	water_quality wq
ON v.record_id = wq.record_id
JOIN
	water_source ws
ON ws.source_id = v.source_id
WHERE v.visit_count = 1 AND 
a.true_water_source_score != wq.subjective_quality_score;

-- Once you're done, remove the columns and JOIN statement for water_sources again.
SELECT 
	a.location_id AS location_id,
    a.type_of_water_source AS auditor_source,
    v.record_id,
    a.true_water_source_score AS auditor_score,
    wq.subjective_quality_score AS surveyor_score
FROM 
	auditor_report a
JOIN
	visits v
ON a.location_id = v.location_id
JOIN
	water_quality wq
ON v.record_id = wq.record_id
WHERE v.visit_count = 1 AND 
a.true_water_source_score != wq.subjective_quality_score;

-- JOIN the assigned_employee_id for all the people on our list from the visits table to our query. Remember, our query shows the shows the 102 incorrect records, so when we join the employee data, we can see whichemployees made these incorrect records
SELECT 
	a.location_id AS location_id,
    v.record_id,
    v.assigned_employee_id,
    a.true_water_source_score AS auditor_score,
    wq.subjective_quality_score AS surveyor_score
FROM 
	auditor_report a
JOIN
	visits v
ON a.location_id = v.location_id
JOIN
	water_quality wq
ON v.record_id = wq.record_id
WHERE v.visit_count = 1 AND 
a.true_water_source_score != wq.subjective_quality_score;

-- So now we can link the incorrect records to the employees who recorded them. The ID's don't help us to identify them. We have employees' names stored along with their IDs, so let's fetch their names from the employees table instead of the ID's.
SELECT 
	a.location_id AS location_id,
    v.record_id,
    e.employee_name,
    a.true_water_source_score AS auditor_score,
    wq.subjective_quality_score AS surveyor_score
FROM 
	auditor_report a
JOIN
	visits v
ON a.location_id = v.location_id
JOIN
	water_quality wq
ON v.record_id = wq.record_id
JOIN 
	employee e
ON v.assigned_employee_id = e.assigned_employee_id
WHERE v.visit_count = 1 AND 
a.true_water_source_score != wq.subjective_quality_score;

-- Well this query is massive and complex, so maybe it is a good idea to save this as a CTE, so when we do more analysis, we can just call that CTE like it was a table
WITH Incorrect_records AS (
 SELECT 
	a.location_id AS location_id,
    v.record_id,
    e.employee_name,
    a.true_water_source_score AS auditor_score,
    wq.subjective_quality_score AS surveyor_score
FROM 
	auditor_report a
JOIN
	visits v
ON a.location_id = v.location_id
JOIN
	water_quality wq
ON v.record_id = wq.record_id
JOIN 
	employee e
ON v.assigned_employee_id = e.assigned_employee_id
WHERE v.visit_count = 1 AND 
a.true_water_source_score != wq.subjective_quality_score
)
SELECT * 
FROM Incorrect_records;

-- Let's first get a unique list of employees from this table
WITH Incorrect_records AS (
 SELECT 
	a.location_id AS location_id,
    v.record_id,
    e.employee_name,
    a.true_water_source_score AS auditor_score,
    wq.subjective_quality_score AS surveyor_score
FROM 
	auditor_report a
JOIN
	visits v
ON a.location_id = v.location_id
JOIN
	water_quality wq
ON v.record_id = wq.record_id
JOIN 
	employee e
ON v.assigned_employee_id = e.assigned_employee_id
WHERE v.visit_count = 1 AND 
a.true_water_source_score != wq.subjective_quality_score
)
SELECT DISTINCT 
	employee_name
FROM Incorrect_records;

-- Next, let's try to calculate how many mistakes each employee made
WITH Incorrect_records AS (
 SELECT 
	a.location_id AS location_id,
    v.record_id,
    e.employee_name,
    a.true_water_source_score AS auditor_score,
    wq.subjective_quality_score AS surveyor_score
FROM 
	auditor_report a
JOIN
	visits v
ON a.location_id = v.location_id
JOIN
	water_quality wq
ON v.record_id = wq.record_id
JOIN 
	employee e
ON v.assigned_employee_id = e.assigned_employee_id
WHERE v.visit_count = 1 AND 
a.true_water_source_score != wq.subjective_quality_score
)
SELECT DISTINCT employee_name,
COUNT(employee_name) AS number_of_mistakes
FROM Incorrect_records
GROUP BY employee_name; 

-- So let's try to find all of the employees who have an above-average number of mistakes.
WITH Incorrect_records AS (
    SELECT  
        a.location_id AS location_id,
        v.record_id,
        e.employee_name,
        a.true_water_source_score AS auditor_score,
        wq.subjective_quality_score AS surveyor_score
    FROM   
        auditor_report a
    JOIN  
        visits v ON a.location_id = v.location_id
    JOIN  
        water_quality wq ON v.record_id = wq.record_id
    JOIN   
        employee e ON v.assigned_employee_id = e.assigned_employee_id
    WHERE 
        v.visit_count = 1 
        AND a.true_water_source_score != wq.subjective_quality_score 
),
error_count AS (
    SELECT
        employee_name,
        COUNT(*) AS number_of_mistakes
    FROM
        Incorrect_records
    GROUP BY
        employee_name
)
SELECT 
    *
FROM 
    error_count;

-- average number of mistakes employees made.
WITH Incorrect_records AS (
    SELECT  
        a.location_id AS location_id,
        v.record_id,
        e.employee_name,
        a.true_water_source_score AS auditor_score,
        wq.subjective_quality_score AS surveyor_score
    FROM   
        auditor_report a
    JOIN  
        visits v ON a.location_id = v.location_id
    JOIN  
        water_quality wq ON v.record_id = wq.record_id
    JOIN   
        employee e ON v.assigned_employee_id = e.assigned_employee_id
    WHERE 
        v.visit_count = 1 
        AND a.true_water_source_score != wq.subjective_quality_score 
),
error_count AS (
    SELECT
        employee_name,
        COUNT(*) AS number_of_mistakes
    FROM
        Incorrect_records
    GROUP BY
        employee_name
)
SELECT 
    AVG(number_of_mistakes) AS avg_error_per_empl
FROM 
    error_count;

-- compare each employee's error_count with avg_error_count_per_empl
WITH error_count AS(
	SELECT DISTINCT employee_name,
COUNT(employee_name) AS number_of_mistakes
FROM(
SELECT
	a.location_id AS location_id,
        v.record_id,
        e.employee_name,
        a.true_water_source_score AS auditor_score,
        wq.subjective_quality_score AS surveyor_score
    FROM   
        auditor_report a
    JOIN  
        visits v ON a.location_id = v.location_id
    JOIN  
        water_quality wq ON v.record_id = wq.record_id
    JOIN   
        employee e ON v.assigned_employee_id = e.assigned_employee_id
    WHERE 
        v.visit_count = 1 
        AND a.true_water_source_score != wq.subjective_quality_score 
        ) AS Incorrect_records
	GROUP BY employee_name
    )
SELECT 
	employee_name,
    number_of_mistakes
FROM error_count
WHERE number_of_mistakes > (SELECT AVG(number_of_mistakes) AS avg_error_count_per_empl
FROM error_count);

--  convert the query error_count, we made earlier, into a CTE
WITH error_count AS ( -- This CTE calculates the number of mistakes each employee made
SELECT
employee_name,
COUNT(employee_name) AS number_of_mistakes
FROM
Incorrect_records
GROUP BY
employee_name)
-- Query
SELECT * FROM error_count;

-- Convert suspect name to CTE
WITH error_count AS (
    SELECT
        e.employee_name,
        COUNT(*) AS number_of_mistakes
    FROM
        auditor_report a
    JOIN
        visits v ON a.location_id = v.location_id
    JOIN
        water_quality wq ON v.record_id = wq.record_id
    JOIN
        employee e ON v.assigned_employee_id = e.assigned_employee_id
    WHERE
        v.visit_count = 1 
        AND a.true_water_source_score != wq.subjective_quality_score
    GROUP BY
        e.employee_name
),
suspect_list AS (
    SELECT 
        employee_name,
        number_of_mistakes
    FROM 
        error_count
    WHERE 
        number_of_mistakes > (
            SELECT 
                AVG(number_of_mistakes) 
            FROM 
                error_count
        )
)
SELECT * 
FROM suspect_list;

-- Now we can filter that Incorrect_records view to identify all of the records associated with the four employees we identified
WITH error_count AS (
    SELECT
        e.employee_name,
        COUNT(*) AS number_of_mistakes
    FROM
        auditor_report a
    JOIN
        visits v ON a.location_id = v.location_id
    JOIN
        water_quality wq ON v.record_id = wq.record_id
    JOIN
        employee e ON v.assigned_employee_id = e.assigned_employee_id
    WHERE
        v.visit_count = 1 
        AND a.true_water_source_score != wq.subjective_quality_score
    GROUP BY
        e.employee_name
),
suspect_list AS (
    SELECT 
        employee_name,
        number_of_mistakes
    FROM 
        error_count
    WHERE 
        number_of_mistakes > (
            SELECT 
                AVG(number_of_mistakes) 
            FROM 
                error_count
        )
)
SELECT 
	employee_name, location_id, statements
FROM Incorrect_records
WHERE employee_name IN (SELECT employee_name FROM suspect_list);

-- Filter the records that refer to "cash"

WITH suspect_list AS (
SELECT
	employee_name,
    number_of_mistakes
FROM error_count
WHERE number_of_mistakes > (SELECT AVG (number_of_mistakes) AS avg_error_count_per_empl FROM error_count
))
SELECT employee_name, location_id, statements
FROM Incorrect_records
WHERE employee_name IN (SELECT employee_name FROM suspect_list)
AND statements LIKE "%cash%";

-- Check if there are any employees in the Incorrect_records table with statements mentioning "cash" that are not in our suspect list.
SELECT * 
FROM Incorrect_records 
WHERE statements LIKE "%cash&";

suspect_list AS (
    SELECT ec1.employee_name, ec1.number_of_mistakes
    FROM error_count ec1
    WHERE ec1.number_of_mistakes >= (
        SELECT AVG(ec2.number_of_mistakes)
        FROM error_count ec2
        WHERE ec2.employee_name = ec1.employee_name));
        
        
WITH AverageMistakes AS (
    SELECT AVG(number_of_mistakes) AS avg_mistakes
    FROM error_count
),
SuspectList AS (
    SELECT employee_name, number_of_mistakes
    FROM error_count
    WHERE number_of_mistakes < (SELECT avg_mistakes FROM AverageMistakes)
)
SELECT *
FROM SuspectList
ORDER BY number_of_mistakes DESC
LIMIT 1;  -- This will give you the employee with the highest number of mistakes below the average.






