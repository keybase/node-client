ICED=node_modules/.bin/iced
BUILD_STAMP=build-stamp
TEST_STAMP=test-stamp
UGLIFYJS=node_modules/.bin/uglifyjs
WD=`pwd`
BROWSERIFY=node_modules/.bin/browserify

default: build
all: build

lib/%.js: src/%.iced
	$(ICED) -I browserify -c -o `dirname $@` $<

$(BUILD_STAMP): \
	lib/alloc.js \
	lib/announcement.js \
	lib/auth.js \
	lib/base.js \
	lib/b64extract.js \
	lib/constants.js \
	lib/cryptocurrency.js \
	lib/device.js \
	lib/eldest.js \
	lib/main.js \
	lib/revoke.js \
	lib/sibkey.js \
	lib/subkey.js \
	lib/scrapers/base.js \
	lib/scrapers/coinbase.js \
	lib/scrapers/dns.js \
	lib/scrapers/generic_web_site.js \
	lib/scrapers/github.js \
	lib/scrapers/hackernews.js \
	lib/scrapers/reddit.js \
	lib/scrapers/twitter.js \
	lib/track.js \
	lib/web_service.js \
	lib/update_passphrase_hash.js \
	lib/util.js
	date > $@

build: $(BUILD_STAMP)

test-server: $(BUILD_STAMP)
	$(ICED) test/run.iced

test-browser: $(TEST_STAMP) $(BUILD_STAMP)
	@echo "Please visit in your favorite browser --> file://$(WD)/test/browser/index.html"

test/browser/test.js: test/browser/main.iced $(BUILD_STAMP)
	$(BROWSERIFY) -t icsify $< > $@

$(TEST_STAMP): test/browser/test.js
	date > $@

test: test-server test-browser

clean:
	rm -rf lib/* lib/scrapers/* $(BUILD_STAMP) $(TEST_STAMP)

setup:
	npm install -d

.PHONY: clean setup test  test-browser
