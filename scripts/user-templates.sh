# User Templates for VPN User Management System
# These templates define the default configurations for different user types

# Template: Admin User
# Full system access with sudo privileges
admin_template() {
    cat << 'EOF'
{
    "user_type": "admin",
    "description": "Full system administrator with complete access",
    "shell": "/bin/bash",
    "sudo_access": "full",
    "groups": ["admin", "sudo", "developers"],
    "vpn_access": "full",
    "ssh_access": true,
    "password_policy": {
        "min_length": 16,
        "require_special_chars": true,
        "require_numbers": true,
        "require_uppercase": true,
        "require_lowercase": true,
        "expiry_days": 90
    },
    "permissions": {
        "system_commands": "all",
        "file_access": "all",
        "network_access": "all",
        "service_management": "all"
    },
    "restrictions": {
        "login_sources": ["vpn_networks"],
        "time_restrictions": "none",
        "session_timeout": 480
    },
    "monitoring": {
        "log_level": "verbose",
        "session_recording": true,
        "command_logging": true
    }
}
EOF
}

# Template: Developer User
# Development access with limited sudo
developer_template() {
    cat << 'EOF'
{
    "user_type": "developer",
    "description": "Developer with access to development tools and limited system commands",
    "shell": "/bin/bash",
    "sudo_access": "limited",
    "groups": ["developers"],
    "vpn_access": "full",
    "ssh_access": true,
    "password_policy": {
        "min_length": 14,
        "require_special_chars": true,
        "require_numbers": true,
        "require_uppercase": true,
        "require_lowercase": true,
        "expiry_days": 60
    },
    "permissions": {
        "system_commands": ["systemctl restart motorbike-parking*", "systemctl status motorbike-parking*", "docker", "git", "npm", "flutter"],
        "file_access": ["/home/", "/opt/motorbike-parking/", "/tmp/", "/var/log/motorbike-parking/"],
        "network_access": ["outbound", "vpn_internal"],
        "service_management": ["motorbike-parking*"]
    },
    "restrictions": {
        "login_sources": ["vpn_networks"],
        "time_restrictions": "business_hours",
        "session_timeout": 360
    },
    "monitoring": {
        "log_level": "standard",
        "session_recording": false,
        "command_logging": true
    }
}
EOF
}

# Template: Read-only User
# Read-only access for monitoring and viewing
readonly_template() {
    cat << 'EOF'
{
    "user_type": "readonly",
    "description": "Read-only access for monitoring and viewing purposes",
    "shell": "/usr/bin/nologin",
    "sudo_access": "none",
    "groups": ["readonly"],
    "vpn_access": "limited",
    "ssh_access": false,
    "password_policy": {
        "min_length": 12,
        "require_special_chars": false,
        "require_numbers": true,
        "require_uppercase": true,
        "require_lowercase": true,
        "expiry_days": 180
    },
    "permissions": {
        "system_commands": ["cat", "less", "grep", "tail", "head"],
        "file_access": ["/var/log/", "/etc/", "/opt/motorbike-parking/config/"],
        "network_access": ["none"],
        "service_management": ["status_only"]
    },
    "restrictions": {
        "login_sources": ["vpn_networks"],
        "time_restrictions": "none",
        "session_timeout": 180
    },
    "monitoring": {
        "log_level": "standard",
        "session_recording": false,
        "command_logging": true
    }
}
EOF
}

# Template: Service User
# Service account for automated processes
service_template() {
    cat << 'EOF'
{
    "user_type": "service",
    "description": "Service account for automated processes and applications",
    "shell": "/usr/sbin/nologin",
    "sudo_access": "none",
    "groups": ["service"],
    "vpn_access": "none",
    "ssh_access": false,
    "password_policy": {
        "min_length": 32,
        "require_special_chars": true,
        "require_numbers": true,
        "require_uppercase": true,
        "require_lowercase": true,
        "expiry_days": 365
    },
    "permissions": {
        "system_commands": ["application_specific"],
        "file_access": ["/opt/motorbike-parking/", "/var/lib/motorbike-parking/"],
        "network_access": ["local_only"],
        "service_management": ["application_specific"]
    },
    "restrictions": {
        "login_sources": ["localhost_only"],
        "time_restrictions": "24/7",
        "session_timeout": 0
    },
    "monitoring": {
        "log_level": "application",
        "session_recording": false,
        "command_logging": false
    }
}
EOF
}

# Template: Auditor User
# Audit and compliance access
auditor_template() {
    cat << 'EOF'
{
    "user_type": "auditor",
    "description": "Auditor with read-only access to logs and configuration files",
    "shell": "/bin/bash",
    "sudo_access": "readonly",
    "groups": ["auditors", "readonly"],
    "vpn_access": "full",
    "ssh_access": true,
    "password_policy": {
        "min_length": 16,
        "require_special_chars": true,
        "require_numbers": true,
        "require_uppercase": true,
        "require_lowercase": true,
        "expiry_days": 90
    },
    "permissions": {
        "system_commands": ["cat", "less", "grep", "tail", "head", "find", "ls", "stat"],
        "file_access": ["/var/log/", "/etc/", "/opt/motorbike-parking/", "/home/", "/var/lib/"],
        "network_access": ["none"],
        "service_management": ["status_only"]
    },
    "restrictions": {
        "login_sources": ["vpn_networks"],
        "time_restrictions": "business_hours",
        "session_timeout": 240
    },
    "monitoring": {
        "log_level": "verbose",
        "session_recording": true,
        "command_logging": true
    }
}
EOF
}

# Function to generate template file
generate_template() {
    local user_type=$1
    local output_file=$2
    
    case "$user_type" in
        "admin")
            admin_template > "$output_file"
            ;;
        "developer")
            developer_template > "$output_file"
            ;;
        "readonly")
            readonly_template > "$output_file"
            ;;
        "service")
            service_template > "$output_file"
            ;;
        "auditor")
            auditor_template > "$output_file"
            ;;
        *)
            echo "Unknown user type: $user_type"
            echo "Available types: admin, developer, readonly, service, auditor"
            return 1
            ;;
    esac
    
    echo "Template generated: $output_file"
}

# Function to list available templates
list_templates() {
    echo "Available user templates:"
    echo "  admin     - Full system administrator"
    echo "  developer - Developer with limited sudo"
    echo "  readonly  - Read-only access"
    echo "  service   - Service account"
    echo "  auditor   - Auditor with read-only access"
}

# Export functions for use in other scripts
export -f admin_template developer_template readonly_template service_template auditor_template
export -f generate_template list_templates