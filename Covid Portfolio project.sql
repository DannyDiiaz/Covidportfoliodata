

Select *
from [Project porfolio]..['COVIDVACCINATIONS']
order by 3,4

--Select the data that we are going to be using

Select Location, Date, total_cases, new_cases, total_deaths, population
From [Project porfolio]..['COVIDDEATHS$']
where continent is not null
order by 1,2 

-- Looking at Total Cases Vs Total Deaths 
--likelihood of dying if you contract covid in your country

select location, date, total_cases, total_deaths, (CONVERT(DECIMAL(18,2), total_deaths) / CONVERT(DECIMAL(18,2), total_cases) )*100 as DeathPercent
from [Project porfolio]..['COVIDDEATHS$']
where location like '%states%'
order by 1,2

--Looking at total cases vs. population 
--shows what % of population got Covid

select location, date, population, total_cases, (CONVERT(DECIMAL(18,2), total_cases) / CONVERT(DECIMAL(18,2), population) )*100 as PercentPopInfected
from [Project porfolio]..['COVIDDEATHS$']
where continent is not null
order by 1,2

-- Looking at countries with highest infection rate 

select location, population, Max(total_cases)as HighestInfectionCount, Max(CONVERT(DECIMAL(18,2), total_cases) / CONVERT(DECIMAL(18,2), population) )*100 as PercentPopInfected
from [Project porfolio]..['COVIDDEATHS$']
where continent is not null
group by  location, population
order by PercentPopInfected desc

--Showing Countries with Highest death count per population 

select location, Max(cast(total_deaths as int)) as totaldeathcount
from [Project porfolio]..['COVIDDEATHS$']
where continent is not null
--where location like '%states%'
group by  location
order by totaldeathcount desc

--seperated by contintent

select continent, Max(cast(total_deaths as int)) as totaldeathcount
from [Project porfolio]..['COVIDDEATHS$']
where continent is not null
--where location like '%states%'
group by continent
order by totaldeathcount desc

--global numbers

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From [Project porfolio]..['COVIDDEATHS$']
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2

--Total pop vs vaccinations

SELECT dea.continent, dea.location, dea.population, dea.Date, vac.new_vaccinations,
       SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location
           ORDER BY dea.location, dea.Date) AS RollingPopVaccinated
FROM [Project porfolio]..['COVIDDEATHS$'] dea
INNER JOIN [Project porfolio]..['COVIDVACCINATIONS'] vac
    ON dea.location = vac.location AND dea.Date = vac.Date
WHERE dea.continent IS NOT NULL;

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated

SELECT dea.continent, dea.location, dea.population, dea.Date, vac.new_vaccinations,
       SUM(Convert(int vac.new_vaccinations)) OVER (PARTITION BY dea.location
           ORDER BY dea.location, dea.Date) AS RollingPopVaccinated
FROM [Project porfolio]..['COVIDDEATHS$'] dea
INNER JOIN [Project porfolio]..['COVIDVACCINATIONS'] vac
    ON dea.location = vac.location AND dea.Date = vac.Date
--WHERE dea.continent IS NOT NULL;

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating View to store data 

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From [Project porfolio]..['COVIDDEATHS$'] dea
Join [Project porfolio]..['COVIDVACCINATIONS'] vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 