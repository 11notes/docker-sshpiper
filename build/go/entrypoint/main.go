package main

import (
	"os"
	"syscall"

	"github.com/11notes/go"
)

var(
	Eleven eleven.New = eleven.New{}
)

func main(){
	// enable environment variable DEBUG
	logLevel := "info"
	if _, ok := os.LookupEnv("DEBUG"); ok {
		logLevel = "debug"
	}

	// set default parameters for sshpiperd
	cmd := Eleven.Container.Command([]string{"/usr/local/bin/sshpiperd", "--server-key", "/run/secrets/ssh_host_key", "--log-format", "json", "--drop-hostkeys-message", "--reply-ping", "--port", "22", "--log-level", logLevel})

	// fork to foreground
	if err := syscall.Exec("/usr/local/bin/sshpiperd", cmd, os.Environ()); err != nil {
		os.Exit(1)
	}
}