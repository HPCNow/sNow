from __future__ import absolute_import, division, print_function
from __future__ import unicode_literals

import argparse
import snow.config
import snow.domain
import snow.db.connection


def main():
    """
    Parse command line arguments passed to the application
    """
#    if os.geteuid() != 0:
#        print("You need root permissions to work with sNow", file=sys.stderr)
#        sys.exit(1)

    try:
        parser = argparse.ArgumentParser(description="sNow tools")
        parser.add_argument('-v', '--version', action='version', version=snow.__version__,
                            help="returns snow tools version and exits")

        subparsers = parser.add_subparsers(dest='command')

        # initialize database
        subparsers.add_parser('init', help="Initialise sNow environment")

        # configure snow environment
        subparsers.add_parser('config', help="Configure sNow environment")

        # virtual machines
        subparser = subparsers.add_parser('domain', help="virtual machines commands")
        group = subparser.add_mutually_exclusive_group(required=True)
        group.add_argument('-cd', '--create-domain', help='Creates a new VM')
        group.add_argument('-ld', '--list-domains', action='store_true', help='Lists VMs')
        group.add_argument('-lr', '--list-roles', action='store_true', help='Lists roles')

        args = parser.parse_args()

        if args.command == 'init':
            snow.db.connection._init(True)
        if args.command == 'config':
            snow.config._configure()
        elif args.command == 'domain':
            snow.db.connection._init()
            snow.domain.create_vm(args.create_domain)

        return True

    except Exception as e:
        from traceback import format_exc
#            Log.critical('Unhandled exception on snow: {0}\n{1}', e, format_exc(10))

        return False


if __name__ == "__main__":
    main()
