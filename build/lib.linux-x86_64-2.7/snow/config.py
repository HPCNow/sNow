from __future__ import absolute_import, division, print_function
from __future__ import unicode_literals

import locale
import dialog
import sys
import os

# This is almost always a good thing to do at the beginning of your programs.
try:
    locale.setlocale(locale.LC_ALL, '')
except Exception as e:
    print("Your locales are not properly configure. Please check them and run the script again.")
    sys.exit(1)


def _handle_exit_code(d, code):
    # d is supposed to be a Dialog instance
    if code in (d.DIALOG_CANCEL, d.DIALOG_ESC):
        if code == d.DIALOG_CANCEL:
            msg = "You chose cancel in the last dialog box. Do you want to " \
                  "exit sNow configuration?"
        else:
            msg = "You pressed ESC in the last dialog box. Do you want to " \
                  "exit sNow configuration?"

        if d.yesno(msg) == d.DIALOG_OK:
            sys.exit(0)
        return d.DIALOG_CANCEL
    else:
        return code


def _eula(d):
    code = d.yesno("TEXT EULA \n \n Do you accept the End User License Agreement?", title="End User License Agreement")

    if code == d.DIALOG_CANCEL:
        d.msgbox("Please feel free to sent feedback to HPCNow! (www.hpcnow.com)")
        sys.exit(0)

def _select_way(d):
    code, way_tag = d.menu("sNow can be installed in a quick way (one master node and pre-defined services) or in a expert mode",
                            choices=[("1", "Quick and Fast Cluster Install"),
                                     ("2", "Expert / Custom Install")])

    return way_tag

def _select_virt_tech(d):
    code, virt_tag = d.menu("Which technology do you want to use?",
                            choices=[("1", "Xen (Paravirtualization)"),
                                     ("2", "LXC (Linux Containers)")])

    return virt_tag


# Domains setup
def _select_domains(d):
    while True:
        # We could put non-empty items here (not only the tag for each entry)
        code, dom_tags = d.checklist("What domains do you want to install?",
                                choices=[("Monitor", "", True),
                                        ("LDAP", "", True),
                                        ("Proxy", "", True),
                                        ("Login", "", True),
                                        ("Portal", "", True),
                                        ("Slurm", "", True)],
                                title="Domains selection",
                                backtitle="And now, for something "
                                "completely different...")

        if "LDAP" not in dom_tags:
            code, answer = d.inputbox("LDAP domain has been disabled. Please insert your LDAP uri",
                                      init="ldap://127.0.0.1", help_button=True, extra_button=True, extra_label="Back")

        if _handle_exit_code(d, code) == d.DIALOG_OK:
            break
        elif _handle_exit_code(d, code) == d.EXTRA:
            pass

    return dom_tags


def _configure_domain(d, domain_name):
    domain = [
        ("%s vCPU" % domain_name, 1, 1, "1", 1, 20, 15, 15),
        ("%s Mem (MB)" % domain_name, 2, 1, "512", 2, 20, 15, 15),
        ("%s Disk size (GB)" % domain_name, 3, 1, "6", 3, 20, 15, 15)
    ]

    (code, domain_fields) = d.form("Please fill in %s domain information:" % domain_name, domain, width=77)

    return domain_fields


# Network setup
def _configure_snow_network(d):
    # sNow! network
    snow_lan = [
        ("sNow LAN IP address", 1, 1, "192.168.7.1", 1, 20, 15, 15),
        ("sNow LAN netmask", 2, 1, "255.255.255.0", 2, 20, 15, 15),
        ("sNow LAN gateway", 3, 1, "192.168.7.1", 3, 20, 15, 15),
        ("sNow LAN VLAN", 4, 1, "vlan7", 4, 20, 15, 15)
    ]

    (code, snow_fields) = d.form("Please fill in sNow network information:", snow_lan, width=77)

    return snow_fields


def _configure_ipmi_network(d):
    # IPMI and consoles network
    ipmi_lan = [
        ("IPMI LAN IP address", 1, 1, "10.0.0.0", 1, 20, 15, 15),
        ("IPMI LAN netmask", 2, 1, "255.255.255.0", 2, 20, 15, 15),
        ("IPMI LAN gateway", 3, 1, "10.0.0.254", 3, 20, 15, 15),
        ("IPMI LAN VLAN", 4, 1, "vlan0", 4, 20, 15, 15)
    ]

    (code, ipmi_fields) = d.form("Please fill in IPMI network information:", ipmi_lan, width=77)

    return ipmi_fields


def _configure_cfs_network(d):
    # Cluster Filesystem Servers network
    cfs_lan = [
        ("Cluster filesystem LAN IP address", 1, 1, "192.168.3.0", 1, 35, 15, 15),
        ("Cluster filesystem LAN netmask", 2, 1, "255.255.255.0", 2, 35, 15, 15),
        ("Cluster filesystem LAN gateway", 3, 1, "192.168.3.254", 3, 35, 15, 15),
        ("Cluster filesystem LAN VLAN", 4, 1, "vlan3", 4, 35, 15, 15)
    ]

    (code, cfs_fields) = d.form("Please fill in cluster filesystem network information:", cfs_lan, width=77)

    return cfs_fields


def _configure_dmz_network(d):
    # DMZ network
    dmz_lan = [
        ("DMZ LAN IP address", 1, 1, "172.16.0.0", 1, 20, 15, 15),
        ("DMZ LAN netmask", 2, 1, "255.255.255.0", 2, 20, 15, 15),
        ("DMZ LAN gateway", 3, 1, "172.16.0.254", 3, 20, 15, 15),
        ("DMZ LAN VLAN", 4, 1, "vlan1", 4, 20, 15, 15)
    ]

    (code, dmz_fields) = d.form("Please fill in cluster filesystem network information:", dmz_lan, width=77)

    return dmz_fields


