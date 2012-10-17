//
//  SwiffPlacedSprite.h
//  SwiffCore
//
//  Created by Will Hankinson on 10/16/12.
//
//

#import <SwiffImport.h>
#import <SwiffPlacedObject.h>
#import <SwiffSpriteDefinition.h>

@class SwiffMovie;


@interface SwiffPlacedSprite : SwiffPlacedObject

-(void)setFrameFromParent:(NSInteger)frameIndex;

@property (nonatomic, assign) BOOL playing;
@property (nonatomic, assign) NSInteger frame;
@property (nonatomic, assign) NSInteger placedFrame; //which frame were we placed? i.e. our frame 0
@property (nonatomic, assign) BOOL shouldLoop;

@property (nonatomic, strong, readonly) SwiffSpriteDefinition *definition;

@end
