.PHONY: main tutorial

include ../utilities/makefile_commands.mk

OUT_DIR := build
ZIP := zip -r

all: main tutorial

# Generic rule: build/NAME.zip with USE_DEV_DB flag
.FORCE:
build/%.zip: .FORCE
	$(call safe_rmdir, $(OUT_DIR)/$*)
	@if [ -z "$${STAGESS_GOOGLE_MAPS_API_KEY}" ]; then \
	  echo "Error: STAGESS_GOOGLE_MAPS_API_KEY is not set in the environment."; \
	  exit 1; \
	fi
	flutter      build web --base-href=/$*/ \
				    --dart-define=STAGESS_USE_DEV_DB=$(USE_DEV_DB) \
				    --dart-define=STAGESS_GOOGLE_MAPS_API_KEY=$${STAGESS_GOOGLE_MAPS_API_KEY}
	$(MoveDir)   $(OUT_DIR)/web $(OUT_DIR)/$*
	$(ChangeDir) $(OUT_DIR) && $(ZIP) $*.zip $*

# Named targets
main: USE_DEV_DB=false
main: build/admin.zip

tutorial: USE_DEV_DB=true
tutorial: build/tutoriel-admin.zip
