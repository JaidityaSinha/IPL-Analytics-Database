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


def main():
    connection = get_connection()

    team_ids = load_teams(connection)
    player_ids = load_players(connection, team_ids)

    print(f"Imported {len(team_ids)} teams")
    print(f"Imported {len(player_ids)} players")

    connection.close()


if __name__ == "__main__":
    main()
