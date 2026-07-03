/*
==========================================================
IPL Analytics Database
Views
==========================================================

Author  : Jaiditya Sinha
Database: PostgreSQL
Project : IPL Analytics Database

Description
-----------
This file contains reusable SQL views built on top of the
normalized IPL database schema.

The views encapsulate commonly used analytical queries,
allowing applications and reports to retrieve statistics
without repeatedly writing complex joins and aggregations.

==========================================================
*/

----------------------------------------------------------
-- Batting Statistics
----------------------------------------------------------

CREATE OR REPLACE VIEW batting_statistics AS
SELECT players.player_name,
       teams.team_name,

       COALESCE(SUM(deliveries.batter_runs), 0) AS runs,

       SUM(
               CASE
                   WHEN deliveries.wide_runs = 0 THEN 1
                   ELSE 0
                   END
       )                               AS balls_faced,

       SUM(
               CASE
                   WHEN deliveries.dismissed_batter_id = players.player_id THEN 1
                   ELSE 0
                   END
       )                               AS dismissals,

       ROUND(
               COALESCE(
                       SUM(deliveries.batter_runs) * 1.0 /
                       NULLIF(
                               SUM(
                                       CASE
                                           WHEN deliveries.dismissed_batter_id = players.player_id THEN 1
                                           ELSE 0
                                           END
                               ),
                               0
                       ),
                       0
               ),
               2
       )                               AS batting_average,

       ROUND(
               COALESCE(
                       SUM(deliveries.batter_runs) * 100.0 /
                       NULLIF(
                               SUM(
                                       CASE
                                           WHEN deliveries.wide_runs = 0 THEN 1
                                           ELSE 0
                                           END
                               ),
                               0
                       ),
                       0
               ),
               2
       )                               AS strike_rate

FROM players
         LEFT JOIN teams
                   ON players.team_id = teams.team_id
         LEFT JOIN deliveries
                   ON players.player_id = deliveries.batter_id

GROUP BY players.player_id,
         players.player_name,
         teams.team_name;

----------------------------------------------------------
-- Bowling Statistics
----------------------------------------------------------

CREATE OR REPLACE VIEW bowling_statistics AS
SELECT players.player_name,
       teams.team_name,

       ROUND(
               SUM(CASE WHEN deliveries.wide_runs = 0 THEN 1 ELSE 0 END) / 6.0,
               1
       )                                                                           AS overs,

       SUM(deliveries.batter_runs + deliveries.wide_runs + deliveries.noball_runs) AS runs_conceded,

       SUM(
               CASE
                   WHEN deliveries.is_wicket
                       AND deliveries.dismissal_type IN ('Caught', 'Bowled')
                       THEN 1
                   ELSE 0
                   END
       )                                                                           AS wickets,

       ROUND(
               SUM(deliveries.batter_runs + deliveries.wide_runs + deliveries.noball_runs) * 1.0
                   /
               NULLIF(
                       SUM(CASE WHEN deliveries.wide_runs = 0 THEN 1 ELSE 0 END) / 6.0,
                       0
               ),
               2
       )                                                                           AS economy,

       ROUND(
               SUM(deliveries.batter_runs + deliveries.wide_runs + deliveries.noball_runs) * 1.0
                   /
               NULLIF(
                       SUM(
                               CASE
                                   WHEN deliveries.is_wicket
                                       AND deliveries.dismissal_type IN ('Caught', 'Bowled')
                                       THEN 1
                                   ELSE 0
                                   END
                       ),
                       0
               ),
               2
       )                                                                           AS bowling_average,

       ROUND(
               SUM(CASE WHEN deliveries.wide_runs = 0 THEN 1 ELSE 0 END) * 1.0
                   /
               NULLIF(
                       SUM(
                               CASE
                                   WHEN deliveries.is_wicket
                                       AND deliveries.dismissal_type IN ('Caught', 'Bowled')
                                       THEN 1
                                   ELSE 0
                                   END
                       ),
                       0
               ),
               2
       )                                                                           AS bowling_strike_rate

FROM players
         LEFT JOIN teams
                   ON players.team_id = teams.team_id
         LEFT JOIN deliveries
                   ON players.player_id = deliveries.bowler_id

GROUP BY players.player_id,
         players.player_name,
         teams.team_name;

----------------------------------------------------------
-- Team Statistics
----------------------------------------------------------

