//
//  SwiffGraphics.m
//  SwiffCore
//
//  Created by Will Hankinson on 9/28/12.
//
//

#import "SwiffFillStyle.h"
#import "SwiffGraphics.h"
#import "SwiffPath.h"

@implementation SwiffGraphics

float _lastX;
float _lastY;

-(id) init
{
    if ((self = [super init])) {

        _paths = [[NSMutableArray alloc] init];
        _currentFill = nil;
        _currentStroke = nil;
        _currentFillStyle = nil;
        _currentLineStyle = nil;
        
        _lastX = 0;
        _lastY = 0;
    }
    
    return self;
}

- (void) dealloc
{
    if(_paths)
    {
        [_paths removeAllObjects];
    }
    
    
}

-(NSMutableArray*) pathsToRender
{
    NSMutableArray* toRender = [[NSMutableArray alloc] initWithArray:_paths copyItems:YES];
    if(_currentFill) [toRender addObject:_currentFill];
    if(_currentStroke) [toRender addObject:_currentStroke];
    
    return toRender;
}

-(void) beginFill:(SwiffColor*)color
{
    //if we have a fill path going, end it and start a new one
    if(_currentFill)
    {
        [_paths addObject:_currentFill];
    }
    
    _currentFillStyle = [[SwiffFillStyle alloc] initWithColor:color];
    _currentFill = [[SwiffPath alloc] initWithLineStyle:nil fillStyle:_currentFillStyle];
}


/*
 *  type = radial or linear
 *  colors = array of SwiffColors with alphas
 *  ratios = array of ratios
 *  matrix = null
 *  spreadMethod = PAD/reflect/repeat
 *  interpolationMethod = RGB/linear_rgb
 *  focalPointRatio=0  - only for radial
 */
-(void) beginGradientFillOfType:(SwiffGradientType)type colors:(NSArray*)colors ratios:(NSArray*)ratios matrix:(CGAffineTransform*)matrix spreadMethod:(SwiffSpreadMethod)spreadMethod interpolationMethod:(SwiffInterpolationMethod)interpolationMethod focalPointRatio:(float)focalPointRatio
{
    
}


-(void) clear
{
    if(_paths)
    {
        //does path need any more cleanup?
        [_paths removeAllObjects];
    }
}


-(void) curveToControlX:(float)controlX controlY:(float)controlY anchorX:(float)anchorX anchorY:(float)anchorY
{
    
}


-(void) drawCircleWithX:(float)x y:(float)y radius:(float)radius
{
    
}
-(void) drawEllipseWithX:(float)x y:(float)y width:(float)width height:(float)height
{
    
}


-(void) drawRectWithX:(float)x y:(float)y width:(float)width height:(float)height
{
    
}

-(void) drawRoundRectWithX:(float)x y:(float)y width:(float)width height:(float)height ellipseWidth:(float)ellipseWidth ellipseHeight:(float)ellipseHeight
{
    
}

-(void) endFill
{
    
}

/*
 *  thickness = line with
 *  color     = SwiffColor (with alpha)
 *  pixelHinting = false  (whether or not pixels can be sub-pixel widths)
 *  scaleMode = normal (normal/none/vertical)
 *  caps = round
 *  joints = round
 *  miterLimit = 3
 */
-(void) lineStyleWithThickness:(float)thickness color:(SwiffColor*)color pixelHinting:(bool)pixelHinting scaleMode:(SwiffLineScaleMode)scaleMode caps:(SwiffCapsStyle)caps joints:(SwiffJointStyle)joints miterLimit:(float)miterLimit
{
    
}
-(void) lineToX:(float)x y:(float)y
{    
    if(x == _lastX && y == _lastY)
    {
        NSLog(@"Called lineTo the same location!");
        return;
    }else if(x == _lastX)
    {
        if(_currentFill)
        {
            SwiffPathAddOperationAndFloats(_currentFill, SwiffPathOperationVerticalLine, y);
        }
        if(_currentStroke)
        {
            SwiffPathAddOperationAndFloats(_currentStroke, SwiffPathOperationVerticalLine, y);
        }
    }else if(y == _lastY)
    {
        if(_currentFill)
        {
            SwiffPathAddOperationAndFloats(_currentFill, SwiffPathOperationHorizontalLine, x);
        }
        if(_currentStroke)
        {
            SwiffPathAddOperationAndFloats(_currentStroke, SwiffPathOperationHorizontalLine, x);
        }
    }else{
        if(_currentFill)
        {
            SwiffPathAddOperationAndFloats(_currentFill, SwiffPathOperationLine, x, y);
        }
        if(_currentStroke)
        {
            SwiffPathAddOperationAndFloats(_currentStroke, SwiffPathOperationLine, x, y);
        }
    }
    
    
    _lastX = x;
    _lastY = y;
}

