class ipset::install {
  include ipset::params

  $cfg = $::ipset::params::config_path

  # main package
  package { $::ipset::params::package:
    ensure => installed,
    alias  => 'ipset',
  }

  # directory with config profiles (*.set & *.hdr files)
  file { $cfg:
    ensure => directory,
  }

  # helper scripts
  ipset::install::helper_script { ['ipset_sync', 'ipset_init']: }

  # autostart
  $warn = 'Autostart of ipset not implemented for this OS.'
  case $::osfamily {
    'RedHat': {
      case $::operatingsystemmajrelease {
        '6': {
          # upstart starter
          file { '/etc/init/ipset.conf':
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            content => template("${module_name}/init.upstart.erb"),
          }
        }
        '7': {
          # systemd
          file { '/usr/lib/systemd/system/ipset.service':
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            content => template("${module_name}/systemd.service.erb"),
          }
          file { '/etc/systemd/system/basic.target.wants/ipset.service':
            ensure => link,
            target => '/usr/lib/systemd/system/ipset.service',
          }
        }
        default: {
          warning($warn)
        }
      }
    }
    'Debian': {
      case $::operatingsystem {
        'Ubuntu': {
          # upstart starter
          file { '/etc/init/ipset.conf':
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            content => template("${module_name}/init.upstart.erb"),
          }
        }
        default: {
          warning($warn)
        }
      }
    }
    default: {
      warning($warn)
    }
  }
}
