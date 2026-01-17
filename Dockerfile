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
ARG DENO_VERSION="2.6.5"
ARG YT_DLP_VERSION="2025.12.08"

################################################################################
# Deno builder stage
FROM busybox:musl@sha256:03db190ed4c1ceb1c55d179a0940e2d71d42130636a780272629735893292223 AS deno-builder
ARG DENO_VERSION

ADD "https://dl.deno.land/release/v${DENO_VERSION}/deno-x86_64-unknown-linux-gnu.zip" /deno.zip
RUN unzip /deno.zip && \
  chmod 755 /deno

################################################################################
# FFmpeg builder stage
FROM debian:13-slim@sha256:77ba0164de17b88dd0bf6cdc8f65569e6e5fa6cd256562998b62553134a00ef0 AS ffmpeg-builder
RUN apt-get update && \
  apt-get install -y --no-install-recommends ffmpeg
RUN mkdir -p /rootfs/usr/bin && \
  cp /usr/bin/ffmpeg /rootfs/usr/bin/ffmpeg && \
  ldd /usr/bin/ffmpeg | grep "=> /" | awk '{print $3}' | \
  xargs -I '{}' cp --parents '{}' /rootfs

################################################################################
# YT-DLP builder stage
FROM busybox:musl@sha256:03db190ed4c1ceb1c55d179a0940e2d71d42130636a780272629735893292223 AS yt-dlp-builder
ARG YT_DLP_VERSION

RUN mkdir -p /rootfs/usr/local/bin /rootfs/target
ADD "https://github.com/yt-dlp/yt-dlp/releases/download/${YT_DLP_VERSION}/yt-dlp_linux" /rootfs/usr/local/bin/yt-dlp
RUN chmod 755 /rootfs/usr/local/bin/yt-dlp

################################################################################
# Assemble runtime image
FROM gcr.io/distroless/base-debian13@sha256:0e299959b841de2aef4259d411c23826a2276e019a5ffea141245679a1d95b46 AS assemble

COPY --from=deno-builder /deno /usr/local/bin/deno
COPY --from=yt-dlp-builder /rootfs /
COPY --from=ffmpeg-builder /rootfs/usr /usr
COPY --from=ffmpeg-builder /rootfs/lib /lib

################################################################################
# Final squashed image
FROM scratch AS final

COPY --from=assemble "/" "/"

WORKDIR /target
# deno is yt-dlp's default JS runtime
ENTRYPOINT ["/usr/local/bin/yt-dlp"]
CMD ["--help"]

LABEL org.opencontainers.image.title="yt-dlp Slim" \
  org.opencontainers.image.description="A distroless yt-dlp container with Deno and FFmpeg based on Debian" \
  org.opencontainers.image.authors="Henrique Almeida <me@h3nc4.com>" \
  org.opencontainers.image.vendor="Henrique Almeida" \
  org.opencontainers.image.licenses="GPL-3.0-or-later" \
  org.opencontainers.image.source="https://github.com/h3nc4/yt-dlp-slim"
