#!/bin/bash

# Script to enumerate running processes and identify high usage candidates
# Step 4: Enumerate running processes (CPU & memory)

# Exit on any error - temporarily disabled for debugging
# set -e

# Arrays to store process information
declare -a pids=()
declare -a ppids=()
declare -a users=()
declare -a commands=()
declare -a cpu_usage=()
declare -a mem_usage=()
declare -a rss_values=()
declare -a high_usage_processes=()

# Output files
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
RAW_OUTPUT_FILE="process_raw_${TIMESTAMP}.txt"
HIGH_USAGE_FILE="high_usage_processes_${TIMESTAMP}.txt"
SUMMARY_FILE="process_summary_${TIMESTAMP}.txt"

echo "=== Process Enumeration and High Usage Detection ==="
echo "Timestamp: $(date)"
echo "Output files will be created:"
echo "- Raw process data: $RAW_OUTPUT_FILE"
echo "- High usage processes: $HIGH_USAGE_FILE"
echo "- Summary: $SUMMARY_FILE"
echo ""
echo "Capturing process information..."

# Capture the ps output and save to file
ps_output=$(/usr/bin/ps -eo pid,ppid,user:20,cmd,%cpu,%mem,rss --no-headers)
echo "$ps_output" > "$RAW_OUTPUT_FILE"

# Check if bc is available for floating point comparisons
if ! command -v bc &> /dev/null; then
    echo "Warning: bc command not found. Using integer comparison for CPU usage."
    USE_BC=false
else
    USE_BC=true
fi

# Parse each line and populate arrays
line_count=0
while IFS= read -r line; do
    # Skip empty lines
    [[ -z "$line" ]] && continue
    
    # Parse fields using awk to handle whitespace properly
    pid=$(echo "$line" | awk '{print $1}')
    ppid=$(echo "$line" | awk '{print $2}')
    user=$(echo "$line" | awk '{print $3}')
    cpu=$(echo "$line" | awk '{print $(NF-2)}')
    mem=$(echo "$line" | awk '{print $(NF-1)}')
    rss=$(echo "$line" | awk '{print $NF}')
    
    # Command is everything from field 4 to field (NF-3)
    cmd=$(echo "$line" | awk '{for(i=4; i<=NF-3; i++) printf "%s ", $i; print ""}' | sed 's/[[:space:]]*$//')
    
    # Store in arrays
    pids[line_count]=$pid
    ppids[line_count]=$ppid
    users[line_count]=$user
    commands[line_count]=$cmd
    cpu_usage[line_count]=$cpu
    mem_usage[line_count]=$mem
    rss_values[line_count]=$rss
    
    # Check for high usage: CPU > 40% OR RSS > 512000 (≈500 MB)
    cpu_high=false
    rss_high=false
    
    # Check CPU usage
    if [[ "$USE_BC" == "true" ]]; then
        # Use bc for floating point comparison
        if [[ $(echo "$cpu > 40" | bc -l) -eq 1 ]]; then
            cpu_high=true
        fi
    else
        # Convert to integer for comparison (remove decimal point)
        cpu_int=$(echo "$cpu" | cut -d. -f1)
        if [[ -n "$cpu_int" ]] && (( cpu_int > 40 )); then
            cpu_high=true
        fi
    fi
    
    # Check RSS usage
    if (( rss > 512000 )); then
        rss_high=true
    fi
    
    # If either condition is met, mark as high usage
    if [[ "$cpu_high" == "true" ]] || [[ "$rss_high" == "true" ]]; then
        high_usage_processes+=("$line_count")
        echo "HIGH USAGE DETECTED: PID=$pid, USER=$user, CPU=$cpu%, RSS=${rss}KB"
        echo "  Command: $cmd"
        if [[ "$cpu_high" == "true" ]]; then
            echo "  Reason: High CPU usage ($cpu% > 40%)"
        fi
        if [[ "$rss_high" == "true" ]]; then
            echo "  Reason: High memory usage (${rss}KB > 512000KB)"
        fi
        echo ""
    fi
    
    ((line_count++))
