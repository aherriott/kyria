// translate(-cam_pos[1]) top();
// translate(-cam_pos[1]) plate();
// translate(-cam_pos[1]) mid();
translate(-cam_pos[1]) base();
// pcb(true);
// case_border(true);
// elec_pocket();

// 3d_model(false);


/**
 * PCB
 */

inf = 100000; // "Infinity". Used for intersections
 
// Main rectangle (x, y, lx, ly)
main_rect = [-120.225+1, -19.095+1, 129.875-2, inf];

// Top arc across the fingertips (x, y, r)
top_arc_x = -45.386;
top_arc_y = -89.444;
top_arc_r = 158.106-1;

// Thumb cluster
thumb_x = -103.28;
thumb_y = -46.435;
thumb_ly = 40.1;
thumb_lx = thumb_ly; // Just needs to be long enough to get buried in main_rect
thumb_rot = 45;
thumb_r = 70.3496+1;

// Bottom right notch below pinkies (Assume bottom right corner is shared)
br_notch_lx = 9.650 + 14.811;
br_notch_ly = 19.095 - 11.525;

// Top left notch above pcb (x/y specify bottom right point)
tl_notch_x = -86.475;
tl_notch_y = sqrt(top_arc_r^2 - (-109.225 - top_arc_x)^2) + top_arc_y; // x is -109.225, point is where that meets top arc

module pcb(notch) {
    difference () {
        // Positive features
        union () {
            intersection() {
                // Main rectangle
                translate([main_rect[0], main_rect[1], 0])
                    square([main_rect[2], main_rect[3]]);
                
                // Top arc
                translate([top_arc_x, top_arc_y, 0])
                    circle(top_arc_r, $fn=100);
            };
            // Thumb cluster
            translate([thumb_x, thumb_y, 0]) rotate([0,0,thumb_rot])
                square([thumb_lx, thumb_ly]);
            
            // Thumb curve
            x = (main_rect[1] - thumb_y) / tan(thumb_rot) + thumb_x; // x where thumb meets main
            translate([x, main_rect[1], 0]) rotate([0, 0, -(180 - thumb_rot)])
                fillet_2d(180-thumb_rot, thumb_r);
        };
        // Negative features
        union () {
            // Bottom right notch
            rect([main_rect[0] + main_rect[2] - br_notch_lx, main_rect[1],              br_notch_lx, br_notch_ly]);
                
            // Top left notch
            if(notch) translate([tl_notch_x, tl_notch_y]) rotate([0, 0, 90])
               square([inf, inf]);
        };
    };
};


/**
 * Case Border
 */

case_clearance = 1; // Gap around the edge of the pcb
case_thickness = 7; // Case wall thickness
case_fillet_r = 2;  // Case edge fillet size
tl_notch_wall = 3;  // Case thickness in the top left notch for the USBC connector

// Draw the outer border of the case (solid)
module case_border(notch) {
    difference() {
        // Positive Features
        union() {
            // Two offsets to control the radii of the outer fillets
            offset(delta = case_clearance + case_thickness - case_fillet_r) pcb(notch);
            offset(r = case_fillet_r, $fn=100)
                offset(delta = case_clearance + case_thickness - case_fillet_r) pcb(notch);
        };
        // Negative Features
        union() {
            // PCB
            offset(delta = case_clearance) pcb(notch);
            // Top left notch
            x = tl_notch_x - tl_notch_wall - case_clearance;
            y = tl_notch_y + tl_notch_wall + case_clearance;
            if(notch) translate([x, y, 0]) rotate([0, 0, 90])
                square([inf, inf]);
        };
    };
};


/**
 * Electrical pocket
 */

// Top left & top right corners of the pcb thumb box
thumb_tl_x = thumb_x - cos(90-thumb_rot) * thumb_ly;
thumb_tl_y = thumb_y + sin(90-thumb_rot) * thumb_ly;
thumb_tr_x = main_rect[0];
thumb_tr_y = thumb_tl_y + tan(thumb_rot) * (thumb_tr_x - thumb_tl_x);

// Electricals cutout
elec_r = sqrt((thumb_tr_x - top_arc_x)^2 + (thumb_tr_y - top_arc_y)^2) + case_clearance;

