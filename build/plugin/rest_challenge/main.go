package main

import (
	"bytes"
	"encoding/json"
	"io/ioutil"
	"net/http"
	"fmt"
	"github.com/tg123/sshpiper/libplugin"
	"github.com/urfave/cli/v2"
	"github.com/fatih/color"
)

func main() {

	libplugin.CreateAndRunPluginTemplate(&libplugin.PluginTemplate{
		Name:  "rest_challenge",
		Usage: "sshpiperd rest_challenge plugin for additional authentication challenge",
		Flags: []cli.Flag{
			&cli.StringFlag{
				Name:    "url",
				Usage:   "URL to a REST endpoint (ie. https://domain.com/v1/sshpiperd/challenge) to challenge the connection",
				Value:   "https://localhost:8443/challenge",
				EnvVars: []string{"REST_CHALLENGE_URL"},
			},
		},
		CreateConfig: func(c *cli.Context) (*libplugin.SshPiperPluginConfig, error) {
			return &libplugin.SshPiperPluginConfig{
				KeyboardInteractiveCallback: func(conn libplugin.ConnMetadata, client libplugin.KeyboardInteractiveChallenge) (*libplugin.Upstream, error) {		
					
					for {
						resp, err := http.Get(c.String("url") + fmt.Sprintf("/%s", conn.User()))
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

							if result["challenge"] == false {
								return &libplugin.Upstream{
									Auth: libplugin.CreateNextPluginAuth(map[string]string{
										"challenge": "false",
									}),
								}, nil
							}else{
								_, _ = client("", color.RedString("warning"), "", false)

								response, err := client("", "", fmt.Sprintf("%v\n", result["message"]), true)

								if err != nil {
									return nil, err
								}
						
								values := map[string]string{"response": response}
								post, err := json.Marshal(values)
								if err != nil {
									return nil, err
								}
								resp, err := http.Post(c.String("url") + fmt.Sprintf("/%s", conn.User()), "application/json", bytes.NewBuffer(post) )
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

									if result["authenticated"] == true {
										return &libplugin.Upstream{
											Auth: libplugin.CreateNextPluginAuth(map[string]string{
												"response": response,
											}),
										}, nil
									}else{
										return nil, err
									}
								} else {
									return nil, err
								}
							}			
					
						} else {
							return nil, err
						}
					}
				},
			}, nil
		},
	})
}
