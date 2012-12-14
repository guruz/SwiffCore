//
//  SubAnimatedController.m
//  Demo
//
//  Created by Will Hankinson on 10/16/12.
//
//

#define USE_BOUNCING_BALL 0

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
    
    SwiffSpriteDefinition* clip = movie;

#if USE_BOUNCING_BALL
    clip = [movie definitionWithExportedName:@"bouncingball"];
#endif
    
    CGRect movieFrame = [[self view] bounds];
    
    movie.frameRate = 6;
    
    movieView = [[SwiffView alloc] initWithFrame:movieFrame movie:clip];
    [movieView setShouldPlayChildren:YES];
    
    [movieView setBackgroundColor:[UIColor whiteColor]];
    [movieView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [[self view] addSubview:movieView];
    
//    //promotes all placed objects to layers
//    for (SwiffFrame *frame in [clip frames]) {
//        for (SwiffPlacedObject *object in [frame placedObjects]) {
//            [self promote:object playOnAdded:TRUE];
//        }
//    }
    
    
    movieView.playhead.loopsMovie = TRUE;
    [movieView.playhead play];
    
    
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
