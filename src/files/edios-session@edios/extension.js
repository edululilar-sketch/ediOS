// ediOS Sitzung (GPL-3.0-or-later)
//
// Warum es das gibt: Alpine kombiniert gnome-session 48 (laeuft ohne systemd) mit gnome-shell 50.
// Damit gnome-session 48 die Shell als gestartet erkennt, meldet sich Alpines gnome-shell per
// RegisterClient("org.gnome.Shell.desktop") an (Alpine-Patch revert-gnome-session-49.patch). Auf die
// Fragen QueryEndSession und EndSession antwortet gnome-shell 50 aber nicht mehr. Folge: Beim Ausschalten
// zeigt GNOME "GNOME Shell - Keine Antwort", wartet 60 Sekunden und haelt danach noch 5 s die logind-Sperre.
//
// Diese Erweiterung antwortet fuer genau diesen einen Client (App-ID org.gnome.Shell.desktop, eigene
// Prozess-ID) sofort mit "bereit". gnome-session sendet die Signale als Rundsignal an alle; Antworten
// fuer fremde Clients wuerden die Abfrage zu frueh beenden, deshalb wird der Client vorher geprueft.
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

const SM = 'org.gnome.SessionManager';
const IFACE_PRIVATE = 'org.gnome.SessionManager.ClientPrivate';
const IFACE_CLIENT = 'org.gnome.SessionManager.Client';
const SHELL_APP_ID = 'org.gnome.Shell.desktop';

export default class EdiosSessionExtension extends Extension {
    enable() {
        this._bus = Gio.DBus.session;
        this._pid = new Gio.Credentials().get_unix_pid();
        this._own = null;       // Objektpfad des eigenen Clients, sobald bekannt
        this._foreign = new Set();
        this._sub = this._bus.signal_subscribe(SM, IFACE_PRIVATE, null, null, null,
            Gio.DBusSignalFlags.NONE, (_c, _sender, path, _iface, signal) => {
                if (signal === 'QueryEndSession' || signal === 'EndSession')
                    this._maybeRespond(path).catch(e => console.warn(`ediOS Sitzung: ${e.message}`));
            });
    }

    async _isOwnClient(path) {
        if (path === this._own)
            return true;
        if (this._foreign.has(path))
            return false;
        const appId = await this._call(path, IFACE_CLIENT, 'GetAppId', null);
        let own = false;
        if (appId === SHELL_APP_ID)
            own = await this._call(path, IFACE_CLIENT, 'GetUnixProcessId', null) === this._pid;
        if (own)
            this._own = path;
        else
            this._foreign.add(path);
        return own;
    }

    async _maybeRespond(path) {
        if (await this._isOwnClient(path))
            await this._call(path, IFACE_PRIVATE, 'EndSessionResponse', new GLib.Variant('(bs)', [true, '']));
    }

    _call(path, iface, method, params) {
        return new Promise((resolve, reject) => {
            this._bus.call(SM, path, iface, method, params, null, Gio.DBusCallFlags.NONE, 2000, null,
                (conn, res) => {
                    try {
                        const r = conn.call_finish(res);
                        resolve(r.n_children() > 0 ? r.get_child_value(0).recursiveUnpack() : null);
                    } catch (e) {
                        reject(e);
                    }
                });
        });
    }

    disable() {
        if (this._sub)
            this._bus.signal_unsubscribe(this._sub);
        this._sub = 0;
        this._own = null;
        this._foreign = null;
    }
}
