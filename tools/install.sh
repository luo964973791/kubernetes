#!/bin/bash
# @Time    : 2025/7/18 09:35
# @Author  : Leo Luo
# @File    : install.sh
# @Software: cursor

print_green() {
    echo -e "\e[01;32m$(date "+%Y-%m-%d %H:%M:%S") [INFO] $*\e[01;00m"
}

print_red() {
    echo -e "\e[01;31m$(date "+%Y-%m-%d %H:%M:%S") [ERROR] $*\e[01;00m"
    exit 1
}

print_yellow() {
    echo -e "\e[01;33m$(date "+%Y-%m-%d %H:%M:%S") [Warning] $*\e[01;00m"
}

print_green "Installing Kubernetes scripts and aliases..."

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_red "Please run this script as root (use sudo)"
fi

# Create .kube_scripts directory if it doesn't exist
if [ ! -d "/root/.kube_scripts" ]; then
    print_yellow "Creating /root/.kube_scripts directory..."
    mkdir -p /root/.kube_scripts
fi

# Copy all script files to .kube_scripts directory
print_yellow "Copying script files to /root/.kube_scripts..."
cp ./*.sh /root/.kube_scripts/
chmod +x /root/.kube_scripts/*.sh

# Define the aliases to check and add
declare -A aliases=(
    ["kdescribe"]="$HOME/.kube_scripts/kube_describe.sh"
    ["kexec"]="$HOME/.kube_scripts/kube_exec.sh"
    ["kdelpod"]="$HOME/.kube_scripts/kube_delete.sh"
    ["kgrepsvc"]="$HOME/.kube_scripts/kube_svc.sh"
    ["kgrepsecret"]="$HOME/.kube_scripts/kube_ksc.sh"
    ["kbox"]="$HOME/.kube_scripts/kube_run_busybox.sh"
    ["klog"]="$HOME/.kube_scripts/kube_logs.sh"
    ["kmanager"]="$HOME/.kube_scripts/kube_get_pods_grep.sh"
    ["kcatcm"]="$HOME/.kube_scripts/kube_cat_configmap.sh"
    ["keditcm"]="$HOME/.kube_scripts/kube_edit_configmap.sh"
    ["kgrepcm"]="$HOME/.kube_scripts/kube_get_cm_grep.sh"
    ["kdelall"]="$HOME/.kube_scripts/kdelall.sh"
)

# Check if .kube_aliases file exists, create if not
if [ ! -f "/root/.kube_aliases" ]; then
    print_yellow "Creating /root/.kube_aliases file..."
    touch /root/.kube_aliases
fi

# Function to check if alias exists in file
alias_exists() {
    local alias_name="$1"
    local alias_value="$2"
    grep -q "^alias $alias_name=\"$alias_value\"$" /root/.kube_aliases
}

# Function to add alias to file
add_alias() {
    local alias_name="$1"
    local alias_value="$2"
    echo "alias $alias_name=\"$alias_value\"" >> /root/.kube_aliases
}

# Check and add missing aliases
print_yellow "Checking and adding aliases to /root/.kube_aliases..."
added_count=0

for alias_name in "${!aliases[@]}"; do
    alias_value="${aliases[$alias_name]}"
    
    if alias_exists "$alias_name" "$alias_value"; then
        print_green "✓ Alias '$alias_name' already exists"
    else
        add_alias "$alias_name" "$alias_value"
        print_yellow "+ Added alias '$alias_name'"
        ((added_count++))
    fi
done

# Check if .bashrc contains source for .kube_aliases
if ! grep -q "source /root/.kube_aliases" /root/.bashrc; then
    print_yellow "Adding source command to /root/.bashrc..."
    {
        echo ""
        echo "# Kubernetes aliases"
        echo "source /root/.kube_aliases"
    } >> /root/.bashrc
    print_green "✓ Added source command to .bashrc"
else
    print_green "✓ Source command already exists in .bashrc"
fi

# Summary
print_green "Installation completed!"
print_green "- Scripts copied to: /root/.kube_scripts/"
print_green "- Aliases file: /root/.kube_aliases"
print_green "- Aliases added: $added_count"
print_green "To use the aliases:"
print_green "  1. Reload your shell: source ~/.bashrc"
print_green "  2. Or start a new terminal session"
print_green "  kdescribe, kexec, kdelpod, kgrepsvc, kgrepsecret, kbox, klog, kmanager, kcatcm, keditcm, kgrepcm, kdelall" 
