/*
  qBittorrent / tema pywal
  Gerado por ~/.local/bin/qbittorrent-colors.sh a partir da paleta pywal.
  TEMPLATE: edite aqui; o stylesheet.qss ao lado e reescrito a cada troca
  de wallpaper. Nao edite o stylesheet.qss diretamente.
*/

/*
  qBittorrent / Black Theme
  @author Eray Chumak
*/

QWidget {
  background: {{base16.base00.default.hex}};
  color: {{colors.on_surface.default.hex}};
  border: none;
}

/*
  QMenuBar
*/

QMenuBar {
  background: {{base16.base00.default.hex}};
}

QMenuBar::item {
  padding: 5px 10px;
  width: 100%;
  color: {{colors.on_surface.default.hex}};
}

QMenuBar::item:selected {
  background: {{colors.surface_container_low.default.hex}};
}

QMenuBar::item:pressed {
  background: {{colors.surface_container.default.hex}};
}

/*
  QMenu
*/

QMenu {
  background: {{base16.base00.default.hex}};
  border: 1px solid {{colors.surface_container.default.hex}};
  left: 50px;
}

QMenu::item {
  margin: 0;
  padding: 5px 10px 5px 5px;
  background: {{base16.base00.default.hex}};
  color: {{colors.on_surface.default.hex}};
}

QMenu::item:selected {
  background: {{colors.surface_container_low.default.hex}};
}

QMenu::separator {
  background: {{colors.surface_container.default.hex}};
  height: 1px;
}

QMenu::icon {
  padding: 0 5px;
}

QMenu::indicator {
  padding: 0 5px;
}

QMenu::indicator:checked {
  backgr
}



/*
  QToolBar
*/

QToolBar {
  background: {{base16.base00.default.hex}};
  border-top: 1px solid {{colors.surface_container.default.hex}};
  border-bottom: 1px solid {{colors.surface_container.default.hex}};
}

QToolBar::separator {
  background: {{colors.surface_container.default.hex}};
  width: 1px;
}

/*
  QToolButton
*/

QToolButton {
  padding: 5px;
  border: none;
  background: {{base16.base00.default.hex}};
}

QToolButton:hover {
  background: {{colors.surface_container_low.default.hex}};
  border: none;
}

QToolButton:pressed {
  background: {{colors.surface_container.default.hex}};
  padding: 0;
}

/*
  QLineEdit in QToolBar
*/

QToolBar QLineEdit {
  background: {{base16.base00.default.hex}};
  margin: 0 5px;
}

/*
  QSplitter
*/

QSplitter::handle {
  background: {{colors.surface_container_low.default.hex}};
}

QSplitter::handle:horizontal {
  width: 1px;
}

QSplitter::handle:vertical {
  height: 1px;
}

QSplitter::handle:pressed {
  background: {{colors.surface_container.default.hex}};
}

/*
  QMainWindow
*/

QMainWindow {
  background: {{base16.base00.default.hex}};
}

/*
  QFrame
*/

QFrame, QLabel {
  outline: none;
  background: {{base16.base00.default.hex}};
  color: {{colors.on_surface.default.hex}};
}

QLabel:disabled {
  color: {{colors.on_surface_variant.default.hex}};
}

/*
  QToolTip
*/

QToolTip {
  padding: 5px;
  background: {{base16.base00.default.hex}};
  border: 2px solid {{colors.surface_container.default.hex}};
  color: {{colors.on_surface.default.hex}};
}

/*
  QTabWidget
*/

QTabWidget::pane {
  margin: 0;
  padding: 0;
}

/*
  QTABBAR
  top
*/

QTabBar::tab:top {
  background: {{colors.surface_container_low.default.hex}};
  color: {{colors.on_surface.default.hex}};
  margin: 0;
  padding: 5px;
}

QTabBar::tab:top:hover {
  background: {{colors.surface_container.default.hex}};
}

QTabBar::tab:top:selected {
  background: {{colors.surface_container.default.hex}};
}

/*
  QListView
*/
QListView {
  background: {{base16.base00.default.hex}};
  color: {{colors.on_surface.default.hex}};
  border: none;
}

QListView::item {
  padding: 5px;
}

QListView::item:hover {
  background: {{colors.surface_container_low.default.hex}};
  padding: 0px;
}

QListView::item:selected:active {
  outline: none;
  background: {{colors.surface_container_low.default.hex}};
  padding: 0px;
}

