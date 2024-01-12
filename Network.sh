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


# Function to configure IPv4 network options in sysctl.conf
configure_ipv4_network_options() {
    # Check if the script is run with root privileges
    if [ "$(id -u)" != "0" ]; then
        echo "This script must be run as root."
        exit 1
    fi

    # Backup the original sysctl.conf file
    cp /etc/sysctl.conf /etc/sysctl.conf.bak

    # Add the recommended IPv4 network options to sysctl.conf

    # Attenuate the effect of JIT kernel dispersion at the cost of performance compromise.
    net.core.bpf_jit_harden=2

    # Disable routing between interfaces. This option is special and may
    # trigger changes in other options. Placing this option early ensures that
    # the configuration of the following options remains unchanged.
    net.ipv4.ip_forward=0

    # Consider packets received from the outside with a source address in the 127/8 range as invalid.
    net.ipv4.conf.all.accept_local=0

    # Refuse to receive ICMP redirect packets.
    net.ipv4.conf.all.accept_redirects=0
    net.ipv4.conf.default.accept_redirects=0
    net.ipv4.conf.all.secure_redirects=0
    net.ipv4.conf.default.secure_redirects=0

    # Disable sharing of media (network) resources.
    net.ipv4.conf.all.shared_media=0
    net.ipv4.conf.default.shared_media=0

    # Refuse source-routed packets to determine their route.
    net.ipv4.conf.all.accept_source_route=0
    net.ipv4.conf.default.accept_source_route=0

    # Prevent the Linux kernel from globally managing the ARP table.
    net.ipv4.conf.all.arp_filter=1

    # Respond to ARP requests only if the source and destination addresses are on the same network and on the receiving interface.
    net.ipv4.conf.all.arp_ignore=2

    # Deny routing of packets with source or destination address in the loopback network.
    net.ipv4.conf.all.route_localnet=0

    # Ignore gratuitous ARP requests.
    net.ipv4.conf.all.drop_gratuitous_arp=1

    # Check that the source address of received packets on a given interface has indeed been contacted via that same interface.
    # This is useful for routers with dynamic route calculation.
    net.ipv4.conf.default.rp_filter=1
    net.ipv4.conf.all.rp_filter=1

    # Set to 1 only on routers, as sending ICMP redirects is a normal behavior for routers.
    net.ipv4.conf.default.send_redirects=0
    net.ipv4.conf.all.send_redirects=0

    # Ignore responses not conforming to RFC 1122.
    net.ipv4.icmp_ignore_bogus_error_responses=1

    # Increase the range for ephemeral ports.
    net.ipv4.ip_local_port_range=32768 65535

    # RFC 1337
    net.ipv4.tcp_rfc1337=1

    # Use SYN cookies to prevent SYN flood attacks.
    net.ipv4.tcp_syncookies=1

    # Apply the changes
    sysctl -p

    echo "IPv4 network options in sysctl.conf have been configured. Please reboot for changes to take effect."
}

# Function to configure IPv6 network options to disable IPv6
configure_ipv6_disable_options() {
    # Check if the script is run with root privileges
    if [ "$(id -u)" != "0" ]; then
        echo "This function must be run as root."
        return 1
    fi

    # Backup the original sysctl.conf file
    cp /etc/sysctl.conf /etc/sysctl.conf.bak

    # Add the recommended IPv6 network options to sysctl.conf to disable IPv6

    # Disable IPv6 globally for the default network configuration
    echo "net.ipv6.conf.default.disable_ipv6=1" >> /etc/sysctl.conf

    # Disable IPv6 globally for all network configurations
    echo "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.conf

    # Apply the changes
    sysctl -p

    echo "IPv6 network options to disable IPv6 in sysctl.conf have been configured. Please reboot for changes to take effect."
}




# Main menu
echo "Linux Network Configuration"
echo "0. Update system"
echo "1. IPV4 configuration"
echo "2. IPV6 configuration"
echo "3. Quit!"
read -p "Choose the number of the configuration: " choice
case $choice in
    0)
        echo "Update the system"
                update_system
        ;;
    1)
        echo "IPV4 configuration."
		echo "Les options de configuration du réseau IPv4 détaillées dans cette liste sont recommandées pour un hôte de type « serveur » n’effectuant pas de routage et ayant une configuration IPv4 minimaliste."
                onfigure_ipv4_network_options
        ;;
    2)
        echo "IPV6 configuration."
		echo "Quand IPv6 n’est pas utilisé, il est recommandé de désactiver la pile IPv6."
                configure_ipv6_disable_options
        ;;
    3)
        echo "Quit!"
        ;;
    *)
        echo "Invalid choice. Quit!"
        ;;
esac

