# IPL Analytics Database

A PostgreSQL-based database project that models IPL cricket matches using a normalized relational schema and performs advanced analytical queries using SQL.

The project is designed to demonstrate database design, SQL proficiency, analytical querying, and query optimization concepts commonly used in backend engineering.

---

## Features

- Normalized relational database schema (3NF)
- Ball-by-ball IPL data model
- Sample dataset with realistic match information
- Basic analytics queries
- Intermediate & advanced analytics queries
- Common Table Expressions (CTEs)
- Window Functions
- Ranking Functions
- Conditional Aggregations
- Query Optimization (Upcoming)
- Views (Upcoming)
- Indexing (Upcoming)

---

## Tech Stack

- PostgreSQL
- SQL
- DataGrip
- Git

---

## Project Structure

IPL-Analytics-Database
│
├── analytics/
│   ├── 01_basic_analytics.sql
│   └── 02_intermediate_and_advanced_analytics.sql
│
├── schema/
│   ├── 01_schema_design.sql
│   ├── 02_create_tables.sql
│   └── 03_seed_data.sql
│
├── views/
│
├── explain-analysis/
│
├── data/
│
├── README.md
└── .gitignore

## Database Schema

The project models the following entities:

- Teams
- Players
- Venues
- Matches
- Innings
- Deliveries

The schema is normalized to Third Normal Form (3NF) to minimize redundancy while supporting complex analytical queries.

## Analytics Included

### Batting Analytics

- Highest Run Scorers
- Highest Strike Rate
- Highest Batting Average
- Most Fifties
- Most Centuries
- Boundary Percentage
- Player Performance by Venue
- Orange Cap Progression

### Bowling Analytics

- Most Wickets
- Best Economy Rate
- Best Bowling Average
- Best Bowling Strike Rate
- Purple Cap Progression

### Team Analytics

- Team Win Percentage
- Head-to-Head Record
- Toss Conversion Rate
- Batting First vs Chasing Success

### Venue Analytics

- Highest Scoring Venues

## SQL Concepts Demonstrated

- Joins
- Aggregate Functions
- GROUP BY & HAVING
- CASE Expressions
- Subqueries
- Common Table Expressions (CTEs)
- Window Functions
- RANK() & DENSE_RANK()
- Conditional Aggregation
- NULLIF()
- COALESCE()

## Upcoming

- Database Views
- Indexing
- EXPLAIN ANALYZE
- Query Optimization
- ER Diagram
- Sample Query Outputs

## Future Scope

Potential future enhancements include:

- Importing complete IPL datasets
- Stored Procedures
- Triggers
- Materialized Views
- Partitioning
- Backend REST API using Spring Boot

## Author

**Jaiditya Sinha**

Databases Mini Project