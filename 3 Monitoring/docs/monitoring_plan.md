Designing the Monitoring System

**a. Operating-system metrics**

To collect key metrics from each server’s operating system, the best tool is Node Exporter. It reports real-time data such as CPU load, memory usage, file-system status (like low disk space), and whether the virtual machine (VM) is up and running.

For Windows servers, I also used Windows Exporter, which tracks the same kinds of performance and health indicators. If a VM unexpectedly restarts or shuts down, the exporter records the event.

The Node Exporter metrics are standard and can be reused to monitor every VM in the network, no matter its role or OS.

**b. Monitoring OpenVPN**

For the OpenVPN server, I chose OpenVPN Exporter, which shows how many clients are connected and whether the service is available.

You can also rely on indirect metrics—such as network traffic, port status, and running processes—from the system exporters to confirm that OpenVPN is healthy even if its own metrics are limited.

**c. VM alert rules**  
I set up alerts for these conditions:

- CPU usage above 85 % for more than one minute
- Less than 10 % free RAM
- Less than 10 % free disk space (ignoring temporary, SSH, and network file systems)
- The exporter itself is unreachable (which can mean the VM is down or frozen)
- An unexpected reboot or shutdown on a Windows VM

**d. OpenVPN alert rules**

Alerts trigger if:

The OpenVPN service stops

The number of connected clients suddenly drops (a possible problem)

**Other details**

Node Exporter and OpenVPN Exporter all run as systemd services. An Alertmanager is set up to send notifications to my Gmail account whenever an alert fires.