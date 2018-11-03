// below are parameters you can set
// all measurements are in millimeters (mm). fuck inches.

button_thickness = 3;
frame_thickness = 6;
button_design_acrylic_thickness = frame_thickness; // unimplemented

include_button_border = false; // true is still unimplemented

bt_side = 50;
bt_count = 4;
bt_center_disparity = 77;
bt_plunge_distance = 4;

fx_length = 40.5;
fx_width = 23.5;
fx_count = 2;
fx_center_disparity = 154; // TODO: this is always at the center of the BT's
fx_plunge_distance = 3.6;

st_side = 25;
st_plunge_distance = 3.6;

bt_center_to_st_center = 91.5;
bt_center_to_fx_center = 82;
bt_center_to_knob_center = 68;

knob_diameter = 30;
knob_disparity = 297;
knob_motor_hole_diameter = 30;

flush_gap = 0.125; // used for the gap between welds
bt_allowance = 1; // used for the gap for the button to reduce friction
height = 50;

front_margin = 25;
back_margin = 25;
left_margin = 25;
right_margin = 25;

// if true, everything will be laid out flat, to be used as the template for the
// cut.
// if false, everything will be laid out as if assembled
dxf_view = false;

// above are the values you can alter

////////////////////////////////////////////////////////////////////////////////

// DO NOT TOUCH ANYTHING BEYOND THIS LINE unless you know what you're doing

// on this section lies the supporting derived parameter

mm_per_inch = 25.4;
acrylic_density = 1.18; // grams per cubic centimeter
cherry_frame_to_max_plunge = (0.46 - 0.2) * mm_per_inch;

////////////////////////////////////////////////////////////////////////////////

// Creates the geometry for the hole where the Cherry MX keys would be mounted
// on
module cherry_hole() {
    // cherry hole sounds lewd...
    
    // reference based on http://i.imgur.com/FeggbO6.png
    
    Z = 0.6140;
    Y = 0.5500;
    X = 0.1972;
    W = 0.1378;
    V = 0.0386;
    U = 0.0320;
    
    A = Z - 2 * (U + V + W) - X / 2;
    B = A + W;
    C = B + V;
    D = C + U;
    
    // scale from mm to inches
    scale(
        mm_per_inch,
        mm_per_inch,
        mm_per_inch
    ) {
        // make sure the center centers to the origin
        polygon([
            [-A,  C],
            [ A,  C],
            [ A,  D],
            [ B,  D],
            [ B,  C],
            [ C,  C],
            [ C,  B],
            [ D,  B],
            [ D,  A],
            [ C,  A],
            [ C, -A],
            [ D, -A],
            [ D, -B],
            [ C, -B],
            [ C, -C],
            [ B, -C],
            [ B, -D],
            [ A, -D],
            [ A, -C],
            [-A, -C],
            [-A, -D],
            [-B, -D],
            [-B, -C],
            [-C, -C],
            [-C, -B],
            [-D, -B],
            [-D, -A],
            [-C, -A],
            [-C,  A],
            [-D,  A],
            [-D,  B],
            [-C,  B],
            [-C,  C],
            [-B,  C],
            [-B,  D],
            [-A,  D],
        ]);
    };
};

// obtained from https://gist.github.com/LightAtPlay/24148d8be2e66d26fd11
function hsv(h, s = 1, v = 1, a = 1, p, q, t) = (p == undef || q == undef || t == undef)
	? hsv(
		(h%1) * 6,
		s<0?0:s>1?1:s,
		v<0?0:v>1?1:v,
		a,
		(v<0?0:v>1?1:v) * (1 - (s<0?0:s>1?1:s)),
		(v<0?0:v>1?1:v) * (1 - (s<0?0:s>1?1:s) * ((h%1)*6-floor((h%1)*6))),
		(v<0?0:v>1?1:v) * (1 - (s<0?0:s>1?1:s) * (1 - ((h%1)*6-floor((h%1)*6))))
	)
	:
	h < 1 ? [v,t,p,a] :
	h < 2 ? [q,v,p,a] :
	h < 3 ? [p,v,t,a] :
	h < 4 ? [p,q,v,a] :
	h < 5 ? [t,p,v,a] :
