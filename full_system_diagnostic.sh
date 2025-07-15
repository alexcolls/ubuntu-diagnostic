#!/bin/bash

# Full System Diagnostic Script
# Comprehensive security check for Ubuntu systems

echo "========================================="
echo "    UBUNTU SYSTEM SECURITY DIAGNOSTIC"
echo "========================================="
echo "Timestamp: $(date)"
echo "User: $(whoami)"
echo "System: $(uname -a)"
echo ""

# Step 1: Process Enumeration
echo "1. Running Process Enumeration..."
./enumerate_processes.sh

echo ""
echo "2. Running Heuristic Evaluation..."
./heuristic_evaluation.sh

echo ""
echo "3. Checking for Mining Activity..."
echo "   - Scanning for known mining processes..."
ps aux | grep -i -E "(mine|xmrig|cpuminer|ethminer|claymore|phoenix|t-rex|nbminer|gminer|lolminer|teamredminer|nanominer|srbminer)" | grep -v grep
if [ $? -eq 0 ]; then
    echo "   WARNING: Potential mining processes detected!"
else
    echo "   ✓ No obvious mining processes found"
fi

echo ""
echo "4. Network Connection Analysis..."
echo "   - Checking for suspicious network connections..."
netstat -tuln | grep -E "(3333|4444|5555|8080|9000|9001|14444)"
if [ $? -eq 0 ]; then
    echo "   WARNING: Suspicious ports detected!"
else
    echo "   ✓ No suspicious mining ports found"
fi

echo ""
echo "5. CPU Usage Analysis..."
echo "   - Top 10 CPU consuming processes:"
ps aux --sort=-%cpu | head -11

echo ""
echo "6. Memory Usage Analysis..."
echo "   - Top 10 Memory consuming processes:"
ps aux --sort=-%mem | head -11

echo ""
echo "7. Checking for Suspicious Files..."
echo "   - Scanning /tmp for suspicious executables..."
find /tmp -type f -executable 2>/dev/null | head -20

echo ""
echo "8. Network Traffic Analysis..."
echo "   - Active network connections:"
ss -tuln | head -20

echo ""
echo "9. System Load Analysis..."
echo "   - Current system load:"
uptime
echo "   - CPU info:"
grep -c ^processor /proc/cpuinfo
echo "   - Memory usage:"
free -h

echo ""
echo "10. Checking for Cryptocurrency Mining Indicators..."
echo "    - Checking for mining-related files in common locations..."
find /home -name "*mine*" -o -name "*xmrig*" -o -name "*crypto*" 2>/dev/null | head -10

echo ""
echo "========================================="
echo "    DIAGNOSTIC COMPLETE"
echo "========================================="
echo "Review the output above for any WARNING messages."
echo "Check generated files for detailed analysis."
