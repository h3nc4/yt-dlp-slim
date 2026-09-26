# yt-dlp Slim

Distroless Docker container for [yt-dlp](https://github.com/yt-dlp/yt-dlp) with JavaScript and FFmpeg support.

The default image uses [Deno](https://deno.land/) as JavaScript runtime and weighs <400MB.

An Alpine-based variant with [QuickJS](https://bellard.org/quickjs/) as JavaScript runtime is also available, weighing <120MB.

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

Or wrapper script for [mpv](https://mpv.io/) integration:

```bash
tee /usr/local/bin/yt-dlp << 'EOF' >/dev/null
#!/bin/sh
exec docker run --rm -u "$(id -u):$(id -g)" -v "${PWD}:/target" h3nc4/yt-dlp-slim "$@"
EOF
chmod +x /usr/local/bin/yt-dlp
```

Distroless Alpine variant:

```bash
docker run --rm -v "$PWD:/target" h3nc4/yt-dlp-slim:alpine [OPTIONS] URL [URL...]
```

## Passing browser cookies

Some sites require authentication. The easiest approach is to export your cookies to a `cookies.txt` file and mount it into the container.

**Recommended extension:** [Get cookies.txt LOCALLY](https://github.com/kairi003/Get-cookies.txt-LOCALLY) — available for [Chrome/Chromium](https://chromewebstore.google.com/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc) and [Firefox](https://addons.mozilla.org/en-US/firefox/addon/get-cookies-txt-locally/). It exports cookies in Netscape format directly from your browser without sending data to any server.

Once you have `cookies.txt`, mount it at `/cookies.txt` — the container will pick it up automatically:

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

yt-dlp Slim is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

yt-dlp Slim is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with yt-dlp Slim. If not, see <https://www.gnu.org/licenses/>.
