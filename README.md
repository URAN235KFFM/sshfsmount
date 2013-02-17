sshfsmount
==========

Script for keeping sshfs mountpoints in a local machine


Configuration
=============

Go to config/sshfstab to configure your mountpoints.

Also, make sure the sshfsmount.sh is executable

	$ chmod +x sshfsmount.sh


Running
=======

Option 1: Mount all your mountpoints

	$ ./sshfsmount.sh mount

	or

	$ /home/user/sshfsmount.sh mount

Option 2: Re-mount all your mountpoints


	$ ./sshfsmount.sh re-mount

	or

	$ /home/user/sshfsmount.sh re-mount