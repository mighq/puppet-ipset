# installs startup files and scripts
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
  case $::osfamily {
    'RedHat', 'redhat': {
      case $::operatingsystemrelease {
        /^6.*/: { # upstart starter
          file { '/etc/init/ipset.conf':
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            content => template("${module_name}/init.upstart.erb"),
          }
        }
        /^7.*/: { # systemd
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
        default: { fail("Unsupported RedHat family version is ${$::operatingsystemrelease} - autostart not enabled") }
      }
    }
    '': {  # handle bug in our Jenkins that returns empty strings for all of these when verifying
          if "${$::osfamily}${$::operatingsystem}${$::operatingsystemmajrelease}" == '' {
            warning("Got null for OS Family, assuming I'm running in Jenkins and this is a known bug!") }
          else {    fail( "Unsupported OSFamily \"${$::osfamily}\" OS is \"${$::operatingsystem}\" major version is \"${$::operatingsystemmajrelease}\" ") }
        }
    default:     { fail( "Unsupported OSFamily \"${$::osfamily}\" OS is \"${$::operatingsystem}\" major version is \"${$::operatingsystemmajrelease}\" ") }
  }

}
