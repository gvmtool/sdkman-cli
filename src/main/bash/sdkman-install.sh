#!/usr/bin/env bash

#
#   Copyright 2021-2023 Marco Vermeulen
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#


function __sdk_set_default() {
	local candidate VERSION

	candidate="$1"
	VERSION="$2"

	if [[ "$sdkman_auto_answer" != 'true' && "$auto_answer_upgrade" != 'true' && -n "$CURRENT" ]]; then
		__sdkman_echo_confirm "Do you want ${candidate} version ${VERSION} to be set as default? (Y/n): "
		read USE
	fi

	if [[ -z "$USE" || "$USE" == "y" || "$USE" == "Y" ]]; then
		echo ""
		__sdkman_echo_green "Setting ${candidate} version ${VERSION} as default."
		__sdkman_link_candidate_version "$candidate" "$VERSION"
		__sdkman_add_to_path "$candidate"
	fi
}

function __sdk_install() {
	local candidate version folder

	candidate="$1"
	version="$2"
	folder="$3"

	__sdkman_check_candidate_present "$candidate" || return 1
	__sdkman_determine_version "$candidate" "$version" "$folder" || return 1

	if [[ -d "${SDKMAN_CANDIDATES_DIR}/${candidate}/${VERSION}" || -L "${SDKMAN_CANDIDATES_DIR}/${candidate}/${VERSION}" ]]; then
		echo ""
		__sdkman_echo_yellow "${candidate} ${VERSION} is already installed."
		return 0
	fi

	if [[ ${VERSION_VALID} == 'valid' ]]; then
		__sdkman_determine_current_version "$candidate"
		__sdkman_install_candidate_version "$candidate" "$VERSION" || return 1

		__sdk_set_default "$candidate" "$VERSION"

		return 0
	elif [[ "$VERSION_VALID" == 'invalid' && -n "$folder" ]]; then
		__sdkman_install_local_version "$candidate" "$VERSION" "$folder" || return 1
	else
		echo ""
		__sdkman_echo_red "Stop! $1 is not a valid ${candidate} version."
		return 1
	fi
}

