

-- Fixing issues with Mac Permissions
SHOW VARIABLES LIKE "secure_file_priv";
SET GLOBAL local_infile= TRue;
SHOW GLOBAL VARIABLES LIKE 'local_infile';


-- Loading Scraped Data CSV into SQL ##

-- Creating Skeleton Table for CSV
Create table rmp_data
(id VARCHAR(150),
professor_name VARCHAR(150),
subject VARCHAR(150),
quality_rating VARCHAR(150),
would_take_again VARCHAR(150),
difficulty VARCHAR(150),
number_of_rating VARCHAR(150));


-- Loading Data into
LOAD DATA INFILE '/Users/brianblockmon/SideProjects/SJ_instructorsfr.csv'
    INTO TABLE rmp_data
    FIELDS TERMINATED BY ','
    ENCLOSED BY ''
    LINES TERMINATED BY '\n'
    IGNORE 1 LINES;


-- DATA MANIPULATION --

SELECT *
FROM RMP_DATA;

-- Splitting the num_of_ratings column to remove 'ratings' string
UPDATE rmp_data
SET rmp_data.number_of_rating = SUBSTRING_INDEX(number_of_rating, ' ', 1);


-- Delete rows with no ratings
DELETE FROM RMP_DATA
WHERE number_of_rating = 0;


-- Turning N/A into null
UPDATE rmp_data
SET    would_take_again = NULL
WHERE  would_take_again = 'N/A';


-- Removing % sign from WTA column
update rmp_data
set would_take_again=replace(would_take_again, '%', "");


-- Changing each column to appropriate datatype
ALTER TABLE rmp_data
  MODIFY COLUMN id int(5),
  MODIFY COLUMN professor_name TINYTEXT,
  MODIFY COLUMN subject TINYTEXT,
  MODIFY COLUMN quality_rating FLOAT(3, 1),
  MODIFY COLUMN difficulty FLOAT(3, 1),
  MODIFY COLUMN number_of_rating int(5);

-- ADD COLUMN to Department
ALTER TABLE rmp_data
ADD COLUMN college TINYTEXT AFTER subject;


-- Actually Changing Table
UPDATE rmp_data
SET college =
CASE
    WHEN (subject LIKE "%business%"
        OR subject LIKE '%finance%'
        OR subject LIKE '%accounting%'
        OR subject LIKE '%International%'
        OR subject LIKE '%mark%'
        OR subject LIKE '%hosp%'
        OR subject LIKE '%manag%')
    THEN 'Business'

    WHEN (subject LIKE "%engineer%"
        OR subject LIKE '%aerospace%'
        OR subject LIKE '%aviation%'
        OR subject LIKE '%tech%')
    THEN 'Engineering'

    WHEN (subject LIKE "%health%"
    OR subject LIKE '%physical%'
    OR subject LIKE '%kin%'
    OR subject LIKE '%recreation%'
    OR subject LIKE '%work%'
    OR subject LIKE '%nurs%'
    OR subject LIKE '%nutri%'
    OR subject LIKE '%Human Development%'
    OR subject LIKE '%occu%')
    THEN 'Health and Human Sciences'

    WHEN (subject LIKE "%education%"
    OR subject LIKE '%child%'
    OR subject LIKE '%disorder%'
    OR subject LIKE 'Languages')
    THEN 'Education'

    WHEN (subject LIKE "%art%"
    OR subject LIKE "%French%"
    OR subject LIKE "%Japan%"
    OR subject LIKE "%Italian%"
    OR subject LIKE "%music%"
    OR subject LIKE "%spanish%"
    OR subject LIKE "%vietnam%"
    OR subject LIKE "%theatre%"
    OR subject LIKE "%german%"
    OR subject LIKE "%portugu%"
    OR subject LIKE "%english%"
    OR subject LIKE "%liberal%"
    OR subject LIKE "%chinese%"
    OR subject LIKE "%philo%"
    OR subject LIKE "%religio%"
    OR subject LIKE "%America%"
    OR subject LIKE "%journa%"
    OR subject LIKE "%thea%"
    OR subject LIKE "%humanities%"
    OR subject LIKE "%radio%"
    OR subject LIKE "%design%"
    OR subject LIKE "%lingui%"
    OR subject LIKE "%Photo%"
    OR subject LIKE "%dance%"
    OR subject LIKE "%writing%"
    OR subject LIKE "%Architecture%"
    )
    THEN 'Humanities and Art'

    WHEN (subject LIKE "%math%"
    OR subject LIKE "%physics%"
    OR subject LIKE "%biology%"
    OR subject LIKE "%chemistry%"
    OR subject LIKE "science"
    OR subject LIKE "decision science"
    OR subject LIKE "%computer science%"
    OR subject LIKE "%meteo%"
    OR subject LIKE "%geolo%"
    OR subject LIKE "%astronomy%")
    THEN 'Science'

    WHEN (subject LIKE "%studies%"
    OR subject LIKE "%history%"
    OR subject LIKE "%soci%"
    OR subject LIKE "%psy%"
    OR subject LIKE "%poli%"
    OR subject LIKE "%communication%"
    OR subject LIKE "%economics%"
    OR subject LIKE "%anthro%"
    OR subject LIKE "Foreign Languages"
    OR subject LIKE "Geography"
    OR subject LIKE "%urban%")
    THEN 'Social Science'

    WHEN (subject LIKE "%lib%")
    THEN 'Professional and Global Education'


