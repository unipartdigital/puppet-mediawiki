# =Class mediawiki::db
class mediawiki::db inherits mediawiki {
  if $manage_database and ($db_host == 'localhost' or $db_host =~ /^127\./) {
    case $db_type {
      'postgres': {
        include postgresql::server

        postgresql::server::db { $database_name:
          user     => $db_user,
          password => postgresql_password($db_user, $db_pass),
        }

        if defined('pgdump::dump') {
          class { 'pgdump::dump':
            db_name     => $database_name,
            db_dump_dir => '/var/lib/pgsql/dump',
            require     => Postgresql::Server::Db[$database_name]
          }
        }
      }
      'mysql': {
        include ::mysql::server

        mysql::db { $database_name:
          user     => $db_user,
          password => $db_pass,
        }
      }
    }
  }
}
