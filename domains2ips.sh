#!/usr/bin/env bash                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          

# Read domains from file and write the resolved addresses to a file for IPv4 / IPv6.

usage() {
  echo "Usage: $0"
  echo "-i, --input <file>  Read file with domains, separated by newline"
  echo "-h, --help          Print usage"
}

log() {
    local LEVEL="$1"
    shift
    local MESSAGE="$*"
    local TIMESTAMP
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$TIMESTAMP [$LEVEL] $MESSAGE" >> "$LOG_FILE"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -i | --input)
      in_file="$2"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use -h, --help for usage."
      exit 1
      ;;
  esac
done

# Check passed values
if [ -z "$in_file" ]; then
  echo "Error: Input file missing."
  usage
  exit 1
elif [ ! -f "$in_file" ]; then
  echo "Error: Input file not found."
  exit 1
fi

OUT_FILE_IPV4=ipv4.out
OUT_FILE_IPV6=ipv6.out
LOG_FILE=$(basename "$0").log

# Clear the output files
echo "" > "$OUT_FILE_IPV4"
echo "" > "$OUT_FILE_IPV6"
# Clear the log file
echo "" > "$LOG_FILE"

# Read each line of input file
while IFS= read -r domain; do
  resolved=false

  # Add IPv4 in IPv4 output file
  ipv4s=$(dig +short A "$domain" | grep -Eo '^[0-9.]+$')
  if [ -n "$ipv4s" ]; then
    while IFS= read -r ip; do
      log "DEBUG" "$domain: $ip"
      echo "$ip" >> $OUT_FILE_IPV4
    done <<< "$ipv4s"
    resolved=true
  fi
 
# Add IPv4 in IPv6 output file
  ipv6s=$(dig +short AAAA "$domain" | grep -Eo '^[0-9a-fA-F:]+$')
  if [ -n "$ipv6s" ]; then
    while IFS= read -r ip; do
      log "DEBUG" "$domain: $ip"
      echo "$ip" >> $OUT_FILE_IPV6
    done <<< "$ipv6s"
    resolved=true
  fi
 
  # Fallback
  if [ "$resolved" = false ]; then
    log "DEBUG" "$domain: resolution failed"
  fi
done < "$in_file"

# Remove empty line
sed -i '/^$/d' "$OUT_FILE_IPV4"
sed -i '/^$/d' "$OUT_FILE_IPV6"

# Sort and remove duplicates
sort -t . -k1,1n -k2,2n -k3,3n -k4,4n -o "$OUT_FILE_IPV4" "$OUT_FILE_IPV4"
sort -u -o "$OUT_FILE_IPV6" "$OUT_FILE_IPV6"