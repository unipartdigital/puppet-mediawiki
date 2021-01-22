# =Class mediawiki::db
class mediawiki::db inherits mediawiki {
  if $db_host == 'localhost' or $db_host =~ /^127\./ {
    case $db_type {
      'postgres': {
        include postgresql::server

        # Postgres module does not allow the automatic creation of DBs
        # from hiera the way the mysql module does, so create it as
        # a resource here
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
        # Define DBs in hiera
        include ::mysql::server
      }
    }
  }
}
