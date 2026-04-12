/******************************** create matches table *****************************/

CREATE TABLE matches (
    match_id INT PRIMARY KEY,
    city VARCHAR(100),
    venue VARCHAR(200),
    date DATE,
    team1 VARCHAR(50),
    team2 VARCHAR(50),
    toss_winner VARCHAR(50),
    toss_decision VARCHAR(20),
    winner VARCHAR(50),
    player_of_match VARCHAR(50),
    season INT,
    month INT,
    day INT,
    match_result_type VARCHAR(30),
    toss_match_win BOOLEAN,
    day_type VARCHAR(20)
);

/**************************** create deliveries table *******************************/

CREATE TABLE deliveries (
    delivery_id INT PRIMARY KEY,
    match_id INT,
    inning INT,
    batting_team VARCHAR(50),
    bowling_team VARCHAR(50),
    over INT,
    ball INT,
    batter VARCHAR(50),
    bowler VARCHAR(50),
    non_striker VARCHAR(50),
    runs_batsman INT,
    runs_extras INT,
    runs_total INT,
    is_wicket BOOLEAN,
    wicket_kind VARCHAR(50),
    fielder VARCHAR(50),
    ball_id INT,
    over_ball VARCHAR(20),
    ball_in_innings INT,
    ball_type VARCHAR(50),
    is_boundary BOOLEAN,
    is_six BOOLEAN,
    runs_type VARCHAR(20),
    is_dot_ball BOOLEAN,
    batter_strike_rate_ball FLOAT,
    ball_faced INT,
    is_four BOOLEAN,
    bowler_runs INT,
    bowler_balls INT,
    bowler_economy_ball FLOAT,
    bowler_wickets INT,
    bowler_strike_rate_ball FLOAT,
    over_runs INT,
    batter_runs_cumsum INT
);


/***************************** MATCH / SEASON ANALYSIS ****************************/

/************************** Total matches played each season **********************/
SELECT season, COUNT(*) AS total_matches
FROM matches
GROUP BY season
ORDER BY season;

/****************************** Total wins by each team ***************************/
SELECT winner, COUNT(*) AS total_wins
FROM matches
WHERE winner IS NOT NULL
GROUP BY winner
ORDER BY total_wins DESC;

/************** Top 10 players with most Player of the Match awards ***************/
SELECT player_of_match, COUNT(*) AS awards
FROM matches
GROUP BY player_of_match
ORDER BY awards DESC
LIMIT 10;

/************************************ Toss Impact *********************************/
SELECT toss_decision, COUNT(*) filter (WHERE toss_match_win = TRUE) AS wins_after_toss_win
FROM matches
GROUP BY toss_decision;

/***************************** Most successful teams ******************************/
SELECT winner, COUNT(*) AS wins
FROM matches
WHERE winner != 'No Result'
GROUP BY winner
ORDER BY wins DESC;

/********************************** Venue analysis ********************************/
SELECT venue, COUNT(*) AS matches_played
FROM matches
GROUP BY venue
ORDER BY matches_played DESC
LIMIT 10;

/************************* Over-wise run rate analysis ************************/
SELECT over, ROUND(AVG(runs_total), 2) AS avg_runs_per_over
FROM deliveries
GROUP BY over
ORDER BY over;


/************************************ TEAM ANALYSIS ******************************/

/***************** Total runs scored by each team in all seasons *****************/
SELECT batting_team, SUM(runs_total) AS total_runs
FROM deliveries
GROUP BY batting_team
ORDER BY total_runs DESC;

/************************ Total wickets taken by each team **********************/
SELECT bowling_team, SUM(is_wicket::int) AS total_wickets
FROM deliveries
GROUP BY bowling_team
ORDER BY total_wickets DESC;

/************************ Teams with best chasing record ************************/
SELECT winner, COUNT(*) AS chases_won
FROM matches
WHERE winner = team2
GROUP BY winner
ORDER BY chases_won DESC;

/************************ Teams with best defending record **********************/
SELECT winner, COUNT(*) AS defended_wins
FROM matches
WHERE winner = team1
GROUP BY winner
ORDER BY defended_wins DESC;

/******************** Powerplay total runs by team (overs 1–6) ******************/
SELECT
  batting_team,
  SUM(runs_total) AS powerplay_runs
FROM public.deliveries
WHERE over BETWEEN 1 AND 6
GROUP BY batting_team
ORDER BY powerplay_runs DESC;

/******************** Powerplay wickets lost by team (overs 1–6) *****************/
SELECT
  batting_team,
  COUNT(*) FILTER (WHERE is_wicket = TRUE) AS powerplay_wickets
