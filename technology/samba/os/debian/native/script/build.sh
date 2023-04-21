#!/usr/bin/env bash

# ============================================================ #
# Tool Created date: 26 mar 2023                               #
# Tool Created by: Henrique Silva (rick.0x00@gmail.com)        #
# Tool Name: srv_files (samba)                                 #
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
samba_common_user="xpto"
samba_common_pass="xpto"
share_folders_trunk="/var/lib/file_server/samba/"

smb_port[0]="445" #  Server Message Block (SMB) traffic
smb_port[1]="139" # NetBIOS session service traffic
dgram_port="138" #  NetBIOS datagram traffic
nbt_port="137" #  NetBIOS name services traffic

workdir="/etc/samba/"
persistence_volumes=("/etc/samba/" "/var/lib/samba/" "/var/log/samba/" "/var/lib/file_server/")
expose_ports="${smb_port[0]}/tcp ${smb_port[1]}/tcp ${dgram_port}/udp ${nbt_port}/udp"
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
    apt install -y samba smbclient
}

function make_admin_user() {
    useradd --create-home --shell /bin/bash --password $samba_admin_pass $samba_admin_user
    echo -e "${samba_admin_pass}\n${samba_admin_pass}\n" | smbpasswd -a $samba_admin_user
    adduser $samba_admin_user users
}

function make_common_user() {
    useradd --no-create-home --shell /sbin/nologin --password $samba_common_pass $samba_common_user
    echo -e "${samba_common_pass}\n${samba_common_pass}\n" | smbpasswd -a $samba_common_user
    adduser $samba_common_user users
}

function make_share_folders_tree() {
    mkdir -p ${share_folders_trunk}{public,private}
    chmod 777 ${share_folders_trunk}public
    chmod 770 ${share_folders_trunk}private
    chown nobody:nogroup ${share_folders_trunk}public
    chown ${samba_admin_user}:users ${share_folders_trunk}private
}

function build_smb_dot_conf() {
    cp -r ./config/ /tmp/
    touch /etc/samba/new_smb.conf
    cat /tmp/config/global/head.conf > /etc/samba/new_smb.conf
    cat /tmp/config/global/networking.conf >> /etc/samba/new_smb.conf
    cat /tmp/config/global/browsing.conf >> /etc/samba/new_smb.conf
    cat /tmp/config/global/debugging.conf >> /etc/samba/new_smb.conf
    cat /tmp/config/global/authentication.conf >> /etc/samba/new_smb.conf
    cat /tmp/config/global/misc.conf >> /etc/samba/new_smb.conf
    cat /tmp/config/share/head.conf >> /etc/samba/new_smb.conf
    cat /tmp/config/share/shares.conf >> /etc/samba/new_smb.conf
}

function configure_smb_dot_conf() {
    mv /etc/samba/smb.conf /etc/samba/smb.conf.bkp_$(date +%Y%m%d%H%M%S)
    #cp ./complement_smb.conf /tmp/
    sed -i "s/\$smb_port/${smb_port[0]} ${smb_port[1]}/" /etc/samba/new_smb.conf
    sed -i "s/\$dgram_port/$dgram_port/" /etc/samba/new_smb.conf
    sed -i "s/\$nbt_port/$nbt_port/" /etc/samba/new_smb.conf
    sed -i "s|\$share_folders_trunk|$share_folders_trunk|" /etc/samba/new_smb.conf
    sed -i "s/\$samba_admin_user/$samba_admin_user/" /etc/samba/new_smb.conf
    cp /etc/samba/new_smb.conf /etc/samba/smb.conf
    mv /etc/samba/new_smb.conf /etc/samba/new_smb.conf.bkp_$(date +%Y%m%d%H%M%S)
    #cat /tmp/complement_smb.conf >> /etc/samba/smb.conf
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
make_common_user;
make_share_folders_tree;
build_smb_dot_conf;
configure_smb_dot_conf;
start_samba;
