-- PART 1 - COVID DEATHS

SELECT *
FROM PortfolioProjectCovid..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4;

ALTER TABLE CovidDeaths ALTER COLUMN total_deaths FLOAT;
ALTER TABLE CovidDeaths ALTER COLUMN new_deaths FLOAT;

-- PART 1.1 - COUNTRIES

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProjectCovid..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2;

-- Total Cases vs Total Deaths
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100  AS DeathPercentage
FROM PortfolioProjectCovid..CovidDeaths
WHERE location like '%states%'
ORDER BY 1, 2;

-- Total Cases vs Population
SELECT location, date, population, total_cases, (total_cases/population)*100  AS PercentPopulationInfected
FROM PortfolioProjectCovid..CovidDeaths
WHERE location like '%states%'
ORDER BY 1, 2;

-- Countries with Highest Infection Rate
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, 
	MAX((total_cases/population)*100)  AS PercentPopulationInfected
FROM PortfolioProjectCovid..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

-- Countries with Highest Death Count
SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM PortfolioProjectCovid..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- PART 1.2 - CONTINENTS

-- Continents with Highest Infection Rate
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, 
	MAX((total_cases/population)*100)  AS PercentPopulationInfected
FROM PortfolioProjectCovid..CovidDeaths
WHERE continent IS NULL
	AND location NOT LIKE '%income%'
	AND location NOT LIKE '%European%'
	AND location <> 'World'
	AND location <> 'International'
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

-- Continents with Highest Death Count
SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM PortfolioProjectCovid..CovidDeaths
WHERE continent IS NULL
	AND location NOT LIKE '%income%'
	AND location NOT LIKE '%European%'
	AND location <> 'World'
	AND location <> 'International'
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- PART 1.3 - GLOBAL NUMBERS

SELECT date, location, total_cases, new_cases, total_deaths, new_deaths
FROM PortfolioProjectCovid..CovidDeaths
WHERE location = 'World'
ORDER BY 1;

-- New Cases by Day
SELECT date, new_cases, new_deaths, 
	(new_deaths/NULLIF(new_cases,0))*100 AS DeathPercentage
FROM PortfolioProjectCovid..CovidDeaths
WHERE location = 'World'
ORDER BY date;

-- Total Cases by Day
SELECT date, total_cases, total_deaths, 
	(total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProjectCovid..CovidDeaths
WHERE location = 'World'
ORDER BY date;

-- PART 2 - JOIN COVID DEATHS AND COVID VACCINATION TABLES

SELECT *
FROM PortfolioProjectCovid..CovidVaccinations
ORDER BY 3, 4;

SELECT * 
FROM PortfolioProjectCovid..CovidDeaths deaths
JOIN PortfolioProjectCovid..CovidVaccinations vaccination
	ON deaths.location = vaccination.location
	AND deaths.date = vaccination.date;

-- Total Population vs Vaccinations
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccination.new_vaccinations
FROM PortfolioProjectCovid..CovidDeaths deaths
JOIN PortfolioProjectCovid..CovidVaccinations vaccination
	ON deaths.location = vaccination.location
	AND deaths.date = vaccination.date
WHERE deaths.continent IS NOT NULL
ORDER BY 2, 3;

-- Total Population vs Vaccinations
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccination.new_vaccinations
FROM PortfolioProjectCovid..CovidDeaths deaths
JOIN PortfolioProjectCovid..CovidVaccinations vaccination
	ON deaths.location = vaccination.location
	AND deaths.date = vaccination.date
WHERE deaths.continent IS NOT NULL
ORDER BY 2, 3;

-- Rolling Count Total Population vs Vaccinatio
SELECT deaths.continent, 
	deaths.location, 
	deaths.date, 
	deaths.population, 
	vaccination.new_vaccinations,
	SUM(CONVERT(BIGINT, vaccination.new_vaccinations)) 
		OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS RollingVaccination
FROM PortfolioProjectCovid..CovidDeaths deaths
JOIN PortfolioProjectCovid..CovidVaccinations vaccination
	ON deaths.location = vaccination.location
	AND deaths.date = vaccination.date
WHERE deaths.continent IS NOT NULL
ORDER BY 2, 3;

-- Use CTE
WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingVaccination) 
AS(
	SELECT deaths.continent, 
		deaths.location, 
		deaths.date, 
		deaths.population, 
		vaccination.new_vaccinations,
		SUM(CONVERT(BIGINT, vaccination.new_vaccinations)) 
			OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS RollingVaccination
	FROM PortfolioProjectCovid..CovidDeaths deaths
	JOIN PortfolioProjectCovid..CovidVaccinations vaccination
		ON deaths.location = vaccination.location
		AND deaths.date = vaccination.date
	WHERE deaths.continent IS NOT NULL
)
SELECT *, (RollingVaccination/population)*100
FROM PopVsVac

-- Temp Table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
	continent nvarchar(255), 
	location nvarchar(255), 
	date datetime, 
	population numeric, 
	new_vaccinations numeric, 
	RollingVaccination numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT deaths.continent, 
	deaths.location, 
	deaths.date, 
	deaths.population, 
	vaccination.new_vaccinations,
	SUM(CONVERT(BIGINT, vaccination.new_vaccinations)) 
		OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS RollingVaccination
FROM PortfolioProjectCovid..CovidDeaths deaths
JOIN PortfolioProjectCovid..CovidVaccinations vaccination
	ON deaths.location = vaccination.location
	AND deaths.date = vaccination.date
WHERE deaths.continent IS NOT NULL

SELECT *, (RollingVaccination/population)*100
FROM #PercentPopulationVaccinated;

-- PART 3 - CREATE VIEWS
CREATE VIEW PercentPopVaccinated 
AS 
SELECT deaths.continent, 
	deaths.location, 
	deaths.date, 
	deaths.population, 
	vaccination.new_vaccinations,
	SUM(CONVERT(BIGINT, vaccination.new_vaccinations)) 
		OVER (PARTITION BY deaths.location ORDER BY deaths.location, deaths.date) AS RollingVaccination
FROM PortfolioProjectCovid..CovidDeaths deaths
JOIN PortfolioProjectCovid..CovidVaccinations vaccination
	ON deaths.location = vaccination.location
	AND deaths.date = vaccination.date
WHERE deaths.continent IS NOT NULL;