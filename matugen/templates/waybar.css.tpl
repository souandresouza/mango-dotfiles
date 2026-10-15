/* Gerado por matugen 4.2.0 a partir do wallpaper atual.
   Fonte: https://github.com/catppuccin/matugen
   NAO EDITE — edite ~/.config/matugen/templates/waybar.css.tpl

   Mapeamento ANSI (matugen -> slots). Os slots 1-6 usam a variante `.light`
   (tom profundo) e os 9-14 a variante `.default` (tom claro), o que reproduz
   o par normal/bright da convencao ANSI.

   Nao mapeia color1..6 para base08..base0e: no matugen esses slots sao
   tonalidades quase acinzentadas da cor dominante do wallpaper e nao
   carregam matiz. Os slots semanticos vem de Material You, que garante
   `error` vermelho e contraste de `on_surface` sobre qualquer fundo. */

@define-color foreground {{colors.on_surface.default.hex}};
@define-color background {{base16.base00.default.hex}};
@define-color cursor {{colors.primary.default.hex}};

@define-color color0 {{base16.base00.default.hex}};
@define-color color1 {{colors.error.light.hex}};
@define-color color2 {{colors.primary.light.hex}};
@define-color color3 {{colors.tertiary.light.hex}};
@define-color color4 {{colors.secondary.light.hex}};
@define-color color5 {{colors.primary_container.light.hex}};
@define-color color6 {{colors.secondary_container.light.hex}};
@define-color color7 {{colors.on_surface.default.hex}};
@define-color color8 {{base16.base03.default.hex}};
@define-color color9 {{colors.error.default.hex}};
@define-color color10 {{colors.primary.default.hex}};
@define-color color11 {{colors.tertiary.default.hex}};
@define-color color12 {{colors.secondary.default.hex}};
@define-color color13 {{colors.primary_container.default.hex}};
@define-color color14 {{colors.secondary_container.default.hex}};
@define-color color15 {{colors.on_surface.default.hex}};