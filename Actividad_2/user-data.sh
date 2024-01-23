#!/bin/bash
sudo yum update -y
sudo yum install -y httpd
num=$RANDOM
echo "<html><h1 align='center'> Hello world from $num </h1></html>" > /var/www/html/index.html
sudo systemctl enable httpd
sudo systemctl start httpd