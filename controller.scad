// below are parameters you can set
// all measurements are in millimeters (mm). fuck inches.

button_thickness = 3; // for most intents and purposes, this CANNOT be greater
// than 3
frame_thickness = 3;
button_design_acrylic_thickness = frame_thickness; // unimplemented

include_button_border = false; // true is still unimplemented

bt_side = 50;
bt_count = 4;
bt_center_disparity = 77;
bt_plunge_distance = 2.625;
bt_guard_extrusion = 4;

fx_length = 40.5;
fx_width = 23.5;
fx_count = 2;
fx_center_disparity = 154; // TODO: this is always at the center of the BT's
fx_plunge_distance = 2.5;
fx_guard_extrusion = 3.75;

st_side = 25;
st_plunge_distance = 2.5;
st_guard_extrusion = 3.75;

bt_center_to_st_center = 91.5;
bt_center_to_fx_center = 82;
bt_center_to_knob_center = 68;

knob_diameter = 30;
knob_height = 22;
knob_spindle_diameter = 2;
knob_spindle_length = 5;
knob_hole_diameter = 24.4 + 0.125;
knob_disparity = 359;

bt_allowance = 0.5; // used for the gap for the button to reduce friction
height = 32.5;

fb_margin = 20;
lr_margin = 20;

// if true, everything will be laid out flat, to be used as the template for the
// cut.
// if false, everything will be laid out as if assembled
dxf_view_mode = false;

// above are the values you can alter

////////////////////////////////////////////////////////////////////////////////

// DO NOT TOUCH ANYTHING BEYOND THIS LINE unless you know what you're doing

// on this section lies the supporting derived parameter

developer_holes = false;

cherry_frame_to_max_plunge = (0.46 - 0.2) * mm_per_inch();
cherry_plunge_depth = 0.14 * mm_per_inch();

bridge_cherry_height = frame_thickness - button_thickness - cherry_frame_to_max_plunge;
bridge_height = bridge_cherry_height - frame_thickness;

bt_buttoncap_height = frame_thickness - button_thickness + bt_plunge_distance + bt_guard_extrusion;
fx_buttoncap_height = frame_thickness - button_thickness + fx_plunge_distance + fx_guard_extrusion;
st_buttoncap_height = frame_thickness - button_thickness + st_plunge_distance + st_guard_extrusion;

snap_fit_scale = [3, 20];

prong_hole_dims = [
    snap_fit_scale[0],
    button_thickness,
];

function vert_prong_hole(plunge_distance) = [
    button_thickness,
    snap_fit_scale[1] * 2 / 12 + plunge_distance,
];

function vert_prong_hole_offset(plunge_distance) =
    snap_fit_scale[1] * 11 / 12 + // TODO: this math is wrong
    vert_prong_hole(plunge_distance)[1];

////////////////////////////////////////////////////////////////////////////////

use <utils.scad>;

module clean_flashes(
    distance = 0.0625
) {
    join_close_objects(-distance) children();
}

// Creates a finger joint given a rectangle centered on origin, the thickness of
// the gap, and number of fingers.
module side_fingers(
    dims,
    thickness,
    count,
    flip,
    sides = [true, true, true, true],
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

    // start with left
    if (sides[0]) {
        translate([
            -dims[0] / 2 - thickness,
            -dims[1] / 2
        ]) scale([
            thickness, dims[1]
        ]) standard_side_fingers(count, flip);
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
        ]) standard_side_fingers(count, flip);
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
        ]) standard_side_fingers(count, flip);
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
        ]) standard_side_fingers(count, flip);
    }
}

button_dims = [bt_side, bt_side];
effects_dims = [fx_length, fx_width];
start_dims = [st_side, st_side];

// Creates the BT button (a simple square)
module button_rect() {
    square(button_dims, true);
}

// Creates the FX button (a simple rectangle)
module effects_rect() {
    square(effects_dims, true);
}

// Creates the ST button (a simple square)
module start_rect() {
    square(start_dims, true);
}

// Creates the needed transformation for the BT buttons given a reference object
module bt_array( offset = true ) {
    // offset doesn't actually do anything

