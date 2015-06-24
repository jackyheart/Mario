//
//  MarioViewController.m
//  Mario
//
//  Created by sap_all\c5152815 on 10/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "MarioViewController.h"
#import "Common.h"

#define FPS 30.0
#define NUM_OF_WALK_FRAMES 2
#define MAX_JUMP_HEIGHT 100.0
#define MAX_WORLD_X 1235

@interface MarioViewController (private)

- (float)calcDistanceWithPoint1:(CGPoint)point1 andPoint2:(CGPoint)point2;
- (void)updateMarioFrameWithTouchMovementDelta:(float)movementDelta;

@end

@implementation MarioViewController

@synthesize marioImgView;
@synthesize worldScrollView;
@synthesize joypadBaseImgView;
@synthesize joypadHeadImgView;
@synthesize walkFrameImgMutArray;
@synthesize JUMP_IMAGE;

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // add gesture recognizer
    
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [self.joypadHeadImgView addGestureRecognizer:panRecognizer];
    [panRecognizer release];   
    
    // init mutable array(s)
    self.walkFrameImgMutArray = [NSMutableArray array];
    
    
    // mario sprite
    NSString *path = [[NSBundle mainBundle] pathForResource:@"mario_sprite_trans" ofType:@"png"];
    UIImage *marioSpriteSheet = [[UIImage alloc] initWithContentsOfFile:path];//to do: use manual release
    
    //start dividing images
    float spriteWidth = 57;
    float spriteHeight = 93.0;
    
    //the first two frames are for walking
    for (int i=0; i < NUM_OF_WALK_FRAMES; i++) {
        
        CGRect cropRect = CGRectMake(i * spriteWidth, 0, spriteWidth, spriteHeight);
        
        CGImageRef imageRef = CGImageCreateWithImageInRect(marioSpriteSheet.CGImage, cropRect);
        UIImage *newImage = [[UIImage alloc] initWithCGImage:imageRef scale:1.0 orientation:marioSpriteSheet.imageOrientation];
        
        [self.walkFrameImgMutArray addObject:newImage];
        
        [newImage release];
        CGImageRelease(imageRef);
    } 
    
    [marioSpriteSheet release];
    
    //get jump frame (it's on frame idx 3, idx 2 is unused)
    {
        //(spriteWidth + 5) --> offset 5 px
        CGRect cropRect = CGRectMake(3 * (spriteWidth + 5), 0, spriteWidth, spriteHeight);
        
        CGImageRef imageRef = CGImageCreateWithImageInRect(marioSpriteSheet.CGImage, cropRect);
        UIImage *newImage = [[UIImage alloc] initWithCGImage:imageRef scale:1.0 orientation:marioSpriteSheet.imageOrientation];
        
        UIImage *tempJumpImage = [[UIImage alloc] initWithCGImage:newImage.CGImage];
        self.JUMP_IMAGE = tempJumpImage;
        [tempJumpImage release];
        
        [newImage release];
        CGImageRelease(imageRef);       
    }
        

    // set mario animation images
    
    self.marioImgView.animationImages = (NSArray *)self.walkFrameImgMutArray;
    self.marioImgView.animationDuration = 0.25;

    // set default mario image
    
    UIImage *defaultFrameImg = (UIImage *)[self.walkFrameImgMutArray objectAtIndex:0];
    self.marioImgView.image = defaultFrameImg;
    
    // debug
    //self.marioImgView.layer.borderColor = [UIColor redColor].CGColor;
    //self.marioImgView.layer.borderWidth = 1.0;
    
    // set misc variables
    IS_MARIO_JUMPING = FALSE;
    TOUCH_MOVEMENT_DELTA = 0.0;
    CUR_JOYPAD_DIRECTION = kJOYPAD_DIRECTION_NONE;
    CUR_MARIO_FACING = kMARIO_FACING_RIGHT;
    
    [NSTimer scheduledTimerWithTimeInterval:1.0/FPS target:self selector:@selector(gameTimer:) userInfo:nil repeats:YES];
}


- (void)viewDidUnload
{
    [self setMarioImgView:nil];
    [self setWorldScrollView:nil];
    [self setJoypadBaseImgView:nil];
    [self setJoypadHeadImgView:nil];
    [self setWalkFrameImgMutArray:nil];
    [self setJUMP_IMAGE:nil];
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == APP_ORIENTATION);
}

