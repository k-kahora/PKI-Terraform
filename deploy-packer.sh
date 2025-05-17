AWS_PROFILE=admin-pki

# packer build -var 'tls_mode=simple' -var 'hostname=mycahostname' ./packer/
packer build ./packer/

