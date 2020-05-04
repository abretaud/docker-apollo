#!/bin/bash
set -ex
# Doubly set, because reasons.
export JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk/jre

source $HOME/.sdkman/bin/sdkman-init.sh

cd /apollo/ && \

	# Temp Apollo patches when needed...
	patch -p1 < /tmp/2379.diff && \
  patch -p1 < /tmp/6ef7007c3c21c397704563bc8b0529dd260360da.diff && \
	patch -p1 < /tmp/90b893d8d68afcf46711a9ce0f2fd8109e178ae2.diff && \
  patch -p1 < /tmp/symlink_fix.diff && \
  patch -p1 < /tmp/2476.diff && \

	./apollo deploy && \

	# Move to tmp dir
	cp /apollo/target/apollo*.war /tmp/ && \
	# So we can remove ~1.6 GB of cruft from the image. Ignore errors because cannot remove parent dir /apollo/
	rm -rf /apollo/ || true && \
	# Before moving back into a standardized location (that we have write access to)
	mv /tmp/apollo*.war /apollo/ && \
	# Symlink to the expected name, but leave the original to allow us to pull out the named file
	ln -s /apollo/apollo*.war /apollo/apollo.war

if [ -d /output/ ]; then
	cp /apollo/apollo.war /output/;
fi
