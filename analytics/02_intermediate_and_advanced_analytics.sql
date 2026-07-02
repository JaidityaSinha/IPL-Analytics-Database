-- =====================================================
-- IPL Analytics Database
-- File: 02_intermediate_and_advanced_analytics.sql
--
-- Intermediate analytical queries using CTEs,
-- window functions, nested aggregations,
-- and cricket-specific statistics.
-- =====================================================




-- =====================================================
-- Highest Strike Rate
-- =====================================================

WITH batting_stats AS (SELECT players.player_name                                        AS batter,
                              teams.team_name                                            AS team,
                              COALESCE(SUM(deliveries.batter_runs), 0)                   AS runs,
                              SUM(CASE WHEN deliveries.wide_runs <> 0 THEN 0 ELSE 1 END) AS balls_faced,
                              COALESCE(ROUND(SUM(deliveries.batter_runs) * 1.0
                                                 /
                                             NULLIF(SUM(CASE WHEN deliveries.wide_runs <> 0 THEN 0 ELSE 1 END), 0) *
                                             100, 2), 0)                                 AS strike_rate
                       FROM players
                                LEFT JOIN teams ON players.team_id = teams.team_id
                                LEFT JOIN deliveries ON players.player_id = deliveries.batter_id
                       GROUP BY players.player_name, teams.team_name)

SELECT *
FROM batting_stats
WHERE balls_faced >= 30
ORDER BY strike_rate DESC;


-- =====================================================
-- Highest Batting Average
-- =====================================================

WITH cte AS (SELECT players.player_name                                                                 AS batter,
                    teams.team_name                                                                     AS team,
                    COALESCE(SUM(deliveries.batter_runs), 0)                                            AS runs,
                    SUM(CASE WHEN deliveries.dismissed_batter_id = players.player_id THEN 1 ELSE 0 END) AS dismissals,
                    COALESCE(ROUND(SUM(deliveries.batter_runs) * 1.0
                                       /
                                   NULLIF(SUM(CASE
                                                  WHEN deliveries.dismissed_batter_id = players.player_id THEN 1
                                                  ELSE 0 END),
                                          0), 2), 0)
                                                                                                        AS batting_average
             FROM players
                      LEFT JOIN teams ON players.team_id = teams.team_id
                      LEFT JOIN deliveries ON players.player_id = deliveries.batter_id
             GROUP BY players.player_name, teams.team_name
             HAVING SUM(CASE WHEN deliveries.dismissed_batter_id = players.player_id THEN 1 ELSE 0 END) > 0)


SELECT *
FROM cte
ORDER BY batting_average DESC;

-- =====================================================
-- Most Fifties
-- =====================================================

WITH cte AS (SELECT players.player_name,
                    teams.team_name,
                    SUM(deliveries.batter_runs) AS runs
             FROM players
                      LEFT JOIN teams ON players.team_id = teams.team_id
                      LEFT JOIN deliveries ON players.player_id = deliveries.batter_id
             GROUP BY players.player_name, teams.team_name, match_id)

SELECT player_name, team_name, SUM(CASE WHEN runs BETWEEN 50 AND 99 THEN 1 ELSE 0 END) AS fifties
FROM cte
GROUP BY player_name, team_name;

-- =====================================================
-- Most Centuries
-- =====================================================

WITH cte AS (SELECT players.player_name,
                    teams.team_name,
                    SUM(deliveries.batter_runs) AS runs
             FROM players
                      LEFT JOIN teams ON players.team_id = teams.team_id
                      LEFT JOIN deliveries ON players.player_id = deliveries.batter_id
             GROUP BY players.player_name, teams.team_name, match_id)

SELECT player_name, team_name, SUM(CASE WHEN runs >= 100 THEN 1 ELSE 0 END) AS centuries
FROM cte
GROUP BY player_name, team_name
ORDER BY centuries DESC;

-- =====================================================
-- Boundary Percentage
-- =====================================================

