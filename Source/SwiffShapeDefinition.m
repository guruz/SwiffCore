/*
    SwiffShape.m
    Copyright (c) 2011-2012, musictheory.net, LLC.  All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
        * Redistributions of source code must retain the above copyright
          notice, this list of conditions and the following disclaimer.
        * Redistributions in binary form must reproduce the above copyright
          notice, this list of conditions and the following disclaimer in the
          documentation and/or other materials provided with the distribution.
        * Neither the name of musictheory.net, LLC nor the names of its contributors
          may be used to endorse or promote products derived from this software
          without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL MUSICTHEORY.NET, LLC BE LIABLE FOR ANY
    DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
    ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


#import "SwiffShapeDefinition.h"
#import "SwiffFillStyle.h"
#import "SwiffLineStyle.h"
#import "SwiffParser.h"
#import "SwiffPath.h"
#import "SwiffUtils.h"

typedef NS_ENUM(UInt8, SwiffShapeOperationType) {
    SwiffShapeOperationTypeHeader = 0,
    SwiffShapeOperationTypeLine   = 1,
    SwiffShapeOperationTypeCurve  = 2,
    SwiffShapeOperationTypeEnd    = 3
};


typedef struct SwiffShapeOperation {
    SwiffShapeOperationType type;
    BOOL       duplicate;
    UInt16     lineStyleIndex;
    UInt16     fillStyleIndex;
    SwiffPoint fromPoint;
    SwiffPoint controlPoint;
    SwiffPoint toPoint;
} SwiffShapeOperation;

static NSString *SwiffStringFromShapeOperation(const SwiffShapeOperation *op)
{
    if (op->type == SwiffShapeOperationTypeHeader) {
        return @"SwiffShapeOperation(header)";
    } else if (op->type == SwiffShapeOperationTypeLine) {
        return [NSString stringWithFormat:@"SwiffShapeOperation(line, %@ -> %@)", SwiffStringFromPoint(op->fromPoint), SwiffStringFromPoint(op->toPoint)];
    } else if (op->type == SwiffShapeOperationTypeCurve) {
        return [NSString stringWithFormat:@"SwiffShapeOperation(curve, %@ -> %@ -> %@)",
                SwiffStringFromPoint(op->fromPoint), SwiffStringFromPoint(op->controlPoint), SwiffStringFromPoint(op->toPoint)];
    } else if (op->type == SwiffShapeOperationTypeEnd) {
        return @"SwiffShapeOperation(end)";
    }
    return @"SwiffShapeOperation(UNKNOWN)";
}

static void sPathAddShapeOperation(SwiffPath *path, SwiffShapeOperation *op, SwiffPoint *position)
{
    if ((op->fromPoint.x != position->x) ||
        (op->fromPoint.y != position->y))
    {
        SwiffPathAddOperationAndTwips(path, SwiffPathOperationMove, op->fromPoint.x, op->fromPoint.y);
    }
    
    if (op->type == SwiffShapeOperationTypeLine) {
        if (op->fromPoint.x == op->toPoint.x) {
            SwiffPathAddOperationAndTwips(path, SwiffPathOperationVerticalLine, op->toPoint.y);
            
        } else if (op->fromPoint.y == op->toPoint.y) {
            SwiffPathAddOperationAndTwips(path, SwiffPathOperationHorizontalLine, op->toPoint.x);
        
        } else {
            SwiffPathAddOperationAndTwips(path, SwiffPathOperationLine, op->toPoint.x, op->toPoint.y);
        }
    
    } else if (op->type == SwiffShapeOperationTypeCurve) {
        SwiffPathAddOperationAndTwips(path, SwiffPathOperationCurve, op->toPoint.x, op->toPoint.y, op->controlPoint.x, op->controlPoint.y);
    }
    
    *position = op->toPoint;
}
 

@interface SwiffShapeDefinition ()
@property (nonatomic, weak) SwiffMovie *movie;
@property (nonatomic, assign) UInt16 libraryID;
@property (nonatomic, assign) CGRect bounds;

@property (nonatomic, assign) CFArrayRef groups;
@property (nonatomic, strong) NSArray *fillStyles;
@property (nonatomic, strong) NSArray *lineStyles;
@end

@implementation SwiffShapeDefinition {
    NSArray    *_paths;
}

@synthesize movie        = _movie,
            libraryID    = _libraryID,
            bounds       = _bounds,
            renderBounds = _renderBounds;


#pragma mark -
#pragma mark Lifecycle

- (id) initWithParser:(SwiffParser *)parser movie:(SwiffMovie *)movie
{
    if ((self = [super init])) {
        SwiffParserByteAlign(parser);

        _movie = movie;

        SwiffTag  tag     = SwiffParserGetCurrentTag(parser);
        NSInteger version = SwiffParserGetCurrentTagVersion(parser);

        if (tag == SwiffTagDefineShape) {
            SwiffParserReadUInt16(parser, &_libraryID);

            SwiffLog(@"Shape", @"DEFINESHAPE defines id %ld", (long)_libraryID);
            
            SwiffParserReadRect(parser, &_bounds);

            if (version > 3) {
                _hasEdgeBounds = YES;
                SwiffParserReadRect(parser, &_edgeBounds);
                
                UInt32 reserved, usesFillWindingRule, usesNonScalingStrokes, usesScalingStrokes;
                SwiffParserReadUBits(parser, 5, &reserved);
                SwiffParserReadUBits(parser, 1, &usesFillWindingRule);
                SwiffParserReadUBits(parser, 1, &usesNonScalingStrokes);
                SwiffParserReadUBits(parser, 1, &usesScalingStrokes);

                _usesFillWindingRule   = usesFillWindingRule;
                _usesNonScalingStrokes = usesNonScalingStrokes;
                _usesScalingStrokes    = usesScalingStrokes;
            }
        }

        SwiffPoint position = { 0, 0 };

        __block UInt16 fillStyleOffset = 0;
        __block UInt16 lineStyleOffset = 0;
        __block UInt16 lineStyleIndex  = 0;
        __block UInt16 fillStyleIndex0 = 0;
        __block UInt16 fillStyleIndex1 = 0;

        NSMutableArray *fillStyles = [[NSMutableArray alloc] init];
        NSMutableArray *lineStyles = [[NSMutableArray alloc] init];

        __block SwiffShapeOperation *operations = NULL;
        __block NSUInteger operationsCount = 0;
        __block NSUInteger operationsCapacity = 0;
        __block CGFloat maxWidth = 0.0;

        CFMutableArrayRef groups = CFArrayCreateMutable(NULL, 0, NULL);

        _fillStyles = fillStyles;
        _lineStyles = lineStyles;
        _groups     = groups;
        
        void (^readStyles)() = ^{
            fillStyleOffset = [_fillStyles count];
            lineStyleOffset = [_lineStyles count];

            NSArray *moreFillStyles = SwiffParserReadArrayOfObjects(parser, [SwiffFillStyle class]);
            NSArray *moreLineStyles = SwiffParserReadArrayOfObjects(parser, [SwiffLineStyle class]);

            for (SwiffLineStyle *lineStyle in moreLineStyles) {
                CGFloat width = [lineStyle width];
                if (width > maxWidth) maxWidth = width;
            }

            [fillStyles addObjectsFromArray:moreFillStyles];
            [lineStyles addObjectsFromArray:moreLineStyles];
        };
        
        SwiffShapeOperation *(^nextOperation)() = ^{
            if (operationsCount == operationsCapacity) {
                operationsCapacity *= 2;
                if (!operationsCapacity) operationsCapacity = 32;
                operations = realloc(operations, operationsCapacity * sizeof(SwiffShapeOperation));
            }
    
            return &operations[operationsCount++];
        };
        
        void (^addEndOperation)() = ^{
            SwiffShapeOperation *o = nextOperation();

            o->type = SwiffShapeOperationTypeEnd;
            o->fillStyleIndex = UINT16_MAX;
            o->lineStyleIndex = UINT16_MAX;
        };
        
        void (^addOperation)(NSInteger, SwiffPoint, SwiffPoint, SwiffPoint) = ^(NSInteger type, SwiffPoint from, SwiffPoint control, SwiffPoint to) {
            {
                SwiffShapeOperation *o = nextOperation();
                o->fromPoint      = from;
                o->controlPoint   = control;
                o->toPoint        = to;
                o->fillStyleIndex = fillStyleIndex0;
                o->lineStyleIndex = lineStyleIndex;
                o->type           = type;
                o->duplicate      = NO;
            }

            if (fillStyleIndex1) {
                SwiffShapeOperation *o = nextOperation();
                o->fromPoint      = to;
                o->controlPoint   = control;
                o->toPoint        = from;
                o->fillStyleIndex = fillStyleIndex1;
                o->lineStyleIndex = lineStyleIndex;
                o->type           = type;
                o->duplicate      = YES;
            }
        };

        if (tag == SwiffTagDefineShape) {
            readStyles();
        }

        UInt32 fillBits, lineBits;
        SwiffParserReadUBits(parser, 4, &fillBits);
        SwiffParserReadUBits(parser, 4, &lineBits);

        BOOL foundEndRecord = NO;
        while (!foundEndRecord) {
            UInt32 typeFlag;
            SwiffParserReadUBits(parser, 1, &typeFlag);

            if (typeFlag == 0) {
                UInt32 newStyles, changeLineStyle, changeFillStyle0, changeFillStyle1, moveTo;
                SwiffParserReadUBits(parser, 1, &newStyles);
                SwiffParserReadUBits(parser, 1, &changeLineStyle);
                SwiffParserReadUBits(parser, 1, &changeFillStyle1);
                SwiffParserReadUBits(parser, 1, &changeFillStyle0);
                SwiffParserReadUBits(parser, 1, &moveTo);
                
                // ENDSHAPERECORD
                if ((newStyles + changeLineStyle + changeFillStyle1 + changeFillStyle0 + moveTo) == 0) {
                    foundEndRecord = YES;

                // STYLECHANGERECORD
                } else {
                    if (moveTo) {
                        UInt32 moveBits;
                        SwiffParserReadUBits(parser, 5, &moveBits);
                        
                        SInt32 x, y;
                        SwiffParserReadSBits(parser, moveBits, &x);
                        SwiffParserReadSBits(parser, moveBits, &y);

                        position.x = x;
                        position.y = y;
                    }
                    
                    if (changeFillStyle0) {
                        UInt32 i;
                        SwiffParserReadUBits(parser, fillBits, &i);
                        fillStyleIndex0 = i > 0 ? (i + fillStyleOffset) : 0;
                    }

                    if (changeFillStyle1) {
                        UInt32 i;
                        SwiffParserReadUBits(parser, fillBits, &i);
                        fillStyleIndex1 = i > 0 ? (i + fillStyleOffset) : 0;
                    }

                    if (changeLineStyle) {
                        UInt32 i;
                        SwiffParserReadUBits(parser, lineBits, &i);
                        lineStyleIndex = i > 0 ? (i + lineStyleOffset) : 0;
                    }

                    if (newStyles) {
                        if (operations) {
                            addEndOperation();
                            CFArrayAppendValue(groups, operations);
                        }
                        operations         = NULL;
                        operationsCount    = 0;
                        operationsCapacity = 0;

                        readStyles();
                        SwiffParserReadUBits(parser, 4, &fillBits);
                        SwiffParserReadUBits(parser, 4, &lineBits);
                    }
                }
                
            } else {
                UInt32 straightFlag, numBits;
                SwiffParserReadUBits(parser, 1, &straightFlag);
                SwiffParserReadUBits(parser, 4, &numBits);
                
                // STRAIGHTEDGERECORD
                if (straightFlag) {
                    UInt32 generalLineFlag;
                    SInt32 vertLineFlag = 0, deltaX = 0, deltaY = 0;

                    SwiffParserReadUBits(parser, 1, &generalLineFlag);

                    if (generalLineFlag == 0) {
                        SwiffParserReadSBits(parser, 1, &vertLineFlag);
                    }

                    if (generalLineFlag || !vertLineFlag) {
                        SwiffParserReadSBits(parser, numBits + 2, &deltaX);
                    }

                    if (generalLineFlag || vertLineFlag) {
                        SwiffParserReadSBits(parser, numBits + 2, &deltaY);
                    }

                    SwiffPoint control = { 0, 0 };
                    SwiffPoint from = position;
                    position.x += deltaX;
                    position.y += deltaY;

                    addOperation( SwiffShapeOperationTypeLine, from, control, position );
                
                // CURVEDEDGERECORD
                } else {
                    SInt32 controlDeltaX = 0, controlDeltaY = 0, anchorDeltaX = 0, anchorDeltaY = 0;
                           
                    SwiffParserReadSBits(parser, numBits + 2, &controlDeltaX);
                    SwiffParserReadSBits(parser, numBits + 2, &controlDeltaY);
                    SwiffParserReadSBits(parser, numBits + 2, &anchorDeltaX);
                    SwiffParserReadSBits(parser, numBits + 2, &anchorDeltaY);

                    SwiffPoint control = {
                        position.x + controlDeltaX,
                        position.y + controlDeltaY,
                    };

                    SwiffPoint from = position;
                    position.x = control.x + anchorDeltaX;
                    position.y = control.y + anchorDeltaY;

                    addOperation( SwiffShapeOperationTypeCurve, from, control, position );
                }
            }
            
            //!spec: "Each individual shape record is byte-aligned within
            //        an array of shape records" (page 134)
            //
            // In practice, this is not the case.  Hence, leave the next line commented:
            // SwiffParserByteAlign(parser);
        }

        if (operations) {
            addEndOperation();
            CFArrayAppendValue(groups, operations);
        }
        
        CGFloat padding = SwiffCeil(maxWidth / 2.0) + 1;
        _renderBounds = CGRectInset(_bounds, -padding, -padding);
    }

    return self;
}


- (void)setGroups:(CFArrayRef)groups
{
    if (_groups) {
        CFIndex length = CFArrayGetCount(_groups);
        for (CFIndex i = 0; i < length; i++) {
            free((void *)CFArrayGetValueAtIndex(_groups, i));
        }
        
        CFRelease(_groups);
        _groups = NULL;
    }

    _groups = groups;
}

- (void) dealloc
{
    if (_groups) {
        CFIndex length = CFArrayGetCount(_groups);
        for (CFIndex i = 0; i < length; i++) {
            free((void *)CFArrayGetValueAtIndex(_groups, i));
        }

        CFRelease(_groups);
        _groups = NULL;
    }
}


- (void) clearWeakReferences
{
    _movie = nil;
}


#pragma mark -
#pragma mark Private Methods

- (NSArray *) _linePathsForOperations:(SwiffShapeOperation *)inOperations
{
    UInt16 index;
    NSMutableArray *result = [NSMutableArray array];

    NSUInteger lineStyleCount = [_lineStyles count];

    for (index = 1; index <= lineStyleCount; index++) {
        SwiffShapeOperation *operation = inOperations;
        SwiffPoint position = { NSIntegerMax, NSIntegerMax };
        SwiffPath *path = nil;
        
        BOOL hadFillStyle = NO;
        
        while (operation->type != SwiffShapeOperationTypeEnd) {
            BOOL   isDuplicate    = operation->duplicate;
            UInt16 lineStyleIndex = operation->lineStyleIndex; 
            UInt16 fillStyleIndex = operation->fillStyleIndex; 
            
            if (lineStyleIndex == index) {
                if (!isDuplicate) { 
                    if (!path) {
                        SwiffLineStyle *lineStyle = [_lineStyles objectAtIndex:(index - 1)];
                        path = [[SwiffPath alloc] initWithLineStyle:lineStyle fillStyle:nil];
                    }

                    sPathAddShapeOperation(path, operation, &position);
                }
                
                if (fillStyleIndex) {
                    hadFillStyle = YES;
                }
            }
            
            operation++;
        }
        
        if (hadFillStyle && ([[path lineStyle] width] == SwiffLineStyleHairlineWidth)) {
            [path setUsesFillHairlineWidth:YES];
        }
        
        if (path) {
            SwiffPathAddOperationEnd(path);

            [result addObject:path];
        }
    }
    
    return result;
}


- (NSArray *) _fillPathsForOperations:(SwiffShapeOperation *)inOperations
{
    NSMutableArray *results = [NSMutableArray array];
    CFMutableDictionaryRef map = CFDictionaryCreateMutable(NULL, 0, NULL, &kCFTypeDictionaryValueCallBacks);
    
    // Collect operations by fill style
    SwiffShapeOperation *operation = inOperations;
    while (operation->type != SwiffShapeOperationTypeEnd) {
        const void *key = (const void *)operation->fillStyleIndex;
        if (!key) {
            operation++;
            continue;
        }

        CFMutableArrayRef operations = (CFMutableArrayRef)CFDictionaryGetValue(map, key);

        if (!operations) {
            operations = CFArrayCreateMutable(NULL, 0, NULL);
            CFDictionarySetValue(map, key, operations);
            CFRelease(operations);
        }
    
        CFArrayAppendValue(operations, operation);
        operation++;
    }

    CFIndex      i, j;
    CFIndex      count  = CFDictionaryGetCount(map);
    CFIndex     jCount;
    const void **keys   = malloc(count * sizeof(void *));
    const void **values = malloc(count * sizeof(void *));

    CFDictionaryGetKeysAndValues(map, keys, values);
    
    for (i = 0; i < count; i++) {
        NSInteger fillStyleIndex = (NSInteger)keys[i];
        CFMutableArrayRef operations = (CFMutableArrayRef)values[i];

        CFMutableArrayRef sortedOperations = CFArrayCreateMutable(NULL, 0, NULL);

        SwiffShapeOperation *currentOperation = (SwiffShapeOperation *)CFArrayGetValueAtIndex(operations, 0);
        SwiffShapeOperation *firstOperation   = NULL;

        CFArrayAppendValue(sortedOperations, currentOperation);
        CFArrayRemoveValueAtIndex(operations, 0);
        firstOperation = currentOperation;
        
        SwiffLog(@"Shape", @"[%hd] firstOperation = %@", _libraryID, SwiffStringFromShapeOperation(firstOperation));
        while ((jCount = CFArrayGetCount(operations)) > 0) {
            for (j = 0; j < jCount; j++) {
                SwiffShapeOperation *o = (SwiffShapeOperation *)CFArrayGetValueAtIndex(operations, j);
                SwiffPoint point1 = o->fromPoint;
                SwiffPoint point2 = currentOperation->toPoint;
                
                if ((point1.x == point2.x) && (point1.y == point2.y)) {
                    SwiffLog(@"Shape", @"[%hd] Found connecting path operation", _libraryID);

                    CFArrayAppendValue(sortedOperations, o);
                    currentOperation = o;
                    SwiffLog(@"Shape", @"[%hd] currentOperation = %@", _libraryID, SwiffStringFromShapeOperation(currentOperation));
                    break;
                }
            }
            
            
            CFRange entireRange = { 0, CFArrayGetCount(operations) };
            CFIndex indexOfCurrent = CFArrayGetFirstIndexOfValue(operations, entireRange, currentOperation);
            if (indexOfCurrent != kCFNotFound) {
                CFArrayRemoveValueAtIndex(operations, indexOfCurrent);

            } else {
                while ((jCount = CFArrayGetCount(operations)) > 0) {
                    currentOperation = (SwiffShapeOperation *)CFArrayGetValueAtIndex(operations, 0);
                    CFArrayRemoveValueAtIndex(operations, 0);

                    SwiffLog(@"Shape", @"[%hd] No connecting path operation found", _libraryID);
                    SwiffLog(@"Shape", @"[%hd] currentOperation = %@", _libraryID, SwiffStringFromShapeOperation(currentOperation));

                    SwiffPoint point1 = firstOperation->fromPoint;
                    SwiffPoint point2 = currentOperation->toPoint;

                    if ((point1.x == point2.x) && (point1.y == point2.y)) {
                        CFArrayInsertValueAtIndex(sortedOperations, 0, currentOperation);
                        firstOperation = currentOperation;
                        SwiffLog(@"Shape", @"[%hd] firstOperation = %@", _libraryID, SwiffStringFromShapeOperation(firstOperation));

                    } else {
                        CFArrayAppendValue(sortedOperations, currentOperation);
                        SwiffLog(@"Shape", @"[%hd] No join found, moving to: %@", _libraryID, SwiffStringFromShapeOperation(currentOperation));
                        break;
                    }
                }
            }
        }
        
        jCount = CFArrayGetCount(sortedOperations);
        if (jCount > 0) {
            SwiffFillStyle *fillStyle = [_fillStyles objectAtIndex:(fillStyleIndex - 1)];
            if (fillStyle) {
                SwiffPath *path = [[SwiffPath alloc] initWithLineStyle:nil fillStyle:fillStyle];
                SwiffPoint position = { NSIntegerMax, NSIntegerMax };

                for (j = 0; j < jCount; j++) {
                    SwiffShapeOperation *op = (SwiffShapeOperation *)CFArrayGetValueAtIndex(sortedOperations, j);
                    sPathAddShapeOperation(path, op, &position);
                }

                SwiffPathAddOperationEnd(path);

                [results addObject:path];
            }
        }

        CFRelease(sortedOperations);
    }
    
    CFRelease(map);
    
    if (keys) free(keys);
    if (values) free(values);

    return results;
}

static inline CGFloat quad(CGFloat t, SwiffTwips p0, SwiffTwips p1, SwiffTwips p2)
{
    return (1 - t) * (1 - t) * p0 + 2 * (1 - t) * t * p1 + t * t * p2;
}

- (void)calculateBounds
{
    
    CGFloat maxWidth = 0.0;
    for (SwiffLineStyle *lineStyle in _lineStyles) {
        CGFloat width = [lineStyle width];
        if (width > maxWidth) maxWidth = width;
    }
    
    __block SwiffPoint topLeft = {INT_MAX, INT_MAX};
    __block SwiffPoint bottomRight = {-INT_MAX, -INT_MAX};
    void (^addPointToBounds)(SwiffPoint pt) = ^(SwiffPoint pt){
        if (pt.x < topLeft.x) {
            topLeft.x = pt.x;
        }
        if (pt.x > bottomRight.x) {
            bottomRight.x = pt.x;
        }
        
        if (pt.y < topLeft.y) {
            topLeft.y = pt.y;
        }
        if (pt.y > bottomRight.y) {
            bottomRight.y = pt.y;
        }
    };
    
    CFIndex length = CFArrayGetCount(_groups);
    for (CFIndex i = 0; i < length; i++) {
        const SwiffShapeOperation *ops = CFArrayGetValueAtIndex(_groups, i);
        while (ops->type != SwiffShapeOperationTypeEnd) {
            addPointToBounds(ops->fromPoint);
            addPointToBounds(ops->toPoint);
            if (ops->type == SwiffShapeOperationTypeCurve) {
                CGFloat tx = (CGFloat)(ops->fromPoint.x - ops->controlPoint.x) / (ops->fromPoint.x - 2 * ops->controlPoint.x + ops->toPoint.x);
                if (tx >= 0 && tx <= 1) {
                    SwiffPoint pt = {
                        quad(tx, ops->fromPoint.x, ops->controlPoint.x, ops->toPoint.x),
                        quad(tx, ops->fromPoint.y, ops->controlPoint.y, ops->toPoint.y)
                    };
                    addPointToBounds(pt);
                }
                CGFloat ty = (CGFloat)(ops->fromPoint.y - ops->controlPoint.y) / (ops->fromPoint.y - 2 * ops->controlPoint.y + ops->toPoint.y);
                if (ty >= 0 && ty <= 1) {
                    SwiffPoint pt = {
                        quad(ty, ops->fromPoint.x, ops->controlPoint.x, ops->toPoint.x),
                        quad(ty, ops->fromPoint.y, ops->controlPoint.y, ops->toPoint.y)
                    };
                    addPointToBounds(pt);
                }
            }
            ops++;
        }
    }
    
    if (topLeft.x < bottomRight.x && topLeft.y < bottomRight.y) {
        _bounds = CGRectMake(SwiffGetCGFloatFromTwips(topLeft.x), SwiffGetCGFloatFromTwips(topLeft.y),
                             SwiffGetCGFloatFromTwips(bottomRight.x - topLeft.x), SwiffGetCGFloatFromTwips(bottomRight.y - topLeft.y));
    } else {
        _bounds = CGRectZero;
    }

    CGFloat padding = SwiffCeil(maxWidth / 2.0) + 1;
    _renderBounds = CGRectInset(_bounds, -padding, -padding);    
}

- (void) _makePaths
{
    @autoreleasepool {
        NSMutableArray *result = [[NSMutableArray alloc] init];

        CFIndex length = CFArrayGetCount(_groups);
        for (CFIndex i = 0; i < length; i++) {
            SwiffShapeOperation *operations = (SwiffShapeOperation *)CFArrayGetValueAtIndex(_groups, i);
           
            [result addObjectsFromArray:[self _fillPathsForOperations:operations]];
            [result addObjectsFromArray:[self _linePathsForOperations:operations]];
        
            free(operations);
        }
        
        CFRelease(_groups);
        _groups = NULL;

        _paths = result;
    }
}


#pragma mark -
#pragma mark Accessors

- (NSArray *) paths
{
    if (!_paths && _groups) {
        [self _makePaths];
    }
    return _paths;
}
@end


@interface SwiffMorphShapeDefinition ()
@property(nonatomic, assign) CGRect startBounds;
@property(nonatomic, assign) CGRect endBounds;
@property(nonatomic, strong) NSArray *fillStyles;
@property(nonatomic, strong) NSArray *lineStyles;
@property(nonatomic, strong) SwiffShapeDefinition *startShape;
@property(nonatomic, strong) SwiffShapeDefinition *endShape;
@end

@implementation SwiffMorphShapeDefinition

@synthesize movie        = _movie,
            libraryID    = _libraryID,
            bounds       = _bounds,
            renderBounds = _renderBounds;

- (id) initWithParser:(SwiffParser *)parser movie:(SwiffMovie *)movie
{
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

        if (version == 2) {
            SwiffLog(@"MorphShape", @"MorphShape2 is not yet supported");
            return nil;
        }
        
        UInt32 offset;
        SwiffParserReadUInt32(parser, &offset);
        
        _fillStyles = SwiffParserReadArrayOfObjects(parser, [SwiffMorphFillStyle class]);
        _lineStyles = SwiffParserReadArrayOfObjects(parser, [SwiffMorphLineStyle class]);
        _startShape = [[SwiffShapeDefinition alloc] initWithParser:parser movie:movie];
        _endShape = [[SwiffShapeDefinition alloc] initWithParser:parser movie:movie];
        
        if (CFArrayGetCount(_startShape.groups) != CFArrayGetCount(_endShape.groups)) {
            NSLog(@"DIFFERENT NUMBER OF SHAPES IN MORPH");
            return nil;
        }
        
        if (!SwiffParserIsValid(parser)) {
            return nil;
        }
    }
    return self;
}

- (void)clearWeakReferences
{
    
}

- (SwiffShapeDefinition *)shapeWithRatio:(CGFloat)ratio
{    
    NSMutableArray *fillStyles = [NSMutableArray arrayWithCapacity:_fillStyles.count];
    for (SwiffMorphFillStyle *fillStyle in _fillStyles) {
        [fillStyles addObject:[fillStyle fillStyleWithRatio:ratio]];
    }

    NSMutableArray *lineStyles = [NSMutableArray arrayWithCapacity:_lineStyles.count];
    for (SwiffMorphLineStyle *lineStyle in _lineStyles) {
        [lineStyles addObject:[lineStyle lineStyleWithRatio:ratio]];
    }

    CFIndex length = CFArrayGetCount(_startShape.groups);
    CFMutableArrayRef groups = CFArrayCreateMutable(NULL, 0, NULL);    
    for (CFIndex i = 0; i < length; i++) {
        const SwiffShapeOperation *startOps = CFArrayGetValueAtIndex(_startShape.groups, i);
        const SwiffShapeOperation *endOps = CFArrayGetValueAtIndex(_endShape.groups, i);

        const SwiffShapeOperation *lenOps = startOps;
        while (lenOps->type != SwiffShapeOperationTypeEnd) {
            lenOps++;
        }
        int numOps = lenOps - startOps + 1;
        
        SwiffShapeOperation *ops = malloc(numOps * sizeof(SwiffShapeOperation));
        CFArrayAppendValue(groups, ops);
        for (int j = 0; j < numOps; j++) {
            ops->type = startOps->type;
            ops->lineStyleIndex = startOps->type;
            ops->fillStyleIndex = startOps->fillStyleIndex;
            ops->duplicate = startOps->duplicate;
            ops->fromPoint.x = startOps->fromPoint.x + (endOps->fromPoint.x - startOps->fromPoint.x) * ratio;
            ops->fromPoint.y = startOps->fromPoint.y + (endOps->fromPoint.y - startOps->fromPoint.y) * ratio;
            ops->controlPoint.x = startOps->controlPoint.x + (endOps->controlPoint.x - startOps->controlPoint.x) * ratio;
            ops->controlPoint.y = startOps->controlPoint.y + (endOps->controlPoint.y - startOps->controlPoint.y) * ratio;
            ops->toPoint.x = startOps->toPoint.x + (endOps->toPoint.x - startOps->toPoint.x) * ratio;
            ops->toPoint.y = startOps->toPoint.y + (endOps->toPoint.y - startOps->toPoint.y) * ratio;
            ops++;
            startOps++;
            endOps++;
        }
    }


    SwiffShapeDefinition *result = [[SwiffShapeDefinition alloc] init];
    result.movie = _movie;
    result.libraryID = _libraryID;
    result.fillStyles = fillStyles;
    result.lineStyles = lineStyles;
    result.groups = groups;
    [result calculateBounds];
    return result;
}
@end
