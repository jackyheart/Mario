//
//  MarioAppDelegate.h
//  Mario
//
//  Created by sap_all\c5152815 on 10/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MarioViewController;

@interface MarioAppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet MarioViewController *viewController;

@end