[v,p,q,a];

module rainbow(angle, alpha = 1) {
    // starting from bright red, color each element with a color obtained by
    // rotating the H in the HSL wheel (but you have to convert it to RGB first)

    for (i = [0: $children - 1]) {
        color(hsv(i * angle, a = alpha)) children(i);
    }
}

// Joins objects that are close together given a specific merging distance
// Use this instead of union() in case there is a space between objects that
// should be joined
module join_close_objects(
    distance = 0.0625
) {
    offset(delta = -distance ) offset( delta = distance ) union() children();
}

module clean_flashes(
    distance = 0.0625
) {
    join_close_objects(-distance) children();
}

// Creates a linear array of objects
module linear_array(
    x_copies,
    y_copies,
    x_distance,
    y_distance
) {
    for (i = [0 : 1 : x_copies - 1]) {
        for (j = [0 : 1 : y_copies - 1]) {
            translate([
                x_distance * i,
                y_distance * i,
                0,
            ]) {
                children();
            }
        }
    }
}

// Creates a linear array of objects but the whole array is centered on the
// origin
module linear_array_from_center(
    x_copies,
    y_copies,
    x_distance,
    y_distance
) {
    linear_array(
        x_copies,
        y_copies,
        x_distance,
        y_distance
    ) {
        translate([
            - (x_distance * (x_copies - 1)) / 2,
            - (y_distance * (y_copies - 1)) / 2,
            0
        ]) {
            children();
        }
    }
}

// Creates a finger joint given a rectangle centered on origin, the thickness of
// the gap, and number of fingers.
module side_fingers(
    dims,
    thickness,
    count,
    flip,
    sides = [true, true, true, true],
    flush_gap = flush_gap
) {
    // Creates fingers on the square from origin to [1, 1], to be scaled up as
    // needed
    module standard_side_fingers(
        count,
        flip
    ) {
        division = 1 / (2 * count);
        flip_val = flip ? 0 : 1;
        
        for ( i = [0 : 1 : count - 1] ) {
            polygon([
                [0, (2 * i + flip_val    ) * division],
                [1, (2 * i + flip_val    ) * division],
                [1, (2 * i + flip_val + 1) * division],
                [0, (2 * i + flip_val + 1) * division]
            ]);
        }
    }

    // Creates the gaps between the fingers.
    module standard_side_finger_gaps(
        count,
        flush_gap
    ) {
        for ( i = [1 : 1 : 2 * count - 1] ) {
            translate([
                0,
                i / (count * 2) - flush_gap / 2
            ]) square([1, flush_gap]);
        }
    }

    // start with left
    if (sides[0]) {
        translate([
            -dims[0] / 2 - thickness,
            -dims[1] / 2
        ]) scale([
            thickness, dims[1]
        ]) clean_flashes() difference() {
            standard_side_fingers(count, flip);
            
            standard_side_finger_gaps(count, flush_gap / dims[1]);
        }
    }
    
    // then with bottom
    if (sides[1]) {
        translate([
            dims[0] / 2,
            -dims[1] / 2 - thickness,
        ]) rotate(
            90,
            [0, 0, 1]
        ) scale([
            thickness, dims[0]
        ]) clean_flashes() difference() {
            standard_side_fingers(count, flip);
            
            standard_side_finger_gaps(count, flush_gap / dims[0]);
        }
    }
    
    // then with right
    if (sides[2]) {
        translate([
            dims[0] / 2 + thickness,
            dims[1] / 2
        ])
        rotate(
            180,
            [0, 0, 1]
        ) scale([
            thickness, dims[1]
        ]) clean_flashes() difference() {
            standard_side_fingers(count, flip);
            
            standard_side_finger_gaps(count, flush_gap / dims[1]);
        }
    }
    
    // then with top
    if (sides[3]) {
        translate([
            -dims[0] / 2,
            dims[1] / 2 + thickness,
        ])
        rotate(
            270,
            [0, 0, 1]
        ) scale([
            thickness, dims[0]
        ]) clean_flashes() difference() {
            standard_side_fingers(count, flip);
            
            standard_side_finger_gaps(count, flush_gap / dims[0]);
        }
    }
}

