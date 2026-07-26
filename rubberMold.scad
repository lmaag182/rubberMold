// Default external parameters (override via Customizer or -D on the CLI)
wheelRadius = 40;
wheelHeight = 5;
overallHeight = 88;
wholeThickness = 5;
wallThickness = 2;
shaftRadius = 15;

// Tessellation: 1000 is print-smooth but makes CGAL STL export very slow.
// export.sh defaults to 64; raise with ./export.sh --fn 128 stl
fn = 64;

// Max quarter separation at full open (animation peak / GUI animate)
maxSep = 20;

// Internal parameters
cutOverlap = 5;

// $t in [0, 1]: closed → open → closed (triangle wave).
// $t=0 and $t=1: sep=0 (closed). $t=0.5: sep=maxSep (fully open).
// Works with View → Animate in the GUI and with export.sh anim.
function mold_sep(t) = maxSep * (1 - abs(2 * t - 1));


module positive(wheelRadius)
{
    difference() {
        union() {
            // shaft
            translate([0, 0, -overallHeight / 2])
                cylinder(overallHeight, shaftRadius, shaftRadius, $fn = fn);

            // wheels
            translate([0, 0, overallHeight / 2 - wheelHeight])
                cylinder(wheelHeight, wheelRadius, wheelRadius, $fn = fn);
            translate([0, 0, -overallHeight / 2])
                cylinder(wheelHeight, wheelRadius, wheelRadius, $fn = fn);

            // inlet
            translate([wheelRadius / 2, wheelRadius / 2, 0])
                cylinder(50, shaftRadius / 2, shaftRadius / 2, $fn = fn);
        }
        // hole
        translate([0, 0, -overallHeight / 2 - cutOverlap])
            cylinder(overallHeight + 2 * cutOverlap, wholeThickness, wholeThickness, $fn = fn);
    }
}

module mold(wheelRadius)
{
    difference() {
        translate([0, 0, -overallHeight / 2 - wallThickness])
            cylinder(
                overallHeight + 2 * wallThickness,
                wheelRadius + 2 * wallThickness,
                wheelRadius + 2 * wallThickness,
                $fn = fn
            );
        positive(wheelRadius);
    }
}

module cut(displacement, rotation, wheelRadius)
{
    translate([displacement, 0, 0]) {
        rotate([0, 0, rotation]) {
            difference() {
                mold(wheelRadius);
                translate([
                    0,
                    -(wheelRadius + wallThickness + cutOverlap),
                    -(overallHeight / 2 + wallThickness + cutOverlap)
                ])
                    cube(size = [
                        wheelRadius * 2 + 2 * wallThickness + 2 * cutOverlap,
                        wheelRadius * 2 + 2 * wallThickness + 2 * cutOverlap,
                        overallHeight + 2 * wallThickness + 2 * cutOverlap
                    ], center = false);
            }
        }
    }
}

module cut2(wheelRadius)
{
    d = wheelRadius + wallThickness + cutOverlap;
    z = overallHeight / 2 + wallThickness + cutOverlap;
    o = overallHeight + 2 * wallThickness + 2 * cutOverlap;
    sep = mold_sep($t);
    c = false;

    translate([sep, -sep, 0])
    intersection() {
        mold(wheelRadius);
        translate([0, -d, -z])
            cube(size = [d, d, o], center = c);
    }
    translate([sep, sep, 0])
    intersection() {
        mold(wheelRadius);
        translate([0, 0, -z])
            cube(size = [d, d, o], center = c);
    }
    translate([-sep, sep, 0])
    intersection() {
        mold(wheelRadius);
        translate([-d, 0, -z])
            cube(size = [d, d, o], center = c);
    }
    translate([-sep, -sep, 0])
    intersection() {
        mold(wheelRadius);
        translate([-d, -d, -z])
            cube(size = [d, d, o], center = c);
    }
}

module theThing(wheelRadius)
{
    cut2(wheelRadius);
}

theThing(wheelRadius);
