default: build
all: build

ICED=node_modules/.bin/iced
BUILD_STAMP=build-stamp
TEST_STAMP=test-stamp

default: build
all: build

lib/%.js: src/%.iced
	$(ICED) -I browserify -c -o `dirname $@` $<

$(BUILD_STAMP): \
	lib/base.js \
	lib/config.js \
	lib/constants.js \
	lib/get_index.js \
	lib/installer.js \
	lib/key_setup.js \
	lib/key_install.js \
	lib/key_upgrade.js \
	lib/log.js \
	lib/main.js \
	lib/npm.js \
	lib/package.js \
	lib/request.js \
	lib/software_upgrade.js \
	lib/top.js \
	lib/util.js
	date > $@

clean:
	find lib -type f -name *.js -exec rm {} \;

build: $(BUILD_STAMP) 

setup: 
	npm install -d

test:

.PHONY: test setup
