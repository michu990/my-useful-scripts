#!/bin/bash

# Weekly Backup Script for Apache & Home Directory
# Run weekly via cron as root
# Keeps maximum 4 backups (rotates old ones)
# michu990

# Configuration
USER="michu990"
BACKUP_DIR="/home/$USER/backup"
MAX_BACKUPS=4
DATE=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_NAME="backup_$DATE.tar.gz"
LOG_FILE="/home/$USER/backup/backup.log"

# What to backup
BACKUP_SOURCES=(
    "/var/log"                # Logs folder
    "/etc/apache2"            # Apache configurations
    "/var/www"                # Web root
    "/home/$USER"             # User home (excluding backup folder itself)
    "/etc/letsencrypt"        # Let's Encrypt certificates and configurations
    "/etc/fail2ban"           # fail2ban configurations
    "/var/spool/cron/crontabs" # User cron jobs
    "/etc/crontab"            # System crontab
    "/etc/cron.d"             # Cron directories
    "/etc/cron.daily"         # Daily cron jobs
    "/etc/cron.weekly"        # Weekly cron jobs
    "/etc/cron.monthly"       # Monthly cron jobs
)

# Exclude patterns (to avoid backing up backups)
EXCLUDE_PATTERNS=(
    "--exclude=${BACKUP_DIR}"
    "--exclude=/var/www/html/piwnica"
    "--exclude=*.tmp"
    "--exclude=*.log"
    "--exclude=*.cache"
    "--exclude=*.swp"
    # Let's Encrypt exclusions
    "--exclude=/etc/letsencrypt/archive"
    "--exclude=/etc/letsencrypt/accounts"
    "--exclude=/etc/letsencrypt/live/*/privkey.pem"  # Private keys are sensitive
    "--exclude=/etc/letsencrypt/renewal-hooks"
    # Log exclusions
   #--exclude=/var/log/letsencrypt"
   #--exclude=/var/log/fail2ban.log"
    # Cache and temp exclusions
    "--exclude=*/cache/*"
    "--exclude=*/tmp/*"
    "--exclude=*/.cache/*"
)

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to backup critical configurations separately (for quick restore)
backup_critical_configs() {
    local critical_dir="${BACKUP_DIR}/critical_configs_${DATE}"
    mkdir -p "$critical_dir"
    
    log_message "Creating critical configurations backup..."
    
    # 1. Backup Apache SSL configurations
    mkdir -p "${critical_dir}/apache_ssl"
    cp -r /etc/apache2/sites-available/*-ssl.conf "${critical_dir}/apache_ssl/" 2>/dev/null
    cp /etc/apache2/conf-available/remoteip.conf "${critical_dir}/apache_ssl/" 2>/dev/null
    cp /etc/apache2/apache2.conf "${critical_dir}/apache_ssl/" 2>/dev/null
    
    # 2. Backup Let's Encrypt critical files only (no private keys)
    mkdir -p "${critical_dir}/letsencrypt"
    # Backup renewal configurations
    cp -r /etc/letsencrypt/renewal "${critical_dir}/letsencrypt/" 2>/dev/null
    # Backup live directory structure without private keys
    if [ -d "/etc/letsencrypt/live" ]; then
        mkdir -p "${critical_dir}/letsencrypt/live"
        for domain in /etc/letsencrypt/live/*; do
            if [ -d "$domain" ]; then
                domain_name=$(basename "$domain")
                mkdir -p "${critical_dir}/letsencrypt/live/${domain_name}"
                # Copy only non-private key files
                cp "$domain/cert.pem" "${critical_dir}/letsencrypt/live/${domain_name}/" 2>/dev/null
                cp "$domain/chain.pem" "${critical_dir}/letsencrypt/live/${domain_name}/" 2>/dev/null
                cp "$domain/fullchain.pem" "${critical_dir}/letsencrypt/live/${domain_name}/" 2>/dev/null
                # Create a note about private key location
                echo "Private key is stored separately in /etc/letsencrypt/live/${domain_name}/privkey.pem" \
                    > "${critical_dir}/letsencrypt/live/${domain_name}/README.txt"
            fi
        done
    fi
    
    # 3. Backup fail2ban configurations
    mkdir -p "${critical_dir}/fail2ban"
    cp /etc/fail2ban/jail.local "${critical_dir}/fail2ban/" 2>/dev/null
    cp /etc/fail2ban/fail2ban.local "${critical_dir}/fail2ban/" 2>/dev/null
    cp -r /etc/fail2ban/filter.d "${critical_dir}/fail2ban/" 2>/dev/null
    cp -r /etc/fail2ban/action.d "${critical_dir}/fail2ban/" 2>/dev/null
    
    # 4. Backup cron configurations
    mkdir -p "${critical_dir}/cron"
    # Backup root crontab
    crontab -l > "${critical_dir}/cron/root_crontab.txt" 2>/dev/null
    # Backup michu990 crontab
    crontab -u michu990 -l > "${critical_dir}/cron/michu990_crontab.txt" 2>/dev/null
    # Backup system cron files
    cp /etc/crontab "${critical_dir}/cron/" 2>/dev/null
    cp -r /etc/cron.d "${critical_dir}/cron/" 2>/dev/null
    cp -r /etc/cron.daily "${critical_dir}/cron/" 2>/dev/null
    cp -r /etc/cron.weekly "${critical_dir}/cron/" 2>/dev/null
    cp -r /etc/cron.monthly "${critical_dir}/cron/" 2>/dev/null
    
    # 5. Backup important service status
    mkdir -p "${critical_dir}/services"
    systemctl status apache2 > "${critical_dir}/services/apache2_status.txt" 2>/dev/null
    systemctl status fail2ban > "${critical_dir}/services/fail2ban_status.txt" 2>/dev/null
    systemctl status certbot.timer > "${critical_dir}/services/certbot_timer_status.txt" 2>/dev/null
    
    # 6. Backup network and firewall config
    mkdir -p "${critical_dir}/network"
    iptables-save > "${critical_dir}/network/iptables_rules.txt" 2>/dev/null
    ufw status verbose > "${critical_dir}/network/ufw_status.txt" 2>/dev/null
    netstat -tlnp > "${critical_dir}/network/listening_ports.txt" 2>/dev/null
    
    # 7. Backup Cloudflare configuration info
    mkdir -p "${critical_dir}/cloudflare"
    # Save current SSL/TLS mode info
    echo "To check Cloudflare SSL mode:" > "${critical_dir}/cloudflare/README.txt"
    echo "1. Go to Cloudflare Dashboard → SSL/TLS → Overview" >> "${critical_dir}/cloudflare/README.txt"
    echo "2. Should be set to: Full or Full (strict)" >> "${critical_dir}/cloudflare/README.txt"
    echo "3. Always Use HTTPS: ON" >> "${critical_dir}/cloudflare/README.txt"
    
    # Compress critical configs
    tar -czpf "${BACKUP_DIR}/critical_configs_${DATE}.tar.gz" -C "${BACKUP_DIR}" "critical_configs_${DATE}"
    rm -rf "${critical_dir}"
    
    log_message "Critical configurations backup created: critical_configs_${DATE}.tar.gz"
}

# Function to check certificate expiry
check_cert_expiry() {
    log_message "Checking Let's Encrypt certificate expiry..."
    
    local cert_check_file="${BACKUP_DIR}/certificate_status_${DATE}.txt"
    echo "=== SSL Certificate Status Check - $(date) ===" > "$cert_check_file"
    echo "" >> "$cert_check_file"
    
    if [ -d "/etc/letsencrypt/live" ]; then
        for cert_dir in /etc/letsencrypt/live/*; do
            if [ -d "$cert_dir" ] && [ -f "$cert_dir/fullchain.pem" ]; then
                domain=$(basename "$cert_dir")
                expiry_date=$(openssl x509 -enddate -noout -in "$cert_dir/fullchain.pem" 2>/dev/null | cut -d= -f2)
                expiry_timestamp=$(date -d "$expiry_date" +%s 2>/dev/null)
                current_timestamp=$(date +%s)
                days_remaining=$(( (expiry_timestamp - current_timestamp) / 86400 ))
                
                echo "Domain: $domain" >> "$cert_check_file"
                echo "Expiry Date: $expiry_date" >> "$cert_check_file"
                echo "Days Remaining: $days_remaining" >> "$cert_check_file"
                
                if [ "$days_remaining" -lt 10 ]; then
                    echo "Status:WARNING - Renew soon!" >> "$cert_check_file"
                    log_message "WARNING: Certificate for $domain expires in $days_remaining days"
                elif [ "$days_remaining" -lt 30 ]; then
                    echo "Status:INFO - Expires in $days_remaining days" >> "$cert_check_file"
                    log_message "INFO: Certificate for $domain expires in $days_remaining days"
                else
                    echo "Status:OK" >> "$cert_check_file"
                    log_message "OK: Certificate for $domain expires in $days_remaining days"
                fi
                echo "---" >> "$cert_check_file"
            fi
        done
    else
        echo "No Let's Encrypt certificates found." >> "$cert_check_file"
        log_message "WARNING: No Let's Encrypt certificates found in /etc/letsencrypt/live"
    fi
    
    # Also check certbot renewal status
    echo "" >> "$cert_check_file"
    echo "=== Certbot Renewal Status ===" >> "$cert_check_file"
    certbot certificates 2>/dev/null >> "$cert_check_file"
    
    log_message "Certificate status saved to: $(basename "$cert_check_file")"
}

# Start backup
log_message "=== Starting weekly backup ==="
log_message "Backup name: $BACKUP_NAME"
log_message "Backup directory: $BACKUP_DIR"
log_message "User: $USER (backing up crontab for michu990 and root)"

# Check if sources exist
for source in "${BACKUP_SOURCES[@]}"; do
    if [ ! -e "$source" ]; then
        log_message "WARNING: Source '$source' does not exist!"
    else
        log_message "Source OK: $source"
    fi
done

# Create critical configs backup first
backup_critical_configs

# Check certificate expiry
check_cert_expiry

# Create main backup
log_message "Creating main backup archive..."
cd /  # Change to root to use relative paths in tar


## Here root fails to do backup --> fixed by (-C / \)
if tar -czpf "${BACKUP_DIR}/${BACKUP_NAME}" \
    -C / \
    "${EXCLUDE_PATTERNS[@]}" \
    --warning=no-file-changed \
    "${BACKUP_SOURCES[@]}" 2>> "$LOG_FILE"; then
    
    # Get backup size
    BACKUP_SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_NAME}" | cut -f1)
    log_message "Backup created successfully: ${BACKUP_NAME} (${BACKUP_SIZE})"
    
    # Calculate checksum for verification
    md5sum "${BACKUP_DIR}/${BACKUP_NAME}" > "${BACKUP_DIR}/${BACKUP_NAME}.md5"
    log_message "MD5 checksum created: $(cat "${BACKUP_DIR}/${BACKUP_NAME}.md5")"
else
    log_message "ERROR: Backup creation failed!"
    exit 1
fi

# Rotate backups - keep only MAX_BACKUPS
log_message "Rotating backups (keeping $MAX_BACKUPS latest backups)..."

# Remove old critical config backups (keep last 2)
CRITICAL_BACKUP_COUNT=$(ls -1 "${BACKUP_DIR}/critical_configs_"*.tar.gz 2>/dev/null | wc -l)
if [ "$CRITICAL_BACKUP_COUNT" -gt 2 ]; then
    ls -1t "${BACKUP_DIR}/critical_configs_"*.tar.gz 2>/dev/null | \
        tail -n +3 | \
        while read -r old_backup; do
            log_message "Removing old critical config backup: $(basename "$old_backup")"
            rm -f "$old_backup"
        done
fi

# Remove old certificate status files (keep last 4)
CERT_STATUS_COUNT=$(ls -1 "${BACKUP_DIR}/certificate_status_"*.txt 2>/dev/null | wc -l)
if [ "$CERT_STATUS_COUNT" -gt 4 ]; then
    ls -1t "${BACKUP_DIR}/certificate_status_"*.txt 2>/dev/null | \
        tail -n +5 | \
        while read -r old_status; do
            log_message "Removing old certificate status: $(basename "$old_status")"
            rm -f "$old_status"
        done
fi

# Rotate main backups
BACKUP_COUNT=$(ls -1 "${BACKUP_DIR}/backup_"*.tar.gz 2>/dev/null | wc -l)
if [ "$BACKUP_COUNT" -gt "$MAX_BACKUPS" ]; then
    # List backups sorted by date (oldest first), remove the excess
    ls -1t "${BACKUP_DIR}/backup_"*.tar.gz 2>/dev/null | \
        tail -n +$((MAX_BACKUPS + 1)) | \
        while read -r old_backup; do
            log_message "Removing old backup: $(basename "$old_backup")"
            rm -f "$old_backup"
            # Also remove corresponding MD5 file
            rm -f "${old_backup}.md5" 2>/dev/null
        done
else
    log_message "No rotation needed (current: $BACKUP_COUNT, max: $MAX_BACKUPS)"
fi

# List remaining backups
log_message "Current backups in $BACKUP_DIR:"
ls -lh "${BACKUP_DIR}/"*.tar.gz "${BACKUP_DIR}/"*.txt 2>/dev/null | \
    awk '{print $9, $5}' | \
    while read -r backup size; do
        backup_name=$(basename "$backup")
        log_message "  ${backup_name} - ${size}"
    done

# Set correct permissions
chown -R $USER:$USER "$BACKUP_DIR"
chmod 750 "$BACKUP_DIR"
chmod 640 "$BACKUP_DIR"/*.tar.gz 2>/dev/null
chmod 640 "$BACKUP_DIR"/*.md5 2>/dev/null
chmod 640 "$BACKUP_DIR"/*.txt 2>/dev/null
chmod 640 "$LOG_FILE" 2>/dev/null

# Calculate total backup size
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
log_message "Total backup directory size: $TOTAL_SIZE"

# Verify backup integrity (optional)
log_message "Verifying backup integrity..."
if md5sum -c "${BACKUP_DIR}/${BACKUP_NAME}.md5" >> "$LOG_FILE" 2>&1; then
    log_message "Backup verification: SUCCESS"
else
    log_message "Backup verification: FAILED"
fi

# Create restore instructions
log_message "Creating restore instructions..."
cat > "${BACKUP_DIR}/RESTORE_INSTRUCTIONS.txt" << EOF
=== RESTORE INSTRUCTIONS ===
Date: $(date)

MAIN BACKUP: ${BACKUP_NAME}

To restore:
# Extracting must be done by root!!!
1. Extract main backup (by root!!!):
   sudo tar -xzf ${BACKUP_NAME} -C /

2. Critical configurations (if needed separately, extract by root!!!):
   sudo tar -xzf critical_configs_${DATE}.tar.gz -C /

3. Important services to restart after restore:
   sudo systemctl restart apache2
   sudo systemctl restart fail2ban
   
4. Certificate information is in: certificate_status_${DATE}.txt

5. To restore crontabs:
   For root: crontab /etc/crontab
   For michu990: crontab -u michu990 /var/spool/cron/crontabs/michu990

6. Check fail2ban status:
   sudo fail2ban-client status

7. Check Apache SSL:
   sudo apache2ctl configtest
   sudo systemctl status apache2

Backup created by: $0
Backup timestamp: ${DATE}
EOF

log_message "Restore instructions saved to: ${BACKUP_DIR}/RESTORE_INSTRUCTIONS.txt"
log_message "=== Backup completed successfully ==="
echo "Backup completed: ${BACKUP_DIR}/${BACKUP_NAME}"
