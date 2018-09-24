#!/bin/bash
set -uxe
rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
yum install -y puppet-3.8.7-1.el7.noarch
