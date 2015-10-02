import logging
import pony.orm
import snow.db.schema


_log = logging.getLogger(__name__)


@pony.orm.core.db_session
def _populate_database():
    snow.db.schema.Roles(role="ldap", cpus=1, mem=256, disk=6144)
    pony.orm.commit()


def _init(clear=False):
    snow.db.schema.db.bind("sqlite", "/tmp/snow.db", create_db=True)
    snow.db.schema.db.generate_mapping(create_tables=True)
    if clear:
        snow.db.schema.db.drop_all_tables(with_all_data=True)
        snow.db.schema.db.create_tables()
        _populate_database()
