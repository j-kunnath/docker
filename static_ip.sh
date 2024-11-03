#!/bin/bash

# Function to detect the network interface
detect_interface() {
    # Get the first active interface that is not a loopback
    local interface
   # interface=$(ip -o -f inet addr show | awk '/^[^127]/ {print $2; exit}')
   # interface=$(ip link show | awk '/^[0-9]+: / {print $2; getline; if ($1 == "state" && $2 == "UP") print $0; exit}' | awk '{print $1}' | sed 's/:$//')
    interface=$(ip -o -f inet addr show | awk '/^[0-9]+: / && $2 != "lo" {print $2; exit}')
    echo "$interface"
}

# Function to configure the static IP
configure_static_ip() {
    local interface="$1"
    local static_ip="192.168.1.77"
    local netmask="255.255.255.0"
    local gateway="192.168.1.1"
    local dns="8.8.8.8"

    echo "Configuring static IP on $interface..."

    # Backup the original interfaces file
    cp /etc/network/interfaces /etc/network/interfaces.bak

    # Write the static configuration to the interfaces file
    cat <<EOF > /etc/network/interfaces
auto $interface
iface $interface inet static
    address $static_ip
    netmask $netmask
    gateway $gateway
    dns-nameservers $dns
EOF

    echo "Static IP configured to $static_ip on $interface."
}

# Main script execution
main() {
    local interface
    interface=$(detect_interface)

    if [[ -z "$interface" ]]; then
        echo "No suitable network interface found."
        exit 1
    fi

    echo "Detected interface: $interface"
    configure_static_ip "$interface"

    # Restart the networking service
    systemctl restart networking
    echo "Networking service restarted."
}

# Execute the main function
main
