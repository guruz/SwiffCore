//
//  DemoGraphicsController.m
//  Demo
//
//  Created by Will Hankinson on 10/1/12.
//
//

#import "DemoGraphicsController.h"
#import "SwiffGraphics.h"

@interface DemoGraphicsController ()

@end

@implementation DemoGraphicsController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
   
    CGRect movieFrame = [[self view] bounds];
    movieView = [[SwiffView alloc] initWithFrame:movieFrame movie:nil];
    
    [movieView setDelegate:self];
    [movieView setBackgroundColor:[UIColor grayColor]];
    [movieView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [[self view] addSubview:movieView];
    
    SwiffGraphics *g = movieView.graphics;
    
    [g beginFill:&(SwiffColor){255,0,0,1}];
    [g moveToX:25 y:25];
    [g lineToX:50 y:25];
    [g lineToX:50 y:50];
    [g lineToX:25 y:50];
    [g lineToX:25 y:25];
    [g endFill];
    
    [movieView redisplay];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

@end
