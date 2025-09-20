**a. System Overview**

The infrastructure consists of one local network (LAN) and three AWS EC2 virtual machines located in the us-east-1a availability zone.

Inside the local network there are two machines:

- Management Server – used for administration and for connecting to the AWS instances over SSH.
- Windows 11 virtual machine – used as a monitored host, with the Windows Exporter installed.

**In AWS there are three EC2 instances, each with its own role:**

1. OpenVPN server – provides VPN access, issues client certificates, and publishes metrics via the OpenVPN Exporter.
2. Monitoring server – runs Prometheus, Grafana, Node Exporter, and Alertmanager to watch system health.
3. Storage server – runs MinIO (an S3-compatible object store) used for backups from the other servers.

**The AWS account is named “said devops.” I have full root access. Access control is managed with IAM roles assigned to each team:**

- VPN team – access to the OpenVPN server.
- Monitoring team – access to the monitoring server.
- Storage team – access to the storage server.

**Each team member gets:**

- An IAM role granting the necessary AWS permissions (for example to manage logs or EC2 instances).
- A public SSH key for direct login to their assigned EC2 instance.

Some virtual machines were created manually in the AWS Management Console, others with the AWS CLI from the management server.  
At the moment I am the only system administrator responsible for the project.

<br>

**b. Domain Names, IP Addresses, and Useful Links**

| **Service** | **IP Address** | **Domain Name** | **Description** |
| --- | --- | --- | --- |
| OpenVPN server | 3.85.247.98 | —   | VPN access point |
| Monitoring server | 3.85.247.92 | prometheus.aviaratours.com | Prometheus, Grafana, Alertmanager |
| MinIO storage server | 3.85.247.96 | minio.aviaratours.com | Object storage and backups |
| Windows 11 VM (LAN) | 192.168.1.119 | —   | Monitored via Windows Exporter |
| Management server (LAN) | 119.235.125.234 | —   | SSH access and AWS CLI |

Helpful references:

- OpenVPN setup: https://www.cherryservers.com/blog/install-openvpn-server-ubuntu
- MinIO deployment: https://www.atlantic.net/dedicated-server-hosting/how-to-deploy-minio-on-ubuntu-24-04-an-open-source-object-storage-application/
- Prometheus installation: https://bindplane.com/docs/going-to-production/bindplane/architecture/prometheus/install-manual

<br>

**c. System Components and How They Work Together**

**OpenVPN Server**

- Provides secure VPN connections.
- Generates client certificates.
- Sends metrics to Prometheus through port 9176.

**Monitoring Server**

- Continuously monitors all servers.
- Displays data in Grafana dashboards.
- Prometheus collects metrics from every EC2 instance (Node Exporter on port 9100), from the OpenVPN Exporter (port 9176), and from the Windows Exporter on the Windows 11 VM (port 9182).
- Alertmanager emails notifications to Gmail when conditions are violated—for example if a host goes down or CPU load drops below 15 %.

Web interface: https://prometheus.aviaratours.com (login required).

**MinIO Storage Server**

- Stores .sh, .deb, and other files sent from the management server.
- Address: https://minio.aviaratours.com.
- Critical for disaster recovery—it keeps key backups if the main server fails.

**Windows 11 VM (LAN)**

- Runs the Windows Exporter on port 9182.
- If the VM is offline or unreachable, Prometheus immediately triggers an Alertmanager notification.
- Used in the office for applications like Microsoft Office and other utilities.

**Management Server (LAN)**

- Runs the AWS CLI to query and create EC2 instances.
- Holds all EC2 SSH public keys.
- Has cron jobs that automatically send files and directories to the MinIO storage.

<br>

**d. Creating EC2 Instances**

This system uses a combination of manual management through the AWS Console and automated management through the AWS CLI:

**Through the AWS Console**

1. Log in with the root account.
2. Choose region us-east-1a.
3. Go to EC2 → Instances → Launch Instance.
4. Pick an Ubuntu image and create a new key pair (.pem).
5. Assign an Elastic IP to make the instance’s IP static.

<br>

**Through the AWS CLI**

aws ec2 run-instances \\

\--image-id ami-0111190769c4329ae \\

\--instance-type t3.micro \\

\--key-name demo_instance \\

\--subnet-id subnet-XXXXXXXXX \\

\--security-group-ids sg-XXXXXXXXXXX \\

\--tag-specifications 'ResourceType=instance,Tags=\[{Key=Name,Value=monitoring-server}\]'

<br>

**Example package installation on the OpenVPN server:**

```bash
sudo dpkg -i easy-rsa-installer.deb
```

```bash
sudo dpkg -i openvpn-installer.deb
```

