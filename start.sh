#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 脚本保存路径
SCRIPT_PATH="$HOME/Ritual.sh"

# 节点安装功能
function install_node() {

# 提示用户输入private_key
read -p "输入EVM 钱包私钥，必须是0x开头，建议使用新钱包: " private_key

# 提示用户输入设置端口
read -p "输入端口: " port1

# 提示用户输入设置端口
read -p "输入Docker hub 用户名: " username
read -p "输入Docker hub 密码: " password

# 更新系统包列表
sudo apt update

# 检查 Git 是否已安装
if ! command -v git &> /dev/null
then
    # 如果 Git 未安装，则进行安装
    echo "未检测到 Git，正在安装..."
    sudo apt install git -y
else
    # 如果 Git 已安装，则不做任何操作
    echo "Git 已安装。"
fi

# 克隆 ritual-net 仓库
git clone https://github.com/ritual-net/infernet-node

# 进入 infernet-deploy 目录
cd infernet-node

# 设置标签
tag="0.2.0"

# 构建镜像
docker build -t ritualnetwork/infernet-node:$tag .

# 进入目录
cd deploy

# 使用cat命令将配置写入config.json
cat > config.json <<EOF
{
  "log_path": "infernet_node.log",
  "manage_containers": true,
  "server": {
    "port": $port1
  },
  "chain": {
    "enabled": true,
    "trail_head_blocks": 5,
    "rpc_url": "https://base-rpc.publicnode.com",
    "coordinator_address": "0x8D871Ef2826ac9001fB2e33fDD6379b6aaBF449c",
    "wallet": {
      "max_gas_limit": 5000000,
      "private_key": "$private_key"
    }
  },
  "snapshot_sync": {
    "sleep": 1.5,
    "batch_size": 200
  },
  "docker": {
    "username": "$username",
    "password": "$password"
  },
  "redis": {
    "host": "redis",
    "port": 6379
  },
  "forward_stats": true,
  "startup_wait": 1.0,
  "containers": [
    {
      "id": "hello-world",
      "image": "ritualnetwork/hello-world-infernet:latest",
      "external": true,
      "port": "3000",
      "allowed_delegate_addresses": [],
      "allowed_addresses": [],
      "allowed_ips": [],
      "command": "--bind=0.0.0.0:3000 --workers=2",
      "env": {}
    }
  ]
}
EOF

echo "Config 文件设置完成"


# 安装基本组件
sudo apt install pkg-config curl build-essential libssl-dev libclang-dev -y

# 检查 Docker 是否已安装
if ! command -v docker &> /dev/null
then
    # 如果 Docker 未安装，则进行安装
    echo "未检测到 Docker，正在安装..."
    sudo apt-get install ca-certificates curl gnupg lsb-release

    # 添加 Docker 官方 GPG 密钥
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # 设置 Docker 仓库
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # 授权 Docker 文件
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    sudo apt-get update

    # 安装 Docker 最新版本
    sudo apt-get install docker-ce docker-ce-cli containerd.io -y 
    DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
    mkdir -p $DOCKER_CONFIG/cli-plugins
    curl -SL https://github.com/docker/compose/releases/download/v2.25.0/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
    sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
    docker compose version
    
else
    echo "Docker 已安装。"
fi

# 启动容器
docker compose up -d

echo "=========================安装完成======================================"
echo "请使用cd infernet-node/deploy 进入目录后，再使用docker compose logs -f 查询日志 "

}
