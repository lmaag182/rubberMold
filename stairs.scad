thinwall=0.3;  //minimum thickness for material FUD=0.3 WSF=0.7
height=40; //height of the tank
radius=5; //radius of the tank
rise=0.75;run=1;width=3; //size of each step

steps=height/rise;echo("steps=",steps);
x=(radius+width/2)*2*PI;
angle=360*((steps*run)/x)/steps;echo("angle=",angle);

color([1,1,1,1])cylinder(r=radius,h=height,$fn=64);
for (i=[1:steps]){
    rotate([0,0,i*angle])translate([radius+width/2,0,i*rise])cube([width+.1,run,thinwall],center=true);
 
    hull(){//outer curve between steps
        rotate([0,0,i*angle])translate([radius+width,0,i*rise])cube([thinwall,run,thinwall],center=true);
        rotate([0,0,(i-1)*angle])translate([radius+width,0,(i-1)*rise])cube([thinwall,run,thinwall],center=true);
    }

    hull() {//handrail
    rotate([0,0,i*angle])translate([radius+width,0,i*rise+3])sphere(d=thinwall,center=true,$fn=16);
    rotate([0,0,(i-1)*angle])translate([radius+width,0,(i-1)*rise+3])sphere(d=thinwall,center=true,$fn=16);
    }
}
for (i=[0:steps]){//vert handrail supports
    rotate([0,0,i*angle])translate([radius+width,0,i*rise+1.5])cylinder(d=thinwall,h=3,center=true,$fn=16);
    }