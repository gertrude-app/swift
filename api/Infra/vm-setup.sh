# Ubuntu 20.04 (@TODO - probably should just go full Docker at some point...)

adduser jared # entered password from buttercup, left everything else empty

usermod -aG sudo jared # grant sudo privs

ufw allow OpenSSH
ufw enable

su jared
mkdir -p ~/.ssh
rsync --archive --chown=jared:jared ~/.ssh /home/jared # copy over authorized keys
exit # back to root
echo "jared ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers # don't ask `jared` for sudo password

# install postgresql
su jared
sudo apt update
sudo apt install -y postgresql postgresql-contrib

# switch to created postgres user
sudo -i -u postgres
createuser jared #

# open psql shell for a hot second and then
ALTER USER jared WITH SUPERUSER;
\q; # exit psql shell
exit; # get back to being jared
createdb <dbname> # ... in order to create the database as jared

# then, INSIDE of the psql terminal i had to:
GRANT ALL PRIVILEGES ON DATABASE <dbname> TO jared; # maybe run this as postgres user?
\password jared # then type password twice
# my connection string was then (in .env) `DATABASE_URL=postgresql://<user>:<pass>@localhost/<dbname>`

# prevent "unattended upgrades" from upgrading postgres,
# because the api maintains a cache of previously prepared statements
# and an auto-upgrade restarts postgres, resulting in a cascade
# of `prepared statement plan X does not exist` errors
sudo vim /etc/apt/apt.conf.d/50unattended-upgrades
# add `"postgresql-";` (no backticks) INSIDE the "Package-Blacklist" block

# generate an ssh key to access github
su jared
ssh-keygen -t rsa -C "jared@netrivet.com"
# add pub key to github

# node things
curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g npm # update npm

# nginx
sudo apt install -y nginx
sudo ufw allow 'Nginx Full'

# make /etc/nginx/sites-available/default look like this:
```
server {
  server_name api.getrude.app;
  location / {
    proxy_pass http://127.0.0.1:8080;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_pass_header Server;
    proxy_connect_timeout 3s;
    proxy_cache_bypass $http_upgrade;
    proxy_read_timeout 10s;

    # nested websocket route gets longer timeout
    location /app {
      proxy_read_timeout 630s; # more than twice our app client websocket PING interval
    }
  }
}

server {
  server_name api--staging.getrude.app;
  location / {
    proxy_pass http://127.0.0.1:8090;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_pass_header Server;
    proxy_connect_timeout 3s;
    proxy_cache_bypass $http_upgrade;
    proxy_read_timeout 10s;

    # nested websocket route gets longer timeout
    location /app {
      proxy_read_timeout 630s; # more than twice our app client websocket PING interval
    }
  }
}
```

# then edit /etc/nginx/nginx.conf add the `map` block, as shown below
# for WEBSOCKET SUPPORT, @see https://github.com/vapor/vapor/issues/2482
```
# ... some stuff up here

http {

  # ... lots of stuff

  # 👋 somewhere ABOVE `include /etc/nginx/sites-enabled/*;` ADD THIS
  map $http_upgrade $connection_upgrade {
      default upgrade;
      '' close;
  }
  # END added block

  # below this line should ALREADY be there...
  include /etc/nginx/conf.d/*.conf;
  include /etc/nginx/sites-enabled/*;
}
```

# set timezone to EST for scheduled jobs, etc.
sudo timedatectl set-timezone America/New_York

# then install and run let's encrypt, letting it finish the config
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d api.getrude.app # choose 2 for https redirect
sudo certbot --nginx -d api--staging.getrude.app # choose 2 for https redirect
sudo systemctl reload nginx

# add 1GB of SWAP space (compiling swift takes a lot of memory)
# especially important for SMALL droplets
# the `1G` amount below should possibly be increased, if going to a larger droplet
# @see https://www.digitalocean.com/community/tutorials/how-to-add-swap-space-on-ubuntu-20-04
sudo fallocate -l 1G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
sudo sysctl vm.swappiness=10
sudo sysctl vm.vfs_cache_pressure=50
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf

# aws pg backup stuff
# install aws cli @see https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html
sudo apt install -y unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf ./aws
rm awscliv2.zip
# check with `aws --version`
# then configure with: (only answer FIRST TWO secret/id questions, leave others [NONE])
aws configure

# then
crontab -e
# add line `0 4 * * * /usr/bin/bash /home/jared/production/api/Infra/cron-backup-db.sh` to start backups

