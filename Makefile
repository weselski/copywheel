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
	cp Resources/AppIcon.icns $(BUNDLE)/Contents/Resources/
	codesign --force -s - $(BUNDLE)
	@echo "→ $(BUNDLE)"

dmg: bundle
	rm -rf $(DIST)/dmg-staging $(DIST)/$(APP).dmg
	mkdir -p $(DIST)/dmg-staging
	cp -R $(BUNDLE) $(DIST)/dmg-staging/
	create-dmg \
		--volname "$(APP)" \
		--volicon Resources/AppIcon.icns \
		--background Resources/dmg-background.png \
		--window-pos 200 150 \
		--window-size 600 400 \
		--icon-size 128 \
		--icon "$(APP).app" 150 185 \
		--hide-extension "$(APP).app" \
		--app-drop-link 450 185 \
		--no-internet-enable \
		$(DIST)/$(APP).dmg $(DIST)/dmg-staging
	rm -rf $(DIST)/dmg-staging
	@echo "→ $(DIST)/$(APP).dmg"

run: bundle
	open $(BUNDLE)

clean:
	rm -rf .build $(DIST)
