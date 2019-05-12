//external parameters
wheelRadius = 30;
wheelHeight = 5;
overallHeight = 88;
wholeThickness = 9;
wallThickness = 2;
shaftRadius = 15;

//internal parameters
cutOverlap = 5;

module positive(wheelRadius)
{
    difference(){
        union(){
            //shaft
            translate([0,0,-overallHeight/2])
                cylinder(overallHeight,shaftRadius,shaftRadius);
            
            //wheels
            translate([0,0,overallHeight/2-wheelHeight])//{
                cylinder(wheelHeight,wheelRadius,wheelRadius);
            translate([0,0,-overallHeight/2])
                cylinder(wheelHeight,wheelRadius,wheelRadius);
        }
    //hole
    translate([0,0,-overallHeight/2-cutOverlap])
        cylinder(overallHeight+2*cutOverlap,wholeThickness,wholeThickness);
    }  
}

module mold(wheelRadius)
{
    difference(){
       translate([0,0,-overallHeight/2-wallThickness])
           cylinder(overallHeight + 2 * wallThickness, wheelRadius + 2* wallThickness,wheelRadius + 2* wallThickness);
       positive(wheelRadius);
    }
}

module cut(displacement,rotation,wheelRadius) {
    translate([displacement,0,0]){
        rotate([0,0,rotation]){
            difference(){     
                mold(wheelRadius);
                translate([0,-(wheelRadius+wallThickness +cutOverlap),-(overallHeight/2+wallThickness +cutOverlap)])
                cube(size = [wheelRadius*2+2*wallThickness +2*cutOverlap, wheelRadius*2+2*wallThickness +2*cutOverlap,          overallHeight+2*wallThickness + 2* cutOverlap], center = false); 
            }
        }
    }
}

echo(version=version());
echo(version="");

module theThing(wheelRadius){
    cut(-40,-180,wheelRadius);
    cut(40,360,wheelRadius);
    cut(80,360,wheelRadius);
    //cut(40,$t*360);//to animate
}

theThing(wheelRadius=30);
theThing(wheelRadius=40);


