class ipset::params {
  $package = $::osfamily ? {
    'RedHat' => 'ipset',
    default  => 'ipset',
  }

  $config_path = $::osfamily ? {
    'RedHat' => '/etc/sysconfig/ipset.d',
    'Debian' => '/etc/iptables/ipset.d',
    default  => '/etc/sysconfig/ipset.d',
  }

   $before_target = $::osfamily ? {
     'Debian' => 'netfilter-persistent.service',
     default  => 'network.target',
   }

   $lib_systemd_file = $::osfamily ? {
     'Debian' => '/lib/systemd/system/ipset.service',
     default => '/usr/lib/systemd/system/ipset.service',
   }

   $etc_systemd_file = $::osfamily ? {
      'Debian' => '/etc/systemd/system/multi-user.target.wants/ipset.service',
      default => '/etc/systemd/system/basic.target.wants/ipset.service',
   }
}
