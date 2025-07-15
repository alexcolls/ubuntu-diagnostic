#!/bin/bash

# Heuristic evaluation script to flag suspicious PIDs
# Step 7: Heuristic evaluation & flag suspicious PIDs

# Define variables and arrays
WHITELIST=(
    "/usr/bin/bash"
    "/usr/bin/systemd"
    "/usr/sbin/systemd"
    "/usr/bin/dbus-daemon"
    "/usr/sbin/NetworkManager"
    "/usr/bin/gnome-session"
    "/usr/bin/firefox"
    "/usr/bin/chrome"
    "/usr/bin/code"
    "/usr/bin/vim"
    "/usr/bin/nano"
    "/usr/bin/ssh"
    "/usr/bin/python3"
    "/usr/bin/node"
    "/usr/bin/java"
)

MINER_BLACKLIST=(
    "miner"
    "cryptominer" 
    "xmrig"
    "cpuminer"
    "minerd"
    "cgminer"
    "bfgminer"
    "ethminer"
    "claymore"
    "phoenix"
    "t-rex"
    "nbminer"
    "gminer"
    "lolminer"
    "teamredminer"
    "nanominer"
    "srbminer"
    "wildrig"
    "z-enemy"
    "ccminer"
    "excavator"
    "bminer"
    "awesome"
    "malware"
    "backdoor"
    "trojan"
    "rootkit"
    "keylogger"
    "botnet"
    "coinminer"
    "cryptonight"
    "monero"
    "bitcoin"
    "ethereum"
    "mining"
    "hashcat"
    "john"
    "hydra"
    "nmap"
    "metasploit"
    "payload"
    "exploit"
    "shell"
    "reverse"
    "bind"
    "nc"
    "netcat"
    "socat"
    "telnet"
    "wget"
    "curl"
    "python"
    "perl"
    "ruby"
    "php"
    "bash"
    "sh"
    "zsh"
    "fish"
    "tcsh"
    "ksh"
    "dash"
    "ash"
)

SUSPICIOUS_PIDS=()
CURRENT_USER=$(whoami)
CURRENT_UID=$(id -u)
HIGH_USAGE_THRESHOLD=50  # CPU usage threshold
NON_STANDARD_PORTS=(3333 14444 5555 9999 4444 8888 7777 6666 1337 31337 8080 9000 9001 9002 9003)

echo "=== HEURISTIC EVALUATION & SUSPICIOUS PID DETECTION ==="
echo "Current user: $CURRENT_USER (UID: $CURRENT_UID)"
echo "Timestamp: $(date)"
echo "=============================================="

# Function to check if a path is in the whitelist
is_whitelisted() {
    local path=$1
    for white in "${WHITELIST[@]}"; do
        if [[ "$path" == "$white" ]]; then
            return 0
        fi
    done
    return 1
}

# Function to check if a process name is in the blacklist (case-insensitive)
is_blacklisted() {
    local name=$1
    local name_lower="${name,,}"  # Convert to lowercase
    for black in "${MINER_BLACKLIST[@]}"; do
        local black_lower="${black,,}"
        if [[ "$name_lower" == *"$black_lower"* ]]; then
            return 0
        fi
    done
    return 1
}

