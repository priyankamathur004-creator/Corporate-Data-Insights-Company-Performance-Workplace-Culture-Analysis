use Companies_db

--Query 1: Find Highly-Rated Young Companies
--Goal: Find companies that are younger than 5 years old and have a perfect rating of 5.0
select company as Younger_company, Age,Rating
from DBO.Company_details
WHERE age <= 5 and Rating = 5
order by Company ASc

--Query 2: Identify Industry Giants (High Review Volume)
---Goal: List the top 10 companies in the 'Banking' or 'Pharma' sectors that have more than 10,000 reviews, sorted from highest to lowest.
select Company,Type,Reviewers from dbo.Company_details
where Type in ('Banking','Pharma')
And Reviewers > 10000
order by Reviewers Desc

--Query 3: Industry Benchmarking Performance
--Goal: Group companies by their industry type to find the total companies, total aggregated reviews, and average rating for each sector.
select  Type,count(*) as Total_Companies, Sum (Reviewers) as Total_Aggregated_Reviews,Round(AVG(Rating),2) as Avg_Rating 
from dbo.Company_details
group by Type
having Count(*) >=10
order by Total_Companies Desc
offset 0 rows fetch next 10 row only

--Query 4: Text Profiling (Workplace Sentiment Analysis)
--Goal: Categorize companies based on what critical flaws are explicitly listed in their Critically_Ratedfor string text

select
     case
         when critically_ratedfor like '%Salary%' then 'Compensation/Pay Issues'
         when critically_ratedfor like '%Benefits%' then 'Burnout/worklife Issues'
         Else 'Other Critique/Balanced Culture'
End as Culture_Critique,
Count(*) as Company_count,
Round (Avg(Rating), 2) as Avg_Rating
from dbo.Company_details
group by
   case
         when critically_ratedfor like '%Salary%' then 'Compensation/Pay Issues'
         when critically_ratedfor like '%Benefits%' then 'Burnout/worklife Issues'
         Else 'Other Critique/Balanced Culture'
         End
order by Company_count desc
select * from dbo.Company_details


---Query 5: Find the Top 3 Highest-Rated Companies Per Industry
--Goal: Rank every single company inside its specific industry sector based on its rating, breaking ties using the number of reviewers, and filtering out everything except the top 3 gold-standard entities per industry.


WITH RankedCompanies AS (
    SELECT
        Company,
        Type AS Industry,
        Rating,
        Reviewers,
        DENSE_RANK() OVER (
            PARTITION BY Type 
            ORDER BY Rating DESC, Reviewers Desc
        ) AS Rank_order
    FROM dbo.Company_details
)
select Company,Industry,Rating,Reviewers,Rank_order
from RankedCompanies
Where Rank_order <= 3
order by Rank_order

--Query 6: Find Underperforming Legacy Establishments
--Goal: Identify old-school "Legacy" companies (older than 30 years) whose ratings fall completely below the global dataset average rating. This uses an embedded Subquery
Select company ,Age,Rating from
dbo.Company_details
where Age > 30 And 
Rating <(Select Avg(Rating) as Avg_Rating from dbo.Company_details)
order by Age

--1. The KPI Summary Card Data (Global Metrics)
--Goal in Power BI: Feed your high-level "KPI Cards" at the top of the dashboard (Total Companies, Avg Rating, Total Reviews across the globe).
select count(Company) as Total_Company,
Round(Avg(Rating),2)as Global_Total_Ratings,
Sum(cast(Reviewers as BigINT)) as Global_Total_Reviewers,
Avg(Age) as Avg_Age
from dbo.Company_details

--2. Industry Performance Table (For Bar Charts / Treemaps)
--Goal in Power BI: Create a Treemap or a Horizontal Bar Chart comparing different industries by their size and 
--reputations
select type as industry,
count(Company) as Company_count,
round(Avg(Rating),2) as Avg_Rating,
Sum(Reviewers) as Total_Reviewers
from dbo.Company_details
where type is not null
group by type
order by Company_count desc

--3Company Age Segments vs. Performance (For Scatter Plots / Line Charts)
--Goal in Power BI: Use this to create a Scatter Plot (X-axis: Age Group, Y-axis: Avg Rating, Bubble Size: Total Reviewers) to see if older companies have better or worse reputations than startups.
select 
     case 
         when Age < 5 Then '0-5 years (Startup)'
         when Age between 5 and 16 Then '5-16 years (Growth)'
         when Age between 16 and 30 then '16-30  years (Established)'
    Else '30+ years (legacy)'
    End as 
    Age_Segment,
count(Company) as Total_Company,
Round(Avg(Rating),2) as Avg_Rating
from dbo.Company_details
Group by   case 
         when Age < 5 Then '0-5 years (Startup)'
         when Age between 5 and 16 Then '5-16 years (Growth)'
         when Age between 16 and 30 then '16-30  years (Established)'
    Else '30+ years (legacy)'
    End 
    Order by Total_Company desc

--5. High-Performer Quadrant (For Matrix Tables / Top N Visuals)
--Goal in Power BI: Power a "Top 10 Leaders" Matrix Table dynamically filtered by industry. It separates elite companies that have high ratings and a massive volume of social proof (reviews).
select Type as Industry,
Company,
Rating,
Reviewers 
from dbo.Company_details
where Rating >= 4.0
And Reviewers >=(select Avg(Reviewers)from dbo.Company_details)




