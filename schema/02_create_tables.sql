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

create table innings
(
    innings_number  integer not null
        constraint valid_innings_number
            check (innings_number = ANY (ARRAY [1, 2])),
    match_id        integer not null
        references matches,
    batting_team_id integer not null
        references teams,
    bowling_team_id integer not null
        references teams,
    primary key (match_id, innings_number),
    constraint different_teams
        check (batting_team_id <> bowling_team_id)
);

create table deliveries
(
    delivery_id         serial
        primary key,
    match_id            integer not null
        references matches,
    innings_number      integer not null,
    over_number         integer not null
        constraint valid_over_number
            check ((over_number >= 1) AND (over_number <= 20)),
    ball_number         integer not null
        constraint valid_ball_number
            check ((ball_number >= 1) AND (ball_number <= 10)),
    batter_id           integer not null
        references players,
    bowler_id           integer not null
        references players,
    batter_runs         integer not null
        constraint deliveries_batter_runs_check
            check (batter_runs >= 0),
    wide_runs           integer not null
        constraint deliveries_wide_runs_check
            check (wide_runs >= 0),
    noball_runs         integer not null
        constraint deliveries_noball_runs_check
            check (noball_runs >= 0),
    bye_runs            integer not null
        constraint deliveries_bye_runs_check
            check (bye_runs >= 0),
    legbye_runs         integer not null
        constraint deliveries_legbye_runs_check
            check (legbye_runs >= 0),
    is_wicket           boolean not null,
    dismissal_type      varchar,
    dismissed_batter_id integer
        references players,
    fielder_id          integer
        references players,
    foreign key (match_id, innings_number) references innings,
    constraint valid_wicket_info
        check (((is_wicket = false) AND (dismissal_type IS NULL) AND (dismissed_batter_id IS NULL)) OR
               ((is_wicket = true) AND (dismissal_type IS NOT NULL) AND (dismissed_batter_id IS NOT NULL)))
);