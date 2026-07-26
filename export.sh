#!/usr/bin/env bash
# Export rubberMold: STL, preview PNG, and/or explode-view GIF.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

SCAD="rubberMold.scad"
OUT_DIR="build"
STL_DIR="$OUT_DIR/stl"
ANIM_DIR="$OUT_DIR/anim"

# Design defaults (override with flags or env)
WHEEL_RADIUS="${WHEEL_RADIUS:-40}"
FN="${FN:-64}"                 # cylinder segments; 64 is fast, 128+ smoother, 1000 very slow
MAX_SEP="${MAX_SEP:-20}"       # peak quarter separation at full open
FRAMES="${FRAMES:-40}"         # full cycle: open then close (even numbers look best)
DELAY_CS="${DELAY_CS:-8}"      # GIF frame delay in centiseconds (8 = 0.08s)
CAMERA="500,500,500,0,0,0"
IMG_SIZE="800,800"

usage() {
  cat <<'EOF'
Usage: ./export.sh [options] [stl|png|anim|all]

Targets (default: all):
  stl     Export build/stl/rubberMold.stl
  png     Export build/anim/rubberMold.png (single preview, fully open)
  anim    Open → close cycle frames + build/anim/rubberMold.gif
  all     stl + png + anim

Animation ($t 0 → 1): mold starts closed, opens to maxSep, then closes again.

Options:
  -r, --radius N     wheelRadius (default: 40, or $WHEEL_RADIUS)
  -f, --fn N         cylinder $fn / tessellation (default: 64, or $FN)
                     Higher = smoother & much slower (e.g. 128, 256)
  -s, --sep N        maxSep peak opening distance (default: 20, or $MAX_SEP)
  -n, --frames N     animation frame count for full open+close cycle (default: 40)
  -d, --delay CS     GIF delay in centiseconds (default: 8)
  -h, --help         Show this help

Examples:
  ./export.sh stl
  ./export.sh anim
  ./export.sh -n 24 -s 25 anim   # smoother cycle, wider open
  ./export.sh --fn 128 stl
  ./export.sh -r 20 -n 20 all

Note: OpenSCAD often prints nothing while CGAL builds the mesh.
That is normal — not a hang. With --fn 64 each frame is usually quick.
EOF
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "error: required command not found: $1" >&2
    exit 1
  }
}

# Run OpenSCAD and keep the user informed while it works silently.
run_openscad() {
  local label="$1"
  shift
  echo "  → OpenSCAD: $label (fn=$FN, wheelRadius=$WHEEL_RADIUS, maxSep=$MAX_SEP)"
  echo "  → no further output until done — this can take a while"
  local start end elapsed
  start=$(date +%s)
  # Stream OpenSCAD logs so it does not look frozen if it prints anything
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
  local out="$STL_DIR/rubberMold.stl"
  echo "exporting STL → $out"
  # $t=0 → closed mold (quarters together)
  run_openscad "CGAL mesh → STL" -o "$out" \
    "${openscad_common[@]}" \
    -D '$t=0' \
    "$SCAD"
  echo "done: $out ($(du -h "$out" | cut -f1))"
}

export_png() {
  need_cmd openscad
  mkdir -p "$ANIM_DIR"
  local out="$ANIM_DIR/rubberMold.png"
  echo "exporting PNG → $out (fully open)"
  # $t=0.5 → peak open
  run_openscad "preview PNG" -o "$out" \
    "${openscad_common[@]}" \
    --camera="$CAMERA" \
    --imgsize="$IMG_SIZE" \
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

  # Remove old numbered frames so globs stay ordered and clean
  rm -f "$ANIM_DIR"/rubberMold_[0-9][0-9].png
  # Also clear 3-digit names if someone used a large frame count before
  rm -f "$ANIM_DIR"/rubberMold_[0-9][0-9][0-9].png

  echo "animation: open → close over $FRAMES frames (maxSep=$MAX_SEP)"

  local z frame out t phase
  local pad=2
  if (( FRAMES > 99 )); then
    pad=3
  fi

  for ((z = 0; z < FRAMES; z++)); do
    frame="$(printf "%0${pad}d" "$((z + 1))")"
    out="$ANIM_DIR/rubberMold_${frame}.png"
    # $t from 0 → 1: closed → open → closed (see mold_sep() in .scad)
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
  echo "done: $gif (open then close, loop)"
}

TARGET="all"
while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--radius)
      WHEEL_RADIUS="$2"
      shift 2
      ;;
    -f|--fn)
      FN="$2"
      shift 2
      ;;
    -s|--sep)
      MAX_SEP="$2"
      shift 2
      ;;
    -n|--frames)
      FRAMES="$2"
      shift 2
      ;;
    -d|--delay)
      DELAY_CS="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    stl|png|anim|all)
      TARGET="$1"
      shift
      ;;
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

# Rebuild common args after option parsing
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
