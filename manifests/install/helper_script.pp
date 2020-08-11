define ipset::install::helper_script () {
  file { "/usr/local/sbin/${title}":
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0754',
    source => "puppet:///modules/${module_name}/${title}",
  }
}
