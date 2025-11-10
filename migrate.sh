#!/bin/bash

# Motorbike Parking App Database Migration Script
# Usage: ./migrate.sh [version] [direction]
# Examples:
#   ./migrate.sh 1.0.1 up    - Apply migration 1.0.1
#   ./migrate.sh 1.0.1 down  - Rollback migration 1.0.1
#   ./migrate.sh latest up   - Apply all pending migrations
#   ./migrate.sh status      - Show migration status

set -e

# Configuration
DB_NAME="motorbike_parking_app"
DB_USER="motorbike_app"
DB_HOST="localhost"
MIGRATIONS_DIR="migrations"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if MySQL client is available
check_mysql_client() {
    if ! command -v mysql &> /dev/null; then
        log_error "MySQL client is not installed or not in PATH"
        exit 1
    fi
}

# Check database connection
check_connection() {
    log_info "Checking database connection..."
    if ! mysql -h"$DB_HOST" -u"$DB_USER" -e "USE $DB_NAME;" 2>/dev/null; then
        log_error "Cannot connect to database '$DB_NAME' with user '$DB_USER'"
        log_info "Please check your database credentials and ensure the database exists"
        exit 1
    fi
    log_success "Database connection successful"
}

# Get current schema version
get_current_version() {
    mysql -h"$DB_HOST" -u"$DB_USER" -D"$DB_NAME" -sN -e "SELECT version FROM schema_version ORDER BY applied_at DESC LIMIT 1;" 2>/dev/null || echo "0.0.0"
}

# Get latest available migration version
get_latest_migration() {
    if [ -d "$MIGRATIONS_DIR" ]; then
        find "$MIGRATIONS_DIR" -name "*.sql" -type f | sed 's/.*\///' | sed 's/\.sql$//' | sort -V | tail -1
    else
        echo "0.0.0"
    fi
}

# Show migration status
show_status() {
    local current_version=$(get_current_version)
    local latest_migration=$(get_latest_migration)
    
    log_info "Current schema version: $current_version"
    log_info "Latest available migration: $latest_migration"
    
    if [ "$current_version" = "$latest_migration" ]; then
        log_success "Database is up to date"
    elif [ "$current_version" = "0.0.0" ]; then
        log_warning "Database has not been initialized. Run './migrate.sh init' to set up the schema"
    else
        log_warning "Database is not up to date. Run './migrate.sh latest up' to apply pending migrations"
    fi
    
    # Show migration history
    log_info "Migration history:"
    mysql -h"$DB_HOST" -u"$DB_USER" -D"$DB_NAME" -e "
        SELECT version, description, applied_at 
        FROM schema_version 
        ORDER BY applied_at DESC;" 2>/dev/null || log_warning "No migration history found"
}

# Initialize database with schema
init_database() {
    log_info "Initializing database with schema..."
    
    if [ ! -f "schema.sql" ]; then
        log_error "schema.sql not found in current directory"
        exit 1
    fi
    
    # Apply the schema
    mysql -h"$DB_HOST" -u"$DB_USER" -D"$DB_NAME" < schema.sql
    
    if [ $? -eq 0 ]; then
        log_success "Database initialized successfully"
        show_status
    else
        log_error "Failed to initialize database"
        exit 1
    fi
}

# Apply migration
apply_migration() {
    local version=$1
    local migration_file="$MIGRATIONS_DIR/${version}.sql"
    
    if [ ! -f "$migration_file" ]; then
        log_error "Migration file not found: $migration_file"
        exit 1
    fi
    
    log_info "Applying migration $version..."
    
    # Read migration description from file header
    local description=$(sed -n '2s/^-- //p' "$migration_file" || echo "Migration $version")
    
    # Start transaction
    mysql -h"$DB_HOST" -u"$DB_USER" -D"$DB_NAME" -e "START TRANSACTION;"
    
    # Apply migration
    mysql -h"$DB_HOST" -u"$DB_USER" -D"$DB_NAME" < "$migration_file"
    
    if [ $? -eq 0 ]; then
        # Record migration
        mysql -h"$DB_HOST" -u"$DB_USER" -D"$DB_NAME" -e "
            INSERT INTO schema_version (version, description) 
            VALUES ('$version', '$description');"
        
        # Commit transaction
        mysql -h"$DB_HOST" -u"$DB_USER" -D"$DB_NAME" -e "COMMIT;"
        
        log_success "Migration $version applied successfully"
    else
        # Rollback on error
        mysql -h"$DB_HOST" -u"$DB_USER" -D"$DB_NAME" -e "ROLLBACK;"
        log_error "Failed to apply migration $version"
        exit 1
    fi
}

