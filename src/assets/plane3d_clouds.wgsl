 
 
  #import bevy_pbr::mesh_bindings   mesh

#import bevy_pbr::mesh_functions::{ get_world_from_local , mesh_position_local_to_world, mesh_position_local_to_clip }

 #import bevy_pbr::{
    mesh_view_bindings::globals, 
    forward_io::{ VertexOutput,  FragmentOutput}, 
    pbr_fragment::pbr_input_from_standard_material,
      pbr_functions::{alpha_discard, apply_pbr_lighting, main_pass_post_lighting_processing},
    pbr_types::STANDARD_MATERIAL_FLAGS_UNLIT_BIT,
      pbr_deferred_functions::deferred_output
}
 
  #import bevy_pbr::prepass_utils


 #import bevy_pbr::mesh_view_bindings view

#import bevy_pbr::view_transformations::{
position_clip_to_world,
sition_view_to_clip, 
position_clip_to_view,
position_view_to_world,
depth_ndc_to_view_z
} 



struct StandardMaterial {
    time: f32,
    base_color: vec4<f32>,
    emissive: vec4<f32>,
    perceptual_roughness: f32,
    metallic: f32,
    reflectance: f32,
    // 'flags' is a bit field indicating various options. u32 is 32 bits so we have up to 32 options.
    flags: u32,
    alpha_cutoff: f32,
};
 
 struct ToonWaterMaterialUniforms {
 
   
    foam_color: vec4<f32>,
    surface_noise_scroll: vec2<f32>,
    surface_noise_cutoff: f32,
    surface_distortion_amount: f32,
   
    noise_map_scale: f32, 

    masking_noise_map_scale: f32, 
    masking_noise_cutoff: f32,
    masking_noise_scroll: vec2<f32>,

    coord_offset: vec2<f32>,
    coord_scale: vec2<f32>,
};
 

 


@group(2) @binding(20)
var<uniform> toon_water_uniforms: ToonWaterMaterialUniforms;
 
 //@group(2) @binding(21)
//var base_color_texture: texture_2d<f32>;

@group(2) @binding(23)
var surface_noise_texture: texture_2d<f32>;
@group(2) @binding(24)
var surface_noise_sampler: sampler;


@group(2) @binding(25)
var surface_distortion_texture: texture_2d<f32>;
@group(2) @binding(26)
var surface_distortion_sampler: sampler;
 

 
//should consider adding vertex painting to this .. need another binding of course.. performs a color shift 

 
//@fragment
//fn fragment(
//    mesh: VertexOutput,
//    @builtin(front_facing) is_front: bool,
  
 

 // i want to make the foam smaller overall and also more concentrated where there is depth 
//https://github.com/bevyengine/bevy/blob/7d843e0c0891545ec6cc0131398b0db6364a7a88/crates/bevy_pbr/src/prepass/prepass.wgsl#L4


//https://github.com/bevyengine/bevy/blob/7d843e0c0891545ec6cc0131398b0db6364a7a88/crates/bevy_pbr/src/render/view_transformations.wgsl#L101
    // i really need world position z !


