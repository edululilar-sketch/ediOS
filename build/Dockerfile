# ediOS Bau-Container: Alpine 3.24, gebaut wird als Benutzer 1000 (wie auf dem Host).
FROM alpine:3.24

ARG MIRROR=https://mirror.netcologne.de/alpine
ARG BRANCH=v3.24
ARG UID=1000
ARG GID=1000

RUN printf '%s/%s/main\n%s/%s/community\n' "$MIRROR" "$BRANCH" "$MIRROR" "$BRANCH" > /etc/apk/repositories \
 && apk add --no-cache \
	alpine-sdk abuild alpine-conf apk-tools busybox fakeroot doas \
	syslinux xorriso squashfs-tools mtools dosfstools \
	grub grub-efi sbsigntool openssl binutils \
	meson ninja sassc glib-dev gettext git \
	python3 py3-pip pipx \
	dconf gtk-update-icon-cache \
	bash rsvg-convert curl wget xz zstd tar file \
 && addgroup -g "$GID" builder 2>/dev/null; adduser -D -u "$UID" -G builder builder 2>/dev/null; \
	addgroup builder abuild \
 && echo "permit nopass builder as root" > /etc/doas.d/builder.conf \
 && mkdir -p /home/builder/.abuild && chown -R builder:builder /home/builder
