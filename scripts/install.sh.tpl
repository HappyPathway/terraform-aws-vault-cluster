#!/usr/bin/env bash
set -e

# Setup the configuration
#consul conf
cat << EOF > /etc/vault.d/vault-consul.hcl
backend "consul" {
  address = "127.0.0.1:8500"
  path    = "vault-${hash}/"
}
EOF

#server conf
cat << EOF > /etc/vault.d/vault-server.hcl
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}
ui=true
EOF

#telemetry conf
#cat << EOF > /etc/vault.d/vault-telemetry.hcl
#telemetry {
#  statsd_address = "127.0.0.1:8125"
#}
#EOF

#kms conf
cat << EOF > /etc/vault.d/vault-kms.hcl
seal "awskms" {
  region     = "${region}"
  kms_key_id = "${kms_id}"
}
EOF

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
    -config=/etc/vault.d \
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
export VAULT_ADDR=http://127.0.0.1:8200
echo 'export VAULT_ADDR=http://127.0.0.1:8200 > /etc/profile.d/vault.sh'

function vault_init {
  root_token=$$(/usr/local/bin/vault operator init -stored-shares=1 -recovery-shares=1 -recovery-threshold=1 -key-shares=1 -key-threshold=1 | grep 'Initial Root Token: '| awk '{print $$NF }')
  echo $${root_token} > /tmp/vault.token
  consul kv put service/vault-${hash}/token $${root_token}
  sudo stop vault
  sudo start vault
}

consul kv get consul kv put service/vault-${hash}/token || vault_init