@fragment
fn fragment(
     
     mesh: VertexOutput,
) -> @location(0) vec4<f32> {
    let uv = mesh.uv  ;

    
   
    let scaled_uv =  uv_to_coord(mesh.uv) * toon_water_uniforms.noise_map_scale  ;
    

     let scaled_uv_for_mask =  uv_to_coord(mesh.uv) * toon_water_uniforms.masking_noise_map_scale  ;
  

            
     //this is how the frag_depth (buffer) is written to by other things 
     //this seems to be correct 
   let water_surface_world_pos =      mesh.world_position   ;  
 
     
    
     
    let surface_noise_cutoff = toon_water_uniforms.surface_noise_cutoff ;
     let masking_noise_cutoff = toon_water_uniforms.masking_noise_cutoff ;
 
 
   let distort_sample = textureSample(surface_distortion_texture, surface_distortion_sampler, scaled_uv   )   ;
 

    let time_base =  ( globals.time  ) * 1.0  ;

    let distorted_plane_uv = scaled_uv + (distort_sample.rg * toon_water_uniforms. surface_distortion_amount);

    var noise_uv = vec2<f32>(
        (distorted_plane_uv.x + (time_base * toon_water_uniforms.surface_noise_scroll.x)) %1.0 ,
        (distorted_plane_uv.y + (time_base * toon_water_uniforms.surface_noise_scroll.y))  %1.0 
    );

     var noise_uv_alt = vec2<f32>(  //this is out of sync time-wise which makes a nice effect when combined
        (distorted_plane_uv.x + (time_base *1.1 * toon_water_uniforms.surface_noise_scroll.x)) % 1.0 ,
        (distorted_plane_uv.y + (time_base  *1.1 * toon_water_uniforms.surface_noise_scroll.y))  %1.0 
    );
    



    var masking_noise_uv = vec2<f32>(
        ( scaled_uv_for_mask.x +  (time_base * toon_water_uniforms.masking_noise_scroll.x)) %1.0 ,
        ( scaled_uv_for_mask.y +  (time_base * toon_water_uniforms.masking_noise_scroll.y))  %1.0 
    );



   let distortion_noise_sample = textureSample(surface_distortion_texture, surface_distortion_sampler, noise_uv_alt    )   ;

   let surface_noise_sample = textureSample(surface_noise_texture, surface_noise_sampler, noise_uv    )   ;


   let masking_noise_sample = textureSample(surface_noise_texture, surface_noise_sampler, masking_noise_uv    )   ;


   let smoothstep_tolerance_band = 0.01 ; //controls foam edge sharpness

   let combined_noise_sample =  surface_noise_sample.r * distortion_noise_sample.g * 2.0 ;

     
    let surface_noise = smoothstep(surface_noise_cutoff -  smoothstep_tolerance_band, surface_noise_cutoff +  smoothstep_tolerance_band ,    combined_noise_sample );


     let masking_noise = smoothstep(masking_noise_cutoff -  smoothstep_tolerance_band, masking_noise_cutoff +  smoothstep_tolerance_band ,    masking_noise_sample.r  );


    
      let mask_output = 1.0 - masking_noise;
    let masked_surface_noise = mask_output * surface_noise  ;

    var surface_noise_color = toon_water_uniforms.foam_color;
    surface_noise_color.a *= masked_surface_noise ; //surface_noise * masked_surface_noise;
    

    var color =  surface_noise_color ;
  
 
    return  color;
}

fn alpha_blend(top: vec4<f32>, bottom: vec4<f32>) -> vec4<f32> {
    let color = top.rgb * top.a + bottom.rgb * (1.0 - top.a);
    let alpha = top.a + bottom.a * (1.0 - top.a);
    return vec4<f32>(color, alpha);  
}

fn uv_to_coord(uv: vec2<f32>) -> vec2<f32> {
  return toon_water_uniforms.coord_offset + (uv * toon_water_uniforms.coord_scale);
}

  

fn screen_to_clip(screen_coord: vec2<f32>, depth: f32) -> vec4<f32> {
    let ndc_x = screen_coord.x * 2.0 - 1.0;
    let ndc_y = screen_coord.y * 2.0 - 1.0;
    let ndc_z = depth * 2.0 - 1.0;
    return vec4<f32>(ndc_x, ndc_y, ndc_z, 1.0);
}


  fn reconstruct_view_space_position( uv: vec2<f32>, depth: f32) -> vec3<f32> {
    let clip_xy = vec2<f32>(uv.x * 2.0 - 1.0, 1.0 - 2.0 * uv.y);
    let t = view.view_from_clip * vec4<f32>(clip_xy, depth, 1.0);
    let view_xyz = t.xyz / t.w;
    return view_xyz;
}



fn clip_to_view(clip_pos: vec4<f32>) -> vec3<f32> {
    // Transform from clip space to view space using the inverse projection matrix
    let view_space = view.view_from_clip * clip_pos;
    let view_space_pos = view_space.xyz / view_space.w;

    // Transform from view space to world space using the inverse view matrix
  //  let world_space = view.inverse_view * vec4<f32>(view_space_pos, 1.0);
    return view_space_pos.xyz;
}


 

struct Vertex {
    @builtin(instance_index) instance_index: u32,
    @location(0) position: vec3<f32>,
    @location(1) blend_color: vec4<f32>,
};
 

@vertex
fn vertex(vertex: Vertex) -> VertexOutput {
    var out: VertexOutput;

    let time_base =  ( globals.time  ) * 1.0  ;

    let sinewave_time = sin(  time_base  );

    var local_psn_output = vertex.position;

    local_psn_output.y = local_psn_output.y + sin(  time_base +  local_psn_output.x) * 20.20; 

    out.position = mesh_position_local_to_clip(
        get_world_from_local(vertex.instance_index),
        vec4<f32>(local_psn_output, 1.0),
    );
   

   
    return out;
}
 