set -eu 

export DEVICE_NAME=${DEVICE_NAME:-/dev/sda}
export IGNITION_FILE=${IGNITION_FILE:-bootstrap.ign} # bootstrap.ign  master.ign  worker.ign 
export IGNITION_URL=${IGNITION_URL:-http://192.168.101.9:8080/ignition/${IGNITION_FILE}}

sudo coreos-installer install ${DEVICE_NAME} \
  --insecure-ignition \
  --ignition-url=${IGNITION_URL} \
  --firstboot-args rd.neednet=1 \
  --copy-network
