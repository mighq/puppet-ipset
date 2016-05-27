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
  if $::osfamily == 'RedHat' and $::operatingsystemmajrelease == '6' {
    # upstart starter
    file { '/etc/init/ipset.conf':
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template("${module_name}/init.upstart.erb"),
    }
    # do not use original RC start script from the ipset package
    # it is hard to define dependencies there
    # also, it can collide with what we define through puppet
    service { 'ipset':
      enable   => false,
      provider => 'redhat',
    }
  } else {
    if $::osfamily == 'RedHat' and $::operatingsystemmajrelease == '7' {
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
    } else {
      warning('Autostart of ipset not implemented for this OS.')
    }
  }
}
