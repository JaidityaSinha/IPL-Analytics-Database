-- =====================================================
-- IPL Analytics Database
-- File: 01_basic_analytics.sql
--
-- Basic analytical queries using joins, aggregates,
-- conditional aggregation, and grouping.
-- =====================================================




-- =====================================================
-- Players with their Teams
-- =====================================================

SELECT players.player_name,
       teams.team_name
FROM players
JOIN teams
ON players.team_id = teams.team_id;



-- =====================================================
-- Total Runs by Batter
-- =====================================================

SELECT players.player_name,
       COALESCE(SUM(deliveries.batter_runs), 0) AS total_runs
FROM players
LEFT JOIN deliveries
ON players.player_id = deliveries.batter_id
GROUP BY players.player_name
ORDER BY total_runs DESC;



-- =====================================================
-- Total Wickets by Bowler
-- =====================================================

SELECT players.player_name,
       SUM(CASE WHEN deliveries.is_wicket THEN 1 ELSE 0 END) AS total_wickets
FROM players
LEFT JOIN deliveries
ON players.player_id = deliveries.bowler_id
GROUP BY players.player_name
ORDER BY total_wickets DESC;



-- =====================================================
-- Batting Strike Rate
-- =====================================================

SELECT players.player_name,
       COALESCE(SUM(deliveries.batter_runs), 0) AS total_runs,
       COALESCE(SUM(CASE WHEN deliveries.wide_runs = 0 THEN 1 END),0) AS balls_faced,
       ROUND(COALESCE(SUM(deliveries.batter_runs) * 100.0 /
               NULLIF(SUM(CASE WHEN deliveries.wide_runs = 0 THEN 1 END),0),0),2) AS strike_rate
FROM players
LEFT JOIN deliveries
ON players.player_id = deliveries.batter_id
GROUP BY players.player_name
ORDER BY total_runs DESC;



-- =====================================================
-- Economy Rate
-- =====================================================

SELECT players.player_name AS bowler,
       SUM(batter_runs + wide_runs + noball_runs) AS runs_conceded,
       COALESCE(SUM(CASE WHEN wide_runs <> 0 THEN 0 ELSE 1 END), 0) AS balls_bowled,
       COALESCE(SUM(CASE WHEN wide_runs <> 0 THEN 0 ELSE 1 END) / 6.0, 0) AS overs,
       COALESCE(
           ROUND(
               SUM(batter_runs + wide_runs + noball_runs) * 1.0 /
               NULLIF(
                   SUM(CASE WHEN wide_runs <> 0 THEN 0 ELSE 1 END) / 6.0,
                   0
               ),
               2
           ),
           0
       ) AS economy
FROM players
LEFT JOIN deliveries
ON players.player_id = deliveries.bowler_id
GROUP BY players.player_name
ORDER BY economy;

-- =====================================================
-- Number of Fours by Batter
-- =====================================================

SELECT players.player_name AS batter,
       COALESCE(SUM(CASE WHEN batter_runs = 4 THEN 1 ELSE 0 END), 0) AS fours
FROM players
LEFT JOIN deliveries
ON players.player_id = deliveries.batter_id
GROUP BY players.player_name
ORDER BY SUM(CASE WHEN batter_runs = 4 THEN 1 ELSE 0 END) DESC;

-- =====================================================
-- Number of Sixes by Batter
-- =====================================================

SELECT players.player_name AS batter,
       COALESCE(SUM(CASE WHEN batter_runs = 6 THEN 1 ELSE 0 END), 0) AS sixes
FROM players
LEFT JOIN deliveries
ON players.player_id = deliveries.batter_id
GROUP BY players.player_name
ORDER BY sixes DESC;

-- =====================================================
-- Dot Balls Faced by Batter
-- =====================================================

SELECT players.player_name AS batter,
       COALESCE(
           SUM(
               CASE
                   WHEN deliveries.batter_runs = 0
                    AND deliveries.wide_runs = 0
                    AND deliveries.noball_runs = 0
                    AND deliveries.bye_runs = 0
                    AND deliveries.legbye_runs = 0
                   THEN 1
                   ELSE 0
               END
           ),
           0
       ) AS dot_balls
FROM players
LEFT JOIN deliveries
ON players.player_id = deliveries.batter_id
GROUP BY players.player_name
ORDER BY dot_balls DESC;

-- =====================================================
-- Dot Balls Bowled
-- =====================================================

SELECT players.player_name AS bowler,
       COALESCE(
           SUM(
               CASE
                   WHEN deliveries.batter_runs = 0
                    AND deliveries.wide_runs = 0
                    AND deliveries.noball_runs = 0
                    AND deliveries.bye_runs = 0
                    AND deliveries.legbye_runs = 0
                   THEN 1
                   ELSE 0
               END
           ),
           0
       ) AS dot_balls
FROM players
LEFT JOIN deliveries
ON players.player_id = deliveries.bowler_id
GROUP BY players.player_name
ORDER BY dot_balls DESC;

-- =====================================================
-- Team Totals
-- =====================================================

