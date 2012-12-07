//
//  SwiffMorphShapeDefinition.h
//  SwiffCore
//
//  Created by Maxim Gavrilov on 12/6/12.
//
//

#import <SwiffImport.h>
#import <SwiffDefinition.h>
#import <SwiffParser.h>
#import "SwiffShapeDefinition.h"

@interface SwiffMorphShapeDefinition : SwiffShapeDefinition

@property (nonatomic, assign, readonly) UInt16 libraryID;
@property (nonatomic, assign, readonly) CGRect bounds;
@property (nonatomic, assign, readonly) CGRect edgeBounds;

@property (nonatomic, strong, readonly) NSArray *paths;

- (id) initWithParser:(SwiffParser *)parser movie:(SwiffMovie *)movie;
- (SwiffShapeDefinition *)shapeWithRatio:(CGFloat)ratio;
@end
