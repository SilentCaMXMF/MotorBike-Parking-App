# 01. Update Raspberry Pi OS

meta:
  id: setup-sql-on-pi-01
  feature: setup-sql-on-pi
  priority: P1
  depends_on: []
  tags: [setup, system]

objective:
- Ensure Raspberry Pi OS is up to date for stable SQL installation

deliverables:
- Updated system packages

steps:
- sudo apt update
- sudo apt upgrade -y
- sudo reboot (if kernel updated)

tests:
- Unit: Check package versions
- Integration: System boots after update

acceptance_criteria:
- apt update runs without errors
- No pending updates shown

validation:
- Run apt list --upgradable (should be empty)
- uname -a to check kernel version

notes:
- Reboot if necessary after upgrade
- Ensure stable internet connection