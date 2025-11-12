.PHONY: all backend web

include utilities/makefile_commands.mk

WEB_BUILD_DIR = build

all: web

backend: 
	$(MAKE) -C stagess_backend

reverse_proxy:
	$(MAKE) -C stagess_reverse_proxy

web: 
	$(call safe_rmdir, $(WEB_BUILD_DIR))
	$(MakeDir)   $(WEB_BUILD_DIR)
	$(MAKE)      -C stagess all
	$(call CopyDir,stagess/build/stagess,$(WEB_BUILD_DIR)/stagess)
	$(call CopyDir,stagess/build/tutoriel,$(WEB_BUILD_DIR)/tutoriel)
	$(MAKE)      -C stagess_admin all
	$(call CopyDir,stagess_admin/build/admin,$(WEB_BUILD_DIR)/admin)
	$(call CopyDir,stagess_admin/build/tutoriel-admin,$(WEB_BUILD_DIR)/tutoriel-admin)
	$(call CopyFile,utilities/index.html,$(WEB_BUILD_DIR)/index.html)
	$(ChangeDir) $(WEB_BUILD_DIR) && zip -r stagess.zip .
