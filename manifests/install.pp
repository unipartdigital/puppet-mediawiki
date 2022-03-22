# =Class mediawiki::install
class mediawiki::install inherits mediawiki {
  require mediawiki::selinux
  require mediawiki::package
  require mediawiki::db
  require ::php

  $ext_list = join($mediawiki::bundled_extensions, ',')
  $skin_list = join($mediawiki::bundled_skins, ',')
  $namespace = regsubst($mediawiki::wiki_name, ' ', '_')
  $article_path = "${mediawiki::wiki_path}/\$1"
  $memcached_servers_list = $mediawiki::memcached_servers.map |$server| { "'${server}'" }.join(', ')
  $ldap_groups_required_list = $mediawiki::ldap_groups_required.map |$group| { "\"cn=${group},${mediawiki::ldap_group_dn}\"" }.join(', ')
  $ldap_groups_excluded_list = $mediawiki::ldap_groups_excluded.map |$group| { "\"cn=${group},${mediawiki::ldap_group_dn}\"" }.join(', ')
  $ldap_groups_mapping_list = $mediawiki::ldap_groups_mapping.map |$wiki_group, $group| {
    "\"${wiki_group}\": \"cn=${group},${mediawiki::ldap_group_dn}\""
  }.join(', ')
  $file_exts = $mediawiki::file_extensions.map |$ext| { "'${ext}'" }.join(', ')

  if $mediawiki::secret_key {
    $secret_key_real = $mediawiki::secret_key
  } else {
    $secret_key_real = seeded_rand_string(64, "${::fqdn}::mediawiki_secret", 'abcdef0123456789')
  }
  if $mediawiki::upgrade_key {
    $upgrade_key_real = $mediawiki::upgrade_key
  } else {
    $upgrade_key_real = seeded_rand_string(16, "${::fqdn}::mediawiki_upgrade", 'abcdef0123456789')
  }

  exec { 'maintenance/install.php':
    command => join([
      'php maintenance/install.php',
      "--server https://${mediawiki::server_name}",
      "--scriptpath ${mediawiki::wiki_path}",
      "--skins ${skin_list}",
      "--extensions ${ext_list}",
      "--installdbuser ${mediawiki::db_user}",
      "--installdbpass ${mediawiki::db_pass}",
      "--dbuser ${mediawiki::db_user}",
      "--dbpass ${mediawiki::db_pass}",
      "--dbserver ${mediawiki::db_host}",
      "--dbname ${mediawiki::database_name}",
      "--dbport ${mediawiki::db_port}",
      "--dbtype ${mediawiki::db_type}",
      "--pass ${mediawiki::admin_pass}",
      "\"${mediawiki::wiki_name}\" ${mediawiki::admin_user}"
    ], ' '),
    creates => "${mediawiki::docroot}/LocalSettings.php",
    cwd     => $mediawiki::docroot,
    user    => 'root',
    group   => 'root',
    path    => '/usr/sbin:/usr/bin:/sbin:/bin'
  }

  file { "${mediawiki::docroot}/LocalSettings.php":
    content => template("${module_name}/opt/mediawiki/docroot/LocalSettings.php.erb"),
    mode    => '0644',
    owner   => $mediawiki::owner,
    group   => $mediawiki::group,
    require => Exec['maintenance/install.php'],
    notify  => Exec['maintenance/update.php']
  }

  file { "${mediawiki::docroot}/ManualSettings.php":
    content => file("${module_name}/opt/mediawiki/docroot/ManualSettings.php"),
    mode    => '0644',
    owner   => $mediawiki::owner,
    group   => $mediawiki::group,
    replace => false,
    require => File["${mediawiki::docroot}/LocalSettings.php"]
  }

  if $mediawiki::ldap_enabled {
    file { "${mediawiki::config_dir}/ldapprovider.json":
      content => template("${module_name}/opt/mediawiki/config/ldapprovider.json.erb"),
      mode    => '0644',
      owner   => $mediawiki::owner,
      group   => $mediawiki::group,
      require => File[$mediawiki::config_dir],
      notify  => Exec['maintenance/update.php']
    }
  }

  exec { 'maintenance/update.php':
    command     => join([
      'php maintenance/update.php',
      "--server https://${mediawiki::server_name}",
      '--quick'
    ], ' '),
    cwd         => $mediawiki::docroot,
    user        => 'root',
    group       => 'root',
    path        => '/usr/sbin:/usr/bin:/sbin:/bin',
    require     => File["${mediawiki::docroot}/LocalSettings.php"],
    refreshonly => true
  }


  # Post-install SELinux tweaking

  if $mediawiki::manage_selinux {
    exec { 'restorecon /var/log/mediawiki-debug.log':
      command => 'restorecon /var/log/mediawiki-debug.log',
      onlyif  => 'test `ls -Z /var/log/mediawiki-debug.log | grep -c httpd_sys_rw_content_t` -eq 0',
      user    => 'root',
      path    => '/sbin:/usr/sbin:/bin:/usr/bin',
    }

    exec { "restorecon -r ${mediawiki::cache_dir}":
      command => "restorecon -r ${mediawiki::cache_dir}",
      onlyif  => "test `ls -aZ ${mediawiki::cache_dir} | grep -c httpd_sys_rw_content_t` -eq 0",
      user    => 'root',
      path    => '/sbin:/usr/sbin:/bin:/usr/bin',
    }

    exec { "restorecon -r ${mediawiki::upload_dir_real}":
      command => "restorecon -r ${mediawiki::upload_dir_real}",
      onlyif  => "test `ls -aZ ${mediawiki::upload_dir_real} | grep -c httpd_sys_rw_content_t` -eq 0",
      user    => 'root',
      path    => '/sbin:/usr/sbin:/bin:/usr/bin',
    }
  }
}
