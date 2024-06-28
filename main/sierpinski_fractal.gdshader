shader_type canvas_item;

// Camera state, set by fractal_navigation.gd
uniform vec3 cam_pos = vec3(0.0);
uniform mat3 cam_mat = mat3(0.0); // The camera basis matrix

// Screen size, set by set by fractal_navigation.gd
uniform float width = 1024.0;
uniform float height = 1024.0;

// Animation constants
const float shimmer_speed = 0.1;
const float glow_range = 0.1;

// Calculation constants
const float fov = 95.0;
const float universe_size = 7.0;
const float runaway_threshold = 8.0;

// Parameters
uniform int palette = 5;
uniform bool ambient_occlusion = true;
uniform bool glow = true;
uniform bool mirror = false;
uniform bool tetrehedron = true;
uniform float collision_threshold = 13e-4;

// http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
vec3 hsv2rgb(vec3 c) {
	vec4 k = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + k.xyz) * 6.0 - k.www);
	return c.z * mix(k.xxx, clamp(p - k.xxx, 0.0, 1.0), c.y);
}

vec3 get_color(int iter, vec3 ray_pos) {
	float x = float(iter) / 128.0;
	
	if (palette == 1) {
		return hsv2rgb(vec3(x + TIME * shimmer_speed, 0.65, 1.0));
	} else if (palette == 2) {
		return vec3(1.0);
	} else if (palette == 3) {
		if (iter == 128) {
			ray_pos = vec3(sin(TIME * shimmer_speed));
		}
		vec3 col = mod(ray_pos, 1.0);
		return hsv2rgb(vec3(col.r + col.g + col.b + x, 0.7, 1.0));
	} else if (palette == 4) { 
		// Scale x to increase the density of colors
		float y = x * 4.0;
		y -= floor(y);
		
		// Rather than let y jump directly from 1 to 0, double it to have a continuous change
		float wave_y = y < 0.5 ? y * 2.0 : 2.0 - 2.0 * y;
		wave_y *= 0.7;
		return vec3(wave_y, 0.5 + wave_y, 0.8 + wave_y);
	} else if (palette == 5) {
		float y = x * (4.0 + sin(TIME) * 2.0);
		y -= floor(y);
		float wave_y = y < 0.5 ? y * 2.0 : 2.0 - 2.0 * y;
		wave_y *= 0.45;
		return vec3(0.5 - wave_y, 0.0, 0.15 - wave_y);
	} else {
		return vec3(0.0);
	}
}

void rotate(inout vec3 p) {
	vec3 pt = p;
	float t = TIME / 5.0;
	p.y = cos(t) * p.y + sin(t) * p.z;
	p.z = -sin(t) * pt.y + cos(t) * pt.z;
	
	t *= 1.5;
	
	pt = p;
	p.x = cos(t) * pt.x - sin(t) * pt.z;
	p.z = sin(t) * pt.x + cos(t) * pt.z;
}

//http://blog.hvidtfeldts.net/index.php/2011/08/distance-estimated-3d-fractals-iii-folding-space/
float tetrahedron_de(vec3 p) {
	if (mirror) {
		p = mod(p, universe_size) - vec3(universe_size / 2.0);
	}
	rotate(p);
	
	vec3 offset = vec3(1.0);
	float scale = 2.0; 
	for (int i = 0; i < 16; i++) {
		if(p.x + p.y < 0.0) p.xy = -p.yx; // fold 1
		if(p.x + p.z < 0.0) p.xz = -p.zx; // fold 2
		if(p.y + p.z < 0.0) p.zy = -p.yz; // fold 3
		p = p * scale - offset * (scale - 1.0);
	}
	return length(p) * pow(scale, -float(16));
}

//http://www.fractalforums.com/ifs-iterated-function-systems/revenge-of-the-half-eaten-menger-sponge/15/
float mengersponge_de(vec3 p) { // by recursively digging a box
	if (mirror) {
		p = mod(p, universe_size) - vec3(universe_size / 2.0);
	}
	rotate(p);
	
	p = p * 0.5 + 0.5;
	vec3 q = abs(p - 0.5) - 0.5;
	float d1 = max(q.x, max(q.y, q.z)); // distance to the box
	float d = d1; // current computed distance
	float scale = 1.0;
	for (int i = 0; i < 5; i++) {
		vec3 pa = mod(p * 3.0 * scale, 3.0);
		scale *= 3.0;
		q = vec3(0.5) - abs(pa - 1.5);
		d1 = min(max(q.x, q.z), min(max(q.x, q.y), max(q.y, q.z))) / scale; //distance inside the 3 axis-aligned square tubes
		d = max(d, d1); //intersection
	}
	return d;
}

int march(inout vec3 ray_pos, vec3 ray_dir, inout float closest_dist) {
	float dist = universe_size;
	int iter = 0;
	
	// WebGL has a limitation that won't allow the shader to compile
	// if a non-constant is used in for-loops; 128 is `MAX_ITER`
	for (int i = 0; i < 128; i++) {
		dist = abs(tetrehedron ? mengersponge_de(ray_pos) : tetrahedron_de(ray_pos));
		closest_dist = min(closest_dist, dist);
		ray_pos += ray_dir * dist;
		
		// We can quit marching early if we are extremely far from the fractal
		if (dist > runaway_threshold) {
			iter = 128;
			break;
		}
		
		// Once we are close enough to the fractal, we say we "collided" with it
		if (dist < collision_threshold) {
			break;
		}
		iter++;
	}
	return iter;
}

// https://www.scratchapixel.com/lessons/3d-basic-rendering/ray-tracing-generating-camera-rays/generating-camera-rays.html
void fragment() {
	// Take the pixel position (UV) and convert it into a ray direction based 
	// on the camera's orientation
	vec3 ray_pos = cam_pos;
	float px = (2.0 * UV.x - 1.0) * tan(fov / 2.0 * PI / 180.0) * (width / height);
	float py = (1.0 - 2.0 * UV.y * tan(fov / 2.0 * PI / 180.0));
	vec3 ray_dir = vec3(px, py, -1);
	ray_dir = cam_mat * normalize(ray_dir);
	
	float closest_dist = universe_size;
	int iter = march(ray_pos, ray_dir, closest_dist);
	
	vec3 col = get_color(iter, ray_pos);
	
	// Color the fractal if we collided with it, otherwise create a glow with
	// the closest we ever got to the fractal
	COLOR.rgb = col;
	if (iter < 128) {
		if (ambient_occlusion) {
			COLOR.rgb *= vec3(1.0 - float(iter) / 128.0);
		}
	} else {
		if (glow) {
			COLOR.rgb *= (1.0 - pow(closest_dist, glow_range));
		} else {
			COLOR.rgb *= 0.0;
		}
	}
}