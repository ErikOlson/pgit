PREFIX ?= /usr/local

.PHONY: test install uninstall

test:
	nix --extra-experimental-features 'nix-command flakes' run nixpkgs#bats -- tests/

install:
	install -d $(PREFIX)/bin
	install -m 755 bin/pgit $(PREFIX)/bin/pgit
	install -m 755 bin/pnp $(PREFIX)/bin/pnp

uninstall:
	rm -f $(PREFIX)/bin/pgit
	rm -f $(PREFIX)/bin/pnp
