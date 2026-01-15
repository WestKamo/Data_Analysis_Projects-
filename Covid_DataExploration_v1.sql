
--explore the data and find out what is in it
select * from Portfolio_Project..covid_death
order by 3,4

--select the data we are going to use
SELECT 
    country, 
    total_cases, 
    total_deaths, 
    (total_cases - total_deaths) as Estimated_Active_Cases, -- Calculated column
    population
FROM Portfolio_Project..covid_death
WHERE Country is not null 
ORDER BY 1, 2;


--looking at total cases vs Total deaths
SELECT 
    country, 
    total_cases, 
    total_deaths, 
    (CAST(total_deaths AS float) / NULLIF(CAST(total_cases AS float), 0)) * 100 as Death_Percentage
FROM Portfolio_Project..covid_death
WHERE Country is not null
ORDER BY 1, 2;

---Looking at countires with highest infection rate compared to population
SELECT 
    country, 
    population,
    MAX(total_cases) as Highest_Infection_Count,
    MAX((CAST(total_cases AS float) / NULLIF(CAST(population AS float), 0))) * 100 as PercentPopulationInfected
FROM Portfolio_Project..covid_death
WHERE Country is not null
GROUP BY country, population
ORDER BY PercentPopulationInfected DESC;


---showing  countries with highest death count per population
SELECT 
    country, 
    MAX(CAST(total_deaths AS float)) as TotalDeathCount
FROM Portfolio_Project..covid_death
WHERE Country is not null 
-- AND country not in ('World', 'High income', 'Upper middle income', 'Europe', 'North America') -- Use this if continent column is missing
GROUP BY country
ORDER BY TotalDeathCount DESC;


---Global numbers

SELECT 
    SUM(total_cases) as Total_Cases, 
    SUM(CAST(total_deaths as float)) as Total_Deaths, 
    (SUM(CAST(total_deaths as float)) / NULLIF(SUM(total_cases), 0)) * 100 as Global_Death_Percentage
FROM Portfolio_Project..covid_death
WHERE country NOT IN ('World', 'Europe', 'North America', 'South America', 'Asia', 'Africa', 'Oceania', 'European Union');



---Lets explore the other table 
---Loooking at total population vs vaccinations
---I included CTE , since we cant direclty use aliases in one sql query to perfom calculations
WITH PopvsVac (Country, Date, Population, Daily_Vaccinations, Rolling_People_Vaccinated) 
AS
(
SELECT dea.Country, vac.date,dea.Population,vac.daily_vaccinations,
    SUM(CAST(vac.daily_vaccinations AS float)) OVER (PARTITION BY dea.Country ORDER BY vac.date) as Rolling_People_Vaccinated
FROM Portfolio_Project..covid_death dea
JOIN Portfolio_Project..covidvac vac
    ON dea.Country = vac.country -- Warning: Fix USA/United States names first!
WHERE dea.Country is not null
--DER BY 2, 3
)
SELECT 
    *,
    (Rolling_People_Vaccinated / NULLIF(Population, 0)) * 100 as Percent_Population_Vaccinated
FROM PopvsVac;

---Lets use temp table also( i am just bragging now cause i can use it)

DROP TABLE IF EXISTS #PercentPopulationVaccinated;


CREATE TABLE #PercentPopulationVaccinated
(
    Country nvarchar(255),
    Date datetime,
    Population numeric,
    Daily_Vaccinations numeric,
    RollingPeopleVaccinated numeric
);


INSERT INTO #PercentPopulationVaccinated
SELECT 
    dea.Country, 
    vac.date,
    dea.Population,
    vac.daily_vaccinations,
    SUM(CAST(vac.daily_vaccinations AS float)) OVER (PARTITION BY dea.Country ORDER BY vac.date) as RollingPeopleVaccinated
FROM Portfolio_Project..covid_death dea
JOIN Portfolio_Project..covidvac vac
    ON dea.Country = vac.country
WHERE dea.Country is not null;


SELECT 
    *,
    (RollingPeopleVaccinated / NULLIF(Population, 0)) * 100 as PercentPopulationVaccinated
FROM #PercentPopulationVaccinated
ORDER BY Country, Date;

---lets create our very first view to store data for later visualisations
-- Drop it just in case it exists partially
USE Portfolio_Project; 
GO
DROP VIEW IF EXISTS PercentPopulationVaccinated;
GO

CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    dea.Country, 
    vac.date,
    dea.Population,
    vac.daily_vaccinations,
    SUM(CAST(vac.daily_vaccinations AS float)) OVER (PARTITION BY dea.Country ORDER BY vac.date) as RollingPeopleVaccinated
FROM Portfolio_Project..covid_death dea
JOIN Portfolio_Project..covidvac vac
    ON dea.Country = vac.country
WHERE dea.Country is not null;
GO

select * from PercentPopulationVaccinated