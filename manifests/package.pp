# =Class mediawiki::package
class mediawiki::package inherits mediawiki {
  require mediawiki::selinux

  $package_name = "mediawiki-${package_version}.tar.gz"
  $package_url = "https://releases.wikimedia.org/mediawiki/${minor_version}/${package_name}"

  file { $base_dir:
    ensure  => directory,
    owner   => $owner,
    group   => $group,
    mode    => '0755',
  }

  file { $docroot:
    ensure  => directory,
    owner   => $owner,
    group   => $group,
    mode    => '0755',
    require => [File[$base_dir]]
  }

  file { $cache_dir:
    ensure  => directory,
    owner   => $httpd,
    group   => $httpd_group,
    mode    => '0755',
    require => [File[$base_dir]]
  }

  file { $config_dir:
    ensure  => directory,
    owner   => $owner,
    group   => $group,
    mode    => '0755',
    require => [File[$base_dir]]
  }

  archive { $package_name:
    path            => "/tmp/${package_name}",
    source          => $package_url,
    extract         => true,
    extract_path    => $docroot,
    extract_command => 'tar xfz %s --strip-components=1',
    cleanup         => true,
    creates         => "${docroot}/index.php",
    require         => [File[$docroot]],
  }

  file { "${docroot}/images":
    ensure  => directory,
    owner   => $httpd,
    group   => $httpd_group,
    mode    => '0755',
    require => [Archive[$package_name]]
  }

  file { '/var/log/mediawiki-debug.log':
    ensure  => present,
    owner   => $httpd,
    group   => $httpd_group,
    mode    => '0644'
  }

  $extensions_list.each |$extension, $mod| {
    vcsrepo { "${docroot}/extensions/${extension}":
      revision => $mod['revision'],
      provider => git,
      source   => $mod['repo'],
      user     => 'root',
      owner    => $owner,
      group    => $group,
      branch   => $mod['branch'],
      require  => Archive[$package_name],
      notify   => Exec['maintenance/update.php']
    }
  }
}
