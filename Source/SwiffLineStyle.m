/*
    SwiffLineStyle.m
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

#import "SwiffLineStyle.h"
#import "SwiffParser.h"
#import "SwiffFillStyle.h"
#import "SwiffUtils.h"

const CGFloat SwiffLineStyleHairlineWidth = CGFLOAT_MIN;

@interface SwiffLineStyle()
@property (nonatomic, strong) SwiffFillStyle *fillStyle;

@property (nonatomic, assign) CGLineCap startLineCap;
@property (nonatomic, assign) CGLineCap endLineCap;
@property (nonatomic, assign) CGLineJoin lineJoin;
@property (nonatomic, assign) CGFloat miterLimit;

@property (nonatomic, assign, getter=isPixelAligned) BOOL pixelAligned;
@property (nonatomic, assign) BOOL scalesHorizontally;
@property (nonatomic, assign) BOOL scalesVertically;
@property (nonatomic, assign) BOOL closesStroke;
@end

@implementation SwiffLineStyle

static inline CGFloat getLineWidth(UInt32 width) {
    CGFloat result = SwiffLineStyleHairlineWidth;
    if (width > 1) {
        result = SwiffGetCGFloatFromTwips(width);
    }
    return result;
}

static inline CGLineCap getLineCap(UInt32 capStyle) {
    CGLineCap result = kCGLineCapRound;
    
    if (capStyle == 1) {
        result = kCGLineCapButt;
    } else if (capStyle == 2) {
        result = kCGLineCapSquare;
    }
    
    return result;
};

static inline CGLineJoin getLineJoin(UInt32 joinStyle) {
    CGLineJoin result = kCGLineJoinRound;
    
    if (joinStyle == 1) {
        result = kCGLineJoinBevel;
    } else if (joinStyle == 2) {
        result = kCGLineJoinMiter;
    }
    
    return result;
};

- (id) initWithParser:(SwiffParser *)parser
{
    if ((self = [super init])) {
        UInt16 width;
        SwiffParserReadUInt16(parser, &width);
        _width = getLineWidth(width);

        NSInteger version = SwiffParserGetCurrentTagVersion(parser);

        if (version < 3) {
            SwiffParserReadColorRGB(parser, &_color);
            _closesStroke = YES;

        } else if (version == 3) {
            SwiffParserReadColorRGBA(parser, &_color);
            _closesStroke = YES;

        } else {
            UInt32 startCapStyle, joinStyle, hasFillFlag, noHScaleFlag, noVScaleFlag, pixelHintingFlag, reserved, noClose, endCapStyle;

            SwiffParserReadUBits(parser, 2, &startCapStyle);
            SwiffParserReadUBits(parser, 2, &joinStyle);
            SwiffParserReadUBits(parser, 1, &hasFillFlag);
            SwiffParserReadUBits(parser, 1, &noHScaleFlag);
            SwiffParserReadUBits(parser, 1, &noVScaleFlag);
            SwiffParserReadUBits(parser, 1, &pixelHintingFlag);
            SwiffParserReadUBits(parser, 5, &reserved);
            SwiffParserReadUBits(parser, 1, &noClose);
            SwiffParserReadUBits(parser, 2, &endCapStyle);
            
            _startLineCap       =  getLineCap(startCapStyle);
            _endLineCap         =  getLineCap(endCapStyle);
            _lineJoin           =  getLineJoin(joinStyle);
            _scalesHorizontally = !noHScaleFlag && (_width != SwiffLineStyleHairlineWidth);
            _scalesVertically   = !noVScaleFlag && (_width != SwiffLineStyleHairlineWidth);
            _pixelAligned       =  pixelHintingFlag;
            _closesStroke       = !noClose;

            if (_lineJoin == kCGLineJoinMiter) {
                SwiffParserReadFixed8(parser, &_miterLimit);
            }

            if (!hasFillFlag) {
                SwiffParserReadColorRGBA(parser, &_color);

            } else {
                _color.red   = 0;
                _color.green = 0;
                _color.blue  = 0;
                _color.alpha = 255;
                
                _fillStyle = [[SwiffFillStyle alloc] initWithParser:parser];
            }
        }

        if (!SwiffParserIsValid(parser)) {
            return nil;
        }
    }
    
    return self;
}


- (SwiffColor *) colorPointer
{
    return &_color;
}


@end


@implementation SwiffMorphLineStyle {
    CGFloat _startWidth;
    CGFloat _endWidth;
    SwiffColor _startColor;
    SwiffColor _endColor;
}

- (id)initWithParser:(SwiffParser *)parser
{
    if ((self = [super init])) {
        UInt16 width;
        SwiffParserReadUInt16(parser, &width);
        _startWidth = getLineWidth(width);

        SwiffParserReadUInt16(parser, &width);
        _endWidth = getLineWidth(width);
        
        NSInteger version = SwiffParserGetCurrentTagVersion(parser);
        
        if (version == 1) {
            SwiffParserReadColorRGBA(parser, &_startColor);
            SwiffParserReadColorRGBA(parser, &_endColor);
        } else if (version == 2) {
            UInt32 startCapStyle, joinStyle, hasFillFlag, noHScaleFlag, noVScaleFlag, pixelHintingFlag, reserved, noClose, endCapStyle;
            
            SwiffParserReadUBits(parser, 2, &startCapStyle);
            SwiffParserReadUBits(parser, 2, &joinStyle);
            SwiffParserReadUBits(parser, 1, &hasFillFlag);
            SwiffParserReadUBits(parser, 1, &noHScaleFlag);
            SwiffParserReadUBits(parser, 1, &noVScaleFlag);
            SwiffParserReadUBits(parser, 1, &pixelHintingFlag);
            SwiffParserReadUBits(parser, 5, &reserved);
            SwiffParserReadUBits(parser, 1, &noClose);
            SwiffParserReadUBits(parser, 2, &endCapStyle);
            
            self.startLineCap       =  getLineCap(startCapStyle);
            self.endLineCap         =  getLineCap(endCapStyle);
            self.lineJoin           =  getLineJoin(joinStyle);
            self.scalesHorizontally = !noHScaleFlag;
            self.scalesVertically   = !noVScaleFlag;
            self.pixelAligned       =  pixelHintingFlag;
            self.closesStroke       = !noClose;
            
            if (self.lineJoin == kCGLineJoinMiter) {
                CGFloat miterLimit;
                SwiffParserReadFixed8(parser, &miterLimit);
                self.miterLimit = miterLimit;
            }
            
            if (!hasFillFlag) {
                SwiffParserReadColorRGBA(parser, &_startColor);
                SwiffParserReadColorRGBA(parser, &_endColor);                
            } else {
                _startColor.red   = 0;
                _startColor.green = 0;
                _startColor.blue  = 0;
                _startColor.alpha = 255;
                
                _endColor = _startColor;
                
                self.fillStyle = [[SwiffMorphFillStyle alloc] initWithParser:parser];
            }
        }
        
        if (!SwiffParserIsValid(parser)) {
            return nil;
        }
    }
    
    return self;
}
@end

