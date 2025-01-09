use crate::{DEFAULT_DISTORTION_MAP_HANDLE, DEFAULT_NOISE_MAP_HANDLE, PLANE_3D_CLOUD_SHADER_HANDLE};
use bevy::prelude::*;
use bevy::reflect::TypePath;
use bevy::render::render_resource::*;

use bevy::pbr::{ExtendedMaterial, MaterialExtension, OpaqueRendererMethod};
use bevy::utils::HashMap;
 


pub type Plane3dCloudMaterial = ExtendedMaterial<StandardMaterial, Plane3dCloudMaterialBase>;


pub fn build_plane_3d_cloud_material(
   	 
    ) ->   Plane3dCloudMaterial {


        //do these do anything ?
        let base_color = LinearRgba::new(1.0,1.0,1.0,1.0);
        let emissive = LinearRgba::new(1.0,1.0,1.0,1.0);
 
  
            ExtendedMaterial {
                     base: StandardMaterial {
			            base_color: base_color.into(),
			            emissive: emissive.into(),
			            opaque_render_method: OpaqueRendererMethod::Auto,
			            alpha_mode: AlphaMode::Blend,
			            double_sided: true,
			            cull_mode: None, 

			            ..Default::default()
			        },
			        extension: Plane3dCloudMaterialBase {
			          //  base_color_texture: Some(texture_handle),
			            custom_uniforms: Plane3dCloudMaterialUniforms::default(),
			            surface_noise_texture: Some( DEFAULT_NOISE_MAP_HANDLE ),
			            surface_distortion_texture: Some( DEFAULT_DISTORTION_MAP_HANDLE ),
			            //depth_texture: None,
			            //normal_texture: None,
			        },
                }

      
}

//pub type AnimatedMaterialExtension = ExtendedMaterial<StandardMaterial, AnimatedMaterial>;
//pub type ToonWaterMaterialBundle = MaterialMeshBundle<ToonWaterMaterial >;

#[derive(Clone, ShaderType, Debug)]
pub struct Plane3dCloudMaterialUniforms {

	pub depth_gradient_shallow: LinearRgba,
    pub depth_gradient_deep: LinearRgba,
    pub depth_max_distance: f32,
    pub foam_color: LinearRgba,
    pub surface_noise_scroll: Vec2,
    pub surface_noise_cutoff: f32,
    pub surface_distortion_amount: f32,
    pub foam_max_distance: f32,
    pub foam_min_distance: f32,

    pub noise_map_scale: f32,

    pub coord_offset: Vec2,
    pub coord_scale: Vec2,

 
}
impl Default for Plane3dCloudMaterialUniforms {
    fn default() -> Self {
        Self {
		    depth_gradient_shallow: LinearRgba::new(0.325, 0.807, 0.971, 0.725),
            depth_gradient_deep: LinearRgba::new(0.086, 0.307, 0.7, 0.949),
            depth_max_distance: 2.0,
            foam_color: LinearRgba::new(0.9,0.9,0.9,1.0),
            surface_noise_scroll: Vec2::new(0.003,0.003),
            surface_noise_cutoff:  0.8,
            surface_distortion_amount:  0.14,
            foam_max_distance: 0.6,  //foam for an obstruction in the water (from normal dot product)
            foam_min_distance: 0.14, //foam at shore
            noise_map_scale: 0.002,

            //these are controlled by an update system 
            coord_offset: Vec2::new(0.0,0.0),
            coord_scale: Vec2::new(1.0,1.0)
        }
    }
}

#[derive(Asset, AsBindGroup, TypePath, Debug, Clone, Default)]
pub struct Plane3dCloudMaterialBase {
   #[uniform(20)]
    pub custom_uniforms: Plane3dCloudMaterialUniforms,
  //  #[texture(21)]
  //  #[sampler(22)]
  //  pub base_color_texture: Option<Handle<Image>>,
    #[texture(23)]
    #[sampler(24)]
    pub surface_noise_texture: Option<Handle<Image>>,
    #[texture(25)]
    #[sampler(26)]
    pub surface_distortion_texture: Option<Handle<Image>>,
    //#[texture(27)]
    //#[sampler(28)]
   // pub depth_texture: Option<Handle<Image>>,
    //#[texture(29)]
   // #[sampler(30)]
   // pub normal_texture: Option<Handle<Image>>,
}

impl MaterialExtension for Plane3dCloudMaterialBase {
    fn fragment_shader() -> ShaderRef {
       
         ShaderRef::Handle(PLANE_3D_CLOUD_SHADER_HANDLE)
    }

    fn deferred_fragment_shader() -> ShaderRef {
         
         ShaderRef::Handle(PLANE_3D_CLOUD_SHADER_HANDLE)
    }
/*
    fn vertex_shader() -> ShaderRef {
       
         ShaderRef::Handle(PLANE_3D_CLOUD_SHADER_HANDLE)
    }

    */
}


// see https://github.com/bevyengine/bevy/blob/1030a99b8e2680a7e696d6433b79f5671768231c/crates/bevy_pbr/src/render/forward_io.wgsl#L32-L56
