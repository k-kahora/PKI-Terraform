# TODO 
- [ ] Store the state file in Terraform HPC Cloud
- [ ] Use container behind a proxy
- [ ] Have a highly available database setup
# Docker hub ami
https://hub.docker.com/r/keyfactor/ejbca-ce
## Steps to build

``` shell
terraform apply
```

- Log into the server using instance connect
- Install maria db client and create the database, the username and password should be in the variables-file
- db-endpoint is outputted by terraform

``` shell
sudo apt update
apt install mariadb-client -y
mysql -h <db-endpoint> -u <db-username> -p (enter <dp-password>)
# (Enter <db-password> when prompted)
CREATE DATABASE ejbca;
exit
```
- Run ejbca with the following

``` shell

sudo docker run -it --rm \
  -p 80:8080 -p 443:8443 \
  -h mycahostname \
  -e TLS_SETUP_ENABLED="true" \
  -e DATABASE_JDBC_URL="jdbc:mariadb://<db-endpoint>:3306/ejbca?characterEncoding=UTF-8" \
  -e DATABASE_USER="<db-user>" \
  -e DATABASE_PASSWORD="<db-password>" \
  keyfactor/ejbca-ce

```
On launch and when the container finishes go do where mycahostname is the public ip of the ec2 instance
https://mycahostname:443/ejbca/ra/enrollwithusername.xhtml?username=superadmin

- The initial password can be found in the EC2 instance's system logs or console output.
follow these instructions to setup up to step 3
https://docs.keyfactor.com/ejbca/latest/quick-start-guide-start-ejbca-container-with-clien

- Since the database is external (separate from the container), you can stop and restart the EJBCA container without data loss.
- Currently, the Terraform architecture includes only one EC2 instance and one RDS database to minimize AWS charges.
 
![alt text](./diagrams/vpn.drawio.png "VPN")




