
/*

	Oldschool Tube
	--------------

	An oldschool tube effect, with a few extra lines to bump it and light it up. Virtually 
    no different in concept to the more compact, minimal character versions.

	Aiekick asked about cylindrically wrapping a pattern - like Voronoi - onto a cyclinder, 
    so  I thought I'd put a simple example together and post it privately... However, I got
    a little carried away adding window dressing. It's still not particularly interesting, 
    but I liked the simple rendering style, so thought I'd release it publicly.

	Having said that, one minor point of interest is that the edging is done in the bump 
    routine. Most edging examples are raymarched and involved normal-based edge calculations,
    but this shows that you can have edging on the bump mapped part of the scene too. There 
    are much more interesting applications, and I'll give an example at a later date.


	
    Created in repsonse to the following:

    Voro Tri Tunnel - aiekick
    https://www.shadertoy.com/view/XtGGWy

	A rough explanation of the oldschool tunnel effect:

	Traced Minkowski Tube - Shane
    https://www.shadertoy.com/view/4lSXzh

    // Another example.
	Luminescent Tiles - Shane
	https://www.shadertoy.com/view/MtSXRm

*/

// Extra coloring. Done in haste, so it needs work. :) Using proper 
// materials would be better, but would complicate the code.
// Platimum: 0, Gold: 1, Gold and Blue: 2
#define COLOR 0


// 2D rotation. Always handy. Angle vector, courtesy of Fabrice.
mat2 rot( float th ){ vec2 a = sin(vec2(1.5707963, 0) + th); return mat2(a, -a.y, a.x); }


// Compact, self-contained version of IQ's 3D value noise function. I have a transparent noise
// example that explains it, if you require it.
float n3D(vec3 p){
    
	const vec3 s = vec3(7, 157, 113);
	vec3 ip = floor(p); p -= ip; 
    vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
    p = p*p*(3. - 2.*p); //p *= p*p*(p*(p * 6. - 15.) + 10.);
    h = mix(fract(sin(h)*43758.5453), fract(sin(h + s.x)*43758.5453), p.x);
    h.xy = mix(h.xz, h.yw, p.y);
    return mix(h.x, h.y, p.z); // Range: [0, 1].
}

// vec2 to vec2 hash.
vec2 hash22(vec2 p, float w) { 

    // The Voronoi pattern needs to be repeatable. Hence the "mod" line below.
    p = mod(p, w);
    // Faster, but doesn't disperse things quite as nicely. However, when framerate
    // is an issue, and it often is, this is a good one to use. Basically, it's a tweaked 
    // amalgamation I put together, based on a couple of other random algorithms I've 
    // seen around... so use it with caution, because I make a tonne of mistakes. :)
    float n = sin(dot(p, vec2(41, 289)));
    return fract(vec2(262144, 32768)*n)*.9 + .1; 
    
    // Animated.
    //p = fract(vec2(262144, 32768)*n); 
    // Note the ".45," insted of ".5" that you'd expect to see. When edging, it can open 
    // up the cells ever so slightly for a more even spread. In fact, lower numbers work 
    // even better, but then the random movement would become too restricted. Zero would 
    // give you square cells.
    //return sin( p*6.2831853 + iTime )*.45 + .5; 
    
}


float vx;
// 2D 2nd-order Voronoi: Obviously, this is just a rehash of IQ's original. I've tidied
// up those if-statements. Since there's less writing, it should go faster. That's how 
// it works, right? :)
//
float Voronoi(in vec2 p, float w){
    
    
	vec2 g = floor(p), o; p -= g;
	
	vec3 d = vec3(1.4142); // 1.4, etc. "d.z" holds the distance comparison value.
    
	for(int y=-1; y<=1; y++){
		for(int x=-1; x<=1; x++){
            
			o = vec2(x, y);
            o += hash22(g + o, w) - p;
            
			d.z = length(o);//(dot(o, o)); 
            
            // More distance metrics.
            //o = abs(o);
            //d.z = mix(max(abs(o.x)*.866025 + o.y*.5, -o.y), dot(o, o), .2);//
            //d.z = max(abs(o.x)*.866025 - o.y*.5, o.y);
            //d.z = max(abs(o.x) + o.y*.5, -(o.y)*.8660254);
            //d.z = max(o.x, o.y);
            //d.z = (o.x*.7 + o.y*.7);
            
            d.y = max(d.x, min(d.y, d.z));
            d.x = min(d.x, d.z); 
                       
		}
	}
 					 
	d/=1.4142;
    
    vx = d.x;
    
    d = smoothstep(0., 1., d);

    
    return max(d.y/1.333 - d.x, 0.)*1.333;
    
   
    //return d.y - d.x;
    
}

