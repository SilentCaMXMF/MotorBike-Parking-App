# 05. Create Database for Motorbike Parking

meta:
  id: setup-sql-on-pi-05
  feature: setup-sql-on-pi
  priority: P1
  depends_on: [setup-sql-on-pi-04]
  tags: [database, schema]

objective:
- Create the motorbike_parking database

deliverables:
- Database 'motorbike_parking' exists

steps:
- mysql -u root -p
- CREATE DATABASE motorbike_parking;
- SHOW DATABASES;
- EXIT;

tests:
- Unit: Database exists in list
- Integration: Can select database

acceptance_criteria:
- SHOW DATABASES; lists motorbike_parking

validation:
- mysql -u root -p -e "SHOW DATABASES;" | grep motorbike_parking

notes:
- Use the root password set in previous step