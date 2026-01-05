#!/bin/bash

# SSH Login Aggregator
# Shows specific IP addresses for all login attempts

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display summary
display_summary() {
    echo -e "\n${BLUE}=== SSH LOGIN ATTEMPTS SUMMARY ===${NC}"
    echo -e "Period: ${YELLOW}$1${NC}"
    echo -e "Total Login Attempts: ${YELLOW}$2${NC}"
    echo -e "Failed Login Attempts: ${RED}$3${NC}"
    echo -e "Successful Logins: ${GREEN}$4${NC}"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (sudo) to access system logs"
    exit 1
fi

# Parse time period
if [ "$1" == "--today" ] || [ -z "$1" ]; then
    TIME_FILTER="--since today"
    PERIOD="Today"
elif [ "$1" == "--yesterday" ]; then
    TIME_FILTER="--since yesterday --until today"
    PERIOD="Yesterday"
elif [ "$1" == "--week" ]; then
    TIME_FILTER="--since '1 week ago'"
    PERIOD="Last 7 days"
elif [ "$1" == "--month" ]; then
    TIME_FILTER="--since '1 month ago'"
    PERIOD="Last 30 days"
elif [ "$1" == "--all" ]; then
    TIME_FILTER=""
    PERIOD="All time"
else
    echo "Usage: $0 [--today|--yesterday|--week|--month|--all] [--details]"
    exit 1
fi

echo -e "${BLUE}Collecting SSH login data from journalctl...${NC}"

# Get SSH logs from journalctl
SSH_LOGS=$(journalctl $TIME_FILTER -u ssh 2>/dev/null)

if [ -z "$SSH_LOGS" ]; then
    echo "No SSH logs found. Trying alternative service names..."
    # Try different SSH service names
    SSH_LOGS=$(journalctl $TIME_FILTER -u sshd 2>/dev/null)
    if [ -z "$SSH_LOGS" ]; then
        SSH_LOGS=$(journalctl $TIME_FILTER | grep -i ssh 2>/dev/null)
    fi
fi

if [ -z "$SSH_LOGS" ]; then
    echo "Could not retrieve SSH logs."
    exit 1
fi

# Count login attempts
TOTAL_ATTEMPTS=$(echo "$SSH_LOGS" | grep -c "sshd")
FAILED_ATTEMPTS=$(echo "$SSH_LOGS" | grep -E -c "Failed|Invalid|failure|authentication error" | head -1)
SUCCESSFUL_LOGINS=$(echo "$SSH_LOGS" | grep -c "Accepted")

# Display summary
display_summary "$PERIOD" "$TOTAL_ATTEMPTS" "$FAILED_ATTEMPTS" "$SUCCESSFUL_LOGINS"

# Extract and display IP addresses from all SSH activity
echo -e "\n${BLUE}=== IP ADDRESSES FROM SSH ACTIVITY ===${NC}"

# All IP addresses from SSH logs
echo -e "\n${YELLOW}All IP addresses found in SSH logs:${NC}"
echo "$SSH_LOGS" | grep -E "from [0-9.:]+" | \
    grep -o "from [0-9.:]*" | \
    cut -d' ' -f2 | \
    sort -u | column

# IP addresses with successful logins
echo -e "\n${GREEN}IP addresses with successful logins:${NC}"
echo "$SSH_LOGS" | grep "Accepted" | \
    grep -o "from [0-9.:]*" | \
    cut -d' ' -f2 | \
    sort -u | column

# IP addresses with failed attempts
echo -e "\n${RED}IP addresses with failed attempts:${NC}"
echo "$SSH_LOGS" | grep -E "Failed|Invalid|failure" | \
    grep -o "from [0-9.:]*" | \
    cut -d' ' -f2 | \
    sort -u | column

# Show detailed breakdown if requested
if [ "$2" == "--details" ] || [ "$1" == "--details" ]; then
    echo -e "\n${BLUE}=== DETAILED IP ANALYSIS ===${NC}"
    
    # IP addresses with counts (most active first)
    echo -e "\n${YELLOW}IP addresses sorted by activity:${NC}"
    echo "$SSH_LOGS" | grep -o "from [0-9.:]*" | \
        cut -d' ' -f2 | \
        sort | uniq -c | sort -rn
    
    # IP addresses with successful logins and usernames
    echo -e "\n${GREEN}Successful logins by IP and user:${NC}"
    echo "$SSH_LOGS" | grep "Accepted" | \
        awk -F'for | from ' '{print $2, $3}' | \
        sort | column -t
    
    # IP addresses with failed attempts and usernames
    echo -e "\n${RED}Failed attempts by IP and user:${NC}"
    echo "$SSH_LOGS" | grep -E "Failed|Invalid" | \
        awk -F'for |from | user ' '{print $2, $3}' | \
        sort | column -t
    
    # Recent SSH activity with IPs
    echo -e "\n${BLUE}Recent SSH activity (last 20 entries):${NC}"
    echo "$SSH_LOGS" | tail -20 | \
        grep -E "Accepted|Failed|Invalid" | \
        awk '{print $1, $2, $3, $8, $9, $10, $11, $12}'
fi