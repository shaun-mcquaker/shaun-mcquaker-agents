TARGET   := wasm32-wasip1
WASM_OUT := target/$(TARGET)/release/tab-titler.wasm
INSTALL  := tab-titler.wasm

.PHONY: build install clean check

## Build, strip, and install in one step
install: build
	wasm-tools strip $(WASM_OUT) -o $(INSTALL)
	@ls -lh $(INSTALL)
	@echo "Done. Restart your Zellij session to pick up the new binary."

## Compile the plugin (release, optimised for size)
build:
	cargo build --release --target $(TARGET)

## Verify exports look sane (quick sanity check)
check: install
	@echo "--- Exports ---"
	@wasm-tools dump $(INSTALL) | grep 'export Export'
	@echo ""
	@echo "--- Imports ---"
	@wasm-tools dump $(INSTALL) | grep 'import \[' | head -10

## Remove build artefacts (keeps installed .wasm)
clean:
	cargo clean
