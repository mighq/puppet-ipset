class ipset::install {
  include ipset::params

  $cfg = $::ipset::params::config_path

  # main package
  package { $::ipset::params::package:
    ensure => 'present',
    alias  => 'ipset',
  }

  # directory with config profiles (*.set & *.hdr files)
  file { $cfg:
    ensure => directory,
  }

  # helper scripts
  ipset::install::helper_script { ['ipset_sync', 'ipset_init']: }

  # autostart
  if $::osfamily == 'RedHat' {
    if $::operatingsystemmajrelease == '6' {
      # make sure libmnl is installed
      package { 'libmnl':
        ensure => installed,
        before => Package[$::ipset::params::package],
      }

      # do not use original RC start script from the ipset package
      # it is hard to define dependencies there
      # also, it can collide with what we define through puppet
      #
      # using exec instead of Service, because of bug:
      # https://tickets.puppetlabs.com/browse/PUP-6516
      exec { 'ipset_disable_distro':
        command  => "/bin/bash -c '/etc/init.d/ipset stop && /sbin/chkconfig ipset off'",
        unless   => "/bin/bash -c '/sbin/chkconfig | /bin/grep ipset | /bin/grep -qv :on'",
        require  => Package[$::ipset::params::package],
      }
      ->
      # upstart starter
      file { '/etc/init/ipset.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template("${module_name}/init.upstart.erb"),
      }
      ~>
      # upstart service autostart
      service { 'ipset_enable_upstart':
        name     => 'ipset',
        enable   => true,
        provider => 'upstart',
        require  => Ipset::Install::Helper_script[ ['ipset_sync', 'ipset_init'] ]
      }
      # dependency is covered by running ipset before RC scripts suite, where firewall service is
    } elsif $::operatingsystemmajrelease == '7' or $::operatingsystemmajrelease == '8' {
      # for management of dependencies
      $firewall_service = $::ipset::params::firewall_service

      # TODO: use ipset-service package

      # systemd service definition, there is no script in COS7
      file { '/usr/lib/systemd/system/ipset.service':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template("${module_name}/init.systemd.erb"),
      }
      ~>
      exec { 'ipset systemctl daemon-reload':
        command     => '/bin/systemctl daemon-reload',
        refreshonly => true,
      }
      ~>
      # systemd service autostart
      service { 'ipset':
        ensure  => 'running',
        enable  => true,
        require => Ipset::Install::Helper_script[ ['ipset_sync', 'ipset_init'] ]
      }

      exec { 'reload-ipset-systemd-unit-if-not-in-sync':
        command  => 'systemctl daemon-reload',
        onlyif   => 'systemctl cat ipset 2>&1 1>/dev/null | grep -q daemon-reload',
        provider => shell,
      }
    } else {
      warning('Autostart of ipset not implemented for this RedHat release.')
    }
  } else {
    warning('Autostart of ipset not implemented for this OS.')
  }
}
