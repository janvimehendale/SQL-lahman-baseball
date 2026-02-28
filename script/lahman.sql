-- **Initial Questions**

-- 1. What range of years for baseball games played does the provided database cover? 
--range of years - appearances

----------------------------------------------------------------------------
----Checking appearances table
----------------------------------------------------------------------------

SELECT
	*	
FROM appearances
LIMIT 5;

SELECT
	DISTINCT yearid
FROM appearances
GROUP BY yearid;
----------------------------------------------------------------------------
-------------------1. range of years --1871 to 2016
----------------------------------------------------------------------------
SELECT
	MIN(yearid) AS min,--1871
	MAX(yearid) AS max --2016
FROM appearances
LIMIT 1;
--1871 to 2016
------------------------------------------------------------------------------------------------------
-- 2. Find the name and height of the shortest player in the database. How many games did he play in? 
--What is the name of the team for which he played?
   
--name and height - people
-- no of games - appearances
--team name - teams
----------------------------------------------------------------------------
--2. Find shortest player - "Eddie"	"Gaedel"	43 "gaedeed01"
----------------------------------------------------------------------------
SELECT 
	--p.playerid,
	CONCAT(p.namefirst, ' ', p.namelast) AS full_name,
	MIN(p.height) AS height,
	a.g_all AS games_played,
	t.name AS team_name -- "St. Louis Browns"
--	(SELECT teamid FROM appearances)- getting error 
			-- more than one row returned by a subquery used as an expression
FROM people p
INNER JOIN appearances a -- teamid SLA
USING (playerid)
INNER JOIN teams t
USING (teamid)
WHERE playerid = 'gaedeed01'
GROUP BY full_name, playerid, a.teamid, t.name, a.g_all
ORDER by height
--"Eddie"	"Gaedel"	"Edward Carl"	43	"SLA"	1	"St. Louis Browns"

--------------------------------------------------------------------------------------------------------
-- 3. Find all players in the database who played at Vanderbilt University. Create a list showing each
--player’s first and last names as well as the total salary they earned in the major leagues. 
--Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the
--most money in the majors?
--all players first name, last name - people
-- total salary - salaries
-- Vanderbilt -school name - schools
			-- schoolid - collegeplaying
-- league name - homegames 
---NEED HELP
----------------------------------------------------------------------------
---List of players and salary played at Vanderbilt-----
----------------------------------------------------------------------------
SELECT DISTINCT schoolname, schoolid FROM schools ORDER BY schoolname DESC;
----------------------------------------------------------------------------

SELECT
	c.playerid,
	c.schoolid,
	SUM(s.salary)::NUMERIC::MONEY AS total_salary,
	s.lgid AS league
FROM collegeplaying c
INNER JOIN salaries s USING (playerid)
WHERE schoolid = 'vandy'
GROUP BY c.playerid,
	c.schoolid,
	s.lgid
ORDER BY total_salary DESC;

----------------------------------------------------------------------------
---List of players with name and salary played at Vanderbilt-----
----------------------------------------------------------------------------

SELECT
	CONCAT(p.namefirst, ' ', p.namelast) AS full_name, 
	SUM(s.salary)::NUMERIC::MONEY AS total_salary
FROM collegeplaying c
INNER JOIN salaries s USING (playerid)
INNER JOIN people p USING (playerid)
WHERE schoolid = 'vandy'
GROUP BY full_name
ORDER BY total_salary DESC;
	

----------------------------------------------------------------------------
-----checking data from salaries table for major leagues ---none found
----------------------------------------------------------------------------

SELECT * FROM salaries
WHERE lgid IN ('AA', 'UA', 'PL', 'FL');

----------------------------------------------------------------------------
---List of players name, salary who played at Vanderbilt--subquery IN WHERE clause
----------------------------------------------------------------------------
SELECT
	CONCAT(p.namefirst, ' ', p.namelast) AS full_name, 
--	(SELECT CONCAT(p.namefirst, ' ', p.namelast)
	--	FROM people
		--WHERE p.playerid = c.playerid)AS full_name, --ERROR:  more than one row returned by a subquery used as an expression 
	SUM(s.salary::NUMERIC::MONEY) AS total_salary
FROM people p
INNER JOIN salaries s USING (playerid)
WHERE p.playerid IN 
	(SELECT c.playerid
	FROM collegeplaying c 
	WHERE schoolid = 'vandy' 
	GROUP BY c.playerid
	)
