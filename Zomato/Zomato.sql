select * from Restaurant;
select * from Rating;
select * from location;
select * from Cuisines;
select * from Booking;
select * from cuisines_varity;

-- Data Exploration 

select * from Restaurant 
order by Restaurant_ID; 

select count(distinct Country_Code) as No_of_country 
from Restaurant;

select count(distinct City) as No_of_country
from Restaurant;

select count(distinct city) as city_count,Country_Code
from Restaurant
group by Country_Code
order by city_count;

select distinct Restaurant_Name,count(Restaurant_Name) 'count',Country_Code from Restaurant
group by Restaurant_Name,Country_Code
order by 'count' desc;

select avg(aggregate_rating) from rating;

select Rating_text,count(Rating_text) 'rating' from rating
group by Rating_text
order by 'rating' desc;

select sum(Votes) from rating;

select avg(Average_cost_for_two) as avg_for_two, Currency 
from cuisines
group by Currency;

select price_range,count(price_range) as count_price
from Cuisines
group by Price_range
order by count_price desc;

select * from Restaurant r
join location l on r.Restaurant_ID = l.Restaurant_ID
join Cuisines c on l.Restaurant_ID = c.Restaurant_ID
join Rating ra on ra.Restaurant_ID =c.Restaurant_ID
join Booking b on ra.Restaurant_ID = b.Restaurant_ID;


-- Data Cleaning

-- Duplicates
select Restaurant_ID, COUNT(*) from Restaurant
group by Restaurant_ID
having COUNT(*) > 1;

-- Datatype
alter table Restaurant
alter column Country_code int;

-- Spliting Cuisines
select Restaurant_Id,trim(value) as cuisines_varity 
into cuisines_varity
from Cuisines
cross apply string_split(Cuisines,',');
 
alter table rating
alter column votes int;

-- Analysis

-- Total Number of Restaurant
select count(distinct Restaurant_Name) from Restaurant

-- Number of branches for each restaurant
select distinct Restaurant_Name,count(Restaurant_Name) 'count' from Restaurant
group by Restaurant_Name
order by 'count' desc;

-- Top 10 Restaurant with the avg rating
select top 10 r.Restaurant_Name ,r.city,round(avg(ra.aggregate_Rating),0) 'highest_avg_rating' 
from rating ra
join Restaurant r on r.Restaurant_ID = ra.Restaurant_ID
group by r.Restaurant_Name ,r.city
order by 'highest_avg_rating' desc;

-- Determain the distribution of Restaurant across different cities
select City,count(*) as Restaurant_Count
from Restaurant
group by City
order by Restaurant_Count desc;

-- How many restaurant have a rating above 4.0 & also offer Online delivery?

select r.Restaurant_Name,round(ra.Aggregate_rating,1) 'rating and online delivary'
from Restaurant r
join rating ra on r.Restaurant_ID = ra.Restaurant_ID
join Booking b on b.Restaurant_ID = r.Restaurant_ID
where ra.Aggregate_rating > 4.0 and b.Has_Online_delivery = 'yes'
order by ra.Aggregate_rating desc;

-- What is the distribution of restaurant rating (How many restaurant fall into different segment)?

select 
case 
when Aggregate_rating >=4.5 then '4.5 & Above'
when Aggregate_rating >=4.0 then '4.0 & 4.4'
when Aggregate_rating >=3.5 then '3.5 & 3.9'
when Aggregate_rating >=3.0 then '3.0 & 3.4' 
when Aggregate_rating >=2.5 then '2.5 & 2.9'
Else 'Below 2.5'
End as Rating_segment,
count(*) as Restaurant_count
from rating ra
join Restaurant r on r.Restaurant_ID = ra.Restaurant_ID
group by Aggregate_rating
order by Aggregate_rating asc;  

-- Number of restaurants with a rating of 4.5 and above in each city
select r.City,count(r.Restaurant_ID) as count_Restaurant from Restaurant r
join Rating ra on ra.Restaurant_ID = r.Restaurant_ID
where ra.Aggregate_rating >= 4.5
group by r.City
order by count_Restaurant desc;

-- Most popular cuisines by the number of restaurant offering them 
select cuisines_varity,count(r.Restaurant_Name) 'count_of_restaurants'
from cuisines_varity c
join Restaurant r on r.Restaurant_ID = c.Restaurant_Id
group by cuisines_varity
order by 'count_of_restaurants' desc;

-- Average rating for each cuisine
select
c.cuisines_varity,round(avg(r.Aggregate_rating),1) as avg_rating
from rating r
join cuisines_varity c on r.Restaurant_ID = c.Restaurant_ID
group by r.Aggregate_rating,c.cuisines_varity
order by r.Aggregate_rating desc;  

-- Cuisine with the highest votes per restaurant
select c.cuisines_varity,max(ra.votes) as votes,r.Restaurant_name from cuisines_varity c
join Rating ra on ra.Restaurant_ID = c.Restaurant_Id
join Restaurant r on r.Restaurant_ID = c.Restaurant_Id
group by c.cuisines_varity,r.Restaurant_name
order by votes desc;

-- Number of restaurants per city/locality
select city,Locality,count(Restaurant_ID) as No_of_restaurant from Restaurant
group by city,Locality
order by No_of_restaurant desc;

