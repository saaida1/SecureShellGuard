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

# Function to configure filesystem options
configure_filesystem_options() {
    # Check if the script is run with root privileges
    if [ "$(id -u)" != "0" ]; then
        echo "This function must be run as root."
        return 1
    fi

    # Backup the original sysctl.conf file
    cp /etc/sysctl.conf /etc/sysctl.conf.bak

    # Add the recommended filesystem options to sysctl.conf

    # Disable coredump creation for setuid executables
    echo "fs.suid_dumpable = 0" >> /etc/sysctl.conf

    # Available from Linux kernel version 4.19, restrict the opening of FIFOS and "regular" files
    # not owned by the user in sticky writable directories for everyone.
    echo "fs.protected_fifos=2" >> /etc/sysctl.conf
    echo "fs.protected_regular=2" >> /etc/sysctl.conf

    # Restrict the creation of symbolic links to files owned by the user.
    # This is part of the prevention mechanisms against Time of Check - Time of Use vulnerabilities.
    echo "fs.protected_symlinks =1" >> /etc/sysctl.conf

    # Restrict the creation of hard links to files owned by the user.
    # This sysctl is part of the prevention mechanisms against Time of Check - Time of Use vulnerabilities,
    # as well as against the possibility of retaining access to obsolete files.
    echo "fs.protected_hardlinks =1" >> /etc/sysctl.conf

    # Apply the changes
    sysctl -p

    echo "Filesystem options in sysctl.conf have been configured. Please reboot for changes to take effect."
}








# Main menu
echo "Linux File System Configuration"
echo "0. Update system"
echo "1. File System configuration"
echo "2. Quit!"
read -p "Choose the number of the configuration: " choice
case $choice in
    0)
        echo "Update the system"
                update_system
        ;;
    1)
        echo "File System configuration."
                configure_filesystem_options
        ;;
    2)
        echo "Quit!"
        ;;
    *)
        echo "Invalid choice. Quit!"
        ;;
esac

