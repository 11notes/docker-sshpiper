package main

import (
	"os"

	"github.com/11notes/go-eleven"
)

const APP_ROOT = "/usr/local/bin"
const APP_BIN = "sshpiperd"

func main(){
	// enable environment variable DEBUG
	logLevel := "info"
	if _, ok := os.LookupEnv("DEBUG"); ok {
		logLevel = "debug"
	}

	// run app
	eleven.Container.Run(APP_ROOT, APP_BIN, []string{"/usr/local/bin/sshpiperd", "--server-key", "/run/secrets/ssh_host_key", "--log-format", "json", "--drop-hostkeys-message", "--reply-ping", "--port", "22", "--log-level", logLevel})
}