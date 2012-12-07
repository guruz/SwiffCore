//
//  SwiffMorphShapeDefinition.m
//  SwiffCore
//
//  Created by Maxim Gavrilov on 12/6/12.
//
//

#import "SwiffMorphShapeDefinition.h"
#import "SwiffFillStyle.h"
#import "SwiffLineStyle.h"
#import "SwiffUtils.h"

@implementation SwiffMorphShapeDefinition {
    CGRect _startBounds;
    CGRect _endBounds;
    NSArray *_fillStyles;
    NSArray *_lineStyles;
    CGPathRef _startPath;
    CGPathRef _endPath;
}

@synthesize movie = _movie,
            libraryID = _libraryID,
            bounds = _bounds,
            renderBounds = _renderBounds;

- (id) initWithParser:(SwiffParser *)parser movie:(SwiffMovie *)movie
{
    SwiffLogSetCategoryEnabled(@"MorphShape", YES);
    
    if ((self = [super init])) {
        SwiffParserByteAlign(parser);
        
        _movie = movie;
        
        SwiffTag  tag     = SwiffParserGetCurrentTag(parser);
        NSInteger version = SwiffParserGetCurrentTagVersion(parser);
        
        if (tag != SwiffTagDefineMorphShape || version > 2) {
            return nil;
        }
        
        SwiffParserReadUInt16(parser, &_libraryID);
        
        SwiffLog(@"MorphShape", @"DEFINEMORPHSHAPE defines id %ld", (long)_libraryID);
        
        SwiffParserReadRect(parser, &_startBounds);
        SwiffParserReadRect(parser, &_endBounds);
        _bounds = _startBounds;
        
        if (version == 2) {
            SwiffLog(@"MorphShape", @"morph need read additional params");
            return nil;
        }
        
        UInt32 offset;
        SwiffParserReadUInt32(parser, &offset);
        
        _fillStyles = SwiffParserReadArrayOfObjects(parser, [SwiffMorphFillStyle class]);
        _lineStyles = SwiffParserReadArrayOfObjects(parser, [SwiffMorphLineStyle class]);
        _startPath = SwiffParserReadPathFromShapeRecord(parser);
        _endPath = SwiffParserReadPathFromShapeRecord(parser);
        
        if (!SwiffParserIsValid(parser)) {
            return nil;
        }
    }
    return self;
}

- (void)dealloc
{
    if (_startPath) {
        CFRelease(_startPath);
        _startPath = NULL;
    }
    if (_endPath) {
        CFRelease(_endPath);
        _endPath = NULL;
    }
}

- (SwiffShapeDefinition *)shapeWithRatio:(CGFloat)ratio
{
    return nil;
}


- (void) clearWeakReferences
{
    _movie = nil;
}
@end
