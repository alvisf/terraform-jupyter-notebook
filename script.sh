#!/bin/bash
sleep 1m
# Log stdout to file
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/home/ec2-user/terraform.log 2>&1
# Update AL2
sudo yum update -y
# Mount /anaconda3
sudo mkfs.xfs /dev/sdb -f
sudo mkdir /anaconda3
sudo mount /dev/sdb /anaconda3
sudo chown -R ec2-user:ec2-user /anaconda3
sudo echo "UUID=$(lsblk -nr -o UUID,MOUNTPOINT | grep "/anaconda3" | cut -d ' ' -f 1) /anaconda3 xfs defaults,nofail 1 2" >> /etc/fstab
# Install Anaconda
wget https://repo.anaconda.com/archive/Anaconda3-2018.12-Linux-x86_64.sh -O /home/ec2-user/anaconda.sh &&
    bash /home/ec2-user/anaconda.sh -u -b -p /anaconda3 &&
    echo 'export PATH="/anaconda3/bin:$PATH"' >> /home/ec2-user/.bashrc &&
    rm -rf /home/ec2-user/anaconda.sh &&
# Configure Jupyter for AWS HTTP
runuser -l ec2-user -c 'jupyter notebook --generate-config' &&
    sed -i -e "s/#c.NotebookApp.ip = 'localhost'/c.NotebookApp.ip = '"$(curl http://169.254.169.254/latest/meta-data/public-hostname)"'/g" /home/ec2-user/.jupyter/jupyter_notebook_config.py &&
    sed -i -e "s/#c.NotebookApp.allow_origin = ''/c.NotebookApp.allow_origin = '*'/g" /home/ec2-user/.jupyter/jupyter_notebook_config.py &&
    sed -i -e "s/#c.NotebookApp.open_browser = True/c.NotebookApp.open_browser = False/g" /home/ec2-user/.jupyter/jupyter_notebook_config.py
    
   
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_COLLATE=C
export LC_CTYPE=en_US.UTF-8
sudo yum -y install automake fuse fuse-devel gcc-c++ git libcurl-devel libxml2-devel make openssl-devel

git clone https://github.com/s3fs-fuse/s3fs-fuse.git

cd s3fs-fuse
./autogen.sh
./configure -prefix=/usr -with-openssl
make
sudo make install

sudo touch /etc/passwd-s3fs
echo "<key>:<secrect>" | sudo tee -a /etc/passwd-s3fs
sudo chmod 640 /etc/passwd-s3fs

sudo mkdir /mys3bucket
sed -i -e "s/#c.Application.allow_admin = False/c.Application.allow_admin = True/g" /home/ec2-user/.jupyter/jupyter_notebook_config.py
sudo s3fs test-jupyter-conn -o use_cache=/tmp -o allow_other -o uid=1000 -o mp_umask=002 -o multireq_max=5 /mys3bucket
