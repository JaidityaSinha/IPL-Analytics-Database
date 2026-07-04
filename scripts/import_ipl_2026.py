import pandas as pd

from database import get_connection

TEAM_NAME_MAP = {
    "CSK": "Chennai Super Kings",
    "MI": "Mumbai Indians",
    "RCB": "Royal Challengers Bengaluru",
    "KKR": "Kolkata Knight Riders",
    "SRH": "Sunrisers Hyderabad",
    "DC": "Delhi Capitals",
    "PBKS": "Punjab Kings",
    "GT": "Gujarat Titans",
    "RR": "Rajasthan Royals",
    "LSG": "Lucknow Super Giants"
}

ROLE_MAP = {
    "BAT": "Batter",
    "BOWL": "Bowler",
    "AR": "All-Rounder",
    "WK": "Wicket-Keeper"
}

VENUE_NAME_MAP = {
    "Narendra Modi Stadium, Ahmedabad": "Narendra Modi Stadium",
    "M. Chinnaswamy Stadium, Bangalore": "M. Chinnaswamy Stadium",
    "MA Chidambaram Stadium, Chennai": "MA Chidambaram Stadium",
    "Arun Jaitley Stadium, Delhi": "Arun Jaitley Stadium",
    "HPCA Stadium, Dharamsala": "HPCA Stadium",
    "HPCA Stadium, Dharamshala": "HPCA Stadium",
    "Barsapara Stadium, Guwahati": "Barsapara Cricket Stadium",
    "Rajiv Gandhi International Stadium, Hyderabad": "Rajiv Gandhi Intl. Stadium",
    "Sawai Mansingh Stadium, Jaipur": "Sawai Mansingh Stadium",
    "Eden Gardens, Kolkata": "Eden Gardens",
    "Ekana Cricket Stadium, Lucknow": "BRSABV Ekana Cricket Stadium",
    "Wankhede Stadium, Mumbai": "Wankhede Stadium",
    "New PCA Cricket Stadium, Mullanpur": "Maharaja Yadavindra Singh Int. Stadium",
    "ACA-VDCA Cricket Stadium, Vishakhapatnam": "ACA-VDCA Cricket Stadium"
}

PLAYER_NAME_MAP = {
    "de Kock": "Quinton de Kock",
    "Sai Kishore": "R Sai Kishore",
    "Rahul": "KL Rahul",
    "Varun Chakaravarthy": "Varun Chakravarthy",
    "Rohit": "Rohit Sharma",
    "Nitish Reddy": "Nitish Kumar Reddy",
    "Chahar": "Deepak Chahar",
    "Axar": "Axar Patel",
    "du Plessis": "Faf du Plessis",

    "M Siddharth": "Manimaran Siddharth",
    "Digvesh Rathi": "Digvesh Singh",
    "Mujeeb": "Mujeeb Ur Rahman",
    "Mulder": "Wiaan Mulder",
    "Brevis": "Dewald Brevis",
    "Jamieson": "Kyle Jamieson",
    "Bairstow": "Jonny Bairstow",
    "Mustafizur": "Mustafizur Rahman",
    "Sakariya": "Chetan Sakariya",
    "N Thushara": "Nuwan Thushara",
    "Prabhsimran": "Prabhsimran Singh",
    "Prasidh": "Prasidh Krishna",
    "Azmatullah": "Azmatullah Omarzai",
    "Bhuvneshwar": "Bhuvneshwar Kumar",
    "Shahrukh Khan": "M Shahrukh Khan",
    "Raj Bawa": "hello",
}

def load_teams(connection):
    dataframe = pd.read_csv("../data/auction.csv")

    dataframe = dataframe[dataframe["Team"] != "-"]

    cursor = connection.cursor()

    team_ids = {}

    teams = sorted(
        TEAM_NAME_MAP[team]
        for team in dataframe["Team"].unique()
    )

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
    dataframe = pd.read_csv("../data/auction.csv")

    # Ignore unsold players
    dataframe = dataframe[dataframe["Team"] != "-"]

    cursor = connection.cursor()

    player_ids = {}

    for _, row in dataframe.iterrows():

        team_name = TEAM_NAME_MAP.get(row["Team"], row["Team"])
        role = ROLE_MAP.get(row["Type"], row["Type"])

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
                row["Players"].strip(),
                None,
                role,
                team_ids[team_name]
            )
        )

        player_id = cursor.fetchone()[0]
        player_ids[row["Players"].strip()] = player_id

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
                row["Stadium Name"].strip(),
                row["City"].strip()
            )
        )

        venue_id = cursor.fetchone()[0]
        venue_ids[row["Stadium Name"].strip()] = venue_id

    connection.commit()
    cursor.close()

    return venue_ids

