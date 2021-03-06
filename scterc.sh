#!/bin/sh

# PROVIDE: scterc
# REQUIRE: LOGIN
# KEYWORD: nojail
#
# Add the following lines to /etc/rc.conf to enable changing SCT
# (SMART Control Transport) ERC (Error Recovery Control) settings
# on your disks at boot time
#
# scterc_enable:                Set to "YES" to enable configuring SCT ERC
#
# scterc_disks:                 Space separated list of disk devices to
#                               configure in either "/dev/ada0" or "ada0"
#                               format
# scterc_read_timeout:          Set default read timeout in tenths of a
#                               second or 0 for infinity. Default is 70
#                               (7 seconds)
# scterc_write_timeout:         Set default write timeout in tenths of a
#                               second or 0 for infinity. Default is 70
#                               (7 seconds)
#
# scterc_groups:                Space separated list of disk groups. Use if
#                               you need different settings for specific
#                               disk groups.
# scterc_{group}_disks:         List of disks for a group
# scterc_{group}_read_timeout:  Read timeout for a group (defaults to
#                               scterc_read_timeout if not specified)
# scterc_{group}_write_timeout: Write timeout for a group (defauts to
#                               scterc_write_timeout if not specified)
#

. /etc/rc.subr

name="scterc"
rcvar="scterc_enable"

load_rc_config $name

: ${scterc_enable="YES"}
: ${scterc_disks=""}
: ${scterc_read_timeout="70"}
: ${scterc_write_timeout="70"}
: ${scterc_groups=""}

command="/usr/local/sbin/smartctl"
start_cmd="scterc_start"
stop_cmd=":"

scterc_start()
{
	local _group _disks _read_timeout _write_timeout _disk _device _result

	check_startmsgs && echo -n 'Setting SCT ERC on disks:'

	for _group in '' ${scterc_groups}; do
		if [ -z "$_group" ]; then
			# handle default group
			_disks="${scterc_disks}"
			_read_timeout="${scterc_read_timeout}"
			_write_timeout="${scterc_write_timeout}"
		else
			# handle real groups
			eval _disks=\"\${scterc_${_group}_disks}\"
			eval _read_timeout=\"\${scterc_${_group}_read_timeout:-${scterc_read_timeout}}\"
			eval _write_timeout=\"\${scterc_${_group}_write_timeout:-${scterc_write_timeout}}\"
		fi

		for _disk in ${_disks}; do
			if echo "$_disk" | grep -q ^/; then
				_device="${_disk}"
			else
				_device="/dev/${_disk}"
			fi

			$command -l "scterc,${_read_timeout},${_write_timeout}" "$_device" >/dev/null 2>&1
			_result=$?

			if check_startmsgs; then
				if [ "${_result}" -eq 0 ]; then
					echo -n " $_disk:${_read_timeout},${_write_timeout}"
				else
					echo -n " $_disk:FAILED"
				fi
			fi
		done
	done

	echo '.'
}

run_rc_command "$1"
