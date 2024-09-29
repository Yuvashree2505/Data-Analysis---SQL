exec sp_help [release];

select *
from [dbo].[movie];

select * 
from [dbo].[people];

select * 
from [dbo].[release];

select *
from [dbo].[review];

select * from directors;

select * from country;

select * from cast;

select * from genre;

-- Exploring Data 

select DISTINCT(type)
from movie;

-- count of movies

select count(type) as Movie from movie
where type= 'movie';

-- count of Tv Show

select count(type) 'Tv Show' from movie
where type = 'TV Show';

-- Count of directors
select distinct(count(director)) as count_directors from directors;

select m.id ,m.type,d.director 
from movie as m
left join directors as d on m.show_id = d.show_id
order by m.id;

-- movies released over a period of time in netflix

select year(r.Date_add) as year,count(m.type) 'Movie'
from movie m
right join release r on m.id = r.id
where m.type = 'Movie'
group by year(r.Date_add)
order by 'Movie' desc;

-- TV show released over a period of time in netflix

select year(r.Date_add) as year,count(m.type) 'TV Show'
from movie m
right join release r on m.id = r.id
where m.type = 'TV Show'
group by year(r.Date_add)
order by 'TV Show' desc;

-- Month where movie where released in netflix 

select month(r.date_add) 'month',count(m.type) as 'count'
from release r
join movie m on m.id = r.id
where m.type = 'Movie'
group by month(r.date_add)
order by 'month' desc;

-- Month where tv show where released in netflix 

select month(r.date_add) 'month',count(m.type) as 'count'
from release r
join movie m on m.id = r.id
where m.type = 'TV Show'
group by month(r.date_add)
order by 'month' desc;

-- Cleaning The data

-- removing duplicates

select id ,count(*) from movie
group by id
having count(*) > 1;

select * from movie
where concat(upper(title),type) in (
select concat(upper(title),type)
from movie
group by concat(upper(title),type)
having count(*) > 1)
order by title;

with cte as (
select *
,ROW_NUMBER() over(partition by title,type order by show_id) as rn
from movie)
select * from cte 
where rn=1 and title not like '?%';

-- Altering the table release and converting the date formate

alter table release
add Date_add date;

update release
set Date_add = cast(date_added as Date);

select Date_add
from release;

-- altering the datatype release, review
alter table release 
alter column id int;

alter table review 
alter column id int;


--new table for listed_in, director,country,cast

-- director 
select show_id,trim(value) as director
into directors
from people
cross apply string_split(director,',');
select * from directors;

-- country
select show_id,trim(value) as country
into country
from people
cross apply string_split(country,',');

-- cast
select show_id,trim(value) as cast
into cast
from people
cross apply string_split(cast,',');

-- listed_in
select show_id,trim(value) as genre
into genre
from review
cross apply string_split(listed_in,',');

-- Modifing the Rating

alter table review
add rating_catagory varchar(50);

update review
set rating_catagory = CASE when rating = 'TV-MA' then 'Adults'
	when rating = 'TV-Y7-FV' then 'Older Kids'
	when rating = 'TV-PG' then 'Older Kids'
	when rating = 'TV-Y7' then 'Older Kids'
	when rating = 'TV-14' then 'Teens'
	when rating = 'R' then 'Adults'
	when rating = 'TV-Y' then 'Kids'
	when rating = 'NR' then 'Adults'
	when rating = 'PG-13' then 'Teens'
	when rating = 'TV-G' then 'Kids'
	when rating = 'PG' then 'Older Kids'
	when rating = 'G' then 'Kids'
	when rating = 'UR' then 'Adults'
	when rating = 'NC-17' then 'Adults'
	else 'Unknown'
END;


-- Missing values 
-- country

insert into country
select show_id,map.country
from people p
inner join (select director,country from country c
inner join directors d on d.show_id = c.show_id
group by director,country) map on p.director = map.director
where p.country is null;

-- duration
select * from review
where duration is null;

update review
set duration = case when duration is null then rating else duration end;

-- Analysing data

-- Percentage of TV shows and movies

select type,round(count(*)*100.0/(select count(*) from movie),1) as percentage
from movie
group by type;

-- Count of Director who's Movie in netflix

select distinct(count(d.director)) as Movie_director from movie as m
left join directors as d on m.show_id = d.show_id
where m.type = 'movie';

-- Count of Director who's Tv show in netflix

select distinct(count(d.director)) as Movie_director from movie as m
left join directors as d on m.show_id = d.show_id
where m.type = 'TV Show';

-- Count of movie or TV show done by director

select d.director,m.type,count(m.type) as count_movie
from directors as d
left join movie m on m.show_id = d.show_id
where d.director is not null 
group by d.director,m.type
order by d.director;

-- Which movie or a Tv Show is done with more then one director

select m.title,d.director,count(*) as director_count
from movie m
inner join directors d on d.show_id = m.show_id
cross apply string_split(trim(director),',')
group by m.title,d.director
having count(*) > 1 
order by title; 


