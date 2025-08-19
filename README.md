# Mastering Redis 


## Setup
wsl --install  

sudo apt remove redis-server  
sudo apt purge redis-server  

sudo apt purge redis-server redis-tools && sudo apt autoremove  

sudo apt install redis-tools  
docker run -p 6379:6379 redis/redis-stack:latest  

ip route show 

redis-cli -h host.docker.internal -p 6379 ping  

Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux-d -p6379 
