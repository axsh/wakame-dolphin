CURDIR ?= $(PWD)
RUBYDIR = $(CURDIR)/ruby
DSTDIR ?= ""

define BUNDLE_CFG
---
BUNDLE_PATH: vendor/bundle
BUNDLE_DISABLE_SHARED_GEMS: '1'
endef
# We're exporting this as a shell variable because otherwise Make can't echo multiline strings into a file
export BUNDLE_CFG

dev: build-ruby install-bundle-dev

build-ruby:
	$(CURDIR)/deployment/rubybuild/build_ruby.sh

install-bundle-dev:
	$(RUBYDIR)/bin/gem install bundler
	(cd $(CURDIR); mkdir .bundle; echo "$$BUNDLE_CFG" > .bundle/config)
	(cd $(CURDIR); $(RUBYDIR)/bin/bundle install)

install-bundle-with-cassandra:
	$(RUBYDIR)/bin/gem install bundler
	(cd $(CURDIR); mkdir .bundle; echo "$$BUNDLE_CFG" > .bundle/config)
	(cd $(CURDIR); $(RUBYDIR)/bin/bundle install --without development test mysql)

install-bundle-with-mysql:
	$(RUBYDIR)/bin/gem install bundler
	(cd $(CURDIR); mkdir .bundle; echo "$$BUNDLE_CFG" > .bundle/config)
	(cd $(CURDIR); $(RUBYDIR)/bin/bundle install --without development test cassandra)

install: update-config
	mkdir -p $(DSTDIR)/opt/axsh/wakame-dolphin
	mkdir -p $(DSTDIR)/etc/wakame-vdc
	cp -r . $(DSTDIR)/opt/axsh/wakame-dolphin
	cp -r deployment/conf_files/etc/default $(DSTDIR)/etc
	cp -r deployment/conf_files/etc/init $(DSTDIR)/etc

uninstall:
	rm -rf $(DSTDIR)/opt/axsh/wakame-dolphin
	rm -rf $(DSTDIR)/tmp/log
	rm -rf $(DSTDIR)/var/run/wakame-dolphin
	rm $(DSTDIR)/etc/default/vdc-dolphin
	rm $(DSTDIR)/etc/init/vdc-dolphin.conf

update-config:
	cp -r deployment/conf_files/etc/wakame-vdc $(DSTDIR)/etc/

remove-config:
	rm -rf $(DSTDIR)/etc/wakame-vdc/dolphin.conf

clean:
	# rm -rf $(RUBYDIR)
	rm -rf $(CURDIR)/vendor
	rm -rf $(CURDIR)/.bundle
