#!/usr/bin/env bash

# MIT License

# Copyright (c) 2022 jscheunemann

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
	export BASH_LOGGER_DEBUG_LOGFILE="${1}"
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

function _log() {
	LEVEL="${1}"
	MESSAGE="${2}"

	shift
	shift

	unset LOG_SOURCE
	unset LOG_LINE_NUMBER

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
			*)
				echo "Fatal error, log command not recognized"
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


	TIMESTAMP="$(${DATE_CMD} "+%Y-%m-%dT%H:%M:%S.%3N%z")"
	SOURCE="${LOG_SOURCE}:${LOG_LINE_NUMBER}"

	if [ $(echo ${SOURCE} | grep -c "^${BASH_LOGGER_BASE_DIR}") -gt 0 ]; then
		SOURCE="$(echo ${SOURCE} | sed "s|^${BASH_LOGGER_BASE_DIR}||g" | sed "s|^/||g")"
	fi

	if [ $(command -v jq | wc -l) -eq 0 ]; then
		JSON_MESSAGE=$(echo "${MESSAGE} "| sed -E 's/([^\]|^)"/\1\\"/g' | sed -z 's/\n/\\n/g' | sed 's/\\n//g' | xargs)

		if [ ! -z "${VERSION}" ]; then
			JSON_STRING="{\"level\": \"${LEVEL}\", \"message\": \"${JSON_MESSAGE}\", \"version\": \"${VERSION}\", \"timestamp\": \"${TIMESTAMP}\", \"source\": \"${SOURCE}\"}"
		else
			JSON_STRING="{\"level\": \"${LEVEL}\", \"message\": \"${JSON_MESSAGE}\", \"timestamp\": \"${TIMESTAMP}\", \"source\": \"${SOURCE}\"}"
		fi
	else
		if [ ! -z "${VERSION}" ]; then
			JSON_STRING=$(jq -cn \
				--arg level "${LEVEL}" \
				--arg message "${MESSAGE}" \
				--arg version "${VERSION}" \
				--arg timestamp "${TIMESTAMP}" \
				--arg source "${SOURCE}" \
				'{level: $level, message: $message, version: $version, timestamp: $timestamp, source: $source}')
		else
			JSON_STRING=$(jq -cn \
				--arg level "${LEVEL}" \
				--arg message "${MESSAGE}" \
				--arg timestamp "${TIMESTAMP}" \
				--arg source "${SOURCE}" \
				'{level: $level, message: $message, timestamp: $timestamp, source: $source}')
		fi
	fi

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
			printf "%-8s%s => %s\n" "${LEVEL}" "${SOURCE}" "${MESSAGE}"
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