function __sdkman_install_candidate_version() {
	local candidate version

	candidate="$1"
	version="$2"

	__sdkman_download "$candidate" "$version" || return 1
	__sdkman_echo_green "Installing: ${candidate} ${version}"

	mkdir -p "${SDKMAN_CANDIDATES_DIR}/${candidate}"

	rm -rf "${SDKMAN_DIR}/tmp/out"
	unzip -oq "${SDKMAN_DIR}/tmp/${candidate}-${version}.zip" -d "${SDKMAN_DIR}/tmp/out"
	mv -f "$SDKMAN_DIR"/tmp/out/* "${SDKMAN_CANDIDATES_DIR}/${candidate}/${version}"
	__sdkman_echo_green "Done installing!"
	echo ""
}

function __sdkman_install_local_version() {
	local candidate version folder version_length version_length_max

	version_length_max=15

	candidate="$1"
	version="$2"
	folder="$3"

	# Validate max length of version
	version_length=${#version}
	__sdkman_echo_debug "Validating that actual version length ($version_length) does not exceed max ($version_length_max)"

	if [[ $version_length -gt $version_length_max ]]; then
		__sdkman_echo_red "Invalid version! ${version} with length ${version_length} exceeds max of ${version_length_max}!"
		return 1
	fi

	mkdir -p "${SDKMAN_CANDIDATES_DIR}/${candidate}"

	# handle relative paths
	if [[ "$folder" != /* ]]; then
		folder="$(pwd)/$folder"
	fi

	if [[ -d "$folder" ]]; then
		__sdkman_echo_green "Linking ${candidate} ${version} to ${folder}"
		ln -s "$folder" "${SDKMAN_CANDIDATES_DIR}/${candidate}/${version}"

		__sdk_set_default "${candidate}" "${version}"
		__sdkman_echo_green "Done linking to $folder!"
	else
		__sdkman_echo_red "Invalid path! Refusing to link ${candidate} ${version} to ${folder}."
		return 1
	fi

	echo ""
}

function __sdkman_download() {
	local candidate version

	candidate="$1"
	version="$2"

	metadata_folder="${SDKMAN_DIR}/var/metadata"
	mkdir -p "${metadata_folder}"
		
	local platform_parameter="$SDKMAN_PLATFORM"
	local download_url="${SDKMAN_CANDIDATES_API}/broker/download/${candidate}/${version}/${platform_parameter}"
	local base_name="${candidate}-${version}"
	local tmp_headers_file="${SDKMAN_DIR}/tmp/${base_name}.headers.tmp"
	local headers_file="${metadata_folder}/${base_name}.headers"

	export local binary_input="${SDKMAN_DIR}/tmp/${base_name}.bin"
	export local zip_output="${SDKMAN_DIR}/tmp/${base_name}.zip"

	echo ""
	__sdkman_echo_no_colour "Downloading: ${candidate} ${version}"
	echo ""
	__sdkman_echo_no_colour "In progress..."
	echo ""

	# download binary
	__sdkman_secure_curl_download "${download_url}" --output "${binary_input}" --dump-header "${tmp_headers_file}"
	grep '^X-Sdkman' "${tmp_headers_file}" > "${headers_file}"
	__sdkman_echo_debug "Downloaded binary to: ${binary_input} (HTTP headers written to: ${headers_file})"

	# post-installation hook: implements function __sdkman_post_installation_hook
	# responsible for taking `binary_input` and producing `zip_output`
	local post_installation_hook="${SDKMAN_DIR}/tmp/hook_post_${candidate}_${version}.sh"
	__sdkman_echo_debug "Get post-installation hook: ${SDKMAN_CANDIDATES_API}/hooks/post/${candidate}/${version}/${platform_parameter}"
	__sdkman_secure_curl "${SDKMAN_CANDIDATES_API}/hooks/post/${candidate}/${version}/${platform_parameter}" >| "$post_installation_hook"
	__sdkman_echo_debug "Copy remote post-installation hook: ${post_installation_hook}"
	source "$post_installation_hook"
	__sdkman_post_installation_hook || return 1
	__sdkman_echo_debug "Processed binary as: $zip_output"
	__sdkman_echo_debug "Completed post-installation hook..."
		
	__sdkman_validate_zip "${zip_output}" || return 1
	__sdkman_checksum_zip "${zip_output}" "${headers_file}" || return 1
	echo ""
}

function __sdkman_validate_zip() {
	local zip_archive zip_ok

	zip_archive="$1"
	zip_ok=$(unzip -t "$zip_archive" | grep 'No errors detected in compressed data')
	if [ -z "$zip_ok" ]; then
		rm -f "$zip_archive"
		echo ""
		__sdkman_echo_red "Stop! The archive was corrupt and has been removed! Please try installing again."
		return 1
	fi
}

function __sdkman_checksum_zip() {
	local -r zip_archive="$1"
	local -r headers_file="$2"
	local algorithm checksum cmd
	local shasum_avail=false
	local md5sum_avail=false
	
	if [ -z "${headers_file}" ]; then
		echo ""
		__sdkman_echo_debug "Skipping checksum for cached artifact"
		return
	elif [ ! -f "${headers_file}" ]; then
		echo ""
		__sdkman_echo_yellow "Metadata file not found at '${headers_file}', skipping checksum..."
		return
	fi
	
	if [[ "$sdkman_checksum_enable" != "true" ]]; then
		echo ""
		__sdkman_echo_yellow "Checksums are disabled, skipping verification..."
		return
	fi
	
	#Check for the appropriate checksum tools
	if command -v shasum > /dev/null 2>&1; then
		shasum_avail=true
	fi
	if command -v md5sum > /dev/null 2>&1; then
		md5sum_avail=true
	fi
	
	while IFS= read -r line; do
		algorithm=$(echo $line | sed -n 's/^X-Sdkman-Checksum-\(.*\):.*$/\1/p' | tr '[:lower:]' '[:upper:]')
		checksum=$(echo $line | sed -n 's/^X-Sdkman-Checksum-.*:\(.*\)$/\1/p' | tr -cd '[:alnum:]')
		
		if [[ -n ${algorithm} && -n ${checksum} ]]; then
			
			if [[ "$algorithm" =~ 'SHA' && "$shasum_avail" == 'true' ]]; then
				cmd="echo \"${checksum} *${zip_archive}\" | shasum --check --quiet"
				
			elif [[ "$algorithm" =~ 'MD5' && "$md5sum_avail" == 'true' ]]; then
				cmd="echo \"${checksum} ${zip_archive}\" | md5sum --check --quiet"
			fi
			
			if [[ -n $cmd ]]; then
				__sdkman_echo_no_colour "Verifying artifact: ${zip_archive} (${algorithm}:${checksum})"

				if ! eval "$cmd"; then
					rm -f "$zip_archive"
					echo ""
					__sdkman_echo_red "Stop! An invalid checksum was detected and the archive removed! Please try re-installing."
					return 1
				fi
			else
				__sdkman_echo_no_colour "Not able to perform checksum verification at this time."
			fi
		fi
  	done < "${headers_file}"
}