    linear_array(
        [4, 1],
        [bt_center_disparity, 0],
        [true, true]
    ) children();
}

// Creates the needed transformation for the FX buttons given a reference object
module fx_array( offset = true ) {
    translate([
        0,
        offset ? -bt_center_to_fx_center : 0,
    ]) linear_array(
        [2, 1],
        [fx_center_disparity, 0],
        [true, true]
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
    ]) linear_array(
        [2, 1],
        [knob_disparity, 0],
        [true, true]
    ) children();
}

top_bottom_frame_dimensions = [
    knob_hole_diameter + knob_disparity + lr_margin * 2,

    frame_thickness + st_side / 2 + bt_center_to_st_center + fb_margin * 2
        + bt_center_to_fx_center + fx_width / 2 + frame_thickness
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

module basic_top_bottom_frame() {
    clean_flashes()
    difference() {
        // create the frame rectangle
        offset(
            delta = frame_thickness
        ) top_bottom_frame_rect();

        // create the fingers
        side_fingers(
            top_bottom_frame_dimensions,
            frame_thickness,
            2,
            true
        );
    }
}

module bottom_frame() {
    difference() {
        basic_top_bottom_frame();

        // create the bt pillar holes
        bt_array(
        ) linear_array(
            [1, 2],
            [0, bt_side + frame_thickness + bt_allowance * 2],
            [false, true]
        ) square(
            [bt_side / 3, frame_thickness],
            true
        );

        // create the fx pillar holes
        fx_array(
        ) linear_array(
            [1, 2],
            [0, fx_width + frame_thickness + bt_allowance * 2],
            [false, true]
        ) square(
            [fx_length / 3, frame_thickness],
            true
        );
        
        // create the st pillar holes
        st_array(
        ) linear_array(
            [1, 2],
            [0, st_side + frame_thickness + bt_allowance * 2],
            [false, true]
        ) square(
            [st_side / 3, frame_thickness],
            true
        );

        // create the arduino uno screw holes
        translate([
            st_side / 2 - 62.5,
            top_bottom_frame_dimensions[1] / 2 - 70
        ]) rotate(0, [0, 0, 1])
        mirror([1, 0, 0])
        arduino_uno_screw_holes();
    }
}

module top_frame() {
    offset_val = bt_allowance;

    difference() {
        basic_top_bottom_frame();

        // prepare the button holes
        offset( delta = offset_val ) {
            bt_array(
            ) square(
                button_dims + [0, (frame_thickness) * 2],
                true
            );

            fx_array(
            ) square(
                effects_dims + [0, (frame_thickness) * 2],
                true
            );

            st_array(
            ) square(
                start_dims + [0, (frame_thickness) * 2],
                true
            );
        }

        // prepare the knob holes
        knob_array() high_def_circle( knob_hole_diameter );

        // developer holes only
        if (developer_holes) {
            // bottom left
            translate(-top_bottom_frame_dimensions / 2)
            square(5);

            // top left
            translate([
                -top_bottom_frame_dimensions[0] / 2,
                top_bottom_frame_dimensions[1] / 2 - 5
            ])
            square(5);

            // top right
            translate([
                top_bottom_frame_dimensions[0] / 2 - 5,
                top_bottom_frame_dimensions[1] / 2 - 5
            ])
            square(5);

            // bottom right
            translate([
                top_bottom_frame_dimensions[0] / 2 - 5,
                -top_bottom_frame_dimensions[1] / 2
            ])
            square(5);
        }
    }
}

module left_right_frame() {
    offset_val = frame_thickness;

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

        // strap holes
        linear_array([2, 1], [10, 0], [true, true])
        rotate(90, [0, 0, 1])
        oblong(2.5, 35);
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

        high_def_circle(15);
    }
}

module bt_strips(height = frame_thickness) {
    bt_array(
    ) translate([
        0,
        height / 2
    ]) square([bt_side, height], true);
}

