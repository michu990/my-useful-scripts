#!/bin/bash
echo "Checking SSL certificate expiry..."

# Check each certificate
for cert in /etc/letsencrypt/live/*; do
    if [ -d "$cert" ]; then
        domain=$(basename "$cert")
        expiry=$(openssl x509 -enddate -noout -in "$cert/fullchain.pem" | cut -d= -f2)
        remaining=$(echo $(( ($(date -d "$expiry" +%s) - $(date +%s)) / 86400 )))
        
        if [ $remaining -lt 30 ]; then
            echo "WARNING: $domain expires in $remaining days on $expiry"
        elif [ $remaining -lt 10 ]; then
            echo "URGENT: $domain expires in $remaining days on $expiry"
        else
            echo "OK: $domain expires in $remaining days on $expiry"
        fi
    fi
done

# Check last renewal
echo -e "\nLast renewal attempts:"
if [ -f "/var/log/certbot-renew.log" ]; then
    tail -5 /var/log/certbot-renew.log
else
    journalctl -u certbot | tail -5
fi
