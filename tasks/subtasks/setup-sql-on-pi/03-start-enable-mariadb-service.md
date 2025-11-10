# 03. Start and Enable MariaDB Service

meta:
  id: setup-sql-on-pi-03
  feature: setup-sql-on-pi
  priority: P1
  depends_on: [setup-sql-on-pi-02]
  tags: [service, database]

objective:
- Start MariaDB service and enable it to start on boot

deliverables:
- MariaDB service running and enabled

steps:
- sudo systemctl start mariadb
- sudo systemctl enable mariadb
- Check status: sudo systemctl status mariadb

tests:
- Unit: Service is enabled
- Integration: Service is active

acceptance_criteria:
- systemctl status mariadb shows active (running)
- systemctl is-enabled mariadb shows enabled

validation:
- sudo systemctl is-active mariadb
- sudo systemctl is-enabled mariadb

notes:
- If service fails to start, check logs with journalctl -u mariadb