# =Class mediawiki::db
class mediawiki::db inherits mediawiki {
  if $db_host == 'localhost' or $db_host =~ /^127\./ {
    case $db_type {
      'postgres': {
        include postgresql::server

        postgresql::server::db { $db_name:
          user     => $db_user,
          password => postgresql_password($db_user, $db_pass),
        }

        if defined('pgdump::dump') {
          class { 'pgdump::dump':
            db_name     => $db_name,
            db_dump_dir => '/var/lib/pgsql/dump',
            require     => Postgresql::Server::Db[$db_name]
          }
        }
      }
      'mysql': {
        include ::mysql::server

        mysql::db { $db_name:
          user     => $db_user,
          password => $db_pass,
        }
      }
    }
  }
}
