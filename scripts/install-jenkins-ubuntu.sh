#!/bin/bash

################################################################################
# Jenkins Installation Script for Ubuntu 24.04 LTS
# Usage: sudo ./install-jenkins-ubuntu.sh
################################################################################

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if script is run as root
check_root() {
    if [ "$EUID" -ne 0 ]; then 
        print_error "Please run as root (use sudo)"
        exit 1
    fi
}

# Function to check OS
check_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
        print_info "Detected OS: $OS $VER"
        
        if [[ "$OS" != "Ubuntu" ]]; then
            print_error "This script is designed for Ubuntu. Use install-jenkins-amazonlinux.sh for Amazon Linux."
            exit 1
        fi
    else
        print_error "Cannot detect OS"
        exit 1
    fi
}

# Function to update system
update_system() {
    print_info "Updating system packages..."
    apt update
    apt upgrade -y
    print_info "System updated successfully"
}

# Function to install Java
install_java() {
    print_info "Installing Java 17..."
    apt install -y fontconfig openjdk-17-jre
    
    # Verify installation
    java -version
    print_info "Java installed successfully"
}

# Function to add Jenkins repository
add_jenkins_repo() {
    print_info "Adding Jenkins repository..."
    
    # Download Jenkins GPG key
    wget -O /usr/share/keyrings/jenkins-keyring.asc \
        https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
    
    # Add Jenkins repository
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
        https://pkg.jenkins.io/debian-stable binary/ | \
        tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    
    # Update package index
    apt update
    
    print_info "Jenkins repository added successfully"
}

# Function to install Jenkins
install_jenkins() {
    print_info "Installing Jenkins..."
    apt install -y jenkins
    print_info "Jenkins installed successfully"
}

# Function to start and enable Jenkins
start_jenkins() {
    print_info "Starting Jenkins service..."
    systemctl start jenkins
    systemctl enable jenkins
    
    # Wait for Jenkins to start
    sleep 10
    
    # Check status
    if systemctl is-active --quiet jenkins; then
        print_info "Jenkins is running"
    else
        print_error "Jenkins failed to start"
        systemctl status jenkins
        exit 1
    fi
}

# Function to configure Java heap size
configure_heap() {
    print_info "Configuring Java heap size..."
    
    # Get total RAM in MB
    TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
    
    # Set heap to 50% of RAM (minimum 2GB, maximum 8GB)
    HEAP_SIZE=$((TOTAL_RAM / 2))
    if [ $HEAP_SIZE -lt 2048 ]; then
        HEAP_SIZE=2048
    elif [ $HEAP_SIZE -gt 8192 ]; then
        HEAP_SIZE=8192
    fi
    
    MIN_HEAP=$((HEAP_SIZE / 2))
    
    print_info "Setting heap size: -Xms${MIN_HEAP}m -Xmx${HEAP_SIZE}m"
    
    # Backup original file
    if [ ! -f /etc/default/jenkins.backup ]; then
        cp /etc/default/jenkins /etc/default/jenkins.backup
    fi
    
    # Update JAVA_ARGS
    if grep -q "^JAVA_ARGS=" /etc/default/jenkins; then
        sed -i "s|^JAVA_ARGS=.*|JAVA_ARGS=\"-Djava.awt.headless=true -Xms${MIN_HEAP}m -Xmx${HEAP_SIZE}m\"|" /etc/default/jenkins
    else
        echo "JAVA_ARGS=\"-Djava.awt.headless=true -Xms${MIN_HEAP}m -Xmx${HEAP_SIZE}m\"" >> /etc/default/jenkins
    fi
    
    print_info "Heap size configured"
}

# Function to configure swap
configure_swap() {
    print_info "Checking swap configuration..."
    
    # Check if swap already exists
    if swapon --show | grep -q '/swapfile'; then
        print_warning "Swap already configured, skipping..."
        return
    fi
    
    # Get total RAM in GB
    TOTAL_RAM_GB=$(free -g | awk '/^Mem:/{print $2}')
    
    # Set swap size (equal to RAM, max 4GB for this script)
    SWAP_SIZE=$TOTAL_RAM_GB
    if [ $SWAP_SIZE -gt 4 ]; then
        SWAP_SIZE=4
    fi
    if [ $SWAP_SIZE -lt 2 ]; then
        SWAP_SIZE=2
    fi
    
    print_info "Creating ${SWAP_SIZE}GB swap file..."
    
    # Create swap file
    fallocate -l ${SWAP_SIZE}G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    
    # Make permanent
    if ! grep -q '/swapfile' /etc/fstab; then
        echo '/swapfile none swap sw 0 0' >> /etc/fstab
    fi
    
    print_info "Swap configured successfully"
}

# Function to install useful tools
install_tools() {
    print_info "Installing additional tools..."
    apt install -y \
        git \
        curl \
        wget \
        net-tools \
        htop \
        unzip \
        awscli
    print_info "Additional tools installed"
}

