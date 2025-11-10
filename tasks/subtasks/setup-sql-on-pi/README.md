# Setup SQL Database on Raspberry Pi Home Server

Objective: Install and configure MariaDB SQL database on Raspberry Pi for the Motorbike Parking App with security best practices.

Status legend: [ ] todo, [~] in-progress, [x] done

Tasks
- [ ] 01 — Update Raspberry Pi OS → `01-update-raspberry-pi-os.md`
- [ ] 02 — Install MariaDB server → `02-install-mariadb-server.md`
- [ ] 03 — Start and enable MariaDB service → `03-start-enable-mariadb-service.md`
- [ ] 04 — Run MariaDB secure installation → `04-run-mariadb-secure-installation.md`
- [ ] 05 — Create database for motorbike_parking → `05-create-database.md`
- [ ] 06 — Create database user with strong password → `06-create-database-user.md`
- [ ] 07 — Grant least privilege permissions → `07-grant-privileges.md`
- [ ] 08 — Import database schema → `08-import-database-schema.md`
- [ ] 09 — Configure SSL/TLS for secure connections → `09-configure-ssl-tls.md`
- [ ] 10 — Setup backup procedures → `10-setup-backup-procedures.md`
- [ ] 11 — Configure monitoring and logging → `11-configure-monitoring.md`
- [ ] 12 — Performance tuning for Raspberry Pi → `12-performance-tuning.md`
- [ ] 13 — Comprehensive security validation → `13-security-validation.md`

Dependencies
- 02 depends on 01
- 03 depends on 02
- 04 depends on 03
- 05 depends on 04
- 06 depends on 05
- 07 depends on 06
- 08 depends on 07
- 09 depends on 08
- 10 depends on 08
- 11 depends on 08
- 12 depends on 08
- 13 depends on [09, 10, 11, 12]

Exit criteria
- MariaDB is installed and running on Raspberry Pi with security hardening
- Database 'motorbike_parking' exists with proper schema and SSL/TLS encryption
- Database user has least privilege access with strong authentication
- Automated backup procedures are configured and tested
- Monitoring and logging are active for security events
- Performance is optimized for Raspberry Pi hardware constraints
- Database is ready for secure backend API integration
- All security validations pass comprehensive testing