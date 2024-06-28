shader_type canvas_item;

uniform int max_iter = 64;

// Camera state, set by fractal_navigation.gd
uniform vec3 cam_pos = vec3(0.0);
uniform mat3 cam_mat = mat3(0.0); // The camera basis matrix

// Screen size, set by set by fractal_navigation.gd
uniform float width = 1024.0;
uniform float height = 1024.0;

// Animation constants
const float glow_range = 0.1;

// Calculation constants
const float fov = 95.0;
const float universe_size = 7.0;
const float runaway_threshold = 8.0;

// Parameters
uniform bool ambient_occlusion = true;
uniform bool glow = true;
uniform float collision_threshold = 1.3e-5;

vec3 get_color(int iter, vec3 ray_pos) {
	return vec3(1.0);
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

// http://blog.hvidtfeldts.net/index.php/2011/09/distance-estimated-3d-fractals-v-the-mandelbulb-different-de-approximations/
float mandelbulb_DE(vec3 p) {
	vec3 z = p;
	float dr = 1.0;
	float r = 0.0;
	for (int i = 0; i < 32; i++) {
		r = length(z);
		if (r>16.0) break;
		
		// convert to polar coordinates
		float theta = acos(z.z/r);
		float phi = atan(z.y,z.x);
		dr =  pow( r, 8.0-1.0)*8.0*dr + 1.0;
		
		// scale and rotate the point
		float zr = pow( r,8);
		theta = theta*8.0;
		phi = phi*8.0;
		
		// convert back to cartesian coordinates
		z = zr*vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
		z += p;
	}
	return 0.5*log(r)*r/dr;
}

int march(inout vec3 ray_pos, vec3 ray_dir, inout float closest_dist) {
	float dist = universe_size;
	int iter = 0;
	
	for (int i = 0; i < max_iter; i++) {
		dist = abs(mandelbulb_DE(ray_pos));
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
	
	// Color the fractal if we collided with it, otherwise create a glow with
	// the closest we ever got to the fractal
	COLOR.rgb = get_color(iter, ray_pos);
	if (iter < max_iter) {
		if (ambient_occlusion) {
			COLOR.rgb *= vec3(1.0 - float(iter) / float(max_iter));
		}
	} else {
		if (glow) {
			COLOR.rgb *= (1.0 - pow(closest_dist, glow_range));
		} else {
			COLOR.rgb *= 0.0;
		}
	}
}