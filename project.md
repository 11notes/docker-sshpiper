${{ content_synopsis }} This image will run sshpiper [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md) and [distroless](https://github.com/11notes/RTFM/blob/main/linux/container/image/distroless.md), for maximum security and performance. In addition to being small and secure, it also offers two additional plugins (rest_auth and rest_challenge) which allow you to use any backend for authentication and challenges.

${{ content_uvp }} Good question! Because ...

${{ github:> [!IMPORTANT] }}
${{ github:> }}* ... this image runs [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md) as 1000:1000
${{ github:> }}* ... this image has no shell since it is [distroless](https://github.com/11notes/RTFM/blob/main/linux/container/image/distroless.md)
${{ github:> }}* ... this image is auto updated to the latest version via CI/CD
${{ github:> }}* ... this image has a health check
${{ github:> }}* ... this image runs read-only
${{ github:> }}* ... this image is automatically scanned for CVEs before and after publishing
${{ github:> }}* ... this image is created via a secure and pinned CI/CD process
${{ github:> }}* ... this image is very small

If you value security, simplicity and optimizations to the extreme, then this image might be for you.

${{ content_comparison }}

${{ title_volumes }}
* **${{ json_root }}/var** - Directory for screen recordings and other stuff (if used)

${{ content_compose }}

${{ content_defaults }}
| `--server-key` | /run/secrets/ssh_host_key | SSH host key |
| `--log-format` | json | json output to console |
| `--log-level` | info | log verbosity level |
| `--drop-hostkeys-message` |  | filter out hostkeys-00@openssh.com |
| `--reply-ping` |  | reply to ping@openssh instead of passing it to upstream |

${{ content_environment }}

${{ content_source }}

${{ content_parent }}

${{ content_built }}

${{ content_tips }}