//
//  SwiffPlacedSprite.m
//  SwiffCore
//
//  Created by Will Hankinson on 10/16/12.
//
//

#import "SwiffPlacedSprite.h"
#import "SwiffMovie.h"
#import "SwiffSpriteDefinition.h"

@implementation SwiffPlacedSprite {
    
}

static int instanceID;

- (id) init
{
    return [super init];
}

- (id) initWithPlacedObject:(SwiffPlacedObject *)placedObject
{
    if ((self = [super initWithPlacedObject:placedObject])) {
        
        if ([placedObject isKindOfClass:[SwiffPlacedSprite class]]) {
            SwiffPlacedSprite *sprite = (SwiffPlacedSprite *)sprite;
            
            _frame = sprite.frame;
            _instanceID = instanceID++;
        }
    }
    
    return self;
}

+(int)instanceID{ return instanceID; }
+(void)setInstanceID:(int)nid{ instanceID = nid; }

- (void) setFrameFromParent:(NSInteger)frameIndex
{
    if(!_playing) return;
    
    NSInteger lastFrame = [[_definition frames] count];
    
    if(frameIndex >= lastFrame)
    {
        if(_shouldLoop)
        {
            _frame = frameIndex % lastFrame;
        }else{
            //hang out on the last frame
            _frame = lastFrame - 1;
        }
    }else{
        _frame = frameIndex;
    }
}

- (void) dealloc
{
    
}

- (void) setupWithDefinition:(id<SwiffDefinition>)definition
{
    if (_definition != definition) {
        _definition = nil;
        
        if ([definition isKindOfClass:[SwiffSpriteDefinition class]]) {
            _definition = (SwiffSpriteDefinition *)definition;
            
            //when initialized always start on frame 1
            _frame = 0;
        }
    }
}

@end
