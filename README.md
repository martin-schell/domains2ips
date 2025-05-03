# domains2ips

This script resolves a list of domains and generates two files, one with the resolved IPv4 addresses and the other with the resolved IPv6 addresses.

## Usage

```sh
Usage: ./domains2ips.sh
-i, --input <file>  Read file with domains, separated by newline
-h, --help          Print usage
```

## Input

This script expects a file with domains, separated by newline.

```
security.ubuntu.com
de.archive.ubuntu.com
```

## Output

This script generates three files:

**ipv4.out**
```
91.189.91.81
91.189.91.82
91.189.91.83
185.125.190.81
185.125.190.82
185.125.190.83
```

**ipv6.out**
```
2620:2d:4000:1::101
2620:2d:4000:1::102
2620:2d:4000:1::103
2620:2d:4002:1::101
2620:2d:4002:1::102
2620:2d:4002:1::103
```

**logfile**
```
2025-05-02 18:14:29 [DEBUG] security.ubuntu.com: 185.125.190.81
2025-05-02 18:14:29 [DEBUG] security.ubuntu.com: 185.125.190.83
2025-05-02 18:14:29 [DEBUG] security.ubuntu.com: 91.189.91.81
2025-05-02 18:14:29 [DEBUG] security.ubuntu.com: 91.189.91.83
2025-05-02 18:14:29 [DEBUG] security.ubuntu.com: 91.189.91.82
2025-05-02 18:14:29 [DEBUG] security.ubuntu.com: 185.125.190.82
2025-05-02 18:14:30 [DEBUG] security.ubuntu.com: 2620:2d:4000:1::101
2025-05-02 18:14:30 [DEBUG] security.ubuntu.com: 2620:2d:4000:1::102
2025-05-02 18:14:30 [DEBUG] security.ubuntu.com: 2620:2d:4002:1::103
2025-05-02 18:14:30 [DEBUG] security.ubuntu.com: 2620:2d:4002:1::102
2025-05-02 18:14:30 [DEBUG] security.ubuntu.com: 2620:2d:4002:1::101
2025-05-02 18:14:30 [DEBUG] security.ubuntu.com: 2620:2d:4000:1::103
```

## Further Details

If domain can be resolved respectively if `ipv4s` / `ipv6s` is not empty, then write each IP address into the output file and set the `resolved` flag.
```sh
if [ -n "$ipv4s" ]; then
    while IFS= read -r ip; do
      log "DEBUG" "$domain: $ip"
      echo "$ip" >> $OUT_FILE_IPV6
    done <<< "$ipv4s"
    resolved=true
fi
```
If a domain cannot be resolved, then write a log entry.
```sh
if [ "$resolved" = false ]; then
  log "DEBUG" "$domain: resolution failed"
fi
```

Because the IP addresses were appended to the output file, e. g. `echo "$ip" >> $OUT_FILE_IPV6`, the first line is always empty.
Therefore, these lines will be removed.

```sh
sed -i '/^$/d' "$OUT_FILE_IPV4"
sed -i '/^$/d' "$OUT_FILE_IPV6"
```

`sort -t . -k1,1n -k2,2n -k3,3n -k4,4n -o "$OUT_FILE_IPV4" "$OUT_FILE_IPV4"` sorts the IPv4 addresses in a ascending order and replaces the content of the output file with the sorted list.
