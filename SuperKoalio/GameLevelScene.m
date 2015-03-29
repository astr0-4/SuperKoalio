//
//  GameLevelScene.m
//  SuperKoalio
//
//  Created by Jake Gundersen on 12/27/13.
//  Copyright (c) 2013 Razeware, LLC. All rights reserved.
//

#import "GameLevelScene.h"
#import "JSTileMap.h"
#import "Player.h"
#import "SKTUtils.h"

@interface GameLevelScene()
@property(nonatomic, strong) JSTileMap *map; //initialization of map object
//map is an object that is an instance of this class, this is allowed to be used in this class
//read only objects are not allowed to be changed by other objects, changes must be "approved"
@property(nonatomic, strong) Player *player;
@property(nonatomic, assign) NSTimeInterval previousUpdateTime;
@property (nonatomic, strong) TMXLayer *walls;
@property(nonatomic, strong) TMXLayer *hazards;
@property(nonatomic, assign) BOOL gameOver;

@end

// interface is the instructions for the class that tell the user how the class is intended to be used.
// defines the way you want other objects to interact with your class.

@implementation GameLevelScene

-(id)initWithSize:(CGSize)size {
  if (self = [super initWithSize:size]) {
    
    // sets the background colour to the scene, this is the blue sky
    self.backgroundColor = [SKColor colorWithRed:.4 green:.4 blue:.95 alpha:1.0];
    
    // loads the level1 map and adds it to the layer
    //self.map = [JSTileMap mapNamed:@"level1.tmx"]; //assign map object to our map
    self.map = [JSTileMap mapNamed:@"level2.tmx"];
    self.walls = [self.map layerNamed:@"walls"];
    self.hazards = [self.map layerNamed:@"hazards"];
    
    [self addChild:self.map];
    self.player = [[Player alloc] initWithImageNamed: @"koalio_stand"];
    self.player.position = CGPointMake(100, 50);
    self.player.zPosition = 15;
    [self.map addChild:self.player];
    self.userInteractionEnabled = YES;
  }
  return self;
}

-(void)update:(NSTimeInterval)currentTime
{
  if(self.gameOver) return;
  NSTimeInterval delta = currentTime - self.previousUpdateTime;
  
  if(delta > 0.02) {
    delta = 0.02;
  }
  self.previousUpdateTime = currentTime;
  [self.player update:delta];
  [self checkForAndResolveCollisionsForPlayer:self.player forLayer:self.walls];
  [self setViewpointCenter:self.player.position];
  [self checkForWin];
}

-(CGRect)tileRectFromTileCoords:(CGPoint)tileCoords {
  float levelHeightInPixels = self.map.mapSize.height * self.map.tileSize.height;
  CGPoint origin = CGPointMake(tileCoords.x * self.map.tileSize.width, levelHeightInPixels - ((tileCoords.y + 1) * self.map.tileSize.height));
  return CGRectMake(origin.x, origin.y, self.map.tileSize.width, self.map.tileSize.height);
}

-(NSInteger)tileGIDAtTileCoord:(CGPoint)coord forLayer:(TMXLayer *)layer {
  TMXLayerInfo *layerInfo = layer.layerInfo;
  return [layerInfo tileGidAtCoord:coord];
}

-(void)checkForAndResolveCollisionsForPlayer:(Player *)player forLayer:(TMXLayer *)layer {
  [self handleHazardCollisions:self.player];
  
  NSInteger indices[8] = {7, 1, 3, 5, 0, 2, 6, 8};
  player.onGround = NO;
  for (NSUInteger i = 0; i < 8; i++) {
    NSInteger tileIndex = indices[i];
    
    CGRect playerRect = [player collisionBoundingBox];
    CGPoint playerCoord = [layer coordForPoint:player.desiredPosition ];
    
    if (playerCoord.y >= self.map.mapSize.height - 2) {
          [self gameOver:0];
          return;
      }
      
    NSInteger tileColumn = tileIndex % 3;
    NSInteger tileRow = tileIndex / 3;
    CGPoint tileCoord = CGPointMake(playerCoord.x + (tileColumn - 1), playerCoord.y + (tileRow - 1));
    
    NSInteger gid = [self tileGIDAtTileCoord:tileCoord forLayer:layer];
    
    if(gid != 0) {
      CGRect tileRect = [self tileRectFromTileCoords:tileCoord];
//      NSLog(@"GID %ld, Tile Coord %@, Tile Rect %@, player rect %@", (long)gid, NSStringFromCGPoint(tileCoord), NSStringFromCGRect(tileRect), NSStringFromCGRect(playerRect));
//      
      if(CGRectIntersectsRect(playerRect, tileRect)){
        CGRect intersection = CGRectIntersection(playerRect, tileRect);
        
        if(tileIndex == 7) {
          //tile is directly below koala
          player.desiredPosition = CGPointMake(player.desiredPosition.x, player.desiredPosition.y + intersection.size.height);
          player.velocity = CGPointMake(player.velocity.x, 0.0);
          player.onGround = YES;
        }
        else if (tileIndex == 1) {
          //tile is directly above Koala
          player.desiredPosition = CGPointMake(player.desiredPosition.x, player.desiredPosition.y - intersection.size.height);
        }
        else if (tileIndex == 3) {
          //tile is to the left of the Koala
          player.desiredPosition = CGPointMake(player.desiredPosition.x + intersection.size.width,player.desiredPosition.y);
        }
        else if(tileIndex == 5) {
          //tile is right of Koala
          player.desiredPosition = CGPointMake(player.desiredPosition.x - intersection.size.width, player.desiredPosition.y);
        }
        else {
          if(intersection.size.width > intersection.size.height){
            // tile is diagonal, but resolving collision vertically
            float intersectionHeight;
            if(tileIndex > 4) {
              intersectionHeight = intersection.size.height;
              player.onGround = YES;
            }
            else {
              intersectionHeight = -intersection.size.height;
            }
            player.desiredPosition = CGPointMake(player.desiredPosition.x, player.desiredPosition.y + intersection.size.height);
          }
          else {
            //tile is diagonal, but resolving collision horizontally
            float intersectionWidth;
            if(tileIndex == 6 || tileIndex == 0) {
              intersectionWidth = intersection.size.width;
            }
            else {
              intersectionWidth = -intersection.size.width;
            }
            player.desiredPosition = CGPointMake(player.desiredPosition.x + intersectionWidth, player.desiredPosition.y);
            }
          }
        }
      }
    }
  player.position = player.desiredPosition;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
  for (UITouch *touch in touches) {
    CGPoint touchLocation = [touch locationInNode:self];
    if(touchLocation.x > self.size.width/2.0) {
      self.player.mightAsWellJump = YES;
    }
    else {
      self.player.forwardMarch = YES;
    }
  }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  for (UITouch *touch in touches) {
    float halfWidth = self.size.width/2.0;
    CGPoint touchLocation = [touch locationInNode:self];
    
    //get previous touch and convert it to node space
    CGPoint previousTouchLocation = [touch previousLocationInNode:self];
    
    if(touchLocation.x > halfWidth && previousTouchLocation.x <= halfWidth) {
      self.player.forwardMarch = NO;
      self.player.mightAsWellJump = YES;
    } else if (previousTouchLocation.x > halfWidth && touchLocation.x <= halfWidth) {
      self.player.forwardMarch = YES;
      self.player.mightAsWellJump = NO;
    }
  }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  for (UITouch *touch in touches) {
    CGPoint touchLocation = [touch locationInNode:self];
    if(touchLocation.x < self.size.width/2.0){
      self.player.forwardMarch = NO;
    } else {
      self.player.mightAsWellJump = NO;
    }
  }
}

