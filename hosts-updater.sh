#!/bin/bash

# Hosts File Updater Script
# Updates /etc/hosts from someonewhocares.org

HOSTS_URL="https://someonewhocares.org/hosts/hosts"
HOSTS_FILE="/etc/hosts"
TEMP_FILE="/tmp/hosts.new"
BACKUP_DIR="$HOME/.hosts_backups"
LOG_FILE="$HOME/Library/Logs/hosts-updater.log"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to send notification
send_notification() {
    osascript -e "display notification \"$1\" with title \"Hosts File Updater\" sound name \"Glass\""
}

log_message "Starting hosts file update check..."

# Download the new hosts file
if curl -s -f -o "$TEMP_FILE" "$HOSTS_URL"; then
    log_message "Successfully downloaded hosts file"
    
    # Check if the file is different from current hosts
    if ! diff -q "$HOSTS_FILE" "$TEMP_FILE" > /dev/null 2>&1; then
        log_message "Changes detected, updating hosts file..."
        
        # Create backup of current hosts file
        BACKUP_FILE="$BACKUP_DIR/hosts.backup.$(date '+%Y%m%d_%H%M%S')"
        cp "$HOSTS_FILE" "$BACKUP_FILE"
        log_message "Backup created: $BACKUP_FILE"
        
        # Update the hosts file (requires sudo)
        if sudo cp "$TEMP_FILE" "$HOSTS_FILE"; then
            log_message "Hosts file updated successfully"
            
            # Flush DNS cache
            sudo dscacheutil -flushcache
            sudo killall -HUP mDNSResponder
            log_message "DNS cache flushed"
            
            # Send notification
            UPDATE_DATE=$(date '+%Y-%m-%d %H:%M:%S')
            send_notification "Hosts file updated on $UPDATE_DATE"
            log_message "Notification sent"
        else
            log_message "ERROR: Failed to update hosts file"
            send_notification "Failed to update hosts file"
        fi
    else
        log_message "No changes detected, hosts file is up to date"
    fi
    
    # Clean up temp file
    rm -f "$TEMP_FILE"
else
    log_message "ERROR: Failed to download hosts file from $HOSTS_URL"
    send_notification "Failed to download hosts file"
fi

log_message "Update check completed"
