# @description Builds the iComm SSV6158/SSV6020 SDIO Wi-Fi driver (SDIO ID 5653:2060). The module name is ssv6158.

#
# SPDX-License-Identifier: GPL-2.0
# This file is a part of the Armbian Build Framework https://github.com/armbian/build/
#

# The pinned commits keep the kernel artifact hash stable.
declare -g SSV6158_REF="commit:a2afa9d80568895edd8875841137103801b51859"
declare -g SSV6158_REPO="https://github.com/wltechblog/wifi-ssv6158"
# SSV6020 firmware from the Radxa Allwinner BSP. SSV6006 firmware has the same upstream name.
declare -g SSV6158_FW_URL="https://raw.githubusercontent.com/radxa/allwinner-bsp/2045a3ca2a01f088c0314dc924bda59d154e363e/drivers/net/wireless/ssv6158/image/ssv6x5x-sw.bin"
declare -g SSV6158_FW_SHA256="ef93a7b50769aede707595afc27d43bf136d4fb9230b9b9dc5b1e39e9583f408"

function custom_kernel_config__ssv6158() {
	declare patch_dir="${SRC}/patch/misc/ssv6158"
	kernel_config_modifying_hashes+=("ssv6158=${SSV6158_REF}")
	kernel_config_modifying_hashes+=("ssv6158_patches=$(cat "${patch_dir}"/*.patch | sha256sum | cut -d' ' -f1)")
	[[ ! -f .config ]] && return 0

	declare kernel_cwd="${PWD}"
	fetch_from_repo "${SSV6158_REPO}" "wifi-ssv6158" "${SSV6158_REF}" "yes"
	cd "${kernel_cwd}" || exit_with_error "ssv6158" "could not return to ${kernel_cwd}"

	declare src_dir="${SRC}/cache/sources/wifi-ssv6158/${SSV6158_REF#*:}"
	declare wireless_dir="${kernel_work_dir}/drivers/net/wireless"
	declare driver_dir="${wireless_dir}/ssv6158"

	display_alert "SSV6158" "adding ssv6158 driver" "info"
	run_host_command_logged rm -rf "${driver_dir}"
	run_host_command_logged mkdir -p "${driver_dir}"
	run_host_command_logged cp -a \
		"${src_dir}/Makefile" \
		"${src_dir}/Kconfig" \
		"${src_dir}/ssv6158.cfg" \
		"${src_dir}/ssv6158-wifi.cfg" \
		"${src_dir}/platform-config.mak" \
		"${src_dir}/config_common.mak" \
		"${src_dir}/parser-conf.sh" \
		"${src_dir}/ssv6158-generic-wlan.c" \
		"${src_dir}/hci" \
		"${src_dir}/hwif" \
		"${src_dir}/include" \
		"${src_dir}/smac" \
		"${src_dir}/ssvdevice" \
		"${driver_dir}/"

	declare patch_file
	for patch_file in "${patch_dir}"/*.patch; do
		patch --batch -p1 -d "${driver_dir}" < "${patch_file}" ||
			exit_with_error "ssv6158 patch failed" "${patch_file}"
	done

	if ! grep -q 'ssv6158/Kconfig' "${wireless_dir}/Kconfig"; then
		sed -i '/source "drivers\/net\/wireless\/ti\/Kconfig"/a source "drivers\/net\/wireless\/ssv6158\/Kconfig"' \
			"${wireless_dir}/Kconfig"
	fi
	grep -q 'ssv6158/Kconfig' "${wireless_dir}/Kconfig" ||
		exit_with_error "ssv6158 Kconfig line missing" "${wireless_dir}/Kconfig"
	if ! grep -q 'ssv6158/' "${wireless_dir}/Makefile"; then
		echo 'obj-$(CONFIG_SSV6158) += ssv6158/' >> "${wireless_dir}/Makefile"
	fi
	grep -q 'obj-$(CONFIG_SSV6158) += ssv6158/' "${wireless_dir}/Makefile" ||
		exit_with_error "ssv6158 Makefile line missing" "${wireless_dir}/Makefile"

	kernel_config_set_m CONFIG_SSV6158
}

function post_family_tweaks__ssv6158_firmware() {
	declare cache_dir="${SRC}/cache/ssv6158-firmware"
	declare fw_file="${cache_dir}/ssv6020-sw.bin"
	mkdir -p "${cache_dir}"
	if [[ ! -f "${fw_file}" ]] || ! echo "${SSV6158_FW_SHA256}  ${fw_file}" | sha256sum -c --status; then
		display_alert "SSV6158" "downloading SSV6020 firmware" "info"
		curl -fsSL --retry 3 -o "${fw_file}.tmp" "${SSV6158_FW_URL}" ||
			exit_with_error "SSV6020 firmware download failed" "${SSV6158_FW_URL}"
		mv "${fw_file}.tmp" "${fw_file}"
	fi
	echo "${SSV6158_FW_SHA256}  ${fw_file}" | sha256sum -c --status ||
		exit_with_error "SSV6020 firmware checksum mismatch" "${fw_file}"

	# The kernel artifact can come from cache, so fetch the driver source here too.
	fetch_from_repo "${SSV6158_REPO}" "wifi-ssv6158" "${SSV6158_REF}" "yes"
	declare src_dir="${SRC}/cache/sources/wifi-ssv6158/${SSV6158_REF#*:}"
	install -D -m 644 "${fw_file}" "${SDCARD}/lib/firmware/ssv6020-sw.bin"
	install -D -m 644 "${src_dir}/ssv6158-wifi.cfg" "${SDCARD}/lib/firmware/ssv6158-wifi.cfg"
}

function post_family_tweaks__ssv6158_module() {
	local module_path
	module_path="$(find "${SDCARD}/lib/modules" -name 'ssv6158.ko*' -print -quit)"
	[[ -n "${module_path}" ]] ||
		exit_with_error "SSV6158 module missing" "ssv6158.ko"
}
