// Note that compiling a precision statement with Metal is not unsupported.
// It is possible to add the precision statememnt when only targeting OpenGL.

//precision mediump float;
precision highp float;

//uniform sampler2D u_texture;
//uniform vec2 outSampleHalfPixelOffset;
//uniform vec2 inSampleHalfPixelOffset;
//uniform vec2 tileSize;

void main(void)
{
  vec2 oneOutputPixel = outSampleHalfPixelOffset * 2.0;
  vec2 oneInputPixel = inSampleHalfPixelOffset * 2.0;
  
  // Convert normalized texture coord to whole number of render pixels
  
  vec2 outNumPixels = (v_tex_coord - outSampleHalfPixelOffset) / oneOutputPixel;
  outNumPixels = floor(outNumPixels + 0.5);
  
  // Convert whole number of render pixels to whole numer of sample pixels via mod() and round()
  
  vec2 modNumPixels = mod(outNumPixels, tileSize);
  modNumPixels = floor(modNumPixels + 0.5);
  
  vec2 lookupCoord = inSampleHalfPixelOffset + (modNumPixels * oneInputPixel);
  
  vec4 pix = texture2D(u_texture, lookupCoord);
  
  gl_FragColor = pix;
}