CREATE OR REPLACE VIEW team_statistics AS
SELECT teams.team_name,

       SUM(
               CASE
                   WHEN matches.team1_id = teams.team_id
                       OR matches.team2_id = teams.team_id
                       THEN 1
                   ELSE 0
                   END
       ) AS matches,

       SUM(
               CASE
                   WHEN matches.winner_team_id = teams.team_id
                       THEN 1
                   ELSE 0
                   END
       ) AS wins,

       SUM(
               CASE
                   WHEN matches.toss_winner_id = teams.team_id
                       THEN 1
                   ELSE 0
                   END
       ) AS tosses_won,

       SUM(
               CASE
                   WHEN matches.toss_winner_id = teams.team_id
                       AND matches.winner_team_id = teams.team_id
                       THEN 1
                   ELSE 0
                   END
       ) AS toss_conversion_wins,

       ROUND(
               SUM(
                       CASE
                           WHEN matches.winner_team_id = teams.team_id
                               THEN 1
                           ELSE 0
                           END
               ) * 100.0
                   /
               NULLIF(
                       SUM(
                               CASE
                                   WHEN matches.team1_id = teams.team_id
                                       OR matches.team2_id = teams.team_id
                                       THEN 1
                                   ELSE 0
                                   END
                       ),
                       0
               ),
               2
       ) AS win_percentage,

       ROUND(
               SUM(
                       CASE
                           WHEN matches.toss_winner_id = teams.team_id
                               AND matches.winner_team_id = teams.team_id
                               THEN 1
                           ELSE 0
                           END
               ) * 100.0
                   /
               NULLIF(
                       SUM(
                               CASE
                                   WHEN matches.toss_winner_id = teams.team_id
                                       THEN 1
                                   ELSE 0
                                   END
                       ),
                       0
               ),
               2
       ) AS toss_conversion_rate

FROM teams
         LEFT JOIN matches
                   ON teams.team_id = matches.team1_id
                       OR teams.team_id = matches.team2_id

GROUP BY teams.team_id,
         teams.team_name;

----------------------------------------------------------
-- Venue Statistics
----------------------------------------------------------

CREATE OR REPLACE VIEW venue_statistics AS
WITH innings_totals AS (SELECT deliveries.match_id,
                               deliveries.innings_number,
                               SUM(
                                       deliveries.batter_runs +
                                       deliveries.wide_runs +
                                       deliveries.noball_runs +
                                       deliveries.bye_runs +
                                       deliveries.legbye_runs
                               ) AS total_runs
                        FROM deliveries
                        GROUP BY deliveries.match_id,
                                 deliveries.innings_number)

SELECT venues.venue_name,
       venues.city,

       COUNT(DISTINCT matches.match_id)              AS matches_played,

       AVG(innings_totals.total_runs)::NUMERIC(6, 2) AS average_first_innings_score,

       MAX(innings_totals.total_runs)                AS highest_first_innings_score,

       MIN(innings_totals.total_runs)                AS lowest_first_innings_score

FROM venues
         JOIN matches
              ON venues.venue_id = matches.venue_id
         JOIN innings_totals
              ON matches.match_id = innings_totals.match_id
                  AND innings_totals.innings_number = 1

GROUP BY venues.venue_id,
         venues.venue_name,
         venues.city;

----------------------------------------------------------
-- Player Performance by Venue
----------------------------------------------------------

CREATE OR REPLACE VIEW player_venue_statistics AS
SELECT players.player_name,
       teams.team_name,
       venues.venue_name,

       COALESCE(SUM(deliveries.batter_runs), 0) AS runs,

       SUM(
               CASE
                   WHEN deliveries.wide_runs = 0 THEN 1
                   ELSE 0
                   END
       )                                        AS balls_faced,

       SUM(
               CASE
                   WHEN deliveries.dismissed_batter_id = players.player_id THEN 1
                   ELSE 0
                   END
       )                                        AS dismissals,

       ROUND(
               COALESCE(SUM(deliveries.batter_runs), 0)::NUMERIC
                   /
               NULLIF(
                       SUM(
                               CASE
                                   WHEN deliveries.dismissed_batter_id = players.player_id THEN 1
                                   ELSE 0
                                   END
                       ),
                       0
               ),
               2
       )                                        AS batting_average,

       ROUND(
               COALESCE(SUM(deliveries.batter_runs), 0)::NUMERIC * 100
                   /
               NULLIF(
                       SUM(
                               CASE
                                   WHEN deliveries.wide_runs = 0 THEN 1
                                   ELSE 0
                                   END
                       ),
                       0
               ),
               2
       )                                        AS strike_rate

FROM players
         LEFT JOIN teams
                   ON players.team_id = teams.team_id
         LEFT JOIN deliveries
                   ON players.player_id = deliveries.batter_id
         LEFT JOIN matches
                   ON deliveries.match_id = matches.match_id
         LEFT JOIN venues
                   ON matches.venue_id = venues.venue_id

GROUP BY players.player_id,
         players.player_name,
         teams.team_name,
         venues.venue_id,
         venues.venue_name;

----------------------------------------------------------
-- Orange Cap Progression
----------------------------------------------------------

