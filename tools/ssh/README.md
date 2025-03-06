Copy the plaintext from C:\Users\admin\Documents\eco\flagtickgroup.nexus.vc\tools\ssh\rsa.pub, 
paste it into your LightSail VPS, and rename the file to authorized_keys (Using vi <file>)

# ssh -i "C:\Users\admin\Documents\eco\flagtickgroup.nexus.vc\tools\ssh\rsa.pem" ubuntu@18.139.110.191
# scp -i "C:\Users\admin\Documents\eco\flagtickgroup.nexus.vc\tools\ssh\rsa.pem" "C:\Users\admin\Documents\eco\flagtickgroup.nexus.vc\tools\ssh\rsa.pem" ubuntu@18.139.110.191:~/.ssh/

Note for Building on a New VPS:
- Approve the SSH key at GitHub SSH Keys.
- Add GitHub to the known_hosts file in the remote server's .ssh directory.
