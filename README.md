# ritual

# 提示用户输入private_key
export private_key=xxxxx

# 提示用户输入设置端口
export port1=xxxxx

# 提示用户输入设置端口
export username=xxxxx
export password=xxxxx
wget -O start.sh https://raw.githubusercontent.com/jiangyaqiii/PingPong/web/start.sh && chmod +x start.sh && ./start.sh 2>&1 | tee console.log