- (void)dealloc {
  
    [marioImgView release];
    [worldScrollView release];
    [joypadBaseImgView release];
    [joypadHeadImgView release];
    [walkFrameImgMutArray release];
    [JUMP_IMAGE release];
    
    [super dealloc];
}

- (IBAction)jumpBtnTapped:(id)sender {
    
    if(! IS_MARIO_JUMPING)
    {
        IS_MARIO_JUMPING = TRUE;
                
        self.marioImgView.image = self.JUMP_IMAGE;
    
        [UIView animateWithDuration:0.35 delay:0.0 options:UIViewAnimationCurveEaseOut | UIViewAnimationOptionAllowUserInteraction animations:^(void) {
            
            self.marioImgView.frame = CGRectOffset(self.marioImgView.frame, 0, -MAX_JUMP_HEIGHT);
            
        } completion:^(BOOL finished) {
            
            [UIView animateWithDuration:0.35 delay:0.0 options:UIViewAnimationCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction animations:^(void) {
                
                self.marioImgView.frame = CGRectOffset(self.marioImgView.frame, 0, MAX_JUMP_HEIGHT);
                
            } completion:^(BOOL finished) {
                
                IS_MARIO_JUMPING = FALSE;
                
                UIImage *defaultWalkImg = (UIImage *)[self.walkFrameImgMutArray objectAtIndex:0];
                self.marioImgView.image = defaultWalkImg;
                
            }];
        }];
    }
}

#pragma mark - timer handler

- (void)gameTimer:(NSTimer *)timer
{
    if(CUR_JOYPAD_DIRECTION != kJOYPAD_DIRECTION_NONE)
    {
        //only update if joypad is moving
                
        // update mario frame
        [self updateMarioFrameWithTouchMovementDelta:TOUCH_MOVEMENT_DELTA];
    }
}

#pragma mark - gesture recognizers

CGPoint touchDelta;
CGPoint prevTouchPoint;
float MAX_RADIUS = 84.0;
BOOL isTouchWithinBound = YES;

- (void) handlePanGesture:(UIPanGestureRecognizer *)recognizer
{
    CGPoint touchPoint = [recognizer locationInView:self.view];  
    
    if(recognizer.state == UIGestureRecognizerStateBegan)
    {
        touchDelta = CGPointMake(touchPoint.x - self.joypadBaseImgView.center.x, 
                                 touchPoint.y - self.joypadBaseImgView.center.y);
        
        prevTouchPoint = touchPoint;
    }
    
    if(CGRectContainsPoint(self.joypadHeadImgView.frame, touchPoint))
    {
        //make sure that current touch point is still on top of the joypad head
        
        isTouchWithinBound = YES;
       
        float touchToPreviousDeltaX = touchPoint.x - prevTouchPoint.x;
        
        TOUCH_MOVEMENT_DELTA = touchToPreviousDeltaX;
        
        if(touchToPreviousDeltaX > 0)
        {
            //moving right
            CUR_JOYPAD_DIRECTION = kJOYPAD_DIRECTION_RIGHT;
            
            CUR_MARIO_FACING = kMARIO_FACING_RIGHT;
        }
        else if(touchToPreviousDeltaX < 0)
        {
            //moving left
            CUR_JOYPAD_DIRECTION = kJOYPAD_DIRECTION_LEFT;
            
            CUR_MARIO_FACING = kMARIO_FACING_LEFT;
        }
        else if(touchToPreviousDeltaX == 0)
        {
            //not moving
            CUR_JOYPAD_DIRECTION = kJOYPAD_DIRECTION_NONE;
        }
        
        if(! self.marioImgView.isAnimating)
        {
            [self.marioImgView startAnimating];
        }
        
        // replace previous touch point with the current touch point
        prevTouchPoint = touchPoint;
    
        
        float dx = self.joypadBaseImgView.center.x - touchPoint.x;
        float dy = self.joypadBaseImgView.center.y - touchPoint.y;
       
        float touchDistance = [self calcDistanceWithPoint1:self.joypadBaseImgView.center andPoint2:touchPoint];
        float touchAngle = atan2(dy, dx);
        
        if(touchDistance > MAX_RADIUS)
        {
            //if out of bounds (if out of the base's perimeter, keep it on the perimeter, using the equation of a circle)
            
            self.joypadHeadImgView.center = CGPointMake(
                                            self.joypadBaseImgView.center.x - cosf(touchAngle) * MAX_RADIUS, 
                                            self.joypadBaseImgView.center.y - sinf(touchAngle) * MAX_RADIUS);     
        }
        else
        {
            self.joypadHeadImgView.center = CGPointMake(
                                            touchPoint.x - touchDelta.x, 
                                            touchPoint.y - touchDelta.y);       
        }
    }
    else
    {
        isTouchWithinBound = NO;
    }
    
    if(recognizer.state == UIGestureRecognizerStateEnded || ! isTouchWithinBound)
    {
        //not moving
        CUR_JOYPAD_DIRECTION = kJOYPAD_DIRECTION_NONE;

        //=== stop animation
        if(self.marioImgView.isAnimating)
        {
            [self.marioImgView stopAnimating];
        } 
        
        //=== bounce back
        
        [UIView animateWithDuration:0.40 
                              delay:0 
                            options:UIViewAnimationCurveEaseOut
                         animations:^{
                                                          
                             recognizer.view.center = self.joypadBaseImgView.center;  
                             
                         } 
                         completion:^(BOOL completion){
                             
                         }];          
      
    }
}