CREATE OR REPLACE VIEW orange_cap_progression AS
WITH player_match_runs AS (SELECT matches.match_id,
                                  matches.match_date,
                                  players.player_name,
                                  SUM(deliveries.batter_runs) AS runs
                           FROM matches
                                    LEFT JOIN deliveries
                                              ON matches.match_id = deliveries.match_id
                                    LEFT JOIN players
                                              ON deliveries.batter_id = players.player_id
                           GROUP BY matches.match_id,
                                    matches.match_date,
                                    players.player_name),

     cumulative_runs AS (SELECT match_id,
                                match_date,
                                player_name,
                                runs,
                                SUM(runs) OVER (
                                    PARTITION BY player_name
                                    ORDER BY match_date, match_id
                                    ) AS cumulative_runs
                         FROM player_match_runs)

SELECT match_id,
       match_date,
       player_name,
       runs,
       cumulative_runs,
       DENSE_RANK() OVER (
           PARTITION BY match_id
           ORDER BY cumulative_runs DESC
           ) AS orange_cap_rank
FROM cumulative_runs;

----------------------------------------------------------
-- Purple Cap Progression
----------------------------------------------------------

CREATE OR REPLACE VIEW purple_cap_progression AS
WITH player_match_wickets AS (SELECT matches.match_id,
                                     matches.match_date,
                                     players.player_name,
                                     SUM(
                                             CASE
                                                 WHEN deliveries.is_wicket
                                                     AND deliveries.dismissal_type IN ('Caught', 'Bowled')
                                                     THEN 1
                                                 ELSE 0
                                                 END
                                     ) AS wickets
                              FROM matches
                                       LEFT JOIN deliveries
                                                 ON matches.match_id = deliveries.match_id
                                       LEFT JOIN players
                                                 ON deliveries.bowler_id = players.player_id
                              GROUP BY matches.match_id,
                                       matches.match_date,
                                       players.player_name),

     cumulative_wickets AS (SELECT match_id,
                                   match_date,
                                   player_name,
                                   wickets,
                                   SUM(wickets) OVER (
                                       PARTITION BY player_name
                                       ORDER BY match_date, match_id
                                       ) AS cumulative_wickets
                            FROM player_match_wickets)

SELECT match_id,
       match_date,
       player_name,
       wickets,
       cumulative_wickets,
       DENSE_RANK() OVER (
           PARTITION BY match_id
           ORDER BY cumulative_wickets DESC
           ) AS purple_cap_rank
FROM cumulative_wickets;

----------------------------------------------------------
-- Batting First vs Chasing
----------------------------------------------------------

CREATE OR REPLACE VIEW batting_first_vs_chasing AS
SELECT teams.team_name,

       SUM(
               CASE
                   WHEN innings.innings_number = 1
                       AND innings.batting_team_id = teams.team_id
                       THEN 1
                   ELSE 0
                   END
       ) AS matches_batted_first,

       SUM(
               CASE
                   WHEN innings.innings_number = 1
                       AND innings.batting_team_id = teams.team_id
                       AND matches.winner_team_id = teams.team_id
                       THEN 1
                   ELSE 0
                   END
       ) AS wins_batting_first,

       ROUND(
               SUM(
                       CASE
                           WHEN innings.innings_number = 1
                               AND innings.batting_team_id = teams.team_id
                               AND matches.winner_team_id = teams.team_id
                               THEN 1
                           ELSE 0
                           END
               ) * 100.0 /
               NULLIF(
                       SUM(
                               CASE
                                   WHEN innings.innings_number = 1
                                       AND innings.batting_team_id = teams.team_id
                                       THEN 1
                                   ELSE 0
                                   END
                       ),
                       0
               ),
               2
       ) AS win_percentage_batting_first,

       SUM(
               CASE
                   WHEN innings.innings_number = 2
                       AND innings.batting_team_id = teams.team_id
                       THEN 1
                   ELSE 0
                   END
       ) AS matches_chased,

       SUM(
               CASE
                   WHEN innings.innings_number = 2
                       AND innings.batting_team_id = teams.team_id
                       AND matches.winner_team_id = teams.team_id
                       THEN 1
                   ELSE 0
                   END
       ) AS wins_chasing,

       ROUND(
               SUM(
                       CASE
                           WHEN innings.innings_number = 2
                               AND innings.batting_team_id = teams.team_id
                               AND matches.winner_team_id = teams.team_id
                               THEN 1
                           ELSE 0
                           END
               ) * 100.0 /
               NULLIF(
                       SUM(
                               CASE
                                   WHEN innings.innings_number = 2
                                       AND innings.batting_team_id = teams.team_id
                                       THEN 1
                                   ELSE 0
                                   END
                       ),
                       0
               ),
               2
       ) AS win_percentage_chasing

FROM teams
         LEFT JOIN innings
                   ON innings.batting_team_id = teams.team_id
         LEFT JOIN matches
                   ON innings.match_id = matches.match_id

GROUP BY teams.team_id,
         teams.team_name;

/*
==========================================================
End of Views
==========================================================
*/