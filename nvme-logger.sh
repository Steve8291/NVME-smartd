#!/bin/bash
PATH=/usr/bin:/usr/local/bin:/usr/sbin:/sbin:/bin

# nvme-logger.sh
# Creates a log file for each nvme drive in /var/log/smartd/<drive-name>.nvme.csv
# Set up to run in crontab every 10 minutes
# */10 * * * * /path/to/nvme-logger.sh

# Info on NVME settings can be found at some of the sites below:
    # https://www.percona.com/blog/2017/02/09/using-nvme-command-line-tools-to-check-nvme-flash-health/
    # https://media.kingston.com/support/downloads/MKP_521.6_SMART-DCP1000_attribute.pdf
    # https://forum.corsair.com/forums/topic/65031-interpreting-smart-data-on-corsair-ssds/
    # https://en.wikipedia.org/wiki/S.M.A.R.T.


ATTRIBUTE_ARRAY=(
        "critical_warning"
        "temperature"
        "available_spare"
        "percentage_used"
        "power_cycles"
        "power_on_hours"
        "unsafe_shutdowns"
        "media_errors"
        "Warning Temperature Time"
)

mapfile -t DRIVE_ARRAY < <(nvme list | grep '/dev/nvme' | awk '{print $1}')
mkdir -p "/var/log/smartd"

get_value() {
    for i in "${SMARTLOG_ARRAY[@]}"; do
        if [[ $i =~ $1[[:space:]]*\: ]]; then
            field=$(cut -d ':' -f2 <<< "$i")
            echo "${field//[!0-9]}"
        fi
    done
}


generate_log() {
    for var in "${ATTRIBUTE_ARRAY[@]}"; do
        value=$(get_value "$var")
        if [[ -n ${value// } ]]; then
            var=$(echo "$var" | tr '[:upper:] ' '[:lower:]_')
            log_line+="     $var;$value"
        fi
    done
}


for drive in "${DRIVE_ARRAY[@]}"; do
    log_line=$(date '+%F %T;')
    mapfile -t SMARTLOG_ARRAY < <(nvme smart-log "$drive")
    generate_log
    echo "$log_line" >> "/var/log/smartd/$(basename "$drive").nvme.csv"
done
