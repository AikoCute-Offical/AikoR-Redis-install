#!/bin/bash

rm -rf $0

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Lỗi：${plain} Tập lệnh này phải được chạy với tư cách người dùng root!\n" && exit 1

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
    echo -e "${red}Phiên bản hệ thống không được phát hiện, vui lòng liên hệ với tác giả kịch bản!${plain}\n" && exit 1
fi

arch=$(arch)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
  arch="64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
  arch="arm64-v8a"
else
  arch="64"
  echo -e "${red}Không có lược đồ nào được phát hiện, hãy sử dụng lược đồ mặc định: ${arch}${plain}"
fi

echo "Architecture System: ${arch}"

if [ "$(getconf WORD_BIT)" != '32' ] && [ "$(getconf LONG_BIT)" != '64' ] ; then
    echo "Phần mềm này không hỗ trợ hệ thống 32-bit (x86), vui lòng sử dụng hệ thống 64-bit (x86_64), nếu phát hiện sai, vui lòng liên hệ với tác giả"
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

# install redis
function install_redis() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install epel-release -y
        yum install -y redis
    else
        apt-get update
        add-apt-repository ppa:redislabs/redis
        apt-get install redis
    fi
}

# config redis
function config_redis() {
    if [[ x"${release}" == x"centos" ]]; then
        echo "" > /etc/redis.conf
        echo "bind 0.0.0.0" >> /etc/redis.conf

        echo -e "Vui lòng nhập cổng của Redis (mặc định: 6379):"
        read -p "(Mặc định cổng: 6379):" redis_port
        [ -z "${redis_port}" ] && redis_port="6379"
        echo -e "Cổng của Redis：${redis_port}"
        echo "port ${redis_port}" >> /etc/redis.conf

        read -p "Vui lòng nhập mật khẩu của Redis (mặc định: AIKO):" redis_password
        [ -z "${redis_password}" ] && redis_password="AIKO"
        echo -e "Mật khẩu của Redis：${redis_password}"
        echo "requirepass ${redis_password}" >> /etc/redis.conf
    fi

    if [[ x"${release}" == x"debian" || x"${release}" == x"ubuntu" ]]; then
        echo "" > /etc/redis/redis.conf
        echo "bind 0.0.0.0" >> /etc/redis/redis.conf

        echo -e "Vui lòng nhập cổng của Redis (mặc định: 6379):"
        read -p "(Mặc định cổng: 6379):" redis_port
        [ -z "${redis_port}" ] && redis_port="6379"
        echo -e "Cổng của Redis：${redis_port}"
        echo "port ${redis_port}" >> /etc/redis/redis.conf

        read -p "Vui lòng nhập mật khẩu của Redis (mặc định: AIKO):" redis_password
        [ -z "${redis_password}" ] && redis_password="AIKO"
        echo -e "Mật khẩu của Redis：${redis_password}"
        echo "requirepass ${redis_password}" >> /etc/redis/redis.conf
    fi
}

# start redis
function start_redis() {
    if [[ x"${release}" == x"centos" ]]; then
        systemctl start redis
        systemctl enable redis
    else
        systemctl start redis-server
        systemctl enable --now redis-server
    fi
}

# install redis
install_redis

# config redis
config_redis

# start redis
start_redis

echo -e "${green}Redis đã được cài đặt thành công!${plain}"