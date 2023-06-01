package main

import (
	"bytes"
	"encoding/json"
	"io/ioutil"
	"net/http"
	"net/url"
	"crypto/tls"
	"fmt"
	"github.com/tg123/sshpiper/libplugin"
	"golang.org/x/crypto/ssh"
)

type plugin struct {
	URL        string
	Insecure bool
}

type piperFrom struct {
	Method string
	User string
}

type piperTo struct {
	Method string
	User string
	Password string
	Host string
	IgnoreHostKey bool
	AuthorizedKeys string
	PrivateKey string
}

func newRestAuthPlugin() *plugin{
	return &plugin{

	}
}

func (p *plugin) supportedMethods() ([]string, error) {
	set := make(map[string]bool)

	set["publickey"] = true
	set["password"] = true

	var methods []string
	for k := range set {
		methods = append(methods, k)
	}
	return methods, nil
}

func (p *plugin) findAndCreateUpstream(conn libplugin.ConnMetadata, password string, publicKey []byte) (*libplugin.Upstream, error) {
	http.DefaultTransport.(*http.Transport).TLSClientConfig = &tls.Config{InsecureSkipVerify: p.Insecure}
	user := conn.User()
	resp, err := http.Get(p.URL + fmt.Sprintf("/%s", url.QueryEscape(user)))
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	if resp.StatusCode == 200 {
		body, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			return nil, err
		}
		var result map[string]interface{}
		json.Unmarshal([]byte(body), &result)

		from := piperFrom{
			Method:fmt.Sprint(result["method"]),
		}

		if from.Method == "key" {
			to := piperTo{
				User:fmt.Sprint(result["user"]),
				Host:fmt.Sprint(result["host"]),
				IgnoreHostKey:p.fromJsonBool(fmt.Sprint(result["ignoreHostKey"])),
				AuthorizedKeys:fmt.Sprint(result["authorizedKeys"]),
				PrivateKey:fmt.Sprint(result["privateKey"]),
			}
			rest, err := p.strToByte(to.AuthorizedKeys, map[string]string{
				"DOWNSTREAM_USER": user,
			})
			if err != nil {
				return nil, err
			}
			var authedPubkey ssh.PublicKey
			for len(rest) > 0 {
				authedPubkey, _, _, rest, err = ssh.ParseAuthorizedKey(rest)
				if err != nil {
					return nil, err
				}
				if bytes.Equal(authedPubkey.Marshal(), publicKey) {
					return p.createUpstream(conn, to, true)
				}
			}
		}else{
			to := piperTo{
				User:fmt.Sprint(result["user"]),
				Password:fmt.Sprint(result["password"]),
				IgnoreHostKey:p.fromJsonBool(fmt.Sprint(result["ignoreHostKey"])),
			}
			return p.createUpstream(conn, to, false)
		}
	}else {
		return nil, err
	}
	return nil, fmt.Errorf("no matching pipe for username [%v] found", user)
}

func (p *plugin) createUpstream(conn libplugin.ConnMetadata, to piperTo, useKey bool) (*libplugin.Upstream, error) {

	host, port, err := libplugin.SplitHostPortForSSH(to.Host)
	if err != nil {
		return nil, err
	}

	u := &libplugin.Upstream{
		Host:          host,
		Port:          int32(port),
		UserName:      to.User,
		IgnoreHostKey: to.IgnoreHostKey,
	}

	if useKey {
		data, err := p.strToByte(to.PrivateKey, map[string]string{
			"DOWNSTREAM_USER": conn.User(),
			"UPSTREAM_USER":   to.User,
		})
		if err != nil {
			return nil, err
		}
	
		if data != nil {
			u.Auth = libplugin.CreatePrivateKeyAuth(data)
			return u, nil
		}
	}else{
		u.Auth = libplugin.CreatePasswordAuth([]byte(to.Password))
		return u, nil
	}
	

	return nil, fmt.Errorf("no password or private key found")
}

func (p *plugin) strToByte(cert string, vars map[string]string) ([]byte, error) {
	return []byte(cert), nil
}

func (p *plugin) fromJsonBool(b string) (bool) {
	if b == "true"{
		return true
	}
	return false
}