#!/usr/bin/env bash

sensors 2>/dev/null | awk '
function temperature(line, value) {
    if (match(line, /[+-]?[0-9]+([.][0-9]+)?/)) {
        value = substr(line, RSTART, RLENGTH)
        sub(/^\+/, "", value)
        return value
    }
    return ""
}

index($0, ":") == 0 && NF > 0 {
    sensor = $1
    next
}

sensor ~ /^k10temp/ && /^[[:space:]]*Tctl:/ {
    tctl = temperature($0)
}
/^[[:space:]]*Package id 0:/ {
    package = temperature($0)
}
/^[[:space:]]*Tdie:/ {
    tdie = temperature($0)
}
/^[[:space:]]*CPU:/ {
    cpu = temperature($0)
}
/^[[:space:]]*Core 0:/ && core == "" {
    core = temperature($0)
}

END {
    if (tctl != "") print tctl
    else if (package != "") print package
    else if (tdie != "") print tdie
    else if (cpu != "") print cpu
    else if (core != "") print core
}
'
