# Wrapper for sets, whose contents is not managed by puppet
#
# Warning: when chaning set attributes (type, options)
#          contents won't be kept, set will be recreated as empty
define ipset::unmanaged(
  $ensure  = 'present',
  $type    = 'hash:ip',
  $options = {},
  $keep_in_sync = true,
) {
  ipset { $title:
    ensure          => $ensure,
    #
    set             => '',
    ignore_contents => true,
    #
    type            => $type,
    options         => $options,
    keep_in_sync    => $keep_in_sync,
  }
}
