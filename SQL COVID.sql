
-- PART 1 - COVID DEATHS
SELECT *
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4;

ALTER TABLE CovidDeaths ALTER COLUMN total_deaths FLOAT;
ALTER TABLE CovidDeaths ALTER COLUMN new_deaths FLOAT;
ALTER TABLE CovidDeaths ALTER COLUMN hosp_patients FLOAT;
ALTER TABLE CovidDeaths ALTER COLUMN icu_patients FLOAT;

-------------------------------------------------------------------------------------
-- PART 1.1 - COUNTRIES

SELECT location, 
       date, 
	   total_cases, 
	   new_cases, 
	   total_deaths, 
	   population
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;

-- Total Cases vs Total Deaths
SELECT location, 
       date, 
	   total_cases, 
	   total_deaths, 
	   population, 
	   (total_deaths/total_cases)*100 AS death_percentage
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;

SELECT location, 
       date, 
	   total_cases, 
	   total_deaths, 
	   population, 
	   (total_deaths/total_cases)*100 AS death_percentage
FROM CovidProject..CovidDeaths
WHERE location = 'United States'
ORDER BY 1, 2;

SELECT location, 
       date, 
	   total_cases, 
	   total_deaths, 
	   population, 
	   (total_deaths/total_cases)*100 AS death_percentage
FROM CovidProject..CovidDeaths
WHERE location = 'Brazil'
ORDER BY 1, 2;

-- Total Cases vs Population
SELECT location, 
       date, 
	   population, 
	   total_cases, 
	   (total_cases/population)*100 AS pct_population_infected
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;

SELECT location, 
       date, 
	   population, 
	   total_cases, 
	   (total_cases/population)*100 AS pct_population_infected
FROM CovidProject..CovidDeaths
WHERE location like '%states%'
ORDER BY 1, 2;

-- Countries with the Highest Infection Rate
SELECT location, 
       population, 
	   MAX(total_cases) AS highest_infection_count, 
	   MAX((total_cases/population)*100) AS pct_population_infected
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY pct_population_infected DESC;

-- Countries with the Highest Death Count
SELECT location, 
       MAX(total_deaths) AS total_death_count
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC;

-- Countries with Highest Hospitalized Patients
SELECT location, 
       MAX(hosp_patients) AS total_hosp_count
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_hosp_count DESC;

-- COVID Reproduction Rate by Country
SELECT location, 
       MAX(reproduction_rate) AS highest_reproduction_rate
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY highest_reproduction_rate DESC;

-- Total Hospitalized Patients by Country
SELECT location, 
       SUM(hosp_patients)
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY SUM(hosp_patients) DESC;

-- Hospitalized Patients vs Total Cases by Country
SELECT location, 
	   SUM(hosp_patients) AS total_hosp_patients, 
	   SUM(total_cases) AS total_cases, 
	   (SUM(hosp_patients)/SUM(total_cases))*100 AS pct_cases_hosp
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY pct_cases_hosp DESC;

-- Pct Hospitalized Patients vs ICU Patients by Country
SELECT location, 
	   SUM(hosp_patients) AS total_hosp_patients,  
	   SUM(icu_patients) AS icu_patients,
	   (SUM(icu_patients)/SUM(hosp_patients))*100 AS pct_icu_cases
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY pct_icu_cases DESC;

-------------------------------------------------------------------------------------
-- PART 1.2 - CONTINENTS

-- Continents with Highest Infection Rate
SELECT location, 
       population, 
	   MAX(total_cases) AS highest_infection_count
FROM CovidProject..CovidDeaths
WHERE continent IS NULL
	AND location NOT LIKE '%income%'
	AND location NOT IN ('International', 'World', 'European Union')
GROUP BY location, population;

-- Continents with Highest Death Count
SELECT location, 
       MAX(total_deaths) AS total_death_count
FROM CovidProject..CovidDeaths
WHERE continent IS NULL
	AND location NOT LIKE '%income%'
	AND location NOT IN ('International', 'World', 'European Union')
GROUP BY location
ORDER BY total_death_count;

-------------------------------------------------------------------------------------
-- PART 1.3 - GLOBAL

SELECT date, 
       location, 
	   population, 
	   total_cases, 
	   new_cases, 
	   total_deaths, 
	   new_deaths
FROM CovidProject..CovidDeaths
WHERE location = 'World'
ORDER BY 1;

-- New Deaths Compared to New Cases by Day
SELECT date, 
       new_cases, 
	   new_deaths,
	   (new_deaths/NULLIF(new_cases,0))*100 AS death_percentage
FROM CovidProject..CovidDeaths
WHERE location = 'World'
ORDER BY 1;

-- Total Cases by Day
SELECT date, 
       total_cases, 
	   total_deaths,
	   (total_deaths/total_cases)*100 AS death_percentage
FROM CovidProject..CovidDeaths
WHERE location = 'World'
ORDER BY 1;

-------------------------------------------------------------------------------------
-- PART 2 - JOIN TABLES

SELECT * 
FROM CovidProject..CovidVaccinations
ORDER BY 3, 4;

SELECT *
FROM CovidProject..CovidDeaths deaths
JOIN CovidProject..CovidVaccinations vaccination
	ON deaths.location = vaccination.location
	AND deaths.date = vaccination.date