# Rollback migration
rollback_migration() {
    local version=$1
    local rollback_file="$MIGRATIONS_DIR/${version}_rollback.sql"
    
    if [ ! -f "$rollback_file" ]; then
        log_error "Rollback file not found: $rollback_file"
        log_warning "Cannot rollback migration $version without rollback script"
        exit 1
    fi
    
    log_info "Rolling back migration $version..."
    
    # Start transaction
    mysql -h"$DB_HOST" -u"$DB_USER" -D"$DB_NAME" -e "START TRANSACTION;"
    
    # Apply rollback
    mysql -h"$DB_HOST" -u"$DB_USER" -D"$DB_NAME" < "$rollback_file"
    
    if [ $? -eq 0 ]; then
        # Remove migration record
        mysql -h"$DB_HOST" -u"$DB_USER" -D"$DB_NAME" -e "
            DELETE FROM schema_version WHERE version = '$version';"
        
        # Commit transaction
        mysql -h"$DB_HOST" -u"$DB_USER" -D"$DB_NAME" -e "COMMIT;"
        
        log_success "Migration $version rolled back successfully"
    else
        # Rollback on error
        mysql -h"$DB_HOST" -u"$DB_USER" -D"$DB_NAME" -e "ROLLBACK;"
        log_error "Failed to rollback migration $version"
        exit 1
    fi
}

# Apply all pending migrations
apply_all_migrations() {
    local current_version=$(get_current_version)
    local latest_migration=$(get_latest_migration)
    
    if [ "$current_version" = "$latest_migration" ]; then
        log_success "Database is already up to date"
        return
    fi
    
    log_info "Applying pending migrations from $current_version to $latest_migration..."
    
    # Get list of migration files
    for migration_file in "$MIGRATIONS_DIR"/*.sql; do
        if [ -f "$migration_file" ]; then
            local version=$(basename "$migration_file" .sql)
            
            # Skip if this is a rollback file
            if [[ "$version" == *"_rollback" ]]; then
                continue
            fi
            
            # Apply if version is newer than current
            if [ "$(printf '%s\n' "$current_version" "$version" | sort -V | head -n1)" = "$current_version" ] && [ "$current_version" != "$version" ]; then
                apply_migration "$version"
            fi
        fi
    done
    
    log_success "All pending migrations applied successfully"
}

# Create new migration template
create_migration() {
    local version=$1
    local description=$2
    
    if [ -z "$version" ] || [ -z "$description" ]; then
        log_error "Usage: ./migrate.sh create <version> <description>"
        exit 1
    fi
    
    local migration_file="$MIGRATIONS_DIR/${version}.sql"
    local rollback_file="$MIGRATIONS_DIR/${version}_rollback.sql"
    
    if [ -f "$migration_file" ]; then
        log_error "Migration file already exists: $migration_file"
        exit 1
    fi
    
    # Create migrations directory if it doesn't exist
    mkdir -p "$MIGRATIONS_DIR"
    
    # Create migration file
    cat > "$migration_file" << EOF
-- Migration: $version
-- Description: $description
-- Applied: $(date '+%Y-%m-%d %H:%M:%S')

START TRANSACTION;

-- Add your migration SQL here
-- Example:
-- ALTER TABLE users ADD COLUMN phone_number VARCHAR(20) NULL;

COMMIT;
EOF

    # Create rollback file
    cat > "$rollback_file" << EOF
-- Rollback: $version
-- Description: Rollback for: $description
-- Applied: $(date '+%Y-%m-%d %H:%M:%S')

START TRANSACTION;

-- Add your rollback SQL here
-- Example:
-- ALTER TABLE users DROP COLUMN phone_number;

COMMIT;
EOF

    log_success "Migration files created:"
    log_info "  Migration: $migration_file"
    log_info "  Rollback:  $rollback_file"
}

# Main script logic
main() {
    local command=${1:-status}
    local version=${2:-latest}
    local direction=${3:-up}
    
    check_mysql_client
    
    case "$command" in
        "init")
            check_connection
            init_database
            ;;
        "status")
            check_connection
            show_status
            ;;
        "create")
            create_migration "$version" "$direction"
            ;;
        "latest")
            check_connection
            if [ "$direction" = "up" ]; then
                apply_all_migrations
            else
                log_error "Cannot rollback to 'latest'. Use specific version"
                exit 1
            fi
            ;;
        "up"|"apply")
            check_connection
            if [ "$version" = "latest" ]; then
                apply_all_migrations
            else
                apply_migration "$version"
            fi
            ;;
        "down"|"rollback")
            check_connection
            if [ "$version" = "latest" ]; then
                local current_version=$(get_current_version)
                rollback_migration "$current_version"
            else
                rollback_migration "$version"
            fi
            ;;
        *)
            echo "Motorbike Parking App Database Migration Tool"
            echo ""
            echo "Usage: $0 [command] [version] [direction]"
            echo ""
            echo "Commands:"
            echo "  init                    Initialize database with schema.sql"
            echo "  status                  Show migration status"
            echo "  create <version> <desc> Create new migration template"
            echo "  latest up               Apply all pending migrations"
            echo "  <version> up            Apply specific migration"
            echo "  <version> down          Rollback specific migration"
            echo "  latest down             Rollback last applied migration"
            echo ""
            echo "Examples:"
            echo "  $0 init"
            echo "  $0 status"
            echo "  $0 create 1.0.1 \"Add phone number to users\""
            echo "  $0 latest up"
            echo "  $0 1.0.1 up"
            echo "  $0 1.0.1 down"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"