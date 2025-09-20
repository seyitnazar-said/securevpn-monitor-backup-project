## Updating Packages and Enabling Automatic Updates on Ubuntu

### Update the package index to make sure we have the latest info on available packages

```bash
sudo apt update
```

### Install the unattended-upgrades package which enables automatic updates

```bash
sudo apt install unattended-upgrades
```

### Check the status of the unattended-upgrades service to see if it's running

```bash
sudo systemctl status unattended-upgrades
```

### Open the configuration file that defines which packages and origins can be automatically upgraded

```bash
sudo vim /etc/apt/apt.conf.d/50unattended-upgrades
```

#### In this file, define which package sources are allowed for automatic upgrades

```bash
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";          # Main Ubuntu repository
    "${distro_id}:${distro_codename}-security"; # Security updates repository
};
```

#### Optionally, define packages that should NOT be automatically upgraded

```bash
Unattended-Upgrade::Package-Blacklist {
    apache2   # Prevent Apache from being automatically upgraded
};
```

### Open the configuration file that sets the frequency of automatic updates

```bash
sudo vim /etc/apt/apt.conf.d/20auto-upgrades
```

#### Configure periodic updates:
```bash
APT::Periodic::Update-Package-Lists "1";     # Update package lists daily
APT::Periodic::Unattended-Upgrade "1";       # Apply unattended upgrades daily
APT::Periodic::AutocleanInterval "7";        # Clean up obsolete packages every 7 days
```

### Restart the unattended-upgrades service to apply changes
```bash
sudo systemctl restart unattended-upgrades.service
```

### Test the unattended-upgrades configuration without actually installing updates
```bash
sudo unattended-upgrades --dry-run --debug
```

## Source
**https://phoenixnap.com/kb/automatic-security-updates-ubuntu**
