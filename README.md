# Ubuntu Diagnostic - Quarantine Remediation Suite

A set of comprehensive scripts designed to monitor, evaluate, and remediate security threats on Ubuntu systems.

## Overview

This project is part of a security diagnostic pipeline focusing on the identification and remediation of suspicious processes.

## Features

### 1. Process Enumeration
- **Script:** `enumerate_processes.sh`
- **Description:** Enumerates running processes and identifies high usage candidates based on CPU and memory usage.
- **Outputs:**
  - Raw process data
  - High usage process log
  - Summary of analysis

### 2. Heuristic Evaluation
- **Script:** `heuristic_evaluation.sh`
- **Description:** Utilizes heuristic techniques to flag suspicious PIDs. It checks processes against white/blacklists and ports.
- **Alerts:**
  - Suspicious process naming
  - Utilization of non-standard ports

### 3. Quarantine Remediation
- **Script:** `quarantine_remediation.sh`
- **Description:** Automatically manages the quarantine of reported suspicious processes.
  - Comprehensive logging of actions
  - Safe termination and storage
  - Disabling associated services and cron jobs

### 4. Miner Detection and Quarantine
- **Script:** `find_and_quarantine_miners.sh`
- **Description:** Searches and quarantines known crypto miners using defined blacklists.

## Usage

1. **Configure the scripts**:
   - Review and adjust arrays like `SUSPICIOUS`, `WHITELIST`, and `MINER_BLACKLIST` as needed.
   - Modify any directory paths to suit your system configuration.

2. **Run the scripts in order**:
   ```bash
   ./enumerate_processes.sh
   ./heuristic_evaluation.sh
   sudo ./quarantine_remediation.sh
   sudo ./find_and_quarantine_miners.sh
   ```

3. **Review logs**:
   - Check dedicated log files for each component stored in `/var/log/` or output files generated in the root directory.

## Configuration

### Common Variables

- **`QUAR_BASE`**: Base directory for quarantine storage (default: `/var/quarantine`)
- **Arrays**: Adjust to match organizational policies and threat benchmarks

### Prerequisites

- Root/sudo access required
- Compatible with Ubuntu/Debian-based systems
- Essential Unix utilities (e.g., grep, sed)

## Security Considerations

- Ensures only non-critical executables are quarantined
- Comprehensive logging provides full traceability
- Utilizes secure coding practices and avoids critical disruptions

## Log Format
Log entries are timestamped for audit purposes in the format:
```
YYYY-MM-DD HH:MM:SS - Action description
```

## Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/alexcolls/ubuntu-diagnostic.git
   cd ubuntu-diagnostic
   ```

2. **Make scripts executable:**
   ```bash
   chmod +x *.sh
   ```

3. **Create necessary directories:**
   ```bash
   sudo mkdir -p /var/quarantine
   sudo mkdir -p /var/log
   ```

## Example Output

### Process Enumeration
```
=== Process Enumeration and High Usage Detection ===
Timestamp: 2025-07-15 08:26:54
HIGH USAGE DETECTED: PID=1234, USER=root, CPU=45.2%, RSS=524288KB
  Command: /usr/bin/suspicious_process
  Reason: High CPU usage (45.2% > 40%)
```

### Heuristic Evaluation
```
=== HEURISTIC EVALUATION & SUSPICIOUS PID DETECTION ===
PID 1234: SUSPICIOUS - Blacklisted process name/command
PID 5678: SUSPICIOUS - Running from suspicious directory (/tmp)
```

## Troubleshooting

### Common Issues

1. **Permission Denied:**
   - Ensure you're running remediation scripts with `sudo`
   - Check file permissions on script files

2. **Missing Dependencies:**
   - Install `bc` for floating-point calculations: `sudo apt install bc`
   - Ensure all standard Unix utilities are available

3. **Log File Access:**
   - Check `/var/log/` permissions
   - Ensure log directory exists and is writable

### Debug Mode

To enable verbose output, modify scripts by uncommenting:
```bash
# set -x  # Enable debug mode
```

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request with detailed description

## Disclaimer

⚠️ **Warning:** These scripts are designed for security analysis and should be used responsibly. Always test in a controlled environment before deploying to production systems.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
