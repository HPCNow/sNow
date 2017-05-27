# overlayroot 
This dracut module allows to boot a diskless system by using a read-only root file system provided as SquashFS image or mounting a folder shared by NFS, BeeGFS or Lustre which contains the OS file system. 
Thanks to overlay allows to write files on top of tmpfs to enable stateless setup
Developed by Jordi Blasco <jordi.blasco@hpcnow.com> as part of sNow! Cluster manager
More information available here: http://snow.hpcnow.com

## Available options
* overlay_rootfs=http://server/path/to/file/rootfs.squashfs
* overlay_type=<squashfs|nfs|lustre|beegfs>
* overlay_opts=ro