FROM public.deliveries
WHERE over BETWEEN 1 AND 6
GROUP BY batting_team
ORDER BY powerplay_wickets ASC;

/**************** Powerplay run rate (runs per over for overs 1–6) ***************/
SELECT
  batting_team,
  ROUND( SUM(runs_total)::numeric / 6.0, 2) AS powerplay_run_rate
FROM public.deliveries
WHERE over BETWEEN 1 AND 6
GROUP BY batting_team
ORDER BY powerplay_run_rate DESC;


/********************************** BATSMAN ANALYSIS *****************************/

/*************************** Top 10 batsmen by total runs ***********************/
SELECT batter, SUM(runs_batsman) AS total_runs
FROM deliveries
GROUP BY batter
ORDER BY total_runs DESC
LIMIT 10;

/****************************** Most sixes by a player **************************/
SELECT batter, SUM(is_six::int) AS sixes
FROM deliveries
GROUP BY batter
ORDER BY sixes DESC
LIMIT 10;

/**************************** Most fours by a player ***************************/
SELECT batter, SUM(is_four::int) AS fours
FROM deliveries
GROUP BY batter
ORDER BY fours DESC
LIMIT 10;

/************************ Strike rate of each batsman *************************/
SELECT batter,
       SUM(runs_batsman) AS runs,
       COUNT(*) AS balls_faced,
       ROUND((SUM(runs_batsman) * 100.0) / COUNT(*), 2) AS strike_rate
FROM deliveries
GROUP BY batter
HAVING COUNT(*) > 200
ORDER BY strike_rate DESC;

/******************* Top 10 finishers (death overs 16–20 runs) **************/
SELECT batter, SUM(runs_batsman) AS death_over_runs
FROM deliveries
WHERE over BETWEEN 16 AND 20
GROUP BY batter
ORDER BY death_over_runs DESC
LIMIT 10;

/********************* Best powerplay batsmen (overs 1–6) ********************/
SELECT batter, SUM(runs_batsman) AS pp_runs
FROM deliveries
WHERE over BETWEEN 1 AND 6
GROUP BY batter
ORDER BY pp_runs DESC
LIMIT 10;

/********************************* BOWLER ANALYSIS ******************************/

/************************** Top 10 bowlers by wickets ***************************/
SELECT bowler, SUM(is_wicket::int) AS wickets
FROM deliveries
WHERE wicket_kind NOT IN ('run out', 'retired hurt', 'obstructing the field')
GROUP BY bowler
ORDER BY wickets DESC
LIMIT 10;

/*************************** Most economical bowlers ***************************/
SELECT bowler,
       SUM(bowler_runs) AS total_runs,
       SUM(bowler_balls) AS total_balls,
       ROUND((SUM(bowler_runs) * 6.0) / SUM(bowler_balls), 2) AS economy
FROM deliveries
GROUP BY bowler
HAVING SUM(bowler_balls) > 300
ORDER BY economy ASC
LIMIT 10;

/***************************** Bowler strike rate ****************************/
SELECT bowler,
       SUM(is_wicket::int) AS wickets,
       SUM(bowler_balls) AS balls,
       ROUND( (SUM(bowler_balls)::numeric / NULLIF(SUM(is_wicket::int), 0)) , 2) AS strike_rate
FROM deliveries
GROUP BY bowler
HAVING SUM(is_wicket::int) >= 10
ORDER BY strike_rate ASC;

/**************************** Best death-over bowlers ************************/
SELECT bowler, SUM(is_wicket::int) AS death_wickets
FROM deliveries
WHERE over BETWEEN 16 AND 20
GROUP BY bowler
ORDER BY death_wickets DESC
LIMIT 10;

/************************** Best powerplay bowlers **************************/
SELECT bowler, SUM(is_wicket::int) AS pp_wickets
FROM deliveries
WHERE over BETWEEN 1 AND 6
GROUP BY bowler
ORDER BY pp_wickets DESC
LIMIT 10;

/*********************** Bowler economy in powerplay (overs 1–6) — 
only bowlers who bowled at least 30 balls in PP **************************/
SELECT
  bowler,
  SUM(runs_total) AS runs_conceded_in_pp,
  COUNT(*) AS balls_bowled_in_pp,
  ROUND( (SUM(runs_total)::numeric * 6.0) / NULLIF(COUNT(*),0), 2) AS economy_powerplay
FROM public.deliveries
WHERE over BETWEEN 1 AND 6
GROUP BY bowler
HAVING COUNT(*) >= 30
ORDER BY economy_powerplay ASC
LIMIT 30;

