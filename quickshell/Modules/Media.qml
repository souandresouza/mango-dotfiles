import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets

ModuleButton {
	id: root

	property var popup: null

	property var players: []

	readonly property var player: {
		for (let i = 0; i < players.length; i++) {
			if (players[i].status === "Playing")
				return players[i];
		}
		return players.length ? players[0] : null;
	}

	readonly property bool playing: player !== null && player.status === "Playing"
	readonly property string title: player ? (player.title || "") : ""
	readonly property string artist: player ? (player.artist || "") : ""

	visible: playing

	function send(id, cmd) {
		Quickshell.execDetached([Theme.binDir + "/mpris.py", "--action", id, cmd]);
	}

	Timer {
		interval: 1000
		repeat: true
		running: true
		triggeredOnStart: true
		onTriggered: mprisProcess.exec([Theme.binDir + "/mpris.py"])
	}

	Process {
		id: mprisProcess

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
				if (Array.isArray(j))
					root.players = j;
			} catch (e) { /* ignore */ }
		}
	}

	IconText {
		glyph: "\uf001"
		text: {
			if (!root.title)
				return "";
			const artistPart = root.artist ? " - " + root.artist : "";
			return root.title + artistPart;
		}
		glyphColor: root.playing ? Theme.accent : Theme.fg
		textColor: Theme.fg
		maxTextWidth: 180
	}

	onClicked: {
		if (popup)
			popup.toggleFrom(root.frame);
	}
}