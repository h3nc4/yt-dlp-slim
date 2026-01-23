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
ARG YT_DLP_VERSION="2025.12.08"

################################################################################
# Deno builder stage
FROM denoland/deno:bin-2.6.6 AS deno-builder

################################################################################
# FFmpeg builder stage
FROM debian:13-slim@sha256:77ba0164de17b88dd0bf6cdc8f65569e6e5fa6cd256562998b62553134a00ef0 AS ffmpeg-builder
RUN apt-get update && \
  apt-get install -y --no-install-recommends ffmpeg
RUN mkdir -p /rootfs/bin && \
  cp /usr/bin/ffmpeg /usr/bin/ffprobe /rootfs/bin/ && \
  ldd /usr/bin/ffmpeg | grep "=> /" | awk '{print $3}' | \
  xargs -I '{}' cp --parents '{}' /rootfs && \
  cp --parents /lib/x86_64-linux-gnu/libdl.so.2 /rootfs && \
  cp --parents /lib/x86_64-linux-gnu/libpthread.so.0 /rootfs && \
  cp --parents /lib/x86_64-linux-gnu/libutil.so.1 /rootfs && \
  cp --parents /lib/x86_64-linux-gnu/librt.so.1 /rootfs && \
  cp --parents /lib64/ld-linux-x86-64.so.2 /rootfs

################################################################################
# YT-DLP builder stage
FROM alpine:3.23@sha256:865b95f46d98cf867a156fe4a135ad3fe50d2056aa3f25ed31662dff6da4eb62 AS yt-dlp-builder
ARG YT_DLP_VERSION

RUN mkdir -p /rootfs/target /rootfs/tmp /rootfs/bin

ADD "https://github.com/yt-dlp/yt-dlp/releases/download/${YT_DLP_VERSION}/yt-dlp_linux" /yt-dlp_linux
ADD "https://github.com/yt-dlp/yt-dlp/releases/download/${YT_DLP_VERSION}/SHA2-256SUMS" /SHA2-256SUMS
ADD "https://github.com/yt-dlp/yt-dlp/releases/download/${YT_DLP_VERSION}/SHA2-256SUMS.sig" /SHA2-256SUMS.sig
ADD "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xAC0CBBE6848D6A873464AF4E57CF65933B5A7581" "/yt-dlp_pubkey.asc"

RUN apk add --no-cache gnupg && \
  gpg --import /yt-dlp_pubkey.asc && \
  gpg --verify /SHA2-256SUMS.sig /SHA2-256SUMS && \
  grep " yt-dlp_linux$" /SHA2-256SUMS | sha256sum -c -

RUN mv /yt-dlp_linux /rootfs/bin/yt-dlp && \
  chmod 755 /rootfs/bin/yt-dlp && \
  chmod 1777 /rootfs/tmp

################################################################################
# Final squashed image
FROM scratch AS final

COPY --from=deno-builder /deno /bin/deno
COPY --from=yt-dlp-builder /rootfs /
COPY --from=ffmpeg-builder /rootfs/ /

WORKDIR /target
# deno is yt-dlp's default JS runtime
ENTRYPOINT ["/bin/yt-dlp"]
CMD ["--help"]

LABEL org.opencontainers.image.title="yt-dlp Slim" \
  org.opencontainers.image.description="A distroless yt-dlp container with Deno and FFmpeg based on Debian" \
  org.opencontainers.image.authors="Henrique Almeida <me@h3nc4.com>" \
  org.opencontainers.image.vendor="Henrique Almeida" \
  org.opencontainers.image.licenses="GPL-3.0-or-later" \
  org.opencontainers.image.source="https://github.com/h3nc4/yt-dlp-slim"
