module positive()
{
    wheelRadius = 20;
    wheelHeight = 5;
    overallHeight = 88;
    wholeThickness = 5;
    
    wallThickness = 2;
    boringOverlap = 5;
    
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
    //hole
    translate([0,0,-overallHeight/2-boringOverlap])
        cylinder(overallHeight+2*boringOverlap,wholeThickness,wholeThickness);
    }  
}

echo(version=version());
echo(version="");

positive();
