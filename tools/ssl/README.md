# SSL Certificate Setup for flagtickgroup.com

## Verify Your Domain's DNS Records
Ensure that `flagtickgroup.com` and `www.flagtickgroup.com` are correctly pointed to the server's IP (`18.142.229.15`). Run the following command to verify:

```shell
dig +short flagtickgroup.com
dig +short www.flagtickgroup.com
```
If the output does not match 18.142.229.15, update your DNS records and wait for propagation before proceeding. Go to Cloudflare and modify 
the A record to point to the current IP of the remote server running Ubuntu.
```shell

```

## Connect to Your Server and Install Certbot
Once the DNS records are correct, SSH into your remote server and install Certbot with the following commands:

```shell
ssh -i "C:\Users\admin\Documents\flagtickgroup.suite.vc\tools\ssh\rsa.pem" ec2-user@18.142.229.15
sudo apt update
sudo apt install -y certbot python3-certbot-nginx
```
Replace `user` with your actual username if necessary. Now, you're ready to proceed with SSL certificate issuance. 🚀

## Generate an SSL Certificate
Run
```shell
sudo certbot certonly --nginx -d flagtickgroup.com -d www.flagtickgroup.com
```

## Wildcard SSL Certificate
If you need a wildcard certificate (for *.flagtickgroup.com), use the manual DNS challenge:
```shell
sudo certbot certonly --manual --preferred-challenges=dns \
-d flagtickgroup.com -d *.flagtickgroup.com
```

During the process, Certbot will prompt you to add a TXT record in your domain's DNS settings.

```shell
sudo certbot certonly --manual --preferred-challenges=dns -d flagtickgroup.com -d *.flagtickgroup.com
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Requesting a certificate for flagtickgroup.com and *.flagtickgroup.com

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Please deploy a DNS TXT record under the name:

_acme-challenge.flagtickgroup.com.

with the following value:

PnZGRwBQsyfBzKc-53lH6CXBDIK5iG0TML7gSr1z5k0

Before continuing, verify the TXT record has been deployed. Depending on the DNS
provider, this may take some time, from a few seconds to multiple minutes. You can
check if it has finished deploying with aid of online tools, such as the Google
Admin Toolbox: https://toolbox.googleapps.com/apps/dig/#TXT/_acme-challenge.flagtickgroup.com.
Look for one or more bolded line(s) below the line ';ANSWER'. It should show the
value(s) you've just added.

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Press Enter to Continue
```
Add TXT Record
   1. Go to Cloudflare DNS settings (or your DNS provider).
   2. Add a TXT record with:
      Name: _acme-challenge.flagtickgroup.com
      Value: PnZGRwBQsyfBzKc-53lH6CXBDIK5iG0TML7gSr1z5k0
   3. Wait for DNS propagation, then press Enter to continue and validate.

Press Enter
```shell
Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/flagtickgroup.com-0001/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/flagtickgroup.com-0001/privkey.pem
This certificate expires on 2025-06-04.
These files will be updated when the certificate renews.

NEXT STEPS:
- This certificate will not be renewed automatically. Autorenewal of --manual certificates requires the use of an authentication hook script (--manual-auth-hook) but one was not provid
ed. To renew this certificate, repeat this same certbot command before the certificate's expiry date.

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
If you like Certbot, please consider supporting our work by:
 * Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
 * Donating to EFF:                    https://eff.org/donate-le
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
```

## SCP with a Custom SSH Key (-i option) Using SSH Key
```shell
sudo chmod 644 /etc/letsencrypt/live/flagtickgroup.com-0001/fullchain.pem
sudo chmod 644 /etc/letsencrypt/live/flagtickgroup.com-0001/privkey.pem

sudo cp /etc/letsencrypt/live/flagtickgroup.com-0001/fullchain.pem /home/ubuntu/fullchain.pem
sudo cp /etc/letsencrypt/live/flagtickgroup.com-0001/privkey.pem /home/ubuntu/privkey.pem

scp -i "C:\Users\admin\Documents\eco\flagtickgroup.nexus.vc\tools\ssh\rsa.pem" ubuntu@47.129.59.175:/home/ubuntu/fullchain.pem C:\Users\admin\Documents\eco\flagtickgroup.nexus.vc\tools\ssh\flagtickgroup.com.crt
scp -i "C:\Users\admin\Documents\eco\flagtickgroup.nexus.vc\tools\ssh\rsa.pem" ubuntu@47.129.59.175:/home/ubuntu/privkey.pem C:\Users\admin\Documents\eco\flagtickgroup.nexus.vc\tools\ssh\flagtickgroup.com.key
```

**Note:** Modify the A record for `flagtickgroup.com` in Cloudflare to point to the correct IP address instead of 
the temporary Ubuntu server, allowing Certbot to generate a wildcard SSL certificate.
Furthermore, since Nginx is used for Certbot on the remote server, remove it to avoid conflicts with the GitHub Actions pipeline.
```shell
sudo lsof -i :80
sudo systemctl stop nginx
sudo systemctl disable nginx
```
