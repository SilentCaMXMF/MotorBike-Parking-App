# 07. Grant Least Privilege Permissions

meta:
  id: setup-sql-on-pi-07
  feature: setup-sql-on-pi
  priority: P1
  depends_on: [setup-sql-on-pi-06]
  tags: [privileges, security]

objective:
- Grant minimal necessary privileges to motorbike_user following principle of least privilege
- Create separate users for different application functions if needed

deliverables:
- User has only necessary privileges on motorbike_parking database
- Privileges documented and reviewed
- No excessive permissions granted

steps:
- mysql -u root -p
- Grant specific privileges based on application needs:
  - GRANT SELECT, INSERT, UPDATE, DELETE ON motorbike_parking.* TO 'motorbike_user'@'localhost';
  - -- For schema management during setup only:
  - -- GRANT CREATE, ALTER, INDEX, DROP ON motorbike_parking.* TO 'motorbike_user'@'localhost';
- FLUSH PRIVILEGES;
- Review granted privileges:
  - SHOW GRANTS FOR 'motorbike_user'@'localhost';
- EXIT;
- Document granted privileges for security audit

tests:
- Unit: Specific privileges granted correctly
- Integration: User can perform allowed operations
- Security: User cannot perform disallowed operations

acceptance_criteria:
- User has SELECT, INSERT, UPDATE, DELETE privileges on motorbike_parking
- User cannot create new databases
- User cannot modify system tables
- User cannot grant privileges to others

validation:
- mysql -u root -p -e "SHOW GRANTS FOR 'motorbike_user'@'localhost';"
- Test allowed operations: mysql -u motorbike_user -p -e "USE motorbike_parking; SELECT 1;"
- Test disallowed operations: mysql -u motorbike_user -p -e "CREATE DATABASE test_db;" (should fail)
- Test table operations: mysql -u motorbike_user -p -e "USE motorbike_parking; CREATE TABLE test (id INT);" (should fail unless CREATE granted)

notes:
- Start with minimal privileges, add only as needed
- Consider separate users for read/write vs admin operations
- Regularly audit and review privileges
- Remove CREATE/ALTER/DROP privileges after schema is deployed
- Document any privilege changes for security compliance
- Use roles for complex permission management if needed