// Creates the BT button (a simple square)
module button_rect() {
    square(bt_side, true);
}

// Creates the FX button (a simple rectangle)
module effects_rect() {
    square([fx_length, fx_width], true);
}

// Creates the ST button (a simple square)
module start_rect() {
    square(st_side, true);
}

// Creates the needed transformation for the BT buttons given a reference object
module bt_array( offset = true ) {
    // offset doesn't actually do anything

    linear_array_from_center(
        4,
        1,
        bt_center_disparity,
        0
    ) children();
}

// Creates the needed transformation for the FX buttons given a reference object
module fx_array( offset = true ) {
    translate([
        0,
        offset ? -bt_center_to_fx_center : 0,
    ]) linear_array_from_center(
        2,
        1,
        fx_center_disparity,
        0
    ) children();
}

// Creates the needed transformation for the FX buttons given a reference object
module st_array( offset = true ) {
    translate([
        0,
        offset ? bt_center_to_st_center : 0,
    ]) children();
}

// Creates the needed transformation for the knobs given a reference object
module knob_array( offset = true ) {
    translate([
        0,
        offset ? bt_center_to_knob_center : 0,
    ]) linear_array_from_center(
        2,
        1,
        knob_disparity,
        0
    ) children();
}

top_bottom_frame_dimensions =  [
    left_margin + knob_diameter + knob_disparity + right_margin,

    front_margin + frame_thickness + st_side / 2 + bt_center_to_st_center
        + bt_center_to_fx_center + fx_width / 2 + frame_thickness + back_margin
];

left_right_frame_dimensions = [
    height,

    top_bottom_frame_dimensions[1],
];

front_back_frame_dimensions = [
    top_bottom_frame_dimensions[0],

    height,
];

module top_bottom_frame_rect() {
    square(top_bottom_frame_dimensions, true);
}

module left_right_frame_rect() {
    square(left_right_frame_dimensions, true);
}

module front_back_frame_rect() {
    square(front_back_frame_dimensions, true);
}

module bottom_frame() {
    // prepare the frame with the fingers
    //clean_flashes()
    difference() {
        offset(
            delta = frame_thickness
        ) top_bottom_frame_rect();

        side_fingers(
            top_bottom_frame_dimensions,
            frame_thickness,
            2,
            true
        );
    }
}

module top_frame() {
    offset_val = bt_allowance;

    difference() {
        // why are you even going to write everything again? just use the bottom
        // frame
        bottom_frame();

        // prepare the button holes
        offset( delta = offset_val ) {
            bt_array() button_rect();

            fx_array() effects_rect();

            st_array() start_rect();
        }

        // prepare the knob holes
        offset( delta = flush_gap ) {
            knob_array() circle( d = knob_motor_hole_diameter );
        }

        // prepare the bolt holes
        // TODO: we still need the bolt holes
    }
}

module left_right_frame() {
    offset_val = frame_thickness + flush_gap;

    difference() {
        // prepare the frame with the fingers
        join_close_objects(0.25) {
            left_right_frame_rect();

            side_fingers(
                left_right_frame_dimensions,
                frame_thickness,
                2,
                false
            );
        }

        // prepare the strap holes
        // TODO: where are the strap holes?

        // prepare the bolt holes
        // TODO: we still need the bolt holes
    }
}

