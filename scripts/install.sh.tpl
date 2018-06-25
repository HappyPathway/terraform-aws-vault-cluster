#!/usr/bin/env bash
set -e

# Setup the configuration
#consul conf
hostname=$$(hostname)
ip_address=$$(ifconfig eth0 | grep "inet addr" | awk '{ print substr($2,6) }')

cat << EOF > /etc/consul.d/consul-join.hcl
{
    "retry_join": ["provider=aws tag_key=ConsulServer tag_value=${env}"]
}
EOF

cat << EOF > /etc/consul.d/consul-type.json
{
  "server": false
}
EOF

cat << EOF > /etc/consul.d/consul-node.json
{
  "advertise_addr": "$${ip_address}",
  "node_name": "$${hostname}"
}
EOF

cat << EOF > /etc/consul.d/consul-datacenter.json
{
  "datacenter": "${datacenter}"
}
EOF

if [ -z "${consul_token}" ]
then
cat << EOF > /etc/vault.d/vault-consul.hcl
backend "consul" {
  address = "127.0.0.1:8500"
  path    = "vault-${hash}/"
}
EOF
else
cat << EOF > /etc/vault.d/vault-consul.hcl
backend "consul" {
  address = "127.0.0.1:8500"
  path    = "vault-${hash}/"
  token = "${consul_token}"
}
EOF
fi


#kms conf
cat << EOF > /etc/vault.d/vault-kms.hcl
seal "awskms" {
  region     = "${region}"
  kms_key_id = "${kms_id}"
}
EOF

# Start Consul
sudo stop consul
sudo start consul

# Start Vault
sudo start vault
export VAULT_ADDR=http://127.0.0.1:8200
echo 'export VAULT_ADDR=http://127.0.0.1:8200 > /etc/profile.d/vault.sh'

function vault_init {
  echo "setting lock"
  consul kv put service/vault-${hash}/locked true
  echo "Running init"
  root_token=$$(/usr/local/bin/vault operator init -stored-shares=1 -recovery-shares=1 -recovery-threshold=1 -key-shares=1 -key-threshold=1 | grep 'Initial Root Token: '| awk '{print $$NF }')
  echo "Checking if token exists, if doesn't then set it"
  consul kv get service/vault-${hash}/token || consul kv put service/vault-${hash}/token $${root_token}
  echo "Stopping vault"
  sudo stop vault
  echo "Startinv Vault"
  sudo start vault
}

consul kv get service/vault-${hash}/locked 2>/dev/null || vault_init
sudo restart vault