QListView::item:selected:!active {
  background: {{colors.surface_container_low.default.hex}};
  color: {{colors.on_surface.default.hex}};
  padding: 0px;
}

/*
  QTableView
*/

QTableView {
  background: {{colors.surface_container.default.hex}};
  border: none;
}

QTableView QLabel {
  padding: 0 5px;
}

QTableView QCheckBox {
  padding-left: 5px;
}

/*
  QTreeView
*/

QTreeView {
  background: {{base16.base00.default.hex}};
  color: {{colors.on_surface.default.hex}};
  border: none;
}

QTreeView::item {
  padding: 5px;
}

QTreeView::item:hover {
  background: {{colors.surface_container_low.default.hex}};
  padding: 0px;
}

QTreeView::item:pressed {
  background: {{colors.surface_container.default.hex}};
  padding: 0px;
}

QTreeView::item:selected {
  background: {{colors.surface_container_low.default.hex}};
  color: {{colors.on_surface.default.hex}};
  padding: 0px;
}

QTreeView:disabled {
  color: {{colors.on_surface_variant.default.hex}};
}

QAbstractItemView {
  alternate-background-color: {{base16.base00.default.hex}};
}

/*
  QProgrssBar
*/

QProgressBar {
  text-align: center;
  border: 1px solid {{colors.surface_container_low.default.hex}};
}

QProgressBar::chunk {
  background: {{colors.primary.default.hex}};
}

QProgressBar::chunk:disabled {
  background: {{colors.tertiary.default.hex}};
}

/*
  QScrollBar / horizontal
*/

QScrollBar:horizontal {
  background: {{colors.surface_container_low.default.hex}};
  margin: 0px 20px;
}

QScrollBar::handle:horizontal {
  background: {{colors.surface_container_high.default.hex}};
  width: 20px;
}

QScrollBar::add-line:horizontal,
QScrollBar::sub-line:horizontal
{
  background: {{colors.surface_container_low.default.hex}};
  width: 20px;
  subcontrol-origin: margin;
}

QScrollBar::add-line:horizontal {
  subcontrol-position: right;
}

QScrollBar::sub-line:horizontal {
  subcontrol-position: left;
}

QScrollBar:left-arrow:horizontal,
QScrollBar::right-arrow:horizontal
{
  width: 5px;
  height: 5px;
  background: {{colors.on_surface.default.hex}};
}

QScrollBar::add-page:horizontal,
QScrollBar::sub-page:horizontal
{
  background: none;
}

/*
  QScrollBar / vertical
*/

QScrollBar:vertical {
  background: {{colors.surface_container_low.default.hex}};
  margin: 20px 0;
}

QScrollBar::handle:vertical {
  background: {{colors.surface_container.default.hex}};
  height: 20px;
}

QScrollBar::add-line:vertical,
QScrollBar::sub-line:vertical
{
  background: {{colors.surface_container_low.default.hex}};
  height: 20px;
  subcontrol-origin: margin;
}

QScrollBar::add-line:vertical {
  subcontrol-position: bottom;
}

QScrollBar::sub-line:vertical {
  subcontrol-position: top;
}

QScrollBar::up-

QScrollBar::down-

QScrollBar::add-page:vertical,
QScrollBar::sub-page:vertical
{
  background: none;
}

/*
  QPushButton
*/

QPushButton,
QPushButton:enabled
{
  padding: 5px 10px;
  background: {{colors.surface_container_low.default.hex}};
  color: {{colors.on_surface.default.hex}};
}

QPushButton:hover {
  background: {{colors.surface_container.default.hex}};
}

QPushButton:focus {
  outline: none;
  background: {{colors.surface_container.default.hex}};
}

QPushButton:pressed {
  padding: 5px 10px;
  border: none;
  background: {{colors.surface_container_high.default.hex}};
}

QPushButton:disabled {
  color: {{colors.on_surface_variant.default.hex}};
}

/*
  QLineEdit
*/

QLineEdit,
QLineEdit:read-only
{
  background: {{colors.surface_container_low.default.hex}};
  color: {{colors.on_surface.default.hex}};
  border: none;
  padding: 4px;
}

QLineEdit:disabled,
QLineEdit:disabled:read-only
{
  color: {{colors.on_surface_variant.default.hex}};
}

/*
  QHeaderView
*/

