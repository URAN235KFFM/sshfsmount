#!/bin/bash

#===============================================================================
#
#    Author: Paulo Pereira <sshfsmount@lofspot.net>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program in the file LICENSE.  If not, see 
#    <http://www.gnu.org/licenses/>.
#
#===============================================================================
#
#    DESCRIPTION:
#       Keeps sshfs mountpoints in a local machine
#
#    PARAMETERS:
#       $1 - flag to mount or re-mount the mountpoints (mount | re-mount)
#
#    EXAMPLE:
#       sshfsmount.sh mount
#
#===============================================================================

# === ~ === ~ === ~ === ~ === ~ === ~ === ~ === ~ === ~ === ~ ===
# CONFIGURATION

# config files
runningscript=`basename "$0"`
basedir=`echo "$0" | awk -F"${runningscript}" '{ print $1 }'`
if [[ "${basedir}" = "./" ]]; then
  basedir=`pwd`
fi
configdir=${basedir}/config
. ${configdir}/sshfsmount.conf

# log
log=${basedir}/${logdir}/sshfsmount.`date "+%Y%m%d.%H%M%S"`.log

# mount flag
mountflag=$1


# === ~ === ~ === ~ === ~ === ~ === ~ === ~ === ~ === ~ === ~ ===
# FUNCTIONS

# 
# sshfsmount()
#
# mounts the sshfs locations
#
# Parameters:
#   $1 - idmapuser
#   $2 - serveruser
#   $3 - server
#   $4 - serverdir
#   $5 - mountpoint
#
sshfsmount() {

  # echo "sshfs -o idmap=${1} ${2}@${3}:${4} ${5}"
  sshfs -o idmap=${1} ${2}@${3}:${4} ${5}
}

# 
# sshfsmount_all()
#
# mounts all the sshfs locations
#
# Parameters:
#   N/A
#
sshfsmount_all() {

  while read line; do
    # ignore comments
    if ! [[ "${line:0:1}" = "#" ]] ; then

      # get parameters
      idmapuser=$(echo "$line" | cut -d';' -f1)
      if [[ "${idmapuser}" = "" ]]; then
        idmapuser=${idmapuserdefault}
      fi
      serveruser=$(echo "$line" | cut -d';' -f2)
      server=$(echo "$line" | cut -d';' -f3)
      serverdir=$(echo "$line" | cut -d';' -f4)
      mountpoint=$(echo "$line" | cut -d';' -f5)

      # mount sshfs location
      sshfsmount "${idmapuser}" "${serveruser}" "${server}" "${serverdir}" "${mountpoint}"
    fi
  done < ${basedir}/${sshfstab}
}

# 
# sshfsumount_all()
#
# kills sshfs and unmounts all the sshfs locations
#
# Parameters:
#   N/A
#
sshfsumount_all() {

  while read line; do
    # ignore comments
    if ! [[ "${line:0:1}" = "#" ]] ; then

      # get parameters
      idmapuser=$(echo "$line" | cut -d';' -f1)
      if [[ "${idmapuser}" = "" ]]; then
        idmapuser=${idmapuserdefault}
      fi
      serveruser=$(echo "$line" | cut -d';' -f2)
      server=$(echo "$line" | cut -d';' -f3)
      serverdir=$(echo "$line" | cut -d';' -f4)
      mountpoint=$(echo "$line" | cut -d';' -f5)

      # kills sshfs 
      killall sshfs
      # umounts sshfs locations
      sudo umount ${mountpoint}
      # mount sshfs location
      sshfsmount ${idmapuser} ${serveruser} ${server} ${serverdir} ${mountpoint}
    fi
  done < ${basedir}/${sshfstab}
}


# === ~ === ~ === ~ === ~ === ~ === ~ === ~ === ~ === ~ === ~ ===
# MAIN

# initial date
initdate=`date "+%Y-%m-%d %H:%M:%S"`

echo "#===============================================================================" > ${log}
echo ">>> ${initdate}" >> ${log}
echo " " >> ${log}
echo "mount flag: ${mountflag}" >> ${log}
echo " " >> ${log}

if [[ "${mountflag}" = "mount" ]]; then
  # guarantee system is up and running before continuing
  sleep 40
  sshfsmount_all >> ${log}
elif [[ "${mountflag}" = "re-mount" ]]; then
  sshfsumount_all >> ${log}
  sshfsmount_all >> ${log}
else
  echo "ERROR: ${runningscript}: Invalid flag. It should be mount or re-mount."
  echo "Example: sshfsmount.sh mount"
fi

# remove older log files
find ${basedir}/${logdir}/*.log -mtime +30 -exec rm {} \; >> ${log}

# end date
enddate=`date "+%Y-%m-%d %H:%M:%S"`

echo ">>> ${enddate}" >> ${log}

#eof