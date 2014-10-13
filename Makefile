
release: *
	/bin/bash scripts/set_version.sh
	/usr/bin/puppet module build --verbose
	/usr/bin/git push origin master --tags