```bash
sudo dpkg -i openvpn-exporter.deb
```

```bash
sudo systemctl status openvpn
```

<br>

**For the monitoring server:**

```bash
sudo dpkg -i prometheus.deb
```

```bash
sudo dpkg -i node-exporter.deb
```

```bash
sudo dpkg -i alertmanager-installer.deb
```

<br>

If a package is already installed, the installer skips it and reports that it’s present.

<br>

**To remove a package:**

```bash
sudo dpkg -r openvpn-installer # remove only binaries
```

```bash
sudo dpkg -P openvpn-installer # remove including configuration
```

<br>

**MinIO Installation and Setup**

<br>

MinIO runs on a separate server and is installed manually

<br>

**Installing MinIO:**  

**Download the MinIO binary file from the official website using wget**

```bash
wget https://dl.min.io/server/minio/release/linux-amd64/minio
```

<br>

**Make the file executable**

```bash
chmod +x minio
```

<br>

**Move the binary to the system directory /usr/local/bin for global use**

```bash
sudo mv minio /usr/local/bin/
```

<br>

**Creating a group, user, and directories.**

```bash
sudo groupadd -r minio-user
```

```bash
sudo useradd -M -r -g minio-user minio-user
```

```bash
sudo mkdir /mnt/data
```

<br>

**Assigning ownership of the directory.**

```bash
sudo chown minio-user:minio-user /mnt/data
```

<br>

**Configuring MinIO (file /etc/default/minio):**

```bash
MINIO_VOLUMES="/mnt/data/"

MINIO_OPTS="-C /etc/minio --address {ip_address}:9000"

MINIO_ROOT_USER={username}

MINIO_ROOT_PASSWORD={password}

MINIO_ACCESS_KEY={access_key}

MINIO_SECRET_KEY={secret_key}
```

<br>

**Systemd service /etc/systemd/system/minio.service (unit file provided in the original text).**

```bash
[Unit]

Description=Minio

Documentation=https://docs.minio.io

Wants=network-online.target

After=network-online.target

AssertFileIsExecutable=/usr/local/bin/minio



[Service]

WorkingDirectory=/usr/local/

User=minio-user

Group=minio-user

PermissionsStartOnly=true

EnvironmentFile=-/etc/default/minio

ExecStartPre=/bin/bash -c "if [ -z \"${MINIO_VOLUMES}\" ]; then echo \"Variable MINIO_VOLUMES not set in /etc/default/minio\"; exit 1; fi"

ExecStart=/usr/local/bin/minio server $MINIO_OPTS $MINIO_VOLUMES

Restart=on-success

StandardOutput=journal

StandardError=inherit

LimitNOFILE=65536

TimeoutStopSec=0

KillSignal=SIGTERM

SendSIGKILL=no

SuccessExitStatus=0



[Install]

WantedBy=multi-user.target
```

<br>

**Starting MinIO as a service:**

```bash
sudo systemctl enable minio.service
```

```bash
sudo systemctl start minio
```

```bash
sudo systemctl status minio
```

<br>

**Install MinIO client (mc) and create a bucket:**

**Download the mc binary file from the official website using wget**

```bash
wget https://dl.min.io/client/mc/release/linux-amd64/mc
```

<br>

**Make the file executable**

```bash
chmod +x mc
```

<br>

**Move the binary to the system directory /usr/local/bin for global use**

```bash
sudo mv mc /usr/local/bin/
```

<br>

**Configuring the MinIO client and creating a bucket**

```bash
mc alias set myminio https://{ip}:9000 {username} {password}
```

```bash
mc mb myminio/backup_system
```

<br>

**e. Backups with MinIO**

**Package management and distribution**

- All .deb packages and scripts are stored on the Management Server.
- A daily cron job uploads them to the MinIO bucket backup_system/ with a timestamp.

<br>

**Access for other teams**

Other teams do **not** have direct MinIO access (no API or mc access).

The MinIO team shares requested files via scp, for example:

```bash
scp user@minio-host:/mnt/data/backup_system/backup_2025-07-13.tar.gz .
```

**f. Monitoring Server**

**Components:**

- Prometheus – collects and stores metrics.
- Node Exporter – runs on all EC2 instances.
- OpenVPN Exporter – monitors VPN connections.
- Grafana – dashboards and visualization.
- Alertmanager – sends email alerts (Gmail).

**Alerts are triggered when:**

- A server is unreachable (ping failure or Node Exporter stops).
- openvpn.service is down or crashes.
- No clients are connected to the VPN.
- The Windows VM is offline or unreachable.
- Disk space is below 10 %.
- The VM runs out of available memory.