# Function to check if path is in suspicious directories
is_suspicious_path() {
    local path=$1
    
    # Check for common suspicious directories
    if [[ "$path" == /tmp/* ]] || \
       [[ "$path" == /var/tmp/* ]] || \
       [[ "$path" == /dev/shm/* ]] || \
       [[ "$path" == "$HOME/Downloads"* ]] || \
       [[ "$path" == "$HOME/."* ]] || \
       [[ "$path" == /var/www/* ]] || \
       [[ "$path" == /usr/tmp/* ]] || \
       [[ "$path" == /var/cache/* ]] || \
       [[ "$path" == /var/spool/* ]]; then
        return 0
    fi
    
    return 1
}

# Function to check if port is non-standard
is_non_standard_port() {
    local port=$1
    for nsp in "${NON_STANDARD_PORTS[@]}"; do
        if [[ "$port" == "$nsp" ]]; then
            return 0
        fi
    done
    return 1
}

# Get all PIDs
echo "Scanning all running processes..."
PIDS=$(ps -e -o pid --no-headers | tr -d ' ')

for PID in $PIDS; do
    # Skip if PID directory doesn't exist (process may have ended)
    if [[ ! -d "/proc/$PID" ]]; then
        continue
    fi
    
    # Get executable path
    EXE_PATH=$(/usr/bin/readlink -f /proc/$PID/exe 2>/dev/null)
    
    # Rule 1: Skip if executable path in WHITELIST
    if is_whitelisted "$EXE_PATH"; then
        echo "PID $PID: WHITELISTED - $EXE_PATH"
        continue
    fi
    
    # Get process information
    CMDLINE=$(cat /proc/$PID/cmdline 2>/dev/null | tr '\0' ' ')
    EXE_BASENAME=$(basename "$EXE_PATH" 2>/dev/null)
    PROCESS_INFO=$(ps -p $PID -o pid,ppid,uid,user,pcpu,pmem,comm,args --no-headers 2>/dev/null)
    
    if [[ -z "$PROCESS_INFO" ]]; then
        continue
    fi
    
    # Extract process details
    PROCESS_UID=$(echo "$PROCESS_INFO" | awk '{print $3}')
    PROCESS_USER=$(echo "$PROCESS_INFO" | awk '{print $4}')
    CPU_USAGE=$(echo "$PROCESS_INFO" | awk '{print $5}' | cut -d. -f1)
    COMM=$(echo "$PROCESS_INFO" | awk '{print $7}')
    
    # Initialize flags
    SUSPICIOUS=false
    REASON=""
    
    # Rule 2: Check if cmdline or exe basename matches MINER_BLACKLIST (case-insensitive)
    if is_blacklisted "$CMDLINE" || is_blacklisted "$EXE_BASENAME" || is_blacklisted "$COMM"; then
        SUSPICIOUS=true
        REASON="Blacklisted process name/command"
    fi
    
    # Rule 3: Check if exe path is in suspicious directories
    if [[ "$SUSPICIOUS" == false ]] && is_suspicious_path "$EXE_PATH"; then
        SUSPICIOUS=true
        REASON="Executable in suspicious directory: $EXE_PATH"
    fi
    
    # Rule 4: Check if UID is not the session user AND is >= 1000 but not in /etc/passwd
    if [[ "$SUSPICIOUS" == false ]] && [[ "$PROCESS_UID" -ge 1000 ]] && [[ "$PROCESS_UID" != "$CURRENT_UID" ]]; then
        if ! getent passwd "$PROCESS_UID" >/dev/null 2>&1; then
            SUSPICIOUS=true
            REASON="Unknown UID ($PROCESS_UID) not in /etc/passwd"
        fi
    fi
    
    # Rule 5: Check if high-usage AND listening/connecting to non-standard ports
    if [[ "$SUSPICIOUS" == false ]] && [[ "${CPU_USAGE:-0}" -gt "$HIGH_USAGE_THRESHOLD" ]]; then
        # Check for listening ports
        LISTENING_PORTS=$(netstat -tuln 2>/dev/null | grep ":$PID " | awk '{print $4}' | awk -F':' '{print $NF}' | sort -u)
        
        # Check for connections
        CONNECTED_PORTS=$(netstat -tun 2>/dev/null | awk -v pid="$PID" 'NR>2 {print $5}' | awk -F':' '{print $NF}' | sort -u)
        
        # Check all ports
        ALL_PORTS="$LISTENING_PORTS $CONNECTED_PORTS"
        
        for port in $ALL_PORTS; do
            if [[ "$port" =~ ^[0-9]+$ ]] && is_non_standard_port "$port"; then
                SUSPICIOUS=true
                REASON="High CPU usage ($CPU_USAGE%) and using non-standard port $port"
                break
            fi
        done
    fi
    
    # Log the process and mark as suspicious if needed
    if [[ "$SUSPICIOUS" == true ]]; then
        echo "PID $PID: $PROCESS_INFO ⚠ SUSPICIOUS - $REASON"
        SUSPICIOUS_PIDS+=("$PID")
    else
        echo "PID $PID: $PROCESS_INFO"
    fi
done

# Final summary
echo "=============================================="
echo "EVALUATION COMPLETE"
echo "=============================================="

if [[ ${#SUSPICIOUS_PIDS[@]} -eq 0 ]]; then
    echo "✅ No suspicious PIDs detected."
else
    echo "⚠ SUSPICIOUS PIDs DETECTED: ${#SUSPICIOUS_PIDS[@]} process(es)"
    echo "Suspicious PID list: ${SUSPICIOUS_PIDS[*]}"
    
    echo ""
    echo "DETAILED SUSPICIOUS PROCESS INFORMATION:"
    echo "----------------------------------------"
    for pid in "${SUSPICIOUS_PIDS[@]}"; do
        if [[ -d "/proc/$pid" ]]; then
            echo "PID $pid:"
            echo "  - Executable: $(/usr/bin/readlink -f /proc/$pid/exe 2>/dev/null)"
            echo "  - Command: $(cat /proc/$pid/cmdline 2>/dev/null | tr '\0' ' ')"
            echo "  - Process info: $(ps -p $pid -o pid,ppid,uid,user,pcpu,pmem,comm,args --no-headers 2>/dev/null)"
            echo ""
        fi
    done
fi

echo "Total processes scanned: $(echo "$PIDS" | wc -w)"
echo "Suspicious processes found: ${#SUSPICIOUS_PIDS[@]}"
echo "Scan completed at: $(date)"
