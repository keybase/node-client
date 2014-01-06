
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
	lib/command/encrypt.js \
	lib/command/help.js \
	lib/command/id.js \
	lib/command/join.js \
	lib/command/login.js \
	lib/command/logout.js \
	lib/command/prove.js \
	lib/command/push.js \
	lib/command/reset.js \
	lib/command/revoke.js \
	lib/command/switch.js \
	lib/command/track.js \
	lib/command/untrack.js \
	lib/command/version.js \
	lib/basex.js \
	lib/bn.js \
	lib/checkers.js \
	lib/config.js \
	lib/constants.js \
	lib/db.js \
	lib/env.js \
	lib/err.js \
	lib/file.js \
	lib/fs.js \
        lib/gpg.js \
	lib/gpgkey.js \
	lib/keymanager.js \
	lib/keyring.js \
	lib/keyselector.js \
	lib/keyutils.js \
	lib/log.js \
	lib/package.js \
	lib/path.js \
	lib/prompter.js \
	lib/sigs.js \
	lib/pw.js \
	lib/queue.js \
	lib/req.js \
	lib/session.js \
	lib/setup.js \
	lib/sigchain.js \
	lib/trackwrapper.js \
	lib/tracksubsub.js \
	lib/user.js \
	lib/util.js
	date > $@

clean:
	find lib -type f -name *.js -exec rm {} \;

build: $(BUILD_STAMP) 

setup: 
	npm install -d

test:

.PHONY: test setup
