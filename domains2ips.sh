#!/usr/bin/env bash
# Read domains from file and write the resolved addresses to a file for IPv4 / IPv6.

SCRIPT_DIR=$(dirname "$(realpath "$0")")
SCRIPTNAME=$(basename "$0" | cut -d'.' -f1)
LOG_FILE="$SCRIPT_DIR/$SCRIPTNAME".log
DOMAIN_PATTERN='^[a-z0-9-]+(\.[a-z0-9-]+)+$'

function file_ends_with_newline() {
    [[ $(tail -c1 "$1" | wc -l) -gt 0 ]]
}

usage() {
  echo "Usage: $0"
  echo "-i, --input <file>    Read file with domains, separated by newline"
  echo "-h, --help            Print usage"
  echo "-o, --output <file>   Output file with addresses, separated by newline"
  echo "-6                    Optional parameter: Resolve domains to IPv6 (default: IPv4)."
  echo "-v, --verbose         Verbose output"
}

log() {
    local LEVEL="$1"
    shift
    local MESSAGE="$*"
    local TIMESTAMP
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$TIMESTAMP [$LEVEL] $MESSAGE" >> "$LOG_FILE"
}

declare -a domains

record=A
ip_pattern='^[0-9.]+$'

# Check if no parameters were passed
if [ $# -eq 0 ]; then
    echo "Error: No arguments provided."
    usage
    exit 1
fi

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -i | --input)
      if [[ -z "$2" || "$2" == --* ]]; then
        echo "Error: -f, --file requires a value."
        exit 1
      elif [ ! -f "$2" ]; then
        echo "ERROR" "Input file $2 does not exist" | tee log
        exit 1
      fi
      in_file="$2"
      shift 2
      ;;
    -6)
      record=AAAA
      ip_pattern='^[0-9a-fA-F:]+$'
      shift 1
      ;;
    -o | --output)
      out_file="$2"
      shift 2
      ;;
    -v | --verbose)
      verbose=true
      shift 1
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

if [[ -z $out_file ]]; then
  out_file=$(basename "$in_file" | cut -d'.' -f1).out
fi

log "INFO" "Output file: $out_file" 
log "INFO" "Input file: $in_file"

if $verbose; then
  echo "DEBUG" "LOGFILE: $LOG_FILE"
  log "DEBUG" "Record: $record"
fi

log "INFO" "--- Clear output file ---"
echo "" > "$out_file"

# If the file does not end with a newline, then the last line will be ignored in the while loop.
if ! file_ends_with_newline "$in_file"
then
  log "INFO" "Append newline in $in_file"
  echo "" >> "$in_file"
fi

log "INFO" "--- Read domains from $in_file ---"
while IFS= read -r line; do
  ((i++))
  if [ -z "$line" ]; then
    log "INFO" "Line $i is empty and will be ignored"
  elif [[ ! "$line" =~ $DOMAIN_PATTERN ]]; then
    log "INFO" "Entry $line in line $i is invalid and will be ignored"
  else
    log "INFO" "Add $line in array"
    domains+=("$line")
  fi

done < "$in_file"

log "INFO" "--- Resolve domains ---"
for domain in "${domains[@]}";
do

  if $verbose; then
    log "DEBUG" "Domain: $domain"
  fi

  resolved=false

  ips=$(dig +short $record "$domain" | grep -Eo "$ip_pattern")

  if $verbose; then
    log "DEBUG" "Resolved IP addresses: $ips"
  fi
  
  log "INFO" "--- Add resolved addresses of $domain in $out_file ---"
  if [ -n "$ips" ]; then
    while IFS= read -r ip; do
      
      if $verbose; then
        log "DEBUG" "$domain -> $ip"
      fi
      
      echo "$ip" >> "$out_file"
    done <<< "$ips"
    resolved=true
  fi
 
  if [ "$resolved" = false ]; then
    log "INFO" "Resolving $record for $domain returned no addresses"
  fi
done

# Remove empty line
sed -i '/^$/d' "$out_file"

# Sort and remove duplicates
sort -u -o "$out_file" "$out_file"