def load_matches(connection, team_ids, venue_ids):
    dataframe = pd.read_csv("../data/matches.csv")

    cursor = connection.cursor()

    match_ids = {}

    for _, row in dataframe.iterrows():

        match_date = pd.to_datetime(
            row["date"],
            format="%B %d,%Y"
        ).date()

        venue_name = VENUE_NAME_MAP.get(
            row["venue"],
            row["venue"]
        )

        team1 = TEAM_NAME_MAP.get(
            row["team1"],
            row["team1"]
        )

        team2 = TEAM_NAME_MAP.get(
            row["team2"],
            row["team2"]
        )

        # Handle toss winner (may be NULL for abandoned matches)
        toss_winner_id = None

        if pd.notna(row["toss_winner"]):
            toss_winner = TEAM_NAME_MAP.get(
                row["toss_winner"],
                row["toss_winner"]
            )
            toss_winner_id = team_ids[toss_winner]

        # Handle toss decision (may be NULL)
        toss_decision = None

        if pd.notna(row["toss_decision"]):
            toss_decision = row["toss_decision"].strip().lower()

        # Handle winner (may be NULL)
        winner_team_id = None

        if pd.notna(row["match_winner"]):
            winner = str(row["match_winner"]).strip()

            if winner not in ("", "No Result", "Tie", "Abandoned"):
                winner = TEAM_NAME_MAP.get(
                    winner,
                    winner
                )
                winner_team_id = team_ids[winner]

        cursor.execute(
            """
            INSERT INTO matches (
                match_date,
                venue_id,
                team1_id,
                team2_id,
                winner_team_id,
                toss_winner_id,
                toss_decision
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING match_id;
            """,
            (
                match_date,
                venue_ids[venue_name],
                team_ids[team1],
                team_ids[team2],
                winner_team_id,
                toss_winner_id,
                toss_decision
            )
        )

        match_id = cursor.fetchone()[0]
        match_ids[row["match_id"]] = match_id

    connection.commit()
    cursor.close()

    return match_ids

def load_innings(connection, match_ids, team_ids):
    dataframe = pd.read_csv("../data/matches.csv")

    cursor = connection.cursor()

    innings_count = 0

    for _, row in dataframe.iterrows():

        # Skip matches where the toss never happened
        if pd.isna(row["toss_winner"]) or pd.isna(row["toss_decision"]):
            continue

        team1 = TEAM_NAME_MAP.get(
            row["team1"],
            row["team1"]
        )

        team2 = TEAM_NAME_MAP.get(
            row["team2"],
            row["team2"]
        )

        toss_winner = TEAM_NAME_MAP.get(
            row["toss_winner"],
            row["toss_winner"]
        )

        if toss_winner == team1:
            other_team = team2
        else:
            other_team = team1

        if row["toss_decision"].strip().lower() == "bat":
            batting_first = toss_winner
            bowling_first = other_team
        else:
            batting_first = other_team
            bowling_first = toss_winner

        match_id = match_ids[row["match_id"]]

        # First innings
        cursor.execute(
            """
            INSERT INTO innings (
                innings_number,
                match_id,
                batting_team_id,
                bowling_team_id
            )
            VALUES (%s, %s, %s, %s);
            """,
            (
                1,
                match_id,
                team_ids[batting_first],
                team_ids[bowling_first]
            )
        )

        # Second innings
        cursor.execute(
            """
            INSERT INTO innings (
                innings_number,
                match_id,
                batting_team_id,
                bowling_team_id
            )
            VALUES (%s, %s, %s, %s);
            """,
            (
                2,
                match_id,
                team_ids[bowling_first],
                team_ids[batting_first]
            )
        )

        innings_count += 2

    connection.commit()
    cursor.close()

    return innings_count

