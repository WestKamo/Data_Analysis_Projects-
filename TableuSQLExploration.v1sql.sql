
-- 1. GLOBAL NUMBERS
-- We sum the "Total Cases" column directly. 
-- We filter out "World", "Europe", etc. to avoid double counting.

Select 
    SUM(CAST(REPLACE([Total_Cases], ',', '') AS float)) as total_cases, 
    SUM(CAST(REPLACE([Total_Deaths], ',', '') AS float)) as total_deaths, 
    (SUM(CAST(REPLACE([Total_Deaths], ',', '') AS float)) / NULLIF(SUM(CAST(REPLACE([Total_Cases], ',', '') AS float)), 0))*100 as DeathPercentage
From Portfolio_Project..covid_death
Where Country NOT IN ('World', 'Europe', 'North America', 'South America', 'Asia', 'Africa', 'Oceania', 'European Union', 'International')
order by 1,2


-- 2. TOTAL DEATHS PER CONTINENT
-- Since your dataset doesn't have a "Continent" column, we manually select the rows 
-- that represent continents based on the Country column.

Select 
    Country as location, 
    SUM(CAST(REPLACE([Total_Deaths], ',', '') AS float)) as TotalDeathCount
From Portfolio_Project..covid_death
Group by Country
order by TotalDeathCount desc


-- 3. PERCENT POPULATION INFECTED (MAP)
-- Shows the infection rate for every country.

Select 
    Country as Location, 
    CAST(REPLACE(Population, ',', '') AS float) as Population, 
    CAST(REPLACE([Total_Cases], ',', '') AS float) as HighestInfectionCount,  
    (CAST(REPLACE([Total_Cases], ',', '') AS float) / NULLIF(CAST(REPLACE(Population, ',', '') AS float), 0))*100 as PercentPopulationInfected
From Portfolio_Project..covid_death

Order by PercentPopulationInfected desc


-- 4. PERCENT POPULATION INFECTED (TIME SERIES)
-- This query below shows "Vaccination Rate Over Time" instead, 


Select 
    vac.Country as Location, 
    CAST(REPLACE(dea.Population, ',', '') AS float) as Population, 
    vac.date, 
    MAX(vac.total_vaccinations) as RollingPeopleVaccinated,
    (MAX(vac.total_vaccinations) / NULLIF(CAST(REPLACE(dea.Population, ',', '') AS float), 0))*100 as PercentPopulationVaccinated
From Portfolio_Project..covidvac vac
JOIN Portfolio_Project..covid_death dea
    ON vac.Country = dea.Country -- Ensure country names match (e.g. USA vs United States)
Group by vac.Country, dea.Population, vac.date
Order by PercentPopulationVaccinated desc





-- 5. TOTAL POPULATION vs VACCINATIONS (Using CTE)


With PopvsVac (Country, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select 
    dea.Country, 
    vac.date, 
    CAST(REPLACE(dea.Population, ',', '') AS float) as Population, 
    vac.daily_vaccinations,
    SUM(CAST(vac.daily_vaccinations AS float)) OVER (Partition by dea.Country Order by vac.date) as RollingPeopleVaccinated
From Portfolio_Project..covid_death dea
Join Portfolio_Project..covidvac vac
	On dea.Country = vac.country 
)
Select *, (RollingPeopleVaccinated/Population)*100 as PercentPeopleVaccinated
From PopvsVac


