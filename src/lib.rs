
use bevy::render::render_asset::RenderAssetUsages;
  
use plane3d_cloud_material::Plane3dCloudMaterial;
use std::io::{Cursor, Read};
use bevy::asset::load_internal_asset;
use bevy::prelude::*;
use bevy::image::{CompressedImageFormats, ImageLoader, ImageSampler, ImageType};
pub mod plane3d_cloud_material;
pub mod camera;







pub struct DegenToonCloudsPlugin;
 
impl Plugin for DegenToonCloudsPlugin {
    fn build(&self, app: &mut App) {

         load_internal_asset!(
            app,
            PLANE_3D_CLOUD_SHADER_HANDLE,
            "assets/plane3d_clouds.wgsl",
            Shader::from_wgsl
        );

          

            // Load the image data into a byte vector
        

        // Load the image from the cursor
        let noise_image = Image::from_buffer(
            include_bytes!("assets/PerlinNoise.png"), 
            ImageType::Format(ImageFormat::Png),
            CompressedImageFormats::empty(), 
            false,
            ImageSampler::default(),
            RenderAssetUsages::default() 
        ).unwrap();

        let distortion_image = Image::from_buffer(
            include_bytes!("assets/WaterDistortion.png"), 
            ImageType::Format(ImageFormat::Png),
            CompressedImageFormats::empty(), 
            false,
            ImageSampler::default(),
            RenderAssetUsages::default() 
        ).unwrap();

 

        let mut images = app.world_mut().resource_mut::<Assets<Image>>();
  
        images.insert(& DEFAULT_NOISE_MAP_HANDLE, noise_image );

        images.insert(& DEFAULT_DISTORTION_MAP_HANDLE, distortion_image );
   

         
        app
           
            .add_plugins(MaterialPlugin::<plane3d_cloud_material::Plane3dCloudMaterial > {

                 prepass_enabled: false,
                ..default() 
            })

            .add_systems(Update, update_material_coord_scale)
             
            ;

    }
}

pub(crate) const PLANE_3D_CLOUD_SHADER_HANDLE: Handle<Shader> =
    Handle::weak_from_u128(4_296_634_513_987_597_127);

 
 
pub const DEFAULT_NOISE_MAP_HANDLE: Handle<Image> =
    Handle::weak_from_u128(6_154_851_784_326_313_901);


pub const DEFAULT_DISTORTION_MAP_HANDLE: Handle<Image> =
    Handle::weak_from_u128(6_441_941_965_326_404_902);

 

 fn update_material_coord_scale (


    material_query: Query < ( &MeshMaterial3d<Plane3dCloudMaterial>, &GlobalTransform)  >,
    mut materials: ResMut<Assets<Plane3dCloudMaterial>>
){

    for (mat_handle, global_xform) in material_query.iter(){



        if let Some(  material) = materials.get_mut( mat_handle ){
        
            let translation = global_xform.translation();
            let scale = global_xform.to_scale_rotation_translation().0;


            let x = translation.x;
            let y = translation.z;



            let coord_offset = Vec2::new(x,y);
            let coord_scale = Vec2::new(scale.x as f32, scale.z as f32);

         
            material.extension.custom_uniforms.coord_offset = coord_offset;
            material.extension.custom_uniforms.coord_scale = coord_scale;


        }

    }

 }