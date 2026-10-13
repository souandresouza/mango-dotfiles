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
  background: {{BG}};
  color: {{TEXT}};
  border: none;
}

/*
  QMenuBar
*/

QMenuBar {
  background: {{BG}};
}

QMenuBar::item {
  padding: 5px 10px;
  width: 100%;
  color: {{TEXT}};
}

QMenuBar::item:selected {
  background: {{BG_PANEL}};
}

QMenuBar::item:pressed {
  background: {{BG_PANEL2}};
}

/*
  QMenu
*/

QMenu {
  background: {{BG}};
  border: 1px solid {{BG_PANEL2}};
  left: 50px;
}

QMenu::item {
  margin: 0;
  padding: 5px 10px 5px 5px;
  background: {{BG}};
  color: {{TEXT}};
}

QMenu::item:selected {
  background: {{BG_PANEL}};
}

QMenu::separator {
  background: {{BG_PANEL2}};
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
  background: {{BG}};
  border-top: 1px solid {{BG_PANEL2}};
  border-bottom: 1px solid {{BG_PANEL2}};
}

QToolBar::separator {
  background: {{BG_PANEL2}};
  width: 1px;
}

/*
  QToolButton
*/

QToolButton {
  padding: 5px;
  border: none;
  background: {{BG}};
}

QToolButton:hover {
  background: {{BG_PANEL}};
  border: none;
}

QToolButton:pressed {
  background: {{BG_PANEL2}};
  padding: 0;
}

/*
  QLineEdit in QToolBar
*/

QToolBar QLineEdit {
  background: {{BG}};
  margin: 0 5px;
}

/*
  QSplitter
*/

QSplitter::handle {
  background: {{BG_PANEL}};
}

QSplitter::handle:horizontal {
  width: 1px;
}

QSplitter::handle:vertical {
  height: 1px;
}

QSplitter::handle:pressed {
  background: {{BG_PANEL2}};
}

/*
  QMainWindow
*/

QMainWindow {
  background: {{BG}};
}

/*
  QFrame
*/

QFrame, QLabel {
  outline: none;
  background: {{BG}};
  color: {{TEXT}};
}

QLabel:disabled {
  color: {{TEXT_DIM}};
}

/*
  QToolTip
*/

QToolTip {
  padding: 5px;
  background: {{BG}};
  border: 2px solid {{BG_PANEL2}};
  color: {{TEXT}};
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
  background: {{BG_PANEL}};
  color: {{TEXT}};
  margin: 0;
  padding: 5px;
}

QTabBar::tab:top:hover {
  background: {{BG_PANEL2}};
}

QTabBar::tab:top:selected {
  background: {{BG_PANEL2}};
}

/*
  QListView
*/
QListView {
  background: {{BG}};
  color: {{TEXT}};
  border: none;
}

QListView::item {
  padding: 5px;
}

QListView::item:hover {
  background: {{BG_PANEL}};
  padding: 0px;
}

QListView::item:selected:active {
  outline: none;
  background: {{BG_PANEL}};
  padding: 0px;
}

QListView::item:selected:!active {
  background: {{BG_PANEL}};
  color: {{TEXT}};
  padding: 0px;
}

/*
  QTableView
*/

QTableView {
  background: {{BG_PANEL2}};
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
  background: {{BG}};
  color: {{TEXT}};
  border: none;
}

QTreeView::item {
  padding: 5px;
}

QTreeView::item:hover {
  background: {{BG_PANEL}};
  padding: 0px;
}

QTreeView::item:pressed {
  background: {{BG_PANEL2}};
  padding: 0px;
}

QTreeView::item:selected {
  background: {{BG_PANEL}};
  color: {{TEXT}};
  padding: 0px;
}

QTreeView:disabled {
  color: {{TEXT_DIM}};
}

QAbstractItemView {
  alternate-background-color: {{BG}};
}

/*
  QProgrssBar
*/

QProgressBar {
  text-align: center;
  border: 1px solid {{BG_PANEL}};
}

QProgressBar::chunk {
  background: {{ACCENT}};
}

QProgressBar::chunk:disabled {
  background: {{ACCENT_DIM}};
}

/*
  QScrollBar / horizontal
*/

QScrollBar:horizontal {
  background: {{BG_PANEL}};
  margin: 0px 20px;
}

QScrollBar::handle:horizontal {
  background: {{BG_HANDLE}};
  width: 20px;
}

QScrollBar::add-line:horizontal,
QScrollBar::sub-line:horizontal
{
  background: {{BG_PANEL}};
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
  background: {{TEXT}};
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
  background: {{BG_PANEL}};
  margin: 20px 0;
}

QScrollBar::handle:vertical {
  background: {{BG_PANEL2}};
  height: 20px;
}

QScrollBar::add-line:vertical,
QScrollBar::sub-line:vertical
{
  background: {{BG_PANEL}};
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
  background: {{BG_PANEL}};
  color: {{TEXT}};
}

QPushButton:hover {
  background: {{BG_PANEL2}};
}

QPushButton:focus {
  outline: none;
  background: {{BG_PANEL2}};
}

QPushButton:pressed {
  padding: 5px 10px;
  border: none;
  background: {{BG_HANDLE}};
}

QPushButton:disabled {
  color: {{TEXT_DIM}};
}

/*
  QLineEdit
*/

QLineEdit,
QLineEdit:read-only
{
  background: {{BG_PANEL}};
  color: {{TEXT}};
  border: none;
  padding: 4px;
}

QLineEdit:disabled,
QLineEdit:disabled:read-only
{
  color: {{TEXT_DIM}};
}

/*
  QHeaderView
*/

QHeaderView::section {
  background: {{BG}};
  padding: 0 5px;
  color: {{TEXT}};
}

QHeaderView::section:hover {
  background: {{BG_PANEL}};
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
  background: {{BG}};
}

/*
  QCheckbox
*/

QCheckBox:disabled {
  color: {{TEXT_DIM}};
}

/*
  QComboBox
*/

QComboBox {
  background: {{BG_PANEL}};
  color: {{TEXT}};
  padding: 4px;
}

QComboBox:focus {
  background: {{BG_PANEL2}};
}

QComboBox:disabled {
  color: {{TEXT_DIM}};
}

QComboBox:on {
  background: {{BG_PANEL2}};
}

QComboBox QAbstractItemView {
  background: {{BG_PANEL}};
  selection-background-color: {{BG_PANEL2}};
  selection-color: {{TEXT}};
  outline: none;
}

QComboBox::drop-down {
  subcontrol-origin: margin;
  subcontrol-position: top right;
  width: 6ex;
  background: {{BG_PANEL}};
}

QComboBox::down-

QComboBox::down-

/*
  QSpinBox
*/

QSpinBox {
  background: {{BG_PANEL}};
  color: {{TEXT}};
  border: none;
  padding: 4px;
}

QSpinBox:disabled {
  color: {{TEXT_DIM}};
}

QSpinBox:focus {
  background: {{BG_PANEL2}};
}

/*
  QGroupBox
*/

QGroupBox {
  background: {{BG}};
  border: 2px solid {{BORDER}};
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
  color: {{TEXT_MUTED}};
}

QGroupBox QCheckBox {
  color: {{TEXT_MUTED}};
}

QGroupBox::title:disabled {
  color: {{TEXT_DIM}};
}

TransferListWidget {
  qproperty-downloadingStateForeground: {{ST_DL}};
  qproperty-forcedDownloadingStateForeground: {{ST_DL}};
  qproperty-downloadingMetadataStateForeground: {{ST_DL}};
  qproperty-allocatingStateForeground: {{ST_ALLOC}};
  qproperty-stalledDownloadingStateForeground: {{ST_STALL}};
  qproperty-stalledUploadingStateForeground: {{ST_STALL}};
  qproperty-uploadingStateForeground: {{ST_UP}};
  qproperty-forcedUploadingStateForeground: {{ST_UP}};
  qproperty-pausedDownloadingStateForeground: {{ST_PAUSE}};
  qproperty-pausedUploadingStateForeground: {{ST_PAUSE}};
  qproperty-errorStateForeground: {{ST_ERROR}};
  qproperty-missingFilesStateForeground: {{ST_ERROR}};
  qproperty-queuedDownloadingStateForeground: {{ST_QUEUE}};
  qproperty-queuedUploadingStateForeground: {{ST_QUEUE}};
  qproperty-checkingDownloadingStateForeground: {{ST_QUEUE}};
  qproperty-checkingUploadingStateForeground: {{ST_QUEUE}};
  qproperty-checkingResumeDataStateForeground: {{ST_QUEUE}};
  qproperty-movingStateForeground: {{ST_QUEUE}};
  qproperty-unknownStateForeground: {{ST_ERROR}};
}
