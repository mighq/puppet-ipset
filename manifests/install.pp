class ipset::install (
    $config_path = $::ipset::params::config_path,
    $etc_systemd_file = $::ipset::params::etc_systemd_file,
    $lib_systemd_file = $::ipset::params::lib_systemd_file,
) {
  include ipset::params

  $cfg = $config_path

  # main package
  package { $::ipset::params::package:
    alias  => 'ipset',
    ensure => installed,
  }

  if $::osfamily == 'Debian' and $::operatingsystemmajrelease == '8' {
      package { 'netfilter-persistent':
        ensure => installed,
      }
  }

  # directory with config profiles (*.set & *.hdr files)
  file { $cfg:
    ensure => directory,
  }

  # helper scripts
  ipset::install::helper_script { ['ipset_sync', 'ipset_init']: }

  # autostart
  if $::osfamily == 'RedHat' and $::operatingsystemmajrelease == '6' {
    # upstart starter
    file { '/etc/init/ipset.conf':
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template("${module_name}/init.upstart.erb"),
    }
  } elsif (($::osfamily == 'RedHat' and $::operatingsystemmajrelease == '7')
            or ($::osfamily == 'Debian' and $::operatingsystemmajrelease == '8'))
  {
      # systemd
      file { $::ipset::params::lib_systemd_file:
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template("${module_name}/systemd.service.erb"),
      }
      file { $::ipset::params::etc_systemd_file:
        ensure => link,
        target => $::ipset::params::lib_systemd_file,
      }
  } else {
      warning('Autostart of ipset not implemented for this OS.')
  }
}
