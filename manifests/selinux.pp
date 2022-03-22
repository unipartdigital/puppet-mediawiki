# =Class mediawiki::selinux
# MediaWiki touches a lot of interesting places in the filesystem,
# but it does generally document these places quite well so we can
# make sure they're handled appriopriately
class mediawiki::selinux inherits mediawiki {
  if $mediawiki::manage_selinux {
    selinux::boolean { 'httpd_can_network_connect': }
    selinux::boolean { 'httpd_setrlimit': }

    selinux::fcontext{"${mediawiki::cache_dir}(/.*)?":
      seltype  => 'httpd_sys_rw_content_t',
      pathspec => "${mediawiki::cache_dir}(/.*)?",
    }

    selinux::fcontext{"${mediawiki::upload_dir_real}(/.*)?":
      seltype  => 'httpd_sys_rw_content_t',
      pathspec => "${mediawiki::upload_dir_real}(/.*)?",
    }

    selinux::fcontext{'/var/log/mediawiki-debug.log':
      seltype  => 'httpd_sys_rw_content_t',
      pathspec => '/var/log/mediawiki-debug.log',
    }
  }
}
