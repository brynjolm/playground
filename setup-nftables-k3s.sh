#!/bin/bash

# Update package list
apt update
post_status $? "Package list update"

# Upgrade packages
apt upgrade -y
post_status $? "Package upgrade"

# Step 1: Create nftables configuration file
cat <<EOF >/etc/nftables-k3s.conf
#!/usr/sbin/nft -f

table inet filter {
    chain input {
        type filter hook input priority 0; policy accept;
    }

    chain forward {
        type filter hook forward priority 0; policy accept;
    }

    chain output {
        type filter hook output priority 0; policy accept;
    }
}
EOF

# Step 2: Load nftables rules
nft -f /etc/nftables-k3s.conf

# Step 3: Save nftables rules for persistence
nft list ruleset > /etc/nftables-k3s.rules

# Step 4: Create and enable systemd service
cat <<EOF >/etc/systemd/system/nftables-k3s.service
[Unit]
Description=nftables rules for k3s
After=nftables.service

[Service]
ExecStart=/usr/sbin/nft -f /etc/nftables-k3s.rules
Type=oneshot

[Install]
WantedBy=multi-user.target
EOF

systemctl enable nftables-k3s.service

# Step 5: Reboot the system
reboot
