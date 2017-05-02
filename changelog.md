## 1.1.0
### Major fixes

* FIX default console options and install repo
* FIX issue #63 - missing mail program and empty license variable
* Included error trapping in snow set node function
* FIX issue #3 - dom0 memory limits
* Fix user home creation on login
* Add skel and ACL on user home creation
* Fix permissions and owner for sssd.conf to be able to start the daemon
* Fix: NET_LLF is optional
* Fix enable public ssh instance in login role
* Patch network config in centos with linkdelay=20 in order to fix issues with some 10Gb devices
* Fix IPv6 issues related with RPCbind Server Activation Socket.


### New Features and Changes

* included OpenSUSE Leap 42.2 template
* Diskless image support based on read-only nfsroot image
* Included "set node" function in order to setup node based parameters
* Extended snow "add node" function
* Integrated database for compute nodes
* Merged node_list function as a part of boot function
* Included default image and template per node if defined in the database
* The functions nreboot, npoweroff, nshutdown are now supporting a node list rather than just a range
* included cpus, memory and disk size in the description of json file, as part of set_snow_json function
* included last_deploy in the description of json file, as part of set_snow_json function
* Included new CentOS 7.3 template with minimal packages
* Included more comments in the snow.conf-example and renamed/removed some confusing variables.
* Included logic for accommodating default node-based template
* snow-install has been merged in this repository
* Improvements in nfsroot and squashfs support
* Included show nodes feature
* Included snow list roles function. The style of the role scripts are normalised
* Included chroot enviroment function
* Included new functions to create raids and filesystems. Included an example of first_boot_hook
* Improved eb_wrap and interactive. 
* Fairsharing is not longer default requirement. AccountingStorageEnforce=nojobs
* Readahead operations disabled in the centos template in order to avoid performance issues in shared FS.
* Removed System Imager from deploy role, as not longer required
* Included memtest as image
* Removed boot_delay in the boot process as it's only required in deploy process
* Introduced NET_COMP in order to define the DHCP service for the compute nodes


### Known Issues

* Read-only NFSROOT image only working for CentOS/RHEL. Tuned dracut module is required to enable it for SuSE


## 1.1.1

### Major fixes

* Fix issue related with multicluster in ganglia monitoring
* Fix issue with minimal domain role deployment