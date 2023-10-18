
SELECT * 
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 3,4

--SELECT * 
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4

--Seleccionar datos que estaremos utilizando

SELECT Location, date, total_cases, new_cases, total_deaths, population_density
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

--Total de casos VS Total de Muertes
--Muestra la probabilidad que tienes de morir si contraes COVID-19 en tu país

SELECT
    Location,
    date,
    total_cases,
    total_deaths,
    ((CONVERT(decimal, total_deaths) / CONVERT(decimal, total_cases)) * 100) AS DeathPercentage
FROM PortfolioProject..CovidDeaths
ORDER BY 1, 2;


--Total de casos VS Población
--Muestra el porcentaje de la poblacion con COVID_19

SELECT
    Location,
    date,
    total_deaths,
    population_density,
    (total_deaths / population_density) * 100 AS PopulationWithCovidPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
ORDER BY 1, 2;


--Paises con la tasa de infeccion mas alta comparando con su población

SELECT
    Location,
    population_density,
	MAX(total_cases) AS HighestInfectionCount,
	(MAX(total_cases) / MAX(CONVERT(decimal, population_density))) * 100.0 AS PopulationInfectedPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
GROUP BY location, population_density
ORDER BY PopulationInfectedPercentage desc


--Desglosemos las cosas por continentes

SELECT
    continent,
    MAX(CAST(total_deaths AS decimal)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC;

--GLOBAL NUMBERS

SELECT
    SUM(CAST(new_cases AS decimal)) AS total_cases,
    SUM(CAST(new_deaths AS decimal)) AS total_deaths,
    (SUM(CAST(new_deaths AS decimal)) / NULLIF(SUM(CAST(new_cases AS decimal)), 0)) * 100 AS deathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;


--Población Total vs Vacunados

SELECT 
	dea.continent,
	dea.location,
	dea.date,
	dea.population_density,
	vac.new_vaccinations,
	SUM(CONVERT(decimal,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

--USE CTE

WITH PopvsVac (continent, location, date, population_density, new_vaccinations, RollingPeopleVaccinated)
	as
	(SELECT 
		dea.continent,
		dea.location,
		dea.date,
		dea.population_density,
		vac.new_vaccinations,
		SUM(CONVERT(decimal,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
	FROM PortfolioProject..CovidDeaths dea
	JOIN PortfolioProject..CovidVaccinations vac
		ON dea.location = vac.location
		AND dea.date = vac.date
	WHERE dea.continent is not null
	)
SELECT *, (RollingPeopleVaccinated / population_density) * 100
FROM PopvsVac


--TEMP TABLE

DROP table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population_density numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT 
		dea.continent,
		dea.location,
		dea.date,
		dea.population_density,
		vac.new_vaccinations,
		SUM(CONVERT(decimal,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
		ON dea.location = vac.location
		AND dea.date = vac.date
WHERE dea.continent is not null
SELECT *, (RollingPeopleVaccinated / population_density) * 100
FROM #PercentPopulationVaccinated


--CREATE A VIEW

CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population_density,
    vac.new_vaccinations,
    SUM(CONVERT(decimal, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;



SELECT *
FROM PercentPopulationVaccinated
