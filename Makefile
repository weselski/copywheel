APP     = CopyWheel
DIST    = dist
BUNDLE  = $(DIST)/$(APP).app

.PHONY: build bundle dmg run clean

build:
	swift build -c release

bundle: build
	rm -rf $(BUNDLE)
	mkdir -p $(BUNDLE)/Contents/MacOS $(BUNDLE)/Contents/Resources
	cp .build/release/$(APP) $(BUNDLE)/Contents/MacOS/$(APP)
	cp Resources/Info.plist $(BUNDLE)/Contents/Info.plist
	cp -R .build/release/*.bundle $(BUNDLE)/Contents/Resources/ 2>/dev/null || true
	codesign --force -s - $(BUNDLE)
	@echo "→ $(BUNDLE)"

dmg: bundle
	rm -rf $(DIST)/dmg-staging $(DIST)/$(APP).dmg
	mkdir -p $(DIST)/dmg-staging
	cp -R $(BUNDLE) $(DIST)/dmg-staging/
	ln -s /Applications $(DIST)/dmg-staging/Applications
	hdiutil create -volname $(APP) -srcfolder $(DIST)/dmg-staging -ov -format UDZO $(DIST)/$(APP).dmg
	rm -rf $(DIST)/dmg-staging
	@echo "→ $(DIST)/$(APP).dmg"

run: bundle
	open $(BUNDLE)

clean:
	rm -rf .build $(DIST)
