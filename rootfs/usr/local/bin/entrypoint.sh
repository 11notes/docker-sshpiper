#!/bin/ash
  if [ -z "${SSHPIPERD_SERVER_KEY}" ]; then
    if [ ! -f /etc/ssh/ssh_host_ed25519_key ];then
        ssh-keygen -t ed25519 -N '' -f /etc/ssh/ssh_host_ed25519_key
    fi
  fi

  exec "$@"