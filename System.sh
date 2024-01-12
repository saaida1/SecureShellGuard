#!/bin/bash

# Function to update the system
update_system() {
    read -p "Do you want to update the system? (y/n): " choice
    if [ "$choice" == "y" ]; then
        sudo apt update
        sudo apt upgrade
        echo "The system has been updated."
    else
        echo "The system has not been updated."
    fi
}

# Access Accounts configuration
applyPasswordRecommendations() {
    # R31: Use strong passwords
    echo "minlen = 12" >> /etc/security/pwquality.conf
    echo "minclass = 3" >> /etc/security/pwquality.conf

    pam_file="/etc/pam.d/common-password"
    if grep -q "password.*pam_pwquality.so" "$pam_file"; then
        echo "PAM already configured for password quality."
    else
        echo "Configuring PAM for password quality..."
        echo "password requisite pam_pwquality.so retry=3" >> "$pam_file"
    fi
}

applyUserAccountRecommendations() {
    # R30: Disable unused user accounts
    echo "Disabling unused user accounts..."
    # Add your specific commands for disabling unused user accounts

    # Call the function to apply password recommendations
    applyPasswordRecommendations

    # R32: Expire local user sessions
    echo "Expiring local user sessions..."
    echo "* hard tmout 15" >> /etc/security/limits.conf
    echo "TMOUT=900" >> /etc/profile
    sudo usermod -L username
}

applyAdministratorAccountRecommendations() {
    # Ensure that the root account is locked
    sudo usermod -L -e 1 root
    sudo usermod -s /bin/false root

    # Logging the creation of every new process with auditd
    echo "Configuring auditd for process creation logging..."
    audit_rules="/etc/audit/rules.d/admin_process_creation.rules"
    if [ ! -f "$audit_rules" ]; then
        echo "-a exit,always -F arch=b64 -S execve,execveat" > "$audit_rules"
        echo "-a exit,always -F arch=b32 -S execve,execveat" >> "$audit_rules"
        service auditd restart
    else
        echo "Audit rules for process creation already configured."
    fi
}

disableServiceAccounts() {
    # R34: Disable service accounts
    echo "Disabling service accounts..."

    # Example: Disable service accounts (adjust account names as needed)
    service_accounts=("www" "www-data" "named" "nobody" "nginx" "php" "mysql")
    
    for account in "${service_accounts[@]}"; do
        sudo usermod -L -e 1 "$account"
        sudo usermod -s /bin/false "$account"
        echo "Service account '$account' disabled."
    done
}

uniqueServiceAccounts() {
    # R35: Use unique and exclusive service accounts
    echo "Create unique and exclusive service accounts:"
    # Create unique service accounts for each service 
    createServiceAccount() {
        local service_name="$1"
        sudo useradd -m "$service_name"
        echo "Service account '$service_name' created."
    }

    createServiceAccount "nginx"
    createServiceAccount "php"
    createServiceAccount "mysql"
}

# Partitioning configuration
configurePartitioning() {
    # R28: Recommended partitioning
    echo "Configuring recommended partitioning..."

    # Example: Update /etc/fstab with recommended options
    cat << EOF >> /etc/fstab
/dev/sda1 /boot ext4 nosuid,nodev,noexec,noauto 0 0
/dev/sda2 /opt ext4 nosuid,nodev,ro 0 0
/dev/sda3 /tmp ext4 nosuid,nodev,noexec 0 0
/dev/sda4 /srv ext4 nosuid,nodev,noexec,ro 0 0
/dev/sda5 /home ext4 nosuid,nodev,noexec 0 0
/dev/sda6 /proc proc hidepid=2 14 0 0
/dev/sda7 /usr ext4 nodev 0 0
/dev/sda8 /var ext4 nosuid,nodev,noexec 0 0
/dev/sda9 /var/log ext4 nosuid,nodev,noexec 0 0
/dev/sda10 /var/tmp ext4 nosuid,nodev,noexec 0 0
EOF

    # R29: Restrict access to the /boot directory
    echo "Restricting access to the /boot directory..."
    sed -i 's|/dev/sda1 /boot ext4|/dev/sda1 /boot ext4 noauto|g' /etc/fstab
    sudo chmod 700 /boot
    sudo chown root:root /boot
}

# Access control functions
modify_umask() {
    echo "Defaults umask=0077" | sudo tee -a /etc/profile > /dev/null
    echo "UMask=0027" | sudo tee -a /etc/systemd/service.conf > /dev/null
}

create_sudo_group() {
    sudo groupadd sudogrp
    sudo chown root:sudogrp /usr/bin/sudo
    sudo chmod 4750 /usr/bin/sudo
}

configure_sudoers() {
    echo "Defaults noexec,requiretty,use_pty,umask=0077,ignore_dot,env_reset" | sudo tee -a /etc/sudoers > /dev/null
}

secure_editing_with_sudoedit() {
    echo "Defaults editor=/usr/bin/sudoedit" | sudo tee -a /etc/sudoers > /dev/null
}

activate_apparmor_profiles() {
    if ! command -v aa-status &> /dev/null; then
        echo "AppArmor is not installed on this system."
        exit 1
    fi

    apparmor_status=$(aa-status)
    echo "$apparmor_status"

    enforce_profiles=$(echo "$apparmor_status" | grep -oP '([0-9]+) profiles are in enforce mode' | grep -oP '[0-9]+')

    if [ "$enforce_profiles" -eq 0 ]; then
        echo "Activating AppArmor profiles in enforce mode..."
        sudo aa-enforce /etc/apparmor.d/*
    else
        echo "All AppArmor profiles are already in enforce mode."
    fi
}

activate_selinux() {
    sestatus_output=$(sestatus)
    echo "$sestatus_output"

    selinux_status=$(echo "$sestatus_output" | grep "SELinux status" | awk '{print $NF}')
    selinux_policy=$(echo "$sestatus_output" | grep "Loaded policy name" | awk '{print $NF}')

    if [ "$selinux_status" != "enabled" ]; then
        echo "Enabling SELinux in enforcing mode..."
        sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
        sudo sed -i 's/^SELINUXTYPE=.*/SELINUXTYPE=targeted/' /etc/selinux/config
        sudo setenforce 1
    else
        echo "SELinux is already enabled in enforcing mode."
    fi

    sestatus
}