module back_frame() {
    // prepare the frame with the fingers
    join_close_objects(0.25) {
        front_back_frame_rect();

        side_fingers(
            front_back_frame_dimensions,
            frame_thickness,
            2,
            false
        );
    }
}

module front_frame() {
    difference() {
        back_frame();

        // prepare the cord hole
        // TODO: where's the cord hole?

        // prepare the bolt holes
        // TODO: where are the bolt holes?
    }
}

module bt_strips() {
    translate([
        0,
        frame_thickness / 2,
    ]) bt_array(
    ) square([frame_thickness * 2 + bt_side, frame_thickness], true);
}

module bt_single_strip_hack() {
    join_close_objects( // this is the hack just to combine the strips
    // into a single strip
        8 // TODO: we need a better, calculated number than 8
    ) bt_strips();
}

module bridge_pillar() {
    rotate(
        90,
        [1, 0, 0]
    ) join_close_objects(0.1) {
        bt_strips();
        
        scale([ // extend the length of the pillar to the bottom
            1,
            -(height + frame_thickness) / frame_thickness,
        ]) bt_single_strip_hack();
    }
}

module bt_northern_bridge_pillar() {
    translate([
        0,
        (bt_side / 2 + frame_thickness + flush_gap)
    ]) bridge_pillar();
}

module bt_southern_bridge_pillar() {
    translate([
        0,
        -(bt_side / 2 + frame_thickness + flush_gap)
    ]) bridge_pillar();
}

module bt_bridge_path() {
    width = bt_side + frame_thickness * 2;
    
    translate([
        0,
        0,
        -10 // TODO: this number is arbitrary for now; it should be calculated
    ]) difference() {
        // the actual bridge
        translate([
            0,
            -width / 2,
        ]) scale([
            1,
            width / frame_thickness,
        ]) bt_single_strip_hack();

        // the cherry holes
        bt_array() cherry_hole();

        // TODO: we still need to subtract the path the buttons' legs will go
    }
}

module bt_bridge() {
    bt_northern_bridge_pillar();
    bt_southern_bridge_pillar();
    bt_bridge_path();
}

module fx_strips( offset = true ) {
    translate([
        0,
        0,
    ]) fx_array(
        offset
    ) square([frame_thickness * 2 + fx_length, frame_thickness], true);
}

module fx_single_strip_hack( offset = true ) {
    join_close_objects( // this is the hack just to combine the strips
    // into a single strip
        51 // TODO: we need a better, calculated number than 51
    ) fx_strips( offset );
}

module fx_bridge_pillar() {
    translate([
        0,
        -bt_center_to_fx_center,
    ]) rotate(
        90,
        [1, 0, 0]
    ) translate([
        0,
        frame_thickness / 2
    ]) join_close_objects(0.1) {
        fx_strips( false );
        
        translate([
            0,
            -height / 2 - frame_thickness,
        ]) scale([ // extend the length of the pillar to the bottom
            1,
            -(height + frame_thickness) / frame_thickness,
        ]) fx_strips( false );
    }
}

module fx_northern_bridge_pillar() {
    translate([
        0,
        fx_width / 2 + frame_thickness
    ]) fx_bridge_pillar();
}

module fx_southern_bridge_pillar() {
    translate([
        0,
        -(fx_width / 2 + frame_thickness)
    ]) fx_bridge_pillar();
}

module fx_bridge_path() {
    width = fx_width + frame_thickness * 2;

    translate([
        0,
        -bt_center_to_fx_center + fx_width / 2 - frame_thickness * 2,
        -10 // todo: this number is arbitrary for now; it should be calculated
    ]) difference() {
        scale([
            1,
            width / frame_thickness,
        ]) fx_strips(false);

        fx_array(false) cherry_hole();
    }
}

module fx_bridge() {
    fx_northern_bridge_pillar();
    fx_southern_bridge_pillar();
    fx_bridge_path();
}