SELECT players.player_name,
       teams.team_name,
       SUM(deliveries.batter_runs)                             AS total_runs,
       SUM(
               CASE
                   WHEN deliveries.batter_runs = 4 THEN 4
                   WHEN deliveries.batter_runs = 6 THEN 6
                   ELSE 0 END
       )                                                       AS boundary_runs,
       ROUND(SUM(
                     CASE
                         WHEN deliveries.batter_runs = 4 THEN 4
                         WHEN deliveries.batter_runs = 6 THEN 6
                         ELSE 0 END
             ) * 1.0 / SUM(deliveries.batter_runs) * 100.0, 2) AS boundary_percentage
FROM players
         LEFT JOIN teams ON players.team_id = teams.team_id
         LEFT JOIN deliveries ON players.player_id = deliveries.batter_id
GROUP BY players.player_name, teams.team_name
HAVING SUM(deliveries.batter_runs) IS NOT NULL
   AND SUM(batter_runs) > 0
ORDER BY boundary_percentage DESC;

-- =====================================================
-- Best Economy Rate
-- =====================================================

WITH cte AS (SELECT players.player_name,
                    teams.team_name,
                    SUM(CASE WHEN deliveries.wide_runs = 0 THEN 1 ELSE 0 END) / 6.0             AS overs,
                    SUM(deliveries.batter_runs + deliveries.wide_runs + deliveries.noball_runs) AS runs_conceded,
                    SUM(deliveries.batter_runs + deliveries.wide_runs + deliveries.noball_runs) * 1.0
                        / (SUM(CASE WHEN deliveries.wide_runs = 0 THEN 1 ELSE 0 END) / 6.0)     AS economy
             FROM players
                      JOIN teams ON players.team_id = teams.team_id
                      JOIN deliveries ON players.player_id = deliveries.bowler_id
             GROUP BY players.player_name, teams.team_name)

SELECT *
FROM cte
WHERE overs >= 10
ORDER BY economy;

-- =====================================================
-- Best Bowling Average
-- =====================================================

SELECT players.player_name,
       teams.team_name,
       SUM(CASE
               WHEN deliveries.is_wicket AND deliveries.dismissal_type IN ('Caught', 'Bowled') THEN 1
               ELSE 0 END)                                                         AS wickets,
       SUM(deliveries.batter_runs + deliveries.wide_runs + deliveries.noball_runs) AS runs_conceded,
       SUM(deliveries.batter_runs + deliveries.wide_runs + deliveries.noball_runs) * 1.0
           / SUM(CASE WHEN deliveries.is_wicket AND deliveries.dismissal_type IN ('Caught', 'Bowled') THEN 1 ELSE 0 END)
                                                                                   AS bowling_average
FROM players
         LEFT JOIN teams ON players.team_id = teams.team_id
         LEFT JOIN deliveries ON players.player_id = deliveries.bowler_id
GROUP BY players.player_name, teams.team_name
HAVING SUM(CASE WHEN deliveries.is_wicket AND deliveries.dismissal_type IN ('Caught', 'Bowled') THEN 1 ELSE 0 END) > 0
ORDER BY bowling_average;

-- =====================================================
-- Best Bowling Strike Rate
-- =====================================================

SELECT players.player_name,
       teams.team_name,
       SUM(CASE
               WHEN deliveries.is_wicket
                    AND deliveries.dismissal_type IN ('Caught', 'Bowled')
               THEN 1
               ELSE 0
           END) AS wickets,

       SUM(CASE
               WHEN deliveries.wide_runs = 0
               THEN 1
               ELSE 0
           END) AS balls_bowled,

       ROUND(
           SUM(CASE
                   WHEN deliveries.wide_runs = 0
                   THEN 1
                   ELSE 0
               END) * 1.0
           /
           NULLIF(
               SUM(CASE
                       WHEN deliveries.is_wicket
                            AND deliveries.dismissal_type IN ('Caught', 'Bowled')
                       THEN 1
                       ELSE 0
                   END),
               0
           ),
           2
       ) AS bowling_strike_rate

FROM players
         LEFT JOIN teams
                   ON players.team_id = teams.team_id
         LEFT JOIN deliveries
                   ON players.player_id = deliveries.bowler_id

GROUP BY players.player_name, teams.team_name

