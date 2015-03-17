//
//  Player.m
//  SuperKoalio
//
//  Created by Jake Gundersen on 12/27/13.
//  Copyright (c) 2013 Razeware, LLC. All rights reserved.
//

#import "Player.h"
#import "SKTUtils.h"

@implementation Player
-(instancetype)initWithImageNamed:(NSString *)name {
    if(self == [super initWithImageNamed:name]) {
        self.velocity = CGPointMake(0.0, 0.0);
    }
    return self;
}

-(void)update:(NSTimeInterval)delta {
    
    CGPoint gravity = CGPointMake(0.0, -450.0);
    
    CGPoint gravityStep = CGPointMultiplyScalar(gravity, delta);
    
    self.velocity = CGPointAdd(self.velocity, gravityStep);
    CGPoint velocityStep = CGPointMultiplyScalar(self.velocity, delta);
    
    self.desiredPosition = CGPointAdd(self.position, velocityStep);
}

-(CGRect)collisionBoundingBox {
    CGRect boundingBox = CGRectInset(self.frame, 2, 0);
    CGPoint diff = CGPointSubtract(self.desiredPosition, self.position);
    return CGRectOffset(boundingBox, diff.x, diff.y);
}

//use instancetype wherever a class returns an instance of that same class - ensures type safety

@end
