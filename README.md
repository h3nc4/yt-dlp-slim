# yt-dlp Slim

Distroless Docker container for [yt-dlp](https://github.com/yt-dlp/yt-dlp) with JavaScript and FFmpeg support.

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

Alpine variant:

```bash
docker run --rm -v "$PWD:/target" h3nc4/yt-dlp-slim:alpine [OPTIONS] URL [URL...]
```

## License

yt-dlp Slim is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

yt-dlp Slim is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with yt-dlp Slim. If not, see <https://www.gnu.org/licenses/>.
