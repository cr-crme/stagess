.PHONY: main tutorial

include ../utilities/makefile_commands.mk

OUT_DIR := build
ZIP := zip -r

all: main tutorial
maintenance: main_maintenance tutorial_maintenance

# Generic rule: build/NAME.zip with USE_DEV_DB flag
.FORCE:
build/%.zip: .FORCE
	$(call safe_rmdir, $(OUT_DIR)/$*)
	@if [ -z "$${STAGESS_GOOGLE_MAPS_API_KEY}" ]; then \
	  echo "Error: STAGESS_GOOGLE_MAPS_API_KEY is not set in the environment."; \
	  exit 1; \
	fi
	@if [ -z "$${STAGESS_OSM_UNBLOCK_STRING}" ]; then \
	  echo "Error: STAGESS_OSM_UNBLOCK_STRING is not set in the environment."; \
	  exit 1; \
	fi
	flutter      build web --base-href=/$*/ \
					--wasm \
		    	    --dart-define=STAGESS_USE_DEV_DB=$(USE_DEV_DB) \
                	--dart-define=STAGESS_MAINTENANCE_MODE=$(MAINTENANCE_MODE) \
					--dart-define=STAGESS_GOOGLE_MAPS_API_KEY=$${STAGESS_GOOGLE_MAPS_API_KEY} \
					--dart-define=flutter.flutter_map.unblockOSM="$${STAGESS_OSM_UNBLOCK_STRING}"
	$(MoveDir)   $(OUT_DIR)/web $(OUT_DIR)/$*
	$(ChangeDir) $(OUT_DIR) && $(ZIP) $*.zip $*

# Named targets
main: USE_DEV_DB=false
main: MAINTENANCE_MODE=false
main: build/stagess.zip

tutorial: USE_DEV_DB=true
tutorial: MAINTENANCE_MODE=false
tutorial: build/tutoriel.zip

main_maintenance: USE_DEV_DB=false
main_maintenance: MAINTENANCE_MODE=true
main_maintenance: build/stagess.zip

tutorial_maintenance: USE_DEV_DB=true
tutorial_maintenance: MAINTENANCE_MODE=true
tutorial_maintenance: build/tutoriel.zip