WHERE  deaths.continent IS NOT NULL
ORDER BY 2, 3;

-- Total Population vs Vaccination
SELECT deaths.location, 
       deaths.date, 
	   deaths.population, 
	   vaccination.total_vaccinations
FROM CovidProject..CovidDeaths deaths
JOIN CovidProject..CovidVaccinations vaccination
	ON deaths.location = vaccination.location
	AND deaths.date = vaccination.date
WHERE  deaths.continent IS NOT NULL
ORDER BY 1, 2;

-- Rolling Count Total Population vs Vaccination
SELECT deaths.continent,
	   deaths.location, 
	   deaths.date, 
	   deaths.population, 
	   vaccination.new_vaccinations,
	   SUM(CONVERT(BIGINT, vaccination.new_vaccinations))
		   OVER (PARTITION BY deaths.location 
			   ORDER BY deaths.location, deaths.date) AS rolling_vaccination
FROM CovidProject..CovidDeaths deaths
JOIN CovidProject..CovidVaccinations vaccination
	ON deaths.location = vaccination.location
	AND deaths.date = vaccination.date
WHERE  deaths.continent IS NOT NULL
ORDER BY 2, 3;

-- CTE
WITH PopVsVac (continent, location, date, population, new_vaccinations, rolling_vaccination)
AS(
	SELECT deaths.continent,
		   deaths.location,
		   CONVERT(date, deaths.date),
		   deaths.population,
		   vaccination.new_vaccinations,
		   SUM(CONVERT(BIGINT, vaccination.new_vaccinations))
		       OVER (PARTITION BY deaths.location 
			       ORDER BY deaths.location, deaths.date) AS rolling_vaccination
	FROM CovidProject..CovidDeaths deaths
	JOIN CovidProject..CovidVaccinations vaccination
		ON deaths.location = vaccination.location
		AND deaths.date = vaccination.date
	WHERE  deaths.continent IS NOT NULL
)
SELECT *, 
       CAST((rolling_vaccination/population)*100 AS decimal(10, 2)) AS pct_pop_vaccinated
FROM PopVsVac;

-------------------------------------------------------------------------------------
-- Part 2.1 - Vaccination Dashboard

-- TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	people_vaccinated numeric,
	people_fully_vaccinated numeric,
	total_boosters numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT deaths.continent,
	   deaths.location,
	   deaths.date,
	   deaths.population,
	   CAST(vaccination.new_vaccinations_smoothed AS BIGINT),
	   vaccination.people_vaccinated,
	   vaccination.people_fully_vaccinated,
	   CAST(vaccination.total_boosters AS BIGINT)
	FROM CovidProject..CovidDeaths deaths
	JOIN CovidProject..CovidVaccinations vaccination
		ON deaths.location = vaccination.location
		AND deaths.date = vaccination.date;

-- Contribution for World Vaccinations by Country
SELECT location, 
       FORMAT(SUM(new_vaccinations), 'N0') as total_vaccinations,
       CAST(SUM(new_vaccinations) * 100.0 / (SELECT SUM(new_vaccinations) FROM #PercentPopulationVaccinated WHERE continent IS NOT NULL) AS decimal(10,2)) as pct_total_vaccinations
FROM #PercentPopulationVaccinated
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY location;

-- Total People Vaccinated VS Population
SELECT location,
       FORMAT(MAX(people_vaccinated), 'N0') AS total_people_vaccinated,
	   FORMAT(MAX(population), 'N0') AS total_population,
	   CAST((MAX(people_vaccinated)/MAX(population))*100 AS decimal(10,2)) AS pct_people_vaccinated
FROM #PercentPopulationVaccinated
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY pct_people_vaccinated DESC;

-- Total People Vaccinated Once, People Fully Vaccinated with Booster and People Fully Vaccinated without Booster
SELECT location,
	   CAST(((MAX(people_vaccinated) - MAX(people_fully_vaccinated))/MAX(population))*100 AS decimal(10,2)) AS pct_people_vaccinated_once,
	   CAST((MAX(total_boosters)/MAX(population))*100 AS decimal(10,2)) AS pct_fully_vaccinated_with_booster,
	   CAST(((MAX(people_fully_vaccinated) - MAX(total_boosters))/MAX(population))*100 AS decimal(10,2)) AS pct_fully_vaccinated_without_booster,
	   CAST((MAX(people_fully_vaccinated)/MAX(population))*100 AS decimal(10,2)) AS pct_people_fully_vaccinated,
	   CAST((MAX(people_vaccinated)/MAX(population))*100 AS decimal(10,2)) AS pct_people_vaccinated
FROM #PercentPopulationVaccinated
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY pct_people_vaccinated DESC;

-- Daily Vaccine Doses by People's Income
SELECT location,
--       CONVERT(date, date) AS date,
       FORMAT(MAX(people_vaccinated), 'N0') AS total_people_vaccinated,
	   FORMAT(MAX(population), 'N0') AS total_population,
	   CAST((MAX(people_vaccinated)/MAX(population))*100 AS decimal(10,2)) AS pct_people_vaccinated
FROM #PercentPopulationVaccinated
WHERE continent IS NULL
	AND location NOT IN ('North America', 'Asia', 'Africa', 'Oceania', 'European Union', 'South America', 'International', 'Europe')
GROUP BY location
ORDER BY location;