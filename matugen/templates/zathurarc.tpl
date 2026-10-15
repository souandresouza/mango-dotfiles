# Gerado por matugen 4.2.0 a partir do wallpaper atual.
# NAO EDITE — edite ~/.config/matugen/templates/zathurarc.tpl
#
# Substitui o zathurarc inteiro. As opcoes de scroll/recolore foram copiadas
# do arquivo atual para nao perder nenhum ajuste.

set adjust-open "best-fit"

set pages-per-row 1

set scroll-page-aware "true"
set smooth-scroll "true"
set scroll-full-overlap 0.01
set scroll-step 100

set zoom-min 10
set guioptions "s"

set font "inconsolata 15"
set default-bg "{{base16.base00.default.hex}}"
set default-fg "{{colors.on_surface.default.hex}}"

set statusbar-fg "{{colors.on_surface.default.hex}}"
set statusbar-bg "{{base16.base00.default.hex}}"

set inputbar-bg "{{base16.base00.default.hex}}"
set inputbar-fg "{{colors.primary.default.hex}}"

set highlight-color "{{colors.tertiary.light.hex}}80"
set highlight-active-color "{{colors.primary.default.hex}}80"

set recolor true
set recolor-lightcolor "{{colors.on_surface.default.hex}}"
set recolor-darkcolor "{{base16.base00.default.hex}}"
set recolor-reverse-video true
#set recolor-keephue true

set render-loading false
set scroll-step 50
unmap f
map f toggle_fullscreen
map [fullscreen] f toggle_fullscreen