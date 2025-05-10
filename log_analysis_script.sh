#!/bin/bash

# Check if a log file is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <log_file>"
  exit 1
fi

LOG_FILE="$1"

# --- 1. Request Counts ---
echo "1. Request Counts"
total_requests=$(wc -l < "$LOG_FILE")
echo "Total requests: $total_requests"

get_requests=$(awk '$6 ~ /"GET/' "$LOG_FILE" | wc -l)
echo "GET requests: $get_requests"

post_requests=$(awk '$6 ~ /"POST/' "$LOG_FILE" | wc -l)
echo "POST requests: $post_requests"
echo ""

# --- 2. Unique IP Addresses ---
echo "2. Unique IP Addresses"
unique_ips=$(awk '{print $1}' "$LOG_FILE" | sort | uniq | wc -l)
echo "Total unique IPs: $unique_ips"

echo "Requests by IP (GET and POST):"
awk '$6 ~ /"GET/ {get[$1]++} $6 ~ /"POST/ {post[$1]++}
     END {
       for (ip in get) {
         printf "%s, Get: %d, Post: %d\n", ip, get[ip], post[ip]+0
       }
       for (ip in post) if (!(ip in get)) {
         printf "%s, Get: 0, Post: %d\n", ip, post[ip]
       }
     }' "$LOG_FILE"
echo ""

# --- 3. Failed Requests ---
echo "3. Failed Requests"
awk '{
  total++
  if ($9 ~ /^[45][0-9][0-9]$/) failed++
} END {
  printf "Total Requests: %d\nFailed Requests: %d\nFailure Percentage: %.2f%%\n", total, failed, (failed/total)*100
}' "$LOG_FILE"
echo ""

# --- 4. Top User (Most Active IP) ---
echo "4. Top User (Most Active IP)"
awk '{count[$1]++} END {
  max = 0
  for (ip in count) {
    if (count[ip] > max) {
      max = count[ip]
      max_ip = ip
    }
  }
  printf "Most Active IP: %s (%d requests)\n", max_ip, max
}' "$LOG_FILE"
echo ""

# --- 5. Daily Request Averages ---
echo "5. Daily Request Averages"
awk '{
  split($4, dt, ":")
  sub("\\[", "", dt[1])
  date = dt[1]
  daily[date]++
  total++
} END {
  count = 0
  for (d in daily) count++
  avg = total / count
  printf "Average requests per day: %.2f\n", avg
}' "$LOG_FILE"
echo ""

# --- 6. Days with Highest Failures ---
echo "6. Days with Highest Failures"
awk '$9 ~ /^[45]/ {
  split($4, dt, ":")
  sub("\\[", "", dt[1])
  day = dt[1]
  failures[day]++
} END {
  for (d in failures) {
    printf "%s: %d failures\n", d, failures[d]
  }
}' "$LOG_FILE" | sort -k2 -nr | head -n 50
echo ""

# --- 7. Requests by Hour ---
echo "7. Requests by Hour"
awk '{
  split($4, a, ":")
  hour = a[2]
  count[hour]++
} END {
  for (h = 0; h < 24; h++) {
    printf "%02d:00 - %d requests\n", h, count[sprintf("%02d", h)]+0
  }
}' "$LOG_FILE"
echo ""

# --- 8. Status Codes Breakdown ---
echo "8. Status Codes Breakdown"
awk '$9 ~ /^[0-9]{3}$/ {codes[$9]++} END {
  for (code in codes) {
    printf "%s: %d\n", code, codes[code]
  }
}' "$LOG_FILE" | sort -n
echo ""

# --- 9. Most Active User by Method ---
echo "9. Most Active User by Method"
awk '$6 ~ /"GET/ {get[$1]++} $6 ~ /"POST/ {post[$1]++}
END {
  max_get=0; max_post=0;
  for (ip in get) if (get[ip] > max_get) { max_get = get[ip]; ip_get = ip }
  for (ip in post) if (post[ip] > max_post) { max_post = post[ip]; ip_post = ip }
  printf "Most GETs: %s (%d)\nMost POSTs: %s (%d)\n", ip_get, max_get, ip_post, max_post
}' "$LOG_FILE"
echo ""

# --- 10. Failure Patterns by Hour ---
echo "10. Failure Patterns by Hour"
awk '$9 ~ /^4[0-9][0-9]$/ || $9 ~ /^5[0-9][0-9]$/ {
  split($4, a, ":")
  hour = a[2]
  failures[hour]++
} END {
  for (h = 0; h < 24; h++) {
    printf "%02d:00 - %d failures\n", h, failures[sprintf("%02d", h)] + 0
  }
}' "$LOG_FILE"
echo ""
