#!/bin/bash
# Redis CLI Installation Script
# Works on Mac and Linux
# For Windows, use install-redis-cli-windows.ps1

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo -e "${CYAN}================================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}================================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ ERROR: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ WARNING: $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="mac"
        print_info "Detected: macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        print_info "Detected: Linux"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ -n "$WSL_DISTRO_NAME" ]]; then
        print_error "Windows detected. Please use the PowerShell script instead."
        echo ""
        echo -e "${CYAN}For Windows installation, run:${NC}"
        echo "  cd scripts"
        echo "  .\\install-redis-cli-windows.ps1"
        echo ""
        exit 1
    else
        print_error "Unsupported OS: $OSTYPE"
        exit 1
    fi
    echo ""
}

# Check if redis-cli is already installed
check_existing() {
    if command -v redis-cli &> /dev/null; then
        print_success "redis-cli is already installed!"
        echo ""
        VERSION=$(redis-cli --version)
        echo -e "${CYAN}Installed version: ${NC}$VERSION"
        echo ""
        read -p "Do you want to reinstall? (y/n): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo ""
            print_info "Installation cancelled. redis-cli is already available."
            exit 0
        fi
        echo ""
    fi
}

# Install on Mac
install_mac() {
    print_header "Installing redis-cli on macOS"

    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        print_warning "Homebrew is not installed"
        echo ""
        echo -e "${YELLOW}Installing Homebrew...${NC}"
        echo ""

        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        if [ $? -eq 0 ]; then
            print_success "Homebrew installed successfully"
            echo ""
        else
            print_error "Failed to install Homebrew"
            echo ""
            echo "Please install Homebrew manually:"
            echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            exit 1
        fi
    else
        print_success "Homebrew is already installed"
        echo ""
    fi

    # Install Redis (includes redis-cli)
    echo -e "${YELLOW}Installing Redis via Homebrew...${NC}"
    echo ""

    brew install redis

    if [ $? -eq 0 ]; then
        print_success "Redis installed successfully!"
    else
        print_error "Failed to install Redis"
        exit 1
    fi
}

# Install on Linux
install_linux() {
    print_header "Installing redis-cli on Linux"

    # Detect Linux distribution
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    else
        print_error "Cannot detect Linux distribution"
        exit 1
    fi

    echo -e "${BLUE}Distribution: ${NC}$DISTRO"
    echo ""

    case $DISTRO in
        ubuntu|debian)
            echo -e "${YELLOW}Installing redis-tools via apt...${NC}"
            echo ""

            sudo apt-get update
            sudo apt-get install -y redis-tools

            if [ $? -eq 0 ]; then
                print_success "redis-tools installed successfully!"
            else
                print_error "Failed to install redis-tools"
                exit 1
            fi
            ;;

        fedora|rhel|centos)
            echo -e "${YELLOW}Installing redis via yum/dnf...${NC}"
            echo ""

            if command -v dnf &> /dev/null; then
                sudo dnf install -y redis
            else
                sudo yum install -y redis
            fi

            if [ $? -eq 0 ]; then
                print_success "Redis installed successfully!"
            else
                print_error "Failed to install Redis"
                exit 1
            fi
            ;;

        arch|manjaro)
            echo -e "${YELLOW}Installing redis via pacman...${NC}"
            echo ""

            sudo pacman -Sy --noconfirm redis

            if [ $? -eq 0 ]; then
                print_success "Redis installed successfully!"
            else
                print_error "Failed to install Redis"
                exit 1
            fi
            ;;

        *)
            print_error "Unsupported Linux distribution: $DISTRO"
            echo ""
            echo "Please install redis-tools manually:"
            echo "  Debian/Ubuntu: sudo apt-get install redis-tools"
            echo "  Fedora/RHEL:   sudo dnf install redis"
            echo "  Arch:          sudo pacman -S redis"
            exit 1
            ;;
    esac
}


# Verify installation
verify_installation() {
    print_header "Verifying Installation"

    if command -v redis-cli &> /dev/null; then
        print_success "redis-cli is installed and in PATH!"
        echo ""

        VERSION=$(redis-cli --version)
        echo -e "${CYAN}Version: ${NC}$VERSION"
        echo ""

        print_header "Quick Start"
        echo -e "${CYAN}Test redis-cli:${NC}"
        echo "  redis-cli --version"
        echo ""
        echo -e "${CYAN}Connect to local Redis:${NC}"
        echo "  redis-cli -h localhost -p 6379 PING"
        echo ""
        echo -e "${CYAN}Connect to remote Redis:${NC}"
        echo "  redis-cli -h hostname -p port"
        echo ""
        echo -e "${CYAN}Interactive mode:${NC}"
        echo "  redis-cli"
        echo ""

        print_success "Installation complete!"

    else
        print_error "redis-cli is not in PATH"
        echo ""
        echo "You may need to:"
        echo "  - Restart your terminal"
        echo "  - Add Redis to your PATH manually"
        echo "  - Source your shell configuration: source ~/.bashrc or source ~/.zshrc"
        exit 1
    fi
}

# Main installation flow
main() {
    print_header "Redis CLI Installation Script"

    # Detect OS
    detect_os

    # Check if already installed
    check_existing

    # Install based on OS
    case $OS in
        mac)
            install_mac
            ;;
        linux)
            install_linux
            ;;
        *)
            print_error "Unsupported operating system"
            exit 1
            ;;
    esac

    echo ""

    # Verify installation
    verify_installation
}

# Run main function
main
