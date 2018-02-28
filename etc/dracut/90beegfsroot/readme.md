<!--
sNow! Cluster Manager provides all the required elements to deploy, manage an HPC cluster
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
-->
# beegfsroot 
This dracut module allows to boot a diskless system by using a read-only root file system provided by BeeGFS. 

Thanks to list of files available in /etc/rwtab it allows to modify them using tmpfs

Developed by Jordi Blasco <jordi.blasco@hpcnow.com> as part of sNow! Cluster manager

More information available here: http://snow.hpcnow.com

## Available options are specified with the following syntax:
* beegfs_rootfs=/path/to/rootfs
* beegfs_mgmt=beegfs01