float objID;

// The bump mapping function.
float bumpFunction(in vec3 p){
    
    // Stock standard cylindrical mapping. This line here is pretty much
    // where all the oldschool tunnel examples stem from.
    vec2 uv = vec2(atan(p.y, p.x)/6.2831853, p.z/8.);
    
    float c = Voronoi(uv*16., 16.);

    objID = 0.;

    // The web section. Comment it out, if you're not sure what it does.
    if(c<.15) { c = abs(max(c, 0.01) - .3), objID = 1.; }
    
    return c;
   
}


// Standard function-based bump mapping function, with some edging added to the mix.
vec3 doBumpMap(in vec3 p, in vec3 n, float bumpfactor, inout float edge){
    
    vec2 e = vec2(2.5/iResolution.y, 0);
    
    float f = bumpFunction(p); 
    
    // Samples about the hit point in each of the axial directions.
    float fx = bumpFunction(p - e.xyy); // Same for the nearby sample in the X-direction.
    float fy = bumpFunction(p - e.yxy); // Same for the nearby sample in the Y-direction.
    float fz = bumpFunction(p - e.yyx); // Same for the nearby sample in the Y-direction.

    // Samples from the other side.
    float fx2 = bumpFunction(p + e.xyy); // Same for the nearby sample in the X-direction.
    float fy2 = bumpFunction(p + e.yxy); // Same for the nearby sample in the Y-direction.
    float fz2 = bumpFunction(p + e.yyx); // Same for the nearby sample in the Y-direction.
    
    // We made three extra function calls, so we may as well use them. Taking measurements
    // from either side of the hit point has a slight antialiasing effect.
    vec3 grad = (vec3(fx - fx2, fy - fy2, fz - fz2))/e.x/2.;   

    // Using the samples to provide an edge measurement.
    edge = abs(fx + fy + fz + fx2 + fy2 + fz2 - 6.*f);
    //edge = abs(fx + fx2 - f*2.) + abs(fy + fy2 - f*2.)+ abs(fz + fz2 - f*2.);
    edge = smoothstep(0., 1., edge/e.x);
          
    grad -= n*dot(n, grad);          
                      
    return normalize( n + grad*bumpfactor );
	
}


// The second function. This adds the swirly noise patterns to the webbing.
float bumpFunction2(in vec3 p){
    
    float c = n3D(p*16.); // Noise value.
    
    c = fract(c*4.); // Producing some repeat noise contour rings... Bad description. :)
    
    return min(c, c*(1. - c)*4.); // Smooth "fract." It's an old trick.
   
}

