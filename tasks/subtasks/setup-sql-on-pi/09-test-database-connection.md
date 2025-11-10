# 09. Test Database Connection

meta:
  id: setup-sql-on-pi-09
  feature: setup-sql-on-pi
  priority: P1
  depends_on: [setup-sql-on-pi-08]
  tags: [testing, database]

objective:
- Verify database connection and basic operations work

deliverables:
- Successful connection and query execution

steps:
- mysql -u motorbike_user -p motorbike_parking -e "SELECT 1;"
- Insert test data: INSERT INTO users (email, password) VALUES ('test@example.com', 'hashed_pass');
- SELECT * FROM users;

tests:
- Unit: Connection succeeds
- Integration: CRUD operations work

acceptance_criteria:
- No connection errors
- Test data inserted and retrieved

validation:
- mysql -u motorbike_user -p motorbike_parking -e "SELECT COUNT(*) FROM users;"

notes:
- Use actual table names from schema
- Clean up test data after