-(void) moveToX:(float)x y:(float)y
{
    //no horizontalMoveTo or verticalMoveTo
    if(x == _lastX && y == _lastY)
    {
        NSLog(@"Called moveTo the same location!");
        return;
    }else{
        if(_currentFill)
        {
            SwiffPathAddOperationAndFloats(_currentFill, SwiffPathOperationMove, x, y);
        }
        if(_currentStroke)
        {
            SwiffPathAddOperationAndFloats(_currentStroke, SwiffPathOperationMove, x, y);
        }
    }
    
    _lastX = x;
    _lastY = y;
}








//DEFAULTS
//these aren't meant to be edited--they just pass default values into the "full" functions

-(void) beginGradientFillOfType:(SwiffGradientType)type colors:(NSArray*)colors ratios:(NSArray*)ratios matrix:(CGAffineTransform*)matrix spreadMethod:(SwiffSpreadMethod)spreadMethod interpolationMethod:(SwiffInterpolationMethod)interpolationMethod
{
    [self beginGradientFillOfType:type colors:colors ratios:ratios matrix:matrix spreadMethod:spreadMethod interpolationMethod:interpolationMethod focalPointRatio:0];
}

-(void) beginGradientFillOfType:(SwiffGradientType)type colors:(NSArray*)colors ratios:(NSArray*)ratios matrix:(CGAffineTransform*)matrix spreadMethod:(SwiffSpreadMethod)spreadMethod
{
    [self beginGradientFillOfType:type colors:colors ratios:ratios matrix:matrix spreadMethod:spreadMethod interpolationMethod:SwiffInterpolationMethodRGB focalPointRatio:0];
}

-(void) beginGradientFillOfType:(SwiffGradientType)type colors:(NSArray*)colors ratios:(NSArray*)ratios matrix:(CGAffineTransform*)matrix
{
    [self beginGradientFillOfType:type colors:colors ratios:ratios matrix:matrix spreadMethod:SwiffSpreadMethodPad interpolationMethod:SwiffInterpolationMethodRGB focalPointRatio:0];
}
-(void) beginGradientFillOfType:(SwiffGradientType)type colors:(NSArray*)colors ratios:(NSArray*)ratios
{
    //TODO: not sure if i should pass nil for matrix or an identity matrix
    [self beginGradientFillOfType:type colors:colors ratios:ratios matrix:nil spreadMethod:SwiffSpreadMethodPad interpolationMethod:SwiffInterpolationMethodRGB focalPointRatio:0];
}
-(void) lineStyleWithThickness:(float)thickness color:(SwiffColor*)color pixelHinting:(bool)pixelHinting scaleMode:(SwiffLineScaleMode)scaleMode caps:(SwiffCapsStyle)caps joints:(SwiffJointStyle)joints
{
    [self lineStyleWithThickness:thickness color:color pixelHinting:pixelHinting scaleMode:scaleMode caps:caps joints:joints miterLimit:3];
}
-(void) lineStyleWithThickness:(float)thickness color:(SwiffColor*)color pixelHinting:(bool)pixelHinting scaleMode:(SwiffLineScaleMode)scaleMode caps:(SwiffCapsStyle)caps
{
    [self lineStyleWithThickness:thickness color:color pixelHinting:pixelHinting scaleMode:scaleMode caps:caps joints:SwiffJointStyleRound miterLimit:3];
}
-(void) lineStyleWithThickness:(float)thickness color:(SwiffColor*)color pixelHinting:(bool)pixelHinting scaleMode:(SwiffLineScaleMode)scaleMode
{
    [self lineStyleWithThickness:thickness color:color pixelHinting:pixelHinting scaleMode:scaleMode caps:SwiffCapsStyleRound joints:SwiffJointStyleRound miterLimit:3];
}
-(void) lineStyleWithThickness:(float)thickness color:(SwiffColor*)color pixelHinting:(bool)pixelHinting
{
    [self lineStyleWithThickness:thickness color:color pixelHinting:pixelHinting scaleMode:SwiffLineScaleModeNormal caps:SwiffCapsStyleRound joints:SwiffJointStyleRound miterLimit:3];
}
-(void) lineStyleWithThickness:(float)thickness color:(SwiffColor*)color
{
    [self lineStyleWithThickness:thickness color:color pixelHinting:FALSE scaleMode:SwiffLineScaleModeNormal caps:SwiffCapsStyleRound joints:SwiffJointStyleRound miterLimit:3];
}

@end
