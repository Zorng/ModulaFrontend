(function registerThermalPrinterBridge() {
  const state = {
    port: null,
    printerLabel: null,
    connectedAtMs: 0,
  };

  function ok(extra) {
    return JSON.stringify(Object.assign({ success: true }, extra || {}));
  }

  function fail(errorCode, errorMessage) {
    return JSON.stringify({
      success: false,
      errorCode,
      errorMessage,
    });
  }

  function formatError(error, fallbackCode) {
    const code =
      error && typeof error.name === 'string' && error.name.trim()
        ? error.name.trim()
        : fallbackCode;
    const message =
      error && typeof error.message === 'string' && error.message.trim()
        ? error.message.trim()
        : String(error);
    return { code, message };
  }

  function sleep(durationMs) {
    return new Promise((resolve) => {
      setTimeout(resolve, durationMs);
    });
  }

  function isSupported() {
    return typeof navigator !== 'undefined' && !!navigator.serial;
  }

  function printerLabelFor(port) {
    const info = typeof port.getInfo === 'function' ? port.getInfo() : {};
    const vendorId = info && info.usbVendorId ? info.usbVendorId : 'unknown';
    const productId = info && info.usbProductId ? info.usbProductId : 'unknown';
    return `BT-583 (${vendorId}:${productId})`;
  }

  async function ensureClosed() {
    if (!state.port) return;
    try {
      if (state.port.writable && state.port.writable.locked) {
        return;
      }
      await state.port.close();
    } catch (_) {
      // Ignore best-effort close errors.
    } finally {
      state.port = null;
    }
  }

  async function connect(baudRateRaw) {
    if (!isSupported()) {
      return fail(
        'UNSUPPORTED_BROWSER',
        'Web Serial is not supported in this browser.',
      );
    }

    try {
      const baudRate = Number.isFinite(Number(baudRateRaw))
        ? Number(baudRateRaw)
        : 9600;
      const port = await navigator.serial.requestPort();
      await port.open({
        baudRate,
        dataBits: 8,
        stopBits: 1,
        parity: 'none',
        flowControl: 'none',
      });
      if (typeof port.setSignals === 'function') {
        try {
          await port.setSignals({
            dataTerminalReady: true,
            requestToSend: true,
          });
        } catch (_) {
          // Some ports do not expose or require signal toggles.
        }
      }
      await sleep(150);
      state.port = port;
      state.printerLabel = printerLabelFor(port);
      state.connectedAtMs = Date.now();
      return ok({ printerLabel: state.printerLabel });
    } catch (error) {
      const formatted = formatError(error, 'CONNECT_FAILED');
      return fail(formatted.code, formatted.message);
    }
  }

  async function disconnect() {
    try {
      await ensureClosed();
      state.printerLabel = null;
      state.connectedAtMs = 0;
      return ok();
    } catch (error) {
      const formatted = formatError(error, 'DISCONNECT_FAILED');
      return fail(formatted.code, formatted.message);
    }
  }

  async function writeBase64(base64Payload) {
    if (!state.port || !state.port.writable) {
      return fail('PORT_NOT_CONNECTED', 'Printer is not connected.');
    }

    let writer;
    try {
      if (Date.now() - state.connectedAtMs < 150) {
        await sleep(150);
      }
      const binary = atob(base64Payload || '');
      const bytes = new Uint8Array(binary.length);
      for (let i = 0; i < binary.length; i += 1) {
        bytes[i] = binary.charCodeAt(i);
      }
      writer = state.port.writable.getWriter();
      if (writer.ready) {
        await writer.ready;
      }
      await writer.write(bytes);
      await sleep(50);
      return ok({ printerLabel: state.printerLabel });
    } catch (error) {
      const formatted = formatError(error, 'WRITE_FAILED');
      return fail(formatted.code, formatted.message);
    } finally {
      if (writer) {
        writer.releaseLock();
      }
    }
  }

  window.modulaThermalPrinterBridge = {
    isSupported,
    connect,
    disconnect,
    writeBase64,
  };
})();