GROUP BY full_name 
ORDER BY total_salary DESC;
-------------------------------------------------------------------------------------------------------
-- 4. Using the fielding table, group players into three groups based on their position: label players
--with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and 
--those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these 
--three groups in 2016.
--fielding position

----------------------------------------------------------------------------
--Categorizing the positions
----------------------------------------------------------------------------
SELECT 
CASE WHEN pos = 'OF' THEN 'Outfield'
	 WHEN pos IN ('P', 'C') THEN 'Battery'
	 WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield' 
	 ELSE 'missing' END AS position,
	 SUM(po) AS total_putouts
FROM fielding
WHERE yearid = 2016
GROUP BY position
--------------------------------------------------------------------------------------------------------
-- 5. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report
--to 2 decimal places. Do the same for home runs per game. Do you see any trends?
   
--avg(strikeouts) decade 1920 onwards, 
--avg(homeruns)

----------------------------------------------------------------------------
---Calculating avg strikeouts and homeruns
----------------------------------------------------------------------------

SELECT
	yearid/10*10 AS decade,
	ROUND(SUM(SO)::NUMERIC/SUM(g)::NUMERIC,2) AS avg_strikeouts,
	ROUND(SUM(HR)::NUMERIC/SUM(g)::NUMERIC,2) AS avg_homeruns
FROM teams
WHERE yearid >= 1920
GROUP BY decade
ORDER BY decade--pattern - avg strikeouts increased every decade except 1970 where it dropped a
--little than last year but increased the following year.

