#!/bin/bash
# Log user_data output for debugging
exec > >(tee /var/log/user_data.log|logger -t user-data -s 2>/dev/console) 2>&1

yum update -y

echo "[user_data] Installing Node.js and git..."
curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
yum install -y nodejs git

cd /home/ec2-user

# Install CloudWatch agent
yum install -y amazon-cloudwatch-agent

echo "[user_data] Cloning repository..."
git clone https://github.com/wegosend/Cameroon-website.git || { echo "[user_data] Git clone failed"; exit 1; }
cd Cameroon-website

echo "[user_data] Installing npm dependencies..."
npm install || { echo "[user_data] npm install failed"; exit 2; }

echo "[user_data] Building Next.js app..."
npm run build || { echo "[user_data] npm run build failed"; exit 3; }

echo "[user_data] Installing pm2..."
npm install -g pm2

# Create ecosystem file (BEST PRACTICE)
cat <<EOF > ecosystem.config.js
module.exports = {
  apps: [
    {
      name: "nextjs-app",
      script: "npm",
      args: "start",
      env: {
        NODE_ENV: "production",
        PORT: 3000,
        HOST: "0.0.0.0"
      }
    }
  ]
};
EOF

echo "[user_data] Starting Next.js app with pm2..."
PORT=3000 HOST=0.0.0.0 pm2 start npm --name "nextjs-app" -- start || { echo "[user_data] pm2 start failed"; exit 4; }

pm2 startup
pm2 save

echo "[user_data] pm2 list:"
pm2 list

echo "[user_data] netstat -tulpen:"
netstat -tulpen