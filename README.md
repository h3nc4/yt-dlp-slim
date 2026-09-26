# yt-dlp Slim

Docker image for [yt-dlp](https://github.com/yt-dlp/yt-dlp) carrying a JavaScript runtime and FFmpeg, for the sites that need either.

Both tags end on `FROM scratch`, so neither holds a shell or a package manager. They differ in what was compiled into them:

| Tag | JavaScript runtime | Compiled against | Size |
| --- | --- | --- | --- |
| `latest` | [Deno](https://deno.land/) | Debian, glibc | under 400 MB |
| `alpine` | [QuickJS](https://bellard.org/quickjs/) | Alpine, musl | under 120 MB |

`alpine` is the one to reach for unless a site needs the full Deno runtime. Its name says what the binaries were built against. The published image itself contains no distribution at all.

## Usage

```bash
docker run --rm -u "$(id -u):$(id -g)" -v "$PWD:/target" h3nc4/yt-dlp-slim [OPTIONS] URL [URL...]
```

Shell function for convenience:

```bash
yt-dlp() {
  docker run --rm -u "$(id -u):$(id -g)" -v "$PWD:/target" h3nc4/yt-dlp-slim "$@"
}
```

A wrapper script on `PATH` is what [mpv](https://mpv.io/) picks up, since mpv looks for a `yt-dlp` executable rather than a shell function. Writing to `/usr/local/bin` needs root:

```bash
doas tee /usr/local/bin/yt-dlp << 'EOF' >/dev/null
#!/bin/sh
exec docker run --rm -u "$(id -u):$(id -g)" -v "${PWD}:/target" h3nc4/yt-dlp-slim "$@"
EOF
doas chmod +x /usr/local/bin/yt-dlp
```

That name shadows a yt-dlp installed from a package. Pick another one to keep both.

The `alpine` tag takes the same arguments:

```bash
docker run --rm -u "$(id -u):$(id -g)" -v "$PWD:/target" h3nc4/yt-dlp-slim:alpine [OPTIONS] URL [URL...]
```

## Passing browser cookies

A site behind a login needs the session cookie. `--cookies-from-browser` cannot reach the host's browser profile from inside a container, so export the cookies to a file and mount that.

[Get cookies.txt LOCALLY](https://github.com/kairi003/Get-cookies.txt-LOCALLY) writes the Netscape format yt-dlp expects, for [Chrome and Chromium](https://chromewebstore.google.com/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc) or [Firefox](https://addons.mozilla.org/en-US/firefox/addon/get-cookies-txt-locally/). It is third-party code, so read its source and permissions before trusting a logged-in session to it.

A `cookies.txt` is a live credential for every site in it. Keep it at mode 600, mount it read-only, and export again rather than keeping an old one around.

Mount the file at `/cookies.txt` and the container picks it up without a flag:

```bash
docker run --rm -u "$(id -u):$(id -g)" \
  -v "$PWD:/target" \
  -v "$PWD/cookies.txt:/cookies.txt:ro" \
  h3nc4/yt-dlp-slim URL
```

## Downloading through tor

A tor daemon binds its SocksPort to loopback, and a container with a namespace of its own has a different loopback, so it needs the host's:

```bash
docker run --rm --network host -u "$(id -u):$(id -g)" -v "$PWD:/target" \
  h3nc4/yt-dlp-slim --proxy socks5h://127.0.0.1:9050 URL
```

The `h` in `socks5h` sends each lookup through the circuit. Plain `socks5` resolves the hostname locally first, which hands every domain visited to whatever resolver the host is configured with.

**ffmpeg takes no SOCKS proxy.** An HLS or DASH stream handed to it leaves direct while everything else is tunnelled, so add `--downloader "m3u8:native"` to keep the fetching inside yt-dlp. The merge at the end is local and reaches no network.

Where tor runs as a container of its own, join its network and name it instead, `--proxy socks5h://tor:9050`. Its `SocksPolicy` has to accept the address the request arrives from, which is the yt-dlp container rather than the host.

Throughput is a fraction of a direct download, and some sites refuse an exit node outright, which reads as a 403 or a bot check rather than as a proxy failure.

## License

<!-- vale off -->

yt-dlp Slim is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

yt-dlp Slim is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with yt-dlp Slim. If not, see <https://www.gnu.org/licenses/>.
