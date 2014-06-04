
ICED=node_modules/.bin/iced

index.js: index.iced
	$(ICED) -m -c $<

default: index.js

pubclean:
	rm -rf node_modules

clean:
	rm -rf index.js

setup:
	npm install -d

.PHONY: setup pubclean
