--Querry0: Selecting data to be used ordered by location and date

--SELECT location, dates, total_cases, new_cases, total_deaths, population
--FROM coviddeaths 
--ORDER BY 1, 2;

--Q1: Deaths per total cases percentage in Hungary
--SELECT location, dates, (total_deaths/total_cases)*100 AS "Percentage"
--FROM coviddeaths
--WHERE location LIKE '%Hungary%'
--ORDER BY 1, 2;

--Q2: Cases per population oreded by population size
--SELECT location, SUM(population) AS "Population", SUM(total_cases) AS "Infected", SUM(total_cases)/SUM(population)*100 AS "Infected Rate"
--FROM coviddeaths
--WHERE iso_code NOT LIKE '%OWID%'
--GROUP BY location
--ORDER BY SUM(population) DESC;
 
--Q3: Most infected countries
--SELECT location, MAX(population) AS "Population", MAX(total_cases) AS "Infected", MAX(total_cases)/MAX(population)*100 AS "Infected Rate"
--FROM coviddeaths
--WHERE iso_code NOT LIKE '%OWID%'AND
--    population IS NOT NULL AND 
--    total_cases IS NOT NULL
--GROUP BY location, population
--ORDER BY MAX(total_cases)/MAX(population)*100 DESC;

--Q4: Countries with most deaths
--SELECT location, MAX(Total_deaths) AS "Total Deaths"
--FROM coviddeaths
--WHERE iso_code NOT LIKE '%OWID%'AND
--    Total_deaths IS NOT NULL
--GROUP BY location
--ORDER BY MAX(Total_deaths) DESC;
--
--Q5: Same as Q3 but with continent
--SELECT continent, MAX(population) AS "Population", MAX(total_cases) AS "Infected", MAX(total_cases)/MAX(population)*100 AS "Infected Rate"
--FROM coviddeaths
--WHERE continent IS NOT NULL
--GROUP BY continent
--ORDER BY MAX(total_cases)/MAX(population)*100 DESC;

--Q6: Same as Q4 but with continent
--SELECT continent, MAX(Total_deaths) AS "Total Deaths"
--FROM coviddeaths
--WHERE continent IS NOT NULL AND
--    Total_deaths IS NOT NULL
--GROUP BY continent
--ORDER BY MAX(Total_deaths) DESC;

--Q7: Covid spreading in Europe
--SELECT location, dates, total_cases AS "Infected"
--FROM coviddeaths
--WHERE continent LIKE 'Europe' AND iso_code NOT LIKE '%OWID%' AND
--   total_cases IS NOT NULL
--ORDER BY dates;

--Q8prelude: Dates when countries started to administer vaccinations
--SELECT location, MIN(dates) AS "Vaccination start"
--FROM covidvacs
--WHERE iso_code NOT LIKE '%OWID%' AND 
--    total_vaccinations IS NOT NULL 
--GROUP BY location
--ORDER BY "Vaccination start" ASC;

--Q8: Dates when countries started to administer vaccinations and how many cases they had by then
--WITH VaccineStart AS (
--    SELECT location, MIN(dates) AS "Vaccination start"
--    FROM covidvacs
--    WHERE iso_code NOT LIKE '%OWID%' AND  
--        total_vaccinations IS NOT NULL
--    GROUP BY location
--) SELECT 
--    vs.location, vs."Vaccination start", MAX(cd.total_cases) AS "Covid cases by then"
--    FROM VaccineStart vs JOIN coviddeaths cd 
--    ON vs.location = cd.location 
--        AND cd.dates <= vs."Vaccination start"
--    WHERE cd.total_cases IS NOT NULL
--    GROUP BY vs.location, vs."Vaccination start"
--    ORDER BY "Covid cases by then" DESC;

--Q9: World death percetege per days when there where new cases
--SELECT dates, SUM(COALESCE(new_cases,0)) AS "Total Cases", SUM(COALESCE(new_deaths,0)) AS "Total Deaths", SUM(COALESCE(new_deaths,0))/NULLIF(SUM(COALESCE(new_cases,0)),0)*100 AS "Death Percentege"
--FROM coviddeaths
--WHERE iso_code NOT LIKE '%OWID%'
--HAVING SUM(COALESCE(new_cases,0)) > 0
--GROUP BY dates
--ORDER BY "Death Percentege" DESC;

--Q10.1: Percentege of Population vaccined after vaccination began

--SELECT cd.continent, cd.location, cd.dates, cd.population, vs.new_vaccinations AS "New Vaccinations", SUM(vs.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.dates) AS "Rolling SUM of Vaccinations" 
--FROM coviddeaths cd JOIN covidvacs vs
--ON cd.location = vs.location
--    AND cd.dates = vs.dates
--WHERE cd.iso_code NOT LIKE '%OWID%'
--ORDER BY cd.location ASC, cd.dates ASC;
--Q10.2: Population versus Vaccination with CTE
--WITH PopvsVacs (continent, location, dates, population, new_vaccinations, RollingPeopleVaccinated)
--AS
--(SELECT cd.continent, cd.location, cd.dates, cd.population, vs.new_vaccinations, SUM(vs.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.dates) AS RollingPeopleVaccinated 
--FROM coviddeaths cd JOIN covidvacs vs
--ON cd.location = vs.location
--    AND cd.dates = vs.dates
--WHERE cd.iso_code NOT LIKE '%OWID%'
--) SELECT     continent, 
--    location, 
--    dates, 
--    population, 
--    new_vaccinations, 
--    RollingPeopleVaccinated, 
--    (RollingPeopleVaccinated / population) * 100 AS VaccinationRate
--FROM PopvsVacs;

--Q10.3: Using TMP table
--BEGIN
--    EXECUTE IMMEDIATE 'DROP TABLE PercentPopulationVaccinated';
--EXCEPTION
--    WHEN OTHERS THEN
--        IF SQLCODE != -942 THEN
--            RAISE;
--        END IF;
--END;
--/
--CREATE TABLE PercentPopulationVaccinated
--(
--Continent VARCHAR(255),
--Location VARCHAR(255),
--Date DATE,
--Population NUMBER,
--New_vaccinations NUMBER,
--RollingPeopleVaccinated NUMBER,
--VaccinationRate NUMBER
--)
--/
--
--INSERT INTO PercentPopulationVaccinated(Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated, VaccinationRate)
--WITH PopvsVacs (continent, location, dates, population, new_vaccinations, RollingPeopleVaccinated)
--AS
--(SELECT cd.continent, cd.location, cd.dates, cd.population, vs.new_vaccinations, SUM(vs.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.dates) AS RollingPeopleVaccinated 
--FROM coviddeaths cd JOIN covidvacs vs
--ON cd.location = vs.location
--    AND cd.dates = vs.dates
--WHERE cd.iso_code NOT LIKE '%OWID%'
--) SELECT     continent, 
--    location, 
--    dates, 
--    population, 
--    new_vaccinations, 
--    RollingPeopleVaccinated, 
--    (RollingPeopleVaccinated / population) * 100 AS VaccinationRate
--FROM PopvsVacs;

--Q11: Creating view for Q10.3
CREATE VIEW PercentPopVaccinated AS
SELECT cd.continent, cd.location, cd.dates, cd.population, vs.new_vaccinations, SUM(vs.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.dates) AS RollingPeopleVaccinated 
FROM coviddeaths cd JOIN covidvacs vs
ON cd.location = vs.location
    AND cd.dates = vs.dates
WHERE cd.iso_code NOT LIKE '%OWID%';

