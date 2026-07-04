CREATE TABLE ipl.teams (
	team_id     SERIAL PRIMARY KEY,
	team_name   VARCHAR NOT NULL UNIQUE
);

CREATE TABLE ipl.players (
	player_id       SERIAL PRIMARY KEY,
	player_name     VARCHAR NOT NULL,
	nationality     VARCHAR NOT NULL,
	role            VARCHAR,
	team_id         INT NOT NULL REFERENCES ipl.teams(team_id)
);

CREATE TABLE ipl.venues (
	venue_id    SERIAL PRIMARY KEY,
	venue_name  VARCHAR NOT NULL UNIQUE,
	city        VARCHAR NOT NULL
);

create table ipl.matches
(
    match_id       serial
        primary key,
    match_date     date    not null,
    venue_id       integer not null
        references venues,
    team1_id       integer not null
        references teams,
    team2_id       integer not null
        references teams,
    winner_team_id integer
        references teams,
    toss_winner_id integer
        references teams,
    toss_decision  varchar(10),
    constraint different_teams
        check (team1_id <> team2_id),
    constraint valid_winner
        check ((winner_team_id IS NULL) OR (winner_team_id = team1_id) OR (winner_team_id = team2_id))
);

CREATE TABLE ipl.innings (
	innings_number  INT NOT NULL,
	match_id        INT NOT NULL REFERENCES ipl.matches(match_id),
	batting_team_id INT NOT NULL REFERENCES ipl.teams(team_id),
	bowling_team_id INT NOT NULL REFERENCES ipl.teams(team_id),

	PRIMARY KEY(match_id, innings_number),

	CONSTRAINT different_teams 
	CHECK(batting_team_id != bowling_team_id)
);

CREATE TABLE ipl.deliveries (
	delivery_id SERIAL PRIMARY KEY,

	match_id        INT NOT NULL REFERENCES ipl.matches(match_id),
	innings_number  INT NOT NULL,

	over_number INT NOT NULL,
	ball_number INT NOT NULL,

	batter_id INT NOT NULL REFERENCES ipl.players(player_id),
	bowler_id INT NOT NULL REFERENCES ipl.players(player_id),

	batter_runs INT NOT NULL CHECK(batter_runs >= 0),
	wide_runs   INT NOT NULL CHECK(wide_runs >= 0),
	noball_runs INT NOT NULL CHECK(noball_runs >= 0),
	bye_runs    INT NOT NULL CHECK(bye_runs >= 0),
	legbye_runs INT NOT NULL CHECK(legbye_runs >= 0),

	is_wicket BOOL      NOT NULL,
	dismissal_type      VARCHAR,
	dismissed_batter_id INT REFERENCES ipl.players(player_id),
	fielder_id          INT REFERENCES ipl.players(player_id),

    CHECK (
        (is_wicket = TRUE  AND dismissal_type IS NOT NULL)
        OR
        (is_wicket = FALSE AND dismissal_type IS NULL)
    ),

	FOREIGN KEY(match_id, innings_number) REFERENCES ipl.innings(match_id, innings_number)
);