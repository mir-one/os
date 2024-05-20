#
# SPDX-License-Identifier: GPL-2.0
# Copyright (c) 2023 Ricardo Pardini <ricardo@pardini.net>
# This file is a part of the Armbian Build Framework https://github.com/armbian/build/
#

# This add's amazingfate's PPAs to the the image, and installs all needed packages.
# It only works on LINUXFAMILY="rk3588-legacy" and RELEASE=jammy and BRANCH=legacy
# if on a desktop, installs more useful packages, and tries to coerce lightdm to use gtk-greeter and a Wayland session.
function extension_prepare_config__amazingfated_rk3588() {

	if [[ "${LINUXFAMILY}" != "rockchip-rk3588" && "${LINUXFAMILY}" != "rk35xx" ]]; then
		exit_with_error "${EXTENSION} only works on LINUXFAMILY=rockchip-rk3588/rk35xx, currently on '${LINUXFAMILY}'"
	fi

        [[ "${BUILDING_IMAGE}" != "yes" ]] && return 0
        [[ "${RELEASE}" != "jammy" && "${RELEASE}" != "noble" ]] && return 0
	[[ "${BRANCH}" != "legacy" && "${BRANCH}" != "vendor" ]] && return 0
        [[ "${BUILD_DESKTOP}" != "yes" ]] && return 0

	display_alert "Preparing amazingfated's rk3588 extension" "${EXTENSION}" "info"
	# Add to the image suffix.
	EXTRA_IMAGE_SUFFIXES+=("-amazingfated") # global array

}

function post_install_kernel_debs__amazingfated_rk358() {

        [[ "${RELEASE}" != "jammy" && "${RELEASE}" != "noble" ]] && return 0
	[[ "${BRANCH}" != "legacy" && "${BRANCH}" != "vendor" ]] && return 0
        [[ "${BUILD_DESKTOP}" != "yes" ]] && return 0

	display_alert "Adding amazingfated's rk3588 PPAs" "${EXTENSION}" "info"
	do_with_retries 3 chroot_sdcard add-apt-repository ppa:liujianfeng1994/panfork-mesa --yes --no-update
	do_with_retries 3 chroot_sdcard add-apt-repository ppa:liujianfeng1994/rockchip-multimedia --yes --no-update

	display_alert "Pinning amazingfated's rk3588 PPAs" "${EXTENSION}" "info"

	cat <<- EOF > "${SDCARD}"/etc/apt/preferences.d/amazingfated-rk3588-panfork-pin
	Package: *
	Pin: release o=LP-PPA-liujianfeng1994-panfork-mesa
	Pin-Priority: 1001
	EOF

	cat <<- EOF > "${SDCARD}"/etc/apt/preferences.d/amazingfated-rk3588-rockchip-multimedia-pin
	Package: *
	Pin: release o=LP-PPA-liujianfeng1994-rockchip-multimedia
	Pin-Priority: 1001
	EOF

        # Ubuntu oracular workaround
        local url_to_check='https://ppa.launchpadcontent.net/liujianfeng1994/panfork-mesa/ubuntu/dists/${RELEASE}/Release'
        if curl -o/dev/null -sfIL "$url_to_check" 2>&1; then
                :
        else
                display_alert "Converting to generic sources list due to missing release file" "${EXTENSION}" "info"
                sed -i "s/${RELEASE}/jammy/g" "${SDCARD}"/etc/apt/sources.list.d/liujianfeng1994-ubuntu-panfork-mesa-"${RELEASE}".*
        fi

        if [[ ${RELEASE} == "oracular" ]]; then
            display_alert "Converting to generic sources list due to missing release file" "${EXTENSION}" "info"
            sed -i "s/oracular/noble/g" "${SDCARD}"/etc/apt/sources.list.d/liujianfeng1994-ubuntu-rockchip-multimedia-"${RELEASE}".*
        fi

	display_alert "Updating sources list, after amazingfated's rk3588 PPAs" "${EXTENSION}" "info"
	do_with_retries 3 chroot_sdcard_apt_get_update

	declare -a pkgs=(mali-g610-firmware chromium-browser gstreamer1.0-rockchip1 libv4l-rkmpp rockchip-multimedia-config)

	if [[ ${RELEASE} == "jammy" ]]; then
           pkgs+=('libwidevinecdm')
        fi

	display_alert "Installing amazingfated's rk3588 packages" "${EXTENSION} :: ${pkgs[*]}" "info"
	do_with_retries 3 chroot_sdcard_apt_get_install --allow-downgrades "${pkgs[@]}"

	display_alert "Upgrading amazingfated's rk3588 packages" "${EXTENSION}" "info"
	do_with_retries 3 chroot_sdcard_apt_get dist-upgrade

	display_alert "Installed amazingfated's rk3588 packages" "${EXTENSION}" "info"

	return 0
}