module st_bridge_pillar() {
    rotate(
        90,
        [1, 0, 0]
    ) translate([
        0,
        -(height - frame_thickness)/ 2,
    ]) square([st_side + frame_thickness * 2, height + frame_thickness], true);
}

module northern_st_bridge_pillar() {
    translate([
        0,
        bt_center_to_st_center + (st_side + frame_thickness + button_thickness) / 2,
    ]) st_bridge_pillar();
}

module southern_st_bridge_pillar() {
    translate([
        0,
        bt_center_to_st_center - (st_side + frame_thickness + button_thickness) / 2,
    ]) st_bridge_pillar();
}

module st_bridge_path() {
    width = fx_width + frame_thickness * 2;

    translate([
        0,
        bt_center_to_st_center + st_side / 2 - frame_thickness * 2,
        -10 // todo: this number is arbitrary for now; it should be calculated
    ]) difference() {
        square(st_side + frame_thickness * 2, true);

        st_array(false) cherry_hole();
    }
}

module st_bridge() {
    northern_st_bridge_pillar();
    southern_st_bridge_pillar();
    st_bridge_path();
}

module standard_snap_fit_prong() {
    scale(
        [1, 1/10.125]
    ) polygon([
        [0, 0],
        [0, 10],
        [-0.5, 10.125],
        [0, 11],
        [1/3, 11],
        [1, 0],
    ]);
}

module bt_buttoncap_top() {
    // we'll need a button
    // then trim off the sides to make the fingers
    // but we only need to trim off the left and right

    linear_extrude(
        height = button_thickness
    ) difference() {
        button_rect();

        side_fingers(
            [bt_side - button_thickness * 2, bt_side - button_thickness * 2],
            button_thickness + flush_gap,
            2,
            true
        );
    }
}

module bt_buttoncap_side_guard() {
    // the prongs' dimensions have to be defined...
    // the height of the prongs will be the sum of...
        // the thickness of the top of the buttoncap
        // the thickness of the design of the buttoncap
        // plunge distance
        // distance of the switch from the plunger base to the mount base
        // some extra distance
    rotate(
        90,
        [0, 1, 0]
    )
    rotate(
        90,
        [0, 0, 1]
    )
    translate([
        0,
        -cherry_frame_to_max_plunge / 2
    ])
    linear_extrude(height = button_thickness)
    join_close_objects() {
        // top
        side_fingers(
            [
                bt_side - button_thickness * 2,
                cherry_frame_to_max_plunge
            ],
            button_thickness,
            2,
            false,
            [false, false, false, true]
        );

        // left
        side_fingers(
            [
                bt_side - button_thickness * 2,
                cherry_frame_to_max_plunge
            ],
            button_thickness,
            1,
            true,
            [true, false, false, false]
        );

        // right
        side_fingers(
            [
                bt_side - button_thickness * 2,
                cherry_frame_to_max_plunge
            ],
            button_thickness,
            1,
            false,
            [false, false, true, false]
        );

        // center
        square(
            [
                bt_side - button_thickness * 2,
                cherry_frame_to_max_plunge
            ],
            true
        );

        // right prong
        translate([bt_side / 2, -3.4]) // what is this -3.4?
        scale([3, 20])
        rotate(180, [0, 0, 1])
        standard_snap_fit_prong();

        // left prong
        translate([-bt_side / 2, -3.4]) // what is this -3.4?
        scale([3, 20])
        rotate(180, [0, 0, 1])
        mirror([1, 0, 0])
        standard_snap_fit_prong();
    }
}

