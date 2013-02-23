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

# notify flag
notify=0


# === ~ === ~ === ~ === ~ === ~ === ~ === ~ === ~ === ~ === ~ ===
# FUNCTIONS

# 
# libnotifyinstall()
#
# installs libnotify-bin
#
# Parameters:
#   N/A
#

libnotifyinstall() {

  checkubuntu=`cat /etc/lsb-release | head -n1 | awk -F"DISTRIB_ID=" '{ print $2 }'`

  if [[ "${checkubuntu}" = "Ubuntu" ]]; then
    if ! which notify-send > /dev/null; then
      echo -e "  Do you want to install libnotify-bin? \b"
      echo -e "  This allows desktop notifications. \b"
      echo ""
      echo -e "  If you choose to do this, the following will execute: \b"
      echo ""
      echo "      $ sudo apt-get install libnotify-bin"
      echo ""
      echo -e "  (y/n) \c"
      read -n1 reply
      if [[ "$reply" = "y" ]]; then
        echo -e "  >>> Installing... \b"
        echo ""
        sudo apt-get install libnotify-bin
        notify=1
      fi
    else
      notify=1
    fi
  fi

}

# 
# notify()
#
# desktop notifications
#
# Parameters:
#   $1 - Notification text (first line)
#   $2 - Notification text (second line)
#

notify() {

  if [[ ${notify} -eq 1 ]]; then
    notify-send "$1" \
                "$2"
  fi

}

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

  echo "# Mounting $5" >> ${log}
  echo "sshfs -o idmap=${1} ${2}@${3}:${4} ${5}" >> ${log}

  sshfs -o idmap=${1} ${2}@${3}:${4} ${5}
  echo "done" >> ${log}
  echo " " >> ${log}
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
      echo "# Killing sshfs" >> ${log}
      killall sshfs
      echo "done" >> ${log}
      echo " " >> ${log}

      # umounts sshfs locations
      echo "# Umounting ${mountpoint}" >> ${log}
      sudo umount ${mountpoint}
      echo "done" >> ${log}
      echo " " >> ${log}
      
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
echo "#" >> ${log}
echo "#   ${initdate}" >> ${log}
echo "#   mount flag: ${mountflag}" >> ${log}
echo " " >> ${log}

# offer to install libnotify-bin
libnotifyinstall

notify "sshfsmount: START" "Mount flag is ${mountflag}"

if [[ "${mountflag}" = "mount" ]]; then
  # guarantee system is up and running before continuing
  sleep ${sleepdefault}
  sshfsmount_all
elif [[ "${mountflag}" = "re-mount" ]]; then
  sshfsumount_all
  sshfsmount_all
else
  notify "sshfsmount: ERROR invalid flag"
  echo "ERROR: ${runningscript}: Invalid flag. It should be mount or re-mount."
  echo "Example: sshfsmount.sh mount"
fi

# remove older log files
echo "# Removing older log files..." >> ${log}
echo "find ${basedir}/${logdir}/*.log -mtime +${purgedefault} -exec rm {} \;" >> ${log}
find ${basedir}/${logdir}/*.log -mtime +${purgedefault} -exec rm {} \; >> ${log}
echo "done" >> ${log}
echo " " >> ${log}

# end date
enddate=`date "+%Y-%m-%d %H:%M:%S"`

echo " "
echo "#   ${enddate}" >> ${log}

notify "sshfsmount: END"

#eof