done <<< "$ps_output"

echo "=== Summary ==="
echo "Total processes analyzed: $line_count"
echo "High usage processes found: ${#high_usage_processes[@]}"

echo ""
echo "=== High Usage Process Details ==="
for idx in "${high_usage_processes[@]}"; do
    echo "Process Index: $idx"
    echo "  PID: ${pids[$idx]}"
    echo "  PPID: ${ppids[$idx]}"
    echo "  User: ${users[$idx]}"
    echo "  CPU: ${cpu_usage[$idx]}%"
    echo "  Memory: ${mem_usage[$idx]}%"
    echo "  RSS: ${rss_values[$idx]} KB"
    echo "  Command: ${commands[$idx]}"
    echo ""
done

echo "=== Arrays populated for later lookup ==="
echo "Process data stored in arrays:"
echo "- pids[] (${#pids[@]} entries)"
echo "- ppids[] (${#ppids[@]} entries)"
echo "- users[] (${#users[@]} entries)"
echo "- commands[] (${#commands[@]} entries)"
echo "- cpu_usage[] (${#cpu_usage[@]} entries)"
echo "- mem_usage[] (${#mem_usage[@]} entries)"
echo "- rss_values[] (${#rss_values[@]} entries)"
echo "- high_usage_processes[] (${#high_usage_processes[@]} entries with indices)"

echo ""
echo "=== Criteria for High Usage ==="
echo "A process is marked as 'high usage' if:"
echo "- CPU usage > 40% OR"
echo "- RSS memory > 512000 KB (≈500 MB)"

# Save high usage processes to file
echo "=== Saving results to files ==="
{
    echo "High Usage Processes - $(date)"
    echo "Criteria: CPU > 40% OR RSS > 512000 KB"
    echo "========================================"
    echo ""
    for idx in "${high_usage_processes[@]}"; do
        echo "Process Index: $idx"
        echo "  PID: ${pids[$idx]}"
        echo "  PPID: ${ppids[$idx]}"
        echo "  User: ${users[$idx]}"
        echo "  CPU: ${cpu_usage[$idx]}%"
        echo "  Memory: ${mem_usage[$idx]}%"
        echo "  RSS: ${rss_values[$idx]} KB"
        echo "  Command: ${commands[$idx]}"
        echo ""
    done
} > "$HIGH_USAGE_FILE"

# Save summary to file
{
    echo "Process Analysis Summary - $(date)"
    echo "===================================="
    echo ""
    echo "Total processes analyzed: $line_count"
    echo "High usage processes found: ${#high_usage_processes[@]}"
    echo ""
    echo "Array sizes:"
    echo "- pids[]: ${#pids[@]}"
    echo "- ppids[]: ${#ppids[@]}"
    echo "- users[]: ${#users[@]}"
    echo "- commands[]: ${#commands[@]}"
    echo "- cpu_usage[]: ${#cpu_usage[@]}"
    echo "- mem_usage[]: ${#mem_usage[@]}"
    echo "- rss_values[]: ${#rss_values[@]}"
    echo "- high_usage_processes[]: ${#high_usage_processes[@]}"
    echo ""
    echo "High usage criteria:"
    echo "- CPU usage > 40% OR"
    echo "- RSS memory > 512000 KB (≈500 MB)"
    echo ""
    echo "Files created:"
    echo "- Raw process data: $RAW_OUTPUT_FILE"
    echo "- High usage processes: $HIGH_USAGE_FILE"
    echo "- Summary: $SUMMARY_FILE"
} > "$SUMMARY_FILE"

echo "Results saved to:"
echo "- Raw process data: $RAW_OUTPUT_FILE"
echo "- High usage processes: $HIGH_USAGE_FILE"
echo "- Summary: $SUMMARY_FILE"

echo ""
echo "=== Task Completed ==="
echo "Process enumeration completed successfully!"
echo "All process data has been captured and parsed into arrays."
echo "High usage processes (CPU > 40% OR RSS > 512000 KB) have been identified."
