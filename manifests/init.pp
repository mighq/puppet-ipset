define ipset (
  $ensure = undef,
  $set,
  $type = 'hash:ip',
  $options = {
    'family'   => 'inet',
    'hashsize' => '1024',
    'maxelem'  => '65536',
  },
  $keep_in_sync = true,
) {
  include ipset::params

  include ipset::install

  if $ensure != 'absent' {
    # assert "present" target

    $opt_string = inline_template('<%= (@options.sort.map { |k,v| k.to_s + " " + v.to_s }).join(" ") %>')

    # header
    file { "${::ipset::params::config_path}/${title}.hdr":
      content => "create ${title} ${type} ${opt_string}\n",
      notify  => Exec["sync_ipset_${title}"],
    }

    # content
    if $set =~ /^puppet:\/\// {
      # passed as puppet file
      file { "${::ipset::params::config_path}/${title}.set":
        ensure  => present,
        source  => $set,
      }
    } elsif $set =~ /^file:\/\// {
      # passed as target node file
      file { "${::ipset::params::config_path}/${title}.set":
        ensure  => present,
        source  => regsubst($set, '^.{7}', ''),
      }
    } else {
      # passed directly as content (from template for example)
      file { "${::ipset::params::config_path}/${title}.set":
        ensure  => present,
        content => $set,
      }
    }

    # sync if needed by helper script
    exec { "sync_ipset_${title}":
      # use helper script to do the sync
      command   => "/usr/local/sbin/ipset_sync -c '${::ipset::params::config_path}'    -i ${title}",
      # only when difference with in-kernel set is detected
      unless    => "/usr/local/sbin/ipset_sync -c '${::ipset::params::config_path}' -d -i ${title}",

      path      => [ '/sbin', '/usr/sbin', '/bin', '/usr/bin' ],

      require   => Package['ipset'],
    }

    if $keep_in_sync {
        File["${::ipset::params::config_path}/${title}.set"] ~> Exec["sync_ipset_${title}"]
    }
  } else {
    # ensuring absence

    # do not contain config files
    file { ["${::ipset::params::config_path}/${title}.set", "${::ipset::params::config_path}/${title}.hdr"]:
      ensure  => absent,
    }

    # clear ipset from kernel
    exec { "/usr/sbin/ipset destroy ${title}":
      onlyif  => "/usr/sbin/ipset list ${title} &>/dev/null",
      require => Package['ipset'],
    }
  }
}
