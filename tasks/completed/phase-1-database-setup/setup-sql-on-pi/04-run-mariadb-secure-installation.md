# 04. Run MariaDB Secure Installation

meta:
  id: setup-sql-on-pi-04
  feature: setup-sql-on-pi
  priority: P1
  depends_on: [setup-sql-on-pi-03]
  tags: [security, database]

objective:
- Secure MariaDB installation by setting strong root password and removing insecure defaults
- Configure password validation plugin for strong password policies

deliverables:
- MariaDB secured with strong root password
- Password validation plugin configured
- All insecure defaults removed

steps:
- sudo mysql_secure_installation
- Follow prompts: Set root password (minimum 16 chars, mixed case, numbers, symbols), remove anonymous users, disallow root login remotely, remove test database, reload privilege tables
- Configure password validation plugin:
  - mysql -u root -p
  - INSTALL PLUGIN validate_password SONAME 'validate_password.so';
  - SET GLOBAL validate_password.policy = 'STRONG';
  - SET GLOBAL validate_password.length = 16;
  - SET GLOBAL validate_password.mixed_case_count = 1;
  - SET GLOBAL validate_password.number_count = 1;
  - SET GLOBAL validate_password.special_char_count = 1;
  - FLUSH PRIVILEGES;
  - EXIT;

tests:
- Unit: Root password set and meets strong criteria
- Integration: Cannot login as root without password
- Security: Password validation plugin active

acceptance_criteria:
- mysql_secure_installation completes without errors
- Root login requires strong password
- Password validation plugin is installed and configured
- No anonymous users exist
- Test database is removed

validation:
- Try to connect: mysql -u root -p (should prompt for password)
- Verify no anonymous users: mysql -u root -p -e "SELECT User,Host FROM mysql.user;"
- Check password validation: mysql -u root -p -e "SHOW VARIABLES LIKE 'validate_password%';"
- Test weak password rejection: mysql -u root -p -e "CREATE USER 'test'@'localhost' IDENTIFIED BY 'weak';" (should fail)

notes:
- Store root password securely (use password manager)
- This is interactive; run on Pi terminal
- Password validation ensures all future passwords meet security standards
- Document password in secure location for recovery