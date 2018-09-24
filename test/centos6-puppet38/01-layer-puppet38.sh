#!/bin/bash
set -uxe
rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm
yum install -y puppet-3.8.7-1.el6.noarch
