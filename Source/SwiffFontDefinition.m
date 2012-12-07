/*
    SwiffFont.m
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


#import "SwiffFontDefinition.h"
#import "SwiffParser.h"
#import "SwiffShapeDefinition.h"
#import "SwiffUtils.h"

const CGFloat SwiffFontEmSquareHeight = 1024;

@implementation SwiffFontDefinition

@synthesize movie     = _movie,
            libraryID = _libraryID;


- (id) initWithLibraryID:(UInt16)libraryID movie:(SwiffMovie *)movie
{
    if ((self = [super init])) {
        _movie = movie;
        _libraryID = libraryID;
    }
    
    return self;
}


- (void) dealloc
{
    if (_glyphPaths) {
        for (NSInteger i = 0; i < _glyphCount; i++) {
            CGPathRelease(_glyphPaths[i]);
            _glyphPaths[i] = NULL;
        }
    }

    free(_glyphPaths);       _glyphPaths     = NULL;
    free(_codeTable);        _codeTable      = NULL;
    free(_glyphAdvances);    _glyphAdvances  = NULL;
    free(_glyphBounds);      _glyphBounds    = NULL;
    free(_kerningRecords);   _kerningRecords = NULL;
}


- (void) clearWeakReferences
{
    _movie = nil;
}


#pragma mark -
#pragma mark Called by Movie


- (void) _readGlyphPathsFromParser:(SwiffParser *)parser
{
    _glyphPaths = calloc(sizeof(CGPathRef), _glyphCount);

    for (NSInteger i = 0; i < _glyphCount; i++) {
        _glyphPaths[i] = SwiffParserReadPathFromShapeRecord(parser);
    }
}


- (void) _readCodeTableFromParser:(SwiffParser *)parser wide:(BOOL)wide
{
    if (!_codeTable) {
        _codeTable = malloc(_glyphCount * sizeof(UInt16));
    }

    for (NSUInteger i = 0; i < _glyphCount; i++) {
        UInt16 value;

        if (wide) {
            SwiffParserReadUInt16(parser, &value);
        } else {
            UInt8 value8;
            SwiffParserReadUInt8(parser, &value8);
            value = value8;
        }

        _codeTable[i] = value;
    }
}


- (void) readDefineFontTagFromParser:(SwiffParser *)parser
{
    NSInteger version = SwiffParserGetCurrentTagVersion(parser);

    if (version == 1) {
        // Per documentation:
        // "...the number of entries in each table (the number of glyphs in the font) can be inferred
        // by dividing the first entry in the OffsetTable by two."
        //
        UInt16 offset;
        SwiffParserReadUInt16(parser, &offset);
        _glyphCount = (offset / 2);

        // Skip through OffsetTable
        if (_glyphCount) {
            SwiffParserAdvance(parser, sizeof(UInt16) * (_glyphCount - 1));
            [self _readGlyphPathsFromParser:parser];
        }

    } else if (version == 2 || version == 3) {
        UInt32 hasLayout, isShiftJIS, isSmallText, isANSIEncoding,
               usesWideOffsets, usesWideCodes, isItalic, isBold;

        SwiffParserReadUBits(parser, 1, &hasLayout);
        SwiffParserReadUBits(parser, 1, &isShiftJIS);
        SwiffParserReadUBits(parser, 1, &isSmallText);
        SwiffParserReadUBits(parser, 1, &isANSIEncoding);
        SwiffParserReadUBits(parser, 1, &usesWideOffsets);
        SwiffParserReadUBits(parser, 1, &usesWideCodes);
        SwiffParserReadUBits(parser, 1, &isItalic);
        SwiffParserReadUBits(parser, 1, &isBold);

        _italic = isItalic;
        _bold   = isBold;
        _smallText = isSmallText;

        if (isANSIEncoding) {
            _encoding = SwiffGetANSIStringEncoding();
        } else if (isShiftJIS) {
            _encoding = NSShiftJISStringEncoding;
        } else {
            _encoding = NSUnicodeStringEncoding;
        }

        UInt8 languageCode;
        SwiffParserReadUInt8(parser, &languageCode);
        _languageCode = languageCode;
    
        NSString *name = nil;
        SwiffParserReadLengthPrefixedString(parser, &name);
        _name = name;
        
        UInt16 glyphCount;
        SwiffParserReadUInt16(parser, &glyphCount);
        _glyphCount = glyphCount;
    
        // Skip OffsetTable and CodeTableOffset
        SwiffParserAdvance(parser, (usesWideOffsets ? sizeof(UInt32) : sizeof(UInt16)) * (glyphCount + 1));

        [self _readGlyphPathsFromParser:parser];
        [self _readCodeTableFromParser:parser wide:usesWideCodes];

        if (hasLayout) {
            _hasLayout = YES;

            SInt16 ascent, descent, leading;
            SwiffParserReadSInt16(parser, &ascent);
            SwiffParserReadSInt16(parser, &descent);
            SwiffParserReadSInt16(parser, &leading);

            _ascent  = SwiffGetCGFloatFromTwips(ascent);
            _descent = SwiffGetCGFloatFromTwips(descent);
            _leading = SwiffGetCGFloatFromTwips(leading);

            _glyphAdvances = _glyphCount ? malloc(sizeof(CGFloat) * _glyphCount) : NULL;
            for (NSInteger i = 0; i < _glyphCount; i++) {
                SInt16 advance;
                SwiffParserReadSInt16(parser, &advance);
                _glyphAdvances[i] = SwiffGetCGFloatFromTwips(advance);
            }

            _glyphBounds = _glyphCount ? malloc(sizeof(CGRect) * _glyphCount) : NULL;
            for (NSInteger i = 0; i < _glyphCount; i++) {
                CGRect rect;
                SwiffParserReadRect(parser, &rect);
                _glyphBounds[i] = rect;
            }

            UInt16 kerningCount;
            SwiffParserReadUInt16(parser, &kerningCount);
            _kerningCount = kerningCount;
            _kerningRecords = kerningCount ? malloc(sizeof(SwiffFontKerningRecord) * _kerningCount) : NULL;

            for (NSInteger i = 0; i < _kerningCount; i++) {
                if (usesWideCodes) {
                    UInt16 tmp;
                    SwiffParserReadUInt16(parser, &tmp);
                    _kerningRecords[i].leftCharacterCode = tmp;

                    SwiffParserReadUInt16(parser, &tmp);
                    _kerningRecords[i].rightCharacterCode = tmp;
    
                } else {
                    UInt8 tmp;
                    SwiffParserReadUInt8(parser, &tmp);
                    _kerningRecords[i].leftCharacterCode = tmp;

                    SwiffParserReadUInt8(parser, &tmp);
                    _kerningRecords[i].rightCharacterCode = tmp;
                }
                
                SInt16 adjustment;
                SwiffParserReadSInt16(parser, &adjustment);
                _kerningRecords[i].adjustment = SwiffGetCGFloatFromTwips(adjustment);
            }
        }

    } else if (version == 4) {
        //!issue6: DefineFont4 support
    }
}


- (void) readDefineFontNameTagFromParser:(SwiffParser *)parser
{
    NSString *name = nil;
    SwiffParserReadString(parser, &name);
    _fullName = name;

    NSString *copyright = nil;
    SwiffParserReadString(parser, &copyright);
    _copyright = copyright;
}


- (void) readDefineFontInfoTagFromParser:(SwiffParser *)parser
{
    UInt32 reserved, isSmallText, isShiftJIS, isANSIEncoding, isItalic, isBold, usesWideCodes;

    NSString *name;
    SwiffParserReadLengthPrefixedString(parser, &name);
    _name = name;

    SwiffParserReadUBits(parser, 2, &reserved);
    SwiffParserReadUBits(parser, 1, &isSmallText);
    SwiffParserReadUBits(parser, 1, &isShiftJIS);
    SwiffParserReadUBits(parser, 1, &isANSIEncoding);
    SwiffParserReadUBits(parser, 1, &isItalic);
    SwiffParserReadUBits(parser, 1, &isBold);
    SwiffParserReadUBits(parser, 1, &usesWideCodes);
    
    _italic = isItalic;
    _bold   = isBold;
    _smallText = isSmallText;

    if (isANSIEncoding) {
        _encoding = SwiffGetANSIStringEncoding();
    } else if (isShiftJIS) {
        _encoding = NSShiftJISStringEncoding;
    } else {
        _encoding = NSUnicodeStringEncoding;
    }

    NSInteger version = SwiffParserGetCurrentTagVersion(parser);
    if (version == 2) {
        UInt8 languageCode;
        SwiffParserReadUInt8(parser, &languageCode);
        _languageCode = languageCode;
    }

    _glyphCount = SwiffParserGetBytesRemainingInCurrentTag(parser);
    if (usesWideCodes) _glyphCount /= 2;
    
    [self _readCodeTableFromParser:parser wide:usesWideCodes];
}


- (void) readDefineFontAlignZonesFromParser:(SwiffParser *)parser
{
    //!issue8: DefineFontAlignZones tag
}


#pragma mark -
#pragma mark Accessors

- (CGRect) bounds       { return CGRectZero; }
- (CGRect) renderBounds { return CGRectZero; }

@end
