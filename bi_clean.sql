-- Duplicating the table
create table bi_clean like bi;
insert into bi_clean
select * from bi;

select distinct gender from bi_clean;

-- updating gender column to maintain consistency
update bi_clean
set gender = 
	case 
    when gender = "M" then "Male"
    when gender="F" then "Female"
	end
where gender="M" or gender = "F"
;

-- Updating country column
select distinct country from bi_clean;

update bi_clean
set country = "Norway"
where country="Norge";

update bi_clean
set country = "South Africa"
where country="Rsa";

update bi_clean
set country = "United Kingdom"
where country="UK";

select * from bi_clean;

-- checking for duplicates
with dup_ctes as (
select *,
row_number() over(partition by first_name, last_name, Age, gender, country, residence, entry_exam,previous_education,study_hours, Python, DB) as row_num
from bi_clean
)
select * from dup_ctes
where row_num > 1;

-- Cleaning the Previous Education column
select distinct previous_education from bi_clean;

update bi_clean
set previous_education = "High School"
where previous_education like "High%";

update bi_clean
set previous_education = "Diploma"
where previous_education like "Dip%";

update bi_clean
set previous_education = "Bachelors"
where previous_education like "Ba%";

update bi_clean
set residence = "BI Residence"
where residence = "BI-Residence" or residence = "BIResidence" or residence="BI_Residence";

select nullif(Python,"") as Python from bi_clean;
update bi_clean
set Python = null
where Python="";

-- Converting text to Int data type
alter table bi_clean
modify column Python int;

describe bi_clean;

-- Calculating mean,median,mode for column Python
select * from bi_clean;
with stastical_ctes as
(
select Avg(Python) as Mean_value from bi_clean),
mode_value as (
select Python as Mode_value from bi_clean
where Python is not null
group by Python
order by count(*) desc
limit 1),
median_value as (
select avg(Python) as Median_value 
from (
	select Python,
		row_number()over(order by Python) as row_num,
        count(*) over () as total_count
	from bi_clean
	where Python is not null
) sub
where row_num in (floor((total_count+1)/2), ceil((total_count+1)/2)))
select * from stastical_ctes, median_value, mode_value;

-- Filling the blank Null values with Median which is 81
-- As It’s robust to outliers.
-- It represents the central tendency of data.
-- With only 2 blanks, filling those with 81 won’t distort the distribution.

update bi_clean
set Python = 81
where Python is Null;

-- EDA --
-- 1. Program Effectiveness Based On Previous Education
select previous_education,
	avg(Python) as Avg_Python_Score,
    avg(DB) as Avg_DB_Score,
    count(*) as Student_count
from bi_clean
group by previous_education
order by Avg_Python_Score desc;

-- Students with a High School background show the lowest overall average score, 
-- driven down by a particularly low average DB score (61.4), 
-- indicating a specific knowledge gap in this domain compared to other groups.


-- 2.Scores based on Residence
select residence,
	avg(Python) as Avg_Python_Score,
    avg(DB) as Avg_DB_Score,
    count(*) as Student_count
from bi_clean
group by residence
order by Avg_Python_Score desc;

-- The performance differences between residence types are relatively minor,
-- suggesting that high-cost residence (like BI Residence) is not necessarily a guarantee of superior performance compared to others.

-- 3. Correlation Analysis
with avg_score_cte as 
(
	select entry_exam,study_hours, Python, DB, (Python+DB)/2 as Avg_scores from bi_clean
)
SELECT
    (AVG(entry_exam * Avg_scores) - AVG(entry_exam) * AVG(Avg_scores)) /
    (STDDEV(entry_exam) * STDDEV(Avg_scores)) AS Entry_Exam_Correlation,

    (AVG(study_hours * Avg_scores) - AVG(study_hours) * AVG(Avg_scores)) /
    (STDDEV(study_hours) * STDDEV(Avg_scores)) AS Study_Hours_Correlation
FROM avg_score_cte;

-- The high correlation of entry exam scores and study hours with the final average score
-- is critical for defining admission criteria and program engagement metrics.
