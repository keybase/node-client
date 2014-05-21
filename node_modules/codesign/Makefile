default: build
all: build

ICED=node_modules/.bin/iced
BUILD_STAMP=build-stamp
TEST_STAMP=test-stamp

default: build
all: build

lib/%.js: src/%.iced
	$(ICED) -I browserify -c -o `dirname $@` $<

lib/preset/%.js: src/preset/%.iced
	$(ICED) -I browserify -c -o `dirname $@` $<

$(BUILD_STAMP): \
	lib/codesign.js \
	lib/constants.js \
	lib/file_info_cache.js \
	lib/main.js \
	lib/markdown.js \
	lib/package.js \
	lib/preset/dropbox.js \
	lib/preset/git.js \
	lib/preset/globber.js \
	lib/preset/kb.js \
	lib/preset/preset_base.js \
	lib/summarized_item.js \
	lib/top.js \
	lib/utils.js \
	lib/x_platform_hash.js
	date > $@

clean:
	find lib -type f -name *.js -exec rm {} \;

build: $(BUILD_STAMP) 

setup: 
	npm install -d

test:
