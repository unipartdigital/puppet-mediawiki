# =Class mediawiki::selinux
# MediaWiki touches a lot of interesting places in the filesystem,
# but it does generally document these places quite well so we can
# make sure they're handled appriopriately
class mediawiki::selinux inherits mediawiki {
  selinux::boolean { 'httpd_can_network_connect': }

  selinux::fcontext{"${cache_dir}(/.*)?":
    seltype  => 'httpd_sys_rw_content_t',
    pathspec => "${cache_dir}(/.*)?",
  }

  selinux::fcontext{"${upload_dir_real}(/.*)?":
    seltype  => 'httpd_sys_rw_content_t',
    pathspec => "${upload_dir_real}(/.*)?",
  }

  selinux::fcontext{'/var/log/mediawiki-debug.log':
    seltype  => 'httpd_sys_rw_content_t',
    pathspec => '/var/log/mediawiki-debug.log',
  }
}
