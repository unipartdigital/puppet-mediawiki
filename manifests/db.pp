# =Class mediawiki::db
class mediawiki::db inherits mediawiki {
  if $mediawiki::manage_database and ($mediawiki::db_host == 'localhost' or $mediawiki::db_host =~ /^127\./) {
    case $mediawiki::db_type {
      'postgres': {
        include postgresql::server

        postgresql::server::db { $mediawiki::database_name:
          user     => $mediawiki::db_user,
          password => postgresql_password($mediawiki::db_user, $mediawiki::db_pass),
        }

        if defined('pgdump::dump') {
          class { 'pgdump::dump':
            db_name     => $mediawiki::database_name,
            db_dump_dir => $mediawiki::dump_dir,
            require     => Postgresql::Server::Db[$mediawiki::database_name]
          }
        }
      }
      'mysql': {
        include ::mysql::server

        mysql::db { $mediawiki::database_name:
          user     => $mediawiki::db_user,
          password => $mediawiki::db_pass,
        }
      }
      default: {
        warning("Database type ${mediawiki::db_type} is not supported")
      }
    }
  }
}
