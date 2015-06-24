//
//  MarioViewController.h
//  Mario
//
//  Created by sap_all\c5152815 on 10/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Common.h"

@interface MarioViewController : UIViewController {

    UIImageView *marioImgView;
    UIScrollView *worldScrollView;
    UIImageView *joypadBaseImgView;
    UIImageView *joypadHeadImgView;
    
@private
    BOOL IS_MARIO_JUMPING;
    JOYPAD_DIRECTION  CUR_JOYPAD_DIRECTION;
    float TOUCH_MOVEMENT_DELTA;
    MARIO_FACING CUR_MARIO_FACING;
}

@property (nonatomic, retain) IBOutlet UIImageView *marioImgView;
@property (nonatomic, retain) IBOutlet UIScrollView *worldScrollView;
@property (nonatomic, retain) IBOutlet UIImageView *joypadBaseImgView;
@property (nonatomic, retain) IBOutlet UIImageView *joypadHeadImgView;
@property (nonatomic, retain) NSMutableArray *walkFrameImgMutArray;
@property (nonatomic, retain) UIImage *JUMP_IMAGE;

- (IBAction)jumpBtnTapped:(id)sender;

@end
