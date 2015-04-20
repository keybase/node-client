default: build
all: build

ICED=node_modules/.bin/iced
BUILD_STAMP=build-stamp
TEST_STAMP=test-stamp

%.js: %.iced
	$(ICED) -I node -c -o `dirname $@` $<

$(BUILD_STAMP): \
	index.js 
	date > $@

clean:
	rm -f index.js

build: $(BUILD_STAMP) 

setup: 
	npm install -d

test:

.PHONY: test setup

