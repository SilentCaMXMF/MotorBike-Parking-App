# 02. Install MariaDB Server

meta:
  id: setup-sql-on-pi-02
  feature: setup-sql-on-pi
  priority: P1
  depends_on: [setup-sql-on-pi-01]
  tags: [installation, database]

objective:
- Install MariaDB server package on Raspberry Pi

deliverables:
- MariaDB server installed and available

steps:
- sudo apt install mariadb-server -y
- Verify installation: mariadb --version

tests:
- Unit: mariadb command exists
- Integration: Service starts successfully

acceptance_criteria:
- mariadb --version returns version info
- No installation errors

validation:
- mariadb --version
- sudo systemctl status mariadb (should show active)

notes:
- Requires internet connection
- Installation may take several minutes on RPi