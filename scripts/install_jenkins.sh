#!/bin/bash

################################################################################
# Jenkins Installation Script for Ubuntu/Debian
# This script installs Jenkins CI/CD server with full error handling
# Author: Auto-generated
# Date: 2025-11-04
################################################################################

set -e  # Exit on any error
set -u  # Exit on undefined variables

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_step() {
    echo -e "\n${BLUE}==>${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if running as root or with sudo
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "This script must be run as root or with sudo"
        echo "Please run: sudo $0"
        exit 1
    fi
}

# Function to check OS compatibility
check_os() {
    print_step "Checking operating system compatibility..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
        
        if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
            print_success "OS detected: $PRETTY_NAME"
            return 0
        else
            print_warning "This script is designed for Ubuntu/Debian"
            print_warning "Your OS: $PRETTY_NAME"
            read -p "Do you want to continue anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
    else
        print_error "Cannot detect operating system"
        exit 1
    fi
}

# Function to install Java
install_java() {
    print_step "Checking Java installation..."
    
    if command_exists java; then
        JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
        print_success "Java is already installed: $JAVA_VERSION"
    else
        print_info "Java not found. Installing OpenJDK 17..."
        
        if apt-get update -qq; then
            print_success "Package lists updated"
        else
            print_error "Failed to update package lists"
            exit 1
        fi
        
        if apt-get install -y openjdk-17-jdk; then
            JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
            print_success "Java installed successfully: $JAVA_VERSION"
        else
            print_error "Failed to install Java"
            exit 1
        fi
    fi
}

# Function to add Jenkins repository
add_jenkins_repo() {
    print_step "Adding Jenkins repository..."
    
    # Install prerequisites
    print_info "Installing prerequisites (curl, gnupg)..."
    if apt-get install -y curl gnupg; then
        print_success "Prerequisites installed"
    else
        print_error "Failed to install prerequisites"
        exit 1
    fi
    
    # Create keyrings directory if it doesn't exist
    mkdir -p /usr/share/keyrings
    
    # Download and add Jenkins GPG key
    print_info "Downloading Jenkins GPG key..."
    if curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | \
       tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null; then
        print_success "Jenkins GPG key added"
    else
        print_error "Failed to download Jenkins GPG key"
        exit 1
    fi
    
    # Add Jenkins repository to sources list
    print_info "Adding Jenkins repository to sources list..."
    echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
https://pkg.jenkins.io/debian-stable binary/" | \
    tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    
    if [ -f /etc/apt/sources.list.d/jenkins.list ]; then
        print_success "Jenkins repository added successfully"
    else
        print_error "Failed to add Jenkins repository"
        exit 1
    fi
}

# Function to install Jenkins
install_jenkins() {
    print_step "Installing Jenkins..."
    
    # Update package lists
    print_info "Updating package lists..."
    if apt-get update -qq; then
        print_success "Package lists updated"
    else
        print_error "Failed to update package lists"
        exit 1
    fi
    
    # Install Jenkins
    print_info "Installing Jenkins package..."
    if apt-get install -y jenkins; then
        print_success "Jenkins installed successfully"
    else
        print_error "Failed to install Jenkins"
        exit 1
    fi
}

# Function to start and enable Jenkins service
start_jenkins() {
    print_step "Starting Jenkins service..."
    
    # Start Jenkins
    if systemctl start jenkins; then
        print_success "Jenkins service started"
    else
        print_error "Failed to start Jenkins service"
        exit 1
    fi
    
    # Enable Jenkins to start on boot
    print_info "Enabling Jenkins to start on boot..."
    if systemctl enable jenkins; then
        print_success "Jenkins enabled for auto-start"
    else
        print_warning "Failed to enable Jenkins auto-start"
    fi
    
    # Check Jenkins status
    print_info "Checking Jenkins status..."
    sleep 3
    
    if systemctl is-active --quiet jenkins; then
        print_success "Jenkins is running"
    else
        print_error "Jenkins is not running"
        systemctl status jenkins --no-pager
        exit 1
    fi
}

# Function to configure firewall (if UFW is active)
configure_firewall() {
    print_step "Checking firewall configuration..."
    
    if command_exists ufw; then
        if ufw status | grep -q "Status: active"; then
            print_info "UFW firewall is active. Opening port 8080..."
            if ufw allow 8080/tcp; then
                print_success "Port 8080 opened in firewall"
            else
                print_warning "Failed to open port 8080 in firewall"
            fi
        else
            print_info "UFW firewall is not active. Skipping firewall configuration."
        fi
    else
        print_info "UFW not installed. Skipping firewall configuration."
    fi
}

# Function to get initial admin password
get_admin_password() {
    print_step "Retrieving initial admin password..."
    
    # Wait for Jenkins to fully start and create the password file
    local max_attempts=30
    local attempt=0
    
    print_info "Waiting for Jenkins to initialize..."
    
    while [ $attempt -lt $max_attempts ]; do
        if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
            print_success "Jenkins initialization complete"
            break
        fi
        sleep 2
        attempt=$((attempt + 1))
        echo -n "."
    done
    echo
    
    if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
        ADMIN_PASSWORD=$(cat /var/lib/jenkins/secrets/initialAdminPassword)
        echo
        print_success "Jenkins installation completed successfully!"
        echo
        print_info "======================================"
        print_info "Jenkins Access Information"
        print_info "======================================"
        echo -e "${GREEN}URL:${NC} http://localhost:8080"
        echo -e "${GREEN}Initial Admin Password:${NC} $ADMIN_PASSWORD"
        print_info "======================================"
        echo
        print_info "Next steps:"
        echo "  1. Open http://localhost:8080 in your browser"
        echo "  2. Enter the initial admin password above"
        echo "  3. Install suggested plugins"
        echo "  4. Create your first admin user"
        echo
    else
        print_warning "Could not retrieve initial admin password"
        print_info "You can get it manually by running:"
        echo "  sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
    fi
}

# Function to display system information
display_system_info() {
    print_step "System Information"
    echo -e "${BLUE}Jenkins Version:${NC} $(jenkins --version 2>/dev/null || echo 'Unknown')"
    echo -e "${BLUE}Java Version:${NC} $(java -version 2>&1 | head -n 1 | cut -d'"' -f2)"
    echo -e "${BLUE}Jenkins Home:${NC} /var/lib/jenkins"
    echo -e "${BLUE}Jenkins Log:${NC} /var/log/jenkins/jenkins.log"
    echo -e "${BLUE}Service Status:${NC} $(systemctl is-active jenkins)"
}

################################################################################
# Main Script Execution
################################################################################

main() {
    echo "=================================="
    echo "  Jenkins Installation Script"
    echo "=================================="
    echo
    
    # Pre-flight checks
    check_root
    check_os
    
    # Installation steps
    install_java
    add_jenkins_repo
    install_jenkins
    start_jenkins
    configure_firewall
    get_admin_password
    
    # Display system information
    echo
    display_system_info
    
    echo
    print_success "Installation complete! 🎉"
}

# Trap errors
trap 'print_error "An error occurred. Installation failed."; exit 1' ERR

# Run main function
main "$@"
