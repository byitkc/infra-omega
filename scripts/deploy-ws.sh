#!/usr/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "You must run this script as root, exiting..."
    exit 101
fi

###
### Functions
###

# Input processing
require_user_input() {
    local prompt=$1
    local user_input

    while true; do
        read -p "$prompt" user_input
        if [[ -n "$user_input" ]]; then
            echo "$user_input"
            break
        else
            echo "Input cannot be blank, try again..."
        fi
    done
}

# Remove existing connections
remove_connections() {
    current_connections=$(nmcli --terse --fields=name connection show)
    while IFS= read -r connection; do
        if [[ "$connection" != "lo" && "$connection" != "deploy" ]]; then
            echo "Removing: $connection"
            nmcli connection delete "$connection"
        else
            echo "Skipping loopback connection: $connection"
        fi
    done <<< "$current_connections"
}

###
### Main
###

# Reset the SSH host keys
while true; do
    read -p "Would you like to reset the SSH host keys? (Y/n): " reset_host_keys
    reset_host_keys=${reset_host_keys:-y}
    case "$reset_host_keys" in
        [Yy])
            echo "Resetting SSH host keys..."
            # rm -f /etc/ssh/ssh_host_dsa_key
            rm -f /etc/ssh/ssh_host_rsa_key
            rm -f /etc/ssh/ssh_host_ecdsa_key
            rm -f /etc/ssh/ssh_host_ed25519_key

            # ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key
            ssh-keygen -q -N "" -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key
            ssh-keygen -q -N "" -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key
            ssh-keygen -q -N "" -t ed25519 -f /etc/ssh/ssh_host_ed25519_key
            break
            ;;
        [Nn])
            echo "Leaving existing SSH host keys"
            break
            ;;
        *)
            echo "Invalid input, please enter 'y' or 'n'."
            ;;
    esac
done
echo ""
    
# Set the Hostname/FQDN
while true; do
    read -p "Would you like to set the Hostname/FQDN now? (y/n): " set_net_fqdn
    case "$set_net_fqdn" in
        [Yy])
            read -p "Enter FQDN: " net_fqdn
            hostnamectl set-hostname "$net_fqdn"
            echo "Set the hostname to $net_fqdn"
            break
            ;;
        [Nn])
            echo "Leaving default hostname, this can be changed later with \`hostnamectl set-hostname\`"
            break
            ;;
        *)
            echo "Invalid input, please enter 'y' or 'n'."
            ;;
    esac
done
echo ""

while true; do
    echo "We can configure a network interface with a static IP now. If you don't configure one all attached interfaces will attempt DHCP."
    read -p "Would you like to configure an interface with a static IP now? (y/n): " net_replace
    case "$net_replace" in
        [Yy])
            echo "Removing existing connections"
            remove_connections
            echo "Configuring connection"
            echo "Please validate which connection should be configured based on the following devices:"
            nmcli --fields=general.device,general.hwaddr device show
            echo ""
            net_device_name=$(require_user_input "Enter Device Name: ")
            net_ip_address=$(require_user_input "Enter IP Address: ")
            net_netmask=$(require_user_input "Enter Netmask: ")
            net_gateway=$(require_user_input "Enter Default Gateway: ")
            net_dns_servers=$(require_user_input "Enter comma separated list of DNS servers (ex. \`8.8.8.8,8.8.4.4\`): ")


            echo "Configuring $net_device_name with the IP $net_ip_address/$net_netmask"

            nmcli c add \
                type ethernet \
                con-name "$net_device_name" \
                ifname "$net_device_name" \
                ipv4.method manual \
                ipv4.addresses "$net_ip_address/$net_netmask" \
                ipv4.gateway "$net_gateway" \
                ipv4.dns "$net_dns_servers"
            break
            ;;
        [Nn])
            echo "Leaving default connection in place."
            echo "You will need to manually turn a connection on using \`nmcli c up <conn-name>\`"
            echo "To have this connection start on boot, please run \`nmcli c mod <conn-name> connection.autoconnect yes\`"
            
            break
            ;;
        *)
            echo "Invalid input, please enter 'y' or 'n'."
            ;;
    esac
done
