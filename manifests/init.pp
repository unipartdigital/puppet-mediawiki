# =Class mediawiki
class mediawiki (
  String $minor_version,
  String $package_version,
  String $wiki_name,
  String $admin_user,
  String $admin_pass,
  String $admin_email,
  String $base_dir,
  String $wiki_path,
  String $resource_path,
  String $owner,
  String $group,
  String $httpd,
  String $httpd_group,
  String $db_host,
  String $db_user,
  String $db_pass,
  String $server_name,
  String $locale,
  String $lang,
  String $default_skin,
  String $cache_type,
  String $parser_cache_type,
  String $logo_path,
  String $login_message,
  String $ldap_enctype,
  String $ldap_server,
  String $ldap_bind_user,
  String $ldap_bind_password,
  String $ldap_base_dn,
  String $ldap_group_dn,
  String $ldap_user_dn,
  String $ldap_search_attrib,
  String $ldap_search_string,
  String $ldap_user_attrib,
  String $ldap_name_attrib,
  String $ldap_mail_attrib,
  String $ldap_groups_mapping_mode,
  String $ldap_group_class,
  String $ldap_group_attrib,
  String $upload_dir,
  String $swift_auth_url,
  String $swift_storage_url,
  String $swift_user,
  String $swift_key,
  Integer $db_port,
  Integer $ldap_port,
  Boolean $image_uploads,
  Boolean $imagemagick,
  Boolean $email_enabled,
  Boolean $email_user,
  Boolean $ldap_enabled,
  Boolean $swift_enabled,
  Boolean $manage_database,
  Array[String] $skins,
  Array[String] $bundled_extensions,
  Array[String] $memcached_servers,
  Array[String] $ldap_groups_required,
  Array[String] $ldap_groups_excluded,
  Hash[String, Hash[String, Boolean]] $group_perms,
  Hash[String, Boolean] $password_routes,
  Hash[String, Hash[String, String]] $ldap_extensions,
  Hash[String, String] $ldap_groups_mapping,
  Hash[String, Any] $smtp_settings,
  Hash[String, Hash[String, Variant[String, Hash[String, Any]]]] $extensions,
  Enum['mysql', 'postgres'] $db_type,
  Enum[
    'GroupMember',
    'GroupUniqueMember',
    'UserMemberOf',
    'Configurable'
  ] $ldap_group_strategy,
  Optional[String] $secret_key = undef,
  Optional[String] $upgrade_key = undef,
  Optional[String] $db_name = undef,
  Optional[String] $swift_name = undef,
) {
  $docroot = "${base_dir}/docroot"
  $cache_dir = "${base_dir}/cache"
  $config_dir = "${base_dir}/config"
  $upload_dir_real = "${docroot}${upload_dir}"

  if $ldap_enabled {
    $extensions_list = $extensions + $ldap_extensions
  } else {
    $extensions_list = $extensions
  }

  $database_name = $db_name ? {
    undef => split($::fqdn, '\.')[0],
    default => $db_name
  }

  $swift_namespace = $swift_name ? {
    undef => split($::fqdn, '\.')[0],
    default => $swift_name
  }

  contain mediawiki::selinux
  contain mediawiki::package
  contain mediawiki::db
  contain mediawiki::install
}
