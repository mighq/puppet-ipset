# puppet-ipset
Linux ipset management by puppet.

Roughly based on [thias/ipset](https://github.com/thias/puppet-ipset) module.
* checks for current ipset state, before doing any changes to it
* applies ipset every time it drifts from target state, not only on config file change
* handles type changes
* autostart added for rhel-6 family