def clean_player_name(name):
    if pd.isna(name):
        return None

    name = str(name).strip()

    # Remove substitute tag
    name = name.replace("(sub)", "").strip()

    # Keep only the first player if multiple fielders are listed
    if "/" in name:
        name = name.split("/")[0].strip()

    return name

def resolve_player_name(name, player_ids):
    if name is None:
        return None

    name = name.strip()

    # ----------------------------
    # 1. Exact match
    # ----------------------------
    if name in player_ids:
        return name

    # ----------------------------
    # 2. Manual mapping
    # ----------------------------
    if name in PLAYER_NAME_MAP:
        return PLAYER_NAME_MAP[name]

    # ----------------------------
    # 3. Surname match
    # ----------------------------
    surname_matches = [
        player
        for player in player_ids
        if player.split()[-1].lower() == name.lower()
    ]

    if len(surname_matches) == 1:
        return surname_matches[0]

    # ----------------------------
    # 4. First name match
    # ----------------------------
    first_name_matches = [
        player
        for player in player_ids
        if player.split()[0].lower() == name.lower()
    ]

    if len(first_name_matches) == 1:
        return first_name_matches[0]

    # ----------------------------
    # 5. Could not resolve
    # ----------------------------
    print(f"Could not resolve player: {name}")
    return None

def load_deliveries(connection, match_ids, player_ids):
    dataframe = pd.read_csv("../data/deliveries.csv")

    dataframe = dataframe[dataframe["innings"].isin([1, 2])]

    cursor = connection.cursor()

    delivery_count = 0

    for _, row in dataframe.iterrows():

        # Skip deliveries from matches that were never imported
        if row["match_no"] not in match_ids:
            continue

        over = str(row["over"])

        over_number = int(over.split(".")[0]) + 1
        ball_number = int(over.split(".")[1])


        batter = resolve_player_name(
            clean_player_name(row["striker"]),
            player_ids
        )


        bowler = resolve_player_name(
            clean_player_name(row["bowler"]),
            player_ids
        )

        if batter is None or bowler is None:
            continue

        is_wicket = pd.notna(row["wicket_type"])

        dismissal_type = None
        dismissed_batter_id = None
        fielder_id = None

        if is_wicket:

            dismissal_type = row["wicket_type"]

            dismissed_player = clean_player_name(
                row["player_dismissed"]
            )

            if dismissed_player is not None:
                dismissed_player = resolve_player_name(
                    dismissed_player,
                    player_ids
                )

                if dismissed_player is not None:
                    dismissed_batter_id = player_ids[dismissed_player]

            fielder = clean_player_name(row["fielder"])

            if fielder is not None:
                fielder = resolve_player_name(fielder, player_ids)

                if fielder is not None:
                    fielder_id = player_ids[fielder]

        cursor.execute(
            """
            INSERT INTO deliveries (
                match_id,
                innings_number,
                over_number,
                ball_number,
                batter_id,
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
            VALUES (
                %s, %s, %s, %s,
                %s, %s,
                %s, %s, %s, %s, %s,
                %s, %s, %s, %s
            );
            """,
            (
                match_ids[row["match_no"]],
                row["innings"],
                over_number,
                ball_number,
                player_ids[batter],
                player_ids[bowler],
                row["runs_of_bat"],
                row["wide"],
                row["noballs"],
                row["byes"],
                row["legbyes"],
                is_wicket,
                dismissal_type,
                dismissed_batter_id,
                fielder_id
            )
        )

        delivery_count += 1

    connection.commit()
    cursor.close()

    return delivery_count

def main():
    connection = get_connection()

    team_ids = load_teams(connection)
    player_ids = load_players(connection, team_ids)
    venue_ids = load_venues(connection)
    match_ids = load_matches(connection, team_ids, venue_ids)
    innings_count = load_innings(connection, match_ids, team_ids)
    delivery_count = load_deliveries(
        connection,
        match_ids,
        player_ids
    )


    print(delivery_count)

    connection.close()


if __name__ == "__main__":
    main()