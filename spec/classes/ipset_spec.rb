require 'spec_helper'

describe 'ipset' do
 it do
   should contain_package('ipset')
 end
 it 'drops ipset_init' do
   should contain_file('/usr/local/sbin/ipset_init')
 end
 it 'drops ipset_sync' do
   should contain_file('/usr/local/sbin/ipset_sync')
 end
 it 'drops ipset.conf' do
   should contain_file('/etc/init/ipset.conf')
 end

end
