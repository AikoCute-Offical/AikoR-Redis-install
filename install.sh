#!/bin/bash

rm -rf $0

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Error：${plain} This script must be run as root user!\n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "${red}System version not detected, please contact script author!${plain}\n" && exit 1
fi

arch=$(arch)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
  arch="64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
  arch="arm64-v8a"
else
  arch="64"
  echo -e "${red}No schema detected, use default schema: ${arch}${plain}"
fi

echo "Architecture System: ${arch}"

if [ "$(getconf WORD_BIT)" != '32' ] && [ "$(getconf LONG_BIT)" != '64' ] ; then
    echo "This software does not support 32-bit (x86) system, please use 64-bit (x86_64) system, if found wrong, please contact the author"
    exit 2
fi

os_version=""

# os version
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "${red}Please use CentOS 7 or later!${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}Please use Ubuntu 16 or higher!${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}Please use Debian 8 or later!${plain}\n" && exit 1
    fi
fi

# install Redis
function install_redis() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install -y epel-release
        yum install -y redis
    else
        apt-get update
        apt-get install -y redis-server
    fi
}

# config Redis
function config_redis() {
    echo "" > /etc/redis.conf
    echo "bind 0.0.0.0" >> /etc/redis.conf

    echo -e "Input the port of Redis [default: 6379]:"
    read -p "(Default port: 6379):" redis_port
    [[ -z "${redis_port}" ]] && redis_port="6379"
    echo "port ${redis_port}" >> /etc/redis.conf

    echo -e "Input the password of Redis [default: none]:"
    read -p "(Default password: none):" redis_password
    [[ -z "${redis_password}" ]] && redis_password=""
    if [[ -n "${redis_password}" ]]; then
        echo "requirepass ${redis_password}" >> /etc/redis.conf
    fi

    
    echo -e "Do you want to enable Redis maxmemory? [y/n]"
    read -p "(Default: n):" redis_maxmemory
    [[ -z "${redis_maxmemory}" ]] && redis_maxmemory="n"
    if [[ ${redis_maxmemory} == [Yy] ]]; then
        echo -e "Input the maxmemory of Redis [default: 512MB]:"
        read -p "(Default maxmemory: 512MB):" redis_maxmemory
        [[ -z "${redis_maxmemory}" ]] && redis_maxmemory="512MB"
        echo "maxmemory ${redis_maxmemory}" >> /etc/redis.conf
    fi 
}

# start Redis
function start_redis() {
    if [[ x"${release}" == x"centos" ]]; then
        systemctl start redis
        systemctl enable redis
    else
        systemctl start redis-server
        systemctl enable redis-server
    fi
}

# install Redis
install_redis

# config Redis
config_redis

# start Redis
start_redisS

echo -e "${green}Redis install completed!${plain}"