# Function to configure firewall (UFW)
configure_firewall() {
    print_info "Checking firewall configuration..."
    
    if command -v ufw &> /dev/null; then
        if ufw status | grep -q "Status: active"; then
            print_warning "UFW is active. Ensure port 8080 is allowed."
            print_info "Run: sudo ufw allow 8080/tcp"
        else
            print_info "UFW is installed but not active"
        fi
    else
        print_info "UFW not installed, skipping firewall configuration"
    fi
}

# Function to get initial admin password
get_admin_password() {
    print_info "Retrieving initial admin password..."
    
    # Wait for password file to be created
    COUNTER=0
    while [ ! -f /var/lib/jenkins/secrets/initialAdminPassword ] && [ $COUNTER -lt 30 ]; do
        sleep 2
        COUNTER=$((COUNTER + 1))
    done
    
    if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
        ADMIN_PASSWORD=$(cat /var/lib/jenkins/secrets/initialAdminPassword)
        echo ""
        echo "========================================"
        echo "JENKINS INITIAL ADMIN PASSWORD:"
        echo "$ADMIN_PASSWORD"
        echo "========================================"
        echo ""
        echo "Save this password! You'll need it for first login."
        echo ""
    else
        print_warning "Could not retrieve initial admin password"
        print_info "Check: sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
    fi
}

# Function to display access information
display_info() {
    # Get public IP
    PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "Unable to retrieve")
    PRIVATE_IP=$(hostname -I | awk '{print $1}')
    
    echo ""
    echo "=========================================="
    echo "JENKINS INSTALLATION COMPLETE!"
    echo "=========================================="
    echo ""
    echo "Access Jenkins at:"
    echo "  http://$PUBLIC_IP:8080"
    echo "  http://$PRIVATE_IP:8080"
    echo ""
    echo "Instance Information:"
    echo "  Public IP:  $PUBLIC_IP"
    echo "  Private IP: $PRIVATE_IP"
    echo ""
    echo "Jenkins Details:"
    echo "  Jenkins Home: /var/lib/jenkins"
    echo "  Jenkins Logs: /var/log/jenkins/jenkins.log"
    echo "  Config File:  /etc/default/jenkins"
    echo ""
    echo "Useful Commands:"
    echo "  Check status:  sudo systemctl status jenkins"
    echo "  Restart:       sudo systemctl restart jenkins"
    echo "  View logs:     sudo journalctl -u jenkins -f"
    echo "  Get password:  sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
    echo ""
    echo "Next Steps:"
    echo "  1. Open http://$PUBLIC_IP:8080 in your browser"
    echo "  2. Use the initial admin password above"
    echo "  3. Install suggested plugins"
    echo "  4. Create your admin user"
    echo "  5. Start creating pipelines!"
    echo ""
    echo "=========================================="
    echo ""
}

# Function to create backup script
create_backup_script() {
    print_info "Creating backup script..."
    
    cat > /usr/local/bin/jenkins-backup.sh << 'EOF'
#!/bin/bash
# Jenkins Backup Script
BACKUP_DIR="/backup/jenkins"
DATE=$(date +%Y%m%d_%H%M%S)
JENKINS_HOME="/var/lib/jenkins"

mkdir -p $BACKUP_DIR

# Stop Jenkins (optional - for consistent backup)
# systemctl stop jenkins

# Create backup
tar -czf $BACKUP_DIR/jenkins-backup-$DATE.tar.gz \
    --exclude="$JENKINS_HOME/workspace/*" \
    --exclude="$JENKINS_HOME/.cache/*" \
    --exclude="$JENKINS_HOME/logs/*" \
    $JENKINS_HOME

# Start Jenkins
# systemctl start jenkins

# Keep only last 7 backups
cd $BACKUP_DIR
ls -t jenkins-backup-*.tar.gz | tail -n +8 | xargs rm -f

echo "Backup completed: $BACKUP_DIR/jenkins-backup-$DATE.tar.gz"
EOF
    
    chmod +x /usr/local/bin/jenkins-backup.sh
    mkdir -p /backup/jenkins
    
    print_info "Backup script created at /usr/local/bin/jenkins-backup.sh"
    print_info "Run manually: sudo /usr/local/bin/jenkins-backup.sh"
    print_info "Or add to crontab: 0 2 * * * /usr/local/bin/jenkins-backup.sh"
}

# Main installation function
main() {
    print_info "Starting Jenkins installation..."
    echo ""
    
    check_root
    check_os
    update_system
    install_java
    add_jenkins_repo
    install_jenkins
    configure_heap
    start_jenkins
    configure_swap
    install_tools
    configure_firewall
    create_backup_script
    get_admin_password
    display_info
    
    print_info "Installation script completed successfully!"
}

# Run main function
main

exit 0
