-- In this question, you'll get to practice correlated subqueries and learn about the LATERAL keyword.
--Note: This could be done using window functions, but we'll do it in a different way in order to revisit 
--correlated subqueries and see another keyword - LATERAL.
--1 a. First, write a query utilizing a correlated subquery to find the team with the most wins from each 
--league in 2016.
-- If you need a hint, you can structure your query as follows:

-- SELECT DISTINCT lgid, ( ) FROM teams t WHERE yearid = 2016;

--team with most wins
-----------------------------------------------------------------------
----without subquery
-----------------------------------------------------------------------
SELECT 
	DISTINCT lgid,
	teamid,
	SUM(w) AS most_wins
FROM teams
WHERE yearid = 2016
GROUP BY lgid, teamid
ORDER BY most_wins DESC
LIMIT 2
--	"NL"	"CHN"	103 , "AL"	"TEX"	95
-----------------------------------------------------------------------
----with subquery
-----------------------------------------------------------------------
SELECT 
	*
FROM (SELECT 
		DISTINCT lgid,
		teamid, 
		SUM(w) AS wins
	   FROM teams
	   WHERE yearid =2016
	   GROUP BY lgid, teamid
	   ORDER BY wins DESC) 

-------------------------------------------------------------------------------------------------------------
--1 b. One downside to using correlated subqueries is that you can only return exactly one row and one column.
--This means, for example that if we wanted to pull in not just the teamid but also the number of wins, we 
--couldn't do so using just a single subquery. (Try it and see the error you get). Add another correlated
--subquery to your query on the previous part so that your result shows not just the teamid but also the 
--number of wins by that team.

