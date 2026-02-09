PREFIX ?= /usr/local

.PHONY: test install uninstall

test:
	nix --extra-experimental-features 'nix-command flakes' run nixpkgs#bats -- tests/

install:
	install -d $(PREFIX)/bin
	install -d $(PREFIX)/lib/pgit
	install -m 755 bin/pgit $(PREFIX)/bin/pgit
	install -m 755 bin/pnp $(PREFIX)/bin/pnp
	install -m 644 lib/pgit-*.sh $(PREFIX)/lib/pgit/

uninstall:
	rm -f $(PREFIX)/bin/pgit
	rm -f $(PREFIX)/bin/pnp
	rm -rf $(PREFIX)/lib/pgit
