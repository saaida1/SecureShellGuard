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

enable_iommu() {
    # Check if the script is run with root privileges
    if [ "$(id -u)" != "0" ]; then
        echo "This script must be run as root."
        exit 1
    fi

    # Backup the original kernel command line
    cp /etc/default/grub /etc/default/grub.bak

    # Add iommu=force to GRUB_CMDLINE_LINUX_DEFAULT
    sed -i 's/^\(GRUB_CMDLINE_LINUX_DEFAULT=".*\)"/\1 iommu=force"/' /etc/default/grub

    # Update GRUB
    update-grub

    echo "IOMMU has been enabled with 'iommu=force'. Please reboot for changes to take effect."
}

configure_memory_options() {
    # Check if the script is run with root privileges
    if [ "$(id -u)" != "0" ]; then
        echo "This script must be run as root."
        exit 1
    fi

    # Backup the original kernel command line
    cp /etc/default/grub /etc/default/grub.bak

    # Add the recommended kernel options
    sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/"$/ n l1tf=full,force page_poison=on pti=on slab_nomerge=yes slub_debug=FZP spec_store_bypass_disable=seccomp spectre_v2=on mds=full,nosmt mce=0 page_alloc.shuffle=1 rng_core.default_quality=500"/' /etc/default/grub

    # Update GRUB
    update-grub

    echo "Kernel options have been configured. Please reboot for changes to take effect."
}


configure_kernel_options() {
    # Check if the script is run with root privileges
    if [ "$(id -u)" != "0" ]; then
        echo "This script must be run as root."
        exit 1
    fi

    # Backup the original sysctl.conf file
    cp /etc/sysctl.conf /etc/sysctl.conf.bak

    # Add the recommended kernel options to sysctl.conf
    cat <<EOF >> /etc/sysctl.conf
# Restreint l'accès au buffer dmesg (équivalent à
# CONFIG_SECURITY_DMESG_RESTRICT=y)
kernel.dmesg_restrict=1
# Interdit le chargement des modules noyau (sauf ceux déjà chargés à ce point)
kernel.modules_disabled=1
# Cache les adresses noyau dans /proc et les différentes autres interfaces ,
# y compris aux utilisateurs privilégiés
kernel.kptr_restrict=2
# Spécifie explicitement l'espace d'identifiants de processus supporté par le
# noyau , 65 536 étant une valeur donnée à titre d'exemple
kernel.pid_max=65536
# Restreint l'utilisation du sous -système perf
kernel.perf_cpu_time_max_percent=1
kernel.perf_event_max_sample_rate=1
# Interdit l'accès non privilégié à l'appel système perf_event_open (). Avec une
# valeur plus grande que 2, on impose la possession de CAP_SYS_ADMIN , pour pouvoir
# recueillir les évènements perf.
kernel.perf_event_paranoid=2
# Active l'ASLR
kernel.randomize_va_space=2
# Désactive les combinaisons de touches magiques (Magic System Request Key)
kernel.sysrq=0
# Restreint l'usage du BPF noyau aux utilisateurs privilégiés
kernel.unprivileged_bpf_disabled=1
# Arrête complètement le système en cas de comportement inattendu du noyau Linux
kernel.panic_on_oops=1
EOF

    # Apply the changes
    sysctl -p

    echo "Kernel options in sysctl.conf have been configured. Please reboot for changes to take effect."
}


configure_yama_options() {
    # Check if the script is run with root privileges
    if [ "$(id -u)" != "0" ]; then
        echo "This script must be run as root."
        exit 1
    fi

    # Backup the original sysctl.conf file
    cp /etc/sysctl.conf /etc/sysctl.conf.bak

    # Add the recommended Yama security module options to sysctl.conf
    cat <<EOF >> /etc/sysctl.conf
# Yama security module options
kernel.yama.ptrace_scope=1
EOF

    # Apply the changes
    sysctl -p

    echo "Yama security module options in sysctl.conf have been configured. Please reboot for changes to take effect."
}


# Main menu
echo "Linux Kernel Configuration"
echo "0. Update system"
echo "1. Memory configuration"
echo "2. Kernel configuration"
echo "3. Processes configuration"
echo "4. Quit!"
read -p "Choose the number of the configuration: " choice
case $choice in
    0)
        echo "Update the system"
        	update_system
        ;;
    1)
        echo "Memory configuration."
		echo "Enabling the IOMMU (Input/Output Memory Management Unit) service helps protect the system's memory from arbitrary accesses performed by devices."
        	enable_iommu
		configure_memory_options
        ;;
    2)
        echo "Kernel configuration."
        	configure_kernel_options
        ;;
    3)
        echo "Processes configuration"
	        configure_yama_options
       ;;
    4)
	echo "Quit!"
	;;
    *)
	echo "Invalid choice. Quit!"
	;;
esac
