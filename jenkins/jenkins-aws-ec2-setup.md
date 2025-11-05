# Jenkins on EC2 - Complete Setup Guide

## Overview
This guide covers installing Jenkins on a fresh EC2 instance using Ubuntu 24.04 LTS or Amazon Linux 2023.

## Part 1: Launch EC2 Instance

### Step 1: Launch Instance from AWS Console

1. Go to **EC2 Dashboard** → **Launch Instance**

2. **Name and tags**
   - Name: `jenkins-server` (or your preferred name)

3. **Application and OS Images (AMI)**
   
   **Option A: Ubuntu 24.04 LTS (Recommended for ease of use)**
   - AMI: Ubuntu Server 24.04 LTS
   - Architecture: 64-bit (x86)
   
   **Option B: Amazon Linux 2023 (AWS-optimized)**
   - AMI: Amazon Linux 2023
   - Architecture: 64-bit (x86)

4. **Instance Type**
   
   For many pipelines, choose:
   - **Minimum**: t3.medium (2 vCPU, 4 GB RAM) - ~$30/month
   - **Recommended**: t3.large (2 vCPU, 8 GB RAM) - ~$60/month
   - **Heavy workloads**: t3.xlarge (4 vCPU, 16 GB RAM) - ~$120/month
   - **Production**: m5.large (2 vCPU, 8 GB RAM) - better baseline performance

5. **Key pair (login)**
   - Select your existing key pair, or
   - Create new key pair:
     - Name: `jenkins-key`
     - Type: RSA
     - Format: .pem (for Mac/Linux) or .ppk (for PuTTY/Windows)
     - **Download and save securely!**

6. **Network Settings**
   - **VPC**: Select your existing VPC
   - **Subnet**: Select a public subnet (or private with NAT gateway)
   - **Auto-assign public IP**: Enable
   - **Firewall (security group)**: Create new security group

### Security Group Configuration

**Security group name**: `jenkins-server-sg`
**Description**: Security group for Jenkins server

**Inbound Rules:**

| Type       | Protocol | Port Range | Source Type | Source          | Description        |
|------------|----------|------------|-------------|-----------------|--------------------|
| SSH        | TCP      | 22         | My IP       | Your IP         | SSH access         |
| Custom TCP | TCP      | 8080       | My IP       | Your IP         | Jenkins Web UI     |
| HTTP       | TCP      | 80         | My IP       | Your IP         | HTTP (optional)    |
| HTTPS      | TCP      | 443        | My IP       | Your IP         | HTTPS (optional)   |

**Important Security Notes:**
- Replace "My IP" with your actual IP address or company CIDR
- Never use 0.0.0.0/0 for Jenkins ports in production
- You can add more IPs later as needed

**Outbound Rules:**
- Leave default (All traffic to 0.0.0.0/0) - Jenkins needs internet access for plugins

7. **Configure Storage**
   - **Root volume**:
     - Size: **50 GB minimum**, **100 GB recommended** (for many pipelines)
     - Volume type: **gp3** (better performance and cost) or gp2
     - IOPS: 3000 (gp3 default)
     - Throughput: 125 MB/s (gp3 default)
     - Encryption: Enable (recommended)
     - Delete on termination: Your choice (disable for production)

