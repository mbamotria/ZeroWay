.PHONY: install install-files uninstall

install:
	sudo ./scripts/install.sh

install-files:
	sudo ACTIVATE_THEME=0 ./scripts/install.sh

uninstall:
	sudo ./scripts/uninstall.sh
