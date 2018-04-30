## 1.1.0
### Major Fixes

* FIX default console options and install repo
* FIX issue #63 - missing mail program and empty license variable
* Included error trapping in snow set node function
* FIX issue #3 - dom0 memory limits
* Fix user home creation on login
* Add skel and ACL on user home creation
* Fix permissions and owner for sssd.conf to be able to start the daemon
* Fix: NET_LLF is optional
* Fix enable public ssh instance in login role
* Patch network config in CentOS with linkdelay=20 in order to fix issues with some 10Gb devices
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
* Included chroot environment function
* Included new functions to create raids and filesystems. Included an example of first_boot_hook
* Improved eb_wrap and interactive.
* Fairsharing is not longer default requirement. AccountingStorageEnforce=nojobs
* Readahead operations disabled in the CentOS template in order to avoid performance issues in shared FS.
* Removed System Imager from deploy role, as not longer required
* Included memtest as image
* Removed boot_delay in the boot process as it's only required in deploy process
* Introduced NET_COMP in order to define the DHCP service for the compute nodes


### Known Issues

* Read-only NFSROOT image only working for CentOS/RHEL. Tuned dracut module is required to enable it for SuSE


## 1.1.1

### Major Fixes

* Fix issue related with multi-cluster in ganglia monitoring
* Fix issue with minimal domain role deployment

## 1.1.2

### New Features and Changes
* Increased memory of snow server to 8GB
* Included installation proxy per node basis in order to achieve better scalability in the deployment
### Minor Fixes
* Fixed OpenVPN AS role deployment
* introduced ConnectTimeout=5 in snow list domains to avoid long waiting when a domain is not responsive
* Fixed minor coding style issues

## 1.1.3

### Minor Fixes

* Fixed issue with public instance of ssh in login role
* Introduced a delay after each domain booted while booting them all with snow boot domains to improve server responsiveness in the bridge management
* Fixed issues related with gmetad
* Fixed issue related with resolv.conf content
* Fixed issues related with xdm and gdm  roles
* Minor improvements in the minimal role

## 1.1.4

### New Features and Changes
* Included Docker support in domain roles
* included Docker Swarm roles (swarm-manager, swarm-worker) to accommodate docker based services.
* Included torque master role. The support of Torque in sNow is not as mature as Slurm.

### Minor Fixes
* interactive CLI not longer requires a Slurm account

## 1.1.5

### New Features and Changes
* Included logic in the Torque and Maui role deployment in order to avoid incompatibility issues
* Included support for Torque and Maui in the node deployment

### Minor Fixes
* included list roles in the snow CLI error message

## 1.1.6

### New Features and Changes
* Initial support for GateOne
* Improvements in ganglia setup - use unicast

### Minor Fixes
* Fix minor issues in Torque 5.3.1 services startup
* Fix issue 114 - snow add node populates the database as expected
* Fix issue 111 - check if a node list is already defined in the database
* Fix issue 118 - corrected squid3 path /var/spool/squid3
* Fix issue 115 - replaced error message with an error exit when trying to add nodes that already exist in the database.
* Fix issue 115 - moved interactive question in node remove outside the loop
* Fix issue 123 - included NTP configuration in compute nodes

## 1.1.7

### New Features and Changes
* Fixed path divergency in SuSE for /usr/lib/systemd/system in dracut
* Stateless based on SquashFS + OverlayFS working for (Open)SuSE and RHEL/CentOS
* Included image_rootfs and image_type in the database.

### Major Fixes
* Remote file systems are excluded during the image generation. mksquasfs uses xz compression. Improvements in dracut support for SuSE
* Included /etc/resolv.conf to avoid potential issues related with DNS service not available while mounting NFS or cluster file systems in the boot time

### Minor Fixes
* Fix issue 5 - update snow.conf permissions to 600 after snow init.
* Fix issue 122 - 'snow show nodes' prints also the host name
* Fix issue 66 - included warning message in /etc/hosts

### Known Issues
* Included NFSROOT option in overlayfs but it doesn't allow to apply live changes in ro NFS image due a bug in OverlayFS. Remount is required to enable changes performed in NFS image.

## 1.1.8

### New Features and Changes
* "snow list domains" command also includes the hosts where the domains are allocated

### Minor Fixes
* Fix issue related with user environment under interactive job session

## 1.1.9

### New Features and Changes
* list domains provides High Availability and service locality information

## 1.1.10

