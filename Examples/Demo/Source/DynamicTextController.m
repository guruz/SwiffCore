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
    
    SwiffPlacedDynamicText *item_1 = (SwiffPlacedDynamicText*)[movie getChildByDotString:@"item_1.tf"];
    SwiffPlacedDynamicText *item_2 = (SwiffPlacedDynamicText*)[movie getChildByDotString:@"item_2.tf"];
    
    if(item_1 == item_2)
    {
        NSLog(@"SAME PLACEDOBJECT!");
    }
    
    NSLog(@"item_2.tf.text = %@", item_2.text);
    //Replicating all the HTML gobbledygook isn't optimal, but necessary in this particular case because of the multi-line text
    //If multiline text with line breaks needs to be edited, could probably write some helpers to ease this...
    [item_2 setText:@"<p align=\"center\"><font face=\"Futura Medium\" size=\"20\" color=\"#000000\" letterSpacing=\"0.000000\" kerning=\"1\">Item 2</font></p><p align=\"center\"><font face=\"Futura Medium\" size=\"20\" color=\"#000000\" letterSpacing=\"0.000000\" kerning=\"1\">This text was placed on the main timeline and later altered with code.</font></p>" HTML:YES];

    
    //SwiffSpriteDefinition *clip = [m_movie definitionWithExportedName:m_classname];
    
    
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}


@end