def _configure_compute_network(d):
    # Compute nodes network
    compute_lan = [
        ("Cluster name (compute nodes' name)", 1, 1, "cluster_one", 1, 35, 15, 15),
        ("Compute nodes LAN IP address", 2, 1, "192.168.10.1", 2, 35, 15, 15),
        ("Compute nodes LAN netmask", 3, 1, "255.255.255.0", 3, 35, 15, 15),
        ("Compute nodes LAN gateway", 4, 1, "192.168.10.254", 4, 35, 15, 15),
        ("Compute nodes LAN VLAN", 5, 1, "vlan10", 5, 35, 15, 15)
    ]

    (code, compute_fields) = d.form("Please fill in compute nodes network information:", compute_lan, width=77)

    return compute_fields

# Storage nodes setup
# Cluster/distributed FileSystem selection (BeeGFS, NFS, Lustre)
def _select_cfs_type(d):
    code, cfs_type_tag = d.menu("Which Distributed or Cluster filesystem do you want to use?",
                                choices=[("1", "NFS"),
                                         ("2", "BeeGFS"),
                                         ("3", "Lustre"),
                                         ("4", "IEEL")])

    if "IEEL" in cfs_type_tag:
        d.msgbox("Please remember to transfer Intel Enterprise Edition for Lustre packages to /sNow/OS/IEEL")

    return cfs_type_tag
# Linux distribution
def _select_cfs_dist(d):
    code, cfs_dist_tag = d.menu("Which Linux distributions do you want to use for the cluster filesystem?",
                                choices=[("1", "SLES-12"),
                                         ("2", "Debian-8"),
                                         ("3", "CentOS-7"),
                                         ("4", "RHEL-7")])

    return cfs_dist_tag
# SLES (optional) and RHEL Activation code
# * SLES : suse_register -a email=<e-mail address> -a regcode-sles=<activation code> --restore-repos
# * RHEL : rhn-channel -a -c rhel-x86_64-server-optional-6 -u <Red Hat Network username> -p <Red Hat Network password>
# Partition layout
def _configure_cfs_part_layout(d):
    cfs_part_layout = [
        ("/", 1, 1, "2", 1, 20, 15, 15),
        ("/usr", 2, 1, "8", 2, 20, 15, 15),
        ("/var", 3, 1, "4", 3, 20, 15, 15),
        ("/tmp", 4, 1, "2", 4, 20, 15, 15)
        ("/scratch", 5, 1, "MAX", 4, 20, 15, 15)
    ]

    (code, cfs_part_layout_fields) = d.form("Please fill in the partition layout for the storage nodes\n Values in GB, 0 means no partition, MAX means the maximum value:", cfs_part_layout, width=77)

    return cfs_part_layout_fields
# Low Latency network fabric setup
# OFED Distribution (Mellanox, Intel, Qlogic)


# Compute nodes setup
# Linux distribution
def _select_compute_dist(d):
    code, comp_dist_tag = d.menu("Which Linux distributions do you want to use for the compute nodes?",
                                 choices=[("1", "SLES-12"),
                                          ("2", "Debian-8"),
                                          ("3", "CentOS-7"),
                                          ("4", "RHEL-7")])

    return comp_dist_tag
# SLES (optional) and RHEL Activation code
# Partition layout
def _configure_comp_part_layout(d):
    comp_part_layout = [
        ("/", 1, 1, "2", 1, 20, 15, 15),
        ("/usr", 2, 1, "8", 2, 20, 15, 15),
        ("/var", 3, 1, "4", 3, 20, 15, 15),
        ("/tmp", 4, 1, "2", 4, 20, 15, 15)
        ("/scratch", 5, 1, "MAX", 4, 20, 15, 15)
    ]

    (code, comp_part_layout_fields) = d.form("Please fill in the partition layout for the compute nodes\n Values in GB, 0 means no partition, MAX means the maximum value:", comp_part_layout, width=77)

    return comp_part_layout_fields
# Low Latency network fabric setup
# OFED Distribution (Mellanox, Intel, Qlogic)

# Security
# Master Password
# Local user creation
# Yubikey support
# Firewall setup
# OSSEC

# Select Multi-Role setup
# Subnet Manager
# Deploy servers
# Login nodes
# Data transfer nodes (HPS-SSH)


# sNow! servers console (text / E17)
# Activate HPCNow! remote support
def _configure():
    # You may want to use 'autowidgetsize=True' here (requires pythondialog >= 3.1)
    d = dialog.Dialog(dialog="dialog", autowidgetsize=True)
    d.set_background_title("sNow! install")

    _eula(d)
    way = _select_way(d)
    if way == "2":
        virt_tech = _select_virt_tech(d)
        domains = _select_domains(d)

        domain_info = dict()
        for domain in domains:
            domain_info[domain.lower()] = _configure_domain(d, domain.lower())

        snow_net = _configure_snow_network(d)
        ipmi_net = _configure_ipmi_network(d)
        cfs_net = _configure_cfs_network(d)
        dmz_net = _configure_dmz_network(d)
        compute_net = _configure_compute_network(d)
        cfs_type = _select_cfs_type(d)
        cfs_dist = _select_cfs_dist(d)
        print("HOLA")
        compute_dist = _select_compute_dist(d)
        d.clear()
    else:
        os.system("clear")

if __name__ == "__main__":
    _configure()
