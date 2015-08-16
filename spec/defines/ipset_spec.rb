require 'spec_helper'

describe 'ipset' do
 let(:title){ 'ipset' }
 let(:params){{ :set => "myipset" }}
 it do
   should contain_package('ipset')
   should contain_file("/usr/local/sbin/ipset_init").
     with_mode('0754').with_owner('root').with_group('root').
     with_source("puppet:///modules/ipset/ipset_init")
   should contain_file("/usr/local/sbin/ipset_sync").
     with_mode('0754').with_owner('root').with_group('root').
     with_source("puppet:///modules/ipset/ipset_sync")
  end
end
