# Copyright (C) 2026  Henrique Almeida
# This file is part of yt-dlp Slim.
#
# yt-dlp Slim is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# yt-dlp Slim is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with yt-dlp Slim.  If not, see <https://www.gnu.org/licenses/>.

########################################
# Versions
ARG BUN_VERSION="1.3.6"
ARG YT_DLP_VERSION="2025.12.08"
ARG ALPINE_VERSION="3.23@sha256:865b95f46d98cf867a156fe4a135ad3fe50d2056aa3f25ed31662dff6da4eb62"

################################################################################
# Bun builder stage
FROM alpine:${ALPINE_VERSION} AS bun-builder
ARG BUN_VERSION

ADD "https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/bun-linux-x64-musl.zip" /tmp/bun.zip
RUN unzip /tmp/bun.zip -d /tmp && \
  mv /tmp/bun-linux-x64-musl/bun /bun && \
  chmod 755 /bun

################################################################################
# YT-DLP builder stage
FROM alpine:${ALPINE_VERSION} AS yt-dlp-builder
ARG YT_DLP_VERSION

ADD "https://github.com/yt-dlp/yt-dlp/releases/download/${YT_DLP_VERSION}/yt-dlp_musllinux" /yt-dlp
RUN chmod 755 /yt-dlp

################################################################################
# Assemble runtime image
FROM alpine:${ALPINE_VERSION} AS assemble

RUN apk add --no-cache ffmpeg

COPY --from=bun-builder /bun /usr/local/bin/bun
COPY --from=yt-dlp-builder /yt-dlp /usr/local/bin/yt-dlp

################################################################################
# Final squashed image
FROM scratch AS final

COPY --from=assemble "/" "/"

WORKDIR /target
# must specify bun as JS runtime
ENTRYPOINT ["/usr/local/bin/yt-dlp", "--js-runtimes", "bun:/usr/local/bin/bun"]
CMD ["--help"]

LABEL org.opencontainers.image.title="yt-dlp Slim" \
  org.opencontainers.image.description="An Alpine yt-dlp container with Bun and FFmpeg" \
  org.opencontainers.image.authors="Henrique Almeida <me@h3nc4.com>" \
  org.opencontainers.image.vendor="Henrique Almeida" \
  org.opencontainers.image.licenses="GPL-3.0-or-later" \
  org.opencontainers.image.source="https://github.com/h3nc4/yt-dlp-slim"
