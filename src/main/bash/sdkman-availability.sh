#!/usr/bin/env bash

#
#   Copyright 2017 Marco Vermeulen
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

function __sdkman_update_broadcast_and_service_availability {
	local broadcast_id
	#TODO: handle offline without qualifier
	if [[ "${SDKMAN_OFFLINE_MODE}" == 'true' || "${COMMAND}" == 'offline' && "${1}" == 'enable' ]]; then
		broadcast_id=
		SDKMAN_AVAILABLE='false'
	else
		local httpStatusCode
		broadcast_id=$(__sdkman_secure_curl_with_timeouts "${SDKMAN_CANDIDATES_API}/broadcast/latest/id")
		httpStatusCode="${?}"

		if [[ -z "${broadcast_id}" ]]; then
			SDKMAN_AVAILABLE='false'
			#TODO: DIFFERENCE: below is now output (but wasn't before change) if command is offline, either with no qualifier, or with disable qualifier
			__sdkman_echo_red '==== INTERNET NOT REACHABLE! ===================================================

 Some functionality is disabled or only partially available.
 If this persists, please enable the offline mode:

   $ sdk offline
================================================================================
'
		elif ((httpStatusCode)); then
			SDKMAN_AVAILABLE='false'
			__sdkman_echo_red '==== PROXY DETECTED! ===========================================================
Please ensure you have open internet access to continue.
================================================================================
'
		else
			SDKMAN_AVAILABLE='true'
		fi
	fi

	__sdkman_update_broadcast "${broadcast_id}"
}

function __sdkman_update_broadcast {
	local broadcast_live_id broadcast_id_file broadcast_text_file broadcast_old_id

	broadcast_live_id="${1}"
	broadcast_id_file="${SDKMAN_DIR}/var/broadcast_id"
	broadcast_text_file="${SDKMAN_DIR}/var/broadcast"

	if [[ -f "${broadcast_id_file}" ]]; then
		broadcast_old_id=$(< "${broadcast_id_file}")
	else
		broadcast_old_id=
	fi

	if [[ -f "${broadcast_text_file}" ]]; then
		BROADCAST_OLD_TEXT=$(< "${broadcast_text_file}")
	fi

	if [[ "${SDKMAN_AVAILABLE}" == 'true' && "${broadcast_live_id}" != "${broadcast_old_id}" && "${COMMAND}" != 'selfupdate' && "${COMMAND}" != 'flush' ]]; then
		mkdir -p "${SDKMAN_DIR}/var"

		echo "${broadcast_live_id}" | tee "${broadcast_id_file}" > /dev/null

		BROADCAST_LIVE_TEXT=$(__sdkman_secure_curl "${SDKMAN_CANDIDATES_API}/broadcast/latest")
		echo "${BROADCAST_LIVE_TEXT}" | tee "${broadcast_text_file}" > /dev/null
		if [[ "${COMMAND}" != 'broadcast' ]]; then
			__sdkman_echo_cyan "${BROADCAST_LIVE_TEXT}"
		fi
	fi
}
