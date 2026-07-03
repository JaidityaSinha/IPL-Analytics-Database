/*
==========================================================
IPL Analytics Database
Indexes
==========================================================

Author  : Jaiditya Sinha
Database: PostgreSQL
Project : IPL Analytics Database

Description
-----------
This file creates indexes to improve query performance
for common analytical workloads.

==========================================================
*/

----------------------------------------------------------
-- Primary Analytics Indexes
----------------------------------------------------------

CREATE INDEX idx_deliveries_batter
ON deliveries(batter_id);

CREATE INDEX idx_deliveries_bowler
ON deliveries(bowler_id);

CREATE INDEX idx_matches_venue
ON matches(venue_id);

CREATE INDEX idx_matches_date
ON matches(match_date);

CREATE INDEX idx_players_team
ON players(team_id);

CREATE INDEX idx_innings_batting_team
ON innings(batting_team_id);

CREATE INDEX idx_innings_bowling_team
ON innings(bowling_team_id);


----------------------------------------------------------
-- Composite Indexes
----------------------------------------------------------

CREATE INDEX idx_deliveries_bowler_match
ON deliveries(bowler_id, match_id);

CREATE INDEX idx_matches_teams
ON matches(team1_id, team2_id);

CREATE INDEX idx_deliveries_dismissal_type
ON deliveries(dismissal_type, bowler_id);


----------------------------------------------------------
-- End of Indexes
----------------------------------------------------------

