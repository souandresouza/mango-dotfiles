; Gerado por matugen 4.2.0 a partir do wallpaper atual.
; NAO EDITE — edite ~/.config/matugen/templates/fuzzel.ini.tpl
;
; alpha ff = opaco. A selecao usa surface_variant (antes: color4) e o texto
; selecionado usa on_surface_variant, que e o par de contraste correto em
; Material You — o script antigo usava `background`, o que fica ilegivel
; quando o wallpaper e claro.

[colors]
background={{base16.base00.default.hex}}ff
prompt={{base16.base07.default.hex}}ff
text={{base16.base07.default.hex}}ff
placeholder={{base16.base03.default.hex}}ff
input={{base16.base07.default.hex}}ff
match={{colors.primary.default.hex}}ff
selection={{colors.surface_variant.default.hex}}ff
selection-text={{colors.on_surface_variant.default.hex}}ff
selection-match={{colors.primary.default.hex}}ff
border={{colors.surface_variant.default.hex}}dd