module bt_bridge_pillar() {
    difference() {
        join_close_objects() {
            // the finger extrusions towards the top frame
            bt_strips(frame_thickness + bt_guard_extrusion);
            
            // main body of the pillar
            // join the walls so that they are one contiguous piece using
            // join_close_objects()
            join_close_objects(
                (bt_center_disparity - bt_side) / 2
            ) bt_array(
            ) translate([
                0,
                -height / 2
            ]) square(
                [bt_side + frame_thickness * 2, height],
                true
            );

            // the finger extrusions towards the bottom frame
            bt_array()
            translate([
                0,
                -height - frame_thickness / 2
            ]) square([bt_side / 3, frame_thickness], true);
        };

        // add the hole for the fingers of the bridge path
        bt_array(
        ) translate([
            0,
            bridge_height + frame_thickness / 2,
        ]) square([
            bt_side / 2,
            frame_thickness,
        ], true);

        // add the vertical hole for the snap fit prongs
        bt_array(
        ) offset(
            delta = bt_allowance
        ) {
            vph = vert_prong_hole(bt_plunge_distance);

            linear_array(
                [2, 1],
                [bt_side - vph[0], 0]
            ) translate([
                -bt_side / 2,
                -vert_prong_hole_offset(bt_plunge_distance) + bt_guard_extrusion
            ]) square(vph);
        };

        // add a hole in the middle so wires can pass through the center
        translate([0, -height / 2])
        high_def_circle(15);
    }
}

module bt_bridge_path() {
    width = bt_side ;// + frame_thickness * 2;
    
    join_close_objects() {
        bt_array() {
            // fingers, front and back
            // the linear array creates the two fingers
            linear_array(
                [1, 2],
                [0, - (bt_side + frame_thickness)]
            ) translate([
                0,
                (bt_side + frame_thickness) / 2
            ]) square([
                bt_side / 2,
                frame_thickness + bt_allowance * 2,
            ], true);
        }

        // bridge path
        difference() {
            // the actual bridge
            // join the mounts so that they are one contiguous piece using
            // join_close_objects()
            join_close_objects(
                (bt_center_disparity - bt_side) / 2
            ) bt_array(
            ) square(
                button_dims + [bt_allowance, bt_allowance] * 2,
                true
            );

            // the cherry holes
            bt_array() cherry_hole();

            // the leg holes
            bt_array()
            translate([
                -bt_side / 2,
                -bt_side / 2,
            ]) offset(
                delta = bt_allowance
            ) linear_array(
                [2, 2],
                button_dims - prong_hole_dims
            ) square(prong_hole_dims);
        }
    }
}

module bt_bridge() {
    // bridge pillars
    translate([
        0, -bt_side / 2 - bt_allowance
    ]) linear_array(
        [1, 2],
        [0, bt_side + frame_thickness + bt_allowance * 2]
    ) rotate(
        90,
        [1, 0, 0]
    ) linear_extrude(
        height = frame_thickness
    ) bt_bridge_pillar();

    // bridge path
    translate([
        0,
        0,
        bridge_height,
    ]) linear_extrude(
        height = frame_thickness
    ) bt_bridge_path();
}

module fx_strips(height = frame_thickness) {
    square([fx_length, height], true);
}

module fx_bridge_pillar() {
    difference() {
        join_close_objects() {
            // main body of the pillar
            translate([
                0,
                -height / 2
            ]) square(
                [fx_length + frame_thickness * 2, height],
                true
            );

            // the finger extrusions towards the top frame
            translate([
                0,
                (frame_thickness + fx_guard_extrusion) / 2
            ]) fx_strips(frame_thickness + fx_guard_extrusion);

            // the finger extrusions towards the bottom frame
            translate([
                0,
                -height - frame_thickness / 2
            ]) square([fx_length / 3, frame_thickness], true);
        }

        // add the hole for the fingers of the bridge path
        translate([
            0,
            bridge_height + frame_thickness / 2,
        ]) square([
            fx_length / 2,
            frame_thickness
        ], true);

        // add the vertical hole for the snap fit prongs
        offset(
            delta = bt_allowance
        ) {
            vph = vert_prong_hole(fx_plunge_distance);

            linear_array(
                [2, 1],
                [fx_length - vph[0], 0]
            ) translate([
                -fx_length / 2,
                -vert_prong_hole_offset(fx_plunge_distance) + fx_guard_extrusion
            ]) square(vph);
        };
    }
}