--------------------------------------------------------------------------------------------------------
-- 6. Find the player who had the most success stealing bases in 2016, where __success__ is measured as
--the percentage of stolen base attempts which are successful. (A stolen base attempt results either in 
--a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen
--bases.
--playerid/ name - 2016  
--stealing bases >20
--percentage

----------------------------------------------------------------------------
----List of players with stolen base and attempts
----------------------------------------------------------------------------

SELECT
	--(SELECT CONCAT(p.namefirst, ' ', p.namelast)AS full_name
	--	FROM people p),-------------------GETTING ERROR
	CONCAT(p.namefirst, ' ', p.namelast)AS full_name,
	SUM(b.SB) AS sb_count,
	(b.SB+b.CS) AS attempts,
	ROUND(SUM(b.SB)::NUMERIC*100/SUM(b.SB+b.CS)::NUMERIC,2) AS percentage
FROM batting b
INNER JOIN people p USING (playerid)
WHERE b.yearid = 2016
AND (b.SB+b.CS)>=20 
GROUP BY b.playerid, p.namefirst, p.namelast, b.sb, b.cs
ORDER BY percentage DESC

--------------------------------------------------------------------------------------------------------
-- 7.  From 1970 – 2016, what is the largest number of wins for a team that did not win the world 
--series? What is the smallest number of wins for a team that did win the world series? Doing this
--will probably result in an unusually small number of wins for a world series champion – determine 
--why this is the case. Then redo your query, excluding the problem year. How often from 1970 – 2016
--was it the case that a team with the most wins also won the world series? What percentage of the time?

--yearid 1970 -2016
--count(max(win))
--count(min(win))
----------------------------------------------------------------------------
----Max wins from 1970-2016 in descending order - 1294 rows - Most won -116
----------------------------------------------------------------------------

SELECT
	yearid,
	w AS wins
FROM teams
WHERE yearid >= 1970
GROUP BY yearid, w, teamid
ORDER BY wins DESC 

----------------------------------------------------------------------------
--largest number of wins for a team that did not win the world series 
-- 116 -(with and without problem year)
----------------------------------------------------------------------------
SELECT
	yearid,
	MAX(w) AS wins
FROM teams
WHERE yearid >= 1970
AND wswin = 'N'
--AND yearid NOT IN (1981)
GROUP BY yearid
ORDER BY wins DESC 

----------------------------------------------------------------------------
--smallest number of wins for a team that did win the world series 
-- 63 wins with problem year
-- 83 wins without problem year
----------------------------------------------------------------------------
SELECT
	yearid,--46 rows w/year, 45 wo/year
	MIN(w) AS wins
FROM teams
WHERE yearid >= 1970
AND yearid NOT IN (1981)
AND wswin = 'Y'
GROUP BY yearid 
ORDER BY wins

----------------------------------------------------------------------------
-- most wins including the world series - 114 (with and without problem year)
----------------------------------------------------------------------------
SELECT
	yearid,--46 rows
	MAX(w) AS wins
FROM teams
WHERE yearid >= 1970
AND wswin = 'Y'
--AND yearid NOT IN (1981, 1994)
GROUP BY yearid
ORDER BY wins DESC 
----------------------------------------------------------------------------
-- Find problem year-- 1981 with 1389 wins, 1994 with 1599 wins
----------------------------------------------------------------------------
SELECT 
	yearid,
	SUM(w) AS wins
FROM teams
WHERE yearid >= 1970
GROUP BY yearid
ORDER BY wins
---------------------------------------------------------------------------------
-- Team with the most wins also won the world series? "NYA"	114  
---------------------------------------------------------------------------------
SELECT
	yearid,--45 rows
	MAX(w) AS wins
FROM teams
WHERE yearid >= 1970
AND yearid NOT IN (1981)
AND wswin = 'Y'
GROUP BY yearid
ORDER BY wins DESC 

---------------------------------------------------------------------------------
-- What percentage of the time
---------------------------------------------------------------------------------
WITH most_wins AS(
SELECT --46 rows
	yearid,
	MAX(w) AS w
FROM teams
WHERE yearid >= 1970
AND yearid NOT IN (1981)
GROUP BY yearid
ORDER BY w DESC 
),

most_win_teams AS(
SELECT --2835 rows
	yearid,
	name AS team_name,
	wswin
FROM teams
INNER JOIN most_wins USING (yearid, w)---52 rows
)
SELECT 
	(SELECT
		COUNT(*) 
		FROM most_win_teams
		WHERE wswin = 'N')--39 rows
		*100/ 
			(SELECT 
				COUNT(*)
			FROM most_win_teams) AS percentage
;
--------------------------------------------------------------------------------------------------------
-- 8. Using the attendance figures from the homegames table, find the teams and parks which had the 
--top 5 average attendance per game in 2016 (where average attendance is defined as total attendance
--divided by number of games). Only consider parks where there were at least 10 games played. Report
--the park name, team name, and average attendance. Repeat for the lowest 5 average attendance.
--attendance - homegames
--teams
--parks
--games =>10

(SELECT 
	--(SELECT park_name FROM parks),
	p.park_name,
	h.attendance,
	t.name,
	h.games,
	h.attendance/ h.games AS attendance_per_game
FROM homegames h
INNER JOIN parks p ON p.park = h.park
INNER JOIN teams t ON t.teamidlahman45 = h.team AND t.yearid = h.year
WHERE h.year = 2016
AND games >=10
ORDER BY attendance_per_game DESC
LIMIT 5)

UNION

(SELECT 
	--(SELECT park_name FROM parks),
	p.park_name,
	h.attendance,
	t.name,
	h.games,
	h.attendance/ h.games AS attendance_per_game
FROM homegames h
INNER JOIN parks p ON p.park = h.park
INNER JOIN teams t ON t.teamidlahman45 = h.team AND t.yearid = h.year
WHERE h.year = 2016
AND games >=10
ORDER BY attendance_per_game ASC
LIMIT 5)
------------------------------------------------------------------------------------------------------
-- 9. Which managers have won the TSN Manager of the Year award in both the National League (NL) and
--the American League (AL)? Give their full name and the teams that they were managing when they won 
--the award.

--manager full name
--team
--NL and AL

WITH both_league AS(
SELECT --2 player ids
	playerid
FROM awardsmanagers
WHERE awardid = 'TSN Manager of the Year'
AND lgid IN ('AL' ,'NL')
GROUP BY playerid
HAVING COUNT(DISTINCT lgid)= 2
)
SELECT
	CONCAT(p.namefirst, ' ', p.namelast) AS full_name,
	a.yearid,
	a.lgid,
	t.name
FROM people p
INNER JOIN both_league USING (playerid)
INNER JOIN awardsmanagers a USING(playerid)
INNER JOIN managers m USING (playerid,lgid, yearid)
INNER JOIN teams t USING (teamid,lgid, yearid)
WHERE awardid = 'TSN Manager of the Year' -- need to mention again to get the correct results
ORDER by full_name

--------------------------------------------------------------------------------------------------------
-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players
--who have played in the league for at least 10 years, and who hit at least one home run in 2016. 
--Report the players' first and last names and the number of home runs they hit in 2016.

--first name - people
--lastname- people
-- yearid = 2016
--MAX(homeruns)--batting
--years >10
---------------------------------------------------------------------------------
--  List of players who scored atleast 1 hr in 2016
---------------------------------------------------------------------------------
SELECT 
	CONCAT(p.namefirst, ' ', p.namelast) AS full_name,
	b.hr
FROM batting b
INNER JOIN people p USING (playerid)
WHERE yearid = 2016 
--AND hr> 0
GROUP BY playerid, full_name, hr, b.yearid

---------------------------------------------------------------------------------
--  List of players who scored atleast 1 hr overall, played more than 10 years
---------------------------------------------------------------------------------
WITH hr_all AS(
SELECT-- List of players who scored atleast 1 hr overall career
	b.playerid,
	CONCAT(p.namefirst, ' ', p.namelast) AS full_name,
	SUM(b.hr)AS total_runs,
	MIN(b.yearid) AS min_year,
	MAX(b.yearid) AS max_year,
	(MAX(b.yearid) - MIN(b.yearid)+ 1) AS years_played
FROM batting b
INNER JOIN people p USING (playerid)
--WHERE CONCAT(p.namefirst, ' ', p.namelast) = 'Justin Upton'
GROUP BY full_name, playerid
),
year_hr AS(--Max scores of all the seasons
		SELECT
		playerid,
		MAX(season_hr) AS yearhr
		FROM (
		SELECT playerid,
		yearid, 
		SUM(hr) AS season_hr
		FROM batting 
		GROUP BY yearid, playerid
		) AS season_runs
		GROUP BY playerid
),
--SELECT * FROM year_hr
hr_2016 AS(--Max scores of 2016
	SELECT playerid,
		   SUM(hr) AS hr2016
	FROM batting
	WHERE yearid = 2016
	GROUP BY playerid
	HAVING SUM(hr)>0
)
SELECT 
	hr_all.full_name,
--	hr_all.total_runs,
	hr_2016.hr2016
--	year_hr.yearhr
	FROM hr_all
INNER JOIN hr_2016 USING (playerid)
INNER JOIN year_hr USING (playerid)
WHERE  hr_2016.hr2016 > 0
AND hr_all.years_played >=10
AND hr_2016.hr2016 >= year_hr.yearhr; -- It is comparing the homeruns scored to max scored in other seasons
--------------------------------------------------------------------------------------------------------
-- **Open-ended questions**

-- 11. Is there any correlation between number of wins and team salary? Use data from 2000 and later to
--answer this question. As you do this analysis, keep in mind that salaries across the whole league 
--tend to increase together, so you may want to look on a year-by-year basis.

WITH win_sal AS(
SELECT 
	t.yearid,
	--t.lgid,
	--t.name,
	t.teamid,
	SUM(t.w) AS total_wins,
	SUM(s.salary) AS total_salary
FROM teams t
INNER JOIN salaries s
USING (yearid, teamid)
WHERE yearid > 2000
GROUP BY yearid,
		t.teamid
		-- s.salary
ORDER BY teamid, yearid
)
SELECT 
	*,
	CASE WHEN total_wins > LAG(total_wins) OVER (PARTITION BY teamid ORDER BY yearid) THEN 'more'
		 WHEN total_wins < LAG(total_wins) OVER (PARTITION BY teamid ORDER BY yearid) THEN 'less'
	     ELSE 'same' END AS win_analysis,
	CASE WHEN total_salary > LAG(total_salary) OVER (PARTITION BY teamid ORDER BY yearid) THEN 'increased'
		 WHEN total_salary < LAG(total_salary) OVER (PARTITION BY teamid ORDER BY yearid) THEN 'decreased'
	     ELSE 'same' END AS salary_analysis
FROM win_sal
ORDER BY teamid, yearid

;---teamwise salary--For some years salary increased when no of wins increased and 
--viceaversa, but for others it increased regardless of wins

----------------------------------------------------------------------------------------------------
-- Yearwise salary for all the teams combined
----------------------------------------------------------------------------------------------------
WITH win_sal AS(
	SELECT 
	t.yearid,
	--t.lgid,
	--t.name,
	--t.teamid,
	SUM(t.w) AS total_wins,
	SUM(s.salary) AS total_salary
FROM teams t
INNER JOIN salaries s
USING (yearid, teamid)
WHERE yearid > 2000
GROUP BY yearid
		--t.teamid
		-- s.salary
ORDER BY yearid
)
SELECT 
	*,
	CASE WHEN total_wins > LAG(total_wins) OVER (ORDER BY yearid) THEN 'more_wins'
		 WHEN total_wins < LAG(total_wins) OVER (ORDER BY yearid) THEN 'less_wins'
	     ELSE 'same' END AS win_analysis,
	CASE WHEN total_salary > LAG(total_salary) OVER (ORDER BY yearid) THEN 'salary_increased'
		 WHEN total_salary < LAG(total_salary) OVER (ORDER BY yearid) THEN 'salary_decreased'
	     ELSE 'same' END AS salary_analysis
FROM win_sal
--------------------------------------------------------------------------------------------------------
-- 12. In this question, you will explore the connection between number of wins and attendance.
--   *  Does there appear to be any correlation between attendance at home games and number of wins? </li>
--   *  Do teams that win the world series see a boost in attendance the following year? What about teams 
--that made the playoffs? Making the playoffs means either being a division winner or a wild card winner.

---win count
--attendance
--homegames
--wswin
--playoffs = divwin or wcwin
SELECT
	yearid,
	ghome,
	wswin,
	divwin,
	wcwin,
	SUM(w) AS wins,
	SUM(attendance) AS total_attendance
FROM teams
GROUP BY yearid, 
		 ghome,
		 wswin,
		 divwin,
		 wcwin
ORDER BY yearid
--------------------------------------------------------------------------------------------------------
-- 13. It is thought that since left-handed pitchers are more rare, causing batters to face them less 
--often, that they are more effective. Investigate this claim and present evidence to either support or
--dispute this claim. First, determine just how rare left-handed pitchers are compared with right-handed
--pitchers. Are left-handed pitchers more likely to win the Cy Young Award? Are they more likely to
--make it into the hall of fame?

--count(left pitcher)
--count(rightpitcher)
--Cy Young Award
--hall of fame
--------------------------------------------------------------------------------------------------
---Determine how rare left-handed pitchers are compared with right-handed pitchers---
-- Left 3654 Right 14480 
--------------------------------------------------------------------------------------------------
SELECT
	COUNT(CASE WHEN throws = 'L' THEN 1 END) AS left,
	COUNT(CASE WHEN throws = 'R' THEN 1 END) AS right	
FROM people

---------------------------------------------------------------------------------------------------
--Cy Young Award  -- left 37, right 75 Left handed pitchers are less likely to make it to the award
---------------------------------------------------------------------------------------------------
SELECT
	COUNT(CASE WHEN p.throws = 'L' THEN 1 END) AS left,
	COUNT(CASE WHEN p.throws = 'R' THEN 1 END) AS right	
FROM people p
INNER JOIN awardsplayers a
USING (playerid)
WHERE awardid = 'Cy Young Award'

-----------------------------------------------------------------------------------------------------------
--hall of fame -- left 786, right 3335 Left handed pitchers are less likely to make it to the hall of fame
-----------------------------------------------------------------------------------------------------------
SELECT
	--p.playerid,
	--CONCAT(p.namefirst, ' ', p.namelast) AS full_name,
	COUNT(CASE WHEN p.throws = 'L' THEN 1 END) AS left,
	COUNT(CASE WHEN p.throws = 'R' THEN 1 END) AS right
FROM people p
INNER JOIN halloffame h
USING (playerid)
---------------------------------------------------------------------------------------------------
--hall of fame -- right handed 3335 left 786
---------------------------------------------------------------------------------------------------


SELECT 
	h.playerid,
	CONCAT(p.namefirst, ' ', p.namelast) AS full_name
FROM halloffame h
INNER JOIN people p
USING (playerid)
WHERE p.throws = 'L'--786 reacords
GROUP BY playerid, full_name--249 players
-----------------------------------------------------

SELECT 
	h.playerid,
	CONCAT(p.namefirst, ' ', p.namelast) AS full_name
FROM halloffame h
INNER JOIN people p
USING (playerid)
WHERE p.throws = 'R'--3335 rows
GROUP BY playerid, full_name--976 players
----------------------------------------------------------------
