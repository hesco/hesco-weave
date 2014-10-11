
release: *
	/bin/bash scripts/set_version.sh
	/usr/bin/puppet module build --verbose
	/bin/echo "This is likely a good time to `git push origin master --tags `"

