**VPN Connection Guide**

**Why Use a VPN?**

Using a VPN ensures secure and protected access to the company’s internal resources from anywhere in the world—whether at home, in the office, or while traveling. A VPN encrypts your connection, protecting your data from interception and unauthorized access.

**What You Get When Connected**

- Secure access to corporate services and internal web resources.
- The ability to work with systems and databases as if you were in the office.
- Safe browsing and information exchange.

**How to Connect to the VPN**

**1\. Obtain a Security Certificate**

A security certificate issued by the IT department is required to connect.

- Send a request for a certificate by email to <it-support@company.com>.
- You will receive an archive containing the certificate files and installation instructions.

**2\. Install the OpenVPN Client**

Use the OpenVPN client, available for various operating systems:

| Operating System | Recommended Client | Download Link |
| --- | --- | --- |
| Windows | OpenVPN Community Client | <https://openvpn.net/community-downloads/> |
| macOS | Tunnelblick or official OpenVPN Client | <https://tunnelblick.net/> or <https://openvpn.net/community-downloads/> |
| Linux | OpenVPN (via package manager) | sudo apt install openvpn (Debian/Ubuntu) or sudo yum install openvpn (CentOS) |
| Android | OpenVPN Connect (official app) | Google Play Store |
| iOS | OpenVPN Connect (official app) | App Store |

**3\. Configure the OpenVPN Client**

- Unpack the archive containing your certificate.
- Import the configuration file (.ovpn) into the OpenVPN client.
- **Windows/macOS**: In the OpenVPN application, choose “Import Profile” and select the file.
- **Linux**: Use a terminal command, for example:
- sudo openvpn --config /path/to/file.ovpn
- **Mobile devices**: Upload the .ovpn file into the OpenVPN Connect app and activate the profile.

**4\. Connect to the VPN**

- Launch the OpenVPN client.
- Select the profile associated with your certificate.
- Click **Connect**.
- After a successful connection, you will have access to the corporate network

**Where to Get Help**

If you encounter problems obtaining the certificate, installing, or connecting to the VPN, send an email to **<it-support@company.com>**.  
Include in your message:

- A description of the issue.
- Your operating system and version.
- Screenshots or error text (if available).

**Additional Recommendations**

- Do not share your certificate with third parties.
- Use the VPN only for work-related purposes.
- If the certificate is lost or compromised, notify the IT department immediately.

If you need OS-specific assistance, the IT team can provide separate detailed instructions.