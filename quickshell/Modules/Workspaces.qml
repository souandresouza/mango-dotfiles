import QtQuick
import qs.Common
import qs.Widgets

Item {
	id: workspaces

	required property var screen

	readonly property int count: Mango.tagCount(screen)
	readonly property var tags: Mango.tagsForScreen(screen)

	height: Theme.contentHeight
	implicitWidth: row.implicitWidth
	visible: count > 0

	Row {
		id: row
		spacing: 4
		anchors.verticalCenter: parent.verticalCenter

		Repeater {
			model: workspaces.count

			delegate: ModuleButton {
				readonly property var tag: workspaces.tags[index]

				width: 26
				height: Theme.contentHeight
				active: tag ? tag.is_active : false
				urgent: tag ? tag.is_urgent : false
				dim: tag ? tag.client_count === 0 : false
				accentColor: Theme.accent

				IconText {
					text: String(index + 1)
					textColor: parent.active ? Theme.accent
						: parent.urgent ? Theme.danger
						: Theme.fg
				}

				onClicked: Mango.dispatch(index + 1)
			}
		}
	}
}