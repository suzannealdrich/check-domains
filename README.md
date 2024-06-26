# Domain Info Script

This script reads a list of domain names from a file, makes HTTPS requests to each domain, and prints out the domain name, the server response header, the certificate issuer, and the TLS cipher suite supported by the domain. The output is printed to the console and written to a file.

Inspired by the list of domains that are using post-quantum cryptography according to a [recent report by TrustFour](https://trustfour.com/current-state-of-transport-layer-security-tls-post-quantum-cryptography/).

You'll note that almost all the domains in the list are utilizing Cloudflare proxy service for TLS termination, which [recently switched to the X25519+Kyber768 standard](https://blog.cloudflare.com/post-quantum-for-all/).

Please note that this informational scan will not detect use of X25519Kyber768 in particular, because [OpenSSL does not currently support X25519Kyber768Draft00 or X25519Kyber768](https://github.com/openssl/openssl/issues/24622).

## Requirements

- `curl`
- `openssl`

Make sure these tools are installed on your system.

## Usage

1. **Create a file named `domains.txt` and list the domain names, each on a new line.** For example:
    ```
    example.com
    google.com
    github.com
    ```

2. **Save the script to a file, for example, `check_domains.sh`.** The script content:
    ```bash
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
    ```

3. **Make the script executable:**
    ```sh
    chmod +x check_domains.sh
    ```

4. **Run the script:**
    ```sh
    ./check_domains.sh
    ```

The script will print the output to the console and write it to `output.txt`.

## Example Output

For a domain `example.com`, the output might look like:

```
Domain: example.com
Server Response Header: Server: ECS (dcb/7F83)
Certificate Issuer: issuer= /C=US/O=Let's Encrypt/CN=R3
TLS Cipher Suite: ECDHE-RSA-AES128-GCM-SHA256
```

## License

This script is released under the MIT License. See [LICENSE](LICENSE) for details.
