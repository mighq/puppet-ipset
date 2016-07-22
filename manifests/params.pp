class ipset::params (
  # if uou use "firewalld" to manage firewall,
  # create instance of ipset::params class with this service name
  $use_firewall_service = undef,
) {
  $package = $::osfamily ? {
    'RedHat' => 'ipset',
    default  => 'ipset',
  }

  $config_path = $::osfamily ? {
    'RedHat' => '/etc/sysconfig/ipset.d',
    'Debian' => '/etc/ipset.d',
    default  => '/etc/ipset.d',
  }

  if $use_firewall_service {
    # use specified override
    $firewall_service = $use_firewall_service
  } else {
    # OS defaults
    if $::osfamily == 'RedHat' {
      if  $::operatingsystemmajrelease == '6' {
        $firewall_service = 'iptables'
      } elsif $::operatingsystemmajrelease == '7' {
        $firewall_service = 'firewalld'
      }
    } else {
      # by default expect everyone to use iptables
      $firewall_service = 'iptables'
    }
  }
}
