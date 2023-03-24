#!/bin/bash
apt-get update -y
apt-get install -y apache2
echo "<h1>Server created using Terraform with `hostname` Hostname at `date`.</h1>" > /var/www/html/index.html
echo "<br>This machine is controlled by AutoScaling Group created by ${name}.</br>" >> /var/www/html/index.html
echo "<br>This machine is controlled by AutoScaling Group has Firewall access managed using AWS Security Group with ID by ${security_group_id}.</br>" >> /var/www/html/index.html