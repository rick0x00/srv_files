#!/usr/bin/env bash

# ============================================================ #
# Tool Created date: 26 mar 2023                               #
# Tool Created by: Henrique Silva (rick.0x00@gmail.com)        #
# Tool Name: status_bar                                        #
# Description: Script for help to create samba File Server     #
# License: MIT License                                         #
# Remote repository 1: https://github.com/rick0x00/srv_files   #
# Remote repository 2: https://gitlab.com/rick0x00/srv_files   #
# ============================================================ #

# ============================================================ #
# start root user checking
if [ $(id -u) -ne 0 ]; then
    echo "Please use root user to run the script."
    exit 1
fi
# end root user checking
# ============================================================ #
# start set variables
samba_admin_user="sysadmin"
samba_admin_pass="sysadmin"
share_folders_trunk="/var/lib/file_server/samba/"
# end set variables
# ============================================================ #
# start definition functions
# ============================== #
# start complement functions

# end complement functions
# ============================== #
# start main functions
function install_samba() {
    apt update
    apt install -y samba
}

function make_admin_user() {
    useradd --no-create-home --shell /sbin/nologin --password $samba_admin_pass $samba_admin_user
    echo -e "${samba_admin_pass}\n${samba_admin_pass}\n" | smbpasswd -a $samba_admin_user
    adduser $samba_admin_user users
}

function make_share_folders_tree() {
    mkdir -p ${share_folders_trunk}{public,private}
    chmod 774 ${share_folders_trunk}public
    chmod 770 ${share_folders_trunk}private
    chown nobody:nogroup ${share_folders_trunk}public
    chown ${samba_admin_user}:users ${share_folders_trunk}private
}

function configure_smb_dot_conf() {
    cp ./complement_smb.conf /tmp/
    sed -i "s|\$share_folders_trunk|$share_folders_trunk|" /tmp/complement_smb.conf
    sed -i "s/\$samba_admin_user/$samba_admin_user/" /tmp/complement_smb.conf
    cp /etc/samba/smb.conf /etc/samba/smb.conf.bkp
    cat /tmp/complement_smb.conf >> /etc/samba/smb.conf
}

function start_samba() {
    systemctl enable --now smbd nmbd
    systemctl restart smbd nmbd
    systemctl start smbd nmbd
    # /usr/sbin/smbd -FS --no-process-group # execute inside docker container
}
# end main functions
# ============================== #
# end definition functions
# ============================================================ #
# start argument reading

# end argument reading
# ============================================================ #
# start main executions of code

install_samba;
make_admin_user;
make_share_folders_tree;
configure_smb_dot_conf;
start_samba;