HAVING SUM(CASE
               WHEN deliveries.is_wicket
                    AND deliveries.dismissal_type IN ('Caught', 'Bowled')
               THEN 1
               ELSE 0
           END) > 0

ORDER BY bowling_strike_rate;

-- =====================================================
-- Team Win Percentage
-- =====================================================

SELECT teams.team_name,
       SUM(CASE WHEN matches.team1_id = teams.team_id OR matches.team2_id = teams.team_id THEN 1 ELSE 0 END) AS matches,
       SUM(CASE WHEN matches.winner_team_id = teams.team_id THEN 1 ELSE 0 END)                               AS wins,
       SUM(CASE WHEN matches.winner_team_id = teams.team_id THEN 1 ELSE 0 END) * 1.0 /
       SUM(CASE WHEN matches.team1_id = teams.team_id OR matches.team2_id = teams.team_id THEN 1 ELSE 0 END) *
       100                                                                                                   AS win_percentage
FROM teams
         LEFT JOIN matches ON teams.team_id = matches.team1_id OR teams.team_id = matches.team2_id
GROUP BY teams.team_name
HAVING SUM(CASE WHEN matches.team1_id = teams.team_id OR matches.team2_id = teams.team_id THEN 1 ELSE 0 END) > 0;

-- =====================================================
-- Head-to-Head Record
-- =====================================================

SELECT t1.team_name,
       t2.team_name,
       COUNT(*)                                                             AS matches,
       SUM(CASE WHEN matches.winner_team_id = t1.team_id THEN 1 ELSE 0 END) AS team_1_wins,
       SUM(CASE WHEN matches.winner_team_id = t2.team_id THEN 1 ELSE 0 END) AS team_2_wins
FROM matches
         LEFT JOIN teams t1 ON matches.team1_id = t1.team_id
         LEFT JOIN teams t2 ON team2_id = t2.team_id
GROUP BY t1.team_name, t2.team_name;

-- =====================================================
-- Toss Impact Analysis
-- =====================================================

SELECT teams.team_name,
       SUM(CASE WHEN matches.toss_winner_id = teams.team_id THEN 1 ELSE 0 END) AS tosses_won,
       SUM(CASE
               WHEN matches.toss_winner_id = teams.team_id AND matches.winner_team_id = teams.team_id THEN 1
               ELSE 0 END)
                                                                               AS matches_won_when_toss_won,
       COALESCE(ROUND(SUM(CASE
                              WHEN matches.toss_winner_id = teams.team_id AND matches.winner_team_id = teams.team_id
                                  THEN 1
                              ELSE 0 END) * 1.0
                          / NULLIF(SUM(CASE WHEN matches.toss_winner_id = teams.team_id THEN 1 ELSE 0 END), 0) * 100,
                      2), 0)                                                   AS conversion_rate
FROM teams
         LEFT JOIN matches ON teams.team_id = matches.team1_id OR teams.team_id = matches.team2_id
GROUP BY teams.team_name
ORDER BY conversion_rate DESC;

-- =====================================================
-- Batting First vs Chasing Success
-- =====================================================

SELECT teams.team_name,
       SUM(CASE
               WHEN innings.innings_number = 1
                   AND innings.batting_team_id = teams.team_id THEN 1
               ELSE 0 END)
                           AS bat_1st,
       SUM(CASE
               WHEN innings.innings_number = 1
                   AND innings.batting_team_id = teams.team_id
                   AND matches.winner_team_id = teams.team_id THEN 1
               ELSE 0 END) AS won_bat_1st,

       SUM(CASE
               WHEN innings.innings_number = 2
                   AND innings.batting_team_id = teams.team_id THEN 1
               ELSE 0 END)
                           AS bat_2nd,
       SUM(CASE
               WHEN innings.innings_number = 2
                   AND innings.batting_team_id = teams.team_id
                   AND matches.winner_team_id = teams.team_id THEN 1
               ELSE 0 END) AS won_bat_2nd
FROM matches
         JOIN innings ON matches.match_id = innings.match_id
         LEFT JOIN teams ON matches.team1_id = teams.team_id OR matches.team2_id = teams.team_id
