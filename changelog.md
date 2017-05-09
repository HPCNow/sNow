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

## 1.1.2

### New Features and changes
* Increased memory of snow server to 8GB
* Included installation proxy per node basis in order to achieve better scalability in the deployment
### Minor fixes
* Fixed OpenVPN AS role deployment
* introduced ConnectTimeout=5 in snow list domains to avoid long waiting when a domain is not responsive
* Fixed minor coding style issues

## 1.1.3

### Minor fixes

* Fixed issue with public instance of ssh in login role
* Introduced a delay after each domain booted while booting them all with snow boot domains to improve server responsiveness in the bridge management
* Fixed issues related with gmetad
* Fixed issue related with resolv.conf content
* Fixed issues related with xdm and gdm  roles
* Minor improvements in the minimal role

## 1.1.4

### New Features and changes
* Included Docker support in domain roles
* included Docker Swarm roles (swarm-manager, swarm-worker) to accommodate docker based services.
* Included torque master role. The support of Torque in sNow is not as mature as slurm.

### Minor fixes
* interactive CLI not longer requires a Slurm account

## 1.1.5

### New Features and changes
* Included logic in the Torque and Maui role deployment in order to avoid incompatibility issues
* Included support for Torque and Maui in the node deployment

### Minor fixes
* included list roles in the snow CLI error message