import pandas as pd

from database import get_connection


def load_teams(connection):
    dataframe = pd.read_csv("../data/squads.csv")

    cursor = connection.cursor()

    team_ids = {}

    teams = sorted(dataframe["team_name"].unique())

    for team in teams:
        cursor.execute(
            """
            INSERT INTO teams (team_name)
            VALUES (%s)
            RETURNING team_id;
            """,
            (team,)
        )

        team_id = cursor.fetchone()[0]
        team_ids[team] = team_id

    connection.commit()
    cursor.close()

    return team_ids


def load_players(connection, team_ids):
    dataframe = pd.read_csv("../data/squads.csv")

    cursor = connection.cursor()

    player_ids = {}

    for _, row in dataframe.iterrows():
        cursor.execute(
            """
            INSERT INTO players (
                player_name,
                nationality,
                role,
                team_id
            )
            VALUES (%s, %s, %s, %s)
            RETURNING player_id;
            """,
            (
                row["player"],
                row["nationality"],
                row["role"],
                team_ids[row["team_name"]]
            )
        )

        player_id = cursor.fetchone()[0]
        player_ids[row["player"]] = player_id

    connection.commit()
    cursor.close()

    return player_ids


def load_venues(connection):
    dataframe = pd.read_csv("../data/venues.csv")

    cursor = connection.cursor()

    venue_ids = {}

    for _, row in dataframe.iterrows():
        cursor.execute(
            """
            INSERT INTO venues (
                venue_name,
                city
            )
            VALUES (%s, %s)
            RETURNING venue_id;
            """,
            (
                row["venue_stadium"],
                row["city"]
            )
        )

        venue_id = cursor.fetchone()[0]
        venue_ids[row["venue_stadium"]] = venue_id

    connection.commit()
    cursor.close()

    return venue_ids


def load_matches(connection, team_ids, venue_ids):
    dataframe = pd.read_csv("../data/matches.csv")

    dataframe["date"] = pd.to_datetime(
        dataframe["date"],
        format="%B %d, %Y"
    )

    venue_name_map = {
        "Arun Jaitley Stadium, Delhi": "Arun Jaitley Stadium",
        "Barsapara Stadium, Guwahati": "Barsapara Stadium",
        "Eden Gardens, Kolkata": "Eden Gardens",
        "Ekana Cricket Stadium, Lucknow": "Ekana Cricket Stadium",
        "M. Chinnaswamy Stadium, Bangalore": "M. Chinnaswamy Stadium",
        "MA Chidambaram Stadium, Chennai": "MA Chidambaram Stadium",
        "Narendra Modi Stadium, Ahmedabad": "Narendra Modi Stadium",
        "New PCA Cricket Stadium, Mullanpur": "New PCA Cricket Stadium",
        "Rajiv Gandhi International Stadium, Hyderabad": "Rajiv Gandhi International Stadium",
        "Sawai Mansingh Stadium, Jaipur": "Sawai Mansingh Stadium",
        "Wankhede Stadium, Mumbai": "Wankhede Stadium",
    }

    team_name_map = {
        "CSK": "Chennai Super Kings",
        "MI": "Mumbai Indians",
        "RCB": "Royal Challengers Bengaluru",
        "KKR": "Kolkata Knight Riders",
        "SRH": "Sunrisers Hyderabad",
        "DC": "Delhi Capitals",
        "PBKS": "Punjab Kings",
        "GT": "Gujarat Titans",
        "RR": "Rajasthan Royals",
        "LSG": "Lucknow Super Giants",
    }

    cursor = connection.cursor()

    match_ids = {}

    for _, row in dataframe.iterrows():

        venue_name = venue_name_map.get(
            row["venue"],
            row["venue"]
        )

        team1 = team_name_map.get(
            row["team1"],
            row["team1"]
        )

        team2 = team_name_map.get(
            row["team2"],
            row["team2"]
        )

        winner_team_id = None

        if pd.notna(row["match_winner"]):
            winner = str(row["match_winner"]).strip()

            if winner not in ("", "No Result", "Tie", "Abandoned"):
                winner = team_name_map.get(winner, winner)

                if winner in team_ids:
                    winner_team_id = team_ids[winner]

        cursor.execute(
            """
            INSERT INTO matches (
                match_date,
                venue_id,
                team1_id,
                team2_id,
                winner_team_id
            )
            VALUES (%s, %s, %s, %s, %s)
            RETURNING match_id;
            """,
            (
                row["date"].date(),
                venue_ids[venue_name],
                team_ids[team1],
                team_ids[team2],
                winner_team_id
            )
        )

        match_id = cursor.fetchone()[0]
        match_ids[row["match_id"]] = match_id

    connection.commit()
    cursor.close()

    return match_ids


def main():
    connection = get_connection()

    team_ids = load_teams(connection)
    player_ids = load_players(connection, team_ids)
    venue_ids = load_venues(connection)
    match_ids = load_matches(connection, team_ids, venue_ids)

    print(f"Imported {len(team_ids)} teams")
    print(f"Imported {len(player_ids)} players")
    print(f"Imported {len(venue_ids)} venues")
    print(f"Imported {len(match_ids)} matches")

    connection.close()


if __name__ == "__main__":
    main()