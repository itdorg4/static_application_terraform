import paramiko, os

HOST = os.environ.get("SSH_HOST")
USER = os.environ.get("SSH_USER", "ubuntu")
KEY  = os.environ.get("SSH_KEY_NAME")
PEM_DIR  = os.environ.get("PEM_DIR")
DIR  = os.path.dirname(os.path.abspath(__file__))

pem_file_path = os.path.expanduser(os.path.join(PEM_DIR, KEY))

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())


ssh.connect(HOST, username=USER, key_filename=pem_file_path)

def run(cmd):
    _, out, err = ssh.exec_command(cmd)
    print(out.read().decode(), err.read().decode())

# 1. Install nginx if not installed
run("which nginx || (sudo apt-get update && sudo apt-get install -y nginx)")

# Upload files to /tmp first (no root needed there)
sftp = ssh.open_sftp()
sftp.put(os.path.join(DIR, "it-defined.com.conf"), "/tmp/it-defined.com.conf")
sftp.put(os.path.join(DIR, "index.html"), "/tmp/index.html")
sftp.close()

# 2. Setup Nginx config for it-defined.com (and remove default site)
run("sudo mv /tmp/it-defined.com.conf /etc/nginx/sites-available/it-defined.com")
run("sudo ln -sf /etc/nginx/sites-available/it-defined.com /etc/nginx/sites-enabled/it-defined.com")
run("sudo rm -f /etc/nginx/sites-enabled/default")

# 3. Copy the code to /var/www/it-defined.com
run("sudo mkdir -p /var/www/it-defined.com")
run("sudo mv /tmp/index.html /var/www/it-defined.com/index.html")

# Reload nginx
run("sudo nginx -t && sudo systemctl reload nginx")

ssh.close()
print("Done")
