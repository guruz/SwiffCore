//
//  SwiffGraphics.h
//  SwiffCore
//
//  Created by Will Hankinson on 9/28/12.
//
//


/* 
 ================================================
 NOTES
 ================================================
 -sticking as close to the Flash drawing API as possible while also switching to some SwiffCore/Objc conventions
 -lineTo(x,y) becomes lineToX:x y:y | curveTo(controlX,controlY,x,y) becomes curveToControlX:controlX.... etc
 -SwiffCore introdoces the SwiffColor, which is RGBA. Where possible, separate calls to color/alpha are replaced by one SwiffColor
    -for example: beginFill(color, alpha) becomes beginFill:swiffColor; instead of passing color and alpha arrays in gradients, a single colors array is used

 
 
 */


#import <SwiffImport.h>
#import <SwiffTypes.h>
#import <SwiffPath.h>


@class SwiffGraphics;


@interface SwiffGraphics : NSObject


//gets all "finished" paths, the currentFill, the currentLine.
//TODO: optimize this and just return an array of path pointers
-(NSMutableArray*) pathsToRender;

//TODOs
-(void) beginFill:(SwiffColor*)color;
-(void) beginGradientFillOfType:(SwiffGradientType)type colors:(NSArray*)colors ratios:(NSArray*)ratios matrix:(CGAffineTransform*)matrix spreadMethod:(SwiffSpreadMethod)spreadMethod interpolationMethod:(SwiffInterpolationMethod)interpolationMethod focalPointRatio:(float)focalPointRatio;
-(void) clear; //resets graphics calls, linestyle and fillstyle
-(void) curveToControlX:(float)controlX controlY:(float)controlY anchorX:(float)anchorX anchorY:(float)anchorY;
-(void) drawCircleWithX:(float)x y:(float)y radius:(float)radius;
-(void) drawEllipseWithX:(float)x y:(float)y width:(float)width height:(float)height;
-(void) drawRectWithX:(float)x y:(float)y width:(float)width height:(float)height;
-(void) drawRoundRectWithX:(float)x y:(float)y width:(float)width height:(float)height ellipseWidth:(float)ellipseWidth ellipseHeight:(float)ellipseHeight; //height=NaN=w
-(void) endFill;
-(void) lineStyleWithThickness:(float)thickness color:(SwiffColor*)color pixelHinting:(bool)pixelHinting scaleMode:(SwiffLineScaleMode)scaleMode caps:(SwiffCapsStyle)caps joints:(SwiffJointStyle)joints miterLimit:(float)miterLimit;
-(void) lineToX:(float)x y:(float)y;
-(void) moveToX:(float)x y:(float)y;


//DEFAULTS
-(void) beginGradientFillOfType:(SwiffGradientType)type colors:(NSArray*)colors ratios:(NSArray*)ratios matrix:(CGAffineTransform*)matrix spreadMethod:(SwiffSpreadMethod)spreadmethod interpolationMethod:(SwiffInterpolationMethod)interpolationMethod;
-(void) beginGradientFillOfType:(SwiffGradientType)type colors:(NSArray*)colors ratios:(NSArray*)ratios matrix:(CGAffineTransform*)matrix spreadMethod:(SwiffSpreadMethod)spreadmethod;
-(void) beginGradientFillOfType:(SwiffGradientType)type colors:(NSArray*)colors ratios:(NSArray*)ratios matrix:(CGAffineTransform*)matrix;
-(void) beginGradientFillOfType:(SwiffGradientType)type colors:(NSArray*)colors ratios:(NSArray*)ratios;
-(void) lineStyleWithThickness:(float)thickness color:(SwiffColor*)color pixelHinting:(bool)pixelHinting scaleMode:(SwiffLineScaleMode)scaleMode caps:(SwiffCapsStyle)caps joints:(SwiffJointStyle)joints;
-(void) lineStyleWithThickness:(float)thickness color:(SwiffColor*)color pixelHinting:(bool)pixelHinting scaleMode:(SwiffLineScaleMode)scaleMode caps:(SwiffCapsStyle)caps;
-(void) lineStyleWithThickness:(float)thickness color:(SwiffColor*)color pixelHinting:(bool)pixelHinting scaleMode:(SwiffLineScaleMode)scaleMode;
-(void) lineStyleWithThickness:(float)thickness color:(SwiffColor*)color pixelHinting:(bool)pixelHinting;
-(void) lineStyleWithThickness:(float)thickness color:(SwiffColor*)color;



//MAYBE TODOs
//-(void) beginBitmapFill;  //bitmapData, matrix=null, repeat=true, smooth=false
//
//PROBABLY NOT TODOs
//-(void) beginShaderFill; //shader, matrix
//-(void) copyFrom; //sourceGraphics  --copies all drawing commands form the sourc egraphics into the calling graphics
//-(void) cubicCurveTo; //controlX1, controlY1, controlX2, controlY2, anchorX, anchorY
//-(void) drawGraphicsData; //graphicsDataVector --submits a series of commands for drawing
//-(void) drawPath; //commandsVector, dataVector, winding="evenOdd"
//-(void) drawTriangles; //verticesVector, indicesVector, uvtDataVector, culling="none"
//-(void) lineBitmapStyle; //bitmapData, matrix=null, repeat=true, smooth=false
//-(void) lineGradientStyle; //typeString, colorsArray, alphasArray, ratiosArray, matrix=null, spreadMethod="pad", interpolationMethod="rgb", focalPointRatio=0
//-(void) lineShaderStyle; //shader, matrix=null

/*********** INTERNAL STUFF **************/

@property (nonatomic, retain) NSMutableArray *paths;

@property (nonatomic, strong) SwiffLineStyle *currentLineStyle;
@property (nonatomic, strong) SwiffFillStyle *currentFillStyle;
@property (nonatomic, strong) SwiffPath *currentStroke;
@property (nonatomic, strong) SwiffPath *currentFill;


@end