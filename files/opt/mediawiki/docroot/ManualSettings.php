<?php
# This file is created by Puppet, but will not be overwritten on
# subsequent Puppet runs. Use it for manual Mediawiki config.
#
# Changes in ManualSettings.php should be considered expendable, and will not
# be supported by sysadmins. They should be merged into Puppet if possible.



# See includes/DefaultSettings.php for all configurable settings
# and their default values, but don't forget to make changes in _this_
# file, not there.
#
# Further documentation for configuration settings may be found at:
# https://www.mediawiki.org/wiki/Manual:Configuration_settings

if (!defined('MEDIAWIKI')) {
  exit;
}

### Add non-puppetised settings below

## Useful debugging options

# Debug log file. This file is automatically created by Puppet
# with an appropriate SELinux file context, but is not logged to
# unless this line is uncommented.
#$wgDebugLogFile = "/var/log/mediawiki-debug.log";

# Show exception details
#$wgShowExceptionDetails = true;