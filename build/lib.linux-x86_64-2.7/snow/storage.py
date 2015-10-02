from __future__ import absolute_import, division, print_function
from __future__ import unicode_literals

# import lvm
import logging
import os
import subprocess
import stat
import sys
import snow.units

_log = logging.getLogger(__name__)
handler = logging.StreamHandler()
formatter = logging.Formatter('%(asctime)s - %(name)s -  [%(levelname)s]: %(message)s')
handler.setFormatter(formatter)
_log.addHandler(handler)


def _create_logical_volume(vg, lv, size, sparse=False):
    """Create LVM image.
    Creates a LVM image with given size.
    :param vg: existing volume group which should hold this image
    :param lv: name for this image (logical volume)
    :size: size of image in bytes
    :sparse: create sparse logical volume
    """
    vg_info = get_volume_group_info(vg)
    free_space = vg_info['free']
    def check_size(vg, lv, size):
        if size > free_space:
            raise RuntimeError(_('Insufficient Space on Volume Group %(vg)s.'
                                 ' Only %(free_space)db available,'
                                 ' but %(size)db required'
                                 ' by volume %(lv)s.') %
                               {'vg': vg,
                                'free_space': free_space,
                                'size': size,
                                'lv': lv})
    if sparse:
        preallocated_space = 64 * snow.units.Mi
        check_size(vg, lv, preallocated_space)
        if free_space < size:
            _log.warn('Volume group %(vg)s will not be able'
                            ' to hold sparse volume %(lv)s.'
                            ' Virtual volume size is %(size)db,'
                            ' but free space on volume group is'
                            ' only %(free_space)db.',
                        {'vg': vg,
                        'free_space': free_space,
                        'size': size,
                        'lv': lv})
            cmd = ('lvcreate', '-L', '%db' % preallocated_space,
                    '--virtualsize', '%db' % size, '-n', lv, vg)
    else:
        check_size(vg, lv, size)
        cmd = ['lvcreate', '-L', '%db' % size, '-n', lv, vg]

    # use close_fds=True see link below
    # https://www.reddit.com/r/Python/comments/25948e/getting_file_descriptor_leaked_errors_when_using/
    try:
        obj = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, close_fds=True)
        out, err = obj.communicate()
    except Exception as e:
        _log.error("Snow error: %s" % e)
        sys.exit(1)

    if obj.returncode != 0:
        _log.error("Snow error: %s" % err)
        sys.exit(1)


def get_volume_group_info(vg):
    """Return free/used/total space info for a volume group in bytes
    :param vg: volume group name
    :returns: A dict containing:
        :total: How big the filesystem is (in bytes)
        :free: How much space is free (in bytes)
        :used: How much space is used (in bytes)
        """
    # use close_fds=True see link below
    # https://www.reddit.com/r/Python/comments/25948e/getting_file_descriptor_leaked_errors_when_using/
    obj = subprocess.Popen(['vgs', '--noheadings', '--nosuffix',
                                 '--separator', '|',
                                 '--units', 'b', '-o', 'vg_size,vg_free', vg],
                                stdout=subprocess.PIPE, close_fds=True)

    out, err = obj.communicate()

    if obj.returncode != 0:
        _log.error("Snow error: %s" % err)
        sys.exit(1)

    info = out.split('|')

    if len(info) != 2:
        raise RuntimeError(_("vg %s must be LVM volume group") % vg)
    return {'total': int(info[0]),
            'free': int(info[1]),
            'used': int(info[0]) - int(info[1])}


def _is_block_device(filename):
    try:
        mode = os.lstat(os.path.realpath(filename)).st_mode
    except OSError:
        return False
    else:
        return stat.S_ISBLK(mode)


def _create_fs(block_device, filesystem='ext4'):
    # check block_device existence
    if _is_block_device(block_device):
        command = ['mkfs.' + filesystem, block_device]
        try:
            subprocess.check_call(command)
        except Exception as e:
            _log.error("sNow error: %s" % e)
            sys.exit(1)
    else:
        _log.error("%s is not a block device" % block_device)
        sys.exit(1)
