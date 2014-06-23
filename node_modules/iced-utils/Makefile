default: build
all: build

ICED=node_modules/.bin/iced
BUILD_STAMP=build-stamp
TEST_STAMP=test-stamp


lib/%.js: src/%.iced
	$(ICED) -I browserify -c -o `dirname $@` $<

$(BUILD_STAMP): \
	lib/drain.js \
	lib/enum.js \
	lib/fs.js \
    lib/gets.js \
	lib/getopt.js \
	lib/lock.js \
	lib/lockfile.js \
	lib/main.js \
	lib/spawn.js \
	lib/util.js 
	date > $@

clean:
	find lib -type f -name *.js -exec rm {} \;

build: $(BUILD_STAMP) 

setup: 
	npm install -d

test:
	iced test/run.iced

.PHONY: test setup

