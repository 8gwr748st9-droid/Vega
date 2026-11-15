shader_type canvas_item;
// Semi-realistic desert terrain, lit by a fixed sun from the upper left.
// TEXTURE = 64x64 map data: R = rock, G = Uralium density. Sampled with filtering so edges are smooth.

uniform sampler2D data_tex;
uniform sampler2D noise_big;
uniform sampler2D noise_fine;
uniform vec2 map_px = vec2(4096.0, 4096.0);
uniform vec3 sun_dir = vec3(-0.55, -0.6, 0.58);
uniform float time_s = 0.0;

float nb(vec2 p) { return texture(noise_big, p / 1500.0).r; }
float nm(vec2 p) { return texture(noise_big, p / 420.0).r; }
float nf(vec2 p) { return texture(noise_fine, p / 230.0).r; }

float rock_at(vec2 p) {
	float r = texture(data_tex, p / map_px).r;
	float n = (nf(p * 0.8) - 0.5) * 0.55 + (nm(p) - 0.5) * 0.35;
	return smoothstep(0.40, 0.60, r + n);
}

float height_at(vec2 p, float rock) {
	float dunes = nb(p) * 0.7 + nm(p) * 0.3;
	vec2 wind = normalize(vec2(0.82, 0.38));
	float warp = nm(p * 1.7) * 9.0 + nb(p) * 14.0;
	float ripple = sin(dot(p, wind) * 0.24 + warp) * 0.5 + 0.5;
	ripple = ripple * ripple * 0.05 * (1.0 - rock) * (0.5 + nm(p * 0.8));
	float rocky = rock * (1.0 + (nm(p * 1.3) - 0.5) * 0.30 + (nf(p * 0.5) - 0.5) * 0.10);
	return dunes * 0.55 + ripple + rocky * 1.1;
}

float ore_at(vec2 p) {
	float a = texture(data_tex, p / map_px).g;
	float edge = (nf(p * 0.9) - 0.5) * 0.9 + (nm(p * 1.5) - 0.5) * 1.0;
	return smoothstep(0.1, 0.5, a + edge);
}

float nug_at(vec2 p, float ore) {
	float big = texture(noise_fine, p / 85.0).r;
	float small = texture(noise_fine, p / 52.0 + vec2(0.5, 0.2)).r;
	float t = 0.69 - ore * 0.07;
	return max(smoothstep(t, t + 0.025, big), smoothstep(t + 0.01, t + 0.035, small) * 0.9) * ore;
}

void fragment() {
	vec2 p = UV * map_px;
	vec4 data = texture(data_tex, UV);
	float rock = rock_at(p);
	float h = height_at(p, rock);
	float e = 2.0;
	float hx = height_at(p + vec2(e, 0.0), rock_at(p + vec2(e, 0.0)));
	float hy = height_at(p + vec2(0.0, e), rock_at(p + vec2(0.0, e)));
	float k = mix(14.0, 6.0, rock);
	vec3 n = normalize(vec3(-(hx - h) / e * k, -(hy - h) / e * k, 1.0));
	vec3 L = normalize(sun_dir);   // points towards the sun
	vec3 lpos = L;

	// ---- albedo
	float fine = nf(p);
	float mid = nm(p);
	vec3 sand_a = vec3(0.86, 0.69, 0.48);
	vec3 sand_b = vec3(0.74, 0.55, 0.36);
	vec3 sand_c = vec3(0.92, 0.80, 0.60);
	vec3 sand = mix(sand_b, sand_a, smoothstep(0.3, 0.7, nb(p)));
	sand = mix(sand, sand_c, smoothstep(0.55, 0.85, mid) * 0.5);
	sand *= 0.94 + fine * 0.12;
	// fine grain speckle
	sand *= 0.96 + texture(noise_fine, p / 14.0).r * 0.08;

	float strata = sin(h * 22.0 + nm(p * 0.9) * 5.0) * 0.5 + 0.5;
	vec3 rock_a = vec3(0.44, 0.33, 0.26);
	vec3 rock_b = vec3(0.58, 0.44, 0.33);
	vec3 rock_col = mix(rock_a, rock_b, strata * 0.6 + nm(p * 2.5) * 0.4);
	rock_col *= 0.95 + texture(noise_fine, p / 40.0).r * 0.1;
	float crack1 = smoothstep(0.012, 0.0, abs(texture(noise_fine, p / 320.0).r - 0.5));
	float crack2 = smoothstep(0.008, 0.0, abs(texture(noise_fine, p / 130.0 + vec2(0.3, 0.7)).r - 0.5));
	rock_col *= 1.0 - max(crack1, crack2 * 0.6) * 0.5;
	// pebbles on the rock
	float pebble = smoothstep(0.86, 0.9, texture(noise_fine, p / 64.0).r);
	rock_col = mix(rock_col, rock_col * 0.75, pebble * rock);
	vec3 albedo = mix(sand, rock_col, rock);

	// ---- Uralium: red metal ore lying on the sand (stain + scattered nuggets)
	float ore = ore_at(p) * (1.0 - rock);
	vec3 stain = mix(albedo, vec3(0.56, 0.27, 0.19), 0.65);
	albedo = mix(albedo, stain, ore * (0.45 + 0.55 * smoothstep(0.35, 0.65, nm(p * 2.2))));
	float nug = nug_at(p, ore);
	// nuggets cast a small shadow away from the sun
	float nug_shadow = clamp(nug_at(p + vec2(-2.5, -2.5), ore) - nug, 0.0, 1.0);
	albedo *= 1.0 - nug_shadow * 0.45;
	// lit top-left rim, darker lower-right: reads as a rounded lump of metal
	float rim = clamp(nug - nug_at(p + vec2(2.0, 2.0), ore), 0.0, 1.0);
	vec3 ur_col = mix(vec3(0.30, 0.04, 0.04), vec3(0.70, 0.12, 0.08), texture(noise_fine, p / 30.0).r);
	ur_col = mix(ur_col, vec3(0.95, 0.45, 0.35), rim * 0.6);
	albedo = mix(albedo, ur_col, nug);
	float ur = nug;

	// ---- lighting
	float diff = max(dot(n, lpos), 0.0);
	// cliff shadow: sand lying just "downwind" of the sun from rock
	vec2 back = normalize(vec2(L.x, L.y)) * -1.0;
	float caster = max(rock_at(p - back * 14.0), rock_at(p - back * 26.0) * 0.8);
	float shadow = clamp(caster - rock, 0.0, 1.0) * 0.55;
	vec3 ambient = vec3(0.50, 0.50, 0.58);
	vec3 sun_col = vec3(1.08, 0.98, 0.84);
	vec3 col = albedo * (ambient + sun_col * diff * 0.72 * (1.0 - shadow));

	// metallic glints on Uralium
	vec3 half_v = normalize(lpos + vec3(0.0, 0.0, 1.0));
	vec3 gn = normalize(n + vec3(texture(noise_fine, p / 40.0).r - 0.5, texture(noise_fine, p / 40.0 + vec2(0.37, 0.11)).r - 0.5, 0.0) * 1.6);
	float spec = pow(max(dot(gn, half_v), 0.0), 40.0) * ur;
	col += vec3(1.0, 0.75, 0.65) * spec * 1.4;

	COLOR = vec4(col, 1.0);
}
