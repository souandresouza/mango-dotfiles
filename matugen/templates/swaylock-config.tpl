# Gerado por matugen 4.2.0 a partir do wallpaper atual.
# NAO EDITE — edite ~/.config/matugen/templates/swaylock-config.tpl
#
# As opcoes nao-cor (fonte, screenshot, blur, vignette, grace) foram copiadas
# do config que existia antes desta migracao.
#
# Os estados de erro e de confirmacao ficam em `error` e `tertiary`: a
# semantica de "senha errada" e "confirmar" nao deve depender do wallpaper.
# O `.light` da esquerda e o tom profundo, que precisa aparecer sobre a foto
# desfocada do wallpaper.

ignore-empty-password
font=JetBrainsMono Nerd Font

clock
timestr=%T
datestr=%a, %d-%m-%Y

screenshots

fade-in=0.2

effect-blur=30x5
#effect-greyscale
effect-scale=0.1
effect-vignette=0.5:0.5

indicator
indicator-radius=100
indicator-thickness=7
indicator-caps-lock

key-hl-color={{colors.on_surface.default.hex}}

separator-color=00000000

inside-color=00000000
inside-clear-color={{colors.tertiary.light.hex}}00
inside-caps-lock-color={{colors.primary.light.hex}}00
inside-ver-color={{colors.tertiary.light.hex}}00
inside-wrong-color={{colors.error.light.hex}}00

ring-color={{colors.primary.default.hex_stripped}}D9
ring-clear-color={{colors.on_surface.default.hex_stripped}}D9
ring-caps-lock-color={{colors.tertiary.default.hex_stripped}}D9
ring-ver-color={{colors.tertiary.default.hex_stripped}}D9
ring-wrong-color={{colors.error.default.hex_stripped}}D9

line-color={{colors.on_surface.default.hex}}
line-clear-color={{colors.tertiary.default.hex}}FF
line-ver-color={{colors.tertiary.default.hex}}00
line-wrong-color={{colors.error.default.hex}}FF

text-color={{colors.on_surface.default.hex}}
text-clear-color={{colors.on_surface.default.hex}}
text-ver-color={{colors.tertiary.default.hex}}
text-wrong-color={{colors.error.default.hex}}

bs-hl-color={{colors.primary.default.hex_stripped}}FF
caps-lock-key-hl-color={{colors.tertiary.default.hex}}FF
caps-lock-bs-hl-color={{colors.error.default.hex}}FF
disable-caps-lock-text
text-caps-lock-color={{colors.primary.default.hex}}

grace=2