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
	lib/err.js \
	lib/gpg.js \
	lib/keyring.js \
	lib/index.js \
	lib/main.js \
	lib/parse.js \
	lib/colgrep.js  
	date > $@

clean:
	find lib -type f -name *.js -exec rm {} \;

build: $(BUILD_STAMP) 

setup: 
	npm install -d

test: $(BUILD_STAMP)
	$(ICED) test/run.iced

.PHONY: test setup
