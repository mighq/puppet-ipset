# installs startup files and scripts
class ipset::install($init_system = undef) {
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
    'RedHat': {
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
            notify  => Exec['ipset_systemctl_daemonreload'],
          }
        }
        default: { fail("Unsupported RedHat family version is ${$::operatingsystemrelease} - autostart not enabled") }
      }
    }
    'Debian': {
      case $::operatingsystem {
        'Ubuntu': {
          case $::operatingsystemrelease {
            /^15\.\d+/: { # systemd / we are assuming they chose systemd for Ubuntu, at this moment we cannot detect is_systemd or use $::service_provider fact (stdlib 4.10.x) to help tell us whether we are upstart or systemd
              if $init_system =~ /(?i:upstart)/ {
                file { '/etc/init/ipset.conf':
                  owner   => 'root',
                  group   => 'root',
                  mode    => '0644',
                  content => template("${module_name}/init.upstart.erb"),
                }
              }
              else {
                file { '/usr/lib/systemd/system/ipset.service':
                  owner   => 'root',
                  group   => 'root',
                  mode    => '0644',
                  content => template("${module_name}/systemd.service.erb"),
                  notify  => Exec['ipset_systemctl_daemonreload'],
                }
              }
            }
            default: { fail("Unsupported Ubuntu version is ${$::operatingsystemrelease} - autostart not enabled") }
          }
        }
      }
    }
    '': {  # handle bug in our Jenkins that returns empty strings for all of these when verifying
          if "${$::osfamily}${$::operatingsystem}${$::operatingsystemmajrelease}" == '' {
            warning("Got null for OS Family, assuming I'm running in Jenkins and this is a known bug!") }
          else {    fail( "Unsupported OSFamily \"${$::osfamily}\" OS is \"${$::operatingsystem}\" major version is \"${$::operatingsystemmajrelease}\" ") }
        }
    default:     { fail( "Unsupported OSFamily \"${$::osfamily}\" OS is \"${$::operatingsystem}\" major version is \"${$::operatingsystemmajrelease}\" ") }
  }
  exec { 'ipset_systemctl_daemonreload':
    command     => 'systemctl daemon-reload',
    path        => [ '/bin/', '/usr/bin/' ],
    refreshonly => true,
  }
}
