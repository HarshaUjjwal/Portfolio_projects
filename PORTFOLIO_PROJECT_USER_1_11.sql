select * from DEATHS
where continent is not null
order by 3,4;

--select * from VACCINATION order by 3,4;

--select dtaa that we are going to be using
select location, dates, total_cases,new_cases, total_deaths, population
from deaths order by 1,2;

--Looking at the total cases vs total deaths
--Shows likelihood of dying is you contract covid in your country
select location, dates, total_cases, total_deaths, (total_deaths/total_cases)*100 as percent
from deaths 
where location like 'India'
order by 1,2;

--Looking at the total cases vs population
select location, dates, population, total_cases, (total_cases/population)*100 as percent
from deaths 
where location like 'India'
order by 1,2;

--what country has highest infection rate compared to population
select location, population, max(total_cases) as highestInfectionCount, max(total_cases/population)*100 as percent
from deaths group by location, population order by 4 desc;

--countries with highest death count per population
select location, population, max(total_deaths) as highestDeathCount, max(total_deaths/population)*100 as percent
from deaths 
where continent is not null and  total_deaths is not null group by location, population order by 3 desc;

--Break things up based on continent

--Showing the continents with the highest death count
select location, max(total_deaths) as highestDeathCount
from deaths where continent is null group by location order by 2 desc;



--GLOBAL NUMBERS
select sum(new_cases) as total_cases, sum(new_deaths) as total_deaths, (sum(new_deaths)/sum(new_cases))*100 as death_percentage 
from deaths
where continent is not null order by 1;

--Total population vs vaccination
select d.continent, d.location, d.dates, d.population, v.new_vaccinations from deaths d
join vaccination v on d.location = v.location and d.dates = v.dates
where d.continent is not null and v.new_vaccinations is not null order by 1,2;

--show vaccination vs population percentage
select d.location, d.population, sum(v.new_vaccinations), (sum(v.new_vaccinations)/d.population)*100 as Vaccination_Percentage 
from deaths d
join vaccination v on d.location = v.location and d.dates = v.dates
where d.continent is null and v.new_vaccinations is not null group by d.location, d.population order by 1,2;

--adding up day by day new vaccination of each location(country)
select d.continent, d.location, d.dates, d.population, v.new_vaccinations, 
sum(v.new_vaccinations) over (partition by d.location order by d.location, d.dates) as rolling_people_vaccinated
--(rolling_people_vaccinated/population)*100 as Vaccinated_percentage
from deaths d
join vaccination v on d.location = v.location and d.dates = v.dates
where d.continent is not null and v.new_vaccinations is not null order by 2,3;

--Use CTE
With PopvsVac (Continent, Location, Dates, Population, New_Vaccinations, rolling_people_vaccinated) 
as
(
select d.continent, d.location, d.dates, d.population, v.new_vaccinations, 
sum(v.new_vaccinations) over (partition by d.location order by d.location, d.dates) as rolling_people_vaccinated
--(rolling_people_vaccinated/population)*100 as Vaccinated_percentage
from deaths d
join vaccination v on d.location = v.location and d.dates = v.dates
where d.continent is not null and v.new_vaccinations is not null
--order by 2,3
)
select Continent, Location, Dates, Population, New_Vaccinations, rolling_people_vaccinated, 
(Rolling_people_vaccinated/population)*100 as vaccination_percentage from PopvsVac;





--Temp Table

declare
    c int;
begin 
    select count(*) into c from user_tables where table_name = upper('percent_population_vaccinated');
    if c>0 then
        execute immediate 'DROP table percent_population_vaccinated';
    else
    dbms_output.put_line('Creating new table.');
    end if;
end;
/
create table percent_population_vaccinated
(
continent varchar(255),
location varchar(255),
dates date,
population number,
new_vaccination number,
rolling_people_vaccinated number);

insert into percent_population_vaccinated
select d.continent, d.location, d.dates, d.population, v.new_vaccinations, 
sum(v.new_vaccinations) over (partition by d.location order by d.location, d.dates) as rolling_people_vaccinated
--(rolling_people_vaccinated/population)*100 as Vaccinated_percentage
from deaths d
join vaccination v on d.location = v.location and d.dates = v.dates
where d.continent is not null and v.new_vaccinations is not null
--order by 2,3;
;
select continent, location , dates, population, new_vaccination, rolling_people_vaccinated as RDP, 
(rolling_people_vaccinated/population)*100 as Vaccinated_percentage from percent_population_vaccinated;


-- Create view for later visualization
create view Percent_Population_vaccinated_view as
select continent, location , dates, population, new_vaccination, rolling_people_vaccinated as RDP, 
(rolling_people_vaccinated/population)*100 as Vaccinated_percentage from percent_population_vaccinated;

select * from Percent_Population_vaccinated_view