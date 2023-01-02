#!/usr/bin/env bash

# MIT License

# Copyright (c) 2022-2023 Jason Scheunemann <jason.scheunemann@gmail.com>

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

SCRIPT_FULL_PATH=$(realpath ${0})
SCRIPT_DIRNAME=$(dirname ${SCRIPT_FULL_PATH})
SCRIPT_FILENAME=$(basename ${0})
SCRIPT_FRIENDLY_NAME=${SCRIPT_FILENAME%.*}

case $(uname -s | tr '[:upper:]' '[:lower:]') in
	darwin)
		if [ $(command -v gdate | wc -l) -gt 0 ]; then
			DATE_CMD='gdate'
		else
			DATE_CMD='date'
		fi
		;;
	*)
		DATE_CMD='date'
		;;
esac

if [ -z "${BASH_LOGGER_SESSION_ID}" ]; then
	if [ $(command -v uuidgen | wc -l) -gt 0 ]; then
		BASH_LOGGER_SESSION_ID="$(uuidgen | tr '[:upper:]' '[:lower:]')"
	elif [ -f "/proc/sys/kernel/random/uuid" ]; then
		BASH_LOGGER_SESSION_ID="$(cat /proc/sys/kernel/random/uuid | tr '[:upper:]' '[:lower:]')"
	else
		echo "Fatal error, missing uuid generator dependency"
		exit 1
	fi
fi

BASH_LOGGER_EMERG_LOGFILE="/dev/null"
BASH_LOGGER_ALERT_LOGFILE="/dev/null"
BASH_LOGGER_CRIT_LOGFILE="/dev/null"
BASH_LOGGER_ERROR_LOGFILE="/dev/null"
BASH_LOGGER_WARN_LOGFILE="/dev/null"
BASH_LOGGER_NOTICE_LOGFILE="/dev/null"
BASH_LOGGER_INFO_LOGFILE="/dev/null"
BASH_LOGGER_DEBUG_LOGFILE="/dev/null"

declare -A SeverityLevel
SeverityLevel[emergency]="EMERG"
SeverityLevel[alert]="ALERT"
SeverityLevel[critical]="CRIT"
SeverityLevel[error]="ERROR"
SeverityLevel[warning]="WARN"
SeverityLevel[notice]="NOTICE"
SeverityLevel[informational]="INFO"
SeverityLevel[debug]="DEBUG"

declare -A SeverityIndex
SeverityIndex[${SeverityLevel[emergency]}]=8
SeverityIndex[${SeverityLevel[alert]}]=7
SeverityIndex[${SeverityLevel[critical]}]=6
SeverityIndex[${SeverityLevel[error]}]=5
SeverityIndex[${SeverityLevel[warning]}]=4
SeverityIndex[${SeverityLevel[notice]}]=3
SeverityIndex[${SeverityLevel[informational]}]=2
SeverityIndex[${SeverityLevel[debug]}]=1

LOG_TO_STDOUT_SEVERITY="${SeverityLevel[informational]}"

function bash_logger_set_emergency_logfile() {
	BASH_LOGGER_EMERG_LOGFILE="${1}"
}

function bash_logger_set_alert_logfile() {
	BASH_LOGGER_ALERT_LOGFILE="${1}"
}

function bash_logger_set_critical_logfile() {
	BASH_LOGGER_CRIT_LOGFILE="${1}"
}

function bash_logger_set_error_logfile() {
	BASH_LOGGER_ERROR_LOGFILE="${1}"
}

function bash_logger_set_warn_logfile() {
	BASH_LOGGER_WARN_LOGFILE="${1}"
}

function bash_logger_set_notice_logfile() {
	BASH_LOGGER_NOTICE_LOGFILE="${1}"
}

function bash_logger_set_info_logfile() {
	BASH_LOGGER_INFO_LOGFILE="${1}"
}

function bash_logger_set_debug_logfile() {
	BASH_LOGGER_DEBUG_LOGFILE="${1}"
}

function bash_logger_set_base_dir() {
	BASH_LOGGER_BASE_DIR="${1}"
}

function log2stdout() {
	LOG_TO_STDOUT=1

	if [ ! -z "${1}" ]; then
		LOG_TO_STDOUT_SEVERITY="${1}"
	fi
}

function preprocess_json() {
	local bs="\\"
	local sq=\'
	local dq=\"
	echo "$(echo -n "${1}" | sed -r 's/\\([abtnvfre\"])/>><<>><<\1/g' | sed -z "s/${bs}${bs}${sq}/>><<>><<${sq}/g" | sed -z "s/${dq}/${bs}${bs}${dq}/g" | sed -z "s/${bs}${bs}${bs}${bs}${dq}/${bs}${bs}${bs}${bs}${bs}${bs}${dq}/g" | sed -z 's/\n/\\\\n/g' | sed -z 's/\r/\\r/g' | sed -z 's/\t/\\t/g' | sed -z "s/>><<>><<${sq}/${bs}${bs}${bs}${bs}${bs}${bs}${bs}${bs}${sq}/g" | sed -r 's/>><<>><<([abtnvfre\"])/\\\\\\\\\1/g' | tr -dc '[:print:]\t\n\r')"
}

function json_postprocess() {
	local bs="\\"
	local sq=\'
	local dq=\"
	echo "$(echo -n "${1}" | sed -r 's/\\\\\\\\([abtnvfre\"])/>><<>><<\1/g' | sed -z "s/${bs}${bs}${bs}${bs}${sq}/${sq}/g" | sed -z "s/${bs}${bs}${dq}/${dq}/g" | sed -z "s/${bs}${bs}${bs}${bs}${bs}${bs}${dq}/${bs}${dq}/g" | sed -z 's/\\\\n/\n/g' | sed -r 's/>><<>><<([abtnvfre\"])/\\\\\1/g')"
}

