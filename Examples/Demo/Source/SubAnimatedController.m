//
//  SubAnimatedController.m
//  Demo
//
//  Created by Will Hankinson on 10/16/12.
//
//

#import "SubAnimatedController.h"

@interface SubAnimatedController ()

@end

@implementation SubAnimatedController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *resourcePath = [[NSBundle mainBundle] pathForResource:@"BounceTest" ofType:@"swf"];
    
    if (!resourcePath) {
        NSLog(@"Unable to find BounceTest.swf");
        return;
    }
    
    //Load the main swf and display it.
    NSData *movieData = [[NSData alloc] initWithContentsOfFile:resourcePath];
    movie = [[SwiffMovie alloc] initWithData:movieData];
    
    CGRect movieFrame = [[self view] bounds];
    
    movieView = [[SwiffView alloc] initWithFrame:movieFrame movie:movie];
    [movieView setShouldPlayChildren:YES];
    
    [movieView setBackgroundColor:[UIColor whiteColor]];
    [movieView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [[self view] addSubview:movieView];
    
    //promotes all placed objects to layers
    for (SwiffFrame *frame in [movie frames]) {
        for (SwiffPlacedObject *object in [frame placedObjects]) {
            [self promote:object playOnAdded:TRUE];
        }
    }
    
    
    [movieView playhead].loopsMovie = TRUE;
    [[movieView playhead] play];

    
//    SwiffPlacedDynamicText *item_1 = (SwiffPlacedDynamicText*)[movie getChildByDotString:@"item_1.tf"];
//    SwiffPlacedDynamicText *item_2 = (SwiffPlacedDynamicText*)[movie getChildByDotString:@"item_2.tf"];
//    
//    if(item_1 == item_2)
//    {
//        NSLog(@"SAME PLACEDOBJECT!");
//    }
//    
//    NSLog(@"item_2.tf.text = %@", item_2.text);
//    //Replicating all the HTML gobbledygook isn't optimal, but necessary in this particular case because of the multi-line text
//    //If multiline text with line breaks needs to be edited, could probably write some helpers to ease this...
//    [item_2 setText:@"<p align=\"center\"><font face=\"Futura Medium\" size=\"20\" color=\"#000000\" letterSpacing=\"0.000000\" kerning=\"1\">Item 2</font></p><p align=\"center\"><font face=\"Futura Medium\" size=\"20\" color=\"#000000\" letterSpacing=\"0.000000\" kerning=\"1\">This text was placed on the main timeline and later altered with code.</font></p>" HTML:YES];
//    
//    
//    //SwiffSpriteDefinition *clip = [m_movie definitionWithExportedName:m_classname];
    
    
}

//ideally only Sprites would get promoted, but need to work in logic to keep layering order
//so anything on top of a sprite remains on top of a sprite
- (void) promote:(SwiffPlacedObject*)placedObject playOnAdded:(BOOL)play
{
    [placedObject setWantsLayer:YES];
    
    __unsafe_unretained // Workaround for <rdar://11044357> clang 3.1 crashes in ObjCARCOpt::runOnFunction()
    id<SwiffDefinition> definition = SwiffMovieGetDefinition(movie, [placedObject libraryID]);
    
    
    if ([definition isKindOfClass:[SwiffSpriteDefinition class]]) {
        for (SwiffFrame *frame in [(SwiffSpriteDefinition*)definition frames]) {
            for (SwiffPlacedObject *object in [frame placedObjects]) {
                [self promote:object playOnAdded:play];
            }
        }
    }
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

@end
