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
ARG YT_DLP_VERSION="2026.02.04"
ARG ALPINE_VERSION="3.23@sha256:25109184c71bdad752c8312a8623239686a9a2071e8825f20acb8f2198c3f659"

################################################################################
# YT-DLP builder stage
FROM alpine:${ALPINE_VERSION} AS yt-dlp-builder
ARG YT_DLP_VERSION

ADD "https://github.com/yt-dlp/yt-dlp/releases/download/${YT_DLP_VERSION}/yt-dlp_musllinux" /yt-dlp_musllinux
ADD "https://github.com/yt-dlp/yt-dlp/releases/download/${YT_DLP_VERSION}/SHA2-256SUMS" /SHA2-256SUMS
ADD "https://github.com/yt-dlp/yt-dlp/releases/download/${YT_DLP_VERSION}/SHA2-256SUMS.sig" /SHA2-256SUMS.sig
ADD "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xAC0CBBE6848D6A873464AF4E57CF65933B5A7581" "/yt-dlp_pubkey.asc"

RUN apk add --no-cache gnupg && \
  gpg --import /yt-dlp_pubkey.asc && \
  gpg --verify /SHA2-256SUMS.sig /SHA2-256SUMS && \
  grep " yt-dlp_musllinux$" /SHA2-256SUMS | sha256sum -c -

RUN mv /yt-dlp_musllinux /yt-dlp && \
  chmod 755 /yt-dlp

################################################################################
# Assemble runtime image
FROM alpine:${ALPINE_VERSION} AS assemble

RUN apk add --no-cache ffmpeg quickjs

RUN mkdir -p /rootfs/bin && \
  cp /usr/bin/ffmpeg /usr/bin/ffprobe /usr/bin/qjs /rootfs/bin/ && \
  ldd /usr/bin/ffmpeg | grep "=> /" | awk '{print $3}' | \
  xargs -I '{}' cp --parents '{}' /rootfs && \
  cp --parents /lib/ld-musl-x86_64.so.1 /rootfs

RUN mkdir -p /rootfs/target /rootfs/tmp && \
  chmod 1777 /rootfs/tmp

################################################################################
# Final squashed image
FROM scratch AS final

COPY --from=yt-dlp-builder /yt-dlp /bin/yt-dlp
COPY --from=assemble /rootfs /

WORKDIR /target
# must specify qjs as JS runtime
ENTRYPOINT ["/bin/yt-dlp", "--js-runtimes", "quickjs:/bin/qjs"]
CMD ["--help"]

LABEL org.opencontainers.image.title="yt-dlp Slim" \
  org.opencontainers.image.description="An Alpine yt-dlp container with QuickJS and FFmpeg" \
  org.opencontainers.image.authors="Henrique Almeida <me@h3nc4.com>" \
  org.opencontainers.image.vendor="Henrique Almeida" \
  org.opencontainers.image.licenses="GPL-3.0-or-later" \
  org.opencontainers.image.source="https://github.com/h3nc4/yt-dlp-slim"
