ICED=node_modules/.bin/iced
BUILD_STAMP=build-stamp
TEST_STAMP=test-stamp
WD=`pwd`

default: build
all: build

lib/%.js: src/%.iced
	$(ICED) -I browserify -c -o `dirname $@` $<

$(BUILD_STAMP): \
	lib/util.js \
	lib/armor.js \
	lib/main.js \
	lib/userid.js
	date > $@

build: $(BUILD_STAMP) 

clean:
	rm -rf lib/* $(BUILD_STAMP) $(TEST_STAMP)

test:
	$(ICED) test/run.iced

setup:
	npm install -d

.PHONY: clean setup test  test-browser