// A second function-based bump mapping function.
vec3 doBumpMap(in vec3 p, in vec3 n, float bumpfactor){
    
    vec2 e = vec2(2.5/iResolution.y, 0);
    float f = bumpFunction2(p); 
    
    float fx = bumpFunction2(p - e.xyy); // Same for the nearby sample in the X-direction.
    float fy = bumpFunction2(p - e.yxy); // Same for the nearby sample in the Y-direction.
    float fz = bumpFunction2(p - e.yyx); // Same for the nearby sample in the Y-direction.
    
    vec3 grad = (vec3(fx, fy, fz )-f)/e.x; 
          
    grad -= n*dot(n, grad);          
                      
    return normalize( n + grad*bumpfactor );
}
 

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    

    
    // Unit direction ray. Coyote's elegant version. So obvious, yet it never occurred
    // to me... or most others, it seems. :)
    vec3 rd = normalize(vec3(fragCoord - iResolution.xy*0.5, iResolution.y));
    
    rd.xy = rot(iTime*0.25)*rd.xy; // Look around, just to show it's a 3D effect.
    rd.xz = rot(iTime*0.125)*rd.xz;
    
    // Ray origin.
    vec3 ro = vec3(0.0, 0.0, iTime);
    
    // Screen color. Initialized to black.
    vec3 col = vec3(0);

	const float rad = 1.; // Initial cylinder radius.

    // Distance fromt the ray origin to the cylinder layer surface point. It's a cut down
    // version of a traced cylinder with its center fixed to the Z axis.
    float sDist = rad/max( length(rd.xy), 0.001 );

    // Surface position.
    vec3 sp = ro + rd*sDist;

    // Surface normal.
    vec3 sn = normalize(vec3(-sp.xy, 0.)); // Cylinder normal.

    // Bumpmapping (the Voronoi part) with some edge calculations included.
    float edge;
    sn = doBumpMap( sp, sn, .75, edge);
    
    // The object ID is calculated in the bump function. We save it here. Zero is the 
    // bulbous portion that gets lit up and one is the webbing.
    float svObjID = objID;
    
    // Secondary bump pattern on the webbing. Done separately, so as not to interfere
    // with the edge calculations.
    if(svObjID>.5) sn = doBumpMap( sp, sn, .003);
    
    // Some rough noise sprinkles. Note that a 3D noise function is being used. You could 
    // also cylindrically map a 2D noise function, but I thought this was less hassle.
    vec3 tex = vec3(1)*n3D(fract(sp)*192.);
    vec3 objCol = smoothstep(.1, .9, tex)*.8 + 1.;
    
    
    if(svObjID<.5) objCol *= vec3(.45, .425, .5); // The bulbs. Using a slightly darker tone.
    else objCol *= vec3(.68, .64, .75); // The Voroni web portion.
    
    #if COLOR == 1
    // Gold color scheme.
    if(svObjID>.5) objCol *= vec3(1.4, .8, .3);
    else objCol *= vec3(.5, 2., 5).zyx;
    #elif COLOR == 2
    // Egyptian look - gold and turquoise... or lapis lazuli, 
    // for the purists... Yeah, it needs work. :)
    if(svObjID>.5) objCol *= vec3(1, .8, .2)*1.35;
    else objCol *= vec3(.1, 2.5, 5);
 
    #endif

    // Lighting.
    //
    // The light. Placed near the ray origin, camera, etc. We're looking down both ends of 
    // the tunnel, so it helps to keep the light near the camera. A better alternative is to 
    // have two lights on either side, but I'm trying to keep it simple.
    vec3 lp = ro + vec3(0, .5, 0);
    vec3 ld = lp - sp; // Light direction.
    float dist = max(length(ld), 0.001); // Distance from light to the surface.
    ld /= dist; // Use the distance to normalize "ld."

    // Light attenuation, based on the distance above.
    float atten = 1.5/(1. + dist*.05 + dist*dist*0.075);
    
    // Use the bump texture to darken the crevices. Comment it out to see its effect.
    atten *= bumpFunction(sp)*.9 + .1;//getGrey(texCol(iChannel0, sp))*.5 + .5;


    float diff = max(dot(ld, sn), 0.); // Diffuse light value.
    diff = pow(diff, 8.)*0.66 + pow(diff, 16.)*0.34;  // Ramping it up.
    
    float spec = pow(max(dot(reflect(ld, sn), rd), 0.), 8.); // Specular light value.
    
    /////
    // The blinking light section. All of it is made up.
    // Basically, we're adding a unit refracted vector to the hit position, then passing it 
    // into a cylindrically mapped Voronoi function, smoothing, then colorizing.
    vec3 ref = sp + refract(rd, sn, 1./1.6);
    vec2 tuv = vec2(atan(ref.y, ref.x)/6.2832, ref.z/8.);
    float c2 = Voronoi(tuv*4. - vec2(1, .5)*iTime, 4.);
    c2 = smoothstep(0.8, 1., 1.-vx);
      
    // Fiery coloring.
    vec3 elec = (objCol*.7 + .3)*pow(min(vec3(1.5, 1, 1)*c2, 1.), vec3(1,  3, 8)); 
        
    if (svObjID<.5) objCol += elec*8.; // Add a lot of the color to the bulbs.
    else objCol += elec*2.; // Add a little to the webbing.
    //////////
    

    // Using the values above to produce the layer color.
    col += (objCol*(diff*vec3(1, .97, .92)*2. + 0.25) + vec3(1, .6, .2)*spec*2.)*atten;;

    // Adding some fake reflection to the walls.
    ref = reflect(rd, sn);
    float rc = n3D(ref*2.);
    col += col*smoothstep(.3, 1., rc)*4.*atten;
    
    // Darkening the edges. Without it, the scene would lose its mild cartoony look.
    col *= 1. - edge*.7;
    
    
    //col = mix(col, vec3(2, 1.5, 1).zyx, 1. - exp(-.002*sDist*sDist)); // Blue fog.
    col = mix(col, vec3(0), 1. - exp(-.002*sDist*sDist)); // Extra fog.
    
    // Rough gamma correction.
    fragColor = vec4(sqrt(clamp(col, 0., 1.)), 1.);
}
