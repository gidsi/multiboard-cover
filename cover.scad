include <BOSL2/std.scad>
include <BOSL2/walls.scad>

// change what you need here
// walls open/closed
top_wall_closed=true;
left_wall_closed=true;
right_wall_closed=true;
bottom_wall_closed=false;

// walls and lid hex
top_wall_hex=false;
left_wall_hex=false;
right_wall_hex=false;
bottom_wall_hex=false;
lid_hex=false;

// grid and box size
size_x=8;
size_y=8;
height=50;

// wall thickness
wall_width=1.2;

// changing the hex layout
hex_strut=1.2;
hex_spacing=5;

// END customizable part

// change these if you know what you're doing
multiboard_height=6.25;
multiboard_gridsize=25;

width=multiboard_gridsize*size_x;
depth=multiboard_gridsize*size_y;

tooth_depth=5;
tooth_height=height*0.5;

clipnose_width=7;
clipnose_height=3.4;
clipnose_offset=(multiboard_height-clipnose_height)/2;

triangle_side_length=7.3;

if(tooth_height < 20) {
    tooth_height=sqrt(tooth_depth^2+height^2);
}

module connector_port() {
    translate([0,clipnose_height,clipnose_width]) rotate([0,90,-90]) translate([0.1,0,0]) linear_extrude(3.4)
      polygon(
          points=[
            [0,0],
            [0.4,0.4],
            [0.4,1.736],
            [-0.1,2.236],
            [-0.1,4.082],
            [1.218,5.4],
            [5.582,5.4],
            [6.9,4.082],
            [6.9,2.236],
            [6.4,1.736],
            [6.4,0.4],
            [6.8,0]
          ], 
          paths=[[0,1,2,3,4,5,6,7,8,9,10,11]]
        );
}

module connector() {
    difference () {
        translate([0,(5*.8)/2,0]) rotate([90,0,0]) scale([.5,.8,.8]) translate([0,0,-1]) difference() {
            connector_port();
            cube([7,5,1]);
            translate([0,0,6]) cube([7,5,1]);
        }
        translate([0,-3.5,0]) rotate([0,45,0]) cube([7,7,7]);
    }
}

module triangle(length, side_length=triangle_side_length, clips=false) {
  difference() {
      linear_extrude(length)
        polygon(points=[[0,0],[side_length,0],[0,side_length]], paths=[[0,1,2]]);
        
      if (clips) {
          clipnose_count=floor(length/25)-1;
          for ( i = [1 :  clipnose_count]) {
              translate([0,clipnose_offset,(i*25)-(clipnose_width/2)]) connector_port();
          }
      }
  }
}

module tooth() {
    diagonal=tooth_depth*sqrt(2);
    trans_C=(diagonal)/2;
    tooth_rotation=atan(trans_C/tooth_height);
    trans_A=trans_C*sin(tooth_rotation);
    trans_B=sqrt(trans_C^2+trans_A^2);
    trans_x=trans_B;
    trans_z=trans_A;
    translate([trans_C,trans_C,0]) rotate([0,0,180]) difference() {
      translate([trans_x,0,-trans_z]) rotate([0,tooth_rotation,0]) rotate([0,0,45]) cube([tooth_depth,tooth_depth,tooth_height]);
      
      translate([trans_C, 0, -width]) cube([width*2,width*2,width*2]);
      translate([-width, -width, -width*2]) cube([width*2,width*2,width*2]);
    }
}

module wall(width_param, left_wall=true, right_wall=true, hex_wall=false) {
    width = width_param 
      + (left_wall ? wall_width : 0) 
      + (right_wall ? wall_width : 0);

    if(hex_wall==true) {
        translate([wall_width/2,width/2,(height+multiboard_height)/2]) rotate([90,0,90]) hex_panel([width,height+multiboard_height,wall_width], hex_strut, hex_spacing);
    } else {
        cube([wall_width,width,height+multiboard_height]);
    }
    
    tooth_count=floor(width_param/25)-1;
    for ( i = [1 : tooth_count]) {
        tooth_offset=(left_wall ? wall_width : 0)+multiboard_gridsize*i;
        translate([wall_width,tooth_offset,0]) {
            translate([0,0,multiboard_height]) tooth();
            translate([0,0,clipnose_offset]) connector();
        }
    }
    
    if(left_wall==true) {
      translate([wall_width,wall_width,0]) triangle(height+multiboard_height,triangle_side_length);
    } else {
      translate([wall_width,0,height+multiboard_height]) rotate([0,180,-90]) triangle(height, triangle_side_length, true);
    }
    
    if(right_wall==true) {
        translate([wall_width,width-wall_width,0]) rotate([0,0,-90]) triangle(height+multiboard_height, triangle_side_length);
    } else {
        translate([wall_width,width,multiboard_height+height]) rotate([0,0,-90]) mirror([0,0,1]) triangle(height, triangle_side_length,true);
    }
    
    translate([wall_width,0,height+multiboard_height]) rotate([-90,0,0]) triangle(width, triangle_side_length);
}

module box(walls=[true,true,true,true],hex_walls=[false,false,false,false], hex_top=false) {
    union() {
        if(walls[0]==true) {
            translate([0,width+wall_width+(walls[2]?wall_width:0),0]) rotate([0,0,-90]) wall(depth,walls[3],walls[1],hex_walls[0]);
        } else {
            translate([(walls[3]?wall_width:0),width+(walls[2]?wall_width:0),height+multiboard_height]) rotate([-90,0,-90]) triangle(depth, triangle_side_length, true);
        }
        if(walls[1]==true) {
            translate([depth+wall_width+(walls[3]?wall_width:0),width+(walls[0]?wall_width:0)+(walls[2]?wall_width:0),0]) rotate([0,0,180]) wall(width,walls[0],walls[2],hex_walls[1]);
        } else {
            translate([depth+(walls[3]?wall_width:0),width+(walls[2]?wall_width:0),height+multiboard_height]) rotate([-90,0,180]) triangle(depth, triangle_side_length, true);
        }
        if(walls[2]==true) {
            translate([depth+(walls[3]?wall_width:0)+(walls[1]?wall_width:0),0,0]) rotate([0,0,90]) wall(depth,walls[1],walls[3],hex_walls[2]);
        } else {
            translate([depth+(walls[3]?wall_width:0),0,height+multiboard_height]) rotate([-90,0,90]) triangle(depth, triangle_side_length, true);
        }
        if(walls[3]==true) {
            wall(width,walls[2],walls[0],hex_walls[3]);
        } else {
            translate([0,(walls[2]?wall_width:0),height+multiboard_height]) rotate([-90,0,0]) triangle(depth, triangle_side_length, true);
        }
        
        top_width=width+(walls[1] ? wall_width : 0)+(walls[3] ? wall_width : 0);
        top_depth=depth+(walls[0] ? wall_width : 0)+(walls[2] ? wall_width : 0);
        if(hex_top==true) {
            translate([width/2,depth/2,height+multiboard_height]) hex_panel([width+wall_width*2,depth+wall_width*2,wall_width], hex_strut, hex_spacing);
        } else {
            translate([0,0,height+multiboard_height]) cube([top_width,top_depth,wall_width]);
        }
    }
}

box(
  [
    top_wall_closed,
    right_wall_closed,
    bottom_wall_closed,
    left_wall_closed
  ],
  [
    top_wall_hex,
    right_wall_hex,
    bottom_wall_hex,
    left_wall_hex
  ],
  lid_hex
);
