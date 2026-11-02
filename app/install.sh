
#!/bin/bash
set -e

# 1. Install Python and pip
sudo dnf install -y python3 python3-pip

# 2. Check Python
python3 --version

# 3. Create application directory
sudo mkdir -p /opt/pythonapp
sudo cp /tmp/app.py /opt/pythonapp/app.py
sudo cp /tmp/requirements.txt /opt/pythonapp/requirements.txt
sudo chown -R ec2-user:ec2-user /opt/pythonapp

# 4. Create virtual environment
python3 -m venv /opt/pythonapp/venv

# 5. Install dependencies
/opt/pythonapp/venv/bin/pip install \
  -r /opt/pythonapp/requirements.txt

# 6. Create Linux service
sudo tee /etc/systemd/system/pythonapp.service > /dev/null <<'EOF'
[Unit]
Description=FastAPI Application
After=network.target

[Service]
User=ec2-user
WorkingDirectory=/opt/pythonapp
ExecStart=/opt/pythonapp/venv/bin/python -m uvicorn app:app --host 0.0.0.0 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 7. Start application
sudo systemctl daemon-reload
sudo systemctl enable pythonapp
sudo systemctl restart pythonapp

echo "FastAPI deployment completed!"
