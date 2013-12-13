
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
	lib/command/all.js \
	lib/command/base.js \
	lib/command/argparse.js \
	lib/command/version.js \
	lib/basex.js \
	lib/bn.js \
	lib/config.js \
	lib/constants.js \
	lib/err.js \
	lib/file.js \
	lib/fs.js \
	lib/gpg.js \
	lib/log.js \
	lib/package.js \
	lib/pw.js \
	lib/queue.js \
	lib/stream.js \
	lib/util.js
	date > $@

build: $(BUILD_STAMP) 

setup: 
	npm install -d

test:

.PHONY: test setup