-- count of movies and TV show released over a period of time in netflix

select year(r.Date_add) 'year_added',count(m.type) 'Movie or TV show'
from movie m
right join release r on m.id = r.id
group by year(r.Date_add)
order by 'Movie or TV show' desc;


-- Month where movie and tv show released in netflix 

select month(r.date_add) 'month',count(m.type) as 'count'
from release r
join movie m on m.id = r.id
group by month(r.date_add)
order by 'month' desc;

-- netflix library by country in particular year

select top 10 r.release_year,c.country,count(m.title) as 'count_movies/tv shows'
from country c
join movie m on m.show_id = c.show_id
join release r on r.id = m.id
where r.release_year = '2021'
group by r.release_year,c.country
order by 'count_movies/tv shows' desc;

-- top 10 countries on netflix

select top 10 count(m.title) as 'count_movies/tv shows',c.country
from country c
join movie m on c.show_id = m.show_id
group by c.country
order by 'count_movies/tv shows' desc;

-- top 10 countries movies and tv show in percentage

select c.country ,count(c.country)*100/(select count(*) from movie) as percentage
from movie m 
join country c on m.show_id = c.show_id
where m.type = 'movie'
group by c.country
order by percentage desc; 

-- age of Movie

select m.title,(year(r.date_added) - r.release_year) as age ,c.country
from release r
join country c on c.show_id = r.show_id
join movie m on m.id = r.id
where m.type = 'Movie'
order by age desc;

-- Avg age of movies in top countries
select top 10 avg(year(r.date_added) - r.release_year) as age,c.country
from release r
join country c on c.show_id = r.show_id
join movie m on m.id = r.id
where m.type = 'Movie'
group by c.country
order by age desc;

-- age of TV show

select m.title,(year(r.date_added) - r.release_year) as age ,c.country
from release r
join country c on c.show_id = r.show_id
join movie m on m.id = r.id
where m.type = 'TV show'
order by age desc;

-- Avg age of TV show in top countries
select top 10 avg(year(r.date_added) - r.release_year) as age ,c.country
from release r
join country c on c.show_id = r.show_id
join movie m on m.id = r.id
where m.type = 'TV show'
group by c.country
order by age desc;

-- rating for Movie

select rating,COUNT(rating) as count_rating
from review r
join movie m on m.id = r.id
where m.type = 'Movie'
group by rating
order by count_rating desc;

-- rating for TV Show

select rating,COUNT(rating) as count
from review r
join movie m on m.id = r.id
where m.type = 'Tv Show'
group by rating
order by count desc;

-- rating catagory of audiance
select r.rating_catagory,count(rating_catagory) as count,c.country
from review r
join movie m on m.id = r.id
join country c on c.show_id = r.show_id
group by r.rating_catagory,c.country
order by count desc;

-- Perentage of rating catagory of audiance

select c.country as country,r.rating_catagory,round(count(r.show_Id)*100.0/sum(count(r.show_id)) over(partition by c.country),1) 'percentage'
from review r
join country c on r.show_id = c.show_id
where c.country not like ''w
group by c.country,r.rating_catagory
order by c.country asc,'percentage' desc;

-- Percentage of rating by country

with country_rating as(
select country,count(rating_catagory) as total_ratings
from review r
join country c on c.show_id = r.show_id
group by country
),
total_rating as(
select count(rating_catagory) as total_ratings
from review
)
select cr.country,cr.total_ratings,(cr.total_ratings * 100.0 / tr.total_ratings) 'Percentage'
from country_rating cr,total_rating tr
order by percentage desc;

-- count of Movie based on genres

select g.genre,count(m.title) as 'count_Movies'
from genre g
join movie m on m.show_id = g.show_id
where m.type = 'Movie'
group by g.genre
order by 'count_Movies' desc;

-- count of Tv Show based on genres

select g.genre,count(m.title) as 'count'
from genre g
join movie m on m.show_id = g.show_id
where m.type = 'TV Show'
group by g.genre
order by 'count' desc;

-- top percentage of movies genre
select top 4 genre,round(count(m.show_id)*100.0/(select count(*) from movie),1) 'percentage_Movie'
from movie m
join genre g on m.show_id = g.show_id
where m.type = 'Movie'
group by genre
order by 'percentage_Movie' desc;

-- top percentage of movies genre
select top 4 genre,round(count(m.show_id)*100.0/(select count(*) from movie),1) 'percentage_TV show'
from movie m
join genre g on m.show_id = g.show_id
where m.type = 'Tv show'
group by genre
order by 'percentage_TV show' desc;

-- Movie Duration
select m.id,r.duration
from review r
join movie m on m.id = r.id
where m.type = 'Movie'
order by id;

-- TV Show Duration
select m.id,r.duration
from review r
inner join movie m on m.id = r.id
where m.type = 'TV Show'
order by id;
