function mm_per_inch() = 25.4;
function acrylic_density() = 1.18; // grams per cubic centimeter

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
        mm_per_inch(),
        mm_per_inch(),
        mm_per_inch()
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

// Converts an RGB color to HSV color
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

// Colors children by assigning a color per angle turn in the HSV color space to
// a child.
module rainbow(angle, alpha = 1) {
    // starting from bright red, color each element with a color obtained by
    // rotating the H in the HSL wheel (but you have to convert it to RGB first)

    for (i = [0: $children - 1]) {
        color(hsv(i * angle, a = alpha)) children(i);
    }
}

// Intersects all children to each other and creates a union out of them
module intersection_any() {
    if ($children == 0) {
        // do nothing
    }

    else if ($children == 1) {
        children(0);
    }

    else {
        for (i = [0: $children - 2]) {
            for (j = [i + 1: $children - 1]) {
                intersection() {
                    children(i);
                    children(j);
                }
            }
        }
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

// Creates a mockup of a Cherry MX switch
module cherry_mockup() {
    Z = 0.6140;
    P = 0.14;
    LB = 0.2;
    Pi = 0.13;
    B = 0.46;
    UB = B - 0.2;

    scale(mm_per_inch()) {
        // plunger
        translate([0, 0, UB])
        linear_extrude(P)
        square(Z / 2.5, true);

        // upper body
        linear_extrude(UB)
        square(Z, true);

        // lower body
        translate([0, 0, -LB])
        linear_extrude(LB)
        square(Z * 0.875, true);

        // pins
        translate([0, 0, -LB - Pi])
        linear_extrude(Pi)
        square(Z * 0.25, true);
    }
}

// Creates a linear array of objects
module linear_array(
    copies = [1, 1],
    distance = [0, 0],
    center = [false, false]
) {
    offset = [
        center[0] ? - (distance[0] * (copies[0] - 1)) / 2 : 0,
        center[1] ? - (distance[1] * (copies[1] - 1)) / 2 : 0,
    ];

    translate(
        offset
    ) for (i = [0 : 1 : copies[0] - 1]) {
        for (j = [0 : 1 : copies[1] - 1]) {
            translate([
                distance[0] * i,
                distance[1] * j,
                0,
            ]) {
                children();
            }
        }
    }
}

module high_def_circle(diameter, definition = 256) {
    scale(1 / definition)
    circle(d = diameter * definition);
}

module arduino_uno_screw_holes() {
    // coordinates are in inches; they will be scaled to mm later
    screw_1 = [0.55, 0.1];
    screw_2 = screw_1 + [2.05, 0.2];
    screw_3 = screw_2 + [0, 1.1];
    screw_4 = screw_3 + [-2, 0.6];

    scale(mm_per_inch()) {
        translate(screw_1)
        high_def_circle(0.125);

        translate(screw_2)
        high_def_circle(0.125);

        translate(screw_3)
        high_def_circle(0.125);

        translate(screw_4)
        high_def_circle(0.125);
    }
}

module oblong(diameter, length) {
    union() {
        translate([-length / 2, 0])
        high_def_circle(diameter);

        translate([length / 2, 0])
        high_def_circle(diameter);

        square([length, diameter], true);
    }
}
