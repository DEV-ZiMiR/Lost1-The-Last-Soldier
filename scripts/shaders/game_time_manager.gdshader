shader_type canvas_item;

uniform float u_brightness = 1.0;
uniform float u_contrast  = 1.0;
uniform float u_saturation = 1.0;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform vec4  u_tint : source_color = vec4(1.0); // колірний тон

void fragment() {
    // беремо картинку сцени під цим CanvasLayer
    vec4 col = texture(SCREEN_TEXTURE, SCREEN_UV);

    // насиченість
    float grey = dot(col.rgb, vec3(0.2126, 0.7152, 0.0722));
    col.rgb = mix(vec3(grey), col.rgb, u_saturation);

    // контраст (навколо 0.5)
    col.rgb = (col.rgb - 0.5) * u_contrast + 0.5;

    // яскравість + тон
    col.rgb *= u_brightness;
    col.rgb *= u_tint.rgb;

    COLOR = col;
}
