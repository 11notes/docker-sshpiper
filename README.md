# Alpine :: SSH proxy via sshpiperd & REST
![pulls](https://img.shields.io/docker/pulls/11notes/sshpiperd?color=2b75d6) ![build](https://img.shields.io/docker/automated/11notes/sshpiperd?color=2b75d6) ![activity](https://img.shields.io/github/commit-activity/m/11notes/docker-sshpiperd?color=c91cb8) ![commit-last](https://img.shields.io/github/last-commit/11notes/docker-sshpiperd?color=c91cb8)

Run a SSH proxy based on Alpine Linux. Small, lightweight, secure and fast 🏔️

The rest plugin for sshpiperd is a simple plugin that allows you to use a restful backend for authentication and challenge. The rest_challenge plugin will get a challenge from your rest backend and present it to the user. The rest_auth plugin will get the upstream/downstream configuration from your rest backend. Since the challenge backend is based on your rest webserver, you can add anything you like, from authenticators, SMS OTP, and so on. No need to use any other plugins.
The auth backend only supports public key authentication!

## Run
```shell
docker run --name sshpiper \
  -d 11notes/sshpiper:[tag] \
    sshpiperd \
      rest_challenge --url https://localhost:8443/challenge  -- \
      rest_auth --url https://localhost:8443/auth
```

## Defaults
| Parameter | Value | Description |
| --- | --- | --- |
| `user` | docker | user docker |
| `uid` | 1000 | user id 1000 |
| `gid` | 1000 | group id 1000 |
| `home` | /sshpiperd | home directory of user docker |

## Environment
| Parameter | Value | Default |
| --- | --- | --- |
| `SSHPIPERD_SERVER_KEY` | ed25519 server key | /etc/ssh/ssh_host_ed25519_key |
| `REST_CHALLENGE_URL` | URL to call for the challenge | "" |
| `REST_CHALLENGE_INSECURE` | validate SSL certificate | "" |
| `REST_AUTH_URL` | URL to call for the authentication | "" |
| `REST_AUTH_INSECURE` | validate SSL certificate | "" |

### Options
```
   --url value URL for your rest endpoint, can be anything you like
   --insecure  allow insecure SSL (do not validate SSL certificate)
```

## Challenge backend: GET https://localhost:8443/challenge/arthur
Upon connection the challenge plugin will send a get request to your endpoint with the /username in the URL that is connecting from the downstream. The content of "message" is then displayed to the user in the session.

```json
{
  "message":"What is the airspeed velocity of an unladen swallow?"
}
```

## Challenge backend: POST https://localhost:8443/challenge/arthur
The user types his response and after hitting enter the plugin will send a post request to your endpoint including /username in the URL. The following data is sent back to your endpoint.

```json
{
  "remoteAddr":"IP and Port of client",
  "uuid":"uniqueID of sshpiperd",
  "response":"response of the client (keyboard interactive)"
}
```

The response is either true or false
```json
{
  "auth":true
}
```

## Skip challenge backend: GET https://localhost:8443/challenge/arthur
You can skip the challenge for a specific connection if you like. For that, instead of sending back the “message” at the first request, just send back the following data.

```json
{
  "challenge":false
}
```

## Authentication backend: GET https://localhost:8443/auth/arthur
To get the upstream/downstream configuration for the user, your endpoint has to send back the following data. You can either use key authentication or password authentication.

```json
{
  "user": "root",
  "host": "192.168.1.1:22",
  "authorizedKeys": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDVEvuHaktOlL+GpF+JUlcX9N2f1b36moKkck7eV8Kgj root@c8e26162952a",
  "privateKey": "-----BEGIN OPENSSH PRIVATE KEY-----\r\nb3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW\r\nQyNTUxOQAAACDacsBgzwtW0WBIVrE/ZVWFr2w2287w1MoVJMueJgog1gAAAJjLTCf6y0wn\r\n+gAAAAtzc2gtZWQyNTUxOQAAACDacsBgzwtW0WBIVrE/ZVWFr2w2287w1MoVJMueJgog1g\r\nAAAEA7WWWE4AN6UIrkjbKa51tyuBNunmGc6W1IhUH0fQ/pz9pywGDPC1bRYEhWsT9lVYWv\r\nbDbbzvDUyhUky54mCiDWAAAAEXJvb3RAODhiNTBkOGM2MDc3AQIDBA==\r\n-----END OPENSSH PRIVATE KEY-----"
}
```

### Authentication backend parameters
| Parameter | Description | Example |
| --- | --- | --- |
| `user` | The name of the upstream user | *root*, *no-standard-username@myserver* |
| `host` | IP:Port of the upstream server | *10.0.0.125:22*, *192.168.1.10:678* |
| `authorizedKeys` | A list of authorized downstream public keys (can be multiple use \r\n) | *ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AA........* |
| `privateKey` | The private key for the upstream connection | *-----BEGIN OPENSSH PRIVATE KEY-----\r\nb3BlbnNz.....* |


# Express example
```js
...
app.get('/:user', (req, res, next) => {
  res.json({hello:`Hi ${req.params.user}, what is the airspeed velocity of an unladen swallow?`});
});
app.post('/:user', (req, res, next) => {
  if(/20\.1mph|20\.1|20|32.35kmh|32.35|32/i.test(req.body.response)){
    res.json({auth:true});
  }else{
    res.json({auth:false});
  }
});
...
```

# Possible high-available solution
This is a possible scenario on how to implement a high-available sshpiper infrastructure (running on multiple nodes). As LB you could use haproxy or traefik, both using sticky sessions for the sshpiper part.

```mermaid
flowchart TD
    A[WAN]:::WAN -->|:22| B(LB HA pair):::LB
    B -->|:22| C(sshpiper #1):::SSH
    B -->|:22| D(sshpiper #2):::SSH
    B -->|:22| E(sshpiper #n):::SSH
    C -->|:8443| F(LB HA pair):::LB
    D -->|:8443| F(LB HA pair)
    E -->|:8443| F(LB HA pair)
    F -->|:8443| G(REST #1):::REST
    F -->|:8443| H(REST #2):::REST
    F -->|:8443| I(REST #n):::REST
    E -->|:22| J(destination server):::DESTINATION

    classDef WAN fill:#FF0000,stroke:none,color#FFF
    classDef LB fill:#0099CC,stroke:none,color:#FFF
    classDef SSH fill:#00CC33,stroke:none,color:#FFF
    classDef REST fill:#9900CC,stroke:none,color:#FFF
    classDef DESTINATION fill:#000000,stroke:none,color:#FFF  
```

## Built with
* [sshpiper](https://github.com/tg123/sshpiper)
* [Alpine Linux](https://alpinelinux.org/)

## Tips
* Only use rootless container runtime (podman, rootless docker)
* Don't bind to ports < 1024 (requires root), use NAT/reverse proxy (haproxy, traefik, nginx)