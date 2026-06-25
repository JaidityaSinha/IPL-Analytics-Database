-- =====================================================
-- IPL Analytics Database
-- File: 03_seed_data.sql
--
-- Inserts sample data for:
-- - Teams
-- - Venues
-- - Players
-- - Matches
-- - Innings
-- - Deliveries
-- =====================================================

-- =====================================================
-- Teams
-- =====================================================

INSERT INTO teams (team_name)
VALUES
    ('Chennai Super Kings'),
    ('Mumbai Indians');



-- =====================================================
-- Venues
-- =====================================================

INSERT INTO venues (venue_name, city)
VALUES
    ('MA Chidambaram Stadium', 'Chennai');



-- =====================================================
-- Players
-- =====================================================

INSERT INTO players (player_name, dob, nationality, batting_style, bowling_style, team_id)
VALUES
    ('Ruturaj Gaikwad', '1997-01-31', 'India',
     'Right-hand bat', 'Right-arm off-break', 1),

    ('MS Dhoni', '1981-07-07', 'India',
     'Right-hand bat', NULL, 1),

    ('Shivam Dube', '1993-06-26', 'India',
     'Left-hand bat', 'Right-arm medium', 1),

    ('Noor Ahmad', '2005-01-03', 'Afghanistan',
     'Left-hand bat', 'Left-arm unorthodox spin', 1),

    ('Anshul Kamboj', '2000-12-06', 'India',
     'Right-hand bat', 'Right-arm medium-fast', 1),

    ('Rohit Sharma', '1987-04-30', 'India',
     'Right-hand bat', NULL, 2),

    ('Suryakumar Yadav', '1990-09-14', 'India',
     'Right-hand bat', NULL, 2),

    ('Hardik Pandya', '1993-10-11', 'India',
     'Right-hand bat', 'Right-arm medium-fast', 2),

    ('Tilak Varma', '2002-11-08', 'India',
     'Left-hand bat', 'Right-arm off-break', 2),

    ('Jasprit Bumrah', '1993-12-06', 'India',
     'Right-hand bat', 'Right-arm fast', 2);



-- =====================================================
-- Matches
-- =====================================================

INSERT INTO matches
(match_date, venue_id, team1_id, team2_id, winner_team_id, toss_winner_id, toss_decision)
VALUES
('2026-05-02', 1, 1, 2, 1, 2, 'BOWL');



-- =====================================================
-- Innings
-- =====================================================

INSERT INTO innings (innings_number, match_id, batting_team_id, bowling_team_id)
VALUES
    (1, 1, 1, 2),
    (2, 1, 2, 1);



-- =====================================================
-- Deliveries
-- =====================================================

INSERT INTO deliveries (
    match_id,
    innings_number,
    over_number,
    ball_number,
    batter_id,
    non_striker_id,
    bowler_id,
    batter_runs,
    wide_runs,
    noball_runs,
    bye_runs,
    legbye_runs,
    is_wicket,
    dismissal_type,
    dismissed_batter_id,
    fielder_id
)
VALUES

-- ===========================
-- Innings 1 : CSK Batting
-- ===========================

(1,1,1,1,1,3,10,1,0,0,0,0,FALSE,NULL,NULL,NULL),
(1,1,1,2,3,1,10,4,0,0,0,0,FALSE,NULL,NULL,NULL),
(1,1,1,3,3,1,10,0,0,0,0,0,FALSE,NULL,NULL,NULL),
(1,1,1,4,3,1,10,2,0,0,0,0,FALSE,NULL,NULL,NULL),
(1,1,1,5,3,1,10,0,1,0,0,0,FALSE,NULL,NULL,NULL),
(1,1,1,6,3,1,10,6,0,0,0,0,FALSE,NULL,NULL,NULL),
(1,1,1,7,3,1,10,1,0,0,0,0,FALSE,NULL,NULL,NULL),

(1,1,2,1,1,3,8,4,0,0,0,0,FALSE,NULL,NULL,NULL),
(1,1,2,2,1,3,8,0,0,0,0,0,TRUE,'Caught',1,6),
(1,1,2,3,2,3,8,1,0,0,0,0,FALSE,NULL,NULL,NULL),
(1,1,2,4,3,2,8,2,0,0,0,0,FALSE,NULL,NULL,NULL),
(1,1,2,5,3,2,8,4,0,0,0,0,FALSE,NULL,NULL,NULL),
(1,1,2,6,3,2,8,1,0,0,0,0,FALSE,NULL,NULL,NULL),

-- ===========================
-- Innings 2 : MI Batting
-- ===========================

(1,2,1,1,6,7,5,1,0,0,0,0,FALSE,NULL,NULL,NULL),
(1,2,1,2,7,6,5,0,0,0,0,0,FALSE,NULL,NULL,NULL),
(1,2,1,3,7,6,5,4,0,0,0,0,FALSE,NULL,NULL,NULL),
(1,2,1,4,7,6,5,1,0,0,0,0,FALSE,NULL,NULL,NULL),
(1,2,1,5,6,7,5,0,0,0,0,0,TRUE,'Bowled',6,NULL),
(1,2,1,6,8,7,5,2,0,0,0,0,FALSE,NULL,NULL,NULL),

(1,2,2,1,7,8,4,6,0,0,0,0,FALSE,NULL,NULL,NULL),
(1,2,2,2,7,8,4,1,0,0,0,0,FALSE,NULL,NULL,NULL),
(1,2,2,3,8,7,4,0,0,0,0,0,FALSE,NULL,NULL,NULL),
(1,2,2,4,8,7,4,1,0,0,0,0,FALSE,NULL,NULL,NULL),
(1,2,2,5,7,8,4,4,0,0,0,0,FALSE,NULL,NULL,NULL),
(1,2,2,6,7,8,4,1,0,0,0,0,FALSE,NULL,NULL,NULL);

-- =====================================================
-- End of Seed Data
-- =====================================================