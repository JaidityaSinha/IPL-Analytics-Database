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
            INSERT INTO teams(team_name)
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


def main():
    connection = get_connection()

    team_ids = load_teams(connection)

    print(team_ids)

    connection.close()


if __name__ == "__main__":
    main()