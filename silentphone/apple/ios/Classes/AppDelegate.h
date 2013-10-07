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
#import "SettingsController.h"
#import "Recents.h"
#import "CallCell.h"
#import "Prov.h"

class CTList;

@class Reachability;
@class CallManeger; 
@class VideoViewController;

@interface AppDelegate : NSObject <UIApplicationDelegate, 
UITextFieldDelegate,// UINavigationBarDelegate,
UIAlertViewDelegate,UIActionSheetDelegate,ProvResponce>
{
   UIWindow *window;
   
   VideoViewController *vvcToRelease;
   
   CallManeger *callMngr;
   IBOutlet UITabBarController *uiMainTabBarController;
   IBOutlet UITabBarItem *keypaditem;
   IBOutlet UITabBar *uiTabBar;
   
   IBOutlet UIButton *curService;
   IBOutlet UILabel *curServiceLB;
   

   IBOutlet UIViewController *uiCallVC;
   
   IBOutlet RecentsViewController *recentsController;  
   IBOutlet UITextField* nr; 
   IBOutlet UINavigationController *second;  

   @public int iCallScreenIsVisible;
   int iAnimateEndCall;
   int iSettingsIsVisble;
   int iDialIsPadDown;
   unsigned int uiCanShowModalAt;
   int iShowCallMngr;
   int iIsClearBTDown;

   IBOutlet SettingsController *settings_ctrl;  
   IBOutlet UINavigationController *settings_nav_ctrl;  
   IBOutlet UIView *dialPadView;
   IBOutlet UIView *dialPadBTView;
   IBOutlet UIView *view6pad;
   
   IBOutlet UIView *viewCSMiddle;
   
   IBOutlet UIView *keyPadInCall;
   
   IBOutlet UIView *fPadView;
   IBOutlet UIView *zrtpPanel;
   IBOutlet UIView *infoPanel;
   
   IBOutlet UIButton *pickerButton;
   IBOutlet UITextView *log;
   IBOutlet UIImageView *peerPB_Img;
   CTList *sList;
   
   IBOutlet UIButton *backToCallBT;
   IBOutlet UIButton *answer;
   IBOutlet UIButton *endCallBT;
   IBOutlet UIButton *cfgBT;
   IBOutlet UIButton *backspaceBT;
   
   IBOutlet UIButton *muteBT;
   IBOutlet UIButton *videoBT;
   
   IBOutlet UIButton *switchSpktBt;
   CGRect endCallRect;
   
   @public IBOutlet UIButton *verifySAS;
   @public int iIsInBackGround;
   int iSecondsInBackGroud;
   @public UIBackgroundTaskIdentifier uiBackGrTaskID;
   @public CTCalls calls;
   
   int iLoudSpkr;
   
@public int iCanHideNow;
@public int iOnMute;
@public int iExiting;
   
   //secure Panel
   IBOutlet UIButton *btHideKeypad;
   IBOutlet UIButton *btSAS;
   IBOutlet UIButton *btChangePN;
   IBOutlet UILabel *lbSecure;
   IBOutlet UILabel *lbSecureSmall;
   IBOutlet UILabel *uiZRTP_peer;
 //  IBOutlet UILabel *lbWarning;
   IBOutlet UIImageView *ivBubble;
   
   int iCanShowMediaInfo;
   int iAudioBufSizeMS;//debug only
   
   IBOutlet UIImageView *callScreenFlag;
   IBOutlet UIImageView *nrflag;
   IBOutlet UIButton *nrflagBt;
   
   IBOutlet UIImageView *iwLed;
   
   IBOutlet UILabel *countryID;
   
   unsigned int uiCanHideCountryCityAt;
   
   IBOutlet UIButton *btAntena;
   IBOutlet UILabel *uiServ;
   IBOutlet UILabel *uiDur;
   IBOutlet UILabel *uiMediaInfo;
   
   @public IBOutlet UILabel *uiCallInfo;

   IBOutlet UILabel *lbDst;
   IBOutlet UILabel *lbDstName;
   
   IBOutlet UILabel *lbNRFieldName;
   IBOutlet UILabel *lbVolumeWarning;
   
   UIAlertView *avZRTPWarning;
   
   
   IBOutlet UITableViewCell *userCell;
   
   id objLogTab;
   
   unsigned int uiNumberChangedAt;
   int iMustSearch;
   
   
   int iPrevCallLouspkrMode;
   int iVideoScrIsVisible;

   char szLastDialed[128];
   
   int accountIdByIndex[20];
   
   //if(*iSASConfirmClickCount > 2)you are an expert
   int *iSASConfirmClickCount;
   int iAudioUnderflow;
   
   int iCanShowSAS_verify;
   
   int iLogPlus;
   
   Reachability* internetReach;
   
   UILocalNotification *incomCallNotif;
   
}

 //@property (nonatomic, retain) IBOutlet RootViewController *rootViewController;
// @property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
 
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
-(int)callScrVisible;

-(IBAction)switchView:(id)sender;
-(IBAction)hideKeypad:(id)sender;
-(IBAction)switchAddCall:(id)sender;
-(IBAction)switchCalls:(id)sender;
-(IBAction)switchMute:(id)sender;
-(IBAction)switchSpkr:(id)sender;

-(IBAction)switchToVideo:(id)sender;

-(void)unholdAndPutOthersOnHold:(CTCall*)c;
-(void)confCallN:(CTCall*)c add:(int)add;
-(void)holdCallN:(CTCall*)c hold:(int)hold;
-(void)answerCallN:(CTCall*)c;
-(void)answerCallFromVidScr:(CTCall*)c;
-(void)endCallN:(CTCall*)c;
-(int)setCurCallMT:(CTCall*)c;
-(NSString*)loadUserData:(CTCall*)c;
-(int)callTo:(int)ctype dst:(const char*)dst;
-(int)callToCheckUS:(int)ctype dst:(const char*)dst  eng:(void*)eng;
-(int)callToS:(int)ctype dst:(const char*)dst eng:(void*)eng;
-(int)callToR:(CTRecentsItem*)i;

-(IBAction)endCallBt;
-(IBAction)clearEdit;
-(IBAction)chooseCallType;
-(void)setText:(NSString *)ns;
/*
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@end
*/

@end
