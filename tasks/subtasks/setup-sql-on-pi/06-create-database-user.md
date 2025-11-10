# 06. Create Database User with Strong Password

meta:
  id: setup-sql-on-pi-06
  feature: setup-sql-on-pi
  priority: P1
  depends_on: [setup-sql-on-pi-05]
  tags: [user, security]

objective:
- Create a dedicated database user for the app with strong password
- Implement secure password generation and storage

deliverables:
- User 'motorbike_user' created with strong password
- Password securely stored for application configuration
- User configured with minimal privileges initially

steps:
- Generate strong password (minimum 16 characters):
  - Use: openssl rand -base64 32 OR
  - Use: pwgen -s 16 1 OR
  - Manual: Create password with mixed case, numbers, symbols
- Store password securely in password manager
- mysql -u root -p
- CREATE USER 'motorbike_user'@'localhost' IDENTIFIED BY 'YOUR_GENERATED_STRONG_PASSWORD';
- FLUSH PRIVILEGES;
- EXIT;
- Add password to application environment variables (not in code)

tests:
- Unit: User exists in mysql.user table
- Integration: User can connect with strong password
- Security: Password meets validation requirements

acceptance_criteria:
- SELECT User FROM mysql.user WHERE User='motorbike_user'; returns the user
- Password is at least 16 characters with mixed case, numbers, symbols
- User can authenticate successfully
- Password is not stored in plain text files

validation:
- mysql -u root -p -e "SELECT User,Host,Password FROM mysql.user WHERE User='motorbike_user';"
- Test connection: mysql -u motorbike_user -p -e "SELECT 1;" (enter password when prompted)
- Verify password strength: mysql -u root -p -e "SHOW CREATE USER 'motorbike_user'@'localhost';"

notes:
- Use password manager to store the generated password
- Never commit passwords to version control
- Consider using environment variables or secret management for app configuration
- Password should be rotated regularly (every 90 days recommended)
- User is localhost only for security - no remote access