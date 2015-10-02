import pony.orm

db = pony.orm.Database()


class OS(db.Entity):
    __table__ = 'OS'
    distro = pony.orm.Required(str)
    version = pony.orm.Required(str)
    iso = pony.orm.Optional(pony.orm.LongStr)
    pony.orm.PrimaryKey(distro, version)


class Roles(db.Entity):
    __table__ = 'role'
    role = pony.orm.PrimaryKey(str)
    cpus = pony.orm.Required(int)
    mem = pony.orm.Required(int)
    disk = pony.orm.Required(int)
