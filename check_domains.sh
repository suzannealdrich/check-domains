#!/bin/bash

# File containing the list of domain names
DOMAIN_FILE="domains.txt"
OUTPUT_FILE="output.txt"

# Check if the file exists
if [[ ! -f "$DOMAIN_FILE" ]]; then
    echo "File $DOMAIN_FILE does not exist."
    exit 1
fi

# Clear the output file if it exists, or create it
> "$OUTPUT_FILE"

# Loop through each domain in the file
while IFS= read -r DOMAIN; do
    if [[ -n "$DOMAIN" ]]; then
        {
            echo "Domain: $DOMAIN"
            
            # Get server response headers and extract the "Server" header
            SERVER_HEADER=$(curl -s -I "https://$DOMAIN" | grep -i "^Server:")
            echo "Server Response Header: $SERVER_HEADER"

            # Get certificate issuer and cipher suite
            CERT_INFO=$(echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN:443" 2>/dev/null)
            CERT_ISSUER=$(echo "$CERT_INFO" | openssl x509 -noout -issuer)
            CIPHER_SUITE=$(echo "$CERT_INFO" | grep "Cipher" | awk '{print $5}')

            echo "Certificate Issuer: $CERT_ISSUER"
            echo "TLS Cipher Suite: $CIPHER_SUITE"
            
            echo ""
        } | tee -a "$OUTPUT_FILE"
    fi
done < "$DOMAIN_FILE"

echo "Output written to $OUTPUT_FILE"