### New Features and Changes
* LDAP master role generates certificates and populates the DB
* LDAP DB has been migrated from HDB to MDB (new standard)
* Improved privacy and security in default LDAP role

### Minor Fixes
* Fix issue 123: automatic start of NTPD at boot time
* Fix recurrent issue 3: dom0 dedicated memory and preventing dom0 memory ballooning
* Fix issue 131: no exit after trying to boot a non-deployed domain

### Major Fixes
* Fix broken compatibility in LDAP deployment due new standards

## 1.1.11

### New Features and Changes
* New domain role for BeeGFS server deployment
* BeeGFS native client support
* BeeGFS stateless image support - tested in CentOS 7.x
* Lustre stateless image support - tested in CentOS 7.x
* Support for Debian preseed deployment (partially fix issue #84 - deploy with ubuntu is still missing)
* New deployment template for Debian 8.x
* New deployment template for Debian 9.x
* New deployment template for CentOS 7.4
* Included GRES requirement in interactive
* updated cpu-id-map to include Skylake architecture

### Minor Fixes
* Fix delay issue listing images.
* Minor fix in OS release detection in install.sh
* Included libx11-devel and openssl-devel to meet the OS packages requirements for some applications
* Clean-up slurm job epilog and prolog
* Fixed issue 125: Included DNS search list to snow.conf
* Updated README files (fix issue #140)
* sNow! CLI help more human readable (fix issue #126)
* Fixed issue #139: check if snow CLI is executed by root
* Fixed issue #138: style issue in the "snow list domains" output

### Major Fixes
* Fixed delay issues in diskless boot.
* Fixed issues with stateless shutdowns due network stop before unmounting CFS.
* Fixed ganglia configuration per cluster nodes.

### Known Issues
* Diskless based on OverlayFSroot over BeeGFS is fixed, but bug in systemd-machine-id-commit still affects old kernels < 4.2. There is a workaround to systemd-machine-id-commit + overlayfs bug (hostname) but not fully tested.

## 1.1.12

### New Features and Changes
* Included icinga2 role (web based setup not automated, so manual intervention is required after the deployment).
* Included native support with Singularity based on HPCNow! repository

### Minor Fixes
* Fix typo in warning_message -> warning_msg.
* Fix missing config file in memtest and localboot images.
* Slurm configuration template updated in order to pick up changes in the latest release
* Updated NFS server configuration with async for /sNow.
* Default NFS mount options noatime and nodiratime in the clients.
* Included performance considerations notes in the snow.conf-example
* Updated slurdmdb configuration in order to fix issues with user creation.
* SlurmDB user is root, in order to have consistency with SlurmCTLD user.
* Updated the order of active-domains.conf-example to match the domain deployment order
* Increased the number of loopback devices to 64 when virtualisation technology selected it Xen

### Major Fixes
* Fix memtest image url.

## 1.1.13

### New Features and Changes
* Included unattended installation in order to accommodate CI/CD
* Included force option in snow init command
* Included additional logic to manage boot/shutdown domains in HA mode
* Boot function is now breakdown into boot_domain and boot_node
* Default memory for domains is 2GB
* merged /root/post-install.log into /root/snow-postinstall.log in Redhad/CentOS deployments

### Minor Fixes
* Fix conditional for domains shutdown/boot in HA mode
* Merged /root/post-install.log into /root/snow-postinstall.log in Redhad/CentOS deployments
* Fix issue 141: snow boot cluster says "cluster booted" when it only triggers the process.
* Fix issue 135: Especial characters in the passwords defined in snow.conf could introduce some issues. It can be fixed by using single quotation marks. i.e. '$my_Str0Ng!! P455w@rD#'
* Fix issue 145: Included additional logic to allow to execute ```snow help``` when the snow.conf is not available.

## 1.1.14

### New Features and Changes
* Initial support for Ubuntu 18.04 LTS as sNow! server
* Removed sudosh from the HPCNow! working environment. Will include the package in the repository.
* Included parallel bzip2 (pbzip2) in the decompression of sNow! domain template.

### Minor Fixes
* Fix warning messages in snow.log during domain deployment
* Included full log history of snow command.

## 1.1.15

### New Features and Changes
* Extended support for Docker Swarm cluster provisioning
* Introduced support for OpenNebula private cloud provisioning
* Initial support for dynamic provisioning between Slurm, Docker Swarm and OpenNebula.
* Included shellcheck in HPCNow! development environment.
* Reduced memory footprint during the image gathering.

### Minor Fixes
* Fix issues with no-fetching option in stateless provisioning over NFS
