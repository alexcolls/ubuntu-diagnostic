#!/bin/bash

# Quarantine Remediation Script - Step 8
# For each PID in SUSPICIOUS array, perform quarantine actions

# Define necessary variables
QUAR_BASE="/var/quarantine"
TIMESTAMP=$(date +%s)
CRITICAL_PATHS=("/bin" "/sbin" "/usr/bin" "/usr/sbin" "/lib" "/lib64" "/usr/lib" "/usr/lib64")
SUSPICIOUS=(1234 5678) # Add suspicious PIDs here

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a /var/log/quarantine.log
}

is_critical_path() {
  for critical_path in "${CRITICAL_PATHS[@]}"; do
    if [[ "$1" == "$critical_path"* ]]; then
      return 0
    fi
  done
  return 1
}

# Main quarantine loop
for PID in "${SUSPICIOUS[@]}"; do
  log "=== Start QUARANTINE section for PID $PID ==="
  
  # Capture exe path
  exe=$(readlink -f /proc/$PID/exe 2>/dev/null || echo unknown)
  log "Executable path for PID $PID: $exe"
  
  # Attempt to kill process
  if /usr/bin/kill -9 "$PID" 2>/dev/null; then
    log "Successfully killed PID $PID"
  else
    log "Failed to kill PID $PID (process may not exist or insufficient permissions)"
  fi
  
  # Check if exe exists, not in critical paths, and writable directory
  if [[ -f "$exe" && "$exe" != "unknown" && ! is_critical_path "$exe" && -w "$(dirname "$exe")" ]]; then
    log "Quarantining executable: $exe"
    
    # Create per-run quarantine directory
    QUAR_DIR="$QUAR_BASE/$TIMESTAMP"
    mkdir -p "$QUAR_DIR" && chmod 700 "$QUAR_DIR"
    log "Created quarantine directory: $QUAR_DIR"
    
    # Remove immutable attribute if present
    sudo /usr/bin/chattr -i "$exe" 2>/dev/null || true
    
    # Move executable to quarantine
    if sudo /usr/bin/mv -f "$exe" "$QUAR_DIR/"; then
      log "Successfully moved $exe to $QUAR_DIR/"
    else
      log "Failed to move $exe to quarantine"
    fi
  else
    log "Skipping quarantine for $exe (critical path, doesn't exist, or directory not writable)"
  fi
  
  # Check for systemd services referencing the executable
  if [[ -f "$exe" && "$exe" != "unknown" ]]; then
    log "Checking for systemd services referencing $exe"
    
    # Check service files in /etc/systemd/system/
    service_files=$(grep -l "$exe" /etc/systemd/system/*.service 2>/dev/null || true)
    
    # Also check running services
    running_services=$(systemctl list-units --type=service --no-pager --plain | grep "$(basename "$exe")" | awk '{print $1}' || true)
    
    if [[ -n "$service_files" || -n "$running_services" ]]; then
      for service_file in $service_files; do
        service_name=$(basename "$service_file")
        log "Found service file referencing $exe: $service_file"
        if systemctl disable --now "$service_name" 2>/dev/null; then
          log "Successfully disabled service: $service_name"
        else
          log "Failed to disable service: $service_name"
        fi
      done
      
      for service in $running_services; do
        log "Found running service referencing executable: $service"
        if systemctl disable --now "$service" 2>/dev/null; then
          log "Successfully disabled service: $service"
        else
          log "Failed to disable service: $service"
        fi
      done
    else
      log "No systemd services found referencing $exe"
    fi
  fi
  
  # Check cron directories for references to the executable
  if [[ -f "$exe" && "$exe" != "unknown" ]]; then
    log "Checking cron directories for references to $exe"
    
    cron_dirs=("/etc/cron.d" "/etc/cron.daily" "/etc/cron.hourly" "/etc/cron.monthly" "/etc/cron.weekly" "/var/spool/cron/crontabs")
    
    for cron_dir in "${cron_dirs[@]}"; do
      if [[ -d "$cron_dir" ]]; then
        cron_matches=$(grep -rl "$exe" "$cron_dir" 2>/dev/null || true)
        
        if [[ -n "$cron_matches" ]]; then
          for cron_file in $cron_matches; do
            log "Found cron file referencing $exe: $cron_file"
            
            # Create backup
            cp "$cron_file" "$cron_file.bak.$(date +%s)"
            log "Created backup: $cron_file.bak.$(date +%s)"
            
            # Comment out lines containing the executable path
            sed -i "s|.*$exe.*|#&|g" "$cron_file"
            log "Commented out cron entries in $cron_file"
          done
        fi
      fi
    done
    
    # Also check user crontabs
    if command -v crontab >/dev/null 2>&1; then
      for user in $(cut -d: -f1 /etc/passwd); do
        user_cron=$(crontab -l -u "$user" 2>/dev/null | grep "$exe" || true)
        if [[ -n "$user_cron" ]]; then
          log "Found cron entries for user $user referencing $exe"
          # Note: Modifying user crontabs requires more careful handling
          log "WARNING: Manual intervention required for user $user crontab"
        fi
      done
    fi
  fi
  
  log "=== End QUARANTINE section for PID $PID ==="
  echo ""
done

log "Quarantine remediation completed for all suspicious processes"
