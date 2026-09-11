import QtQuick
import qs.Common

Item {
	id: root

	required property var screen

	readonly property var focused: Mango.focusedForScreen(screen)
	readonly property string title: focused && focused.title ? focused.title : ""
	readonly property string appId: focused && focused.appid ? focused.appid : ""

	implicitWidth: Math.min(titleLabel.implicitWidth, 260)
	height: Theme.contentHeight
	visible: title.length > 0

	Text {
		id: titleLabel
		text: root.title
		font.family: Theme.fontFamily
		font.pixelSize: Theme.fontSize
		verticalAlignment: Text.AlignVCenter
		anchors.verticalCenter: parent.verticalCenter
		color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.9)
		elide: Text.ElideRight
		maximumLineCount: 1
		width: Math.min(implicitWidth, 260)
		clip: true
	}
}