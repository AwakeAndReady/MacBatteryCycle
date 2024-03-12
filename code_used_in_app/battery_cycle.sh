#!/bin/bash

# MacBatteryCycle
# Author: René Sesgör
# Last Update: 2024-01-12

# This script manages battery charging cycles to optimize battery health. It allows to let the Mac's power cable be plugged in all the time. 
# The script monitors the battery level and controls charging/discharging based on upper and lower battery level thresholds.
# Configure LOW_THRESHOLD and HIGH_THRESHOLD to desired levels.
# Run the script with the "--discharge" option to enable using the battery as the power source after reaching the HIGH_THRESHOLD. 
# Without this option, the battery will not be discharged, and the power adapter will remain as the primary energy source.
# The script includes a cleanup function for graceful exit and log file management for size constraints.  
# Battery status and actions taken are logged to 'battery_cycle_logs.log' file.   
# 
# The script requires the Open Source Battery CLI by Mentor Palokaj installed (https://github.com/actuallymentor/battery).
# Run this script with 'bash battery_cycle.sh' or via Automator application. See instructions in file 'AppleSkript.txt'

# Articles on Battery health:
# - https://www.makeuseof.com/charging-habits-that-prolongs-macbook-battery-life/
# - https://batteryuniversity.com/article/bu-808-how-to-prolong-lithium-based-batteries
# - https://batteryuniversity.com/article/bu-809-how-to-maximize-runtime
# - https://praxistipps.chip.de/macbook-akku-kalibrieren-eine-anleitung_3530

# Configuration
LOG_FILE="battery_cycle_logs.log"
LOW_THRESHOLD=25 # For best charging limits refer to Battery University (see link above)
HIGH_THRESHOLD=75
INTERVALL_TIME=60 # seconds
DISCHARGE_ALLOWED=1  # As in bash: 0 means true, 1 means false

# Parse Arguments
for arg in "$@"
do
    case $arg in
        --discharge)
        DISCHARGE_ALLOWED=0
        shift
        ;;
        --upper)
        HIGH_THRESHOLD="${2}"
        shift 2
        ;;
        --lower)
        LOW_THRESHOLD="${2}"
        shift 2
        ;;
    esac
done

# Functions
get_battery_percentage() {
    pmset -g batt | grep -Eo "\d+%" | cut -d% -f1
}

get_smc_charging_status() {
    local status_output=$(battery status)
    local charging_status=$(echo $status_output | grep -o "smc charging [a-z]*" | awk '{print $3}')
    echo $charging_status
}

close_if_power_adapter_not_connected() {
   pmset -g ps | grep 'AC Power' > /dev/null
   if [[ $? -ne 0 ]]; then
        log_message "Power adapter is not connected."
        log_message "### Ending script ###"
        cleanup
    fi
}

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

trim_logfile_if_needed() {
    logsize=$(stat -f%z "$LOG_FILE")
    max_logsize_bytes=5000000
    if ((logsize > max_logsize_bytes)); then
        tail -n 100 $LOG_FILE >$LOG_FILE
    fi
}

cleanup() {
    log_message "Exiting: Re-enabling normal charging behavior."
    battery charging on
    osascript -e 'tell application "Terminal" to close first window' & exit 0 >> "$LOG_FILE" # Apple Script
}

# Setup
log_message "### Starting script ###"
trap cleanup SIGINT SIGHUP  # listen to events like ctrl+c and terminal closed
[[ ! -f "$LOG_FILE" ]] && touch "$LOG_FILE"  # create logfile if not there
battery charging on
charging_on=0
close_if_power_adapter_not_connected
osascript -e 'tell application "Terminal" to set miniaturized of front window to true'
if [[ $DISCHARGE_ALLOWED -ne 1 ]]; then
    log_message "Battery has been set as power source during discharge"
else
    log_message "Power adapter has been set as power source during discharge. --> Battery will only self-discharge"
fi

# Main loop
while true; do
    trim_logfile_if_needed
    close_if_power_adapter_not_connected

    battery_level=$(get_battery_percentage)
    charging_status=$(get_smc_charging_status)

    if [[ $charging_on -ne 0 && $battery_level -le $LOW_THRESHOLD ]]; then
        log_message "Battery level is low ($battery_level%). Starting to charge up to $HIGH_THRESHOLD%."
        battery charging on
        charging_on=0
    elif [[ $charging_on -eq 0 && $battery_level -ge $HIGH_THRESHOLD ]]; then
        if [[ $DISCHARGE_ALLOWED -eq 0 ]]; then
            log_message "Battery level is high ($battery_level%). Starting to discharge down to $LOW_THRESHOLD%."
            battery discharge $LOW_THRESHOLD >> "$LOG_FILE"  # blocking function
        else
            log_message "Battery level is high ($battery_level%). Charging stopped until $LOW_THRESHOLD% is reached by self-discharge. Power source: power adapter. Power adapter removal detection unavailable."
            battery charging off
        fi
        charging_on=1
    else
        log_message "Battery level: $battery_level%. Charging $charging_status."
    fi

    sleep $INTERVALL_TIME

done
