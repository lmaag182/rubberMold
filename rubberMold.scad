//default external parameters, can be overwritten via commandline
wheelRadius = 30;
wheelHeight = 5;
overallHeight = 88;
wholeThickness = 5;
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
                cylinder(overallHeight,shaftRadius,shaftRadius,$fn=100);
            
            //wheels
            translate([0,0,overallHeight/2-wheelHeight])//{
                cylinder(wheelHeight,wheelRadius,wheelRadius,$fn=100);
            translate([0,0,-overallHeight/2])
                cylinder(wheelHeight,wheelRadius,wheelRadius,$fn=100);

            //inlet
            translate([wheelRadius/2,wheelRadius/2,0])
                cylinder(400,shaftRadius/4,shaftRadius/4);

        }
    //hole
    translate([0,0,-overallHeight/2-cutOverlap])
        cylinder(overallHeight+2*cutOverlap,wholeThickness,wholeThickness,$fn=100);
    }
}

module mold(wheelRadius)
{
    difference(){
       translate([0,0,-overallHeight/2-wallThickness])
           cylinder(overallHeight + 2 * wallThickness, wheelRadius + 2* wallThickness,wheelRadius + 2* wallThickness,$fn=100);
       positive(wheelRadius);
    }
}

module cut(displacement,rotation,wheelRadius) {
    translate([displacement,0,0]){
        rotate([0,0,rotation]){
            difference(){     
                mold(wheelRadius);
                translate([0,-(wheelRadius+wallThickness +cutOverlap),-(overallHeight/2+wallThickness +cutOverlap)])
                    cube(size = [wheelRadius*2+2*wallThickness +2*cutOverlap, wheelRadius*2+2*wallThickness +2*cutOverlap,overallHeight+2*wallThickness + 2* cutOverlap], center = false); 
            }
        }
    }
}

module cut2(wheelRadius){
    translate([6,-6,0])
    intersection(){     
        mold(wheelRadius);
        translate([0,-(wheelRadius+wallThickness +cutOverlap),-(overallHeight/2+wallThickness +cutOverlap)])
            cube(size = [wheelRadius+wallThickness +cutOverlap, wheelRadius+wallThickness +cutOverlap,overallHeight+2*wallThickness + 2* cutOverlap], center = false); 
    }
    translate([6,6,0])
    intersection(){     
        mold(wheelRadius);
        translate([0,0,-(overallHeight/2+wallThickness +cutOverlap)])
            cube(size = [wheelRadius+wallThickness +cutOverlap, wheelRadius+wallThickness +cutOverlap,overallHeight+2*wallThickness + 2* cutOverlap], center = false); 
    }
    translate([-6,6,0])
    intersection(){     
        mold(wheelRadius);
        translate([-(wheelRadius+wallThickness +cutOverlap),0,-(overallHeight/2+wallThickness +cutOverlap)])
            cube(size = [wheelRadius+wallThickness +cutOverlap, wheelRadius+wallThickness +cutOverlap,overallHeight+2*wallThickness + 2* cutOverlap], center = false); 
    }
    translate([-6,-6,0]) 
    intersection(){   
        mold(wheelRadius);
        translate([-(wheelRadius+wallThickness +cutOverlap),-(wheelRadius+wallThickness +cutOverlap),-(overallHeight/2+wallThickness +cutOverlap)])
            cube(size = [wheelRadius+wallThickness +cutOverlap, wheelRadius+wallThickness +cutOverlap,overallHeight+2*wallThickness + 2* cutOverlap], center = false); 
    }
}

echo(version=version());
echo(version="");

module theThing(wheelRadius){
    cut2(wheelRadius);
    //cut(-40,-180,wheelRadius);
    //cut(40,360,wheelRadius);
    //cut(80,360,wheelRadius);
    //cut(40,$t*360);//to animate
}

theThing(wheelRadius);



