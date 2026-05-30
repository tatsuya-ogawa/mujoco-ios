
MUJOCO_REPO ?= https://github.com/google-deepmind/mujoco.git
MUJOCO_DIR  ?= mujoco
MUJOCO_REF  ?= 7667e7110e8cc56135080624d0cac021edcb1ae7

.PHONY: help download clone patch unpatch build xcframework typecheck package-release clean distclean

help:
	@printf '%s\n' \
	  'Targets:' \
	  '  make download   Clone MuJoCo and checkout MUJOCO_REF' \
	  '  make build      Build output/mujoco.xcframework' \
	  '  make typecheck  Typecheck the Swift wrapper and iOS example' \
	  '  make package-release  Zip output/mujoco.xcframework and compute checksum' \
	  '  make clean      Remove local build output' \
	  '' \
	  'Variables:' \
	  '  MUJOCO_REPO=$(MUJOCO_REPO)' \
	  '  MUJOCO_REF=$(MUJOCO_REF)'

download clone:
	@if [ ! -d "$(MUJOCO_DIR)/.git" ]; then \
	  git clone $(MUJOCO_REPO) $(MUJOCO_DIR); \
	else \
	  echo "$(MUJOCO_DIR) already present"; \
	fi
	git -C $(MUJOCO_DIR) fetch --tags origin
	git -C $(MUJOCO_DIR) checkout --detach $(MUJOCO_REF)

# Reset upstream tree and apply iOS patches (idempotent).
patch:
	git -C $(MUJOCO_DIR) checkout -- .
	git -C $(MUJOCO_DIR) clean -fd
	git -C $(MUJOCO_DIR) apply --whitespace=nowarn ../scripts/ios-patches.diff

unpatch:
	git -C $(MUJOCO_DIR) checkout -- .
	git -C $(MUJOCO_DIR) clean -fd

# Full build: configures, builds static slices and creates output/mujoco.xcframework
build xcframework:
	MUJOCO_REF=$(MUJOCO_REF) bash scripts/build_xcframework.sh

typecheck:
	bash scripts/typecheck_ios_example.sh

package-release:
	bash scripts/package_release_artifacts.sh

clean:
	rm -rf build output

distclean: clean
	-git -C $(MUJOCO_DIR) checkout -- . 2>/dev/null || true
	-git -C $(MUJOCO_DIR) clean -fd 2>/dev/null || true