module bt_buttoncap_other_side() {
    rotate(
        90,
        [0, 1, 0]
    )
    rotate(
        90,
        [0, 0, 1]
    )
    translate([
        0,
        -cherry_frame_to_max_plunge / 2
    ])
    linear_extrude(height = button_thickness)
    join_close_objects() {
        side_fingers(
            [
                bt_side - button_thickness * 2,
                cherry_frame_to_max_plunge
            ],
            button_thickness,
            2,
            false,
            [false, false, false, true]
        );

        // left
        side_fingers(
            [
                bt_side - button_thickness * 2,
                cherry_frame_to_max_plunge
            ],
            button_thickness,
            1,
            false,
            [true, false, false, false]
        );

        // right
        side_fingers(
            [
                bt_side - button_thickness * 2,
                cherry_frame_to_max_plunge
            ],
            button_thickness,
            1,
            true,
            [false, false, true, false]
        );

        square(
            [
                bt_side - button_thickness * 2,
                cherry_frame_to_max_plunge
            ],
            true
        );
    }
}

module bt_buttoncap() {
    // top
    bt_buttoncap_top();

    // left
    translate([
        -bt_side / 2,
        0,
    ])
    mirror([
        0,
        1,
        0
    ])
    bt_buttoncap_side_guard();

    // right
    translate([
        bt_side / 2 - button_thickness,
        0
    ])
    bt_buttoncap_side_guard();

    // front
    translate([
        0,
        bt_side / 2 - button_thickness,
    ])
    rotate(90, [0, 0, 1])
    bt_buttoncap_other_side();

    // back
    translate([
        0,
        -bt_side / 2
    ])
    rotate(90, [0, 0, 1])
    mirror([
        0, 1, 0
    ])
    bt_buttoncap_other_side();
}

module fx_buttoncap_top() {
    linear_extrude(
        height = button_thickness
    ) difference() {
        effects_rect();

        side_fingers(
            [fx_length - button_thickness * 2, fx_width - button_thickness * 2],
            button_thickness + flush_gap,
            2,
            true
        );
    }
}

module fx_buttoncap_side_guard() {
    rotate(
        90,
        [0, 1, 0]
    )
    rotate(
        90,
        [0, 0, 1]
    )
    translate([
        0,
        -cherry_frame_to_max_plunge / 2,
    ])
    linear_extrude(height = button_thickness)
    join_close_objects() {
        // top
        side_fingers(
            [
                fx_width - button_thickness * 2,
                cherry_frame_to_max_plunge
            ],
            button_thickness,
            2,
            false,
            [false, false, false, true]
        );

        // left
        side_fingers(
            [
                fx_width - button_thickness * 2,
                cherry_frame_to_max_plunge
            ],
            button_thickness,
            1,
            true,
            [true, false, false, false]
        );

        // right
        side_fingers(
            [
                fx_width - button_thickness * 2,
                cherry_frame_to_max_plunge
            ],
            button_thickness,
            1,
            false,
            [false, false, true, false]
        );

        // center
        square(
            [
                fx_width - button_thickness * 2,
                cherry_frame_to_max_plunge
            ],
            true
        );

        // right prong
        translate([fx_width / 2, -3.4]) // what is this -3.4?
        scale([3, 20])
        rotate(180, [0, 0, 1])
        standard_snap_fit_prong();

        // left prong
        translate([-fx_width / 2, -3.4]) // what is this -3.4?
        scale([3, 20])
        rotate(180, [0, 0, 1])
        mirror([1, 0, 0])
        standard_snap_fit_prong();
    }
}

module fx_buttoncap_other_side() {
    rotate(
        90,
        [0, 1, 0]
    )
    rotate(
        90,
        [0, 0, 1]
    )
    translate([
        0,
        -cherry_frame_to_max_plunge / 2
    ])
    linear_extrude(height = button_thickness)
    join_close_objects() {
        side_fingers(
            [
                fx_length - button_thickness * 2,
                cherry_frame_to_max_plunge
            ],
            button_thickness,
            2,
            false,
            [false, false, false, true]
        );

        // left
        side_fingers(
            [
                fx_length - button_thickness * 2,
                cherry_frame_to_max_plunge
            ],
            button_thickness,
            1,
            false,
            [true, false, false, false]
        );

        // right
        side_fingers(
            [
                fx_length - button_thickness * 2,
                cherry_frame_to_max_plunge
            ],
            button_thickness,
            1,
            true,
            [false, false, true, false]
        );

        square(
            [
                fx_length - button_thickness * 2,
                cherry_frame_to_max_plunge
            ],
            true
        );
    }
}

