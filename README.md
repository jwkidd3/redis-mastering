# Mastering Redis 



# Add Redis Stack repository  
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg  
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee   /etc/apt/sources.list.d/redis.list  

# Update and install Redis Stack  
sudo apt update  
sudo apt install redis-stack-server  

# Start Redis Stack  
sudo systemctl start redis-stack-server  
sudo systemctl enable redis-stack-server  
