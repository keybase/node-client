
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
	lib/command/argparse.js \
	lib/command/all.js \
	lib/command/base.js \
	lib/command/config.js \
	lib/command/join.js \
	lib/command/version.js \
	lib/command/push.js \
	lib/basex.js \
	lib/bn.js \
	lib/checkers.js \
	lib/config.js \
	lib/constants.js \
	lib/env.js \
	lib/err.js \
	lib/file.js \
	lib/fs.js \
	lib/gpg.js \
	lib/keymanager.js \
	lib/keyselector.js \
	lib/log.js \
	lib/package.js \
	lib/path.js \
	lib/proofer.js \
	lib/prompter.js \
	lib/pw.js \
	lib/queue.js \
	lib/req.js \
	lib/session.js \
	lib/stream.js \
	lib/util.js
	date > $@

build: $(BUILD_STAMP) 

setup: 
	npm install -d

test:

.PHONY: test setup
