#!/bin/sh -x
# This script changes the oom option for the vms to p[anic when a oom situation arises. We also set the reboot time as per the AzLinux suggestion
#More details at: https://unix.stackexchange.com/questions/87732/linux-reboot-out-of-memory

# Make sure to fail on a non zero error code
set -e

echo 'vm.panic_on_oom = 2' | sudo tee -a /etc/sysctl.conf
echo 'kernel.panic = 20' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p /etc/sysctl.conf
