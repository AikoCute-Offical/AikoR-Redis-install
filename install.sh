#!/bin/bash

rm -rf $0

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain} 该脚本必须运行在root用户下!\n" && exit 1

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
    echo -e "${red}当前系统版本暂未支持, 请联系作者!${plain}\n" && exit 1
fi

arch=$(arch)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
  arch="64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
  arch="arm64-v8a"
else
  arch="64"
  echo -e "${red}当前架构暂未支持, 使用默认架构: ${arch}${plain}"
fi

echo "系统架构: ${arch}"

if [ "$(getconf WORD_BIT)" != '32' ] && [ "$(getconf LONG_BIT)" != '64' ] ; then
    echo "当前暂未支持 32-bit (x86) 系统, 请使用 64-bit (x86_64) 系统, 如果识别错误, 请联系作者"
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
        echo -e "${red}请使用 CentOS 7 或更新版本!${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "${red}请使用 Ubuntu 16 或更新版本!${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red}请使用 Debian 8 或更新版本!${plain}\n" && exit 1
    fi
fi

# install redis
function install_redis(){
    if [[ x"${release}" == x"centos" ]]; then
        yum install epel-release -y
        yum install -y redis
    else
        apt-get update
        apt-get install -y redis-server
    fi
}

# config redis
function config_redis() {
    echo "" > /etc/redis.conf
    echo "bind 0.0.0.0" >> /etc/redis.conf

    echo -e "请输入Redis的端口号 [1-65535]:"
    read -p "(默认端口: 6379):" redis_port
    [[ -z "${redis_port}" ]] && redis_port="6379"
    echo -e "Redis的端口号: ${redis_port}\n"
    echo "port ${redis_port}" >> /etc/redis.conf

    echo -e "请输入Redis的密码:"
    read -p "(默认密码: 123456):" redis_password
    [[ -z "${redis_password}" ]] && redis_password="123456"
    echo -e "Redis的密码: ${redis_password}\n"
    echo "requirepass ${redis_password}" >> /etc/redis.conf
}

# start redis
function start_redis(){
    if [[ x"${release}" == x"centos" ]]; then
        systemctl start redis
        systemctl enable redis
    else
        systemctl start redis-server
        systemctl enable redis-server
    fi
}

# install redis
install_redis

# config redis
config_redis

# start redis
start_redis

echo -e "${green}Redis安装成功!${plain}"
