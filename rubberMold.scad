// Parametric silicon rubber mold — OpenSCAD
// Override via Customizer or: openscad -D name=value
//
// Tooling (3 pieces):
//   1–2) Two clamshell halves — outer shape only (parting = XZ, open ±Y)
//   3)   Loose core pin — withdraw along Z, then open the halves
//
// Demolding sequence:
//   1. Pull the core pin out along the axis (grip the end tabs)
//   2. Open the two halves along ±Y
//   3. Remove the cast; trim sprue/vent runners
//
// Why a loose core (not molded into the halves)?
//   An integral core is a fixed axle through both end caps. The hollow
//   shaft is cast onto that axle; opening the halves rips the tube.
//
// Why two halves (not four radial quarters)?
//   Disks sit in fixed-height U-grooves on every jaw → demold damages the part.

// --- Part geometry ---
wheelRadius = 40;
wheelHeight = 5;
overallHeight = 88;
shaftRadius = 15;
// Cast through-hole radius (= core seat / pin radius)
holeRadius = 5;

// --- Mold shell ---
wallThickness = 2;

// --- Sprue / vents ---
sprueRadius = 6;
ventRadius = 2.5;
diskVentCount = 4;
bottomVents = true;
topVents = true;

// --- Loose core pin ---
corePullTab = 12;      // grip length past each end cap
coreClearance = 0.15;  // pin radius undersize for release
coreExtract = true;    // animate core pull with $t in assembly view

// --- Tessellation ---
fn = 64;

// --- Animation ---
maxSep = 25;

// --- Internal ---
cutOverlap = 5;

// $t in [0,1]: halves closed → open → closed; core seats → extracts → seats
function mold_sep(t) = maxSep * (1 - abs(2 * t - 1));
function core_pull(t) =
    coreExtract
        ? (shell_height() + corePullTab) * (1 - abs(2 * t - 1))
        : 0;

function outer_radius() = wheelRadius + wallThickness;
function shell_z_min() = -overallHeight / 2 - wallThickness;
function shell_z_max() = overallHeight / 2 + wallThickness;
function shell_height() = shell_z_max() - shell_z_min();

// ---------------------------------------------------------------------------
// Outer cast shape (SOLID — hole comes from the loose core, not from this)
// ---------------------------------------------------------------------------
module shaft_and_wheels()
{
    translate([0, 0, -overallHeight / 2])
        cylinder(h = overallHeight, r = shaftRadius, $fn = fn);

    translate([0, 0, overallHeight / 2 - wheelHeight])
        cylinder(h = wheelHeight, r = wheelRadius, $fn = fn);

    translate([0, 0, -overallHeight / 2])
        cylinder(h = wheelHeight, r = wheelRadius, $fn = fn);
}

function channel_ox(r) =
    let (
        clear_core = holeRadius + r + 0.5,
        prefer = shaftRadius * 0.65
    )
    max(clear_core, prefer);

module sprue()
{
    r = sprueRadius;
    ox = channel_ox(r);
    z0 = -wheelHeight;
    z1 = shell_z_max() + cutOverlap;
    translate([ox, 0, z0])
        cylinder(h = z1 - z0, r = r, $fn = fn);
}

module top_disk_vents()
{
    if (topVents && ventRadius > 0 && diskVentCount > 0) {
        r = ventRadius;
        radial = (shaftRadius + wheelRadius) * 0.5;
        z0 = overallHeight / 2 - wheelHeight;
        z1 = shell_z_max() + cutOverlap;
        for (i = [0 : diskVentCount - 1]) {
            a = (i + 0.5) * 360 / diskVentCount;
            rotate([0, 0, a])
                translate([radial, 0, z0])
                    cylinder(h = z1 - z0, r = r, $fn = max(16, fn / 2));
        }
    }
}

module bottom_disk_vents()
{
    if (bottomVents && ventRadius > 0 && diskVentCount > 0) {
        r = ventRadius;
        z0 = shell_z_min() - cutOverlap;
        z1 = -overallHeight / 2 + wheelHeight;
        h = z1 - z0;

        radial_inner = (holeRadius + shaftRadius) * 0.5 + shaftRadius * 0.25;
        for (i = [0 : diskVentCount - 1]) {
            a = (i + 0.5) * 360 / diskVentCount;
            rotate([0, 0, a])
                translate([radial_inner, 0, z0])
                    cylinder(h = h, r = r, $fn = max(16, fn / 2));
        }

        radial_outer = wheelRadius - r * 1.5;
        for (i = [0 : diskVentCount - 1]) {
            a = i * 360 / diskVentCount;
            rotate([0, 0, a])
                translate([radial_outer, 0, z0])
                    cylinder(h = h, r = r * 0.85, $fn = max(16, fn / 2));
        }
    }
}

module outer_positive()
{
    union() {
        shaft_and_wheels();
        sprue();
        top_disk_vents();
        bottom_disk_vents();
    }
}

// ---------------------------------------------------------------------------
// Loose core pin (print as its own STL)
// ---------------------------------------------------------------------------
module core_pin()
{
    r = max(0.4, holeRadius - coreClearance);
    h = shell_height() + 2 * corePullTab;
    translate([0, 0, shell_z_min() - corePullTab])
        cylinder(h = h, r = r, $fn = fn);

    // Pull heads outside each end cap
    for (z = [shell_z_min() - corePullTab, shell_z_max()]) {
        translate([0, 0, z])
            cylinder(h = corePullTab * 0.35, r = r + 2.5, $fn = fn);
    }
}

module core_pin_animated()
{
    translate([0, 0, core_pull($t)])
        core_pin();
}

// ---------------------------------------------------------------------------
// Clamshell halves — outer cavity + cylindrical seat for the loose core
// ---------------------------------------------------------------------------
module mold_shell()
{
    translate([0, 0, shell_z_min()])
        cylinder(h = shell_height(), r = outer_radius(), $fn = fn);
}

module core_tunnel()
{
    translate([0, 0, shell_z_min() - cutOverlap])
        cylinder(
            h = shell_height() + 2 * cutOverlap,
            r = holeRadius,
            $fn = fn
        );
}

module mold_half_body()
{
    difference() {
        mold_shell();
        outer_positive();
        core_tunnel();
    }
}

// sep_override < 0 → use mold_sep($t); else use that distance
module mold_halves(sep_override = -1)
{
    d = outer_radius() + cutOverlap;
    z = -shell_z_min() + cutOverlap;
    o = 2 * z;
    sep = sep_override < 0 ? mold_sep($t) : sep_override;

    translate([0, -sep, 0])
    intersection() {
        mold_half_body();
        translate([-d, -d, -z])
            cube([2 * d, d, o], center = false);
    }

    translate([0, sep, 0])
    intersection() {
        mold_half_body();
        translate([-d, 0, -z])
            cube([2 * d, d, o], center = false);
    }
}

// ---------------------------------------------------------------------------
// Render mode (export.sh sets these via -D)
//   "assembly" — halves + core, animated with $t  (preview / GIF)
//   "halves"   — mold halves only, closed          (print STL)
//   "core"     — core pin only                     (print STL)
//   "layout"   — halves opened + core to the side  (optional plate)
// ---------------------------------------------------------------------------
show = "assembly";

if (show == "assembly") {
    mold_halves();
    core_pin_animated();
} else if (show == "halves") {
    mold_halves(0);
} else if (show == "core") {
    core_pin();
} else if (show == "layout") {
    mold_halves(outer_radius() + 10);
    translate([outer_radius() * 2 + corePullTab + 20, 0, 0])
        core_pin();
}