END;


-- Seeing which subjects still need a college assigned
-- Going back and altering above query
SELECT subject,
count(subject)
FROM rmp_data
WHERE college IS NULL
GROUP BY(subject)
ORDER BY count(subject)
DESC;

-- Deleting rows that dont fit in a college group
DELETE FROM rmp_data
WHERE college IS NULL;

-- Filling WTA NULLs with Average by College
update rmp_data
inner join (
    select college, avg(would_take_again) as avgWTA
    from rmp_data
    group by college
) b on rmp_data.college = b.college
set would_take_again = b.avgWTA
where would_take_again is null;


-- Making sure no more nulls for WTA
SELECT count(would_take_again)
FROM rmp_data
WHERE would_take_again IS NULL
GROUP BY college;


-- DATA EXPLORATION --

-- Number of Professors By Subject
SELECT subject,
count(subject) FROM rmp_data
GROUP BY subject
ORDER BY count(subject)
DESC;


-- Number of Ratings By Subject
SELECT subject,
SUM(number_of_rating) FROM rmp_data
GROUP BY subject
ORDER BY SUM(number_of_rating)
DESC;


-- Average quality rating by subject with over 25 ratings
SELECT subject,
AVG(quality_rating), sum(number_of_rating)
FROM rmp_data
WHERE number_of_rating < 1
GROUP BY subject
ORDER BY AVG(quality_rating)
DESC;


-- Feature averages by Department
SELECT college,
AVG(quality_rating),
sum(number_of_rating),
AVG(would_take_again),
AVG(difficulty)
FROM rmp_data
GROUP BY college
ORDER BY AVG(quality_rating)
DESC;


-- Professors with highest number of ratings
SELECT professor_name, number_of_rating, college
FROM rmp_data
ORDER BY number_of_rating
DESC;


-- Maximum amount of rating by college
SELECT college, MAX(number_of_rating)
FROM rmp_data
GROUP BY college;

-- Total amount of Ratings by College
SELECT college, SUM(number_of_rating)
FROM rmp_data
GROUP BY college
ORDER BY SUM(number_of_rating);


-- Average "would take again" by college
SELECT college, AVG(would_take_again)
FROM rmp_data
GROUP BY college
ORDER BY AVG(would_take_again);

-- Professors with highest quality ratings and over 15 ratings
-- Tester for what is a "significant" number of ratings
SELECT college, quality_rating, number_of_rating, professor_name
from rmp_data
WHERE number_of_rating > 25
ORDER BY quality_rating
DESC;

-- Creating temp table for the join below
CREATE TABLE max_rating_table AS
SELECT college, MAX(number_of_rating) as number_of_rating
FROM rmp_data
GROUP BY college;


-- Creating table with highest number of rating by college with professor names
-- using join with above temp table
CREATE TABLE max_rate_prof AS
SELECT rmp_data.college, professor_name, rmp_data.number_of_rating
FROM rmp_data
JOIN max_rating_table
ON rmp_data.college = max_rating_table.college
AND rmp_data.number_of_rating = max_rating_table.number_of_rating
ORDER BY number_of_rating
DESC;


-- First draft of table with statistics by college
CREATE TABLE college_stats AS
SELECT college,
AVG(quality_rating) AS avg_qr,
sum(number_of_rating) AS sum_rating,
AVG(would_take_again) AS avg_wta,
AVG(difficulty) AS avg_difficulty
FROM rmp_data
GROUP BY college
ORDER BY AVG(quality_rating)
DESC;


-- Second draft of table with statistics by college
-- (added professors with most ratings by college)
CREATE TABLE college_stats2 AS
SELECT college_stats.college,
avg_qr, sum_rating, avg_wta, avg_difficulty,
professor_name as max_rating_num
FROM college_stats
JOIN max_rate_prof
ON college_stats.college = max_rate_prof.college;


-- Third draft of table with statistics by college
-- (added total amount of ratings by college)
CREATE TABLE college_stats3 AS
SELECT
college_stats2.college,
avg_qr,
avg_wta,
avg_difficulty,
max_rating_num,
total_ratings
FROM college_stats2
JOIN (SELECT college, SUM(number_of_rating) as total_ratings
FROM RMP_DATA
GROUP BY college) b
ON college_stats2.college = b.college;


-- Deleting the duplicate row from table
DELETE FROM college_stats3
WHERE max_rating_num LIKE "%ANT%";


-- Used as tester to observe..
-- ..how much number of ratings impacted the 'highest' quality ratings
SELECT college, MAX(quality_rating) as max_qr
FROM rmp_data
WHERE number_of_rating > 50
GROUP BY college;


-- Table showing professors with highest quality ratings by college
-- Professor must have over 50 ratings to be considered
SELECT rmp_data.college, professor_name, rmp_data.number_of_rating, quality_rating
FROM rmp_data
JOIN (SELECT college, MAX(quality_rating) as max_qr
FROM rmp_data
WHERE number_of_rating > 50
GROUP BY college) b
ON rmp_data.college = b.college
AND rmp_data.quality_rating = b.max_qr
WHERE number_of_rating > 50
ORDER BY college
DESC, number_of_rating;


SELECT * FROM rmp_data;
SELECT * FROM max_rating_table;
SELECT * FROM max_rate_prof;
SELECT * FROM college_stats;
SELECT * FROM college_stats2;
SELECT * FROM college_stats3;
