# beegfsroot 
This dracut module allows to boot a diskless system by using a read-only root file system provided by BeeGFS. 
Thanks to list of files available in /etc/rwtab it allows to modify them using tmpfs
Developed by Jordi Blasco <jordi.blasco@hpcnow.com> as part of sNow! Cluster manager
More information available here: http://snow.hpcnow.com

## Available options are specified with the following syntax:
* beegfs_rootfs=/path/to/rootfs
* beegfs_mgmt=beegfs01
