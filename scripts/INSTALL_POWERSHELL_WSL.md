# Installing PowerShell in WSL

## Option 1: Install PowerShell Core in WSL (Recommended)

To install PowerShell in your WSL Ubuntu environment, run these commands:

```bash
# Update the list of packages
sudo apt-get update

# Install pre-requisite packages
sudo apt-get install -y wget apt-transport-https software-properties-common

# Download the Microsoft repository GPG keys
wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb"

# Register the Microsoft repository GPG keys
sudo dpkg -i packages-microsoft-prod.deb

# Update the list of packages after we added packages.microsoft.com
sudo apt-get update

# Install PowerShell
sudo apt-get install -y powershell

# Start PowerShell
pwsh
```

## Option 2: Use Windows PowerShell from WSL

You can also call Windows PowerShell directly from WSL:

```bash
# Run a PowerShell command from WSL
powershell.exe -Command "Get-Process"

# Run the deployment script using Windows PowerShell
powershell.exe -File "/mnt/c/path/to/Deploy-EasySpaces.ps1"
```

Note: Replace `/mnt/c/path/to/` with the actual Windows path to your script.

## Option 3: Use the Bash Alternative Script

We've provided a bash alternative that doesn't require PowerShell:

```bash
cd /home/e/projects/easy-spaces-dynamics365/scripts
./deploy-easy-spaces.sh
```

This script will:
- Validate your environment URL
- Create a solution package
- Generate detailed import instructions
- Guide you through manual deployment

## Checking Installation

After installing PowerShell, verify it works:

```bash
# Check version
pwsh --version

# Start PowerShell
pwsh

# Exit PowerShell
exit
```

## Troubleshooting

### If you get permission errors:
```bash
# Make sure you're using sudo for installation
sudo apt-get install -y powershell
```

### If the Microsoft repository isn't found:
```bash
# For Ubuntu 20.04
wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
```

### If PowerShell won't start:
```bash
# Check if it's installed
which pwsh

# Try the full path
/usr/bin/pwsh

# Check for errors
pwsh --version
```

## Why PowerShell in WSL?

PowerShell in WSL is useful for:
- Running Dynamics 365 deployment scripts
- Managing Power Platform resources
- Using Microsoft Graph API
- Automating Azure/Microsoft 365 tasks

However, for Easy Spaces deployment, the bash script alternative (`deploy-easy-spaces.sh`) works just as well!