function _log() {
	LEVEL="${1}"
	MESSAGE="${2}"

	shift
	shift

	unset LOG_SOURCE
	unset LOG_LINE_NUMBER
	unset PROCESS_ID

	declare -A JSON_STR

	while [[ ${#} -gt "0" ]]; do
		KEY="${1}"

		case "${KEY}" in 
			-s | --source)
				LOG_SOURCE="${2}"
				shift
				shift;;

			-l | --line-number)
				LOG_LINE_NUMBER="${2}"
				shift
				shift;;
			-p | --pid)
				PROCESS_ID="${2}"
				shift
				shift;;
			-a | --attribute)
				_KEY="$(echo "${2}" | cut -d= -f1)"
				_VAL="$(echo "${2}" | cut -d= -f2-)"
				JSON_STR[${_KEY}]="$(preprocess_json "${_VAL}")"
				shift
				shift;;
			*)
				echo "Fatal error, log command line argument not recognized"
				exit 1;;
		esac
	done

	if [ -z "${BASH_LOGGER_BASE_DIR}" ]; then
		BASH_LOGGER_BASE_DIR="${SCRIPT_DIRNAME}"
	fi

	if [ -z "${LOG_SOURCE}" ]; then
		LOG_SOURCE="$(realpath ${BASH_SOURCE[-1]})"
	fi

	if [ -z "${LOG_LINE_NUMBER}" ]; then
		LOG_LINE_NUMBER="${BASH_LINENO[-2]}"
	fi

	if [ -z "${PROCESS_ID}" ]; then
		PROCESS_ID="${$}"
	fi

	TIMESTAMP="$(${DATE_CMD} "+%Y-%m-%dT%H:%M:%S.%3N%z")"
	SOURCE="${LOG_SOURCE}:${LOG_LINE_NUMBER}"

	LEVEL="${LEVEL}"
	MESSAGE="$(preprocess_json "${MESSAGE}")"
	TIMESTAMP="${TIMESTAMP}"

	if [ $(echo ${SOURCE} | grep -c "^${BASH_LOGGER_BASE_DIR}") -gt 0 ]; then
		SOURCE="$(echo ${SOURCE} | sed "s|^${BASH_LOGGER_BASE_DIR}||g" | sed "s|^/||g")"
	fi

	JSON_STR[session]="${BASH_LOGGER_SESSION_ID}"
	JSON_STR[pid]="${PROCESS_ID}"
	JSON_STR[level]="${LEVEL}"
	JSON_STR[message]="${MESSAGE}"
	JSON_STR[timestamp]="${TIMESTAMP}"
	JSON_STR[source]="${SOURCE}"

	ARGS="$(for x in "${!JSON_STR[@]}"; do
		printf "\"%s\":\"%s\"," "${x}" "${JSON_STR[${x}]}"
	done)"

	OLD_IFS="${IFS}"
	IFS=""
	JSON_STRING="{${ARGS::-1}}"
	IFS="${OLD_IFS}"

	case "${LEVEL}" in
		${SeverityLevel[emergency]})
			echo "${JSON_STRING}" >> "${BASH_LOGGER_EMERG_LOGFILE}"
			;&
		${SeverityLevel[alert]})
			echo "${JSON_STRING}" >> "${BASH_LOGGER_ALERT_LOGFILE}"
			;&
		${SeverityLevel[critical]})
			echo "${JSON_STRING}" >> "${BASH_LOGGER_CRIT_LOGFILE}"
			;&
		${SeverityLevel[error]})
			echo "${JSON_STRING}" >> "${BASH_LOGGER_ERROR_LOGFILE}"
			;&
		${SeverityLevel[warning]})
			echo "${JSON_STRING}" >> "${BASH_LOGGER_WARN_LOGFILE}"
			;&
		${SeverityLevel[notice]})
			echo "${JSON_STRING}" >> "${BASH_LOGGER_NOTICE_LOGFILE}"
			;&
		${SeverityLevel[informational]})
			echo "${JSON_STRING}" >> "${BASH_LOGGER_INFO_LOGFILE}"
			;&
		${SeverityLevel[debug]})
			echo "${JSON_STRING}" >> "${BASH_LOGGER_DEBUG_LOGFILE}"
			;;
		*)
			echo "Critical Error, \"${LEVEL}\" is not a valid log severity level"
			exit 1
			;;
	esac

	if [ ! -z "${LOG_TO_STDOUT}" ]; then
		if [ "${SeverityIndex[${LEVEL}]}" -ge "${SeverityIndex[${LOG_TO_STDOUT_SEVERITY}]}" ]; then
			echo -e "$(printf "%-8s%s => %s\n" "${LEVEL}" "${SOURCE}" "$(json_postprocess "${MESSAGE}")")"
		fi
	fi
}

function log_emergency() {
	_log "${SeverityLevel[emergency]}" "${@}"
}

function log_alert() {
	_log "${SeverityLevel[alert]}" "${@}"
}

function log_critical() {
	_log "${SeverityLevel[critical]}" "${@}"
}

function log_error() {
	_log "${SeverityLevel[error]}" "${@}"
}

function log_warning() {
	_log "${SeverityLevel[warning]}" "${@}"
}

function log_notice() {
	_log "${SeverityLevel[notice]}" "${@}"
}

function log_info() {
	_log "${SeverityLevel[informational]}" "${@}"
}
	
function log_debug() {
	_log "${SeverityLevel[debug]}" "${@}"
}
