# @description Builds the iComm SV6256P SDIO Wi-Fi driver. The module name is ssv6x5x. Firmware comes from armbian-firmware.

#
# SPDX-License-Identifier: GPL-2.0
# Copyright (c) 2023 Armbian
# This file is a part of the Armbian Build Framework https://github.com/armbian/build/
#

# The pinned commit keeps the kernel artifact hash stable.
declare -g SSV6X5X_REF="commit:43c2ede238b39ba3abb1129323a998495c6b8be9"
declare -g SSV6X5X_REPO="https://github.com/cdhigh/armbian_sv6256p"

function custom_kernel_config__ssv6x5x() {
	declare patch_file="${SRC}/patch/misc/ssv6x5x/0001-replace-strncpy.patch"
	kernel_config_modifying_hashes+=("ssv6x5x=${SSV6X5X_REF}")
	kernel_config_modifying_hashes+=("ssv6x5x_patch=$(sha256sum "${patch_file}" | cut -d' ' -f1)")
	[[ ! -f .config ]] && return 0

	declare kernel_cwd="${PWD}"
	fetch_from_repo "${SSV6X5X_REPO}" "armbian_sv6256p" "${SSV6X5X_REF}" "yes"
	cd "${kernel_cwd}" || exit_with_error "ssv6x5x" "could not return to ${kernel_cwd}"

	declare src_dir="${SRC}/cache/sources/armbian_sv6256p/${SSV6X5X_REF#*:}"
	declare wireless_dir="${kernel_work_dir}/drivers/net/wireless"
	declare driver_dir="${wireless_dir}/ssv6x5x"

	display_alert "SV6256P" "adding ssv6x5x driver" "info"
	run_host_command_logged rm -rf "${driver_dir}"
	run_host_command_logged mkdir -p "${driver_dir}"
	run_host_command_logged cp -a \
		"${src_dir}/Makefile" \
		"${src_dir}/Kconfig" \
		"${src_dir}/ssv6x5x.cfg" \
		"${src_dir}/platform-config.mak" \
		"${src_dir}/config_common.mak" \
		"${src_dir}/ssv6x5x-generic-wlan.c" \
		"${src_dir}/hci" \
		"${src_dir}/hwif" \
		"${src_dir}/include" \
		"${src_dir}/smac" \
		"${src_dir}/ssvdevice" \
		"${driver_dir}/"

	# The backup copy is for the vendor image directory. The kernel tree has none.
	sed -i '/BKP_CFG/d' "${driver_dir}/Makefile"
	sed -i 's/---help---/help/g' "${driver_dir}/Kconfig"
	# Kernel 7.2 removes strncpy.
	patch --batch -p1 -d "${driver_dir}" < "${SRC}/patch/misc/ssv6x5x/0001-replace-strncpy.patch"

	if ! grep -q 'ssv6x5x/Kconfig' "${wireless_dir}/Kconfig"; then
		sed -i '/source "drivers\/net\/wireless\/ti\/Kconfig"/a source "drivers\/net\/wireless\/ssv6x5x\/Kconfig"' \
			"${wireless_dir}/Kconfig"
	fi
	grep -q 'ssv6x5x/Kconfig' "${wireless_dir}/Kconfig" ||
		exit_with_error "ssv6x5x Kconfig line missing" "${wireless_dir}/Kconfig"
	if ! grep -q 'ssv6x5x/' "${wireless_dir}/Makefile"; then
		echo 'obj-$(CONFIG_SSV6X5X) += ssv6x5x/' >> "${wireless_dir}/Makefile"
	fi
	grep -q 'obj-$(CONFIG_SSV6X5X) += ssv6x5x/' "${wireless_dir}/Makefile" ||
		exit_with_error "ssv6x5x Makefile line missing" "${wireless_dir}/Makefile"

	kernel_config_set_m CONFIG_SSV6X5X
}

function post_family_tweaks__ssv6x5x_firmware() {
	declare fw_dir="${SDCARD}/lib/firmware"
	[[ -f "${fw_dir}/ssv6x5x-sw.bin" ]] ||
		exit_with_error "SV6256P firmware missing" "${fw_dir}/ssv6x5x-sw.bin"
	[[ -f "${fw_dir}/ssv6x5x-wifi.cfg" ]] ||
		exit_with_error "SV6256P firmware config missing" "${fw_dir}/ssv6x5x-wifi.cfg"
}

function post_family_tweaks__ssv6x5x_module() {
	local module_path
	module_path="$(find "${SDCARD}/lib/modules" -name 'ssv6x5x.ko*' -print -quit)"
	[[ -n "${module_path}" ]] ||
		exit_with_error "SV6256P module missing" "ssv6x5x.ko"
}

function post_family_tweaks__ssv6x5x_autoload() {
	mkdir -p "${SDCARD}/etc/modules-load.d"
	printf '%s\n' "ssv6x5x" > "${SDCARD}/etc/modules-load.d/ssv6x5x.conf"
}