module fx_buttoncap() {
    // top
    fx_buttoncap_top();

    // left
    translate([
        -fx_length / 2,
        0,
    ])
    mirror([
        0,
        1,
        0
    ])
    fx_buttoncap_side_guard();

    // right
    translate([
        fx_length / 2 - button_thickness,
        0
    ])
    fx_buttoncap_side_guard();

    // front
    translate([
        0,
        fx_width / 2 - button_thickness,
    ])
    rotate(90, [0, 0, 1])
    fx_buttoncap_other_side();

    // back
    translate([
        0,
        -fx_width / 2
    ])
    rotate(90, [0, 0, 1])
    mirror([
        0, 1, 0
    ])
    fx_buttoncap_other_side();
}

module st_buttoncap_top() {
    linear_extrude(
        height = button_thickness
    ) difference() {
        start_rect();

        side_fingers(
            [st_side - button_thickness * 2, st_side - button_thickness * 2],
            button_thickness + flush_gap,
            2,
            true
        );
    }
}

module st_buttoncap_side_guard() {
    rotate(
        90,
        [0, 1, 0]
    )
    rotate(
        90,
        [0, 0, 1]
    )
    translate([
        0,
        -cherry_frame_to_max_plunge / 2,
    ])
    linear_extrude(height = button_thickness)
    join_close_objects() {
        // top
        side_fingers(
            [
                st_side - button_thickness * 2,
                cherry_frame_to_max_plunge
            ],
            button_thickness,
            2,
            false,
            [false, false, false, true]
        );

        // left
        side_fingers(
            [
                st_side - button_thickness * 2,
                cherry_frame_to_max_plunge
            ],
            button_thickness,
            1,
            true,
            [true, false, false, false]
        );

        // right
        side_fingers(
            [
                st_side - button_thickness * 2,
                cherry_frame_to_max_plunge
            ],
            button_thickness,
            1,
            false,
            [false, false, true, false]
        );

        // center
        square(
            [
                st_side - button_thickness * 2,
                cherry_frame_to_max_plunge
            ],
            true
        );

        // right prong
        translate([st_side / 2, -3.4]) // what is this -3.4?
        scale([3, 20])
        rotate(180, [0, 0, 1])
        standard_snap_fit_prong();

        // left prong
        translate([-st_side / 2, -3.4]) // what is this -3.4?
        scale([3, 20])
        rotate(180, [0, 0, 1])
        mirror([1, 0, 0])
        standard_snap_fit_prong();
    }
}

module st_buttoncap_other_side() {
    rotate(
        90,
        [0, 1, 0]
    )
    rotate(
        90,
        [0, 0, 1]
    )
    translate([
        0,
        -cherry_frame_to_max_plunge / 2
    ])
    linear_extrude(height = button_thickness)
    join_close_objects() {
        side_fingers(
            [
                st_side - button_thickness * 2,
                cherry_frame_to_max_plunge
            ],
            button_thickness,
            2,
            false,
            [false, false, false, true]
        );

        // left
        side_fingers(
            [
                st_side - button_thickness * 2,
                cherry_frame_to_max_plunge
            ],
            button_thickness,
            1,
            false,
            [true, false, false, false]
        );

        // right
        side_fingers(
            [
                st_side - button_thickness * 2,
                cherry_frame_to_max_plunge
            ],
            button_thickness,
            1,
            true,
            [false, false, true, false]
        );

        square(
            [
                st_side - button_thickness * 2,
                cherry_frame_to_max_plunge
            ],
            true
        );
    }
}

