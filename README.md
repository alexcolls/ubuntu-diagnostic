# Ubuntu Diagnostic - Quarantine Remediation

A comprehensive security remediation script for Ubuntu systems that performs quarantine actions on suspicious processes.

## Overview

This project implements Step 8 of a security diagnostic pipeline: **Remediation loop for suspicious processes**.

## Features

The `quarantine_remediation.sh` script performs the following actions for each suspicious PID:

1. **Logging**: Comprehensive logging of all quarantine actions
2. **Process Termination**: Attempts to kill suspicious processes using `kill -9`
3. **Executable Quarantine**: 
   - Captures executable paths via `/proc/$PID/exe`
   - Moves executables to quarantine directory if conditions are met
   - Avoids critical system paths
   - Checks for writable directory permissions
4. **Service Management**: Detects and disables systemd services referencing quarantined executables
5. **Cron Job Handling**: Identifies and comments out cron jobs referencing quarantined executables

## Usage

1. **Configure the script**:
   - Edit the `SUSPICIOUS` array to include target PIDs
   - Adjust `QUAR_BASE` path as needed
   - Review `CRITICAL_PATHS` array for your system

2. **Run the script**:
   ```bash
   sudo ./quarantine_remediation.sh
   ```

3. **Review logs**:
   - Check `/var/log/quarantine.log` for detailed execution logs
   - Monitor console output for real-time feedback

## Configuration

### Variables

- `QUAR_BASE`: Base directory for quarantine storage (default: `/var/quarantine`)
- `SUSPICIOUS`: Array of PIDs to process
- `CRITICAL_PATHS`: Protected system directories that won't be quarantined

### Prerequisites

- Root/sudo access required
- Ubuntu/Debian-based system
- systemd service management
- Standard Unix utilities (grep, sed, etc.)

## Security Considerations

- Only non-critical system executables are quarantined
- Backup files are created before modifying cron configurations
- All actions are logged for audit purposes
- Immutable file attributes are handled appropriately

## Log Format

All actions are logged with timestamps in the format:
```
YYYY-MM-DD HH:MM:SS - Action description
```

## License

This project is provided as-is for educational and security purposes.