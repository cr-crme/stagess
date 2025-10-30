.PHONY: main tutorial

OUT_DIR := build
ZIP := zip -r

all: main tutorial

# Generic rule: build/NAME.zip with USE_DEV_DB flag
.FORCE:
build/%.zip: .FORCE
	rm -rf $(OUT_DIR)/$*
	flutter build web --base-href=/$*/ \
		--dart-define=STAGESS_USE_DEV_DB=$(USE_DEV_DB)
	mv $(OUT_DIR)/web $(OUT_DIR)/$*
	cd $(OUT_DIR) && $(ZIP) $*.zip $*

# Named targets
main: USE_DEV_DB=false
main: build/admin.zip

tutorial: USE_DEV_DB=true
tutorial: build/tutoriel-admin.zip
