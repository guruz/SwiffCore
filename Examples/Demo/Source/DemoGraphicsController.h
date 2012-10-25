//
//  DemoGraphicsController.h
//  Demo
//
//  Created by Will Hankinson on 10/1/12.
//
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface DemoGraphicsController : UIViewController <SwiffViewDelegate> {

@private
//    NSURL       *m_movieURL;
//    NSString    *m_classname;
//    NSData      *m_movieData;
//    SwiffMovie  *m_movie;

    SwiffView   *movieView;
    
//    
//    UIButton    *m_playButton;
//    UISlider    *m_timelineSlider;
//    NSInteger    m_frameNumber;
    
}

//- (id) initWithURL:(NSURL *)url andSymbol:(NSString *)classname;
//- (void) gotoFrameNumber:(NSInteger)frameNumber;

@end