-(void)setViewpointCenter:(CGPoint)position {
  NSInteger x = MAX(position.x, self.size.width/2);
  NSInteger y = MAX(position.y, self.size.height/2);
  x = MIN(x, (self.map.mapSize.width * self.map.tileSize.width) - self.size.width/2);
  y = MIN(y, (self.map.mapSize.height * self.map.tileSize.height) - self.size.height/2);
  CGPoint actualPosition = CGPointMake(x, y);
  CGPoint centerOfView = CGPointMake(self.size.width/2, self.size.height/2);
  CGPoint viewPoint =  CGPointSubtract(centerOfView, actualPosition);
  self.map.position = viewPoint;
}

-(void)handleHazardCollisions:(Player *)player
{
  if (self.gameOver) return;
  NSInteger indices[8] = {7, 1, 3, 5, 0, 2, 6, 8};
  
  for(NSUInteger i = 0; i < 8; i++) {
    NSInteger tileIndex = indices[i];
    
    CGRect playerRect = [player collisionBoundingBox];
    CGPoint playerCoord = [self.hazards coordForPoint:player.desiredPosition];
    
    NSInteger tileColumn = tileIndex % 3;
    NSInteger tileRow = tileIndex / 3;
    CGPoint tileCoord = CGPointMake(playerCoord.x + (tileColumn - 1), playerCoord.y + (tileRow - 1));
    
    NSInteger gid = [self tileGIDAtTileCoord:tileCoord forLayer:self.hazards];
    if (gid != 0) {
      CGRect tileRect = [self tileRectFromTileCoords:tileCoord];
      if (CGRectIntersectsRect(playerRect, tileRect)) {
        [self gameOver:0];
      }
    }
  }
}

-(void)gameOver:(BOOL)won {
  //1
  self.gameOver = YES;
  //2
  NSString *gameText;
  if(won) {
    gameText = @"You Won!";
  } else {
    gameText = @"You have died!";    
  }
  
  //3
  SKLabelNode *endGameLabel = [SKLabelNode labelNodeWithFontNamed:@"Marker Felt"];
  endGameLabel.text = gameText;
  endGameLabel.fontSize = 40;
  endGameLabel.position = CGPointMake(self.size.width/2.0, self.size.height/1.7);
  [self addChild:endGameLabel];
  
  //4
  UIButton *replay = [UIButton buttonWithType:UIButtonTypeCustom];
  replay.tag = 321;
  UIImage *replayImage = [UIImage imageNamed:@"replay"];
  [replay setImage:replayImage forState:UIControlStateNormal];
  [replay addTarget:self action:@selector(replay:)
   forControlEvents:UIControlEventTouchUpInside];
  replay.frame = CGRectMake(self.size.width / 2.0 - replayImage.size.width /2.0,
                            self.size.height/2.0 - replayImage.size.height / 2.0, replayImage.size.width, replayImage.size.height);
  [self.view addSubview:replay];
}

-(void)replay:(id)sender
{
  //5
  [[self.view viewWithTag:321] removeFromSuperview];
  //6
  [self.view presentScene:[[GameLevelScene alloc] initWithSize:self.size]];
}

-(void)checkForWin {
    if(self.player.position.x > 3230.0) {
        [self gameOver:1];
    }
}

@end
