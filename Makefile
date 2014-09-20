
default: build
all: build

ICED=node_modules/.bin/iced
BUILD_STAMP=build-stamp
TEST_STAMP=test-stamp

default: build
all: build

lib/%.js: src/%.iced
	$(ICED) -I node -c -o `dirname $@` $<

$(BUILD_STAMP): \
	lib/command/announce.js \
	lib/command/argparse.js \
	lib/command/all.js \
	lib/command/base.js \
	lib/command/btc.js \
	lib/command/cert.js \
	lib/command/config.js \
	lib/command/decrypt.js \
	lib/command/decrypt_and_verify.js \
	lib/command/dir.js \
	lib/command/encrypt.js \
	lib/command/help.js \
	lib/command/id.js \
	lib/command/join.js \
	lib/command/keygen.js \
	lib/command/list_signatures.js \
	lib/command/list_tracking.js \
	lib/command/login.js \
	lib/command/logout.js \
	lib/command/proof_base.js \
	lib/command/prove.js \
	lib/command/pull.js \
	lib/command/push.js \
	lib/command/push_and_keygen.js \
	lib/command/reset.js \
	lib/command/revoke.js \
	lib/command/revoke_sig.js \
	lib/command/search.js \
	lib/command/sign.js \
	lib/command/status.js \
	lib/command/switch.js \
	lib/command/track.js \
	lib/command/untrack.js \
	lib/command/update.js \
	lib/command/verify.js \
	lib/command/version.js \
	lib/basex.js \
	lib/bn.js \
	lib/ca.js \
	lib/chainlink.js \
	lib/checkers.js \
	lib/colors.js \
	lib/config.js \
	lib/constants.js \
	lib/db.js \
	lib/display.js \
	lib/dve.js \
	lib/env.js \
	lib/err.js \
	lib/file.js \
	lib/fs.js \
	lib/gpg.js \
	lib/hkp_loopback.js \
	lib/keymanager.js \
	lib/keypatch.js \
	lib/keypull.js \
	lib/keyring.js \
	lib/keyselector.js \
	lib/keys.js \
	lib/keyutils.js \
	lib/log.js \
	lib/merkle_client.js \
	lib/package.js \
	lib/prompter.js \
	lib/proxyca.js \
	lib/services.js \
	lib/sigs.js \
	lib/pw.js \
	lib/queue.js \
	lib/req.js \
	lib/scrapers.js \
	lib/session.js \
	lib/setup.js \
	lib/sigchain.js \
	lib/tor.js \
	lib/trackwrapper.js \
	lib/tracksubsub.js \
	lib/user.js \
	lib/util.js \
	lib/version.js
	date > $@

clean:
	find lib -type f -name *.js -exec rm {} \;

build: $(BUILD_STAMP)

setup:
	npm install -d

test:
	(cd test && ../$(ICED) run.iced)

.PHONY: test setup
