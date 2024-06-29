shader_type canvas_item;

group_uniforms detail;
uniform int max_iter = 128; // How many iterations an individual ray can march
uniform int max_bounce = 4; // How many times a ray can be reflected
uniform int light_iter = 64;
uniform float collision_threshold = 1.0e-3; // Distance where a ray is considered to have collided
uniform float normal_sample_length = 1.0e-2; // How far along a collided surface to move when sampling for a normal vector

group_uniforms fractal;
uniform int bulb_iter = 8; // Increase for more fractal detail, decrease for performance
uniform float bulb_power = 8.0; // Dimension of the fractal

group_uniforms camera;
uniform float fov = 95.0; // In degrees
uniform float runaway_threshold = 8.0; // Distance where a ray is considered far enough to stop iteration

group_uniforms light;
uniform vec3 light_ray = vec3(0.0, -1.0, 0.0);
uniform float light_dist = 8.0;

group_uniforms scene;
uniform vec3 sky_color: source_color;
uniform vec3 fractal_color: source_color;
uniform vec3 plane_normal = vec3(0.2, 1.0, 0.0);
uniform float plane_height = 1.1;
uniform vec3 plane_color: source_color;

// Updated by script only
group_uniforms internal;
uniform vec3 _cam_pos = vec3(0.0); // Camera position
uniform mat3 _cam_mat = mat3(0.0); // Camera basis matrix
uniform vec2 _screen_size;

// Returns distance estimate to infinite plane
float plane_DE(vec3 p) {
	return dot(p, normalize(plane_normal)) + plane_height;
}

// Returns distance estimate to fractal
// http://blog.hvidtfeldts.net/index.php/2011/09/distance-estimated-3d-fractals-v-the-mandelbulb-different-de-approximations/
float mandelbulb_DE(vec3 p) {
	vec3 z = p;
	float dr = 1.0;
	float r = 0.0;
	for (int i = 0; i < bulb_iter; i++) {
		r = length(z);
		if (r > 2.0)
			break;
		
		// convert to polar coordinates
		float theta = acos(z.z/r);
		float phi = atan(z.y, z.x);
		dr =  pow(r, bulb_power - 1.0) * bulb_power * dr + 1.0;
		
		// scale and rotate the point
		float zr = pow(r, bulb_power);
		theta = theta * bulb_power;
		phi = phi * bulb_power;
		
		// convert back to cartesian coordinates
		z = zr * vec3(sin(theta) * cos(phi), sin(phi) * sin(theta), cos(theta));
		z += p;
	}
	return 0.5 * log(r) * r/dr;
}

// Returns a vec4 of the color and distance to the closest object as rgba respectively
float world_DE(vec3 p, inout int collision_id) {
	float d1 = mandelbulb_DE(p);
	float d2 = plane_DE(p);
	if (d1 < d2) {
		collision_id = 0;
		return d1;
	} else {
		collision_id = 1;
		return d2;
	}
}

int march(inout vec3 ray_pos, vec3 ray_dir, inout int id) {
	float dist = 10000.0;
	int iter = 0;
	
	for (int i = 0; i < max_iter; i++) {
		dist = abs(world_DE(ray_pos, id));
		ray_pos += ray_dir * dist;
		
		// We can quit marching early if we are extremely far from the fractal
		if (dist > runaway_threshold) {
			iter = max_iter;
			break;
		}
		
		// Once we are close enough to the fractal, we say we collided with it
		if (dist < collision_threshold)
			break;
		iter++;
	}
	return iter;
}

// https://iquilezles.org/articles/rmshadows/
float soft_shadow(vec3 ray_pos, vec3 ray_dir, float light_sharpness) {
	float min_shadow = 1.0;
	float dist_from_surface = 0.0;
	for(int i = 0; i < light_iter; i++) {
		int _id;
		float dist = abs(world_DE(ray_pos, _id));
		if(dist < collision_threshold)
			return 0.0;
		if (dist > runaway_threshold * 4.0) {
			break;
		}
		ray_pos += ray_dir * dist;
		min_shadow = min(min_shadow, light_sharpness * dist/dist_from_surface);
		dist_from_surface += dist;
	}
	return min_shadow;
}

vec3 get_normal(vec3 ray_pos) {
	int _id;
	return normalize(
		vec3(world_DE(ray_pos + vec3(normal_sample_length, 0.0, 0.0), _id) - world_DE(ray_pos - vec3(normal_sample_length, 0.0, 0.0), _id),
			 world_DE(ray_pos + vec3(0.0, normal_sample_length, 0.0), _id) - world_DE(ray_pos - vec3(0.0, normal_sample_length, 0.0), _id),
			 world_DE(ray_pos + vec3(0.0, 0.0, normal_sample_length), _id) - world_DE(ray_pos - vec3(0.0, 0.0, normal_sample_length), _id)));
}

// https://www.scratchapixel.com/lessons/3d-basic-rendering/ray-tracing-generating-camera-rays/generating-camera-rays.html
vec3 get_color(vec2 uv) {
	// Take the pixel position (UV) and convert it into a ray direction based 
	// on the camera's orientation
	vec3 ray_pos = _cam_pos;
	float px = (2.0 * uv.x - 1.0) * tan(fov * PI / 360.0) * (_screen_size.x / _screen_size.y);
	float py = (1.0 - 2.0 * uv.y * tan(fov * PI / 360.0));
	vec3 ray_dir = vec3(px, py, -1);
	ray_dir = _cam_mat * normalize(ray_dir);
	
	vec3 final_color = sky_color;
	for (int i = 0; i < max_bounce; i++) {
		int id;
		int iter = march(ray_pos, ray_dir, id);
		if (iter == max_iter) 
			break;
		
		float light_sharpness = 0.0;
		float reflectivity = 0.0;
		float roughness = 0.0;
		vec3 albedo = vec3(0.0);
		if (id == 0) {
			albedo = fractal_color;
			reflectivity = 0.05;
			light_sharpness = 7.0;
			roughness = 0.8;
		} else {
			albedo = plane_color;
			reflectivity = 0.2;
			light_sharpness = 8.0;
			roughness = 0.8;
		}
		
		vec3 normal = get_normal(ray_pos);
		
		vec3 hit_color = albedo * soft_shadow(ray_pos + normal * collision_threshold * 4.0, -normalize(light_ray), light_sharpness);
		
		
		
		ray_dir = ray_dir - 2.0 * dot(ray_dir, normal) * normal;
		ray_pos += ray_dir * collision_threshold * 4.0;
		
		hit_color *= vec3(1.0 - float(iter) / float(max_iter));
		hit_color *= pow(max(0.0, dot(normal, -normalize(light_ray))), 1.0/2.2);
		
		float specular = dot(-normalize(light_ray), ray_dir);
		float specular_power = pow(25.0 * (roughness - 1.0), 2.0) + 2.0;
		hit_color += vec3(0.5) * pow(specular, specular_power);
		
		if (i == 0) 
			final_color = hit_color;
		final_color = mix(final_color, hit_color, reflectivity);
	}
	return final_color;
}

void fragment() {
	COLOR.rgb = get_color(UV);
}