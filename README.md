# TODO 
- Store the state file in Terraform HPC Cloud
- Needed to run aws-cli with sso configuration set up
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
sudo apt install mariadb-client -y
mysql -h <db-endpoint> -u <db-username> -p (enter <dp-password>)
CREATE DATABASE ejbca;
exit
```
- Run ejbca with the following

``` shell

sudo docker run -it --rm \
  -p 80:8080 -p 443:8443 \
  -h mycahostname \
  -e TLS_SETUP_ENABLED="true" \
  -e DATABASE_JDBC_URL="jdbc:mariadb://<RDS-endpoint>:3306/ejbca?characterEncoding=UTF-8" \
  -e DATABASE_USER="<db-user>" \
  -e DATABASE_PASSWORD="<db-password>" \
  keyfactor/ejbca-ce

```
On launch and when the container finishes go do where mycahostname is the public ip of the ec2 instance
https://mycahostname:443/ejbca/ra/enrollwithusername.xhtml?username=superadmin

the password should be in the console of the running ec2 instance
follow these instructions to setup up to step 3
https://docs.keyfactor.com/ejbca/latest/quick-start-guide-start-ejbca-container-with-clien

because the database is seperate taking down the docker image an restarting it should not be an issue, below is the diagram of the current terrafomr architeture, their is only one ec2 and database rn because any more could incur charges
 
![alt text](./diagrams/vpn.drawio.png "VPN")




