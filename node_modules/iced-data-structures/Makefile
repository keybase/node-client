ICED=node_modules/.bin/iced
BROWSERIFY=node_modules/.bin/browserify
BUILD_STAMP=build-stamp
WD=`pwd`

lib/%.js: src/%.iced
	$(ICED) -I none -c -o lib $<

$(BUILD_STAMP): \
	lib/index.js \
	lib/list.js 
	date > $@

build: $(BUILD_STAMP)

clean:
	rm -f lib/*.js $(BUILD_STAMP)

default: build
all: build

setup:
	npm install -d

.PHONY: clean setup 