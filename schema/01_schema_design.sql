/*
==========================================================
IPL Analytics Database
Schema Design
==========================================================

Author: Jaiditya Sinha
Database: PostgreSQL
Project: IPL Analytics Database

Purpose
-------
This file documents the logical schema design used in the
project before implementation.

==========================================================
Database Entities
==========================================================

1. Teams
   - Stores IPL team information.

2. Players
   - Stores player information.
   - Each player belongs to one team.

3. Venues
   - Stores stadium information.

4. Matches
   - Stores match-level information.
   - References:
       • Team 1
       • Team 2
       • Toss Winner
       • Match Winner
       • Venue

5. Innings
   - Represents each innings of a match.
   - Each match contains two innings.

6. Deliveries
   - Stores ball-by-ball information.
   - References:
       • Match
       • Batter
       • Bowler
       • Innings

==========================================================
Relationships
==========================================================

Teams (1) ────────< Players

Venues (1) ───────< Matches

Matches (1) ──────< Innings

Matches (1) ──────< Deliveries

Players (1) ──────< Deliveries (Batter)

Players (1) ──────< Deliveries (Bowler)

==========================================================
Normalization
==========================================================

✓ First Normal Form (1NF)

• Atomic values
• No repeating groups

✓ Second Normal Form (2NF)

• No partial dependencies

✓ Third Normal Form (3NF)

• Non-key attributes depend only on the primary key

==========================================================
Design Decisions
==========================================================

• Ball number stores the physical delivery order.
• Wides have their own ball_number.
• Extras are stored separately.
• Runs are split into:
    - Batter Runs
    - Wide Runs
    - No Ball Runs
    - Bye Runs
    - Leg Bye Runs

This allows accurate analytics for batting,
bowling and team statistics.

==========================================================
End of Design
==========================================================
*/