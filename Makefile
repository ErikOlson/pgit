PREFIX ?= /usr/local
BASH_COMPLETION_DIR ?= $(PREFIX)/share/bash-completion/completions
ZSH_COMPLETION_DIR ?= $(PREFIX)/share/zsh/site-functions
FISH_COMPLETION_DIR ?= $(PREFIX)/share/fish/vendor_completions.d

.PHONY: test install install-completions uninstall

test:
	nix --extra-experimental-features 'nix-command flakes' run nixpkgs#bats -- tests/

install:
	install -d $(PREFIX)/bin
	install -d $(PREFIX)/lib/pgit
	install -d $(PREFIX)/share/pgit/completions
	install -m 755 bin/pgit $(PREFIX)/bin/pgit
	install -m 755 bin/pnp $(PREFIX)/bin/pnp
	install -m 644 lib/pgit-*.sh $(PREFIX)/lib/pgit/
	install -m 644 completions/pgit.bash $(PREFIX)/share/pgit/completions/pgit.bash
	install -m 644 completions/_pgit $(PREFIX)/share/pgit/completions/_pgit
	install -m 644 completions/pgit.fish $(PREFIX)/share/pgit/completions/pgit.fish

install-completions:
	install -d $(BASH_COMPLETION_DIR)
	install -d $(ZSH_COMPLETION_DIR)
	install -d $(FISH_COMPLETION_DIR)
	install -m 644 completions/pgit.bash $(BASH_COMPLETION_DIR)/pgit
	install -m 644 completions/_pgit $(ZSH_COMPLETION_DIR)/_pgit
	install -m 644 completions/pgit.fish $(FISH_COMPLETION_DIR)/pgit.fish

uninstall:
	rm -f $(PREFIX)/bin/pgit
	rm -f $(PREFIX)/bin/pnp
	rm -rf $(PREFIX)/lib/pgit
	rm -rf $(PREFIX)/share/pgit
	rm -f $(BASH_COMPLETION_DIR)/pgit
	rm -f $(ZSH_COMPLETION_DIR)/_pgit
	rm -f $(FISH_COMPLETION_DIR)/pgit.fish
