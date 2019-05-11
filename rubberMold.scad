//external parameters
wheelRadius = 20;
wheelHeight = 5;
overallHeight = 88;
wholeThickness = 5;
wallThickness = 2;
shaftRadius = 10;

//internal parameters
boringOverlap = 5;

module positive()
{
    difference(){
        union(){
            //shaft
            translate([0,0,-overallHeight/2])
                cylinder(overallHeight,shaftRadius*2,shaftRadius*2);
            
            //wheels
            translate([0,0,overallHeight/2-wheelHeight])//{
                cylinder(wheelHeight,wheelRadius*2,wheelRadius*2);
            translate([0,0,-overallHeight/2])
                cylinder(wheelHeight,wheelRadius*2,wheelRadius*2);
        }
    //hole
    translate([0,0,-overallHeight/2-boringOverlap])
        cylinder(overallHeight+2*boringOverlap,wholeThickness,wholeThickness);
    }  
}

module mold()
{
    difference(){
       translate([0,0,-overallHeight/2-wallThickness])
           cylinder(overallHeight + 2 * wallThickness, wheelRadius*2 + 2* wallThickness,wheelRadius*2 + 2* wallThickness);
       positive();
    }
}

module cut() {
    difference(){
        
        mold();
        cube(size = [100, 100, 100], center = false);
        
    }
}

echo(version=version());
echo(version="");



cut();
