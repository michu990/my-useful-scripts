#!/bin/bash

# Apache Log Summary Script

# Configuration
USER="michu990"
DATE=$(date +%Y-%m-%d)
SUMMARY_DIR="/home/$USER/log-summaries"

# Create summary directory if it doesn't exist
mkdir -p "$SUMMARY_DIR"

# Summary files with today's date
AUTH_SUMMARY="$SUMMARY_DIR/auth-summary-$DATE.txt"
SCRAPE_SUMMARY="$SUMMARY_DIR/scrape-summary-$DATE.txt"

# Function to create auth.log summary
create_auth_summary() {
    echo "=============================================" > "$AUTH_SUMMARY"
    echo "AUTH.LOG DAILY SUMMARY - $DATE" >> "$AUTH_SUMMARY"
    echo "Generated: $(date)" >> "$AUTH_SUMMARY"
    echo "=============================================" >> "$AUTH_SUMMARY"
    echo "" >> "$AUTH_SUMMARY"
    
    if [ -f "/var/log/apache2/auth.log" ]; then
        TOTAL_AUTH=$(grep -c "\[auth\]" "/var/log/apache2/auth.log")
        echo "Total authentication attempts: $TOTAL_AUTH" >> "$AUTH_SUMMARY"
        echo "" >> "$AUTH_SUMMARY"
        
        echo "=== UNIQUE USERS ===" >> "$AUTH_SUMMARY"
        grep "\[auth\]" "/var/log/apache2/auth.log" | \
            grep -o "user:'[^']*'" | \
            cut -d"'" -f2 | \
            sort | uniq -c >> "$AUTH_SUMMARY"
        echo "" >> "$AUTH_SUMMARY"
        
        echo "=== IP ADDRESSES (AUTH ATTEMPTS) ===" >> "$AUTH_SUMMARY"
        grep "\[auth\]" "/var/log/apache2/auth.log" | \
            grep -o "client [^]]*" | \
            cut -d' ' -f2 | \
            sort | uniq -c >> "$AUTH_SUMMARY"
        echo "" >> "$AUTH_SUMMARY"
        
        echo "=== LAST 10 AUTH ATTEMPTS ===" >> "$AUTH_SUMMARY"
        grep "\[auth\]" "/var/log/apache2/auth.log" | tail -10 >> "$AUTH_SUMMARY"
    else
        echo "ERROR: /var/log/apache2/auth.log not found" >> "$AUTH_SUMMARY"
    fi
}

# Function to create scrape.log summary
create_scrape_summary() {
    echo "=============================================" > "$SCRAPE_SUMMARY"
    echo "SCRAPE.LOG DAILY SUMMARY - $DATE" >> "$SCRAPE_SUMMARY"
    echo "Generated: $(date)" >> "$SCRAPE_SUMMARY"
    echo "=============================================" >> "$SCRAPE_SUMMARY"
    echo "" >> "$SCRAPE_SUMMARY"
    
    if [ -f "/var/log/apache2/scrape.log" ]; then
        TOTAL_REQUESTS=$(wc -l < "/var/log/apache2/scrape.log")
        echo "Total requests: $TOTAL_REQUESTS" >> "$SCRAPE_SUMMARY"
        echo "" >> "$SCRAPE_SUMMARY"
        
        # Show HTTP methods
        echo "=== HTTP METHODS ===" >> "$SCRAPE_SUMMARY"
        awk -F'|' '{split($6, parts, " "); print parts[1]}' "/var/log/apache2/scrape.log" | \
            sort | uniq -c | sort -rn >> "$SCRAPE_SUMMARY"
        echo "" >> "$SCRAPE_SUMMARY"
        
        # Show status codes
        echo "=== STATUS CODES ===" >> "$SCRAPE_SUMMARY"
        awk -F'|' '{split($7, status, " "); print status[1]}' "/var/log/apache2/scrape.log" | \
            sort | uniq -c | sort -rn >> "$SCRAPE_SUMMARY"
        echo "" >> "$SCRAPE_SUMMARY"
        
        # Show top 10 client IP addresses
        echo "=== TOP 10 CLIENT IP ADDRESSES ===" >> "$SCRAPE_SUMMARY"
        awk -F'|' '{print $3}' "/var/log/apache2/scrape.log" | \
            awk -F':' '{print $2}' | \
            sed 's/^ //; s/ $//' | \
            sort | uniq -c | \
            sort -rn | head -20 >> "$SCRAPE_SUMMARY"
        echo "" >> "$SCRAPE_SUMMARY"
        
        # Show top countries
        echo "=== TOP COUNTRIES ===" >> "$SCRAPE_SUMMARY"
        awk -F'|' '{print $5}' "/var/log/apache2/scrape.log" | \
            awk -F':' '{print $2}' | \
            sed 's/^ //; s/ $//' | \
            sort | uniq -c | \
            sort -rn >> "$SCRAPE_SUMMARY"
        echo "" >> "$SCRAPE_SUMMARY"
        
        # Show full user agents
        echo "=== TOP USER AGENTS ===" >> "$SCRAPE_SUMMARY"
        awk -F'|' '{print $9}' "/var/log/apache2/scrape.log" | \
            awk -F':' '{print substr($0, index($0, ":")+2)}' | \
            sed 's/ $//' | \
            sort | uniq -c | \
            sort -rn | head -10 >> "$SCRAPE_SUMMARY"
        echo "" >> "$SCRAPE_SUMMARY"
        
        # Show top hosts/domains
        echo "=== TOP HOSTS/DOMAINS ===" >> "$SCRAPE_SUMMARY"
        awk -F'|' '{print $10}' "/var/log/apache2/scrape.log" | \
            awk -F':' '{print $2}' | \
            sed 's/^ //; s/ $//' | \
            sort | uniq -c | \
            sort -rn | head -10 >> "$SCRAPE_SUMMARY"
        echo "" >> "$SCRAPE_SUMMARY"
        
        # Show last 20 requests
        echo "=== LAST 20 REQUESTS ===" >> "$SCRAPE_SUMMARY"
        tail -20 "/var/log/apache2/scrape.log" >> "$SCRAPE_SUMMARY"
    else
        echo "ERROR: /var/log/apache2/scrape.log not found" >> "$SCRAPE_SUMMARY"
    fi
}

# Create summaries
create_auth_summary
create_scrape_summary

# Change permissions
chown -R $USER:$USER "$SUMMARY_DIR"
chmod 755 "$SUMMARY_DIR"
chmod 644 "$SUMMARY_DIR"/*.txt 2>/dev/null

# Cleanup old summary files (optional - keeps last 7 days)
# find "$SUMMARY_DIR" -name "*.txt" -mtime +7 -delete >/dev/null 2>&1
