
ICED=node_modules/.bin/iced
BROWSERIFY=node_modules/.bin/browserify
BUILD_STAMP=build-stamp
WD=`pwd`


lib/%.js: src/%.coffee
	$(ICED) -I none -c -o lib $<

$(BUILD_STAMP): \
	lib/main.js \
	lib/buffer.js \
	lib/const.js \
        lib/frame.js \
	lib/pack.js \
	lib/unpack.js \
	lib/util.js 
	date > $@

build: $(BUILD_STAMP)

test/pack/data.js: test/pack/generate.iced test/pack/input.iced
	$(ICED) test/pack/generate.iced > $@

test-server: test/pack/data.js
	$(ICED) test/run.iced

test/browser/test.js: test/browser/main.iced $(BUILD_STAMP) test/pack/data.js
	$(BROWSERIFY) -t icsify $< > $@

test-browser: test/browser/test.js
	@echo "Please visit in your favorite browser --> file://$(WD)/test/browser/index.html"

test: test-server test-browser

clean:
	rm -f lib/*.js test/pack/data.js $(BUILD_STAMP)

default: build
all: build

setup:
	npm install -d

.PHONY: clean setup test test-browser-buffer
