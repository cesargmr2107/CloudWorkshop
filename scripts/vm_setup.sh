#!/bin/bash

# Interpolate TF variables into Bash variables
export vm_user=${vm_user} 
export app_repo=${app_repo}
export SQLAZURECONNSTR_DB_CONNECTION_STRING='${db_connection_string}'

# Install all dependencies
apt update -y
apt install -y git python3-venv python3-pip python3-dev build-essential libssl-dev libffi-dev python3-setuptools nginx

# Install Microsoft ODBC 18
curl https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc
curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list
sudo apt-get update
sudo ACCEPT_EULA=Y apt-get install -y msodbcsql18
sudo apt-get install -y unixodbc-dev

# Clone Git repo into app /var/www/app/
sleep 20
git clone $app_repo /var/www/app/
chown $vm_user:www-data -R /var/www/app/

# Create Python virtual environment and install dependencies
cd /var/www/app
python3 -m venv venv
source venv/bin/activate
pip install wheel
pip install -r requirements.txt
deactivate

# Generate Linux service config file
echo "[Unit]
Description=Gunicorn service to serve the app
After=network.target

[Service]
User=$vm_user
Group=www-data
WorkingDirectory=/var/www/app
Environment=\"PATH=/var/www/app/venv/bin\" \"SQLAZURECONNSTR_DB_CONNECTION_STRING=$SQLAZURECONNSTR_DB_CONNECTION_STRING\"
ExecStart=/var/www/app/venv/bin/gunicorn --bind unix:app.sock -m 007 wsgi:app

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/app.service

# Configure app as Linux service
systemctl start app
systemctl enable app
systemctl status app

# Configure NGINX to proxy requests to gunicorn service
rm /etc/nginx/sites-enabled/default
echo "server {
    listen 80;
    server_name localhost;

    location / {
        include proxy_params;
        proxy_pass http://unix:/var/www/app/app.sock;
    }
}" > /etc/nginx/sites-available/app
sudo ln -s /etc/nginx/sites-available/app /etc/nginx/sites-enabled

# Restart NGINX service
systemctl restart nginx