// Electric pocket (left & top side use the pcb, bottom radius lines up with pocket)
elec_x = -86.475; // right side x coord

module elec_pocket(notch) {
    difference() {
        intersection() {
            offset(delta = case_clearance) pcb(notch);
            translate([elec_x, thumb_tr_y, 0]) rotate([0, 0, 90])
                square([inf, elec_x - main_rect[0] + case_clearance]);
        };
        union() {
            translate([top_arc_x, top_arc_y, 0]) circle(elec_r, $fn=100);
        };
    };
};


/**
 * Key holes
 */ 

// Cherry mx spec: https://docs.rs-online.com/19cd/0900766b813d1126.pdf (No corner filleting. Assumes the plate will be laser cut)
key_hole_lx = 14;
key_hole_ly = 14;

module key_hole() {
    square([key_hole_lx, key_hole_ly], center = true);
};

module key_hole_2u() {
    // 2u key hole dimensions. Each row is a rectangle: [x,y,lx,ly]
    rectangles = [
        [-7,                -7,                     14,             14],
        [-23.8 / 2,         -6.77 + 0.8,            23.8,           12.3 - 2*0.8],
        [-23.8/2 - 6.65/2,  -6.67,                  6.65,           12.3],
        [+23.8/2 - 6.65/2,  -6.67,                  6.65,           12.3],
        [-23.8/2 - 4.2,     -0.5,                   4.2 - 6.65/2,   2.8],
        [+23.8/2 + 6.65/2,  -0.5,                   4.2 - 6.65/2,   2.8],
        [-23.8/2 - 3/2,     -6.77 - (13.5 - 12.3),  3,              13.5 - 10],
        [+23.8/2 - 3/2,     -6.77 - (13.5 - 12.3),  3,              13.5 - 10],
    ];

    union() {
        for(i = rectangles) {
            translate([i[0], i[1], 0]) square([i[2], i[3]]);
        };
    };
};

module key_holes() {
    // Key hole positions (x, y, rotation)
    key_c = 19.05;                  // Gap between keys
    key_y0 = [0, 12, 18, 11.5, 9];  // y stagger of each column

    1u_key_pos = [
        for(x = [0:4]) for(y=[0:2]) [-key_c*x, key_c*y + key_y0[x], 0],
        [-45.386, -7.570, 0],
        find_center(-64.765, -17.121, -68.388, -3.598)
    ];
    2u_key_pos = [
        find_center(-85.023, -6.790, -97.148, -13.790),
        find_center(-105.065, -19.865, -114.965, -29.765)
    ];
    enc_cut = [-26.336, -7.57, 11, 11];
    enc_fillet = 1;

    // 1u keys
    for(i=1u_key_pos){
        translate([i[0], i[1], 0]) rotate([0, 0, i[2]])
            key_hole();
    };
    // 2u keys
    for(i=2u_key_pos) {
        translate([i[0], i[1], 0]) rotate([0, 0, i[2]+90])
            key_hole_2u();
    };
    // Encoder
    offset(r = enc_fillet, $fn = 100) rect_center(enc_cut);
};


/**
 * Holes
 */

m3_tap_d = 2.5;    // Tap size
m3_clear_d = 3.2;  // Clearance fit
magnet_d = 4.1;     // 4mm magnet
pin_d = 3;
cam_tap_d = 5.105; // 1/4-20 tap size (camera)
plate_hole_d = m3_clear_d;

ho = 4.5;           // Hole offset: Orthogonal distance from pcb to hole
ho_ra = sqrt(2)*ho; // Hole off at a right angle

// Calculate all the corners going counter-clockwise:
ho_thumb_tl = [thumb_tl_x - sin(thumb_rot+45)*ho_ra, thumb_tl_y + cos(thumb_rot+45)*ho_ra, 0];
ho_thumb_bl = [thumb_x - cos(thumb_rot+45)*ho_ra, thumb_y - sin(thumb_rot+45)*ho_ra, 0];
ho_thumbc_ra = 90;
ho_thumbc_la = 135;
// Thumb curve angle -> coord (+x = 0)
function ho_thumbc(a) =
    [cos(a) * (thumb_r - ho) + top_arc_x, sin(a) * (thumb_r - ho) + top_arc_y, 0];
