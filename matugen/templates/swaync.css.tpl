/* Gerado por matugen 4.2.0 a partir do wallpaper atual.
   NAO EDITE — edite ~/.config/matugen/templates/swaync.css.tpl

   Hierarquia de fundo pelos papeis de superficie do Material You, que
   garantem degrau de luminancia consistente. Antes isso vinha de color1 e
   color2 do pywal.

   `accent` e colors.primary. O script pywal antigo buscava a cor mais
   saturada entre color1..color6 por calculo manual; no Material You o
   primary ja e a cor dominante do wallpaper. */

@define-color bg          {{base16.base00.default.hex}};
@define-color fg          {{colors.on_surface.default.hex}};
@define-color muted       {{colors.on_surface_variant.default.hex}};
@define-color accent      {{colors.primary.default.hex}};
@define-color surface     {{colors.surface_container.default.hex}};
@define-color surface-2   {{colors.surface_container_high.default.hex}};

/* Variantes translucidas */
@define-color bg-solid    {{colors.surface_container_lowest.default.hex}};
@define-color bg-cc       rgba({{colors.surface_container.default.red}}, {{colors.surface_container.default.green}}, {{colors.surface_container.default.blue}}, 0.94);
@define-color bg-hover    rgba({{colors.surface_container_high.default.red}}, {{colors.surface_container_high.default.green}}, {{colors.surface_container_high.default.blue}}, 0.32);
@define-color bg-active   rgba({{colors.surface_container_high.default.red}}, {{colors.surface_container_high.default.green}}, {{colors.surface_container_high.default.blue}}, 0.45);
@define-color border      rgba({{colors.surface_container_high.default.red}}, {{colors.surface_container_high.default.green}}, {{colors.surface_container_high.default.blue}}, 0.55);
@define-color border-soft rgba({{colors.surface_container_high.default.red}}, {{colors.surface_container_high.default.green}}, {{colors.surface_container_high.default.blue}}, 0.30);
@define-color accent-soft rgba({{colors.primary.default.red}}, {{colors.primary.default.green}}, {{colors.primary.default.blue}}, 0.22);
@define-color accent-mid  rgba({{colors.primary.default.red}}, {{colors.primary.default.green}}, {{colors.primary.default.blue}}, 0.55);
@define-color fg-dim      rgba({{colors.on_surface.default.red}}, {{colors.on_surface.default.green}}, {{colors.on_surface.default.blue}}, 0.55);
@define-color fg-faint    rgba({{colors.on_surface.default.red}}, {{colors.on_surface.default.green}}, {{colors.on_surface.default.blue}}, 0.12);