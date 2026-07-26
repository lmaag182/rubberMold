#!/usr/bin/env bash
# Export rubberMold: STLs (halves + core), preview PNG, and/or open/close GIF.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

SCAD="rubberMold.scad"
OUT_DIR="build"
STL_DIR="$OUT_DIR/stl"
ANIM_DIR="$OUT_DIR/anim"

WHEEL_RADIUS="${WHEEL_RADIUS:-40}"
FN="${FN:-64}"
MAX_SEP="${MAX_SEP:-25}"
FRAMES="${FRAMES:-40}"
DELAY_CS="${DELAY_CS:-8}"
CAMERA="500,500,500,0,0,0"
IMG_SIZE="800,800"

usage() {
  cat <<'EOF'
Usage: ./export.sh [options] [stl|png|anim|all]

Targets (default: all):
  stl     Export printable STLs:
            build/stl/rubberMold_halves.stl
            build/stl/rubberMold_core.stl
            build/stl/rubberMold_assembly.stl  (preview, closed)
  png     Preview PNG at full open (halves + extracted core)
  anim    Open → close cycle (halves + core pull) → GIF
  all     stl + png + anim

Demolding (cast hollow shaft without ripping it):
  1. Pull the loose core pin out along the axis
  2. Open the two halves
  3. Remove the part; trim sprue/vent runners

Options:
  -r, --radius N     wheelRadius (default: 40)
  -f, --fn N         tessellation $fn (default: 64)
  -s, --sep N        maxSep half opening (default: 25)
  -n, --frames N     animation frames (default: 40)
  -d, --delay CS     GIF delay centiseconds (default: 8)
  -h, --help         Show this help

Examples:
  ./export.sh stl
  ./export.sh anim
  ./export.sh --fn 128 stl
EOF
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "error: required command not found: $1" >&2
    exit 1
  }
}

run_openscad() {
  local label="$1"
  shift
  echo "  → OpenSCAD: $label (fn=$FN, wheelRadius=$WHEEL_RADIUS, maxSep=$MAX_SEP)"
  echo "  → no further output until done — this can take a while"
  local start end elapsed
  start=$(date +%s)
  if openscad "$@"; then
    end=$(date +%s)
    elapsed=$((end - start))
    echo "  → finished in ${elapsed}s"
  else
    local rc=$?
    echo "error: openscad failed (exit $rc)" >&2
    return "$rc"
  fi
}

openscad_common=(
  -D "wheelRadius=${WHEEL_RADIUS}"
  -D "fn=${FN}"
  -D "maxSep=${MAX_SEP}"
  --autocenter
  --projection=p
)

export_stl() {
  need_cmd openscad
  mkdir -p "$STL_DIR"

  local halves="$STL_DIR/rubberMold_halves.stl"
  local core="$STL_DIR/rubberMold_core.stl"
  local assembly="$STL_DIR/rubberMold_assembly.stl"

  echo "exporting mold halves → $halves"
  run_openscad "halves STL" -o "$halves" \
    "${openscad_common[@]}" \
    -D 'show="halves"' \
    -D '$t=0' \
    "$SCAD"
  echo "done: $halves ($(du -h "$halves" | cut -f1))"

  echo "exporting core pin → $core"
  run_openscad "core STL" -o "$core" \
    "${openscad_common[@]}" \
    -D 'show="core"' \
    "$SCAD"
  echo "done: $core ($(du -h "$core" | cut -f1))"

  echo "exporting closed assembly (preview) → $assembly"
  run_openscad "assembly STL" -o "$assembly" \
    "${openscad_common[@]}" \
    -D 'show="assembly"' \
    -D '$t=0' \
    "$SCAD"
  echo "done: $assembly ($(du -h "$assembly" | cut -f1))"

  # Keep legacy filename as a copy of the halves for older docs/scripts
  cp -f "$halves" "$STL_DIR/rubberMold.stl"
}

export_png() {
  need_cmd openscad
  mkdir -p "$ANIM_DIR"
  local out="$ANIM_DIR/rubberMold.png"
  echo "exporting PNG → $out (halves open, core extracted)"
  run_openscad "preview PNG" -o "$out" \
    "${openscad_common[@]}" \
    --camera="$CAMERA" \
    --imgsize="$IMG_SIZE" \
    -D 'show="assembly"' \
    -D '$t=0.5' \
    "$SCAD"
  echo "done: $out"
}

export_anim() {
  need_cmd openscad
  need_cmd convert
  mkdir -p "$ANIM_DIR"

  if (( FRAMES < 3 )); then
    echo "error: --frames must be at least 3 for open+close (got $FRAMES)" >&2
    exit 1
  fi

  rm -f "$ANIM_DIR"/rubberMold_[0-9][0-9].png
  rm -f "$ANIM_DIR"/rubberMold_[0-9][0-9][0-9].png

  echo "animation: halves open + core extract over $FRAMES frames (maxSep=$MAX_SEP)"

  local z frame out t phase
  local pad=2
  if (( FRAMES > 99 )); then
    pad=3
  fi

  for ((z = 0; z < FRAMES; z++)); do
    frame="$(printf "%0${pad}d" "$((z + 1))")"
    out="$ANIM_DIR/rubberMold_${frame}.png"
    t="$(awk -v i="$z" -v n="$FRAMES" 'BEGIN {
      if (n <= 1) { printf "0"; exit }
      printf "%.6f", i / (n - 1)
    }')"
    if (( z * 2 < FRAMES - 1 )); then
      phase="opening"
    elif (( z * 2 == FRAMES - 1 )) || (( z * 2 == FRAMES )); then
      phase="open"
    else
      phase="closing"
    fi
    echo "frame $frame/$FRAMES  \$t=$t  ($phase) → $out"
    run_openscad "frame $frame ($phase)" -o "$out" \
      "${openscad_common[@]}" \
      --camera="$CAMERA" \
      --imgsize="$IMG_SIZE" \
      -D 'show="assembly"' \
      -D "\$t=$t" \
      "$SCAD"
  done

  local gif="$ANIM_DIR/rubberMold.gif"
  local glob
  if (( pad == 2 )); then
    glob="$ANIM_DIR"/rubberMold_[0-9][0-9].png
  else
    glob="$ANIM_DIR"/rubberMold_[0-9][0-9][0-9].png
  fi
  echo "assembling GIF → $gif"
  # shellcheck disable=SC2086
  convert -delay "$DELAY_CS" -loop 0 $glob "$gif"
  echo "done: $gif"
}

TARGET="all"
while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--radius) WHEEL_RADIUS="$2"; shift 2 ;;
    -f|--fn) FN="$2"; shift 2 ;;
    -s|--sep) MAX_SEP="$2"; shift 2 ;;
    -n|--frames) FRAMES="$2"; shift 2 ;;
    -d|--delay) DELAY_CS="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    stl|png|anim|all) TARGET="$1"; shift ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ! -f "$SCAD" ]]; then
  echo "error: missing $SCAD in $SCRIPT_DIR" >&2
  exit 1
fi

openscad_common=(
  -D "wheelRadius=${WHEEL_RADIUS}"
  -D "fn=${FN}"
  -D "maxSep=${MAX_SEP}"
  --autocenter
  --projection=p
)

case "$TARGET" in
  stl)  export_stl ;;
  png)  export_png ;;
  anim) export_anim ;;
  all)
    export_stl
    export_png
    export_anim
    ;;
esac
