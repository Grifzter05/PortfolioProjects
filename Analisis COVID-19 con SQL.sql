SELECT * 
FROM Portfolioproject ..covid_deaths
ORDER BY 3, 4 

SELECT * 
FROM Portfolioproject ..VACCINATIONS
ORDER BY 3, 4 

SELECT location, date, total_cases, total_deaths, population 
FROM Portfolioproject ..covid_deaths
ORDER BY 1, 2 

-- Numero de casos positivos vs numero de muertes por COVID

-- En este caso convertiremos en float a las variables "total_deaths" y "total_cases", pues en 
	--nuestra tabla original son datos tipo nvarchar(225) y al ser texto no se pueden dividir.

SELECT location, date, total_cases, total_deaths,(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS Deathpercentage
FROM Portfolioproject ..covid_deaths
WHERE location LIKE '%xico%'
ORDER BY 1, 2


--Numero de casos positivos vs total de la población
--Muestra que porcentaje de la población contrajo COVID en México
--Se ve como a principios del 2020 el procentaje de contagio era muy alto

SELECT location, date, total_cases, population,(CONVERT(float, total_cases) / (population)) * 100 AS Contaggionpercentage
FROM Portfolioproject ..covid_deaths
WHERE location LIKE '%xico%'
ORDER BY 1, 2

--Paises con la tasas de infección más altas respecto a su población

SELECT location, MAX(total_cases) AS Highestinfeccioncount, population, MAX((CONVERT(float, total_cases) / (population)) * 100)
AS Contaggionpercentage
FROM Portfolioproject ..covid_deaths
GROUP BY location, population
ORDER BY Contaggionpercentage DESC

--Paises con el mayor numero de muertes por país

SELECT location, MAX (CAST(total_deaths AS INT)) AS Highestdeathcount 
FROM Portfolioproject ..covid_deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY Highestdeathcount DESC

-- Muertes totales por COVID por continentes

SELECT continent, MAX (CAST(total_deaths AS INT)) AS Highestdeathcount 
FROM Portfolioproject ..covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Highestdeathcount DESC

-- Continentes con el mayor numero de muertes por población

SELECT continent,population, MAX (CAST(total_deaths AS INT)) AS Highestdeathcount 
FROM Portfolioproject ..covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent, population
ORDER BY Highestdeathcount DESC

-- Numeros globales por fecha

SELECT date, SUM(new_cases) AS New_cases, SUM(new_deaths) AS New_deaths,(SUM(new_cases) / NULLIF(SUM(new_deaths), 0)) * 100 AS Deathpercentage
FROM Portfolioproject ..covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2

--Total de la población vs Vacunas 

SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations,
SUM(CAST(VAC.new_vaccinations AS bigint)) OVER (partition by DEA.location ORDER BY DEA.location, DEA.date) 
AS RollingPeopleVaccinated
FROM Portfolioproject ..COVID_DEATHS DEA
JOIN Portfolioproject ..VACCINATIONS VAC
	ON DEA.location = vac.location
	AND DEA.date = VAC.date
WHERE DEA.continent IS NOT NULL
ORDER BY 2, 3

--Usamos CTE

WITH pepvsvac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) AS
(
SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations,
SUM(CAST(VAC.new_vaccinations AS bigint)) OVER (partition by DEA.location ORDER BY DEA.location, DEA.date) 
AS RollingPeopleVaccinated
FROM Portfolioproject ..COVID_DEATHS DEA
JOIN Portfolioproject ..VACCINATIONS VAC
	ON DEA.location = vac.location
	AND DEA.date = VAC.date
WHERE DEA.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated / population) * 100
FROM pepvsvac


-- Tabla temporal

DROP TABLE IF EXISTS #Percentpopulationvaccinated
CREATE TABLE #Percentpopulationvaccinated 
(
continent nvarchar(225),
location nvarchar(225),
date datetime,
population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO #Percentpopulationvaccinated 
SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations,
SUM(CAST(VAC.new_vaccinations AS bigint)) OVER (partition by DEA.location ORDER BY DEA.location, DEA.date) 
AS RollingPeopleVaccinated
FROM Portfolioproject ..COVID_DEATHS DEA
JOIN Portfolioproject ..VACCINATIONS VAC
	ON DEA.location = vac.location
	AND DEA.date = VAC.date
WHERE DEA.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated / population) * 100
FROM #Percentpopulationvaccinated

-- Creamos una vista para almacenar datos para posteriores visualizaciones

CREATE VIEW PercentPopulationVaccinated AS 
SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations,
SUM(CAST(VAC.new_vaccinations AS bigint)) OVER (partition by DEA.location ORDER BY DEA.location, DEA.date) 
AS RollingPeopleVaccinated
FROM Portfolioproject ..COVID_DEATHS DEA
JOIN Portfolioproject ..VACCINATIONS VAC
	ON DEA.location = vac.location
	AND DEA.date = VAC.date
WHERE DEA.continent IS NOT NULL

SELECT * 
FROM PercentPopulationVaccinated