GROUP BY teams.team_name; 

-- =====================================================
-- Highest Scoring Venue
-- =====================================================

SELECT venues.venue_name,
       count(DISTINCT matches.match_id)                                            AS matches,
       SUM(deliveries.batter_runs + deliveries.wide_runs +
           deliveries.noball_runs + deliveries.legbye_runs + deliveries.bye_runs) AS runs,
       SUM(deliveries.batter_runs + deliveries.wide_runs +
           deliveries.noball_runs + deliveries.legbye_runs + deliveries.bye_runs) * 1.0
           / count(DISTINCT matches.match_id)                                      AS avg_runs
FROM venues
         LEFT JOIN matches ON venues.venue_id = matches.venue_id
         LEFT JOIN deliveries ON matches.match_id = deliveries.match_id
GROUP BY venues.venue_name
ORDER BY avg_runs DESC;

-- =====================================================
-- Player Performance by Venue
-- =====================================================

SELECT players.player_name,
       teams.team_name,
       venues.venue_name,
       count(DISTINCT matches.match_id)                                                                               AS matches,
       SUM(deliveries.batter_runs)                                                                                    AS runs,
       SUM(deliveries.batter_runs) * 1.0 /
       NULLIF(SUM(CASE WHEN is_wicket AND dismissed_batter_id = player_id THEN 1 ELSE 0 END),
              0)                                                                                                      AS avg,
       SUM(deliveries.batter_runs) * 1.0 / NULLIF(SUM(CASE WHEN deliveries.wide_runs = 0 THEN 1 ELSE 0 END), 0) *
       100                                                                                                            AS sr
FROM players
         LEFT JOIN deliveries ON players.player_id = deliveries.batter_id
         LEFT JOIN matches ON deliveries.match_id = matches.match_id
         LEFT JOIN venues ON matches.venue_id = venues.venue_id
         LEFT JOIN teams ON players.team_id = teams.team_id
GROUP BY players.player_name, teams.team_name, venues.venue_name
HAVING count(DISTINCT matches.match_id) > 0;

-- =====================================================
-- Orange Cap Progression
-- =====================================================

WITH cte AS (SELECT matches.match_id            AS matches,
                    matches.match_date          AS date,
                    players.player_name         AS player,
                    SUM(deliveries.batter_runs) AS runs
             FROM matches
                      LEFT JOIN deliveries ON matches.match_id = deliveries.match_id
                      LEFT JOIN players ON deliveries.batter_id = players.player_id
             GROUP BY matches.match_id, matches.match_date, players.player_name),

     cte2 AS (SELECT matches, date, player, runs, SUM(runs) OVER (PARTITION BY player ORDER BY date) AS cumulative_runs
              FROM cte)

SELECT cte2.matches,
       cte2.date,
       cte2.player,
       cte2.cumulative_runs,
       cte2.runs,
       DENSE_RANK() over (PARTITION BY matches ORDER BY cumulative_runs DESC)
FROM cte2;

-- =====================================================
-- Purple Cap Progression
-- =====================================================

WITH cte AS (SELECT matches.match_id                                                                      AS matches,
                    matches.match_date                                                                    AS date,
                    players.player_name                                                                   AS player,
                    SUM(CASE WHEN is_wicket AND dismissal_type IN ('Caught', 'Bowled') THEN 1 ELSE 0 END) AS wickets
             FROM matches
                      LEFT JOIN deliveries ON matches.match_id = deliveries.match_id
                      LEFT JOIN players ON deliveries.bowler_id = players.player_id
             GROUP BY matches.match_id, matches.match_date, players.player_name),

     cte2 AS (SELECT matches,
                     date,
                     player,
                     wickets,
                     SUM(wickets) OVER (PARTITION BY player ORDER BY date) AS cumulative_wickets
              FROM cte)

SELECT cte2.matches,
       cte2.date,
       cte2.player,
       cte2.cumulative_wickets,
       cte2.wickets,
       DENSE_RANK() over (PARTITION BY matches ORDER BY cumulative_wickets DESC)
FROM cte2;

-- =====================================================
-- End of Intermediate Analytics Queries
-- =====================================================