8. **Advanced Details (Important!)**
   
   **IAM instance profile**: 
   - Create a role with permissions Jenkins needs:
     - EC2 (if using dynamic agents)
     - S3 (for artifact storage)
     - ECR (for Docker images)
     - Any other AWS services you'll use in pipelines
   
   **User data** (leave blank for now, we'll install manually)
   
   **Termination protection**: Enable for production

9. **Summary**
   - Review all settings
   - Click **Launch Instance**
   - Wait 1-2 minutes for instance to start

10. **Note your Instance Details**
    - Instance ID: ________________
    - Public IP: ________________
    - Private IP: ________________

## Part 2: Connect to Your Instance

### For Mac/Linux:

```bash
# Set proper permissions on your key
chmod 400 /path/to/jenkins-key.pem

# Connect to instance
ssh -i /path/to/jenkins-key.pem ubuntu@<PUBLIC_IP>
# For Amazon Linux: ssh -i /path/to/jenkins-key.pem ec2-user@<PUBLIC_IP>
```

### For Windows (using PuTTY):

1. Convert .pem to .ppk using PuTTYgen
2. Open PuTTY
3. Enter public IP in Host Name
4. Connection → SSH → Auth → Browse for .ppk file
5. Open connection

### Alternative: AWS Systems Manager Session Manager
- No SSH key needed
- Works with private instances
- Enable in Advanced Details when launching

## Part 3: Install Jenkins

Once connected via SSH, follow the commands for your OS:

### For Ubuntu 24.04 LTS:

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install Java (Jenkins requires Java 17 or 21)
sudo apt install fontconfig openjdk-17-jre -y

# Verify Java installation
java -version
# Should show: openjdk version "17.x.x"

# Add Jenkins repository key
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

# Add Jenkins repository
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update package index
sudo apt update

# Install Jenkins
sudo apt install jenkins -y

# Start Jenkins service
sudo systemctl start jenkins

# Enable Jenkins to start on boot
sudo systemctl enable jenkins

# Check Jenkins status
sudo systemctl status jenkins
# Should show "active (running)"
```

### For Amazon Linux 2023:

```bash
# Update system packages
sudo dnf update -y

# Install Java 17
sudo dnf install java-17-amazon-corretto -y

# Verify Java installation
java -version

# Add Jenkins repository
sudo wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/redhat-stable/jenkins.repo

# Import Jenkins GPG key
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# Install Jenkins
sudo dnf install jenkins -y

# Start Jenkins service
sudo systemctl start jenkins

# Enable Jenkins to start on boot
sudo systemctl enable jenkins

# Check Jenkins status
sudo systemctl status jenkins
```

### Common Post-Installation Steps (Both OS):

```bash
# Check if Jenkins is listening on port 8080
sudo netstat -tuln | grep 8080
# Or
sudo ss -tuln | grep 8080

# If netstat not found, install it:
# Ubuntu: sudo apt install net-tools -y
# Amazon Linux: sudo dnf install net-tools -y

# View Jenkins logs (if needed)
sudo journalctl -u jenkins -f

# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

**Save this password!** You'll need it for first login.

## Part 4: Access Jenkins Web Interface

1. Open your web browser
2. Navigate to: `http://<PUBLIC_IP>:8080`
3. You should see the "Unlock Jenkins" page

### Troubleshooting Access Issues:

**Cannot reach Jenkins?**
```bash
# Check if Jenkins is running
sudo systemctl status jenkins

# Check if port 8080 is listening
sudo netstat -tuln | grep 8080

# Check firewall (Ubuntu)
sudo ufw status
# If active and blocking, allow port 8080:
sudo ufw allow 8080/tcp

# Check Security Group in AWS Console:
# - Ensure port 8080 is open to your IP
# - Verify instance is in public subnet with internet gateway
# - Check Network ACLs aren't blocking traffic
```

## Part 5: Initial Jenkins Setup

### 1. Unlock Jenkins
- Paste the initial admin password from `/var/lib/jenkins/secrets/initialAdminPassword`
- Click **Continue**

### 2. Customize Jenkins
You'll see two options:

**Option A: Install suggested plugins (Recommended for beginners)**
- Click **Install suggested plugins**
- Wait 5-10 minutes for plugins to install
- Includes: Git, Pipeline, GitHub, Folders, etc.

**Option B: Select plugins to install (Advanced)**
- Choose specific plugins you need
- Can always add more later

### 3. Create First Admin User
- Username: (choose your username)
- Password: (strong password)
- Full name: (your name)
- Email: (your email)
- Click **Save and Continue**

### 4. Instance Configuration
- Jenkins URL: `http://<PUBLIC_IP>:8080` (or your domain if you have one)
- Click **Save and Finish**
- Click **Start using Jenkins**

## Part 6: Essential Configuration

### 1. Configure Security

**Manage Jenkins → Security → Configure Global Security**

**Security Realm:**
- Keep "Jenkins' own user database" selected
- Uncheck "Allow users to sign up" (prevent unauthorized registrations)

**Authorization:**
- Select "Matrix-based security" or "Project-based Matrix Authorization Strategy"
- For your admin user, grant all permissions
- For anonymous users, grant only "Read" (or nothing)

**CSRF Protection:**
- Ensure "Prevent Cross Site Request Forgery exploits" is checked (default)

**Agent → Controller Security:**
- Keep defaults (secure)

**Save** configuration

### 2. Install Additional Plugins

**Manage Jenkins → Plugins → Available plugins**

Search and install these plugins for AWS/Multiple Pipelines:

**Essential for AWS:**
- [ ] Amazon EC2 Plugin (dynamic build agents)
- [ ] AWS Credentials Plugin
- [ ] AWS CodeBuild
- [ ] AWS CodePipeline
- [ ] CloudBees AWS Credentials Plugin

**Pipeline Enhancement:**
- [ ] Blue Ocean (modern UI - highly recommended!)
- [ ] Pipeline: Stage View
- [ ] Pipeline: AWS Steps
- [ ] Pipeline: GitHub Groovy Libraries
- [ ] Pipeline Utility Steps

**Source Control:**
- [ ] GitHub Plugin (if using GitHub)
- [ ] Bitbucket Plugin (if using Bitbucket)
- [ ] GitLab Plugin (if using GitLab)

**Build Tools (install based on your tech stack):**
- [ ] Maven Integration Plugin
- [ ] Gradle Plugin
- [ ] NodeJS Plugin
- [ ] Docker Plugin
- [ ] Docker Pipeline

**Useful Utilities:**
- [ ] Workspace Cleanup Plugin
- [ ] Build Timeout Plugin
- [ ] Timestamper (adds timestamps to console output)
- [ ] AnsiColor (colored console output)
- [ ] Slack Notification Plugin
- [ ] Email Extension Plugin

**Click "Install" and select "Restart Jenkins when installation is complete"**

### 3. Configure System Settings

**Manage Jenkins → System**

**Jenkins Location:**
- Jenkins URL: Verify it's correct
- System Admin e-mail address: Your email

**# of executors:**
- For t3.large: Set to **2-4**
- Each executor can run one job concurrently
- Don't set too high or jobs will compete for resources

**Global properties** (if needed):
- Environment variables
- Tool locations

**Save** configuration

### 4. Configure Tools

**Manage Jenkins → Tools**

Configure the tools you'll use in your pipelines:

**JDK installations:**
- Add JDK (if not auto-detected)
- Name: `JDK-17`
- Install automatically or specify JAVA_HOME: `/usr/lib/jvm/java-17-openjdk-amd64` (Ubuntu)

**Git installations:**
- Usually auto-detected
- Name: `Default`
- Path: `git`

**Maven installations** (if using Maven):
- Add Maven
- Name: `Maven-3.9`
- Install automatically: Check, select version

**Gradle installations** (if using Gradle):
- Add Gradle
- Name: `Gradle-8`
- Install automatically: Check, select version

**NodeJS installations** (if using Node):
- Add NodeJS
- Name: `NodeJS-20`
- Install automatically: Check, select version

**Docker installations** (if using Docker):
- Add Docker
- Name: `Docker`
- Install automatically: Download from docker.com

**Save** configuration

### 5. Configure AWS Credentials

**Manage Jenkins → Credentials → System → Global credentials → Add Credentials**

**Option A: AWS Access Key (Less secure, not recommended for production)**
- Kind: AWS Credentials
- ID: `aws-credentials`
- Access Key ID: Your AWS access key
- Secret Access Key: Your AWS secret key
- Description: AWS Credentials for Jenkins

**Option B: IAM Role (Recommended - already set up via EC2 IAM role)**
- No need to add credentials if using IAM role
- Jenkins will automatically use the EC2 instance role
- Verify in AWS console: EC2 → Instances → Your instance → IAM role

## Part 7: Performance Optimization

### 1. Increase Java Heap Size

For t3.large with 8GB RAM, allocate 4GB to Jenkins:

**Ubuntu:**
```bash
sudo systemctl stop jenkins

# Edit Jenkins configuration
sudo nano /etc/default/jenkins

# Find the line with JAVA_ARGS and modify:
JAVA_ARGS="-Djava.awt.headless=true -Xms2048m -Xmx4096m"

# Save and exit (Ctrl+X, Y, Enter)

sudo systemctl start jenkins
```

**Amazon Linux:**
```bash
sudo systemctl stop jenkins

# Edit systemd service file
sudo nano /usr/lib/systemd/system/jenkins.service

# Find Environment="JAVA_OPTS=..." and modify:
Environment="JAVA_OPTS=-Djava.awt.headless=true -Xms2048m -Xmx4096m"

# Reload systemd and restart
sudo systemctl daemon-reload
sudo systemctl start jenkins
```

### 2. Configure Swap (for stability under load)

**Ubuntu/Amazon Linux:**
```bash
# Create 4GB swap file
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Verify
free -h
```

### 3. Optimize Build Discard

For each job/pipeline:
- **Pipeline → Configure → Discard old builds**
- Strategy: "Log Rotation"
- Days to keep builds: 30
- Max # of builds to keep: 20

Or globally in **Manage Jenkins → System** (if plugin available).

## Part 8: Setup Dynamic Build Agents (For Multiple Pipelines)

### Install Amazon EC2 Plugin

(Should be installed from Part 6)

### Configure EC2 Cloud

**Manage Jenkins → Clouds → New cloud**

1. **Cloud name**: `aws-ec2`
2. **Amazon EC2 Credentials**: Select your AWS credentials or use IAM role
3. **Region**: Select your region (e.g., us-east-1)
4. **EC2 Key Pair's Private Key**: Paste your private key (or use credentials)

**Click "Add a new cloud" → Select "Amazon EC2"**

### Add AMI (Agent Template)

1. Click **Add** under "AMIs"
2. **AMI ID**: 
   - Ubuntu: Use AWS Marketplace Ubuntu AMI with Java pre-installed
   - Or use base Ubuntu and install Java via init script
   - Quick: `ami-0c55b159cbfafe1f0` (Ubuntu 22.04 in us-east-1, verify current)
3. **Instance Type**: t3.small or t3.medium
4. **Security group names**: `jenkins-agent-sg` (create in AWS first with port 22 open to Jenkins server)
5. **Remote FS root**: `/home/ubuntu/jenkins`
6. **Remote user**: `ubuntu` (or `ec2-user` for Amazon Linux)
7. **AMI Type**: `unix`
8. **Labels**: `linux docker` (use in pipeline: agent { label 'linux' })
9. **Usage**: "Only build jobs with label expressions matching this node"
10. **Idle termination time**: 30 (minutes)
11. **Init script**: (if Java not pre-installed)
    ```bash
    #!/bin/bash
    sudo apt update
    sudo apt install -y openjdk-17-jre git
    ```
12. **Number of Executors**: 2
13. **Stop/Disconnect on Idle Timeout**: Check

**Test connection** and **Save**

### Create Security Group for Agents

In AWS Console:
1. **EC2 → Security Groups → Create security group**
2. **Name**: `jenkins-agent-sg`
3. **VPC**: Same as Jenkins server
4. **Inbound rules**:
   - Type: SSH, Port: 22, Source: Security group of Jenkins server
5. **Outbound rules**: All traffic to 0.0.0.0/0
6. **Create**

## Part 9: Backup Strategy

### Method 1: EBS Snapshots (Recommended)

**Manual Snapshot:**
1. EC2 → Volumes → Select root volume → Actions → Create snapshot
2. Name: `jenkins-backup-YYYY-MM-DD`

**Automated Snapshots:**
1. **AWS Backup → Create backup plan**
2. Configure daily/weekly snapshots
3. Retention: 30 days or as needed

### Method 2: Jenkins ThinBackup Plugin

**Install ThinBackup Plugin:**
1. **Manage Jenkins → Plugins → Available** → Search "ThinBackup"
2. Install and restart

**Configure ThinBackup:**
1. **Manage Jenkins → ThinBackup → Settings**
2. **Backup directory**: `/var/backups/jenkins`
3. **Backup schedule**: `0 2 * * *` (daily at 2 AM)
4. **Full backup schedule**: `0 2 * * 0` (weekly on Sunday)
5. **Keep backups**: 30 days

**Create backup directory:**
```bash
sudo mkdir -p /var/backups/jenkins
sudo chown jenkins:jenkins /var/backups/jenkins
```

### Method 3: S3 Sync Script

```bash
#!/bin/bash
# Create file: /usr/local/bin/jenkins-backup.sh

BACKUP_DIR="/var/lib/jenkins"
S3_BUCKET="s3://your-jenkins-backup-bucket"
DATE=$(date +%Y%m%d)

# Stop Jenkins (optional, for consistent backup)
# sudo systemctl stop jenkins

# Sync to S3
aws s3 sync $BACKUP_DIR $S3_BUCKET/jenkins-$DATE/ \
    --exclude "workspace/*" \
    --exclude "logs/*" \
    --exclude "*.log"

# Start Jenkins
# sudo systemctl start jenkins

echo "Backup completed to $S3_BUCKET/jenkins-$DATE/"
```

**Make executable and schedule:**
```bash
sudo chmod +x /usr/local/bin/jenkins-backup.sh

# Add to crontab
sudo crontab -e
# Add line:
0 3 * * * /usr/local/bin/jenkins-backup.sh >> /var/log/jenkins-backup.log 2>&1
```

## Part 10: Monitoring and Alerting

### CloudWatch Monitoring

**Enable detailed monitoring:**
1. EC2 Console → Select instance
2. Actions → Monitor and troubleshoot → Manage detailed monitoring → Enable

**Create CloudWatch Alarms:**

1. **High CPU Alert**
   - Metric: CPUUtilization
   - Threshold: > 80% for 5 minutes
   - Action: SNS notification

2. **Low Disk Space Alert**
   - Metric: disk_used_percent (requires CloudWatch agent)
   - Threshold: > 80%
   - Action: SNS notification

### Install CloudWatch Agent (for disk metrics)

```bash
# Download CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
# For Amazon Linux: Use .rpm

# Install
sudo dpkg -i amazon-cloudwatch-agent.deb
# For Amazon Linux: sudo rpm -i amazon-cloudwatch-agent.rpm

# Configure (wizard)
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard

# Start agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json
```

### Jenkins Monitoring Plugin

**Install Monitoring Plugin:**
1. **Manage Jenkins → Plugins** → Search "Monitoring"
2. Install "Monitoring" plugin
3. Access at: **Manage Jenkins → Monitoring**

Shows:
- Memory usage
- CPU usage
- Thread count
- HTTP sessions
- Build queue

## Part 11: SSL/HTTPS Setup (Optional but Recommended)

### Option A: Nginx Reverse Proxy with Let's Encrypt

**Install Nginx:**
```bash
# Ubuntu
sudo apt install nginx certbot python3-certbot-nginx -y

# Amazon Linux
sudo dnf install nginx certbot python3-certbot-nginx -y
```

**Configure Nginx:**
```bash
sudo nano /etc/nginx/sites-available/jenkins
```

Add:
```nginx
upstream jenkins {
    server 127.0.0.1:8080 fail_timeout=0;
}

server {
    listen 80;
    server_name jenkins.yourdomain.com;  # Replace with your domain

    location / {
        proxy_pass http://jenkins;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Increase timeout for long-running builds
        proxy_read_timeout 90;
    }
}
```

**Enable site:**
```bash
sudo ln -s /etc/nginx/sites-available/jenkins /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

**Get SSL Certificate:**
```bash
sudo certbot --nginx -d jenkins.yourdomain.com
```

**Update Security Group:**
- Add HTTP (80) and HTTPS (443) to inbound rules
- Can remove port 8080 from external access

**Configure Jenkins URL:**
- **Manage Jenkins → System → Jenkins Location**
- Jenkins URL: `https://jenkins.yourdomain.com`

### Option B: Application Load Balancer with ACM

1. Create Application Load Balancer
2. Request certificate in ACM
3. Configure ALB to terminate SSL
4. Target group pointing to Jenkins EC2 instance:8080
5. Update Security Group to allow ALB traffic

## Part 12: First Pipeline Job

### Create a Test Pipeline

1. **Dashboard → New Item**
2. **Name**: `test-pipeline`
3. **Type**: Pipeline
4. **OK**

5. **Pipeline script:**
```groovy
pipeline {
    agent any
    
    stages {
        stage('Hello') {
            steps {
                echo 'Hello from Jenkins on EC2!'
                sh 'echo "Current date: $(date)"'
                sh 'echo "Jenkins running on: $(hostname)"'
            }
        }
        
        stage('System Info') {
            steps {
                sh 'uname -a'
                sh 'java -version'
                sh 'free -h'
                sh 'df -h'
            }
        }
        
        stage('Test AWS CLI') {
            steps {
                sh 'aws --version'
                sh 'aws sts get-caller-identity || echo "No AWS credentials/role configured"'
            }
        }
    }
    
    post {
        always {
            echo 'Pipeline completed!'
        }
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
```

6. **Save** and **Build Now**
7. Check **Console Output** to verify everything works

### Connect to Git Repository

**Install Git (if not already):**
```bash
# On Jenkins server
sudo apt install git -y  # Ubuntu
sudo dnf install git -y  # Amazon Linux
```

**Create Pipeline from SCM:**
1. **New Item → Pipeline**
2. **Pipeline Definition**: Pipeline script from SCM
3. **SCM**: Git
4. **Repository URL**: Your Git repo URL
5. **Credentials**: Add Git credentials if private repo
6. **Branch**: `*/main` or `*/master`
7. **Script Path**: `Jenkinsfile`
8. **Save**

## Part 13: Maintenance and Operations

### Regular Maintenance Tasks

**Weekly:**
```bash
# Check disk space
df -h
du -sh /var/lib/jenkins/*

# Check Jenkins logs for errors
sudo journalctl -u jenkins --since "7 days ago" | grep -i error

# Verify backups
aws s3 ls s3://your-backup-bucket/
```

**Monthly:**
- Update plugins (test in non-prod first!)
- Review and archive old builds
- Check security advisories
- Update Java if needed
- Review IAM permissions

**Quarterly:**
- Update Jenkins core version
- Test disaster recovery
- Review and optimize pipelines
- Audit user access

### Useful Management Commands

```bash
# Check Jenkins status
sudo systemctl status jenkins

# Start/Stop/Restart Jenkins
sudo systemctl start jenkins
sudo systemctl stop jenkins
sudo systemctl restart jenkins

# View real-time logs
sudo journalctl -u jenkins -f

# Check Jenkins configuration
sudo cat /etc/default/jenkins  # Ubuntu
sudo cat /usr/lib/systemd/system/jenkins.service  # Amazon Linux

# Jenkins CLI (from Jenkins server)
java -jar /var/lib/jenkins/war/WEB-INF/jenkins-cli.jar -s http://localhost:8080/ -auth admin:password help

# Reload configuration without restart
curl -X POST http://localhost:8080/reload -u admin:password
```

### Disaster Recovery Procedure

**Restore from EBS Snapshot:**
1. Create new volume from snapshot
2. Attach to new EC2 instance (or stop current, detach, attach new)
3. Mount volume
4. Start Jenkins

**Restore from S3 Backup:**
```bash
# Stop Jenkins
sudo systemctl stop jenkins

# Restore files
aws s3 sync s3://your-backup-bucket/jenkins-YYYYMMDD/ /var/lib/jenkins/

# Fix permissions
sudo chown -R jenkins:jenkins /var/lib/jenkins

# Start Jenkins
sudo systemctl start jenkins
```

## Part 14: Security Hardening Checklist

- [ ] Changed default admin password
- [ ] Disabled anonymous access
- [ ] Security Group restricted to known IPs only
- [ ] Enabled CSRF protection
- [ ] Regular security updates scheduled
- [ ] SSL/TLS enabled (for production)
- [ ] Audit logging enabled
- [ ] Secrets management (not hardcoded in pipelines)
- [ ] IAM roles instead of access keys where possible
- [ ] Backup and tested restore procedure
- [ ] Termination protection enabled
- [ ] Root volume encrypted
- [ ] No unnecessary plugins installed
- [ ] Regular security scans

## Part 15: Cost Optimization

**EC2 Cost Estimates (us-east-1, monthly):**

| Instance Type | On-Demand | 1-Yr Reserved | 3-Yr Reserved |
|---------------|-----------|---------------|---------------|
| t3.medium     | $30       | $18           | $12           |
| t3.large      | $60       | $36           | $24           |
| t3.xlarge     | $120      | $72           | $48           |
| m5.large      | $70       | $42           | $28           |

**Additional Costs:**
- EBS (50GB gp3): ~$4/month
- Data transfer: First 100GB free, then $0.09/GB
- Dynamic agents: Cost when running (can be spot instances)
- Backups: EBS snapshots ~$0.05/GB-month

**Cost Optimization Tips:**
1. Use Reserved Instances for main Jenkins server (30-50% savings)
2. Use Spot Instances for build agents (up to 90% savings)
3. Schedule Jenkins to stop during off-hours (if not 24/7)
4. Clean up old builds and artifacts regularly
5. Use S3 lifecycle policies for old backups
6. Right-size instance (start small, scale up if needed)
7. Use gp3 volumes instead of gp2
8. Enable CloudWatch detailed monitoring only if needed

## Troubleshooting Common Issues

### Jenkins won't start
```bash
# Check logs
sudo journalctl -u jenkins -n 50

# Common causes:
# - Out of disk space: df -h
# - Port 8080 already in use: sudo lsof -i :8080
# - Java not found: java -version
# - Permission issues: sudo chown -R jenkins:jenkins /var/lib/jenkins
```

### Can't access Jenkins web interface
```bash
# Verify Jenkins is running
sudo systemctl status jenkins

# Check if listening on 8080
sudo netstat -tuln | grep 8080

# Check Security Group in AWS Console
# Check instance has public IP
# Try from instance: curl http://localhost:8080
```

### Out of disk space
```bash
# Check usage
df -h
du -sh /var/lib/jenkins/*

# Clean up
# 1. Delete old builds (in Jenkins UI or manually)
sudo find /var/lib/jenkins/jobs/*/builds/* -mtime +30 -exec rm -rf {} \;

# 2. Clean workspace
sudo rm -rf /var/lib/jenkins/workspace/*

# 3. Increase EBS volume size in AWS Console, then:
sudo growpart /dev/xvda 1
sudo resize2fs /dev/xvda1  # For ext4
# Or: sudo xfs_growfs -d /  # For xfs
```

### Plugins won't install
```bash
# Check internet connectivity
ping google.com

# Check Jenkins update center
# Manage Jenkins → Manage Plugins → Advanced
# Update Site URL: https://updates.jenkins.io/update-center.json

# Manual plugin install:
# 1. Download .hpi file from https://updates.jenkins.io/download/plugins/
# 2. Manage Jenkins → Manage Plugins → Advanced → Upload Plugin
```

### Performance issues
```bash
# Check resources
top
free -h
df -h

# Increase Java heap (see Part 7)
# Reduce concurrent executors
# Add more agents
# Upgrade instance size
```

## Quick Reference Commands

```bash
# Jenkins service management
sudo systemctl status jenkins
sudo systemctl start jenkins
sudo systemctl stop jenkins
sudo systemctl restart jenkins

# View logs
sudo journalctl -u jenkins -f
sudo tail -f /var/log/jenkins/jenkins.log

# Jenkins directories
/var/lib/jenkins          # Jenkins home
/var/lib/jenkins/jobs     # Job configurations
/var/lib/jenkins/workspace # Build workspaces
/var/log/jenkins          # Logs

# Get initial password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# Backup
sudo tar -czf jenkins-backup-$(date +%Y%m%d).tar.gz /var/lib/jenkins

# Disk cleanup
sudo du -sh /var/lib/jenkins/* | sort -hr | head -10
```

## Next Steps

1. ✅ Jenkins installed and running
2. ✅ Basic security configured
3. ✅ Essential plugins installed
4. ⬜ Create your first real pipeline
5. ⬜ Set up Git webhooks for automatic builds
6. ⬜ Configure build agents for parallel execution
7. ⬜ Set up notifications (Slack, email)
8. ⬜ Implement proper secrets management
9. ⬜ Create backup and restore procedures
10. ⬜ Document your Jenkins setup

## Additional Resources

- Jenkins Documentation: https://www.jenkins.io/doc/
- Jenkins Pipeline Syntax: https://www.jenkins.io/doc/book/pipeline/syntax/
- AWS EC2 Documentation: https://docs.aws.amazon.com/ec2/
- Jenkins Community: https://community.jenkins.io/
- Jenkins Plugins: https://plugins.jenkins.io/

---

**Need Help?**
- Check Jenkins logs: `sudo journalctl -u jenkins -f`
- Jenkins Community Forums
- Stack Overflow: [jenkins] tag
- AWS Support (for infrastructure issues)