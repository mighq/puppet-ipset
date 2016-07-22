all:
	puppet module build .

check:
	rpm -qa | grep -vq ^rubygem-puppet-lint$$ || yum -y install rubygem-puppet-lint
	for i in `find . -type f -name '*.pp'`; do echo $$i; puppet-lint --no-documentation-check --no-80chars-check --no-autoloader_layout-check $$i; done
