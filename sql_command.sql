select * from artist;
select * from canvas_size;
select * from image_link;
select * from museum;
select * from museum_hours;
select * from product_size;
select * from subject;
select * from work;

-- 1) Fetch all the paintings which are not displayed on any museums?
select name as paintings 
from work w
where w.museum_id is null;


-- 2) Are there museuems without any paintings?

select name 
from museum m
where not exists(select 1 from work w
					 where w.museum_id=m.museum_id);
					 
-- findings : There is no museum without paintings
					 
-- 3) How many paintings have an asking price of more than their regular price? 

select count(distinct(work_id))
from product_size
where sale_price > regular_price;

-- findings : There is no product which asking price is more than their regular price.

-- 4) Identify the paintings whose asking price is less than 50% of its regular price

select distinct(ps.work_id) painting_id, w.name painting_name
from product_size ps
join work w
on ps.work_id=w.work_id
where ps.sale_price < (0.5*ps.regular_price);

-- 5) Which canva size costs the most?


select * from canvas_size
where size_id = (select size_id from product_size
order by sale_price desc
limit 1)


-- 6) Delete duplicate records from work, product_size, subject and image_link tables

-- work
delete from work
where ctid not in(
	select min(ctid) from work
	group by work_id, name, artist_id, style, museum_id
)

-- sebject
delete from subject
where ctid not in(
	select min(ctid) from subject
	group by work_id, subject
)

-- product_size
delete from product_size
where ctid not in(
	select min(ctid) from product_size
	group by work_id, sale_price, regular_price, size_id
)

-- image_link
delete from image_link
where ctid not in(
	select min(ctid) from image_link
	group by work_id, url
)

-- 7) Identify the museums with invalid city information in the given dataset

select name, city from museum
where city ~ '^[0-9]';

-- 8) Museum_Hours table has 1 invalid entry. Identify it and remove it.

delete from museum_hours
where ctid not in(
	select min(ctid) from museum_hours
	group by museum_id, day,open, close
)


-- 9) Fetch the top 10 most famous painting subject

select subject, count(*) as number_of_use from subject
group by subject
order by number_of_use desc
limit 10;

-- 10) identify the museums which are open both Sunday and Monday, Display museum name, city.
select m.name, m.city
from museum_hours mh1
join museum m on mh1.museum_id=m.museum_id
where mh1.day='Sunday'
and exists (select * from museum_hours mh2
		   where mh1.museum_id=mh2.museum_id
		   and mh2.day='Monday');	   
		   
		   
-- 11) How many museums are open every single day?

select count(*) as no_of_museum from
(select museum_id, count(*) from museum_hours
group by museum_id
having count(distinct day)=7)


-- 12) Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum)


select w.museum_id, m.name, m.city, no_of_paint 
from (
select museum_id, count(*) as no_of_paint
from work
group by museum_id
order by no_of_paint desc
limit 5 offset 1) w join museum m on w.museum_id=m.museum_id

-- 13) Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)

select w.artist_id, a.full_name, no_of_paint
from (select artist_id, count(*) as no_of_paint from work
group by artist_id
order by no_of_paint desc
limit 5
) w join artist a on  w.artist_id=a.artist_id

-- 14) Display the 3 least popular canva sizes

select * from canvas_size
where size_id in (select size_id
from product_size
group by size_id
order by count(*)
limit 4)

-- 15) Which museum is open for the longest during a day. Dispay museum name, state and hours open and which day?

select mh.museum_id, m.name, m.city, m.country, day, interval from (
select museum_id, 
		day,  
		to_timestamp(close, 'HH:MI AM')-to_timestamp(open, 'HH:MI: PM') as interval
from museum_hours
where to_timestamp(close, 'HH:MI AM')-to_timestamp(open, 'HH:MI: PM')=(
select max(to_timestamp(close, 'HH:MI AM')-to_timestamp(open, 'HH:MI: PM')) from museum_hours)) as mh
join museum m on mh.museum_id=m.museum_id


-- 16) Which museum has the most no of most popular painting style?

select w.museum_id, m.name, style
from work w join museum m on w.museum_id=m.museum_id
where style=
(select style from work
group by style
order by count(*) desc limit 1) and w.museum_id is not null
group by w.museum_id, m.name, style
order by count(*) desc
limit 1

-- 17) Identify the artists whose paintings are displayed in multiple countries?

select w.artist_id, a.full_name, w.no_of_country
from(
select artist_id, count(distinct country) as no_of_country
from work w join museum m on w.museum_id=m.museum_id
group by artist_id
having count(distinct country)>1) w join artist a on w.artist_id=a.artist_id
order by w.no_of_country desc

-- 18) Display the country and the city with most no of museums. Output 2 seperate columns to mention the 
--city and country.  If there are multiple value, seperate them with comma.

select country, city, count(*) no_of_museum
from museum
group by country, city
order by no_of_museum desc
limit 3;

-- 19) Identify the artist and the museum where the most expensive and least expensive painting is placed
-- Display the artist name, sale_price, painting name, museum name, museum city and canvas label

with cte as 
	(select *
	, rank() over(order by sale_price desc) as rnk
	, rank() over(order by sale_price ) as rnk_asc
	from product_size )
select w.name as painting
, cte.sale_price
, a.full_name as artist
, m.name as museum, m.city
, cz.label as canvas
from cte
join work w on w.work_id=cte.work_id
join museum m on m.museum_id=w.museum_id
join artist a on a.artist_id=w.artist_id
join canvas_size cz on cz.size_id = cte.size_id::NUMERIC
where rnk=1 or rnk_asc=1;
	
-- 20) Which country has the 5th highest no of paintings?

select m.country, count(*) no_of_painting
from work w
join museum m on w.museum_id=m.museum_id
group by country
order by no_of_painting desc
limit 1 offset 4;

-- 21) Which are the 3 most popular and 3 least popular painting styles?

	with cte as 
		(select style, count(1) as cnt
		, rank() over(order by count(1) desc) rnk
		, count(1) over() as no_of_records
		from work
		where style is not null
		group by style)
	select style
	, case when rnk <=3 then 'Most Popular' else 'Least Popular' end as remarks 
	from cte
	where rnk <=3
	or rnk > no_of_records - 3;


-- 22) Which artist has the most no of Portraits paintings outside USA?. Display artist name, no of paintings
--and the artist nationality.

	select full_name as artist_name, nationality, no_of_paintings
	from (
		select a.full_name, a.nationality
		,count(1) as no_of_paintings
		,rank() over(order by count(1) desc) as rnk
		from work w
		join artist a on a.artist_id=w.artist_id
		join subject s on s.work_id=w.work_id
		join museum m on m.museum_id=w.museum_id
		where s.subject='Portraits'
		and m.country != 'USA'
		group by a.full_name, a.nationality) x
	where rnk=1;	



