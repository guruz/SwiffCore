/*
    SwiffFillStyle.m
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

#import "SwiffFillStyle.h"
#import "SwiffParser.h"
#import "SwiffGradient.h"
#import "SwiffUtils.h"


#define IS_COLOR_TYPE(type)    (type == SwiffFillStyleTypeColor)

#define IS_GRADIENT_TYPE(type) ((type == SwiffFillStyleTypeLinearGradient) || \
                          (type == SwiffFillStyleTypeRadialGradient) || \
                          (type == SwiffFillStyleTypeFocalRadialGradient))

#define IS_BITMAP_TYPE(type)   ((type >= SwiffFillStyleTypeRepeatingBitmap) && (type <= SwiffFillStyleTypeNonSmoothedClippedBitmap))

@interface SwiffFillStyle()
@property (nonatomic, assign) SwiffFillStyleType type;
@property (nonatomic, assign) SwiffColor color;
@property (nonatomic, strong) SwiffGradient *gradient;
@property (nonatomic, assign) CGAffineTransform transform;
@property (nonatomic, assign) UInt16 bitmapID;
@end

@implementation SwiffFillStyle

- (id) initWithColor:(SwiffColor*)fill_color
{
    if ((self = [super init])) {
        //initialize the color
        _color = (SwiffColor){0,0,0,1};

        //copy the fill_color... is this neccessary? can we just directly assign?
        _color.red      = fill_color->red;
        _color.green    = fill_color->green;
        _color.blue     = fill_color->blue;
        _color.alpha    = fill_color->alpha;
        
        _type = SwiffFillStyleTypeColor;
    }
    
    return self;
}

- (id) initWithParser:(SwiffParser *)parser
{
    if ((self = [super init])) {
        SwiffParserReadUInt8(parser, &_type);

        if (IS_COLOR_TYPE(_type)) {
            SwiffTag  tag     = SwiffParserGetCurrentTag(parser);
            NSInteger version = SwiffParserGetCurrentTagVersion(parser);
        
            if ((tag == SwiffTagDefineShape) && (version >= 3)) {
                SwiffParserReadColorRGBA(parser, &_color);
            } else {
                SwiffParserReadColorRGB(parser, &_color);
            }

        } else if (IS_GRADIENT_TYPE(_type)) {
            SwiffParserReadMatrix(parser, &_transform);
            BOOL isFocalGradient = (_type == SwiffFillStyleTypeFocalRadialGradient);

            _gradient = [[SwiffGradient alloc] initWithParser:parser isFocalGradient:isFocalGradient];

        } else if (IS_BITMAP_TYPE(_type)) {
            SwiffParserReadUInt16(parser, &_bitmapID);
            SwiffParserReadMatrix(parser, &_transform);

            _transform.a /= 20.0;
            _transform.d /= 20.0;

        } else {
            return nil;
        }

        if (!SwiffParserIsValid(parser)) {
            return nil;
        }
    }

    return self;
}


- (NSString *) description
{
    NSString *typeString = nil;

    if (_type == SwiffFillStyleTypeColor) {

        typeString = [NSString stringWithFormat:@"#%02lX%02lX%02lX, %ld%%",
            (long)(_color.red   * 255.0),
            (long)(_color.green * 255.0),
            (long)(_color.blue  * 255.0),
            (long)(_color.alpha * 100.0)
        ];

    } else if (_type == SwiffFillStyleTypeLinearGradient) {
        typeString = @"LinearGradient";
    } else if (_type == SwiffFillStyleTypeRadialGradient) {
        typeString = @"RadialGradient";
    } else if (_type == SwiffFillStyleTypeFocalRadialGradient) {
        typeString = @"FocalRadialGradient";
    } else if (_type == SwiffFillStyleTypeRepeatingBitmap) {
        typeString = @"RepeatingBitmap";
    } else if (_type == SwiffFillStyleTypeClippedBitmap) {
        typeString = @"ClippedBitmap";
    } else if (_type == SwiffFillStyleTypeNonSmoothedRepeatingBitmap) {
        typeString = @"NonSmoothedRepeatingBitmap";
    } else if (_type == SwiffFillStyleTypeNonSmoothedClippedBitmap) {
        typeString = @"NonSmoothedClippedBitmap";
    }

    return [NSString stringWithFormat:@"<%@: %p; %@>", [self class], self, typeString];
}


#pragma mark -
#pragma mark Accessors

- (SwiffColor *) colorPointer
{
    return IS_COLOR_TYPE(_type) ? &_color : NULL;
}


- (CGAffineTransform) gradientTransform
{
    return IS_GRADIENT_TYPE(_type) ? _transform : CGAffineTransformIdentity;
}


- (CGAffineTransform) bitmapTransform
{
    return IS_BITMAP_TYPE(_type) ? _transform : CGAffineTransformIdentity;
}

@end

@implementation SwiffMorphFillStyle {
    SwiffColor _startColor;
    SwiffColor _endColor;
    CGAffineTransform  _startTransform;
    CGAffineTransform  _endTransform;
}


- (id) initWithParser:(SwiffParser *)parser
{
    if ((self = [super init])) {
        UInt8 type;
        SwiffParserReadUInt8(parser, &type);
        self.type = type;
        
        if (IS_COLOR_TYPE(type)) {
            SwiffParserReadColorRGBA(parser, &_startColor);
            SwiffParserReadColorRGBA(parser, &_endColor);
        } else if (IS_GRADIENT_TYPE(type)) {
            SwiffParserReadMatrix(parser, &_startTransform);
            SwiffParserReadMatrix(parser, &_endTransform);
            self.gradient = [[SwiffMorphGradient alloc] initWithParser:parser];
        } else if (IS_BITMAP_TYPE(type)) {
            UInt16 bitmapID;
            SwiffParserReadUInt16(parser, &bitmapID);
            self.bitmapID = bitmapID;
            SwiffParserReadMatrix(parser, &_startTransform);
            _startTransform.a = SwiffGetCGFloatFromTwips(_startTransform.a);
            _startTransform.d = SwiffGetCGFloatFromTwips(_startTransform.d);
            
            SwiffParserReadMatrix(parser, &_endTransform);
            _endTransform.a = SwiffGetCGFloatFromTwips(_endTransform.a);
            _endTransform.d = SwiffGetCGFloatFromTwips(_endTransform.d);
            
        } else {
            return nil;
        }
        
        if (!SwiffParserIsValid(parser)) {
            return nil;
        }
    }
    
    return self;
}


- (NSString *) description
{
    NSString *typeString = nil;
    UInt8 type = self.type;
    
    if (type == SwiffFillStyleTypeColor) {
        
        typeString = [NSString stringWithFormat:@"%@ -> %@",
                      SwiffStringFromColor(_startColor), SwiffStringFromColor(_endColor)];        
    } else if (type == SwiffFillStyleTypeLinearGradient) {
        typeString = @"MorphLinearGradient";
    } else if (type == SwiffFillStyleTypeRadialGradient) {
        typeString = @"MorphRadialGradient";
    } else if (type == SwiffFillStyleTypeFocalRadialGradient) {
        typeString = @"MorphFocalRadialGradient";
    } else if (type == SwiffFillStyleTypeRepeatingBitmap) {
        typeString = @"MorphRepeatingBitmap";
    } else if (type == SwiffFillStyleTypeClippedBitmap) {
        typeString = @"MorphClippedBitmap";
    } else if (type == SwiffFillStyleTypeNonSmoothedRepeatingBitmap) {
        typeString = @"MorphNonSmoothedRepeatingBitmap";
    } else if (type == SwiffFillStyleTypeNonSmoothedClippedBitmap) {
        typeString = @"MorphNonSmoothedClippedBitmap";
    }
    
    return [NSString stringWithFormat:@"<%@: %p; %@>", [self class], self, typeString];
}

- (void)setRatio:(CGFloat)ratio
{
    _ratio = ratio;
    self.color = SwiffColorInterpolate(_startColor, _endColor, ratio);
    self.transform = CGAffineTransformMake(_startTransform.a + (_endTransform.a - _startTransform.a) * ratio,
                                           _startTransform.b + (_endTransform.b - _startTransform.b) * ratio,
                                           _startTransform.c + (_endTransform.c - _startTransform.c) * ratio,
                                           _startTransform.d + (_endTransform.d - _startTransform.d) * ratio,
                                           _startTransform.tx + (_endTransform.tx - _startTransform.tx) * ratio,
                                           _startTransform.ty + (_endTransform.ty - _startTransform.ty) * ratio);

    if ([self.gradient isKindOfClass:[SwiffMorphGradient class]]) {
        ((SwiffMorphGradient *)self.gradient).ratio = ratio;
    }
}
@end
