#/usr/bin/bash

if [ $EUID -ne 0 ]; then
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

echo "You should edit the files in \`/etc/netplan/\` to set your IP address staticly if needed."
echo "There is an example file here as \`./netplan_setup/static_ip.yaml\`"
