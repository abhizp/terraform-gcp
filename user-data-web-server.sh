#!/bin/bash

# inventory first (so we can print it)
inventory_file="inventory"

# write all output (stdout and stderr) to a timestamped log file next to the script
log_file="$(dirname "$0")/user-data-web-server-$(date +%F_%H%M%S).log"
exec >"$log_file" 2>&1

# include timestamps for each traced command and enable tracing (captures commands + output)
export PS4='+ $(date "+%Y-%m-%d %H:%M:%S")\011(${BASH_SOURCE##*/}:$LINENO) '
set -x

# log the script itself and the inventory (so the log contains more than just output)
echo "---- script: $0 ----"
cat "$0" || echo "(failed to read script)"
if [ -f "$inventory_file" ]; then
    echo "---- inventory: $inventory_file ----"
    sed -n '1,$p' "$inventory_file"
else
    echo "Inventory file not found: $inventory_file"
    exit 1
fi

# login to servers and check if a particular process is running
while IFS= read -r server || [ -n "$server" ]; do
    server=$(echo "$server" | tr -d '\r\n')
    [ -z "$server" ] && continue

    echo "Checking server: $server"
    sshpass -p "Nandu@021023" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "ablnu@$server" \
        "ps -ef | grep -i pmd | grep -v grep >/dev/null 2>&1; rc=\$?; if [ \$rc -eq 0 ]; then echo Process is running on $server; else echo Process is not running on $server; fi; rpm -qa | grep -i cortex >/dev/null 2>&1; if [ \$? -eq 0 ]; then echo Cortex package is installed on $server; else echo Cortex package is not installed on $server; fi"
done < "$inventory_file"

echo "Log saved to: $log_file"
exit 0