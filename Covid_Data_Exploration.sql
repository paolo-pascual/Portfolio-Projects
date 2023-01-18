/***** 
Covid Data Exploration

The following codes explore the Covid situation in different countries.

*****/


-- Checking the imported tables

SELECT *
FROM Portfolio..deaths
ORDER BY location, date

SELECT *
FROM Portfolio..vaccinations
ORDER BY location, date

--Checking fields of interest for subsequent analysis

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Portfolio..deaths
ORDER BY location, date

SELECT location, date, people_vaccinated
FROM Portfolio..vaccinations
ORDER BY location, date


-- Daily Total Death vs Total Cases Per Country

SELECT location
	  ,date
	  ,total_deaths
	  ,total_cases
	  ,ROUND(total_deaths/total_cases, 4) AS DeathToCasesRatio
FROM Portfolio..deaths
WHERE continent IS NOT NULL
ORDER BY DeathToCasesRatio DESC

-- Daily Total Death vs Total Cases In The Philippines

SELECT location
	  ,date
	  ,total_deaths
	  ,total_cases
	  ,ROUND(total_deaths/total_cases, 4) AS DeathToCasesRatio
FROM Portfolio..deaths
WHERE location = 'Philippines' 
ORDER BY location, date

-- Daily Total Cases vs Population Per Country

SELECT location
	  ,date
	  ,total_cases
	  ,population
	  ,ROUND(total_cases/population, 4) AS CaseToPopulationRatio
FROM Portfolio..deaths
WHERE continent IS NOT NULL
ORDER BY location, date

-- Daily Total Cases vs Population In The Philippines

SELECT location
	  ,date
	  ,total_cases
	  ,population
	  ,ROUND(total_cases/population, 4) AS CaseToPopulationRatio
FROM Portfolio..deaths
WHERE location = 'Philippines'
ORDER BY location, date

-- Total of Cases to Population Ratio Per Country

SELECT location
	  ,MAX(total_cases) AS TotalCases
	  ,population
	  ,ROUND(MAX(total_cases/population),4) AS TotalCasesToPopulationRatio
FROM Portfolio..deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY TotalCasesToPopulationRatio DESC

-- Total Number of Deaths to Population Ratio Per Country

SELECT location
      ,MAX(CAST(total_deaths AS int)) AS TotalDeaths
	  ,population
	  ,MAX(ROUND(CAST(total_deaths AS int)/population, 4)) AS DeathToPopulationRatio
FROM Portfolio..deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY DeathToPopulationRatio DESC


-- Global Total Numbers of Deaths vs Total Covid Cases Daily

SELECT date 
	  ,SUM(CAST(new_deaths AS int)) AS GlobalTotalDeaths
      ,SUM(new_cases) AS GlobalNewCases 
	  ,ROUND(SUM(CAST(new_deaths AS int))/SUM(new_cases), 4) AS GlobalTotalDeathsToCasesRatio
FROM Portfolio..deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date


-- Creating a view to add "new_people_vaccinated column" for subsequent analysis since it is not availabe in the given data
-- This can show us the number of new people vaccinated everyday in each country

DROP VIEW IF EXISTS vaccinations_upd
CREATE VIEW vaccinations_upd
AS
SELECT *
      ,CASE WHEN people_vaccinated IS NOT NULL OR people_vaccinated <> 0 THEN
	   people_vaccinated -(CASE WHEN 
	                       MAX(CAST(people_vaccinated AS bigint)) 
						   OVER (PARTITION BY location ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) IS NULL
						   THEN 0
						   ELSE
						   MAX(CAST(people_vaccinated AS bigint)) 
						   OVER (PARTITION BY location ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) 
						   END)
       ELSE NULL END AS new_people_vaccinated
FROM Portfolio..vaccinations

SELECT *
FROM vaccinations_upd

-- Daily Cumulative (Rolling) Number of Vaccinated People Per Country
-- Although this is already given in the people_vaccinated column, I opted to use the new_people_vaccinated column as a challenge

SELECT d.continent 
	  ,d.location 
	  ,d.date 
	  ,d.population 
	  ,v.new_people_vaccinated
	  ,SUM(CAST(v.new_people_vaccinated AS bigint)) 
	       OVER (PARTITION BY d.location ORDER BY d.location, d.date)
		   AS CumulativeVaccPeopleNumber
	  ,v.people_vaccinated
FROM Portfolio..deaths d INNER JOIN vaccinations_upd v
	 ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL 
ORDER BY d.continent, d.location


-- Using CTE To Determine Number of People Vaccinated To Population Ratio Per Country

WITH VaccToPopulation 
	 (Continent, Location, Date, Population, New_Vaccinations, CumulativeVaccPeopleNumber)
AS
(
SELECT d.continent 
	  ,d.location 
	  ,d.date 
	  ,d.population 
	  ,v.new_people_vaccinated
	  ,SUM(CAST(v.new_people_vaccinated AS bigint)) 
	       OVER (PARTITION BY d.location ORDER BY d.location, d.date)
		   AS CumulativeVaccPeopleNumber
FROM Portfolio..deaths d INNER JOIN vaccinations_upd v
	 ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL 
)
SELECT *, CumulativeVaccPeopleNumber/Population AS VaccToPopulationRatio
FROM VaccToPopulation
WHERE CumulativeVaccPeopleNumber/Population <= 1
ORDER BY VaccToPopulationRatio DESC


--Using Temp Table: Another Way To Determine Number of People Vaccinated To Population Ratio Per Country

DROP TABLE IF EXISTS VaccRatio
CREATE TABLE VaccRatio 
(
 Continent nvarchar(255) 
,Location nvarchar(255) 
,Date datetime
,Population bigint 
,New_Vaccinations bigint 
,CumulativeVaccPeopleNumber numeric
)

INSERT INTO VaccRatio
SELECT d.continent 
	  ,d.location 
	  ,d.date 
	  ,d.population 
	  ,v.new_people_vaccinated
	  ,SUM(CAST(v.new_people_vaccinated AS bigint)) 
	       OVER (PARTITION BY d.location ORDER BY d.location, d.date)
		   AS CumulativeVaccPeopleNumber
FROM Portfolio..deaths d INNER JOIN vaccinations_upd v
	 ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL

SELECT *, CumulativeVaccPeopleNumber/Population AS VaccToPopulationRatio
FROM VaccRatio
ORDER BY VaccToPopulationRatio DESC


-- Initial correlation analysis between vaccination and death

WITH CorrVaccandDeath 
(Year, Quarter, NewVacc, NewDeath)
AS
(
SELECT DATEPART(yyyy, d.date)
	  ,CASE WHEN DATEPART(mm, d.date) BETWEEN 1 AND 3 THEN 1
	        WHEN DATEPART(mm, d.date) BETWEEN 4 AND 6 THEN 2
			WHEN DATEPART(mm, d.date) BETWEEN 7 AND 9 THEN 3
			WHEN DATEPART(mm, d.date) BETWEEN 10 AND 12 THEN 4
			ELSE NULL END
	  ,CAST(v.new_vaccinations AS bigint)
	  ,CAST(d.new_deaths AS bigint)
FROM vaccinations_upd v INNER JOIN Portfolio..deaths d
	 ON v.location = d.location AND v.date = d.date
)
SELECT Year, Quarter, AVG(NewVacc) AS AvgNewVacc, AVG(NewDeath) AS AvgNewDeath
FROM CorrVaccandDeath
GROUP BY Year, Quarter
ORDER BY Year, Quarter