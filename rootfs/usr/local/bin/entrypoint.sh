#!/bin/ash
set -eo pipefail

if [ -z "${SSHPIPERD_SERVER_KEY}" ]; then
    SSHPIPERD_SERVER_KEY=/sshpiderd/etc/ssh_host_rsa_key
    ssh-keygen -t rsa -N '' -f ${SSHPIPERD_SERVER_KEY}
fi

exec "$@"