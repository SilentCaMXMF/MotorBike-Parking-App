# 08. Import Database Schema

meta:
  id: setup-sql-on-pi-08
  feature: setup-sql-on-pi
  priority: P1
  depends_on: [setup-sql-on-pi-07]
  tags: [schema, database]

objective:
- Import the SQL schema into the motorbike_parking database

deliverables:
- All tables created from schema

steps:
- Assume schema.sql exists (from design task)
- mysql -u motorbike_user -p motorbike_parking < schema.sql

tests:
- Unit: Tables exist
- Integration: Can insert sample data

acceptance_criteria:
- SHOW TABLES; lists all expected tables

validation:
- mysql -u motorbike_user -p motorbike_parking -e "SHOW TABLES;"

notes:
- Schema file must be created first (from migrate-to-sql-db-01)
- Transfer schema.sql to Pi if needed