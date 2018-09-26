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
# sNow! Continuous Integration and Continuous Deployment

This repository contains required files to conduct CI/CD for sNow! Cluster Manager.

Currently, this repository supports Debian 9 and Ubuntu 18.04 LTS in High Availability (HA) mode using a previously deployed BeeGFS as cluster file system backend.

The credentials are updated via Jenkins. If you want to test a complete deployment, the default passwords used are:

- Default password after deployment: HPCNOW
- Default password after snow init: HPCN0w!!

## Actions Performed in Continuous Deployment:
1. Deploy sNow! nodes (snowha01 and snowha02) from scratch
2. Install BeeGFS clients
3. Install sNow! Cluster Manager
4. Setup sNow! Cluster Manager
5. Deploy common domains
6. Deploy golden node*
7. Install minimal toolchain (foss 2018a) and Supermagic
8. Generate stateless image
9. Boot nodes with stateless image*
10. Sanity check based on supermagic jobs based on stateless image*
11. Generate SSI*
12. Boot nodes with SSI*
13. Sanity check based on supermagic jobs based on SSI*

More information about this setup available in the sNow! documentation, [Scalability and High Availability Overview
](https://hpcnow.github.io/snow-documentation/mydoc_ha_loopback_files.html) section.