-------------------------------------------------------------------------------------------------------------
--1 c. If you are interested in pulling in the top (or bottom) values by group, you can also use the 
--DISTINCT ON expression (https://www.postgresql.org/docs/9.5/sql-select.html#SQL-DISTINCT). 
--Rewrite your previous query into one which uses DISTINCT ON to return the top team by league in terms of 
--number of wins in 2016. Your query should return the league, the teamid, and the number of wins.

-------------------------------------------------------------------------------------------------------------
--1 d. If we want to pull in more than one column in our correlated subquery, another way to do it is to make
--use of the LATERAL keyword
--(https://www.postgresql.org/docs/9.4/queries-table-expressions.html#QUERIES-LATERAL). 
--This allows you to write subqueries in FROM that make reference to columns from previous FROM items. 
--This gives us the flexibility to pull in or calculate multiple columns or multiple rows (or both). 
--Rewrite your previous query using the LATERAL keyword so that your result shows the teamid and number
--of wins for the team with the most wins from each league in 2016.

-- If you want a hint, you can structure your query as follows:

SELECT 
	* 
FROM (SELECT DISTINCT lgid FROM teams WHERE yearid = 2016) AS leagues, 
LATERAL (SELECT teamid, w AS wins FROM teams 
WHERE yearid = 2016 AND leagues.lgid=teams.lgid 
GROUP BY teamid, w
ORDER BY wins DESC
LIMIT 3) as top_teams;

-------------------------------------------------------------------------------------------------------------
-- 1e. Finally, another advantage of the LATERAL keyword over using correlated subqueries is that you return
--multiple result rows. (Try to return more than one row in your correlated subquery from above and see
--what type of error you get). Rewrite your query on the previous problem sot that it returns the top 3 
--teams from each league in term of number of wins. Show the teamid and number of wins.

-- Another advantage of lateral joins is for when you create calculated columns. In a regular query, when 
--you create a calculated column, you cannot refer it it when you create other calculated columns. This is 
--particularly useful if you want to reuse a calculated column multiple times. For example,
SELECT teamid, w, l, w + l AS total_games, w*100.0 / total_games AS winning_pct 
FROM teams WHERE yearid = 2016 ORDER BY winning_pct DESC;
-- results in the error that "total_games" does not exist. However, I can restructure this query using the
--LATERAL keyword.

SELECT teamid, 
		w,
		l,
		total_games,
		w*100.0 / total_games AS winning_pct 
FROM teams t,
LATERAL (SELECT w + l AS total_games ) AS tg
WHERE yearid = 2016 
ORDER BY winning_pct DESC;
------------------------------------------------------------------------------------------------------------

-- 2a. Write a query which, for each player in the player table, assembles their birthyear, birthmonth, 
--and birthday into a single column called birthdate which is of the date type.
SELECT 
	namefirst,
	namelast,
	birthyear,
	birthmonth,
	birthday
FROM people
--LIMIT 2
------------------------------------------------------------------------
SELECT 
	CONCAT(namefirst, ' ', namelast) AS full_name,
	--CONCAT (birthyear,'-',birthmonth,'-',birthday) AS birthdate 
	TO_DATE(
		CONCAT(
		birthyear::text,'-',
		LPAD(birthmonth::text,2,'0'), '-', 
		LPAD(birthday::text,2,'0')
		), 'YYYY-MM-DD') AS birthdate 
FROM people
WHERE birthyear IS NOT NULL
AND birthmonth IS NOT NULL
AND birthday IS NOT NULL

-------------------------------------------------------------------------------------------------------------
-- 2b. Use your previous result inside a subquery using LATERAL to calculate for each player their age at 
--debut and age at retirement. (Hint: It might be useful to check out the PostgreSQL date and time functions
--https://www.postgresql.org/docs/8.4/functions-datetime.html).

SELECT 
	full_name,
	birthdate,
	debut,
	finalgame,
	age.debut_age,
	age.retirement_age
FROM(
	SELECT
	CONCAT(namefirst, ' ', namelast) AS full_name,
	TO_DATE(
		CONCAT(
		birthyear::text,'-',
		LPAD(birthmonth::text,2,'0'), '-', 
		LPAD(birthday::text,2,'0')
		), 'YYYY-MM-DD') AS birthdate,
		debut,
		finalgame
	FROM people
	WHERE birthyear IS NOT NULL
	AND birthmonth IS NOT NULL
	AND birthday IS NOT NULL
	) subquery,
LATERAL (SELECT 
		 ROUND((TO_DATE(debut,'YYYY-MM-DD') - birthdate + 1)/365.25) AS debut_age, 
		 ROUND((TO_DATE(finalgame,'YYYY-MM-DD') - birthdate +1)/365.25) AS retirement_age) AS age

-------------------------------------------------------------------------------------------------------------
--2c. Who is the youngest player to ever play in the major leagues? --"Willie McGill" debut age 16
SELECT 
	full_name,
	birthdate,
	debut,
	finalgame,
	age.debut_age,
	age.retirement_age,
	league
FROM(
	SELECT
	playerid,
	CONCAT(namefirst, ' ', namelast) AS full_name,
	TO_DATE(
		CONCAT(
		birthyear::text,'-',
		LPAD(birthmonth::text,2,'0'), '-', 
		LPAD(birthday::text,2,'0')
		), 'YYYY-MM-DD') AS birthdate,
		debut,
		finalgame,
		appearances.lgid  AS league
	FROM people
	INNER JOIN appearances USING (playerid)
	WHERE birthyear IS NOT NULL
	AND birthmonth IS NOT NULL
	AND birthday IS NOT NULL
	AND appearances.lgid IN ('AA', 'UA', 'PL', 'FL')
	) subquery,
LATERAL (SELECT 
		 ROUND((TO_DATE(debut,'YYYY-MM-DD') - birthdate + 1)/365.25) AS debut_age, 
		 ROUND((TO_DATE(finalgame,'YYYY-MM-DD') - birthdate +1)/365.25) AS retirement_age) AS age
GROUP BY full_name, birthdate, debut, finalgame, debut_age, retirement_age, league
ORDER BY age.debut_age
-------------------------------------------------------------------------------------------------------------
-- 2d. Who is the oldest player to player in the major leagues? You'll likely have a lot of null values
--resulting in your age at retirement calculation. Check out the documentation on sorting rows here
--https://www.postgresql.org/docs/8.3/queries-order.html about how you can change how null values are sorted.

-- "Charlie Miller" debut age 38

SELECT 
	full_name,
	birthdate,
	debut,
	finalgame,
	age.debut_age,
	age.retirement_age,
	league
FROM(
	SELECT
	playerid,
	CONCAT(namefirst, ' ', namelast) AS full_name,
	TO_DATE(
		CONCAT(
		birthyear::text,'-',
		LPAD(birthmonth::text,2,'0'), '-', 
		LPAD(birthday::text,2,'0')
		), 'YYYY-MM-DD') AS birthdate,
		debut,
		finalgame,
		appearances.lgid  AS league
	FROM people
	INNER JOIN appearances USING (playerid)
	WHERE birthyear IS NOT NULL
	AND birthmonth IS NOT NULL
	AND birthday IS NOT NULL
	AND appearances.lgid IN ('AA', 'UA', 'PL', 'FL')
	) subquery,
LATERAL (SELECT 
		 ROUND((TO_DATE(debut,'YYYY-MM-DD') - birthdate + 1)/365.25) AS debut_age, 
		 ROUND((TO_DATE(finalgame,'YYYY-MM-DD') - birthdate +1)/365.25) AS retirement_age) AS age
GROUP BY full_name, birthdate, debut, finalgame, debut_age, retirement_age, league
ORDER BY age.debut_age DESC NULLS LAST
-------------------------------------------------------------------------------------------------------------
-- For this question, you will want to make use of RECURSIVE CTEs 
--(see https://www.postgresql.org/docs/13/queries-with.html). 
--The RECURSIVE keyword allows a CTE to refer to its own output. Recursive CTEs are useful for navigating
--network datasets such as social networks, logistics networks, or employee hierarchies 
--(who manages who and who manages that person). To see an example of the last item, see this tutorial: 
--https://www.postgresqltutorial.com/postgresql-recursive-query/. In the next couple of weeks, 
--you'll see how the graph database Neo4j can easily work with such datasets, but for now we'll see how 
--the RECURSIVE keyword can pull it off (in a much less efficient manner) in PostgreSQL. 
--(Hint: You might find it useful to look at this blog post when attempting to answer the following questions
--: https://data36.com/kevin-bacon-game-recursive-sql/.)


-- 3a. Willie Mays holds the record of the most All Star Game starts with 18. How many players started in an
--All Star Game with Willie Mays? (A player started an All Star Game if they appear in the allstarfull table 
--with a non-null startingpos value).
-----------------------------------------------------------------------------------------------
---Find the player id of Willie Mays ----"mayswi01"
-----------------------------------------------------------------------------------------------
SELECT 
	playerid,
	namefirst,
	namelast,
FROM people
WHERE namefirst = 'Willie'
AND namelast = 'Mays'

SELECT * FROM allstarfull

---------------------------------------------------------------------------------------------------

WITH RECURSIVE williemays AS(
SELECT -- Willie Mays start_year = 1957
	a.playerid,
	p.namefirst,
	p.namelast,
	MIN(a.yearid) AS start_year,
	a.startingpos
FROM allstarfull a
INNER JOIN people p
USING (playerid)
WHERE startingpos IS NOT NULL
AND playerid = 'mayswi01'
GROUP BY playerid, namefirst, namelast, startingpos
UNION ALL
SELECT --All other players who started in the year 1957
	a1.playerid,
	p1.namefirst,
	p1.namelast,
	MIN(a1.yearid) AS start_year,
	a1.startingpos
FROM allstarfull a1
INNER JOIN people p1
USING (playerid)
INNER JOIN williemays
USING (yearid)
WHERE a1.startingpos IS NOT NULL
AND a1.playerid <> 'mayswi01'
AND a1.yearid = williemays.start_year
GROUP BY playerid, namefirst, namelast, startingpos
)
SELECT * FROM williemays


-------------------------------------------------------------------------------------------------------------

--3b. How many players didn't start in an All Star Game with Willie Mays but started an All Star Game with
--another player who started an All Star Game with Willie Mays? For example, Graig Nettles never started an
--All Star Game with Willie Mayes, but he did star the 1975 All Star Game with Blue Vida who started the 
--1971 All Star Game with Willie Mays.


-------------------------------------------------------------------------------------------------------------
-- 3c. We'll call two players connected if they both started in the same All Star Game. Using this, 
--we can find chains of players. For example, one chain from Carlton Fisk to Willie Mays is as follows: 
--Carlton Fisk started in the 1973 All Star Game with Rod Carew who started in the 1972 All Star Game 
--with Willie Mays. Find a chain of All Star starters connecting Babe Ruth to Willie Mays.

-------------------------------------------------------------------------------------------------------------
-- 3d. How large a chain do you need to connect Derek Jeter to Willie Mays?

-------------------------------------------------------------------------------------------------------------