ho_brnot_bl = [main_rect[0] + main_rect[2] - br_notch_lx + ho, main_rect[1] - ho, 0];
ho_brnot_tl = [main_rect[0] + main_rect[2] - br_notch_lx + ho, main_rect[1] + br_notch_ly - ho, 0];
ho_brnot_tr = [main_rect[0] + main_rect[2] + ho, main_rect[1] + br_notch_ly - ho, 0];
// Top arc angle -> coord (+x = 0)
ho_ta_ar = acos((main_rect[0] + main_rect[2] + ho - top_arc_x) / (top_arc_r + ho));
ho_ta_aelec = acos((elec_x - top_arc_x) / (top_arc_r + ho));
ho_ta_al = acos((main_rect[0] - ho - top_arc_x) / (top_arc_r + ho));
function ho_ta(a) =
    [cos(a) * (top_arc_r + ho)  + top_arc_x, sin(a) * (top_arc_r + ho) + top_arc_y, 0];
ho_thumb_tr = [thumb_tr_x - ho, thumb_tr_y + cos(thumb_rot)*ho, 0];

// interpolate point a, point b, portion of a to b (p=0.5 is the midpoint)
function interp(a, b, p) = a*(1-p) + b*p;

// Screws (one in each corner)
screw_pos = [
    ho_thumb_tl, ho_thumb_bl, ho_brnot_tr, ho_ta(ho_ta_al), ho_ta(ho_ta_ar),
];

// Pin holes for case rigidity
pin_pos = [
    ho_thumbc(105.5),                                       // Thumb curve
    ho_brnot_tl,                                            // Bottom right notch
    interp(ho_brnot_tr, ho_ta(ho_ta_ar), 0.5),              // Right side
    ho_ta(interp(ho_ta_ar, ho_ta_aelec, 0.66)),             // Top arc
    ho_thumb_tr,
];

// Magnet holes
magnet_pos = [
    interp(ho_thumb_tl, ho_thumb_bl, 0.5),                  // End of thumb
    ho_thumbc(126),                                         // Thumb curve
    interp(ho_thumbc(ho_thumbc_ra), ho_brnot_bl, 0.25),     // Below encoder
    interp(ho_brnot_tr, ho_ta(ho_ta_ar), 0.25),             // Bottom right side
    interp(ho_brnot_tr, ho_ta(ho_ta_ar), 0.75),             // Top of right side
    ho_ta(interp(ho_ta_ar, ho_ta_aelec, 0.33)),             // Right of top arc
    ho_ta(ho_ta_aelec),                                     // Left of top arc
    interp(ho_thumb_tr, ho_ta(ho_ta_al), 0.5),              // Left side
];

// Holes to mount plate to the pcb
plate_hole_pos = [
    [-101.307, -16.566],
    [-57.376, 1.631],
    [-66.675, 60.125],
    [-7, 49.950],
    [-13.164, 0.250],
];

// 1/4 camera holes
cam_pos = [
    [main_rect[0]+main_rect[2]/2-30, (main_rect[1]+tl_notch_y)/2+3],
    [main_rect[0]+main_rect[2]/2, (main_rect[1]+tl_notch_y)/2+3],
    [main_rect[0]+main_rect[2]/2+30, (main_rect[1]+tl_notch_y)/2+3],
];

module holes(screw, pin, magnet, plate, cam) {
    if(screw) for(i = screw_pos) translate(i) circle(screw/2, $fn = 100);
    if(pin) for(i = pin_pos) translate(i) circle(pin/2, $fn = 100);
    if(magnet) for(i = magnet_pos) translate(i) circle(magnet/2, $fn = 100);
    if(plate) for(i = plate_hole_pos) translate(i) circle(plate/2, $fn = 100);
    if(cam) for(i = cam_pos) translate(i) circle(cam/2, $fn = 100);
};

/**
 * Misc
 */

module nice_view() {
    // Designed to cutout nice!view controller. Screen + black border
    // See Nice Keyboards for where the dimensions came from.

