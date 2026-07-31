"use strict";
const electron = require("electron");
const api = {
  platform: process.platform,
  /** OS-encrypted storage for the auth session. Backed by Electron `safeStorage`. */
  secureStore: {
    get: (key) => electron.ipcRenderer.invoke("secure-store:get", key),
    set: (key, value) => electron.ipcRenderer.invoke("secure-store:set", key, value),
    remove: (key) => electron.ipcRenderer.invoke("secure-store:remove", key)
  },
  /**
   * Recolours the native window buttons to match the app theme.
   * Windows draws them itself, so they cannot read our CSS variables.
   */
  setTitleBarTheme: (theme) => electron.ipcRenderer.invoke("window:set-title-bar-theme", theme)
};
electron.contextBridge.exposeInMainWorld("api", api);
