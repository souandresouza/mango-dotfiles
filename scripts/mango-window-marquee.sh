#!/usr/bin/env bash
# Marquee do título da janela focada (MangoWC) com no máximo 30 chars visíveis
title=""
pos=0
period=0
json_escape() {
  jq -Rn --arg t "$1" '$t'
}
while true; do
  cur=$(mmsg get focusing-client 2>/dev/null | jq -r '.title // empty')
  if [ "$cur" != "$title" ]; then
    title="$cur"
    pos=0
    pad="$title   "
    period=${#pad}
    s="$pad$pad"
  fi

  if [ -z "$title" ]; then
    printf '{"text": ""}\n'
  elif [ ${#title} -le 30 ]; then
    printf '{"text": %s}\n' "$(json_escape "$title")"
  else
    printf '{"text": %s}\n' "$(json_escape "${s:pos:30}")"
    pos=$(( (pos + 1) % period ))
  fi
  sleep 0.3
done
