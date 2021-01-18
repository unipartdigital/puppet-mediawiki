# =Class mediawiki::db
class mediawiki::db inherits mediawiki {
  include postgresql::server

  postgresql::server::db {$db_name:
    user     => $db_user,
    password => postgresql_password($db_user, $db_pass),
  }

  class { 'pgdump::dump':
    db_name     => $db_name,
    db_dump_dir => '/var/lib/pgsql/dump',
    require     => Postgresql::Server::Db[$db_name]
  }
}