QHeaderView::section {
  background: {{base16.base00.default.hex}};
  padding: 0 5px;
  color: {{colors.on_surface.default.hex}};
}

QHeaderView::section:hover {
  background: {{colors.surface_container_low.default.hex}};
}

QHeaderView::down-arrow {
  height: 12px;
  margin: 5px;
  width: 12px;
}

QHeaderView::up-arrow {
  height: 12px;
  margin: 5px;
  width: 12px;
}

/*
  QDialog
*/

QDialog {
  background: {{base16.base00.default.hex}};
}

/*
  QCheckbox
*/

QCheckBox:disabled {
  color: {{colors.on_surface_variant.default.hex}};
}

/*
  QComboBox
*/

QComboBox {
  background: {{colors.surface_container_low.default.hex}};
  color: {{colors.on_surface.default.hex}};
  padding: 4px;
}

QComboBox:focus {
  background: {{colors.surface_container.default.hex}};
}

QComboBox:disabled {
  color: {{colors.on_surface_variant.default.hex}};
}

QComboBox:on {
  background: {{colors.surface_container.default.hex}};
}

QComboBox QAbstractItemView {
  background: {{colors.surface_container_low.default.hex}};
  selection-background-color: {{colors.surface_container.default.hex}};
  selection-color: {{colors.on_surface.default.hex}};
  outline: none;
}

QComboBox::drop-down {
  subcontrol-origin: margin;
  subcontrol-position: top right;
  width: 6ex;
  background: {{colors.surface_container_low.default.hex}};
}

QComboBox::down-

QComboBox::down-

/*
  QSpinBox
*/

QSpinBox {
  background: {{colors.surface_container_low.default.hex}};
  color: {{colors.on_surface.default.hex}};
  border: none;
  padding: 4px;
}

QSpinBox:disabled {
  color: {{colors.on_surface_variant.default.hex}};
}

QSpinBox:focus {
  background: {{colors.surface_container.default.hex}};
}

/*
  QGroupBox
*/

QGroupBox {
  background: {{base16.base00.default.hex}};
  border: 2px solid {{colors.surface_container_highest.default.hex}};
  padding: 5px;
  margin-top: 15px;
  border-radius: 5px;
}

QGroupBox::title {
  subcontrol-origin: margin;
  subcontrol-position: top left;
  left: 10px;
  padding: 8px 5px 20px 5px;
}

QGroupBox QLabel {
  color: {{colors.on_surface_variant.default.hex}};
}

QGroupBox QCheckBox {
  color: {{colors.on_surface_variant.default.hex}};
}

QGroupBox::title:disabled {
  color: {{colors.on_surface_variant.default.hex}};
}

TransferListWidget {
  qproperty-downloadingStateForeground: {{colors.primary.default.hex}};
  qproperty-forcedDownloadingStateForeground: {{colors.primary.default.hex}};
  qproperty-downloadingMetadataStateForeground: {{colors.primary.default.hex}};
  qproperty-allocatingStateForeground: {{colors.on_surface_variant.default.hex}};
  qproperty-stalledDownloadingStateForeground: {{colors.tertiary.default.hex}};
  qproperty-stalledUploadingStateForeground: {{colors.tertiary.default.hex}};
  qproperty-uploadingStateForeground: {{colors.secondary.default.hex}};
  qproperty-forcedUploadingStateForeground: {{colors.secondary.default.hex}};
  qproperty-pausedDownloadingStateForeground: {{colors.secondary_container.default.hex}};
  qproperty-pausedUploadingStateForeground: {{colors.secondary_container.default.hex}};
  qproperty-errorStateForeground: {{colors.error.default.hex}};
  qproperty-missingFilesStateForeground: {{colors.error.default.hex}};
  qproperty-queuedDownloadingStateForeground: {{colors.secondary_container.default.hex}};
  qproperty-queuedUploadingStateForeground: {{colors.secondary_container.default.hex}};
  qproperty-checkingDownloadingStateForeground: {{colors.secondary_container.default.hex}};
  qproperty-checkingUploadingStateForeground: {{colors.secondary_container.default.hex}};
  qproperty-checkingResumeDataStateForeground: {{colors.secondary_container.default.hex}};
  qproperty-movingStateForeground: {{colors.secondary_container.default.hex}};
  qproperty-unknownStateForeground: {{colors.error.default.hex}};
}
