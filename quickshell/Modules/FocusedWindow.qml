import QtQuick
import qs.Common
import qs.Widgets

ModuleButton {
	id: root

	required property var screen

	readonly property var focused: Mango.focusedForScreen(screen)
	readonly property string title: focused && focused.title ? focused.title : ""
	readonly property string appId: focused && focused.appid ? focused.appid : ""

	height: Theme.contentHeight
	visible: title.length > 0

	IconText {
		glyph: "\uf2d2"
		glyphColor: Theme.accent
		text: root.title
		textColor: Theme.fg
		maxTextWidth: 220
	}
}