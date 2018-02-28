```
sNow! Cluster Manager
Copyright (C) 2008 Jordi Blasco

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

sNow! Cluster Suite is an opensource project developed by Jordi Blasco <jordi.blasco@hpcnow.com>
For more information, visit the official website: www.hpcnow.com/snow
```
# overlayroot 
This dracut module allows to boot a diskless system by using a read-only root file system provided as SquashFS image or mounting a folder shared by NFS, BeeGFS or Lustre which contains the OS file system. 

Thanks to overlay allows to write files on top of tmpfs to enable stateless setup

Developed by Jordi Blasco <jordi.blasco@hpcnow.com> as part of sNow! Cluster manager

More information available here: http://snow.hpcnow.com

## Available options
* overlay_rootfs=http://server/path/to/file/rootfs.squashfs
* overlay_type=<squashfs|nfs|lustre|beegfs>
* overlay_opts=ro
