# rest plugin for sshpiperd

The rest plugin for sshpiperd is a simple plugin that allows you to use a restful backend for authentication and challenge

The rest_challenge plugin will get a challenge from your rest backend and present it to the user
The rest_auth plugin will get the upstream/downstram configuration from your rest backend

Since the challenge backend is based on your rest webserver, you can add anything you like, from authenticators, sms, OTP, and so on. No need to use any other plugins.

## Usage

```
sshpiperd rest_challenge --url https://localhost:8443/challenge --insecure  -- rest_auth --url https://localhost:8443/auth --insecure
```

### options

```
   --url value URL for your rest endpoint, can be anything you like
   --insecure  allow insecure SSL
```

## challenge backend: GET URL/user (GET https://localhost:8443/challenge/arthur)

```json
{
  "message":"What is the airspeed velocity of an unladen swallow?"
}
```

## challenge backend: POST URL/user (POST https://localhost:8443/challenge/arthur)

```json
{
  "remoteAddr":"IP and Port of client",
  "uuid":"uniqueID of sshpiperd",
  "response":"response of the client (keyboard interactive)"
}
```

## skip challenge backend: GET URL/user (GET https://localhost:8443/challenge/arthur)

```json
{
  "challenge":false
}
```

## authentication backend: GET URL/user (GET https://localhost:8443/auth/arthur)

```json
{
  "user": "root",
  "host": "192.168.1.1:22",
  "method": "key",
  "ignoreHostKey": true,
  "authorizedKeys": "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDVEvuHaktOlL+GpF+JUlcX9N2f1b36moKkck7eV8Kgj root@c8e26162952a",
  "privateKey": "-----BEGIN OPENSSH PRIVATE KEY-----\r\nb3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW\r\nQyNTUxOQAAACDacsBgzwtW0WBIVrE/ZVWFr2w2287w1MoVJMueJgog1gAAAJjLTCf6y0wn\r\n+gAAAAtzc2gtZWQyNTUxOQAAACDacsBgzwtW0WBIVrE/ZVWFr2w2287w1MoVJMueJgog1g\r\nAAAEA7WWWE4AN6UIrkjbKa51tyuBNunmGc6W1IhUH0fQ/pz9pywGDPC1bRYEhWsT9lVYWv\r\nbDbbzvDUyhUky54mCiDWAAAAEXJvb3RAODhiNTBkOGM2MDc3AQIDBA==\r\n-----END OPENSSH PRIVATE KEY-----"
}
```