#!/usr/bin/env bash
set -euo pipefail

# Abort if not run as root
[ "$EUID" -ne 0 ] && echo "Run with sudo" && exit 1

# Declare variables
timestamp=$(date +"%Y-%m-%d %H:%M:%S")
logfile="/var/log/miner_quarantine.log"
quarantine_dir="/var/quarantine"

# Define arrays
WHITELIST=("/usr/bin/safe_program" "/usr/local/bin/another_safe_program")
MINER_BLACKLIST=("miner1" "miner2" "unwanted_miner")

# Enable basic colors
green=$(tput setaf 2)
reset=$(tput sgr0)

# Open logfile and echo initial metadata
echo "Script run at: $timestamp" | tee -a "$logfile"
echo "Running as user: $(whoami)" | tee -a "$logfile"
echo "Quarantine directory: $quarantine_dir" | tee -a "$logfile"

