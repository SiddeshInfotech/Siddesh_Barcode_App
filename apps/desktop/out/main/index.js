"use strict";
const node_path = require("node:path");
const electron = require("electron");
const path = require("path");
const node_fs = require("node:fs");
const promises = require("node:fs/promises");
const icon = path.join(__dirname, "../../resources/icon.png");
function pathFor(key) {
  const safeKey = key.replace(/[^a-zA-Z0-9._-]/g, "_");
  return node_path.join(electron.app.getPath("userData"), "secure", `${safeKey}.dat`);
}
async function getSecure(key) {
  const file = pathFor(key);
  if (!node_fs.existsSync(file)) return null;
  try {
    const encrypted = await promises.readFile(file);
    if (!electron.safeStorage.isEncryptionAvailable()) return null;
    return electron.safeStorage.decryptString(encrypted);
  } catch {
    return null;
  }
}
async function setSecure(key, value) {
  if (!electron.safeStorage.isEncryptionAvailable()) {
    throw new Error("OS encryption unavailable; refusing to store the session in plaintext");
  }
  const file = pathFor(key);
  await promises.mkdir(node_path.dirname(file), { recursive: true });
  await promises.writeFile(file, electron.safeStorage.encryptString(value));
}
async function removeSecure(key) {
  const file = pathFor(key);
  if (!node_fs.existsSync(file)) return;
  try {
    await promises.unlink(file);
  } catch {
  }
}
const IPC = {
  secureGet: "secure-store:get",
  secureSet: "secure-store:set",
  secureRemove: "secure-store:remove",
  setTitleBarTheme: "window:set-title-bar-theme"
};
const TITLE_BAR_HEIGHT = 48;
const DEFAULT_TITLE_BAR = { color: "#09090b", symbolColor: "#e5e1e4" };
function isHexColor(value) {
  return typeof value === "string" && /^#[0-9a-fA-F]{6}$/.test(value);
}
function registerIpcHandlers() {
  electron.ipcMain.handle(IPC.secureGet, (_event, key) => getSecure(key));
  electron.ipcMain.handle(IPC.secureSet, (_event, key, value) => setSecure(key, value));
  electron.ipcMain.handle(IPC.secureRemove, (_event, key) => removeSecure(key));
  electron.ipcMain.handle(
    IPC.setTitleBarTheme,
    (event, theme) => {
      if (!isHexColor(theme?.color) || !isHexColor(theme?.symbolColor)) {
        throw new Error("setTitleBarTheme expects { color, symbolColor } as #rrggbb");
      }
      const win = electron.BrowserWindow.fromWebContents(event.sender);
      if (!win || process.platform !== "win32") return;
      win.setTitleBarOverlay({
        color: theme.color,
        symbolColor: theme.symbolColor,
        height: TITLE_BAR_HEIGHT
      });
    }
  );
}
function createWindow() {
  const win = new electron.BrowserWindow({
    width: 1440,
    height: 900,
    minWidth: 1100,
    // below this the 208px sidebar + a data table stop fitting
    minHeight: 700,
    show: false,
    // revealed on ready-to-show to avoid a white flash
    autoHideMenuBar: true,
    backgroundColor: DEFAULT_TITLE_BAR.color,
    // prevents a white flash before first paint
    icon,
    // Hides the OS title bar (its icon, "Siddesh ERP" text, and its own grey background)
    // while KEEPING the native minimise/maximise/close buttons, drawn over our own
    // background colour. The alternative — frame:false — would mean reimplementing those
    // three buttons, and hand-rolled ones never behave quite like the real Windows
    // controls (snap layouts on maximise hover, double-click-to-restore, accessibility).
    ...process.platform === "win32" ? {
      titleBarStyle: "hidden",
      titleBarOverlay: { ...DEFAULT_TITLE_BAR, height: TITLE_BAR_HEIGHT }
    } : {},
    webPreferences: {
      preload: node_path.join(__dirname, "../preload/index.js"),
      // Both are load-bearing security settings, not defaults to tweak away.
      // The renderer ships to three offices; it gets no direct Node access.
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false
    }
  });
  win.on("ready-to-show", () => {
    win.show();
    win.maximize();
  });
  win.webContents.setWindowOpenHandler(({ url }) => {
    electron.shell.openExternal(url);
    return { action: "deny" };
  });
  win.webContents.on("will-navigate", (event, url) => {
    const isDevServer = process.env.ELECTRON_RENDERER_URL ? url.startsWith(process.env.ELECTRON_RENDERER_URL) : false;
    if (!isDevServer && !url.startsWith("file://")) {
      event.preventDefault();
      electron.shell.openExternal(url);
    }
  });
  if (process.env.ELECTRON_RENDERER_URL) {
    win.loadURL(process.env.ELECTRON_RENDERER_URL);
  } else {
    win.loadFile(node_path.join(__dirname, "../renderer/index.html"));
  }
}
electron.app.whenReady().then(() => {
  registerIpcHandlers();
  createWindow();
  electron.app.on("activate", () => {
    if (electron.BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});
electron.app.on("window-all-closed", () => {
  if (process.platform !== "darwin") electron.app.quit();
});