    // Positioned over the nice!nano controller. 
    // Note, this will not line up with the 4/5 holes from the native kyria display support. Instead this is meant to be wired manually.
    size = [14, 36 - 1.3 - 1.7 - 3.65];
    coord = [
        main_rect[0] + (14.5 + 27.4)/2 - size[0]/2, 
        tl_notch_y - 3.65 - size[1], 0
    ];

    translate(coord) square(size);
};

module pwr_switch() {
    size = [8, 8];
    coord = [
        main_rect[0] + 1, 
        sqrt(top_arc_r^2 - (top_arc_x - main_rect[0])^2) + top_arc_y - size[1] - 1, 
        0
    ];

    translate(coord) square(size);
};

/**
 * Generate
 */

module 3d_model(pcb) {
    color("red", 1.0) linear_extrude(3) base();
    color("orange", 1.0) translate([0, 0, 3]) linear_extrude(6) mid();
    color("yellow", 1.0) translate([0, 0, 9]) linear_extrude(1.5) plate();
    color("green", 1.0) translate([0, 0, 10.5]) linear_extrude(3) mid();
    color("blue", 1.0) translate([0, 0, 13.5]) linear_extrude(3) top();
    
    if(pcb) color("black", 1.0) translate([0, 0, 10.5-5-1]) linear_extrude(1) pcb(true);
};

module top() {
    notch = false;
    difference() {
        // Positive features
        union() {
            case_border(notch);
            elec_pocket(notch);
        };
        // Negative features
        union() {
            // Holes
            holes(m3_clear_d, pin_d, magnet_d, false, false);
            // Nice!view
            nice_view();
            // Power switch
            pwr_switch();
        };
    };  
};

module plate() {
    notch = true;
    union() {
        difference() {
            // Positive features
            union() {
                case_border(notch);
                offset(delta = case_clearance) pcb(notch);
            };
            // Negative features
            union() {
                elec_pocket(notch);
                key_holes();
                holes(m3_clear_d, false, false, plate_hole_d, false);
            };
        };
        // Fillet the bottom left
        angle = atan2(abs(thumb_tr_y - top_arc_y), abs(thumb_tr_x - top_arc_x));
        translate([thumb_tr_x-1, thumb_tr_y-1, 0]) rotate([0, 0, 90-angle])
            fillet_2d(angle, case_fillet_r);
    };
};

module mid() {
    notch = true;
    difference() {
        // Positive features
        union() {
            case_border(notch);
        };
        // Negative features
        union() {
            // PCB + clearance
            offset(delta = case_clearance) pcb(notch);
            // Holes (we allow pins b/c mid serves double duty)
            holes(m3_clear_d, pin_d, false, false, false);
        };
    };  
};

module base() {
    notch = false;
    difference() {
        // Positive features
        union() {
            case_border(notch);
            offset(delta = case_thickness) pcb(notch);
        };
        // Negative features
        union() {
            // Holes
            holes(m3_tap_d, false, magnet_d, false, cam_tap_d);
        };
    };  
};

/**
 * Utils
 */

module fillet_2d(angle, r) {
    /**
     * icoceles triangle with a circle cut from the end
     * one line on +x axis, angle rotates counterclockwise
     * sides of triangle are r/tan(angle/2) so circle is tangent to both sides of the triangle
     */
    s = r/tan(angle/2);
    difference () {
        polygon([[0, 0], 
            [s, 0], 
            [cos(angle) * s, sin(angle)*s]]
        );
        translate([s, r]) circle(r, $fn=100);
    };    
}

// Returns [x, y, angle] of center of two points
function find_center(x1, y1, x2, y2) =
    [(x1 + x2)/2, (y1 + y2)/2, atan2(y2-y1, x2-x1)];

// [x, y, sz_x, sz_y]
module rect(r){
    translate([r[0], r[1], 0]) square([r[2], r[3]]);
}
module rect_center(r){
    translate([r[0], r[1], 0]) square([r[2], r[3]], center = true);
}
module circ(c){
    translate([c[0], c[1], 0]) circle(c[2], $fn = 100);
}

    