//
//  SubAnimatedController.h
//  Demo
//
//  Created by Will Hankinson on 10/16/12.
//
//

#import <UIKit/UIKit.h>

@interface SubAnimatedController : UIViewController {

@private

SwiffView   *movieView;
SwiffMovie  *movie;

}

- (void)promote:(SwiffPlacedObject*)placedObject playOnAdded:(BOOL)play;

@end
