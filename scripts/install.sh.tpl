#!/usr/bin/env bash
set -e

# Install packages
sudo apt-get update -y
sudo apt-get install -y curl unzip

# Download Vault into some temporary directory
curl -L "${consul_download_url}" > /tmp/consul.zip
curl -L "${vault_download_url}" > /tmp/vault.zip

# Unzip it
cd /tmp
sudo unzip vault.zip
sudo unzip consul

sudo mv vault /usr/local/bin
sudo mv consul /usr/local/bin

sudo chmod 0755 /usr/local/bin/vault
sudo chown root:root /usr/local/bin/vault

sudo chmod 0755 /usr/local/bin/consul
sudo chown root:root /usr/local/bin/consul

# Setup the configuration
cat <<EOF >/tmp/vault-config
${config}
EOF
sudo mv /tmp/vault-config /usr/local/etc/vault-config.json


# Setup the init scripts
cat <<EOF >/tmp/consul_upstart
description "Consul Agent"

start on runlevel [2345]
stop on runlevel [!2345]

respawn

script
  if [ -f "/etc/service/consul" ]; then
    . /etc/service/consul
  fi

  # Make sure to use all our CPUs, because Vault can block a scheduler thread
  export GOMAXPROCS=`nproc`
  BIND=`ifconfig eth0 | grep "inet addr" | awk '{ print substr($2,6) }'`
  exec /usr/local/bin/consul agent \
    -join=${consul_cluster} \
    -bind=\$${BIND} \
    -config-dir="/etc/consul.d" \
    -data-dir=/opt/consul/data \
    -client 0.0.0.0 \
    >>/var/log/consul.log 2>&1
end script
EOF

cat <<EOF >/tmp/vault_upstart
description "Vault server"

start on runlevel [2345]
stop on runlevel [!2345]

respawn

script
  if [ -f "/etc/service/vault" ]; then
    . /etc/service/vault
  fi

  # Make sure to use all our CPUs, because Vault can block a scheduler thread
  export GOMAXPROCS=`nproc`

  exec /usr/local/bin/vault server \
    -config="/usr/local/etc/vault-config.json" \
    \$${VAULT_FLAGS} \
    >>/var/log/vault.log 2>&1
end script
EOF

sudo mv /tmp/vault_upstart /etc/init/vault.conf
sudo mv /tmp/consul_upstart /etc/init/consul.conf

# Extra install steps (if any)
${extra-install}

# Start Consul
sudo start consul

# Start Vault
sudo start vault
root_token=$$(/usr/local/bin/vault operator init -stored-shares=1 -recovery-shares=1 -recovery-threshold=1 -key-shares=1 -key-threshold=1 | grep 'Initial Root Token: '| awk '{print $$NF }')
consul kv put service/vault/token $${root_token}
sudo stop vault
sudo start vault