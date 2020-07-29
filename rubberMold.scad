//default external parameters, can be overwritten via commandline
wheelRadius = 40;
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
                cylinder(overallHeight,shaftRadius,shaftRadius,$fn=1000);
            
            //wheels
            translate([0,0,overallHeight/2-wheelHeight])//{
                cylinder(wheelHeight,wheelRadius,wheelRadius,$fn=1000);
            translate([0,0,-overallHeight/2])
                cylinder(wheelHeight,wheelRadius,wheelRadius,$fn=1000);

            //inlet
            translate([wheelRadius/2,wheelRadius/2,0])
                cylinder(50,shaftRadius/2,shaftRadius/2,$fn=1000);

        }
    //hole
    translate([0,0,-overallHeight/2-cutOverlap])
        cylinder(overallHeight+2*cutOverlap,wholeThickness,wholeThickness,$fn=1000);
    }
}

module mold(wheelRadius)
{
    difference(){
       translate([0,0,-overallHeight/2-wallThickness])
           cylinder(overallHeight + 2 * wallThickness, wheelRadius + 2* wallThickness,wheelRadius + 2* wallThickness,$fn=1000);
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

module cut3(wheelRadius){

}

module cut2(wheelRadius){
    d = wheelRadius+wallThickness +cutOverlap;
    z = overallHeight/2+wallThickness +cutOverlap;
    o = overallHeight+2*wallThickness + 2* cutOverlap;
    sep = 10;
    sep = $t;
    cp = [[1,1],[1,-1],[-1,1],[-1,-1]];
    c = false;
    echo(cp);
    for (a=cp){
        echo(a[0]);
        echo(a[1]);

    }
        
    //     translate([a[0]*curDisplacement,a[1]*curDisplacement,0])
    //     intersection(){     
    //         mold(wheelRadius);
    //         translate([0,-d,-z])
    //             cube(size = [d, d, o], center = c); 
    //}

    translate([sep,-sep,0])// move it a bit away from the center in order to visualize or print 
    intersection(){// do the actual cut
        mold(wheelRadius);//provide a mold to cut away from
        translate([0,-d,-z])// move it so one edge is right in the center of the mold (one of 4 options)
            cube(size = [d, d, o], center = c);// a cube that is supposed to cut 1/4 of the mold
    }
    translate([sep,sep,0])
    intersection(){     
        mold(wheelRadius);
        translate([0,0,-z])
            cube(size = [d, d, o], center = c); 
    }
    translate([-sep,sep,0])
    intersection(){     
        mold(wheelRadius);
        translate([-d,0,-z])
            cube(size = [d, d, o], center = c); 
    }
    translate([-sep,-sep,0]) 
    intersection(){   
        mold(wheelRadius);
        translate([-d,-d,-z])
            cube(size = [d, d, o], center = c); 
    }
}

echo(version=version());
echo("test");

module theThing(wheelRadius){
    cut2(wheelRadius);
    //cut(-40,-180,wheelRadius);
    //cut(40,360,wheelRadius);
    //cut(80,360,wheelRadius);
    //cut(40,$t*360);//to animate
}

theThing(wheelRadius);



