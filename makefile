.PHONY: all backend web

all: web

WEB_BUILD_DIR = build

backend: 
	$(MAKE) -C stagess_backend

web: 
	rm -rf $(WEB_BUILD_DIR)
	mkdir -p $(WEB_BUILD_DIR)
	$(MAKE) -C stagess all
	cp -r stagess/build/stagess/ $(WEB_BUILD_DIR)/stagess
	cp -r stagess/build/tutoriel/ $(WEB_BUILD_DIR)/tutoriel
	$(MAKE) -C stagess_admin all
	cp -r stagess_admin/build/admin/ $(WEB_BUILD_DIR)/admin
	cp -r stagess_admin/build/tutoriel-admin/ $(WEB_BUILD_DIR)/tutoriel-admin
	cp utilities/index.html $(WEB_BUILD_DIR)/index.html
	cd $(WEB_BUILD_DIR) && zip -r stagess.zip .
