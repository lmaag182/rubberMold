
module example003()
{
  difference() {
    union() {
      cylinder(3,30,30);
      cube([30, 30, 30], center = true);
      cube([40, 15, 15], center = true);
      cube([15, 40, 15], center = true);
      cube([15, 15, 40], center = true);
    }
    union() {
      cube([50, 10, 10], center = true);
      cube([10, 50, 10], center = true);
      cube([10, 10, 50], center = true);
    }
  }
}

module rubberMold()
{
    wheelRadius = 30;
    wheelHeight = 5;
    overallHeight = 60;
    wholeThickness = 5;
    
    difference(){
        union(){
            //shaft
            translate([0,0,-overallHeight/2])
                cylinder(overallHeight,10,10);
            
            //wheels
            translate([0,0,overallHeight/2-wheelHeight])//{
                cylinder(wheelHeight,wheelRadius,wheelRadius);
            translate([0,0,-overallHeight/2])
                cylinder(wheelHeight,wheelRadius,wheelRadius);
        }
    //whole
    translate([0,0,-overallHeight/2-5])
        cylinder(70,wholeThickness,wholeThickness);
    }  
}

echo(version=version());
echo(version="hello");

rubberMold();

// Written by Clifford Wolf <clifford@clifford.at> and Marius
// Kintel <marius@kintel.net>
//
// To the extent possible under law, the author(s) have dedicated all
// copyright and related and neighboring rights to this software to the
// public domain worldwide. This software is distributed without any
// warranty.
//
// You should have received a copy of the CC0 Public Domain
// Dedication along with this software.
// If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