#pragma mark - private methods implementation

- (float)calcDistanceWithPoint1:(CGPoint)point1 andPoint2:(CGPoint)point2
{
    float dist = 0.0;
    
    float x2Minx1 = point2.x - point1.x;
    float y2Miny1 = point2.y - point1.y;
    
    dist = sqrtf(x2Minx1 * x2Minx1 + y2Miny1 * y2Miny1);
    
    return dist;
}

- (void)updateMarioFrameWithTouchMovementDelta:(float)movementDelta
{
   float marioX = self.marioImgView.frame.origin.x;
    
    if(movementDelta > 0)
    {
        //moving right
        
        self.marioImgView.transform = CGAffineTransformMakeScale(1.0, 1.0);
        
        //update world offset
        
        if(marioX > 100)
        {
            //start scrolling the world if mario has moved 100 px from the left
            
            if(self.worldScrollView.contentOffset.x < 330)//this value is to limit the scrolling of the scroll view
            {
                self.worldScrollView.contentOffset = CGPointMake(self.worldScrollView.contentOffset.x + 3, 0);
            }
        }
    }
    else if(movementDelta < 0)
    {
        //moving left
        
        //flip image
        self.marioImgView.transform = CGAffineTransformMakeScale(-1.0, 1.0);
        
        //update world offset
        
        if(marioX < 1000)
        {   
            //if mario is on the right side, and he is currently moving left, 
            //only scroll the world if he has moved to the area less than 1000 px (from the left)
            
            if(self.worldScrollView.contentOffset.x > 0)//limit scrolling offset to 0
            {
                self.worldScrollView.contentOffset = CGPointMake(self.worldScrollView.contentOffset.x - 3, 0);
            }
        }
    }
    else
    {
        //ignore case touchToPreviousDeltaX == 0 (current touch position is the same as the previous touch position)
    }
    
    //NSLog(@"mario frame origin x: %f", marioX); 
    //NSLog(@"self.worldScrollView.contentOffset.x: %f", self.worldScrollView.contentOffset.x);
    
    //bound mario (collision detection)
    
    CGRect newMarioRect = CGRectZero;
    

    if(self.marioImgView.frame.origin.x < 0)
    {
        
        newMarioRect = CGRectMake(0, self.marioImgView.frame.origin.y, 
                                  self.marioImgView.frame.size.width, 
                                  self.marioImgView.frame.size.height);
    }
    else if(self.marioImgView.frame.origin.x > MAX_WORLD_X)
    {
        newMarioRect = CGRectMake(MAX_WORLD_X, self.marioImgView.frame.origin.y, 
                                  self.marioImgView.frame.size.width, 
                                  self.marioImgView.frame.size.height);       
    }
    else
    {
        newMarioRect = CGRectOffset(self.marioImgView.frame, movementDelta * 3.0, 0);
    }
    
    self.marioImgView.frame = newMarioRect;
}

@end
