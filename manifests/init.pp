define ipset (
  $set,
  $ensure       = 'present',
  $type         = 'hash:ip',
  $options      = {},
  # do not touch what is inside the set, just its header (properties)
  $ignore_contents = false,
  # keep definition file and in-kernel runtime state in sync
  $keep_in_sync = true,
) {
  include ipset::params

  include ipset::install

  $default_options = {
    'family'   => 'inet',
    'hashsize' => '1024',
    'maxelem'  => '65536',
  }

  $actual_options = merge($default_options, $options)

  if $ensure == 'present' {
    # assert "present" target

    $opt_string = inline_template('<%= (@actual_options.sort.map { |k,v| k.to_s + " " + v.to_s }).join(" ") %>')

    # header
    file { "${::ipset::params::config_path}/${title}.hdr":
      content => "create ${title} ${type} ${opt_string}\n",
      notify  => Exec["sync_ipset_${title}"],
    }

    # content
    if is_array($set) {
      # create file with ipset, one record per line
      file { "${::ipset::params::config_path}/${title}.set":
        ensure  => present,
        content => inline_template('<%= (@set.map { |i| i.to_s }).join("\n") %>'),
      }
    } elsif $set =~ /^puppet:\/\// {
      # passed as puppet file
      file { "${::ipset::params::config_path}/${title}.set":
        ensure => present,
        source => $set,
      }
    } elsif $set =~ /^file:\/\// {
      # passed as target node file
      file { "${::ipset::params::config_path}/${title}.set":
        ensure => present,
        source => regsubst($set, '^.{7}', ''),
      }
    } else {
      # passed directly as content string (from template for example)
      file { "${::ipset::params::config_path}/${title}.set":
        ensure  => present,
        content => $set,
      }
    }

    # add switch to script, if we 
    if $ignore_contents {
      $ignore_contents_opt = ' -n'
    } else {
      $ignore_contents_opt = ''
    }

    # sync if needed by helper script
    exec { "sync_ipset_${title}":
      path    => [ '/sbin', '/usr/sbin', '/bin', '/usr/bin' ],

      # use helper script to do the sync
      command => "/usr/local/sbin/ipset_sync -c '${::ipset::params::config_path}'    -i ${title}${ignore_contents_opt}",

      # only when difference with in-kernel set is detected
      unless  => "/usr/local/sbin/ipset_sync -c '${::ipset::params::config_path}' -d -i ${title}${ignore_contents_opt}",

      require => Package['ipset'],
    }

    if $keep_in_sync {
        File["${::ipset::params::config_path}/${title}.set"] ~> Exec["sync_ipset_${title}"]
    }
  } elsif $ensure == 'absent' {
    # ensuring absence

    # do not contain config files
    file { ["${::ipset::params::config_path}/${title}.set", "${::ipset::params::config_path}/${title}.hdr"]:
      ensure  => absent,
    }

    # clear ipset from kernel
    exec { "ipset destroy ${title}":
      path    => [ '/sbin', '/usr/sbin', '/bin', '/usr/bin' ],

      command => "/usr/sbin/ipset destroy ${title}",
      onlyif  => "/usr/sbin/ipset list -name ${title} &>/dev/null",

      require => Package['ipset'],
    }
  } else {
    fail('Unsupported "ensure" parameter.')
  }
}
