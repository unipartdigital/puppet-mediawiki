# =Class mediawiki::package
class mediawiki::package inherits mediawiki {
  require mediawiki::selinux

  $package_name = "mediawiki-${mediawiki::package_version}.tar.gz"
  $package_url = "https://releases.wikimedia.org/mediawiki/${mediawiki::minor_version}/${package_name}"

  if $mediawiki::manage_httpd {
    user { $mediawiki::httpd:
      ensure => present,
    }
    group { $mediawiki::httpd_group:
      ensure => present
    }
  }

  Group <| title == $mediawiki::httpd_group |>
  -> User <| title == $mediawiki::httpd |>
  ->File[$mediawiki::base_dir]

  file { $mediawiki::base_dir:
    ensure => directory,
    owner  => $mediawiki::owner,
    group  => $mediawiki::group,
    mode   => '0755',
  }

  file { $mediawiki::docroot:
    ensure  => directory,
    owner   => $mediawiki::owner,
    group   => $mediawiki::group,
    mode    => '0755',
    require => [File[$mediawiki::base_dir]]
  }

  file { $mediawiki::cache_dir:
    ensure  => directory,
    owner   => $mediawiki::httpd,
    group   => $mediawiki::httpd_group,
    mode    => '0755',
    require => [File[$mediawiki::base_dir]]
  }

  file { $mediawiki::config_dir:
    ensure  => directory,
    owner   => $mediawiki::owner,
    group   => $mediawiki::group,
    mode    => '0755',
    require => [File[$mediawiki::base_dir]]
  }

  archive { $package_name:
    path            => "/tmp/${package_name}",
    source          => $package_url,
    extract         => true,
    extract_path    => $mediawiki::docroot,
    extract_command => 'tar xfz %s --strip-components=1',
    cleanup         => true,
    creates         => "${mediawiki::docroot}/index.php",
    require         => [File[$mediawiki::docroot]],
  }

  file { "${mediawiki::docroot}/images":
    ensure  => directory,
    owner   => $mediawiki::httpd,
    group   => $mediawiki::httpd_group,
    mode    => '0755',
    require => [Archive[$package_name]]
  }

  file { '/var/log/mediawiki-debug.log':
    ensure => present,
    owner  => $mediawiki::httpd,
    group  => $mediawiki::httpd_group,
    mode   => '0644'
  }

  $mediawiki::extensions_list.each |$extension, $details| {
    vcsrepo { "${mediawiki::docroot}/extensions/${extension}":
      revision => $details['revision'],
      provider => git,
      source   => $details['repo'],
      user     => 'root',
      owner    => $mediawiki::owner,
      group    => $mediawiki::group,
      branch   => $details['branch'],
      require  => Archive[$package_name],
      notify   => Exec['maintenance/update.php']
    }

    if $details['packages'] =~ Array {
      package { $details['packages']:
        ensure => installed
      }
    }
  }

  $mediawiki::skins.each |$skin, $details| {
    vcsrepo { "${mediawiki::docroot}/skins/${skin}":
      revision => $details['revision'],
      provider => git,
      source   => $details['repo'],
      user     => 'root',
      owner    => $mediawiki::owner,
      group    => $mediawiki::group,
      branch   => $details['branch'],
      require  => Archive[$package_name],
      notify   => Exec['maintenance/update.php']
    }
  }
}
