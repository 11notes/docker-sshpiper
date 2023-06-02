# rest plugin for sshpiperd

The rest plugin for sshpiperd is a simple plugin that allows you to use a restful backend for authentication and challenge

The rest_challenge plugin will get a challenge from your rest backend and present it to the user
The rest_auth plugin will get the upstream/downstream configuration from your rest backend

Since the challenge backend is based on your rest webserver, you can add anything you like, from authenticators, SMS OTP, and so on. No need to use any other plugins.

## Usage

```
sshpiperd rest_challenge --url https://localhost:8443/challenge --insecure  -- rest_auth --url https://localhost:8443/auth --insecure
```

### options

```
   --url value URL for your rest endpoint, can be anything you like
   --insecure  allow insecure SSL
```

## challenge backend: GET https://localhost:8443/challenge/arthur

Upon connection the challenge plugin will send a get request to your endpoint with the /username in the URL that is connecting from the downstream. The content of "message" is then displayed to the user in the session.

```json
{
  "message":"What is the airspeed velocity of an unladen swallow?"
}
```

## challenge backend: POST https://localhost:8443/challenge/arthur

The user types his response and after hitting enter the plugin will send a post request to your endpoint including /username in the URL. The following data is sent back to your endpoint.

```json
{
  "remoteAddr":"IP and Port of client",
  "uuid":"uniqueID of sshpiperd",
  "response":"response of the client (keyboard interactive)"
}
```

## skip challenge backend: GET https://localhost:8443/challenge/arthur

You can skip the challenge for a specific connection if you like. For that, instead of sending back the “message” at the first request, just send back the following data.

```json
{
  "challenge":false
}
```

## authentication backend: GET https://localhost:8443/auth/arthur

To get the upstream/downstream configuration for the user, your endpoint has to send back the following data. You can either use key authentication or password authentication.

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


```json
{
  "user": "root",
  "host": "192.168.1.1:22",
  "method": "password",
  "ignoreHostKey": true,
  "password": "myVerySecurePassword"
}
```

### authentication backend parameters

| Parameter | Description | Default | Example |
| --- | --- | --- | --- |
| `user` | The name of the upstream user | | *root*, *no-standard-username@myserver* |
| `host` | IP:Port of the upstream server | | *10.0.0.125:22*, *192.168.1.10:678* |
| `method` | The connection method, either **key** or **password"** | | *key*, *password* |
| `ignoreHostKey` | If to ignore the host key of the upstream server (known_hosts) | true | *true*, *false* |
| `knownHostKey` | If **ignoreHostKey** is false, the known host key | | *10.29.160.218 ssh-ed25519 AAAAC3NzaC1lZDI1N.....* |
| `authorizedKeys` | A list of authorized downstream public keys (can be multiple use \r\n) | | *ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AA........* |
| `privateKey` | The private key for the upstream connection | | *-----BEGIN OPENSSH PRIVATE KEY-----\r\nb3BlbnNz.....* |
| `password` | The password for the upstream connection | | *mysecurepassword* |