-- location with highest number of restaurants per square kilometer
select r.Restaurant_id, r.Restaurant_Name,l.latitude,l.longitude,RADIANS(Latitude) as lat_rad,RADIANS(Longitude) as lon_rad 
from Restaurant r
join location l on l.Restaurant_ID = r.Restaurant_ID;

with LocationGrid as(
select r.Restaurant_id, r.Restaurant_Name,round(l.latitude,3) as lat_grid ,round(l.longitude,3) as lon_grid 
from Restaurant r
join location l on l.Restaurant_ID = r.Restaurant_ID
)

select top 10 lat_grid,lon_grid,count(Restaurant_id) as restaurant_count 
from LocationGrid
group by lat_grid,lon_grid
order by restaurant_count desc;

-- Percentage of Restaurants offering online delivary vs.those offering table bookings
select round((sum(case when Has_Online_delivery='YES' THEN 1 ELSE 0 END)*100.0/count(Restaurant_id)),1)as percentage_online_delivery,
round((sum(case when Has_Table_booking= 'Yes' THEN 1 ELSE 0 END)*100.0/count(Restaurant_id)),1)as percentage_table_booking
from Booking;

-- Percentage of Restaurants delivaring at the Moment vs. Total Restaurants
select round((SUM(case when Is_delivering_now = 'YES' then 1 else 0 end)*100.0/count(Restaurant_id)),1) as percentage_delivering_now
from Booking;

-- Average cost for two people per city/locality
select avg(c.Average_Cost_for_two) as 'avg_cost_for_two',r.city,r.Locality
from Cuisines c
join Restaurant r on r.Restaurant_ID = c.Restaurant_ID
group by r.city,r.Locality
order by avg_cost_for_two desc;

--Distribution of Restaurant by price range
select cuisines_varity ,
(case when Average_Cost_for_two <= 250000 then 'budget' 
	when Average_Cost_for_two > 250000 and Average_Cost_for_two < 500000 then 'Mid-budget'
	else 'Premium'
END) as Price_range,
Average_Cost_for_two
from Cuisines c
join cuisines_varity cv on cv.Restaurant_Id = c.Restaurant_ID
group by cuisines_varity,Average_Cost_for_two
order by Average_Cost_for_two desc;

-- Restaurants with the highest number of votes

select top 3 r.Restaurant_Name,sum(ra.Votes) as votes 
from Restaurant r
join Rating Ra on ra.Restaurant_ID = r.Restaurant_ID
group by r.Restaurant_Name,r.City
order by votes desc;

-- Cities with the highest voter engagement per restaurant

select r.City, sum(ra.Votes) as votes,r.Restaurant_Name
from Restaurant r
join Rating ra on ra.Restaurant_ID = r.Restaurant_ID
group by r.Restaurant_Name,r.City
order by votes desc;

-- Heatmap of restaurants with ratings above 4.0 using latitude and longitude data
select l.latitude,l.longitude,round(r.Aggregate_rating,2)
from rating r
join Location l on r.Restaurant_ID = l.Restaurant_ID
where r.Aggregate_rating > 4.0;

-- Average rating for restaurants offering table booking vs.those without

select round(avg(case when b.has_table_booking= 'Yes' then r.Aggregate_rating END),2) as avg_rating_with_table_booking,
round(avg(case when b.Has_Table_booking = 'No' then r.Aggregate_rating END),2) as avg_rating_with_table_booking
from Booking b
join Rating r on b.Restaurant_ID = r.Restaurant_ID;


-- Average rating for restaurants with online delivery vs. those without
select round(avg(case when b.Has_Online_delivery= 'Yes' then r.Aggregate_rating END),2) as avg_rating_with_Online_delivery,
round(avg(case when b.Has_Online_delivery = 'No' then r.Aggregate_rating END),2) as avg_rating_with_Online_delivery
from Booking b
join Rating r on b.Restaurant_ID = r.Restaurant_ID;

-- Percentage of restaurants rated as Excellent, Very Good, Good, Average, poor, not rated
select rating_text,
count(*) as total_count,
round(count(*)*100.0/(select count(*) from rating),2) as percentage
from Rating 
group by Rating_text;

-- Correlation between average rating and average cost
With RatingAndCost as (
select c.Restaurant_ID ,
cast(c.average_cost_for_two as float)as avg_cost,
cast(r.aggregate_rating as float) as avg_rating
from Cuisines c
join rating r on c.Restaurant_ID = r.Restaurant_ID
)select 
(count(*) * Sum(avg_cost * avg_rating) - Sum(avg_cost) * Sum(avg_rating))/
(SQRT(count(*) * SUM(POWER(avg_cost,2)) - POWER(SUM(avg_cost),2)) * 
SQRT(Count(*) * SUM(POWER(avg_cost,2)) - POWER(SUM(avg_rating),2))
) as correlation_coefficient
from RatingAndCost;

-- Price range that receives the highest ratings
select c.Price_range,round(avg(ra.aggregate_rating),2) as avg_rating
from Cuisines c
join Rating ra on c.Restaurant_ID = ra.Restaurant_ID
group by c.Price_range 
order by avg_rating desc;