module fx_bridge_path() {
    join_close_objects() {
        // fingers, front and back
        // the linear array creates the two fingers
        linear_array(
            [1, 2],
            [0, - (fx_width + frame_thickness)]
        ) translate([
            0,
            (fx_width + frame_thickness) / 2
        ]) square([
            fx_length / 2,
            frame_thickness + bt_allowance * 2,
        ], true);

        // bridge path
        difference() {
            // the actual bridge
            square(
                effects_dims + [bt_allowance, bt_allowance] * 2,
                true
            );

            // the cherry holes
            cherry_hole();

            // the leg holes
            translate(
                -effects_dims / 2
            ) offset(
                delta = bt_allowance
            ) linear_array(
                [2, 2],
                effects_dims - prong_hole_dims
            ) square(prong_hole_dims);
        }
    }
}

module fx_bridge() {
    // bridge pillars
    fx_array(
    ) translate([
        0,
        -fx_width / 2 - bt_allowance
    ]) linear_array(
        [1, 2],
        [0, fx_width + frame_thickness + bt_allowance * 2]
    ) rotate(
        90,
        [1, 0, 0]
    ) linear_extrude(
        height = frame_thickness
    ) fx_bridge_pillar();

    // bridge path
    fx_array()
    translate([
        0,
        0,
        bridge_height,
    ]) linear_extrude(
        height = frame_thickness
    ) fx_bridge_path();
}

module st_bridge_pillar() {
    difference() {
        join_close_objects() {
            // main body of the pillar
            translate([
                0,
                -height / 2,
            ]) square(
                [st_side + frame_thickness * 2, height],
                true
            );
            
            // the finger extrusions towards the top of the frame
            translate([
                0,
                (frame_thickness + st_guard_extrusion) / 2
            ]) square([st_side, frame_thickness + st_guard_extrusion], true);

            // the finger extrusions towards the bottom frame
            translate([
                0,
                -height - frame_thickness / 2
            ]) square([st_side / 3, frame_thickness], true);
        }

        // add the hole for the fingers of the bridge path
        translate([
            0,
            bridge_height + frame_thickness / 2,
        ]) square(
            [st_side / 2, frame_thickness],
            true
        );

        // add the vertical hole for the snap fit prongs
        offset(
            delta = bt_allowance
        ) {
            vph = vert_prong_hole(st_plunge_distance);

            linear_array(
                [2, 1],
                [st_side - vph[0], 0]
            ) translate([
                -st_side / 2,
                -vert_prong_hole_offset(st_plunge_distance) + st_guard_extrusion
            ]) square(vph);
        }
    }
}

module st_bridge_path() {
    join_close_objects() {
        // fingers, front and back
        // the linear array creates the two fingers
        linear_array(
            [1, 2],
            [0, - (st_side + frame_thickness)]
        ) translate([
            0,
            (st_side + frame_thickness) / 2
        ]) square([
            st_side / 2,
            frame_thickness + bt_allowance * 2,
        ], true);

        // bridge path
        difference() {
            // the actual bridge
            square(
                start_dims + [bt_allowance, bt_allowance] * 2,
                true
            );

            // the cherry holes
            cherry_hole();

            // the leg holes
            translate(
                -start_dims / 2
            ) offset(
                delta = bt_allowance
            ) linear_array(
                [2, 2],
                start_dims - prong_hole_dims
            ) square(prong_hole_dims);
        }
    }

}

module st_bridge() {
    // bridge pillars
    st_array(
    ) translate([
        0,
        -st_side / 2 - bt_allowance
    ]) linear_array(
        [1, 2],
        [0, st_side + frame_thickness + bt_allowance * 2]
    ) rotate(
        90,
        [1, 0, 0]
    ) linear_extrude(
        height = frame_thickness
    ) st_bridge_pillar();

    // bridge path
    st_array()
    translate([
        0,
        0,
        bridge_height,
    ]) linear_extrude(
        height = frame_thickness
    ) st_bridge_path();
}

