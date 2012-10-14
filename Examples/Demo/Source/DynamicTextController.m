//
//  DynamicTextController.m
//  Demo
//
//  Created by Will Hankinson on 10/13/12.
//
//

#import "SwiffMovie.h"
#import "DynamicTextController.h"

@interface DynamicTextController ()

@end

@implementation DynamicTextController


- (void)viewDidLoad
{
    [super viewDidLoad];

    NSString *resourcePath = [[NSBundle mainBundle] pathForResource:@"DynamicTextPlacement" ofType:@"swf"];
    
    if (!resourcePath) {
        NSLog(@"Unable to find DynamicTextPlacement.swf");
        return;
    }
    
    //Item 1 - Load the main swf and display it.
    NSData *movieData = [[NSData alloc] initWithContentsOfFile:resourcePath];
    SwiffMovie *movie = [[SwiffMovie alloc] initWithData:movieData];
    
    CGRect movieFrame = [[self view] bounds];
    
    movieView = [[SwiffView alloc] initWithFrame:movieFrame movie:movie];
    
    [movieView setBackgroundColor:[UIColor whiteColor]];
    [movieView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [[self view] addSubview:movieView];
    
    //SwiffSpriteDefinition *clip = [m_movie definitionWithExportedName:m_classname];
    
    
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}


@end
