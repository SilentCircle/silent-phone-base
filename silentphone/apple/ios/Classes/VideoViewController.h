/*
Created by Janis Narbuts
Copyright © 2004-2012, Tivi LTD,www.tiviphone.com. All rights reserved.
Copyright © 2012-2013, Silent Circle, LLC. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Any redistribution, use, or modification is done solely for personal 
      benefit and not for any commercial purpose or for monetary gain
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name Silent Circle nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL SILENT CIRCLE, LLC BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import <UIKit/UIKit.h>
#import "SquareCamViewController.h"
#import "QuartzVO.h"

class CTCall;

@class AppDelegate;


@interface VideoViewController : UIViewController<UITouchDetector,UIActionSheetDelegate>{
   IBOutlet UIBarButtonItem *btMute;
   IBOutlet UIBarButtonItem *btSwitch;
   IBOutlet UIButton *btSendStop;
   IBOutlet SquareCamViewController *cvc;
   IBOutlet UIBarButtonItem *btDeclineEnd;   
   IBOutlet UIBarButtonItem *btAccept;
   IBOutlet UIButton *btBack;
   IBOutlet UILabel *lbVolumeWarning;
   
   IBOutlet UIToolbar *toolBar;
   
   IBOutlet UIImageView *muteIco;
   
   CTCall *call,*newCall;
   
   AppDelegate *app;
   
   int *pIsVisible;
   
   int iActionSheetIsVisible;
   
   int iCanStartVideo;
   int iIsIncomingVideoCall;
   int iAnsweredVideo;
   int iActiveVideo;
   
   int iUserTouched;
   
   unsigned int uiCanHideInfoAt;
   
   int iWasSendingVideoBeforeEnteringBackgr;
   
   int iAnimating;
   
   int iMoving;
   
   int iHideBackToAudioButton;
   int iSimplifyUI;
   
}
//@property (retain, nonatomic) IBOutlet UIBarButtonItem *btBackToAudio;
//--@property (retain, nonatomic) IBOutlet UIBarButtonItem *btSwitch;
//--@property (retain, nonatomic) IBOutlet UIBarButtonItem *btSendStop;
//--@property (retain, nonatomic) IBOutlet SquareCamViewController *cvc;

-(void)setCall:(CTCall*)c canAutoStart:(int)canAutoStart iVideoScrIsVisible:(int*)iVideoScrIsVisible a:(AppDelegate*)a;
-(void)showInfoView;
-(void)showIncomingCallMT;


-(void)onGotoBackground;
-(void)onGotoForeground;
@end
