# 10. Configure Firewall for Database Access

meta:
  id: setup-sql-on-pi-10
  feature: setup-sql-on-pi
  priority: P1
  depends_on: [setup-sql-on-pi-09]
  tags: [firewall, security]

objective:
- Configure firewall to allow database connections from app devices

deliverables:
- Firewall rules allow MySQL port 3306

steps:
- sudo ufw allow 3306
- sudo ufw status

tests:
- Unit: Port open
- Integration: External connection possible

acceptance_criteria:
- ufw status shows 3306 allowed
- Can connect from another device (if tested)

validation:
- sudo ufw status | grep 3306
- From another machine: mysql -h <pi-ip> -u motorbike_user -p motorbike_parking

notes:
- Only allow if necessary; consider VPN for security
- Default MariaDB listens on localhost; may need to configure bind-address