APP     = CopyWheel
DIST    = dist
BUNDLE  = $(DIST)/$(APP).app

.PHONY: build bundle run clean

build:
	swift build -c release

bundle: build
	rm -rf $(BUNDLE)
	mkdir -p $(BUNDLE)/Contents/MacOS $(BUNDLE)/Contents/Resources
	cp .build/release/$(APP) $(BUNDLE)/Contents/MacOS/$(APP)
	cp Resources/Info.plist $(BUNDLE)/Contents/Info.plist
	codesign --force -s - $(BUNDLE)
	@echo "→ $(BUNDLE)"

run: bundle
	open $(BUNDLE)

clean:
	rm -rf .build $(DIST)
