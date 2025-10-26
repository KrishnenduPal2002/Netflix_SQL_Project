--Netflix project
CREATE TABLE netflix(
	show_id VARCHAR(5),
	type VARCHAR(10),
	title VARCHAR(150),
	director VARCHAR(208),
	casts VARCHAR(1000),
	country VARCHAR(150),
	date_added VARCHAR(50),
	release_year INT,
	rating VARCHAR(10),
	duration VARCHAR(15),
	listed_in VARCHAR(200),
	description VARCHAR(250)
);
SELECT * FROM netflix;

SELECT COUNT(*) AS total_content FROM netflix;

SELECT DISTINCT type FROM netflix;

--15 Business Problems

--  1. Count the number of Movies vs TV Shows

SELECT type, COUNT(*) AS total_content
FROM netflix
GROUP BY type;


--  2. Find the most common rating for movies and TV shows

SELECT type, rating 
FROM
(SELECT type,
rating,
--rating
COUNT(*),
--MAX(rating) 
RANK() OVER(PARTITION BY type ORDER BY COUNT(*) DESC) AS ranking
FROM netflix
GROUP BY 1, 2
-- ORDER BY 1, 3 DESC;
) AS t1
WHERE ranking = 1;


--  3. List all movies released in a specific year(e.g. 2020)

SELECT * FROM netflix
WHERE type = 'Movie' AND release_year = 2020;


--  4. Find the top 5 countries  with the most content on Netflix

SELECT country , COUNT(title) FROM netflix
GROUP BY country
ORDER BY COUNT(title) DESC;  -- HERE WE HAVE A PROBLEM THAT SOME ROWS ARE FILLED WITH MORE THAN ONE COUNTRIES

-- SO FIRST WE HAVE TO CONVERT THOSE ROWS INTO ARRAYS THEN SEPARATE THEM INTO NEW COLUMN
--TO CONVERT, STRING TO ARRAY WE USE = STRING_TO_ARRAY
--TO SEPERATE THEM WE USE = UNNEST

SELECT UNNEST(STRING_TO_ARRAY(country, ',')), COUNT(show_id)
FROM netflix
GROUP BY country
ORDER BY COUNT(show_id) DESC
LIMIT 5;


--  5. Identify the longest movie?

SELECT MAX(duration) FROM(
SELECT type, duration FROM netflix 
WHERE type = 'Movie'
ORDER BY duration DESC);


--  6. Find the content added in the last 5 years.

--HERE , DATATYPE OF date_added IS VARCHAR..SO WE HAVE TO CONVERT VARCHAR TO DATE BY USING = TO_DATE 
SELECT * FROM netflix
WHERE TO_DATE(date_added, 'MONTH DD, YYYY') >= CURRENT_DATE - INTERVAL '5 years';


--  7. Find all the movies / TV shows by director 'Rajiv Chilaka'.

SELECT UNNEST(STRING_TO_ARRAY(director, ',')), * -- if we use GROUP BY we can't use SELECT * 
FROM netflix WHERE director = 'Rajiv Chilaka'
GROUP BY director; -- we can't use UNNREST because it extract all array elements only if there is used GROUP BY method

SELECT  * FROM netflix
WHERE director LIKE '%Rajiv Chilaka%'; --LIKE '%Rajiv Chilaka%' IS USED BECAUSE MANY ROWS OF DIRECTOR CONTAIN MULTIPLE NAMES


--  8. List all TV shows having more than 5 seasons.

SELECT * FROM netflix
WHERE 
	type = 'TV Show'
	AND
	SPLIT_PART(duration, ' ', 1) :: numeric > 5; -- SPLIT_PART is used to split 'x seasons' in duration... before ' ',  1st text is taken(eg. 5 season...SPLIT_PART will take 5 as text)
												 -- :: is used to convert the text into numeric


--  9. Count the number of content in each genre.

SELECT 
UNNEST(STRING_TO_ARRAY(listed_in, ',')), COUNT(show_id)
FROM netflix
GROUP BY 1;


--  10. Find each year and the average number of content release by India on netflix, 
--		return top 5 year with highest content release.

SELECT 
	EXTRACT(YEAR FROM TO_DATE(date_added, 'Month DD, YYYY')) as year, -- to EXTRACT year from date_addded column
	COUNT(*) as yearly_content,
	ROUND(                                                                                  -- ROUND function will round up the decimal number upto 2
	COUNT(*)::numeric/(SELECT COUNT(*) FROM NETFLIX WHERE country = 'India')::numeric * 100 -- to get the average, we are doing (yearly_content/total_content_per_year)
	,2)as avg_content_per_year
FROM netflix
WHERE country = 'India'
GROUP BY 1;


--  11. List all the movies that are documentries.


SELECT 
	SPLIT_PART(listed_in, ',', 1) , *
FROM netflix
WHERE 
type = 'Movie' 
AND 
SPLIT_PART(listed_in, ',', 1) = 'Documentaries';    -- HERE, A PROBLEM OCCURS..THAT IS IT MISSES THOSE ROWS WHICH CONTAIN SINGLE ENTRIES(eg. Documentaries)
												    --IT IS SPLITING THOSE ROWS WHICH CONTAINMORE THAN ONE ENTRIES.
--OTHER WAY

SELECT * FROM netflix
WHERE listed_in ILIKE '%documentaries%'


--  12. Find the all content without a director

SELECT * FROM netflix
WHERE director IS NULL;


--  13. Find how many movies, actor 'Salman Khan' apeared in last 10 years.

SELECT * FROM netflix
WHERE casts ILIKE '%Salman Khan%'
AND
release_year > EXTRACT(YEAR FROM CURRENT_DATE) - 10


-- 14. Find the top 10 actors who have apeared in the highest number of movies produced in India.

SELECT UNNEST(STRING_TO_ARRAY(casts, ',')) AS actors, COUNT(show_id) AS highest_movies
FROM(
SELECT * FROM netflix
WHERE country ILIKE '%india%'
)
GROUP BY 1
ORDER BY count(show_id) DESC
LIMIT 10;


--  15. Categorize content based on the presence of the keywords 'kill' and 'voilence' in the description field,
--      Label content containing these keyword as 'bad' and allother content as 'good, Count how many items fall into each category.


WITH new_table
AS(
SELECT 
* ,
	CASE
	WHEN description ILIKE '%kill%' OR
		 description ILIKE '%violence%' THEN 'Bad_Content'
		 ELSE 'Good_Content'
	END category
FROM netflix
)
SELECT category, COUNT(*) AS total_content
FROM new_table
GROUP BY 1;


