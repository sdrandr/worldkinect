# Jenkins EC2 Quick-Start Checklist

## Pre-Launch (5 minutes)
- [ ] Decided on OS: Ubuntu 24.04 LTS ☐  or Amazon Linux 2023 ☐
- [ ] Decided on instance type: ________________
- [ ] Have SSH key pair ready: ________________
- [ ] Know your IP address for security group: ________________

## Launch EC2 Instance (10 minutes)
- [ ] Instance launched with name: ________________
- [ ] Instance ID: ________________
- [ ] Public IP: ________________
- [ ] Private IP: ________________
- [ ] Security group created: ________________
  - [ ] Port 22 (SSH) open to my IP
  - [ ] Port 8080 (Jenkins) open to my IP
- [ ] Storage: 50-100GB gp3 allocated
- [ ] IAM role attached (optional): ________________
- [ ] Termination protection enabled (if production)

## Connect & Install (15 minutes)
- [ ] Successfully SSH'd into instance
- [ ] System packages updated
- [ ] Java 17 installed and verified
- [ ] Jenkins repository added
- [ ] Jenkins installed
- [ ] Jenkins service started and enabled
- [ ] Jenkins status shows "active (running)"
- [ ] Port 8080 is listening
- [ ] Initial admin password retrieved and saved: ________________

## First Access (10 minutes)
- [ ] Accessed Jenkins at http://<PUBLIC_IP>:8080
- [ ] Unlocked Jenkins with initial password
- [ ] Installed suggested plugins (or custom selection)
- [ ] Created admin user:
  - Username: ________________
  - Password: (stored in password manager)
  - Email: ________________
- [ ] Jenkins URL configured

## Essential Configuration (20 minutes)
- [ ] Security configured:
  - [ ] Anonymous access disabled
  - [ ] CSRF protection enabled
  - [ ] Authorization strategy set
- [ ] Additional plugins installed:
  - [ ] Amazon EC2 Plugin
  - [ ] AWS Credentials Plugin
  - [ ] Blue Ocean
  - [ ] Docker Plugin (if needed)
  - [ ] Git/GitHub/GitLab plugins
  - [ ] Build tool plugins (Maven/Gradle/NodeJS)
- [ ] System configuration:
  - [ ] Number of executors set: ____
  - [ ] Admin email configured
  - [ ] Jenkins URL verified
- [ ] Tools configured:
  - [ ] JDK configured
  - [ ] Git configured
  - [ ] Other tools (Maven/Gradle/Node): ________________
- [ ] AWS credentials added (or IAM role verified)

## Performance Tuning (10 minutes)
- [ ] Java heap size increased (if t3.large or larger)
- [ ] Swap configured (4GB)
- [ ] Build discard strategy configured

## Backup Setup (15 minutes)
Choose one or more:
- [ ] EBS snapshot schedule created
- [ ] ThinBackup plugin installed and configured
- [ ] S3 backup script created and scheduled
- [ ] Tested restore procedure documented

## Monitoring (10 minutes)
- [ ] CloudWatch detailed monitoring enabled
- [ ] CloudWatch alarms created:
  - [ ] High CPU (>80%)
  - [ ] Low disk space (>80%)
- [ ] CloudWatch agent installed (for disk metrics)
- [ ] Jenkins monitoring plugin installed

## Optional Enhancements (30-60 minutes)
- [ ] SSL/HTTPS configured with Nginx + Let's Encrypt
- [ ] Domain name pointed to Jenkins
- [ ] Dynamic EC2 agents configured:
  - [ ] Agent AMI identified: ________________
  - [ ] Agent security group created: ________________
  - [ ] Agent template configured
  - [ ] Test agent provisioned successfully
- [ ] Slack/Email notifications configured
- [ ] Blue Ocean UI explored

## First Pipeline (15 minutes)
- [ ] Test pipeline created and run successfully
- [ ] Git repository connected
- [ ] Real pipeline created from Jenkinsfile
- [ ] Webhook configured (optional)
- [ ] Successful build executed

## Documentation (10 minutes)
- [ ] Instance details documented
- [ ] Admin credentials stored securely
- [ ] Backup procedure documented
- [ ] Team members granted access
- [ ] Runbook created for common operations

## Post-Setup Tasks
- [ ] Security group locked down to minimum required IPs
- [ ] Regular maintenance schedule created
- [ ] Team trained on Jenkins usage
- [ ] Pipeline templates created for common jobs
- [ ] Monitoring dashboard created

---

## Estimated Timeline

| Task | Time |
|------|------|
| Pre-Launch & Launch EC2 | 15 min |
| Connect & Install Jenkins | 15 min |
| First Access & Setup | 10 min |
| Essential Configuration | 20 min |
| Performance Tuning | 10 min |
| Backup Setup | 15 min |
| Monitoring | 10 min |
| **Basic Setup Total** | **~95 min** |
| | |
| Optional: SSL/HTTPS | 30 min |
| Optional: Dynamic Agents | 30 min |
| Optional: Advanced Config | 30 min |
| **Full Setup with Options** | **~185 min** |

---

## Common Mistakes to Avoid

❌ **Security Group too open** (0.0.0.0/0)
✅ Restrict to your IP or company CIDR

❌ **Forgot to enable Jenkins service**
✅ Run: `sudo systemctl enable jenkins`

❌ **Insufficient disk space** (<30GB)
✅ Allocate at least 50GB for many pipelines

❌ **No backup strategy**
✅ Set up backups on day 1

❌ **Running builds on master**
✅ Use agents for builds

❌ **Hardcoded secrets in pipelines**
✅ Use Jenkins credentials store

❌ **Never updating plugins**
✅ Schedule monthly updates

❌ **No monitoring**
✅ Set up CloudWatch alarms

---

## Success Criteria

✅ Can access Jenkins web interface
✅ Can log in as admin
✅ Can create and run a pipeline
✅ Can connect to Git repository
✅ Backups are running
✅ Monitoring is active
✅ Security is properly configured
✅ Performance is adequate for your workload

---

## Emergency Contacts

| Role | Name | Contact |
|------|------|---------|
| Jenkins Admin | __________ | __________ |
| AWS Admin | __________ | __________ |
| Team Lead | __________ | __________ |
| On-Call | __________ | __________ |

---

## Quick Commands Reference

```bash
# SSH to instance
ssh -i /path/to/key.pem ubuntu@<PUBLIC_IP>

# Get initial password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# Check Jenkins status
sudo systemctl status jenkins

# Restart Jenkins
sudo systemctl restart jenkins

# View logs
sudo journalctl -u jenkins -f

# Check disk space
df -h

# Check memory
free -h

# Backup Jenkins
sudo tar -czf jenkins-backup.tar.gz /var/lib/jenkins
```

---

## Notes Section

**Installation Date:** ________________

**Jenkins Version:** ________________

**Java Version:** ________________

**OS Version:** ________________

**Instance Type:** ________________

**Security Group ID:** ________________

**IAM Role:** ________________

**Backup Location:** ________________

**SSL Certificate:** ________________

**Custom Configurations:**
_______________________________________
_______________________________________
_______________________________________

**Known Issues:**
_______________________________________
_______________________________________
_______________________________________

**Future Enhancements:**
_______________________________________
_______________________________________
_______________________________________