module standard_snap_fit_prong() {
    scale(
        [1, 1/12]
    ) polygon([
        [0, 0],
        [0, 10],
        [-0.5, 11],
        [0, 12],
        [1/3, 12],
        [1, 0],
    ]);
}

module buttoncap(
    dims,
    button_thickness,
    dxf_view = false,
) {
    module buttoncap_top() {
        linear_extrude(
            height = button_thickness
        ) clean_flashes(
        ) difference() {
            square(dims, true);

            side_fingers(
                dims - [button_thickness, button_thickness] * 2,
                button_thickness,
                2,
                true
            );
        }
    }
    
    module buttoncap_prong_side() {
        // the prongs' dimensions have to be defined...
        // the height of the prongs will be the sum of...
            // the thickness of the top of the buttoncap
            // the thickness of the design of the buttoncap
            // plunge distance
            // distance of the switch from the plunger base to the mount base
            // some extra distance
        
        rect_dims = [
            dims[1] - button_thickness * 2,
            cherry_frame_to_max_plunge,
        ];

        rotate(
            90,
            [0, 1, 0]
        ) rotate(
            90,
            [0, 0, 1]
        ) translate([
            0,
            -cherry_frame_to_max_plunge / 2
        ]) linear_extrude(
            height = button_thickness
        ) join_close_objects() {
            // top
            side_fingers(
                rect_dims,
                button_thickness,
                2,
                false,
                [false, false, false, true]
            );

            // left
            side_fingers(
                rect_dims,
                button_thickness,
                1,
                true,
                [true, false, false, false]
            );

            // right
            side_fingers(
                rect_dims,
                button_thickness,
                1,
                false,
                [false, false, true, false]
            );

            // center
            square(rect_dims, true);

            // right prong
            translate([dims[1] / 2, -3.4]) // TODO: what is this -3.4?
            scale(snap_fit_scale)
            rotate(180, [0, 0, 1])
            standard_snap_fit_prong();

            // left prong
            translate([-dims[1] / 2, -3.4]) // TODO: what is this -3.4?
            scale(snap_fit_scale)
            rotate(180, [0, 0, 1])
            mirror([1, 0, 0])
            standard_snap_fit_prong();
        }
    }

    module buttoncap_stub_side() {
        rect_dims = [
            dims[0] - button_thickness * 2,
            cherry_frame_to_max_plunge,
        ];

        rotate(
            90,
            [0, 1, 0]
        ) rotate(
            90,
            [0, 0, 1]
        ) translate([
            0,
            -cherry_frame_to_max_plunge / 2
        ]) linear_extrude(
            height = button_thickness
        ) join_close_objects() {
            // top
            side_fingers(
                rect_dims,
                button_thickness,
                2,
                false,
                [false, false, false, true]
            );

            // left
            side_fingers(
                rect_dims,
                button_thickness,
                1,
                false,
                [true, false, false, false]
            );

            // right
            side_fingers(
                rect_dims,
                button_thickness,
                1,
                true,
                [false, false, true, false]
            );

            square(rect_dims, true);
        }
    }

    if (!dxf_view) {
        // top
        buttoncap_top();

        // left
        translate([
            -dims[0] / 2,
            0
        ]) mirror([
            0,
            1,
            0,
        ]) buttoncap_prong_side();

        // right
        translate([
            dims[0] / 2 - button_thickness,
            0
        ]) buttoncap_prong_side();

        // front
        translate([
            0,
            dims[1] / 2 - button_thickness,
        ]) rotate(
            90,
            [0, 0, 1]
        ) buttoncap_stub_side();

        // back
        translate([
            0,
            -dims[1] / 2,
        ]) rotate(
            90,
            [0, 0, 1]
        ) mirror([
            0, 1, 0
        ]) buttoncap_stub_side();
    }

    else {
        // top
        projection()
        buttoncap_top();

        // left
        projection()
        translate([-dims[0] * 0.75, 0])
        mirror([0, 1, 0])
        //rotate(90, [0, 0, 1])
        rotate(90, [0, 1, 0])
        buttoncap_prong_side();

        // right
        projection()
        translate([dims[0] * 0.75, 0])
        //rotate(90, [0, 0, 1])
        rotate(-90, [0, 1, 0])
        buttoncap_prong_side();

        // front
        projection()
        translate([0, dims[1] * 0.75])
        rotate(90, [0, 0, 1])
        rotate(-90, [0, 1, 0])
        buttoncap_stub_side();

        // back
        projection()
        translate([0, -dims[1] * 0.75])
        rotate(90, [0, 0, 1])
        rotate(90, [0, 1, 0])
        mirror([0, 1, 0])
        buttoncap_stub_side();
    }
}