module st_buttoncap() {
    // top
    st_buttoncap_top();

    // left
    translate([
        -st_side / 2,
        0,
    ])
    mirror([
        0,
        1,
        0
    ])
    st_buttoncap_side_guard();

    // right
    translate([
        st_side / 2 - button_thickness,
        0
    ])
    st_buttoncap_side_guard();

    // front
    translate([
        0,
        st_side / 2 - button_thickness,
    ])
    rotate(90, [0, 0, 1])
    st_buttoncap_other_side();

    // back
    translate([
        0,
        -st_side / 2
    ])
    rotate(90, [0, 0, 1])
    mirror([
        0, 1, 0
    ])
    st_buttoncap_other_side();
}

////////////////////////////////////////////////////////////////////////////////

module everything() {
    // position everything
    rainbow(sqrt(3) / 15, 1/3) {
        // top frame
        linear_extrude(
            height = frame_thickness
        ) top_frame();
        
        // bottom frame
        translate([
            0,
            0,
            -height,
        ]) rotate(
            180,
            [0, 1]
        ) linear_extrude(
            height = frame_thickness
        ) bottom_frame();

        // left frame
        translate([
            -top_bottom_frame_dimensions[0] / 2,
            0,
        ]) rotate(
            270,
            [0, 1]
        ) translate([
            -height / 2,
            0,
        ]) linear_extrude(
            height = frame_thickness
        ) left_right_frame();

        // right frame
        translate([
            top_bottom_frame_dimensions[0] / 2,
            0,
        ]) rotate(
            90,
            [0, 1]
        ) translate([
            height / 2,
            0,
        ]) linear_extrude(
            height = frame_thickness
        ) left_right_frame();

        // front frame
        translate([
            0,
            top_bottom_frame_dimensions[1] / 2,
        ]) rotate(
            270,
            [1, 0]
        )
        translate([
            0,
            height / 2,
        ]) linear_extrude(
            height = frame_thickness
        ) front_frame();

        // back frame
        translate([
            0,
            -top_bottom_frame_dimensions[1] / 2,
        ])
        rotate(
            90,
            [1, 0]
        ) translate([
            0,
            - height / 2,
        ]) linear_extrude(
            height = frame_thickness
        ) back_frame();

        // bt bridge
        bt_bridge();

        // fx bridge
        fx_bridge();

        // st bridge
        st_bridge();
        
        // bt
        translate([0, 0, frame_thickness - button_thickness + bt_plunge_distance])
        bt_array()
        bt_buttoncap();

        // fx
        translate([0, 0, frame_thickness - button_thickness + fx_plunge_distance])
        fx_array()
        fx_buttoncap();

        // st
        translate([0, 0, frame_thickness - button_thickness + st_plunge_distance])
        st_array()
        st_buttoncap();
    }
}

////////////////////////////////////////////////////////////////////////////////

/*
Heirarchy of needs:

> Controller
    > Top frame
        > BT hole
        > FX hole
        > ST hole
        > Finger joints (extruding)
            > Side
            > Corner
    > Front frame
        > Finger joints (extruding)
        > Cord hole
    > Back frame
        > Finger joints (extruding)
    > Left frame
        > Finger joints (extruding)
        > Strap hole
    > Right frame
        > Finger joints (extruding)
        > Strap hole
    > Bottom frame
        > Finger joints (extruding)
        > Holes for the bridges
    > Button bridges
        > Bridge
        > Pillars
        > Cross lap
        > Cherry holes
    > Buttons
        ! Finger joints (intruding)
        ! Creating the snap-fit joints
        ! Height consideration of the button given thickness, under thickness,
          Cherry MX height, etc.
        > BT
        > FX
        > ST
    > Knobs
        > Disc bridge
        > Number of discs to be used given a thickness
*/

everything();
