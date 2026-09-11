pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common

Singleton {
	id: network

	property int state: 0
	property string ssid: ""
	property int signal: 0
	property bool wifiEnabled: false

	Timer {
		id: pollTimer
		interval: 5000
		repeat: true
		running: true
		triggeredOnStart: true
		onTriggered: networkProcess.exec([Theme.binDir + "/network.sh"])
	}

	Process {
		id: networkProcess

		running: false
		stdout: StdioCollector {
			id: coll
			waitForEnd: true
		}

		onExited: () => {
			const line = coll.text.toString().trim();
			if (line.length === 0)
				return;
			try {
				const j = JSON.parse(line);
				network.state = j.state === "wifi" ? 1 : j.state === "ethernet" ? 2 : 0;
				network.ssid = j.ssid || "";
				network.signal = Number(j.signal) || 0;
				network.wifiEnabled = j.wifi_enabled === "yes";
			} catch (e) { console.warn("[rede] falha ao parsear output:", e.message); }
		}
	}

	function toggleWifi() {
		Quickshell.execDetached(["nmcli", "radio", "wifi", wifiEnabled ? "off" : "on"]);
		pollTimer.restart();
	}
}