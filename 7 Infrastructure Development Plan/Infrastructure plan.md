**Final Project — Small-Company Infrastructure**

**1\. Minimum Services Needed**

For a company of up to about 30 people (including 2–3 developers, a DevOps engineer, an accountant, and managers), the basic infrastructure could include:

| Service | Purpose |
| --- | --- |
| GitLab / Gitea / GitHub | Code storage and CI/CD pipelines |
| Docker + Docker Compose | Packaging and running applications |
| Prometheus + Grafana | Monitoring and alerts |
| Alertmanager | Handles alerts from Prometheus |
| Nginx Proxy Manager | Reverse proxy and SSL certificates |
| Vault or Doppler | Secure storage of secrets |
| MinIO or S3 | Backup and artifact storage |
| OpenVPN / WireGuard | Secure remote access |
| Ansible / Terraform | Infrastructure automation |
| PostgreSQL / MySQL | Main database |
| Loki / Grafana Alloy | Centralized logging and alerting |

<br>

**2\. Ways to Improve**

- Move from manual server setup to full automation using Ansible and Terraform.
- Set up centralized logging with Grafana Alloy and Loki.
- Build CI/CD pipelines that:
  run tests,
  publish Docker images,
  deploy to staging and production.
- Configure MinIO backups with versioning and test restores.
- Separate staging and production environments.
- Use a Python script (scheduled with cron or run manually) to regularly delete unused Docker images from ProGet, freeing space and preventing CI/CD failures.

<br>

**3\. References and Goals**

| Sources / Channels | What Was Useful |
| --- | --- |
| Abhishek Veeramalla (YouTube) | Various mini-projects covering CI/CD, EKS, GitOps, Prometheus, ArgoCD |
| KodeKloud Discord | Real-world Kubernetes practices, working with Helm, Ingress, and Secrets |
| DevOpsHint.com | Examples of GitLab CI/CD pipelines and ELK Stack deployment |

<br>

**What We Want to Achieve:**

| Requirement | Goal |
| --- | --- |
| Fast delivery through GitLab CI/CD | Automate the entire process from code commit to production |
| Centralized logging (ELK) | Easy log searching, better observability, and alerting |
| Manage unused images in ProGet | Optimize Docker image storage |
| Kubernetes с Helm, Ingress, Secrets | Improve scalability, security, and standardization |
| Documentation and onboarding | Help new team members get up to speed quickly |
| Infrastructure as Code (Terraform) | Ensure reproducibility and version control |
| Simple diagnostics (monitoring stack) | Quickly detect and resolve problems |
| Centralized log management | Speed up incident investigations |
| Regular backups | Enable recovery after failures or user errors |
| Secure remote access | Allow work from anywhere in the world |
| Cost-effective and automated | Save time and reduce expenses |

<br>

**4\. Six-Month Plan**

| **Task** | **Short Description** | **Goal** | **Duration (weeks)** | **Order** | **Notes** |
| --- | --- | --- | --- | --- | --- |
| Implement Ansible | Describe server configurations using Ansible | Automation | 2   | 1   | Use roles and inventory files |
| Set Up Monitoring | Install Prometheus, Node Exporter, Grafana, and Alertmanager | Problem detection | 2   | 2   | Configure alerts for CPU, RAM, and disk usage |
| Central Logging | Configure Grafana Alloy + Loki | Log search and alerts | 1   | 3   | Collect logs from Docker containers |
| GitLab CI/CD Pipelines | Create pipelines for testing, building, and deployment | Fast delivery | 3   | 4   | Start with staging environment |
| VPN Setup | Install OpenVPN with exporter and restrict server access | Secure remote access | 1   | 5   | Manage keys and back up configs |
| Terraform Automation | Define virtual machines and S3/MinIO resources as code | Faster infrastructure changes | 2   | 6   | Use AWS or local environment |
| Backups to MinIO | Configure database and configuration backups | Disaster recovery | 1   | 7   | Test the restore process |
| Documentation | Document the full stack, CI/CD processes, and key commands | Onboarding & support | 1   | 8   | Use a Wiki or mkdocs |
| Learn Kubernetes (Basics) | Study core concepts and install Minikube/Kind | Prepare for future migration | 2   | 9   | Can run in parallel with other tasks |
| Reserve Time | Refactoring, debugging, and training | Flexibility | 2   | 10  | Allows for unexpected issues |

Total: about 17 weeks of active work (~4 months).

The remaining ~2 months are reserved for support, documentation updates, small experiments, and refining the CI/CD pipelines.

<br>

**Conclusion**

Over the next six months, even with limited resources, it’s realistic to:

- Automate the infrastructure using Ansible and Terraform
- Implement reliable CI/CD and monitoring systems
- Strengthen security by setting up a VPN
- Prepare for a move to Kubernetes in the future
- Reduce reliance on manual administration

This approach will provide reliability, repeatability, and scalability without adding extra costs.