module knob_disk_array(direction = [0, 0, 1], extrude = true) {
    function linear_mul(x, y) =
        [ for (i = [0 : 1 : min(len(x), len(y)) - 1]) x[i] * y[i] ];

    thicker_than_spindle = frame_thickness > knob_spindle_length;

    holed_count = thicker_than_spindle
        ? 1
        : floor(knob_spindle_length / frame_thickness);

    top_spindle_height = thicker_than_spindle
        ? frame_thickness
        : knob_spindle_length;

    disk_count_after_holed =
        round((knob_height - top_spindle_height) / frame_thickness);

    array_multiplier = [knob_diameter, knob_diameter, frame_thickness];

    for (i = [0 : 1 : holed_count - 1]) {
        linear_extrude(frame_thickness)
        translate(linear_mul(array_multiplier, direction) * i)
        difference() {
            high_def_circle(knob_diameter);
            high_def_circle(knob_spindle_diameter);
        }
    }

    for (i = [holed_count : 1 : holed_count + disk_count_after_holed]) {
        translate(linear_mul(array_multiplier, direction) * i)
        linear_extrude(height = frame_thickness)
        high_def_circle(knob_diameter);
    }
}

////////////////////////////////////////////////////////////////////////////////

module assembled_view() {
    // position everything
    rainbow(sqrt(3) / 15, 0.5) {
        // top frame
        linear_extrude(
            height = frame_thickness
        ) ;// top_frame();
        
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
        ) translate([
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
        translate([0, 0, bt_buttoncap_height])
        bt_array()
        buttoncap(button_dims, button_thickness);

        // fx
        translate([0, 0, fx_buttoncap_height])
        fx_array()
        buttoncap(effects_dims, button_thickness);

        // st
        translate([0, 0, st_buttoncap_height])
        st_array()
        ;//buttoncap(start_dims, button_thickness);

        // knobs
        translate([0, 0, frame_thickness])
        knob_array()
        knob_disk_array();

        // mockups
        bt_array() cherry_mockup();
        fx_array() cherry_mockup();
        st_array() cherry_mockup();
    }
}

module dxf_view() {
    top_frame();

    translate([0, -300])
    bottom_frame();

    translate([-250, 0])
    left_right_frame();

    translate([-300, 0])
    left_right_frame();

    translate([0, 180])
    front_frame();

    translate([0, 230])
    back_frame();

    translate([0, 300])
    bt_bridge_path();

    translate([0, 375])
    linear_array([1, 2], [0, 50])
    bt_bridge_pillar();

    translate([0, 560])
    linear_array([2, 1], [50, 0])
    fx_bridge_path();

    translate([0, 475])
    linear_array([2, 2], [60, 50])
    fx_bridge_pillar();

    translate([0, 600])
    st_bridge_path();

    translate([0, 675])
    linear_array([2, 1], [50, 0])
    st_bridge_pillar();

    // bt
    translate([0, -480])
    linear_array([4, 1], [150, 0], [true, true])
    buttoncap(button_dims, button_thickness, true);

    // fx
    translate([0, -575])
    linear_array([2, 1], [125, 0], [true, true])
    buttoncap(effects_dims, button_thickness, true);

    // st
    translate([0, -625])
    buttoncap(start_dims, button_thickness, true);

    // knob disk
    translate([250, 0])
    linear_array([2, 1], [knob_diameter + 5, 0])
    projection()
    knob_disk_array([0, 1.25, 0], false);
}

////////////////////////////////////////////////////////////////////////////////

if (dxf_view_mode) {
    dxf_view();
}

else {
    assembled_view();
}
