import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.Common
import qs.Widgets

Item {
	id: root

	readonly property var items: SystemTray.items.values.filter(item => {
			const icon = item && item.icon;
			const name = item && item.id;
			return (typeof icon === "string" && icon.length > 0) || (name && name.length > 0);
		})

	height: Theme.contentHeight
	implicitWidth: row.implicitWidth

	Row {
		id: row
		spacing: 2
		anchors.verticalCenter: parent.verticalCenter

		Repeater {
			model: root.items

			delegate: ModuleButton {
				required property var modelData

				width: 26
				height: Theme.contentHeight
				framed: false
				padding: 4

				IconImage {
					source: Quickshell.iconPath(modelData.icon)
					width: 18
					height: 18
					asynchronous: true
					smooth: true
					mipmap: true
				}

				onClicked: modelData.activate()
				onRightClicked: modelData.secondaryActivate()
			}
		}
	}
}