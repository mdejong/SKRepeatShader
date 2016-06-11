//
//  GameScene.m
//  SK2KTile
//
//  Created by Mo DeJong on 4/23/16.
//  Copyright (c) 2016 HelpURock. All rights reserved.
//

#import "GameScene.h"

@implementation GameScene

// This implementation makes use of a repeating shared to render a tile
// over the entire viewable area of a SKSpriteNode. This approach saves
// significant memory when compared to an approach like:
// http://www.spritekitlessons.com/tile-a-background-image-with-sprite-kit/
//
// Note that due to poor performant in SpriteKit Metal mode, OpenGL mode
// should be enbaled with PrefersOpenGL=YES in Info.plist

- (void) makeBackgroundNode
{
  // Use new size of SKScene
  
  CGSize sceneSize = self.size;
  
  NSLog(@"makeBackgroundNode at size %d x %d", (int)sceneSize.width, (int)sceneSize.height);
  
  [self.background removeFromParent];
  self.background = nil; // dealloc memory
  
  SKSpriteNode *background = [self.class generateRepeatTiledImageNode:sceneSize];
  
  self.background = background;
  
  background.anchorPoint = CGPointMake(0.0,0.0);
  background.position = CGPointZero;
  
  NSLog(@"background.position : %d %d", (int)background.position.x, (int)background.position.y);
  
  NSLog(@"background.size : %d %d", (int)background.size.width, (int)background.size.height);
  
  background.zPosition = 0;
  
  [self addChild:background];
}

-(void)didMoveToView:(SKView *)view {
  self.scene.backgroundColor = [UIColor redColor];
  
  [self makeBackgroundNode];
  
  return;
}

- (void)didChangeSize:(CGSize)oldSize
{
  NSLog(@"SKScene.didChangeSize old size %d x %d", (int)oldSize.width, (int)(int)oldSize.height);
  
  if (self.background) {
    // Resize after initial invocation of didMoveToView
    
    [self makeBackgroundNode];
  }
}

// Generate a repeating tile pattern in a SKSpriteNode using an OpenGL shader

+ (SKSpriteNode*) generateRepeatTiledImageNode:(CGSize)backgroundSizePoints
{
  NSString *textureFilename = @"tile.png";
  
  // Load the tile as a SKTexture
  
  SKTexture *tileTex = [SKTexture textureWithImageNamed:textureFilename];
  
  // Dimensions of tile image
  
  CGSize tileSizePixels = CGSizeMake(tileTex.size.width, tileTex.size.height); // tile texture dimensions
  
  NSLog(@"tile size in pixels %d x %d", (int)tileSizePixels.width, (int)tileSizePixels.height);
  
  // Generate tile that exactly covers the whole screen
  
  float screenScale = [UIScreen mainScreen].scale;
  
  CGSize coverageSizePixels = CGSizeMake(backgroundSizePoints.width * screenScale, backgroundSizePoints.height * screenScale);
  
  CGSize coverageSizePoints = CGSizeMake(coverageSizePixels.width / screenScale, coverageSizePixels.height / screenScale);
  
  // Make shader and calculate uniforms to be used for pixel center calculations
  
  SKShader* shader;

  NSBundle *mainBundle = [NSBundle mainBundle];
  NSDictionary *infoDict = mainBundle.infoDictionary;
  NSNumber *preferesOpenGLNum = infoDict[@"PrefersOpenGL"];
  BOOL preferesOpenGL = [preferesOpenGLNum boolValue];
  
  NSString *shaderFilename;
  
  // OpenGL shader : 60 FPS
  // Metal shader :  39 FPS
  
  if (preferesOpenGL) {
    shaderFilename = @"shader_opengl.fsh";
  } else {
    shaderFilename = @"shader_metal.fsh";
  }
  
  shader = [SKShader shaderWithFileNamed:shaderFilename];
  assert(shader);
  
  float outSampleHalfPixelOffsetX = 1.0f / (2.0f * ((float)coverageSizePixels.width));
  float outSampleHalfPixelOffsetY = 1.0f / (2.0f * ((float)coverageSizePixels.height));
  
  [shader addUniform:[SKUniform uniformWithName:@"outSampleHalfPixelOffset" floatVector2:GLKVector2Make(outSampleHalfPixelOffsetX, outSampleHalfPixelOffsetY)]];
  
  // normalized width passed into mod operation
  
  float tileWidth = tileSizePixels.width;
  float tileHeight = tileSizePixels.height;
  
  [shader addUniform:[SKUniform uniformWithName:@"tileSize" floatVector2:GLKVector2Make(tileWidth, tileHeight)]];
  
  // Tile pixel width and height
  
  float inSampleHalfPixelOffsetX = 1.0f / (2.0f * ((float)tileSizePixels.width));
  float inSampleHalfPixelOffsetY = 1.0f / (2.0f * ((float)tileSizePixels.height));
  
  [shader addUniform:[SKUniform uniformWithName:@"inSampleHalfPixelOffset" floatVector2:GLKVector2Make(inSampleHalfPixelOffsetX, inSampleHalfPixelOffsetY)]];
  
  // Attach shader to node
  
  SKSpriteNode *node = [SKSpriteNode spriteNodeWithColor:[UIColor whiteColor] size:coverageSizePoints];
  
  node.texture = tileTex;
  
  node.texture.filteringMode = SKTextureFilteringNearest;
  
  node.shader = shader;
  
  return node;
}

@end