SELECT teams.team_name,
       COALESCE(
           SUM(
               d.batter_runs +
               d.wide_runs +
               d.noball_runs +
               d.legbye_runs +
               d.bye_runs
           ),
           0
       ) AS total_runs
FROM teams
LEFT JOIN innings
ON teams.team_id = innings.batting_team_id
LEFT JOIN deliveries d
ON innings.match_id = d.match_id
AND innings.innings_number = d.innings_number
GROUP BY teams.team_name
ORDER BY total_runs DESC;

-- =====================================================
-- Match Summary
-- =====================================================

SELECT matches.match_date,
       venues.venue_name,
       t1.team_name AS team1,
       t2.team_name AS team2,
       t3.team_name AS winner,
       t4.team_name AS toss_winner,
       matches.toss_decision
FROM matches
JOIN teams t1 ON matches.team1_id = t1.team_id
JOIN teams t2 ON matches.team2_id = t2.team_id
JOIN teams t3 ON matches.winner_team_id = t3.team_id
JOIN teams t4 ON matches.toss_winner_id = t4.team_id
JOIN venues ON matches.venue_id = venues.venue_id;

-- =====================================================
-- Highest Scorer in the Match
-- =====================================================

WITH batting_scores AS (
    SELECT
        m.match_id,
        m.match_date,
        p.player_name,
        t.team_name,
        SUM(d.batter_runs) AS runs,
        RANK() OVER (
            PARTITION BY m.match_id
            ORDER BY SUM(d.batter_runs) DESC
        ) AS rank
    FROM matches m
    JOIN deliveries d
        ON m.match_id = d.match_id
    JOIN players p
        ON d.batter_id = p.player_id
    JOIN teams t
        ON p.team_id = t.team_id
    GROUP BY
        m.match_id,
        m.match_date,
        p.player_name,
        t.team_name
)

SELECT
    match_id,
    match_date,
    player_name,
    team_name,
    runs
FROM batting_scores
WHERE rank = 1
ORDER BY match_date;

-- =====================================================
-- Best Bowling Figures
-- =====================================================

WITH cte AS (SELECT matches.match_id,
                    matches.match_date,
                    players.player_name,
                    teams.team_name,
                    SUM(CASE
                            WHEN deliveries.is_wicket
                                AND (dismissal_type = 'Caught' OR dismissal_type = 'Bowled') THEN 1
                            ELSE 0 END)                                                         AS wickets,
                    SUM(deliveries.batter_runs + deliveries.wide_runs + deliveries.noball_runs) AS runs_conceded,
                    rank() over (PARTITION BY matches.match_id
                        ORDER BY SUM(CASE
                                         WHEN deliveries.is_wicket
                                             AND (dismissal_type = 'Caught' OR dismissal_type = 'Bowled') THEN 1
                                         ELSE 0 END) DESC,
                            SUM(deliveries.batter_runs + deliveries.wide_runs + deliveries.noball_runs)
                        )                                                                       AS rank
             FROM matches
                      LEFT JOIN deliveries ON matches.match_id = deliveries.match_id
                      LEFT JOIN players ON deliveries.bowler_id = players.player_id
                      LEFT JOIN teams ON players.team_id = teams.team_id
             GROUP BY matches.match_id, matches.match_date, players.player_name, teams.team_name)

SELECT *
FROM cte
WHERE rank = 1;

-- =====================================================
-- Orange Cap Leaderboard
-- =====================================================

SELECT players.player_name,
       teams.team_name,
       COUNT(DISTINCT deliveries.match_id)                                  AS matches,
       COALESCE(SUM(deliveries.batter_runs), 0)                             AS total_runs,
       RANK() OVER (ORDER BY COALESCE(SUM(deliveries.batter_runs), 0) DESC) AS orange_cap_rank
FROM players
         LEFT JOIN teams ON players.team_id = teams.team_id
         LEFT JOIN deliveries ON players.player_id = deliveries.batter_id
GROUP BY players.player_name, teams.team_name
HAVING COUNT(DISTINCT deliveries.match_id) != 0
ORDER BY total_runs DESC;

-- =====================================================
-- Purple Cap Leaderboard
-- =====================================================

SELECT players.player_name,
       teams.team_name,
       COUNT(DISTINCT deliveries.match_id)      AS matches,
       SUM(CASE
               WHEN is_wicket AND dismissal_type IN ('Caught', 'Bowled') THEN 1
               ELSE 0 END)                      AS total_wickets,
       DENSE_RANK()
       OVER (ORDER BY SUM(CASE
                              WHEN is_wicket AND (dismissal_type = 'Caught' OR dismissal_type = 'Bowled') THEN 1
                              ELSE 0 END) DESC) AS purple_cap_rank
FROM players
         LEFT JOIN teams ON players.team_id = teams.team_id
         LEFT JOIN deliveries ON players.player_id = deliveries.bowler_id
GROUP BY players.player_name, teams.team_name
HAVING COUNT(DISTINCT deliveries.match_id) > 0
ORDER BY total_wickets DESC;







-- =====================================================
-- End of Basic Analytics Queries
-- =====================================================