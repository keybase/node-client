default: build
all: build

ICED=node_modules/.bin/iced

index.js: index.iced
	$(ICED) -I browserify -c -o `dirname $@` $<

clean:
	rm -rf index.js

setup:
	npm install -d

test:
	$(ICED) test/run.iced

build: index.js

.PHONY: clean setup test
