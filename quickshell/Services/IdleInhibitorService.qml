pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._IdleInhibitor

Singleton {
	id: inhibitor

	property bool active: false

	Window {
		id: inhibitionWindow
		visible: inhibitor.active
		width: 1
		height: 1
		x: -40
		y: -40
		opacity: 0
		color: "transparent"
	}

	IdleInhibitor {
		id: inhibition
		window: inhibitionWindow
		enabled: inhibitor.active
	}

	function enable() {
		inhibitor.active = true;
	}

	function disable() {
		inhibitor.active = false;
	}

	function toggle() {
		if (inhibitor.active)
			inhibitor.disable();
		else
			inhibitor.enable();
	}
}