#!/bin/bash
#for file in /*;do;unrar e $file;done;
#for file in "ls *"; do echo $file; done;
#for file in "*.rar"; do unrar x "$file"; done;
#for file in "*.zip"; do unzip "$file" -d "$file" ; done;
#exit 1
for ((z=1; z<=20; z++)); 
do
echo "process anim $z";
openscad -o build/anim/rubberMold$z.png -D wheelRadius=40 -D '$t='$z --camera=500,500,500,0,0,0 --autocenter  --projection=p rubberMold.scad;
#do unzip "$z" -d "$z'DIR'"; 


#echo "$z"
done;

convert build/anim/rubberMold*.png to build/anim/rubberMold.gif

echo "create stl file ... not at the moment"
#openscad -o rubberMold.stl -D wheelRadius=40 --camera=500,500,500,0,0,0 --autocenter  --projection=p rubberMold.scad

#for z in *.zip; do unzip "$z" ; done;
#for z in *.zip; do echo $z ; done;

