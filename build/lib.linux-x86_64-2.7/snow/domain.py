from __future__ import absolute_import, division, print_function
from __future__ import unicode_literals

import libvirt
import logging
import pony.orm
import sys
import snow.db.schema
import snow.storage

_log = logging.getLogger(__name__)
handler = logging.StreamHandler()
formatter = logging.Formatter('%(asctime)s - %(name)s -  [%(levelname)s]: %(message)s')
handler.setFormatter(formatter)
_log.addHandler(handler)

def list_vms():
    conn = _open_connection()

    return conn.listDefinedDomains()


def _open_connection():
    try:
        conn = libvirt.openReadOnly('qemu:/system')
    except Exception as e:
        print("Snow error: %s" % e, file=sys.stderr)
        sys.exit(1)

    return conn


@pony.orm.core.db_session
def create_vm(role):
    # determine virtualisation technology to use (xen, kvm, lxc) from config file?
    virt_tech = 'kvm'
    vg_name = 'snow_vg'

    # check if virt is available
    _open_connection()

    # recover role from database
    try:
        role_data = pony.orm.select(r for r in snow.db.schema.Roles if role in r.role)
    except Exception as e:
        _log.error("Snow error: %s" % e)
        sys.exit(1)

    # _log.debug("Database info:%s" % str(role_data.show()))

    # generate new vm name (e.g.: ldap01)
    matching = [vm for vm in list_vms() if role in vm]
    new_vm_name = "%s%02d" % (role, len(matching)+1)
    _log.debug("VM generated name: %s" % new_vm_name)

    # allocate disk space
    try:
        snow.storage._create_logical_volume(vg_name, new_vm_name, role_data.first().disk*1024*1024)
        lv = '/dev/' + vg_name + '/' + new_vm_name
        snow.storage._create_fs(lv)
    except Exception as e:
        _log.error("Snow error: %s" % e)
        sys.exit(1)

    # create vm
