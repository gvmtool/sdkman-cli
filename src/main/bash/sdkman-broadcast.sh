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

function __sdk_broadcast {
	__sdkman_validate_no_arguments "sdk ${COMMAND}" "${@}" || return 1

	if [ "${BROADCAST_OLD_TEXT}" ]; then
		__sdkman_echo_cyan "${BROADCAST_OLD_TEXT}"
	else
		__sdkman_echo_cyan "${BROADCAST_LIVE_TEXT}"
	fi
}
