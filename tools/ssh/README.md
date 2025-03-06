Copy the plaintext from C:\Users\admin\Documents\eco\flagtickgroup.nexus.vc\tools\ssh\rsa.pub, 
paste it into your LightSail VPS, and rename the file to authorized_keys (Using vi <file>)

# ssh -i "C:\Users\admin\Documents\eco\flagtickgroup.nexus.vc\tools\ssh\rsa.pem" ubuntu@47.129.59.175
# scp -i "C:\Users\admin\Documents\eco\flagtickgroup.nexus.vc\tools\ssh\rsa.pem" "C:\Users\admin\Documents\eco\flagtickgroup.nexus.vc\tools\ssh\rsa.pem" ubuntu@47.129.59.175:~/.ssh/

Note for Building on a New VPS:
- Approve the SSH key at GitHub SSH Keys.
- Add GitHub to the known_hosts file in the remote server's .ssh directory.

# Since you're running Ubuntu 24.04 LTS (Noble Numbat), the issue occurs because Docker has not yet officially released packages for Ubuntu 24.04. 
The containerd.io package is missing from the default repositories.
```shell
cat /etc/os-release

PRETTY_NAME="Ubuntu 24.04.1 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.1 LTS (Noble Numbat)"
VERSION_CODENAME=noble
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=noble
LOGO=ubuntu-logo
```

=> Need to update deploy.sh file.

## Add Swap Space (If Low RAM) [Nexus Repository]
```shell
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

sudo docker logs nexus

## Navigate to the Networking tab and configure the IPv4 Firewall in the instance where the public IP is accessible on Lightsail.
- SSH : TCP : 22
- HTTP : TCP : 80
- HTTPS : TCP : 443 

## Add Nexus Domain to Hosts File: Mapping 47.129.59.175 to nexus.flagtickgroup.com in /etc/hosts.

## Change the A record for `nexus.flagtickgroup.com` in Cloudflare to point to the IP address `47.129.59.175`.
