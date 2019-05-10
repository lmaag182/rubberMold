module rubberMold()
{
    wheelRadius = 40;
    wheelHeight = 5;
    overallHeight = 25;
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
echo(version="");

rubberMold();
