#!/bin/bash

# Function to activate virtualization (VT-x)
activate_virtualization() {
    sudo modprobe kvm_intel
    sudo modprobe kvm
    echo "The virtualization (VT-x) has been activated."
}

# Function to update the boot order
update_boot_order() {
    sudo update-grub
    echo "The boot order has been updated."
}

# Function to enable secure boot
enable_secure_boot() {

  if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as an administrator (root)." 
    exit 1
  fi

  # Check if efibootmgr is installed
  if ! command -v efibootmgr &> /dev/null; then
    echo "The efibootmgr program is not installed. Please install it before running this script."
    exit 1
  fi

  # Enable Secure Boot
  efibootmgr --verbose --create --disk /dev/sdX --part Y --loader /EFI/Path/to/Bootloader.efi --label "Secure Boot" --unicode "root=UUID=XXXXXXXXXXXXXXXXX ro quiet splash" --trust
}

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

# Main menu
echo "Configuration of hardware security for the Linux system"
echo "Make your choice:"
echo "0. Update System"
echo "1. Enable Virtualization"
echo "2. Update Boot Order"
echo "3. Enable Secure Boot"
echo "4. Set a password for the BIOS/UEFI"
echo "5. Quit!"
read -p "Choose the number of the configuration: " choice
case $choice in
    0)
        echo "Update the system"
        update_system
        ;;
    1)
        echo "Enable Virtualization."
        activate_virtualization
        ;;
    2)
        echo "Update Boot Order."
        update_boot_order
        ;;
    3)
        echo "Enable Secure Boot."
        enable_secure_boot
        ;;
    4)
        echo "Set a password for the BIOS/UEFI."
        echo "Access the BIOS/UEFI:"
        echo "Reboot your computer, during the boot process, press the key to access the BIOS/UEFI. Common keys include Del, Esc, F1, F2, F10, F12, or a combination of keys. The exact key depends on your computer's manufacturer."
        echo "Navigate to Security or Advanced settings:"
        echo "Once inside the BIOS/UEFI, navigate to the Security or Advanced settings. The exact location may vary."
        echo "Locate the Set Password option:"
        echo "Look for an option related to setting a password. It might be called 'Set Supervisor Password,' 'Administrator Password,' or something similar."
        echo "Enter the new password:"
        echo "Choose a strong password and enter it. Some BIOS/UEFI systems may have specific requirements for password strength."
        echo "Confirm the password:"
        echo "Re-enter the password to confirm."
        echo "Save and exit:"
        echo "Save the changes and exit the BIOS/UEFI. The process usually involves selecting a 'Save & Exit' or similar option."
        ;;
    5) 
        echo "Quit."
        ;;
    *)
        echo "Invalid Choice! Please enter a valid number."
        ;;
esac