set_selinux_booleans() {
    echo "Setting SELinux boolean variables..."
    sudo setsebool -P allow_execheap=off
    sudo setsebool -P allow_execmem=off
    sudo setsebool -P allow_execstack=off
    sudo setsebool -P secure_mode_insmod=on
    sudo setsebool -P ssh_sysadm_login=off
}

# File & Directories Configuration
restrict_access_to_sensitive_files() {
    echo "Restricting access to sensitive files and directories..."

    sudo chown root:root /etc/gshadow
    sudo chmod 640 /etc/gshadow

    sudo chown root:root /etc/shadow
    sudo chmod 640 /etc/shadow

    sudo chown foo:users /home/foo/.ssh/id_rsa
    sudo chmod 600 /home/foo/.ssh/id_rsa

    echo "Access restricted successfully."
}

restrict_access_to_named_ipc() {
    echo "Restricting access to named IPC sockets and pipes..."

    find / -type p -print0 | while IFS= read -r -d '' pipe_file; do
        sudo chmod 600 "$pipe_file"
        echo "Access restricted for $pipe_file."
    done

    find / -type s -print0 | while IFS= read -r -d '' socket_file; do
        sudo chmod 600 "$socket_file"
        echo "Access restricted for $socket_file."
    done

    echo "Access restricted successfully."
}

access_rights_to_sesitive_files() {
    echo "Finding files or directories without a known user or group..."
    find / -type f \( -nouser -o -nogroup \) -ls 2>/dev/null

    echo "Enabling sticky bit on writable directories..."
    find / -type d \( -perm -0002 -a \! -perm -1000 \) -exec sudo chmod +t {} \; 2>/dev/null
    find / -type d -perm -0002 -a \! -uid 0 -exec echo "WARNING: Directory without sticky bit owned by root - {}" \; -exec ls -ld {} \; 2>/dev/null

    echo "Separating temporary directories for users..."
    # Add your specific commands for separating temporary directories using PAM modules

    echo "Avoiding the usage of executables with setuid or setgid..."
    find / -type f -perm /6000 -ls 2>/dev/null

    echo "Avoiding executables with setuid root and setgid root..."
    # Add your specific commands for avoiding executables with setuid root and setgid root

    echo "Security recommendations applied."
}

# Main menu
echo "Linux System Configuration"
echo "0. Update system"
echo "1. Partitioning configuration"
echo "2. Access Accounts configuration"
echo "3. Access Control configuration"
echo "4. Files and Directories configuration"
echo "5. Quit!"

read -p "Choose the number of the configuration: " choice
case $choice in
    0)
        echo "Update the system"
        update_system
        ;;
    1)
        echo "Partitioning configuration."
        configurePartitioning
        ;;
    2)
        echo "Access Accounts configuration."
        echo "Choose the accounts type:"
        echo "1. User Accounts"
        echo "2. Administrator Accounts"
        echo "3. Service Accounts"
        echo "4. Quit!"

        read -p "Choose the number of the configuration: " choice_accounts
        case $choice_accounts in
            1)
                echo "User Accounts"
                applyUserAccountRecommendations
                ;;
            2)
                echo "Administrator Accounts"
                applyAdministratorAccountRecommendations
                ;;
            3)
                echo "Service Accounts"
                disableServiceAccounts
                uniqueServiceAccounts
                ;;
            4)
                echo "Quit!"
                ;;
            *)
                echo "Invalid choice. Quit!"
                ;;
        esac
        ;;
    3)
        echo "Access Control configuration"
        echo "Choose access control model :"
        echo "1. Traditional Unix Model "
        echo "2. AppArmor"
        echo "3. SELinux"
        echo "4. Quit!"

        read -p "Choose the number of the configuration: " choice_access_control
        case $choice_access_control in
            1)
                echo "Traditional Unix Model"
                modify_umask
                create_sudo_group
                configure_sudoers
                secure_editing_with_sudoedit
                ;;
            2)
                echo "AppArmor"
                activate_apparmor_profiles
                ;;
            3)
                echo "SELinux"
                activate_selinux
                set_selinux_booleans
                ;;
            4)
                echo "Quit!"
                ;;
            *)
                echo "Invalid choice. Quit!"
                ;;
        esac
        ;;
    4)
        echo "Files and Directories configuration"
        echo "Choose the files/directories type:"
        echo "1. Sensitive Files and Directories"
        echo "2. Named IPC Files, Sockets, or Pipes"
        echo "3. Access Rights"
        echo "4. Quit!"

        read -p "Choose the number of the configuration: " choice_files_directories
        case $choice_files_directories in
            1)
                echo "Sensitive Files and Directories"
                restrict_access_to_sensitive_files
                ;;
            2)
                echo "Named IPC Files, Sockets, or Pipes"
                restrict_access_to_named_ipc
                ;;
            3)
                echo "Access Rights"
                access_rights_to_sesitive_files
                ;;
            4)
                echo "Quit!"
                ;;
            *)
                echo "Invalid choice. Quit!"
                ;;
        esac
        ;;
    5)
        echo "Quit!"
        ;;
    *)
        echo "Invalid choice. Quit!"
        ;;
esac
