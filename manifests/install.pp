# =Class mediawiki::install
class mediawiki::install inherits mediawiki {
  require mediawiki::selinux
  require mediawiki::package
  require mediawiki::db
  require ::php

  $ext_list = join($bundled_extensions, ',')
  $skin_list = join($skins, ',')
  $namespace = regsubst($wiki_name, ' ', '_')
  $article_path = "${wiki_path}/\$1"
  $memcached_servers_list = $memcached_servers.map |$server| { "'${server}'" }.join(', ')
  $ldap_groups_required_list = $ldap_groups_required.map |$group| { "\"cn=${group},${ldap_group_dn}\"" }.join(', ')
  $ldap_groups_excluded_list = $ldap_groups_excluded.map |$group| { "\"cn=${group},${ldap_group_dn}\"" }.join(', ')
  $ldap_groups_mapping_list = $ldap_groups_mapping.map |$wiki_group, $group| { "\"${wiki_group}\": \"cn=${group},${ldap_group_dn}\"" }.join(', ')
  if $secret_key {
    $secret_key_real = $secret_key
  } else {
    $secret_key_real = seeded_rand_string(64, "${::fqdn}::mediawiki_secret", 'abcdef0123456789')
  }
  if $upgrade_key {
    $upgrade_key_real = $upgrade_key
  } else {
    $upgrade_key_real = seeded_rand_string(16, "${::fqdn}::mediawiki_upgrade", 'abcdef0123456789')
  }

  exec { 'maintenance/install.php':
    command => join([
      'php maintenance/install.php',
      "--server https://${server_name}",
      "--scriptpath ${wiki_path}",
      "--skins ${skin_list}",
      "--extensions ${ext_list}",
      "--installdbuser ${db_user}",
      "--installdbpass ${db_pass}",
      "--dbuser ${db_user}",
      "--dbpass ${db_pass}",
      "--dbserver ${db_host}",
      "--dbname ${database_name}",
      "--dbport ${db_port}",
      "--dbtype ${db_type}",
      "--pass ${admin_pass}",
      "\"${wiki_name}\" ${admin_user}"
    ], ' '),
    creates => "${docroot}/LocalSettings.php",
    cwd     => $docroot,
    user    => 'root',
    group   => 'root',
    path    => '/usr/sbin:/usr/bin:/sbin:/bin'
  }

  file { "${docroot}/LocalSettings.php":
    content => template("${module_name}/opt/mediawiki/docroot/LocalSettings.php.erb"),
    mode    => '0644',
    owner   => $owner,
    group   => $group,
    require => Exec['maintenance/install.php'],
    notify  => Exec['maintenance/update.php']
  }

  file { "${docroot}/ManualSettings.php":
    content => file("${module_name}/opt/mediawiki/docroot/ManualSettings.php"),
    mode    => '0644',
    owner   => $owner,
    group   => $group,
    replace => false,
    require => File["${docroot}/LocalSettings.php"]
  }

  if $ldap_enabled {
    file { "${config_dir}/ldapprovider.json":
      content => template("${module_name}/opt/mediawiki/config/ldapprovider.json.erb"),
      mode    => '0644',
      owner   => $owner,
      group   => $group,
      require => File[$config_dir],
      notify  => Exec['maintenance/update.php']
    }
  }

  exec { 'maintenance/update.php':
    command     => join([
      'php maintenance/update.php',
      "--server https://${server_name}",
      '--quick'
    ], ' '),
    cwd         => $docroot,
    user        => 'root',
    group       => 'root',
    path        => '/usr/sbin:/usr/bin:/sbin:/bin',
    require     => File["${docroot}/LocalSettings.php"],
    refreshonly => true
  }


  # Post-install SELinux tweaking

  exec { 'restorecon /var/log/mediawiki-debug.log':
    command => 'restorecon /var/log/mediawiki-debug.log',
    onlyif  => 'test `ls -Z /var/log/mediawiki-debug.log | grep -c httpd_sys_rw_content_t` -eq 0',
    user    => 'root',
    path    => '/sbin:/usr/sbin:/bin:/usr/bin',
  }

  exec { "restorecon -r ${cache_dir}":
    command => "restorecon -r ${cache_dir}",
    onlyif  => "test `ls -aZ ${cache_dir} | grep -c httpd_sys_rw_content_t` -eq 0",
    user    => 'root',
    path    => '/sbin:/usr/sbin:/bin:/usr/bin',
  }

  exec { "restorecon -r ${upload_dir_real}":
    command => "restorecon -r ${upload_dir_real}",
    onlyif  => "test `ls -aZ ${upload_dir_real} | grep -c httpd_sys_rw_content_t` -eq 0",
    user    => 'root',
    path    => '/sbin:/usr/sbin:/bin:/usr/bin',
  }
}
