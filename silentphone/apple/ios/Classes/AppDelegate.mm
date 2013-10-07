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

#include <string.h>
#import "AppDelegate.h"
#import "CallManeger.h"
#import "ZRTPInfoView.h"


#import "VideoViewController.h"
#import "../../../utils/Reachability.h"

#include "../../../os/CTMutex.h"
#include "../../../tiviandroid/engcb.h"

#define T_DISABLE_BLINK_WARN 1

#define T_CREATE_CALL_MNGR
//iSASConfirmClickCount
#define T_SAS_NOVICE_LIMIT 2
//#define T_TEST_MAX_JIT_BUF_SIZE


#define getAccountTitle(pS) sendEngMsg(pS,"title")

void *findGlobalCfgKey(const char *key);
int fncCBRet(void *ret, void *ph, int iCallID, int msgid, const char *psz, int iSZLen);
char* z_main(int iResp,int argc, const char* argv[]);;
int get_time();
void safeStrCpy(char *dst, const char *name, int iMaxSize);
void* findCfgItemByServiceKey(void *ph, char *key, int &iSize, char **opt, int *type);
NSString *toNSFromTB(CTStrBase *b);
const char* sendEngMsg(void *pEng, const char *p);
int getCallInfo(int iCallID, const char *key, char *p, int iMax);
int getCallInfo(int iCallID, const char *key, int *v);
void *getAccountByID(int id, int iIsEnabled);
void* getAccountCfg(void *eng);
void *getCurrentDOut();
int getMediaInfo(int iCallID, const char *key, char *p, int iMax);

int setCurrentDOut(int idx, const char *sz);
void apple_log_x(const char *p);
int findIntByServKey(void *pEng, const char *key, int *ret);
int isVideoCall(int iCallID);
char *iosLoadFile(const char *fn, int &iLen);
void initCC(char *p, int iLen);
int getReqTimeToLive();
void translateZRTP_errMsg(CTEditBase &warn, CTEditBase *general, CTEditBase *descr);
int isZRTPInfoVisible();
int isPlaybackVolumeMuted();
unsigned int getTickCount();
int fixNR(const char *in, char *out, int iLenMax);
void tivi_log1(const char *p, int val);


static CTMutex mutexCallManeger;
void *pCurService=NULL;
void *pCurCfg=NULL;
static int iCfgOn=0;


const char* sendEngMsg(void *pEng, int iCallID, const char *p){
   char msg[64];
   snprintf(msg,63,"%s%u",p,iCallID);
   return sendEngMsg(pEng,msg);
}

int isSDESSecure(int iCallId, int iVideo){
   int v=0;
   if(getCallInfo(iCallId,iVideo?"media.video.zrtp.sec_state": "media.zrtp.sec_state", &v)==0 && v & 0x100)
      return 1;
   return 0;
}




NSString *checkNrPatterns(NSString *ns){
   
   char buf[64];
   if(fixNR(ns.UTF8String,&buf[0],63)){
      return [NSString stringWithUTF8String:&buf[0]];
   }
   return ns;
}

typedef struct{
   NSString *ns;
}T_Log;

static void fnc_log(void *ret, const char *line, int iLen){
   char buf[256];
   
   if(iLen>=sizeof(buf))iLen=sizeof(buf)-1;
   memcpy(buf,line,iLen);
   buf[iLen]=0;
   
   T_Log *l=(T_Log*)ret;
   
   NSString *ns=l->ns;
   l->ns=[ns stringByAppendingString:[NSString stringWithUTF8String:buf]];
}


@implementation AppDelegate

@synthesize window;
@synthesize navigationController;

/*
 onts provided by application
 Item 0        myfontname.ttf
 Item 1        myfontname-bold.ttf
 ...
 Then check to make sure your font is included by running :
 
 for (NSString *familyName in [UIFont familyNames]) {
  for (NSString *fontName in [UIFont fontNamesForFamilyName:familyName]) {
    NSLog(@"%@", fontName);
  }
 }
 Note that your ttf file name might not be the same name that you use when you set the font for your label (you can use the code above to get the "fontWithName" parameter):
 
 [label setFont:[UIFont fontWithName:@"MyFontName-Regular" size:18]];
 */


/*
 ￼-(BOOL)isForeground
 {
 ! if (![self isMultitaskingOS])
 ! ! return YES;
 ! UIApplicationState state = [UIApplication sharedApplication].applicationState;
 ! //return (state==UIApplicationStateActive || state==UIApplicationStateInactive );
 ! return (state==UIApplicationStateActive); 
 }
 */
/*
 
 NSString *myIDToCancel = @"some_id_to_cancel";
 UILocalNotification *notificationToCancel=nil;
 for(UILocalNotification *aNotif in [[UIApplication sharedApplication] scheduledLocalNotifications]) {
 if([aNotif.userInfo objectForKey:@"ID"] isEqualToString:myIDToCancel]) {
 notificationToCancel=aNotif;
 break;
 }
 }
 [[UIApplication sharedApplication] cancelLocalNotification:notificationToCancel];
 */

/*
 ￼-(BOOL)isForeground
 {
 if (![self isMultitaskingOS])   return YES;
 UIApplicationState state = [UIApplication sharedApplication].applicationState;
 //return (state==UIApplicationStateActive || state==UIApplicationStateInactive );
 return (state==UIApplicationStateActive); 
 }
 */

#pragma mark - Init

-(void)makeDPButtons{
   static  int iInitOk=0;
   if(iInitOk)return ;
   iInitOk=1;
   
   NSString *ns[]={
      @"1",@"2",@"3",
      @"4",@"5",@"6",
      @"7",@"8",@"9",
      @"*",@"0",@"#",
   };
   
   NSString *ns_text[]={
      @"",@"ABC",@"DEF",
      @"GHI",@"JKL",@"MNO",
      @"PQRS",@"TUV",@"WXYZ",
      @"",@"+",@"",
   };
   
   float ofsx=0;//10;
   float ofsy=0;//nr.frame.size.height+10;//115;
   float sp=0;//10;
   float szx=(dialPadBTView.frame.size.width-sp*2)/3;
   float szy=(dialPadBTView.frame.size.height-sp*3)/4;

   
   UIImage *bti=[UIImage imageNamed:@"bt_dial_up.png"];
   CGSize szShadow=CGSizeMake(0,-1);
   UIEdgeInsets uiEI=UIEdgeInsetsMake(0,0,szy/6,0);
   
   for(int y=0,i=0;y<4;y++)
      for(int x=0;x<3;x++,i++){
         UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];//UIButtonTypeRoundedRect];
         [button addTarget:self  action:@selector(pressDP_Bt:) forControlEvents:UIControlEventTouchDown];
         [button addTarget:self  action:@selector(textFieldReturn:) forControlEvents:UIControlEventTouchDown];
         [button addTarget:self  action:@selector(pressDP_Bt_up:) forControlEvents:UIControlEventTouchUpInside];
         [button addTarget:self  action:@selector(pressDP_Bt_up:) forControlEvents:UIControlEventTouchUpOutside];
         [button addTarget:self  action:@selector(pressDP_Bt_up:) forControlEvents:UIControlEventTouchDragOutside];
         
         [button setBackgroundImage:bti forState:UIControlStateNormal];
         //setTitleColor
         [button.titleLabel setFont:[UIFont boldSystemFontOfSize:i==9?52:32]];
         [button.titleLabel setTextColor:[UIColor whiteColor]];
         [button.titleLabel setShadowOffset:szShadow];
         
         [button setIsAccessibilityElement:YES];
         button.accessibilityLabel=ns[i];
         button.accessibilityTraits=UIAccessibilityTraitKeyboardKey;
         // button a
         
         if(i==9)button.contentEdgeInsets=UIEdgeInsetsMake(szy/4,0,0,0);else
            if(i!=11 && i!=9)button.contentEdgeInsets=uiEI;
         
         
         [button setTitle:ns[i] forState:UIControlStateNormal];
         
         float ox=ofsx+x*(szx+sp);
         float oy=ofsy+y*(szy+sp);
         button.frame = CGRectMake(ox,oy, szx, szy);
         
         UILabel *lb=[[UILabel alloc]initWithFrame:CGRectMake(0,0+szy*5/8,szx,szy*2/8)];
         lb.text=ns_text[i];
         lb.font=[UIFont systemFontOfSize:12];
         lb.textColor=[UIColor whiteColor];
         lb.textAlignment=UITextAlignmentCenter;
         lb.backgroundColor=[UIColor clearColor];           
         [button addSubview:lb ];
         
         [dialPadBTView addSubview:button];
      }
   
   szx=(keyPadInCall.frame.size.width-sp*2)/3;
   szy=(keyPadInCall.frame.size.height-sp*3)/4;
   
   
   //- (void)loadView
   {
      /*
       CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
       UIView *view = [[UIView alloc] initWithFrame:appFrame];
       view.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
       self.view = view;
       [view release];
       */
      //[UIScreen mainScreen] 
      /*   
       CGRect webFrame = CGRectMake(0,0,dialPadBTView.frame.size.width,dialPadBTView.frame.size.height);//[[UIScreen mainScreen] applicationFrame];
       UIWebView *webview2 = [[UIWebView alloc] initWithFrame:webFrame];
       webview2.backgroundColor = [UIColor whiteColor];
       webview2.scalesPageToFit = YES;
       webview2.allowsInlineMediaPlayback=YES;
       [dialPadBTView addSubview:webview2];
       NSString *html = @"<html><head><meta name=""viewport"" content=""width=640""/></head><body>\
       <object style=""height: 390px; width: 640px""><param name=""movie"" value=""http://www.youtube.com/v/ucivXRBrP_0?version=3&feature=player_detailpage""><param name=""allowFullScreen"" value=""true""><param name=""allowScriptAccess"" value=""always""><embed src=""http://www.youtube.com/v/ucivXRBrP_0?version=3&feature=player_detailpage"" type=""application/x-shockwave-flash"" allowfullscreen=""true"" allowScriptAccess=""always"" width=""640"" height=""360""></object>\
       </body</html>";
       
       [webview2 loadHTMLString:html baseURL:[NSURL URLWithString:@"http://www.apple.com"]];
       */
      /*
       NSString *html = @"<html><head><meta name=""viewport"" content=""width=320""/></head><body><h1>Header</h1><p>This is some of my introduction..BLA BLA BLA!!</body</html>";
       */
      
   }
   
  //-- bti=[UIImage imageNamed:@"bt_settings.png"];
   uiEI=UIEdgeInsetsMake(0,0,szy/6,0);

   // keyPadInCall 
   for(int y=0,i=0;y<4;y++)
      for(int x=0;x<3;x++,i++){
         
         
         UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
         
         [button addTarget:self  action:@selector(inCallKeyPad_down:) forControlEvents:UIControlEventTouchDown];
         [button addTarget:self  action:@selector(inCallKeyPad_up:) forControlEvents:UIControlEventTouchUpInside];
         [button addTarget:self  action:@selector(inCallKeyPad_up:) forControlEvents:UIControlEventTouchUpOutside];
         [button addTarget:self  action:@selector(inCallKeyPad_up:) forControlEvents:UIControlEventTouchDragOutside];
         
         
         
         //--[button setBackgroundImage:bti forState:UIControlStateHighlighted];
         //setTitleColor
         button.showsTouchWhenHighlighted=YES;
         
         [button.titleLabel setFont:[UIFont boldSystemFontOfSize:i==9?52:32]];
         [button.titleLabel setTextColor:[UIColor whiteColor]];
         
         [button setTitle:ns[i] forState:UIControlStateNormal];
         
         [button setIsAccessibilityElement:YES];
         button.accessibilityLabel=ns[i];
         button.accessibilityTraits=UIAccessibilityTraitKeyboardKey;
         
         float ox=ofsx+x*(szx+sp);
         float oy=ofsy+y*(szy+sp);
         button.frame = CGRectMake(ox,oy, szx, szy);
         
         UILabel *lb=[[UILabel alloc]initWithFrame:CGRectMake(0,0+szy*5/8,szx,szy*3/8)];
         lb.text=ns_text[i];
         lb.font=[UIFont systemFontOfSize:12];
         lb.textColor=[UIColor whiteColor];
         lb.textAlignment=UITextAlignmentCenter;
         lb.backgroundColor=[UIColor clearColor];           
         [button addSubview:lb ];
         [button setEnabled:YES];
         
         if(i==9)button.contentEdgeInsets=UIEdgeInsetsMake(szy/4,0,0,0);else
            if(i!=11 && i!=9)button.contentEdgeInsets=uiEI;
         
         [keyPadInCall addSubview:button];
      }
   
   [keyPadInCall setHidden:YES];
   
   btHideKeypad= [UIButton buttonWithType:UIButtonTypeCustom];
   bti=[UIImage imageNamed:@"bt_gray.png"];
   
   [btHideKeypad setBackgroundImage:bti  forState:UIControlStateNormal];
   [btHideKeypad setTitle:@"Hide Keypad" forState:UIControlStateNormal];
   [btHideKeypad addTarget:self  action:@selector(hideKeypad:) forControlEvents:UIControlEventTouchUpInside];
   
   btHideKeypad.frame=answer.frame;
   
   [[answer superview]addSubview:btHideKeypad];
   
   [btHideKeypad setHidden:YES];
}

-(void)init_or_reinitDTMF{
   
   void setDtmfEnable(int f);
   
   setDtmfEnable(UIAccessibilityIsVoiceOverRunning()?0:1);
   
   return;
   
   NSLog(@"Init dtmf");
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      static int iX=0;
      if(!iX){
         iX=1;
         const char *xr[]={"",":d ",":d"};//onforeground
         z_main(0,3,xr);
         iX=0;
         
      }
   });
}

-(void)awakeFromNib{
   [self initT];
}

-(void)initT {
   
   static int iInit=1;
   if(!iInit)return;
   iInit=0;
   
   
   
   void t_init_log();
   t_init_log();

   iOnMute=0;
   iVideoScrIsVisible=0;
   iExiting=0;
   iLoudSpkr=0;
   
   iAudioUnderflow=0;
   iSettingsIsVisble=0;
   iShowCallMngr=0;
   iCanShowMediaInfo=0;
   iAudioBufSizeMS=700;
   vvcToRelease=NULL;
#ifdef T_CREATE_CALL_MNGR 
   callMngr=NULL;
#endif
   iPrevCallLouspkrMode=0;
   uiCanShowModalAt=0;
   
   endCallRect=endCallBT.frame;
   sList=NULL;
   iCallScreenIsVisible=0;
   iAnimateEndCall=1;
   iIsClearBTDown=0;
   iIsInBackGround=1;
   iSecondsInBackGroud=0;
   incomCallNotif=NULL;
   
   szLastDialed[0]=0;
   
   calls.init();
   
   iCanHideNow=0;
   
   setPhoneCB(&fncCBRet,self);
   
   objLogTab=nil;

   [self hideLogTab];
   
   [self checkProvValues];
   
   [cfgBT setHidden:YES];

   [uiMainTabBarController setSelectedIndex:3];
   
   nr.delegate=self;
   nr.enablesReturnKeyAutomatically = NO;

   uiCallInfo.lineBreakMode = UILineBreakModeWordWrap;
   uiCallInfo.numberOfLines = 0;
   
   [backToCallBT setHidden:YES];
   
   CALayer *l;
   
   [lbVolumeWarning setHidden:YES];
   l=lbVolumeWarning.layer;
   l.borderColor = [UIColor whiteColor].CGColor;
   l.cornerRadius = 5;
   l.borderWidth=2;
   
   
   [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(onNewProximityState)
                                                name:UIDeviceProximityStateDidChangeNotification
                                              object:nil];
   
   // Register for battery level and state change notifications.
   [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(batteryLevelDidChange:)
                                                name:UIDeviceBatteryLevelDidChangeNotification object:nil];
   
   [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(batteryStateDidChange:)
                                                name:UIDeviceBatteryStateDidChangeNotification object:nil];
   
   [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(reachabilityChanged:)
                                                name: kReachabilityChangedNotification object: nil];
   
	
   internetReach = [[Reachability reachabilityForInternetConnection] retain];
	[internetReach startNotifier];

   
   [UIDevice currentDevice].batteryMonitoringEnabled = YES;
   
   iSASConfirmClickCount=(int*)findGlobalCfgKey("iSASConfirmClickCount");;
   backspaceBT.accessibilityTraits=UIAccessibilityTraitKeyboardKey;
   
}

#pragma mark - Network notifications

- (void) reachabilityChanged: (NSNotification* )note
{
	Reachability* curReach = [note object];
	NSParameterAssert([curReach isKindOfClass: [Reachability class]]);
   
   NetworkStatus netStatus = [curReach currentReachabilityStatus];
   BOOL connectionRequired= [curReach connectionRequired];
   NSString* statusString= @"";
   int checkIPNow();
   
   switch (netStatus)
   {
      case NotReachable:
      {
         statusString = @"Access Not Available";
         //Minor interface detail- connectionRequired may return yes, even when the host is unreachable.  We cover that up here...
         connectionRequired= NO;
         break;
      }
         
      case ReachableViaWWAN:
      {
         statusString = @"Reachable WWAN";
         break;
      }
      case ReachableViaWiFi:
      {
         statusString= @"Reachable WiFi";
         break;
      }
   }

   int net_ok = checkIPNow();
   NSLog(@"Connection:(%@) net_ok=%d req=%d", statusString, net_ok, connectionRequired);

}



#pragma mark - Battery notifications

- (void)batteryLevelDidChange:(NSNotification *)notification
{
   [self checkBattery];
}

- (void)batteryStateDidChange:(NSNotification *)notification
{
   [self checkBattery];
}

-(void) checkBattery{
   
   if(iVideoScrIsVisible)return;
   
   int iKeepScreenOnIfBatOk=0;
   findIntByServKey(NULL, "iKeepScreenOnIfBatOk", &iKeepScreenOnIfBatOk);
   
   UIDeviceBatteryState bs = [UIDevice currentDevice].batteryState;
   float bl = [UIDevice currentDevice].batteryLevel;
   
   int on=0;

   if(bs==UIDeviceBatteryStateFull || bs==UIDeviceBatteryStateCharging){
      if(bl>=.5)on=1;
   }
   
   [[ UIApplication sharedApplication ] setIdleTimerDisabled: on && iKeepScreenOnIfBatOk==1? YES : NO];
}

-(void)showChatTab{
   if(objLogTab){
      NSMutableArray *newControllers = [NSMutableArray arrayWithArray: [uiMainTabBarController viewControllers]];
      [newControllers addObject:objLogTab];
      [uiMainTabBarController setViewControllers: newControllers animated: NO];
      [objLogTab release];
      objLogTab=nil;
      [self updateLogTab]; 
   }
   
}
-(void)hideLogTab{
   if(objLogTab)return;
   
   NSMutableArray *newControllers = [NSMutableArray arrayWithArray: [uiMainTabBarController viewControllers]];
   objLogTab=[newControllers objectAtIndex:4];
   [objLogTab retain];
   [newControllers removeObjectAtIndex:4];
   [uiMainTabBarController setViewControllers: newControllers animated: NO];
}



#pragma mark - UIApplication notifications

- (void)application:(UIApplication *)app didReceiveLocalNotification:(UILocalNotification *)notif {
   // Handle the notificaton when the app is running
//   NSLog(@"Recieved Notification %@",notif);
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation{
    NSLog(@"Recieved openURL %@ %@",[url absoluteString],sourceApplication);
   const char *p=[[url absoluteString] UTF8String];
   int l=[url absoluteString].length;
   
   
   int isSPURL(const char *p, int &l);
   int iIs=isSPURL(p, l);
   
   
   if(l>0 && iIs)
      [self setText:[NSString stringWithUTF8String:p+iIs]];
   
   [uiMainTabBarController setSelectedIndex:3];
   
   return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
   // [UIApplication sharedApplication].applicationIconBadgeNumber|=16;
   // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
   // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}


-(void)tryWorkInBackground{
   
   UIApplication *app=[UIApplication sharedApplication];

   iIsInBackGround=1;
   iSecondsInBackGroud=0;
   
   BOOL yes=[app setKeepAliveTimeout:(UIMinimumKeepAliveTimeout) handler: ^{
      [self keepalive2];
   }];
   
   NSLog(@"bg=%d mi=%d",(int)yes, (int)UIMinimumKeepAliveTimeout+5);

#if defined(_WAKE_FROM_BACKGROUD_SLOW)
   [self performSelectorOnMainThread:@selector(keepalive2)    withObject:nil waitUntilDone:YES];
#else
   uiBackGrTaskID=[[UIApplication sharedApplication]  beginBackgroundTaskWithExpirationHandler:^{
      
      if(uiBackGrTaskID && uiBackGrTaskID!=UIBackgroundTaskInvalid)
         [[UIApplication sharedApplication] endBackgroundTask:uiBackGrTaskID];
      uiBackGrTaskID=NULL;
      
   }];
   //TODO if uiBackGrTaskID is ok, then sleep(1)*40,rereg(600s),sleep(1)*20,endBackgroundTask
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [self atBackgroundStart];
      
   });
#endif
   NSLog(@".abc back.");
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
   
   NSLog(@"applicationDidEnterBackground");

   [recentsController saveRecents];
   
   if(!iExiting){
      if(vvcToRelease && iVideoScrIsVisible) [vvcToRelease onGotoBackground];
      {const char *xr[]={"",":d"};z_main(0,2,xr);}//stop dtmf player
      [self tryWorkInBackground];
   }
   calls.relCallsNotInUse();
}




- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
   //--dbg--[UIApplication sharedApplication].applicationIconBadgeNumber=100;
   
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      {const char *xr[]={"",":reg"};z_main(0,2,xr);}
      setPhoneCB(&fncCBRet,self);
   });
   
   NSLog(@"didFinishLaunchingWithOptions %d", application.applicationState);
   
   if(UIApplicationStateBackground==application.applicationState)
      [self tryWorkInBackground];
   
   return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
   
   NSLog(@"applicationWillEnterForeground");

   if(iIsInBackGround){
      [[UIApplication sharedApplication] clearKeepAliveTimeout];
      
      if(uiBackGrTaskID && uiBackGrTaskID!=UIBackgroundTaskInvalid)[[UIApplication sharedApplication] endBackgroundTask:uiBackGrTaskID];
      uiBackGrTaskID=UIBackgroundTaskInvalid;
   }
   iIsInBackGround=0;
   
   if(vvcToRelease && iVideoScrIsVisible) [vvcToRelease onGotoForeground];
   
   if(!calls.getCallCnt()){
      [self stopRingMT];
   }
   
   
   
   // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
   NSLog(@"applicationDidBecomeActive %d", application.applicationState);
   setPhoneCB(&fncCBRet,self);
   iIsInBackGround=0;
   
   [self showCallScrMT];
   
   [self checkBattery];
   
   [self makeDPButtons];

   [self loadCC];
   
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      const char *xr[]={"",":onka",":onforeground"};//
      z_main(0,3,xr);
   });
   
   [self init_or_reinitDTMF];
   
   int isProvisioned(int iCheckNow);
   int provOk=isProvisioned(0);
   
   
   if(!provOk){
      [self showProvScreen];
   }
   else{
      [self setAccountTitle:nil];
   }
   [[UIApplication sharedApplication] cancelAllLocalNotifications];
   
   [recentsController resetBadgeNumber:false];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
   // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
   iExiting=1;
   
   NSLog(@"Terminating app");
   
   if(iIsInBackGround){
      iIsInBackGround=0;
      [[UIApplication sharedApplication] clearKeepAliveTimeout];
      if(uiBackGrTaskID && uiBackGrTaskID!=UIBackgroundTaskInvalid)[[UIApplication sharedApplication] endBackgroundTask:uiBackGrTaskID];
   }
   
   void t_onEndApp();
   t_onEndApp();
   
   [internetReach stopNotifier];
   [internetReach release];
   
   NSLog(@"Terminated");
}

#pragma mark - backgroud

-(void) atBackgroundStart{
   iSecondsInBackGroud=0;
   usleep(1000);
   NSTimeInterval t;
   for(int i=0;i<30 && iIsInBackGround;i++){
      iSecondsInBackGroud++;
      sleep(1);
      if(i>6){
         t=[[UIApplication sharedApplication] backgroundTimeRemaining];
         if(t<20)break;
      }
   }
   if(iIsInBackGround){
      const char *xr[]={"",":onka"};//will rereg here
      z_main(0,2,xr);
      
      NSLog(@"rereg ");
      for(int i=0;i<120 && iIsInBackGround;i++){
         iSecondsInBackGroud++;
         sleep(1);
         if(i>2){
            if(i>10 && getReqTimeToLive()<1)break;
            t=[[UIApplication sharedApplication] backgroundTimeRemaining];
            if(t<10)break;
         }
         //TODO if all eng are online goto sleep
      }
   }
   
   NSLog(@"going to sleep");
   
   if(iIsInBackGround && uiBackGrTaskID && uiBackGrTaskID!=UIBackgroundTaskInvalid)[[UIApplication sharedApplication] endBackgroundTask:uiBackGrTaskID];
   uiBackGrTaskID=NULL;
   
   
}


-(void) keepalive2{
   
   
   NSTimeInterval t=0;
   NSLog(@"KA waking up ");
   
   const char *xr[]={"",":onka"};//will rereg here
   z_main(0,2,xr);
   
   NSLog(@" ,rereg ok");
   
   for(int i=0;i<7 && iIsInBackGround;i++){
      iSecondsInBackGroud++;
      sleep(1);
      if(i>4){
         if(getReqTimeToLive()<1)break;
         t=[[UIApplication sharedApplication] backgroundTimeRemaining];
         if(t<2)break;
      }
   }
   
   NSLog(@"KA going to sleep bckgr=%ds rem=%fs\n", iSecondsInBackGroud,t);
}


-(void)loadCC{
   static int iCLoaded=0;
   if(iCLoaded)return ;
   iCLoaded=1;
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      
      int iLen=0;
      char *p=iosLoadFile("Country.txt",iLen);
      if(p){
         initCC(p,iLen);
         delete p;
      }
   });
}

- (void)dealloc
{
   //	[navigationController release];
   //TODO releaseALL obj
   NSLog(@"dealloc 1");
   [btSAS release];
   [btChangePN release];
   [lbSecure release];
   [uiZRTP_peer release];
   [uiDur release];
   [fPadView release];
   [second release];
   if(callMngr)[callMngr release];
   [window release];
   callMngr=nil;
   [super dealloc];
   NSLog(@"dealloc ok");
}

-(IBAction)showSettings{
   
   static int iLoading=0;
   
   if(iLoading)return;
   iLoading=1;
   
   sList=new CTList();//
   void loadSettings(CTList *l);
   loadSettings(sList);
   [settings_ctrl setList:sList];
   
   
   iSettingsIsVisble=1;
   [recentsController presentModalViewController:settings_nav_ctrl animated:YES];
   iLoading=0;
}



-(IBAction)saveSettings{
   
   void saveCfgFromList(CTList *l,AppDelegate *s);
   saveCfgFromList(sList, self);
   sList=NULL;
   [self settingsDone];
   
}

-(IBAction)settingsDone{
   [settings_nav_ctrl dismissModalViewControllerAnimated:YES];
   iSettingsIsVisble=0;
   [self performSelector:@selector(showCallScrMT) withObject:nil afterDelay:1.5];
   CTList *l=sList;
   if(l){l->removeAll();sList=NULL;}
}

-(void) setNewCurCallMT{
   int cc=calls.getCallCnt();
   
   
   
   if(cc<2)iShowCallMngr=0;
   if(cc==1){
      CTCall *c=calls.curCall;//calls.getLastCall();
      if(!c || ! (CTCalls::isCallType(c,CTCalls::ePrivateCall) || CTCalls::isCallType(c,CTCalls::eConfCall)) )c=calls.getLastCall();
      if(!c || c->iEnded){
         [self hideCallScreen];
      }else{
         [self setCurCallMT:c];
         //self checkMedia:c
         if(vvcToRelease && iVideoScrIsVisible){
            if(!vvcToRelease.isBeingDismissed){
               iVideoScrIsVisible=0;
               [vvcToRelease.navigationController popViewControllerAnimated:YES];
            }
            
         }
      }
      //  [self updateCallDurMT
   }
   else if(cc>1){
      [self needShowCallMngr]; 
   }
   else [self hideCallScreen];
}


-(void)needShowCallMngr{
   int cc=calls.getCallCnt();
   NSLog(@"show call mngr cc=%d",cc);

   iShowCallMngr=1;
   if(iCallScreenIsVisible){
      [self showCallManeger];
   }
}
#pragma mark - Local notifications

-(void)notifyMissedCall:(CTCall *)c{
   if ([UIApplication sharedApplication].applicationState !=  UIApplicationStateActive) {
      // Create a new notification
      UILocalNotification* notif = [[[UILocalNotification alloc] init] autorelease];
      if (notif) {
         [self findName: c];
         notif.repeatInterval = 0;
         notif.alertBody =[NSString stringWithFormat: @"Missed call from %@", toNSFromTB(&c->nameFromAB)];
         notif.alertAction = @"Missed Call";
         notif.soundName = nil;
         // Specify custom data for the notification
         //    NSDictionary *infoDict = [NSDictionary dictionaryWithObject:@"someValue" forKey:@"someKey"];
         //  notif.userInfo = infoDict;
         
         [[UIApplication sharedApplication]  presentLocalNotificationNow:notif];
      }
   }
}

-(void)notifyIncomCall:(CTCall *)c{
   if ([UIApplication sharedApplication].applicationState !=  UIApplicationStateActive) {
      // Create a new notification
      UILocalNotification* notif = [[UILocalNotification alloc] init];
      if (notif) {
         notif.repeatInterval = 0;
         // toNSFromTB(&c->nameFromAB)
         NSString *p = [self findName:c];
         
         notif.alertBody =[NSString stringWithFormat: @"Incoming call from\n%@ %@",toNSFromTB(&c->nameFromAB), p];
         notif.alertAction = @"Answer";
         int useRetroRingtone();
         notif.soundName = useRetroRingtone()?@"ring_retro.caf":@"ring.caf";
         // Specify custom data for the notification
         //    NSDictionary *infoDict = [NSDictionary dictionaryWithObject:@"someValue" forKey:@"someKey"];
         //  notif.userInfo = infoDict;
         
         [[UIApplication sharedApplication]  presentLocalNotificationNow:notif];
         incomCallNotif=notif;
         
      }
   }
}


-(void)incomingCall:(CTCall *)c{
   int cc=calls.getCallCnt();
   
   if(!cc)return;
   
   int d=(int)(getTickCount()-uiCanShowModalAt);
   if(second.isBeingDismissed || (d<0 && d>-5000)){
      
      [self performSelector:@selector(incomingCall:) withObject:nil afterDelay:1];
      return;
   }
   
   if(c){
      
      if(cc==1){
         [self setCurCallMT:c];
         
         if(iIsInBackGround)
            [self notifyIncomCall:c];//do it only when app is in background
         
         
         void* playDefaultRingTone(int iIsInBack);
         playDefaultRingTone(iIsInBackGround);
         
      }
      else{
         [self needShowCallMngr];
         int ca=calls.getCallCnt(calls.eStartupCall);
         if(ca){
            //beep
            char buf[64];
            sprintf(&buf[0],"*r%u",c->iCallId);
            sendEngMsg(c->pEng, &buf[0]);
         }
      }
      
   }
   
   if(cc==1){
      [self switchAR:iPrevCallLouspkrMode];//
      [self muteMic:0];
   }
   
   [self showCallScrMT];
   
}

-(void)updateRecents:(CTCall *)c{
   if(!c || c->iRecentsUpdated || !c->iCallId)return;
   
   c->uiRelAt=getTickCount()+5000;
   if(!c->uiRelAt)c->uiRelAt=1;//if getTickCount()+5000 == 0
   
   c->iRecentsUpdated=1;
   // c->
   const char *pServ="Unknown";
   if(!c->pEng)c->pEng=getCurrentDOut();;
   if(c->pEng){
      int sz=0;
      char *pRet=(char*)findCfgItemByServiceKey(c->pEng, (char*)"tmpServ", sz, NULL, NULL);
      if(pRet && sz>0){
         pServ=pRet;
      }
      
   }
   
   if(c->iIsIncoming && !c->uiStartTime){
      [self notifyMissedCall: c];
      [recentsController addToRecents:CTRecentsAdd::addMissed(&c->nameFromAB, &c->bufPeer[0],0,pServ)];
   }
   else if(c->iIsIncoming)
      [recentsController addToRecents:CTRecentsAdd::addReceived(&c->nameFromAB,&c->bufPeer[0],get_time()-(int)c->uiStartTime,pServ)];
   else 
      [recentsController addToRecents:CTRecentsAdd::addDialed(&c->nameFromAB, &c->bufPeer[0],c->uiStartTime?(get_time()-(int)c->uiStartTime):0,pServ)];
   
}

-(CTCall *)getEmptyCall:(int)iIsMainThread{
   
   return calls.getEmptyCall(iIsMainThread);
}
-(CTCall *)findCallById:(int)iCallId{
   
   return calls.findCallById(iCallId);
}


-(void)clearZRTP_infoMT{
   [btSAS setHidden:YES];
   [btChangePN setHidden:YES];
   [uiZRTP_peer setHidden:YES];
   [verifySAS setHidden:YES];
   
   [uiDur setText:@""];
   [uiMediaInfo setText:@""];
   [lbSecure setText:@"Connecting"];
   lbSecure.alpha=1.0;
   [lbSecure setHidden:NO];
   
}
//
#if 1
-(void)updateZRTP_infoMT:(CTCall*)c{
   
   if(vvcToRelease && iVideoScrIsVisible){
      [vvcToRelease showInfoView];
   }
   

   
   int iHideSASAndVerify = iCanShowSAS_verify==0 && iSASConfirmClickCount && iSASConfirmClickCount[0]<T_SAS_NOVICE_LIMIT && c->zrtpWarning.getLen()==0 && c->zrtpPEER.getLen()==0;
   
   
   
   int iShowPeer=(c->zrtpPEER.getLen()>0 || (!(c->iShowEnroll|c->iShowVerifySas) && c->bufSAS[0]));
   
   int iGreenDispName=(c->nameFromAB==&c->zrtpPEER);//if cache matches display name
   
   if(iShowPeer && iGreenDispName)iShowPeer=0;
   
   [lbDstName setTextColor:iGreenDispName?[UIColor greenColor]:[UIColor whiteColor]];
   
   
   if(iShowPeer){
      [uiZRTP_peer setHidden:NO];
      [uiZRTP_peer setText:toNSFromTB(&c->zrtpPEER)];
      [ivBubble setHidden:NO];
      [btChangePN setHidden:NO];
   }else {
      [uiZRTP_peer setHidden:YES];
      [ivBubble setHidden:YES];
      [btChangePN setHidden:YES];
   }
   int iSecureInGreen=0;
   
   
   
   if(c->iActive || (!c->iEnded && c->bufSecureMsg[0])){
      lbSecure.alpha=1.0;
      [lbSecure setHidden:NO];
      iSecureInGreen = c->setSecurityLines(lbSecure, lbSecureSmall);
   }
   else {
      [lbSecure setText:@""];
      [lbSecureSmall setText:@""];
   }
   
   if(c->bufSAS[0] && !iHideSASAndVerify){
      btSAS.alpha=1.0;
      [btSAS setHidden:NO];
      [btSAS setTitle:[NSString stringWithUTF8String:&c->bufSAS[0]] forState:UIControlStateNormal];
   }else [btSAS setHidden:YES];
   
   if(!c->bufSAS[0]){
      [verifySAS setHidden:YES];
   }
   else if(c->iShowEnroll){
      c->iShowVerifySas=0;
      [verifySAS setTitle:@"Trust PBX" forState:UIControlStateNormal];
      [verifySAS setHidden:NO];
   }
   else if(c->iShowVerifySas && !iHideSASAndVerify){
      
      [verifySAS setTitle:@"Verify" forState:UIControlStateNormal];
      [self showVerifyBT];
      [verifySAS setHidden:NO];
   }
   else{
      [verifySAS setHidden:YES];
   }
   btSAS.alpha=iSecureInGreen?0.3:1;
   
   [self checkVideoBTState:c];
   
   
   int iCanEnableVBt=c->iActive && !c->iEnded && !c->iShowVerifySas && c->bufSAS[0] && c->zrtpPEER.getLen()>0;
   
   if(c->iShowVideoSrcWhenAudioIsSecure==1){
      
      if(iCanEnableVBt){
         c->iShowVideoSrcWhenAudioIsSecure=2;
         if(!iVideoScrIsVisible)[self showVideoScr:1 call:c];
      }
   }
}


#endif

-(void)checkVideoBTState:(CTCall *)c{
   int iCanEnableVBt=c->iActive && !c->iEnded && !c->iShowVerifySas && c->bufSAS[0] && c->zrtpPEER.getLen()>0;
   
   videoBT.enabled=!!iCanEnableVBt;
   
   int iCanAttachDetachVideo;
   
   if(0>=findIntByServKey(c->pEng,"iCanAttachDetachVideo",&iCanAttachDetachVideo)){
      [videoBT setHidden:!iCanAttachDetachVideo];
   }
   
}

- (void)onNewProximityState{
   BOOL b = UIAccessibilityIsVoiceOverRunning();
   NSLog(@"UIAccessibilityIsVoiceOverRunning()=%d",b);
   if(!b){
      return;
   }
   
   if([UIDevice currentDevice].proximityState){//if true device is close to user
      [self switchAR:0];
   }
   else{
      [self switchAR:1];
   }
}

-(int)showCallScrMT{
   if(iIsInBackGround){

      return 0;
   }

   int cc=calls.getCallCnt();
   NSLog(@"cc=%d",cc);
   if(!cc)return -1;
   
  
   UIDevice *device = [UIDevice currentDevice];
   device.proximityMonitoringEnabled = YES;
   if (device.proximityMonitoringEnabled == YES){
      NSLog(@"pr ok");
   } 
   
   [self tryShowCallScrMT];
   
   return 1;
}

-(IBAction)showCallScrPress{
   [self setCurCallMT:calls.curCall]; 
   [self tryShowCallScrMT];
}

-(void)checkLeds{
   int *pi=(int*)findGlobalCfgKey("iShowRXLed");
   int hideLeds=!pi || *pi==0;
   [iwLed setHidden:hideLeds];
   
   {
      CGPoint p = CGPointMake(
                              hideLeds ? iwLed.frame.origin.x : (iwLed.frame.origin.x+10),
                              uiMediaInfo.frame.origin.y
                              );
      
      
      CGRect r = CGRectMake(p.x, p.y, uiMediaInfo.frame.size.width, uiMediaInfo.frame.size.height);
      uiMediaInfo.frame = r;
   }
}

-(void)tryShowCallScrMT{
   NSLog(@"iCallScreenIsVisible=%d iSettingsIsVisble=%d",iCallScreenIsVisible,iSettingsIsVisble);
   
   if(second.isBeingDismissed){
      [self performSelector:@selector(tryShowCallScrMT) withObject:nil afterDelay:1];
      return;
   }
   
   NSLog (@"res=%d %p",second==recentsController.modalViewController,recentsController.modalViewController);
   
   if(iSettingsIsVisble)return;
   
   if(second==recentsController.modalViewController)iCallScreenIsVisible=1;
   
   if(iCallScreenIsVisible || second.isBeingPresented){
      if(iShowCallMngr)
         [self showCallManeger];
      return ;
   }
   iCallScreenIsVisible=1;

   [self checkVolumeWarning];
   
   [self checkLeds];

   //TODO checkSpkrState
   
   iAnimateEndCall=1;
   if(1){
      
      [self.navigationController setNavigationBarHidden:YES animated:NO];
      
      [recentsController presentModalViewController:second animated:YES];
      
      [second setNavigationBarHidden:YES];
      
      void LaunchThread(AppDelegate *p);
      LaunchThread(self);
      
      findIntByServKey(NULL, "iAudioUnderflow", &iAudioUnderflow);
   }
   
   
   if(iShowCallMngr)
      [self showCallManeger];
}

-(NSString *)findName:(CTCall *)c{
   
   // static CTMutex t;
   // t.lock();
   char bufRet[128];
   char bufRet2[128];
   
   char *p2=&c->bufPeer[0];
   if(!c->iIsIncoming && c->bufDialed[0]){
      p2=&c->bufDialed[0];
   }
   //remove server
   for(int i=0;i<sizeof(bufRet);i++){
      if(!p2[i])break;
      if(p2[i]=='@'){
         strncpy(bufRet,p2,i);
         bufRet[i]=0;
         p2=&bufRet[0];
         break;
      }
   }


   int ret=[self findName:p2 len:strlen(p2) pEng:c->pEng  bOut:&c->nameFromAB];
   
   if(fixNR(p2,bufRet2,sizeof(bufRet2)-1)>=0)
      p2=&bufRet2[0];
   
   if(ret>=0){
      
   }
   else if(c->iIsIncoming){
      c->findSipName();
   }
   return  [NSString stringWithUTF8String:p2];
   
}

-(NSString *)loadUserData:(CTCall*)c{
   
   // static CTMutex t;
   // t.lock();
   char bufRet[128];
   char bufRet2[128];
   
   char *p2=&c->bufPeer[0];   
   if(!c->iIsIncoming && c->bufDialed[0]){
      p2=&c->bufDialed[0];
   }

   for(int i=0;i<sizeof(bufRet);i++){
      if(!p2[i])break;
      if(p2[i]=='@'){
         strncpy(bufRet,p2,i);
         bufRet[i]=0;
         p2=&bufRet[0];
         break;
      }
   }
 
   if(fixNR(p2,bufRet2,sizeof(bufRet2)-1)>=0)
      p2=&bufRet2[0];
   
   if(c->iUserDataLoaded){
      if(!c->nameFromAB.getLen()){
         if(c->iActive)c->findSipName();
      }
      //      t.unLock();
      return [NSString stringWithUTF8String:p2];
   }
   c->iUserDataLoaded=1;
   
   int ret=[self findName:p2 len:strlen(p2) pEng:c->pEng  bOut:&c->nameFromAB];
   
   if(ret>=0){
      if(!c->img){
         NSData *data = [recentsController getImageData:ret];
         if(data){
            // c->img=[UIImage imageWithData:data];
            c->img=[[UIImage alloc]initWithData:data];if(c->img)c->iImgRetainCnt++;
            
            [data release];
            if(c->img){
               c->iUserDataLoaded=2;
               [c->img retain]; c->iImgRetainCnt++;
            }
         }
      }
   }
   else if(c->iIsIncoming){
      c->findSipName();

   }
   return [NSString stringWithUTF8String:p2];
}
-(void)unholdAndPutOthersOnHold:(CTCall*)c{
   if(!c)return;//or put all on hold
   calls.lock();
   int cc=calls.getCallCnt();
   
   
   [self holdCallN:c hold:0];
   
   
   //int n=0;
   for(int i=0;i<cc+1;i++){
      CTCall *ch=calls.getCall(i);
      if(!ch || ch->iEnded || !ch->iActive)continue;
      if(ch!=c){
         if(ch->iIsInConferece && c->iIsInConferece){
            [self holdCallN:ch hold:0];
         }
         else{
            [self holdCallN:ch hold:1];
         }
      }
      //  NSLog(@"%p %p %s",c,ch,ch->bufPeer);
   }
   calls.unLock();
}

-(void)setCallScrFlagMT:(const char *)pNr{
   
   int findCSC_C_S(const char *nr, char *szCountry, char *szCity, char *szID, int iMaxLen);
   char bufC[64],szCity[64],sz2[64];
   

   
   if(findCSC_C_S(pNr, &bufC[0], &szCity[0], &sz2[0],64)>0){
      strcat(sz2,".png");
      UIImage *im=[UIImage imageNamed: [NSString stringWithUTF8String:&sz2[0]]];
      lbDst.center=CGPointMake(105+28,52);
      [callScreenFlag setImage:im];
      
   }
   else{
      lbDst.center=CGPointMake(105,52);
      [callScreenFlag setImage:nil];
   }
   

}

-(int)setCurCallMT:(CTCall*)c{
   //TODO reset screen state
   //TODO if c!=curCall
   
   if(!c || !c->iInUse)return 0;
   calls.setCurCall(c);
   
   int cc=calls.getCallCnt();
   if(!cc){
      NSLog(@"GUI Err no active calls");
      return -1;
   }
   
   
   [self unholdAndPutOthersOnHold:c];
   
   //TODO lockCalls
   
   [backToCallBT setHidden:NO];
   
   [keyPadInCall setHidden:YES];
   [infoPanel setHidden:NO];
   
   int iShowAnswBt=c->mustShowAnswerBT();
   
   if(iShowAnswBt){
      if(isVideoCall(c->iCallId)){
         [answer setImage:[UIImage imageNamed:@"ico_camera.png"] forState:UIControlStateNormal];
      }
      else{
         [answer setImage:nil forState:UIControlStateNormal];
      }
   }
   
   
   [btHideKeypad setHidden:YES];
   
   [answer setHidden:!iShowAnswBt];  
   
   [endCallBT setTitle:!iShowAnswBt || c->iEnded?@"End Call":@"Decline" forState:UIControlStateNormal];
   
   [self setEndCallBT:0 wide:!iShowAnswBt];//delay
   
   fPadView.alpha=1.0;
   
   [fPadView setHidden:NO];
   [view6pad setHidden:NO];
   
   if(!c->iEnded && !c->iActive && c->bufSecureMsg[0])
      [self showZRTPPanel:0];
   else if(!c->iActive || c->iEnded)
      [self showInfoLabel:0];
   else if(c->iActive)
      [self showZRTPPanel:0];

   
   NSString *ci=[NSString stringWithUTF8String:&c->bufMsg[0]];
   [uiCallInfo setText:ci];
   
   if(!c->iActive){
      [uiMediaInfo setText:@""];
   }
   
   if((c->bufSecureMsg[0] || uiCallInfo.isHidden) && !c->iActive && !c->iEnded){
      [uiDur setText:ci];
      NSLog(@"ci=%@",ci);
   }
   else [uiDur setText:@""];
   
   if(!c->bufServName[0]){
      safeStrCpy(c->bufServName,getAccountTitle(c->pEng), sizeof(c->bufServName)-1);
     // strcpy(c->bufServName,getAccountTitle(c->pEng));
   }
   [uiServ setText:[NSString stringWithUTF8String:&c->bufServName[0]]];

   NSString *p2=[self loadUserData:c];
   
   if(c->img){
      [c->img retain];c->iImgRetainCnt++;
      [peerPB_Img setImage:nil];
      [peerPB_Img setImage:c->img];
   }
   else{
      [peerPB_Img setImage:nil];
   }
   const char *pUtfP2=[p2 UTF8String];
   
   [lbDstName setText:toNSFromTB(&c->nameFromAB)];

   //dont repeat if matches
   [lbDst setText:(c->nameFromAB==pUtfP2?@"":p2)];
   
   [self setCallScrFlagMT:pUtfP2];
   
   [self updateZRTP_infoMT:c];
   
   if(!c->iEnded){
      if(c->iIsIncoming && !c->iActive)view6pad.alpha=.3;
      else view6pad.alpha=1.0;
   }
   

   return 0;
   
}

+(int)isAudioDevConnected{
   
   CFStringRef s;
   int getAOState(CFStringRef *state);
   getAOState(&s);
   if(!s)return 0;
   NSString *str=(NSString *)s;
   
   NSLog(@"ao=%@",s);

   NSRange r;
   
   NSString *ao0[]={@"ReceiverAndMicrophone",@"SpeakerAndMicrophone",@"Speaker" ,NULL};
   NSString *ao1[]={@"Heads",@"Headp",@"BT", @"Headphone",@"HeadphonesAndMicrophone",@"HeadphonesBT",@"HeadsetBT",
                    @"MicrophoneBluetooth",@"HeadsetInOut" ,@"AirTunes",NULL};

   for(int i=0;;i++){
      if(!ao0[i])break;
      r=[str rangeOfString : ao0[i]];
      if(r.location!=NSNotFound){
         puts("Not found");
         return 0;
      }
   }

   
   for(int i=0;;i++){
      if(!ao1[i])break;
      r=[str rangeOfString : ao1[i]];
      if(r.location!=NSNotFound){
         puts("found");
         return 1;
      }
   }
   puts("ret0");
   
   //SpeakerAndMicrophone Speaker HeadphonesAndMicrophone ReceiverAndMicrophone Headphone
   //  HeadphonesBT  HeadsetBT MicrophoneBluetooth
  
   return 0;
}
-(int)callToR:(CTRecentsItem*)i{
   
   if(!i || i->peerAddr.getLen()<=0)return -1;
   char buf[128];
   getText(&buf[0],127,&i->peerAddr);
   
   void *findEngByServ(CTEditBase *b);
   void *eng = findEngByServ(&i->lbServ);
   if(!eng && i->lbServ.getLen()){
      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"SIP account is disabled or deleted"
                                                      message:nil
                                                     delegate:nil
                                            cancelButtonTitle:@"Ok"
                                            otherButtonTitles:nil];
      [alert show];
      [alert release];
      return -1;
   }
   
   return [self callToCheckUS:'c' dst:&buf[0] eng:eng];
}

-(int)callTo:(int)ctype dst:(const char*)dst{
   return [self callToS:ctype dst:dst eng:NULL];
}

-(int)callToCheckUS:(int)ctype dst:(const char*)dst eng:(void*)eng{
   
   int canAddUS_CCode(const char *nr);
   if(canAddUS_CCode(dst)){
      char dstnr[64];
      snprintf(dstnr, sizeof(dstnr)-1, "+1%s",dst );
      dstnr[63]=0;
      return [self callToS:ctype dst:dstnr eng:eng];
   }
   
   return [self callToS:ctype dst:dst eng:eng];
}

-(int)callToS:(int)ctype dst:(const char*)dst eng:(void*)eng{
   
   if(strncmp(dst,"*##*",4)==0){
      int l=strlen(dst);
      if(l>5 && dst[l-1]=='*'){
         
         if(strcmp(dst+4,"112233*")==0){
            void test_close_last_sock();
            test_close_last_sock();
            return 0;
         }
         /*
         if(strncmp(dst+4,"112244",6)==0){
            void test_send_options(const char *name);
            test_send_options(dst+4+6);
            return 0;
         }
         */
         if(strcmp(dst+4,"668423*")==0){
            if(iSASConfirmClickCount){
               iSASConfirmClickCount[0]=0;
               void t_save_glob();
               t_save_glob();
            }
            return 0;
         }
         if(strcmp(dst+4,"735*")==0){
            calls.relCallsNotInUse();
            return 0;
         }

         if(strcmp(dst+4,"56466*")==0){//logon
            [self showChatTab];
            return 0;
         }
         
         unsigned int calcMD5(const char *p, int iLen, int n);
         unsigned int code=calcMD5(dst+4,0,20000000);
         printf("[md5=0x%08x]\n",code);
         
         if(code==0x58e7fa40){
            iCfgOn=1;
            [cfgBT setHidden:NO];
            return 0;
         }
         
         const char *x[2]={"",dst};
         z_main(0,2,x); 
         return 0;
      }
   }
   
   CTCall *c=[self getEmptyCall:1];
   if(!c){
      return -1;
   }
   calls.setCurCall(c);
   strcpy(c->bufMsg,"Calling...");

   iShowCallMngr=0;
   if(strncmp(dst,"sip:",4)==0){
      dst+=4;
   }
   else if(strncmp(dst,"sips:",5)==0){
      dst+=5;
   }
   
   int iNRLen=strlen(dst);
   if(iNRLen>=sizeof(szLastDialed)-1){
      iNRLen=sizeof(szLastDialed)-1;
   }
   
   strncpy(szLastDialed,dst,iNRLen);
   szLastDialed[iNRLen]=0;
   
   int stripDotsIfNumber(char *p, int iLen);
   iNRLen = stripDotsIfNumber(szLastDialed, iNRLen);
   
   void *findBestEng(const char *dst, const char *name);
   void *pEng=eng?eng:findBestEng(szLastDialed,NULL);
   
   safeStrCpy(&c->bufDialed[0],szLastDialed,sizeof(c->bufDialed)-1);
   
   c->pEng=pEng;
   c->iShowVideoSrcWhenAudioIsSecure='c'!=ctype;
   char buf[128];
   snprintf(buf,127,":%c %s",ctype,szLastDialed);
   if(pEng){
      safeStrCpy(c->bufServName,getAccountTitle(pEng), sizeof(c->bufServName)-1);
      printf("[ds=%s, cmd={%s}]",c->bufServName,&buf[0]);
      sendEngMsg(pEng,&buf[0]);
   }
   else{
      const char *x[2];
      x[0]="";
      x[1]=&buf[0];
      z_main(0,2,x); 
   }
   
   [self setCurCallMT:c];
   
   if(calls.getCallCnt()==1){
      [self switchAR:iPrevCallLouspkrMode];// 
      [self muteMic:0];
   }
   
   [self setText:@""];

   
   if(![self showCallScrMT])return -2;

   
   return 0;
}
-(IBAction)makeCall:(int)ctype{
   
   const char *p=[[nr text] UTF8String];
   if(!p[0]){
      [self pickContact];
      return;
   }
   [self callTo:ctype dst:p];

}
/*
 - (BOOL)textFieldShouldBeginEditing:(UITextField *)textField;        // return NO to disallow editing.
 - (void)textFieldDidBeginEditing:(UITextField *)textField;           // became first responder
 
 - (BOOL)textFieldShouldEndEditing:(UITextField *)textField{          // return YES to allow editing to stop and to resign first responder status. NO to disallow the editing session to end
 return NO;
 }
 */

-(void)clearDelayed{
   [self setText:@""];
   [nr resignFirstResponder];

}

- (BOOL) textFieldShouldClear:(UITextField *)textField{
   [nr resignFirstResponder];   
   [self performSelector:@selector(clearDelayed) withObject:nil afterDelay:.1];
   return NO;
}
- (void)textFieldDidEndEditing:(UITextField *)textField{             // may be called if forced even if shouldEndEditing returns NO (e.g. view removed from window) or endEditing:YES called
   
   [self numberChange];
}
-(void) hideCountryCity:(void*)unused{
   if(uiCanHideCountryCityAt>getTickCount())return;
   uiCanHideCountryCityAt=0;
   
   int findCSC_C_S(const char *nr, char *szCountry, char *szCity, char *szID, int iMaxLen);
   char bufC[64],szCity[64],sz2[64];
   if(findCSC_C_S([nr text].UTF8String, &bufC[0], &szCity[0], &sz2[0],64)>0){
      char buf[4]={toupper(sz2[0]),toupper(sz2[1]),0,0};
      [countryID setText: [NSString stringWithUTF8String:&buf[0]]];
   }
   [lbNRFieldName setHidden:NO];
}

-(IBAction)onFlagClick{
   int findCSC_C_S(const char *nr, char *szCountry, char *szCity, char *szID, int iMaxLen);
   char bufC[64],szCity[64+64+4],sz2[64];
   szCity[0]=0;
   if(findCSC_C_S([nr text].UTF8String, &bufC[0], &szCity[0], &sz2[0],64)>0){
      if(szCity[0])strcat(szCity,", ");
      strcat(szCity,bufC);
      [countryID setText: [NSString stringWithUTF8String:&szCity[0]]];
      uiCanHideCountryCityAt=getTickCount()+2000;
      [self performSelector:@selector(hideCountryCity:) withObject:nil afterDelay:3];
      [lbNRFieldName setHidden:YES];
   }
   
}

-(int)checkCC_FLAG_CountryLabels{
   
   int findCSC_C_S(const char *nr, char *szCountry, char *szCity, char *szID, int iMaxLen);
   char bufC[64],szCity[64],sz2[64];
   static char prevsz2[5];
   int iOfsX=0;
   if(findCSC_C_S([nr text].UTF8String, &bufC[0], &szCity[0], &sz2[0],64)>0){
      
      char buf[4]={toupper(sz2[0]),toupper(sz2[1]),0,0};
      [countryID setText: [NSString stringWithUTF8String:&buf[0]]];
      
      
      if(strcmp(prevsz2,sz2)){
         strcpy(prevsz2,sz2);
         strcat(sz2,".png");
         UIImage *im=[UIImage imageNamed: [NSString stringWithUTF8String:&sz2[0]]];
         [nrflag setImage:im];
      }
      iOfsX = nrflag.frame.size.width+5;
      
      CGFloat actualFontSize;
      [nr.text sizeWithFont:nr.font
                minFontSize:nr.minimumFontSize
             actualFontSize:&actualFontSize
                   forWidth:nr.bounds.size.width
              lineBreakMode:UILineBreakModeTailTruncation];
      
      CGPoint c=nrflag.center;
      
      actualFontSize/=1.15f; 
      nrflag.frame=CGRectMake(nrflag.frame.origin.x,nrflag.frame.origin.y,nrflag.frame.size.width,actualFontSize);
      nrflag.center=c;
      
      [nrflagBt setHidden:NO];
      
      

   }
   else{
      [nrflagBt setHidden:YES];
      prevsz2[0]=0;
      [nrflag setImage:nil];
      [countryID setText:@""];
   }
   

   nr.frame = CGRectMake(iOfsX, nr.frame.origin.y, self.window.frame.size.width-iOfsX, nr.frame.size.height);

//   void freemem_to_log();freemem_to_log();
   return 0;   
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string   // return NO to not change text
{
   // [self numberChange];
   return YES;
}

-(IBAction)textFieldReturn:(id)sender
{
   [sender resignFirstResponder];
   [nr resignFirstResponder];
} 

#define CHECK_NAME_DELAYMS 500

-(void)tryFindName:(int*)unused{
   
   // return;
   static int iIn=0;
   if(iIn)return;
   
   if(!iMustSearch || uiNumberChangedAt+CHECK_NAME_DELAYMS>getTickCount() || iIsClearBTDown>0)return;
   iMustSearch=0;
   iIn=1;
   const char *p=[nr.text UTF8String];
   int l=nr.text.length;
   CTEditBuf<128> bOut;
   
   
   int ret=[self findName:p len:l pEng:getCurrentDOut() bOut:&bOut];
   if(ret>=0)[lbNRFieldName setText:toNSFromTB(&bOut)];else [lbNRFieldName setText:@""];
   iIn=0;
}

-(IBAction)numberChange{
   int l=nr.text.length;
   if(l==0) [nr resignFirstResponder];
   uiNumberChangedAt=getTickCount();
   iMustSearch=1;
   
   if(!l){
      [lbNRFieldName setText:@""];
   //   backspaceBT.accessibilityLabel=@"backspace";
   }
   else{
      [self performSelector:@selector(tryFindName:) withObject:nil afterDelay:((float)CHECK_NAME_DELAYMS/1000.f)+0.1f];
   }
   [self checkCC_FLAG_CountryLabels ];
   
   
}
-(int)findName:(const char*)p len:(int)len pEng:(void *)pEng bOut:(CTEditBase *)bOut{
   
   if(len>4 &&  strncmp(p,"sip:",4)==0){
      len-=4;p+=4;
   }
   if(len<1)return -1;
   
   int l=len;
   int r;
   
   CTEditBuf<128> b;
   b.setText(p,l);
   
   if(1){
      int iHasAt=0;
      for(int i=0;i<l;i++){if(p[i]=='@'){iHasAt=1;break;}}
      
      if(!iHasAt){

         int iSize=0;
         
         if(!pEng)pEng=getCurrentDOut();
         
         char *ret=(char*)findCfgItemByServiceKey(pEng, (char*)"tmpServ", iSize, NULL, NULL);
         
         if(ret){
            b.addChar('@');
            b.addText(ret);
         }
      }
   }
   
   r=[recentsController findContactByEB:&b outb:bOut];
   return r;
}



-(void)setText:(NSString *)ns{
   
   [nr setText:checkNrPatterns(ns)];
   [self numberChange];
}

-(IBAction)clearEditUP{
   iIsClearBTDown=-5;
}

-(void) clearEditRep:(int *)rep{
   
   int i=iIsClearBTDown;
   int l=[[nr text]length];
   if(l>0 && i>0){
      const char *p=[nr text].UTF8String;
      int rm=((p[l-1]==' ' || p[l-1]=='-' || p[l-1]=='(' || p[l-1]==')')?2:1);
      if(rm==2 && l>2 && p[l-1]=='(' && p[l-2]==' ')rm=3;
   
      while(rm<l && (p[l-rm-1]=='(' || p[l-rm-1]=='-' || p[l-rm-1]==' ') ){
         rm++;
      }
      if(rm>l)rm=l;
      
      NSString *n= [[nr text] substringToIndex:l - rm];
      [self setText:n];

      int v=i<3?0:(i-1);
      NSTimeInterval ti=1/(v*v*v+1.2)+.02;
      
      [self performSelector:@selector(clearEditRep:) withObject:nil afterDelay:ti];
      iIsClearBTDown++;
   }
}



-(IBAction)backgroundTouched:(id)sender
{
   [nr resignFirstResponder];
}

-(IBAction)clearEdit{
   
   iIsClearBTDown=1;
   
   [self clearEditRep:nil]; 
}


-(IBAction)pickContact{
   //  [nr 
   if([[nr text]length]>0){
      [recentsController showUnknownPersonViewControllerNS:[nr text]];
   }
   else [recentsController showPeoplePickerController];
}

-(void)updateLogTab{
   if(iExiting || objLogTab)return;
   NSString *ns=@"";
   
   for(int i=0;;i++){

      void *eng=getAccountByID(i,1);
      if(!eng)break;
      
      const char *p=sendEngMsg(eng,NULL);

      NSString *a=[NSString stringWithUTF8String:p];
      ns=[ns stringByAppendingString:a];
      ns=[ns stringByAppendingString:@"\n"];
   }
   
   const char *g_getInfo(const char *cmd);
   ns=[ns stringByAppendingString:[NSString stringWithUTF8String:g_getInfo(NULL)]];
   
   if(iLogPlus>0)
   {
      void t_read_log(int iLastNLines, void *ret, void(*fnc)(void *ret, const char *line, int iLen));
      T_Log l;
      l.ns=ns;
      t_read_log(100,&l,fnc_log);
      ns=l.ns;
      iLogPlus--;
   }
   
   if(ns && ns.length>0){
      [log performSelectorOnMainThread:@selector(setText:) withObject:ns waitUntilDone:FALSE];
   }
}

-(IBAction)refreshLog:(id)sender{
   iLogPlus=3;
   [self updateLogTab];
}

-(IBAction)pressDP_Bt_up:(id)sender{
   const char *x[]={"",":d"};
   z_main(0,2,x);   
   iDialIsPadDown=0;
}

-(IBAction)pressDP_Bt:(id)sender{
   
   iDialIsPadDown=1;
   UIButton *bt=(UIButton *)sender;
   const char *p=[[[bt titleLabel]text]  UTF8String];
   
   char buf[4];
   buf[0]=':';buf[1]='d';buf[2]=p[0];buf[3]=0;
   const char *x[]={"",&buf[0]};
   
   
   if(calls.getCallCnt()>0 && !iLoudSpkr && ![AppDelegate isAudioDevConnected])
      [self switchAR:1];
   
   z_main(0,2,x);

   NSString * ns =[[nr text] stringByAppendingString:[[bt titleLabel]text] ];
   if(p[0]=='0'){
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
         for(int i=0;iDialIsPadDown;i++){
            usleep(1000*10);
            if(i==60){
               if([[nr text] length]>0){
                  NSString *n= [[nr text] substringToIndex:[[nr text] length] - 1];
                  n=[n stringByAppendingString:@"+"];
                  [nr performSelectorOnMainThread:@selector(setText:) withObject:n waitUntilDone:TRUE];
                  [self numberChange]; 
               }
               break;
            }
         }
      });
   }
   [self setText:ns];
}

/*
 - (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPushItem:(UINavigationItem *)item{return YES;} // called to push. return NO not to.
 - (void)navigationBar:(UINavigationBar *)navigationBar didPushItem:(UINavigationItem *)item{}    // called at end of animation of push or immediately if not animated
 - (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item{return YES;}// same as push methods
 - (void)navigationBar:(UINavigationBar *)navigationBar didPopItem:(UINavigationItem *)item{}
 */
-(void)confCallN:(CTCall*)c add:(int)add{
   if(!c || c->iEnded || !c->iInUse)return;
   char buf[64];
   sprintf(&buf[0],add?"*+%u":"*-%u",c->iCallId);
   const char *x[2]={"",&buf[0]};
   z_main(0,2,x);
   c->iIsInConferece=add;
}

-(void)holdCallN:(CTCall*)c hold:(int)hold{
   if(!c || c->iEnded || !c->iInUse)return;
   char buf[64];
   sprintf(&buf[0],hold?"*h%u":"*u%u",c->iCallId);
   const char *x[2]={"",&buf[0]};
   z_main(0,2,x);
   c->iIsOnHold=hold;
}
-(void)answerCallFromVidScr:(CTCall*)c{
   if(c->iEnded || !c->iCallId || !c->iIsIncoming)return;
   c->iActive=1;
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      char buf[64];
      sprintf(&buf[0],"*a%u",c->iCallId);
      const char *x[2]={"",&buf[0]};
      z_main(0,2,x);
   });
   
}

-(void)answerCallN:(CTCall*)c{
   c->iActive=1;
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      char buf[64];
      sprintf(&buf[0],"*a%u",c->iCallId);
      const char *x[2]={"",&buf[0]};
      z_main(0,2,x);
      [self setCurCallMT:c];
      //      [self unholdAndPutOthersOnHold:c];
   } );
   [answer setHidden:YES];
   view6pad.alpha=1.0;
   [self setEndCallBT:1 wide:1];
   
}
-(IBAction)answerBT{
   [self stopRingMT];
   
   CTCall *c=calls.curCall;
   if( !c)return;
   
   [uiCallInfo setText:@"Answering"];
   [self answerCallN:c];

   
}
-(CGRect)getFullWithEndCallRect{
   CGRect r= CGRectMake(endCallBT.frame.origin.x, answer.frame.origin.y,
                        answer.frame.origin.x+answer.frame.size.width-endCallBT.frame.origin.x,
                        endCallBT.frame.size.height);
   return r;
}


-(void)checkCallMngr{
   if(iCallScreenIsVisible && callMngr){
      dispatch_async(dispatch_get_main_queue(), ^(void) {
         [self checkCallMngrMT];
      });
   }
}
-(void)checkCallMngrMT{
   
   CTMutexAutoLock a(mutexCallManeger);
   
   if(iCallScreenIsVisible && callMngr && [CallManeger isVisibleOrShowningNow]){
      [callMngr redraw];
   }
}

-(IBAction)showCallMngrClick{
   void setFlagShowningCallManeger(int f);
   setFlagShowningCallManeger(0);
   iShowCallMngr=1;
   [self showCallManeger];
   
}

-(IBAction)showCallManeger{
   
   if(iVideoScrIsVisible && vvcToRelease){
      [vvcToRelease showIncomingCallMT];
      return;
   }
   
   ZRTPInfoView *v=(ZRTPInfoView*)[second.view viewWithTag:1001]; 
   if(v){[v removeFromSuperview]; }
   
   CTMutexAutoLock a(mutexCallManeger);

   if(!iShowCallMngr){
      if(callMngr)[callMngr redraw];
      return; 
   }
   iShowCallMngr=0;
   
#ifdef T_CREATE_CALL_MNGR
   if(!callMngr){
      
      //    iIsVisible=0;
      callMngr =[[CallManeger alloc]initWithNibName:@"CallManeger" bundle:nil];
      //callMngr autor
   }
#endif
   [callMngr setCallArray:&calls];
   callMngr->appDelegate=self;
   if(callMngr.isBeingDismissed){
      [self performSelector:@selector(showCallManeger) withObject:nil afterDelay:2];
      return;
   }
   
   if([CallManeger isVisibleOrShowningNow] || callMngr.isBeingPresented){
      NSLog(@"cm %d %d",[CallManeger isVisibleOrShowningNow],callMngr.isBeingPresented);
      [callMngr redraw];
      return;
   }
   void setFlagShowningCallManeger(int f);
   setFlagShowningCallManeger(1);
   
   [[uiCallVC navigationController] pushViewController:callMngr animated:YES];
}

-(IBAction)inCallKeyPad_down:(id)sender{

   UIButton *bt=(UIButton *)sender;
   const char *p=[[[bt titleLabel]text]  UTF8String];
   char buf[4];
   char bufx[4];
   
   if(!iLoudSpkr && ![AppDelegate isAudioDevConnected])
      [self switchAR:1];
   
   buf[0]=':';buf[1]='D';buf[2]=p[0];buf[3]=0;//send dtmf
   bufx[0]=':';bufx[1]='d';bufx[2]=p[0];bufx[3]=0;//play dtmf
   const char *x[]={"",&buf[0],&bufx[0]};
   z_main(0,3,x);
}

-(IBAction)inCallKeyPad_up:(id)sender{
   // keyPadInCall 
   //stop send dtmf
}

//

-(void)showZRTPPanel:(int)anim{
   
   zrtpPanel.alpha = 1.0;
   
   if(!anim){
      [uiCallInfo setHidden:YES];
      [zrtpPanel setHidden:NO];
      return;
   }
   zrtpPanel.hidden=YES;
   infoPanel.hidden=NO;
   
   
   [UIView transitionWithView:infoPanel
                     duration:1.0
                      options:UIViewAnimationOptionTransitionFlipFromLeft//UIViewAnimationOptionTransitionCurlUp
                   animations:^{
                      uiCallInfo.hidden = YES;
                      zrtpPanel.hidden = NO;
                   }
                   completion:^(BOOL finished){
                      [uiCallInfo setHidden:YES];
                      [self setCurCallMT:calls.curCall];
                   }];
   
   
   
}

-(void)showInfoLabel:(int)anim{
   
   uiCallInfo.alpha = 1.0;
   if(!anim){
      [uiCallInfo setHidden:NO];
      [zrtpPanel setHidden:YES];
      return;
   }
   
   
   [uiCallInfo setHidden:NO];
   [zrtpPanel setHidden:YES];
   if(anim && iAnimateEndCall){
      
      [UIView animateWithDuration:1.0 
                            delay:0.0 
                          options:UIViewAnimationCurveEaseInOut 
                       animations:^ {
                          fPadView.alpha=0.0;
                       } 
                       completion:^(BOOL finished) {
                          [fPadView setHidden:YES];
                          fPadView.alpha=1.0;
                       }];
   }
   
}


-(void)animEndCallBT:(CGRect)rect img:(UIImage*)im ico:(UIImage*)ico wide:(int)wide{

   [UIView beginAnimations:@"resizeButton" context:NULL];
   CTCall *c=calls.curCall;

   [UIView setAnimationDuration:0.5];
   [UIView setAnimationTransition:UIViewAnimationTransitionNone forView:endCallBT cache:YES];
   if(ico){
      [endCallBT setImageEdgeInsets:UIEdgeInsetsMake(0, -20, 0, 0)];
   }
   if(c && c->iActive)
      [endCallBT setTitle:@"End Call" forState:UIControlStateNormal];
   
   [endCallBT setBackgroundImage:im forState:UIControlStateNormal];
   
   if(!wide)[endCallBT setImage:ico forState:UIControlStateNormal];
   if(!wide)[endCallBT setImage:ico forState:UIControlStateHighlighted];
   
   rect.origin.y=answer.frame.origin.y;
   endCallBT.frame=rect;
   
   if(wide)btHideKeypad.hidden=YES;
   if(wide)answer.hidden=YES;

   if(wide)[endCallBT setImage:ico forState:UIControlStateNormal];
   if(wide)[endCallBT setImage:ico forState:UIControlStateHighlighted];

   [UIView commitAnimations];
   
}
-(void)stopAnimEndCallWide{
   UIImage *ico=[UIImage imageNamed:@"ico_end_call.png"];
   [endCallBT setImage:ico forState:UIControlStateNormal];
   [endCallBT setImage:ico forState:UIControlStateHighlighted];
   
}

-(void)setEndCallBT:(int)animate wide:(int)wide{

   NSString *ns=@"bt_red.png";
   
   UIImage    *im_bt_red=[[UIImage imageNamed:ns] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 11, 0, 11)];
   
   
   CGRect r=wide?[self getFullWithEndCallRect]:endCallRect;
   UIImage *im=nil;
   if(wide)im=[UIImage imageNamed:@"ico_end_call.png"];
   
   CTCall *c=calls.curCall;
   
   if(!wide && c && !c->iActive && isVideoCall(c->iCallId)){
      im=[UIImage imageNamed:@"ico_camera_not.png"];
   }
   
   if(wide){
      [answer setHidden:YES];
   }
   
   if(animate){
      [self animEndCallBT:r img:im_bt_red ico:im wide:wide];
   }
   else{
      
      r.origin.y=answer.frame.origin.y;
      
      if(wide){
         [answer setHidden:YES];
         [btHideKeypad setHidden:YES];
      }
      
      endCallBT.frame=r;
      [endCallBT setBackgroundImage:im_bt_red forState:UIControlStateNormal];
      [endCallBT setImage:im forState:UIControlStateNormal];
      [endCallBT setImage:im forState:UIControlStateHighlighted];
      [endCallBT setImageEdgeInsets:UIEdgeInsetsMake(0, -20, 0, 0)];
      if(c && c->iActive)
         [endCallBT setTitle:@"End Call" forState:UIControlStateNormal];
      
      
   }
}

-(void)restoreEndCallBt{
   [self setEndCallBT:0 wide:0];
}

-(void)stopRingMT{
   void stoRingTone();stoRingTone();
   //cancelLocalNotification
   if(incomCallNotif){
      
      [[UIApplication sharedApplication] cancelLocalNotification:incomCallNotif];//cancelAllLocalNotifications];
      [incomCallNotif release];
      incomCallNotif=NULL;
   }
}

-(void)onStopCallMT{
   //TODO do this if is visible
   int cc=calls.getCallCnt();
   if(cc==0){
      [answer setHidden:YES];
      [verifySAS setHidden:YES];
      [self showInfoLabel:cc==0]; 
   }
   [self setNewCurCallMT];
   
   ZRTPInfoView *v=(ZRTPInfoView*)[second.view viewWithTag:1001]; 
   if(v){[v removeFromSuperview]; }
   
   [self stopRingMT];
}

-(void)onStopCall{
   if(calls.getCallCnt()){
      [self performSelector:@selector(onStopCallMT) withObject:nil afterDelay:1];
   }
   else [self performSelectorOnMainThread:@selector(onStopCallMT) withObject:nil waitUntilDone:NO];  
}


-(IBAction)hideCallScreen{
   if(iCallScreenIsVisible && iCanHideNow){
      iCanHideNow=0;
      
      uiCanShowModalAt=getTickCount()+1000;
      
      UIDevice *device = [UIDevice currentDevice];
      device.proximityMonitoringEnabled = NO;;
     
      CTMutexAutoLock a(mutexCallManeger);
      if(callMngr && [CallManeger isVisibleOrShowningNow]){

         [self.navigationController setNavigationBarHidden:YES animated:NO];
         [[callMngr navigationController] popViewControllerAnimated:NO];
      }
      
      if(!second.isBeingDismissed)
         [second dismissModalViewControllerAnimated:YES];
      [self restoreEndCallBt];

      if(callMngr){
         [callMngr release];
         callMngr=nil;
      }
      
      iPrevCallLouspkrMode=iLoudSpkr;
      if(calls.getCallCnt()==0){

         if(vvcToRelease && iVideoScrIsVisible){
            iVideoScrIsVisible=0;
            [vvcToRelease.navigationController popViewControllerAnimated:NO];
         }
      }      
      
      iCallScreenIsVisible=0;
   }   
   [backToCallBT setHidden:YES];
}

-(void)onEndCallMT{
   [self checkCallMngrMT];
   [self onStopCallMT];
   [self checkBattery];
}

-(void)onEndCall{
   [self performSelectorOnMainThread:@selector(onEndCallMT) withObject:nil waitUntilDone:NO];  
}


-(void)endCallN:(CTCall*)c{
   iCanHideNow=1;
   if(c)strcpy(c->bufMsg,"Call ended");
   
   if(c)c->iEnded=1;
   [self updateRecents:c];
   if(c && c==calls.curCall){[uiCallInfo setText:@""];calls.curCall=NULL;}
   [self onEndCallMT];
   if(!c)return ;
   int cid=c->iCallId;
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      char buf[64];
      sprintf(&buf[0],"*e%u",cid);
      const char *x[2];
      x[0]="";
      x[1]=&buf[0];
      z_main(0,2,x);
   });
}

-(void)endCall_cid:(int)cid{
   
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      char buf[64];
      sprintf(&buf[0],"*e%u",cid);
      const char *x[2];
      x[0]="";
      x[1]=&buf[0];
      z_main(0,2,x);
   });
}

-(IBAction)endCallBt{
   
   [self init_or_reinitDTMF];
   iAnimateEndCall=0;
   [self endCallN:calls.curCall];
}



-(IBAction)chooseCallType{

   if(nr.text.length<1){
      [self setText:[NSString stringWithUTF8String:&szLastDialed[0]]];
      return ;
   }
   
   void *ph=getCurrentDOut();
   if(ph){
      int ret;
      if(findIntByServKey(ph,"iDisableVideo",&ret)>=0){
         if(ret>0){
            [self makeCall:'c'];
            return;
         }
      }

   }
   

   UIActionSheet *as = [[UIActionSheet alloc]initWithTitle:@"" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Call", @"Video Call",nil];
   as.tag=0;
   [as showFromTabBar:uiTabBar];
   [as release];
   
}

-(void)updateLedMT{
   int g_getCap(int &iIsCN, int &iIsVoice, int &iPrevAuthFail);
   int iIsCn,iIsVoice,iPrevAuthFail;
   int v=g_getCap(iIsCn,iIsVoice,iPrevAuthFail);
   static int pv=-1;
   static int previPrevAuthFail=-1;
   float fv=(float)v*0.005f+.35f;
#if 1
   if(previPrevAuthFail!=iPrevAuthFail || pv!=v){
      if(iPrevAuthFail){
         [iwLed setBackgroundColor:[UIColor colorWithRed:fv green:0 blue:0 alpha:1.0]];
      }
      else{
         [iwLed setBackgroundColor:[UIColor colorWithRed:0 green:fv blue:0 alpha:1.0] ];
      }
      pv=v;
      previPrevAuthFail=iPrevAuthFail;
   }
#else
   if(iPrevAuthFail){
      if(previPrevAuthFail!=iPrevAuthFail){
         previPrevAuthFail=iPrevAuthFail;
         [iwLed setBackgroundColor:[UIColor colorWithRed:1.0 green:0 blue:0 alpha:1.0] ];
         pv=-1;
      }
   }
   else if(pv!=v){
      pv=v;
      [iwLed setBackgroundColor:[UIColor colorWithRed:0 green:fv blue:0 alpha:1.0] ];
      previPrevAuthFail=-1;
   }
#endif
   
   
}

-(void)updateCallDurMT{
      
   CTCall *c=calls.curCall;
   
   if(c && c->iActive && c->uiStartTime && !isZRTPInfoVisible()){
      
      if(c->iEnded==3){c->iEnded=4;[self onStopCallMT];return;}
      if(c->iEnded==2 && c->iRecentsUpdated) {c->iEnded=3;} 
      if(iVideoScrIsVisible)return;
      
      int d=c->iTmpDur;
      int m=d/60;
      int s=d-m*60;
      
      
      NSString *ns=[NSString stringWithFormat:@"%02d:%02d",m,s];
      [uiDur setText:ns];
#ifdef T_TEST_MAX_JIT_BUF_SIZE
      if(iAudioBufSizeMS){//TODO restore default 3000
         char buf[32];
         char bufms[32];
         sprintf(bufms,"bufms%d",iAudioBufSizeMS);
         int r = getMediaInfo(c->iCallId,bufms,&buf[0],31);
      }
 #endif
      
      
      if(iCanShowMediaInfo || iAudioUnderflow==1){
         char buf[64];
         int r=getMediaInfo(c->iCallId,"codecs",&buf[0],63);
         if(r<0)r=0;
#ifdef T_TEST_MAX_JIT_BUF_SIZE
         if(iAudioBufSizeMS){
            //10 = 1000 msec,25 = 2500 msec, 
            r+=snprintf(&buf[r],63-r," d%02d",iAudioBufSizeMS/100);
         }
#endif
         if(r>0)[uiMediaInfo setText:[NSString stringWithUTF8String:&buf[0]]];
      }
      
      if(1){
         char buf[32];
         strcpy(buf,"ico_antena_");
         static char cc;
         int r=getMediaInfo(c->iCallId,"bars",&buf[11],31-11);//11=strlen("ico_antena_" or buf);
         // puts(buf);
         if(r==1){
            static int iX=0;
            iX++;
            if(buf[11]!='0'){
               //TODO fix
               if(strcmp(c->bufSecureMsg,"Connecting...")==0){strcpy(c->bufSecureMsg,"");[self refreshZRTP:c];}
            }
            if((cc!=buf[11]) || (iX&7)==1){
               cc=buf[11];
               UIImage *a=[UIImage imageNamed:[NSString stringWithUTF8String:&buf[0]]];
               //[b setBackgroundImage:bti forState:UIControlStateNormal];
               [btAntena setImage:nil forState:UIControlStateNormal];
               [btAntena setImage:a forState:UIControlStateNormal];
               
            }
         }
      }
      if(!lbVolumeWarning.hidden){
         if(!isPlaybackVolumeMuted())[lbVolumeWarning setHidden:YES];
      }
      

      if(c->iZRTPShowPopup){
         c->iZRTPShowPopup=0;
         [self showZRTPErrorPopup:c];
      }

      if(0)
      {
         void freemem_to_log();
         freemem_to_log();
      }
   }
   
}

-(void)callThreadCB:(int)i{
   //TODO test audio without this   
   CTCall *c=calls.curCall;
   
   
   if(c && c->iActive && c->uiStartTime && (!iVideoScrIsVisible || c->iEnded)){
      int d=get_time()-c->uiStartTime;
      if(d!=c->iTmpDur ){
         c->iTmpDur=d;
         [self performSelectorOnMainThread:@selector(updateCallDurMT) withObject:nil waitUntilDone:FALSE];
      }
   }
}

-(void)callThreadLedCB{
   if([CallManeger isVisibleOrShowningNow] || isZRTPInfoVisible())return;
   
   CTCall *c=calls.curCall;
   
   if(c && c->iActive && c->uiStartTime && (!iVideoScrIsVisible || c->iEnded)){

         [self performSelectorOnMainThread:@selector(updateLedMT) withObject:nil waitUntilDone:FALSE];
      
   }
}

#define T_ALERT_TF_NEW

-(void)showExetendedZRTPWarnPopup:(CTCall *)c{

   CTEditBuf<1024> b;
   CTEditBuf<1024> bDescr;
   translateZRTP_errMsg(c->zrtpWarning, &b, &bDescr);
   
   NSString *ns=toNSFromTB(&b);
   ns=[ns stringByAppendingString:@"\n\nDescription:\n"];
   ns=[ns stringByAppendingString:toNSFromTB(&bDescr)];
   
   if(c->zrtpWarning.getLen()>8 && c->zrtpWarning.getChar(0)=='s' && c->zrtpWarning.getChar(7)==':'){
      NSString *toNSFromTBN(CTStrBase *b, int N);
     // ns=[ns stringByAppendingString:@"\n\nError code: "];
      ns=[ns stringByAppendingString:@"\n\n"];
//      ns=[ns stringByAppendingString:toNSFromTBN(&c->zrtpWarning, 7)];
      ns=[ns stringByAppendingString:toNSFromTB(&c->zrtpWarning)];
   }
   
   UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Security Warning"
                                                message:ns
                                               delegate:nil
                                      cancelButtonTitle:@"Ok"
                                      otherButtonTitles:nil];
   [av show];
   [av release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
   NSLog(@"alertView %d %d",buttonIndex, alertView.tag);
   
   if(alertView.tag &&  alertView.tag==(int)alertView){
      CTCall *c=calls.curCall;
      if(c && buttonIndex!=alertView.cancelButtonIndex){
         [self showExetendedZRTPWarnPopup:c];
      }
      return;
   }
   
#if defined(T_ALERT_TF_NEW)
   if(alertView.tag!=3 || buttonIndex==alertView.cancelButtonIndex)return;
   UITextField *tf=[alertView textFieldAtIndex:0];
#else
   if(buttonIndex==alertView.cancelButtonIndex)return;
   UITextField *tf=(UITextField*)alertView.tag;
#endif
   if(!tf)return;
   CTCall *c=calls.curCall;
   
   if(c){
      if([tf.text length]>0){
         [verifySAS setHidden:YES];
         c->iShowVerifySas=0;
         const char *p=[tf.text UTF8String];
         c->zrtpPEER.setText(p);
         
         c->iShowWarningForNSec=0;
         c->zrtpWarning.reset();
         
         char buf[128];
         snprintf(buf,127,"*z%u %s",c->iCallId,p);
         const char *x[]={"",&buf[0]};
         z_main(0,2,x);
         [self refreshZRTP:c];
         
         if(iSASConfirmClickCount){
            iSASConfirmClickCount[0]++;
            if(iSASConfirmClickCount[0]<T_SAS_NOVICE_LIMIT*2){
               void t_save_glob();
               t_save_glob();
            }
         }
      }
   }
   
}


-(void)showZRTPErrorPopup:(CTCall *)c{
   if(!c || c->iEnded || !c->iInUse)return;
   if(c->iZRTPPopupsShowed>1 || [CallManeger isVisibleOrShowningNow])return;
   
   int iSDES=0;
   
   if(c->zrtpWarning.getLen()>8){
      
      CTStr zrtpCode((unsigned short*)c->zrtpWarning.getText(), 8);
      
      if (zrtpCode=="s2_c007:" || zrtpCode=="s2_c051:")
         return;
      
      iSDES = isSDESSecure(c->iCallId, 0);
      
   }
   
   c->iZRTPPopupsShowed++;//should i reset this flag when it is secure
  
   CTEditBuf<1024> b;
   CTEditBuf<1024> bDescr;
   translateZRTP_errMsg(c->zrtpWarning, &b, &bDescr);
   
 //  UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"ZRTP error description"
   //                                             message:toNSFromTB(&b)
   
   avZRTPWarning = [[UIAlertView alloc] initWithTitle: @"Security Warning"
                                                   message:toNSFromTB(&b)
                                                  delegate:self
                                         cancelButtonTitle:@"Ok"
                                         otherButtonTitles:nil];
   if(bDescr.getLen()){
      [avZRTPWarning addButtonWithTitle:@"Details"];
   }
   avZRTPWarning.tag=(int)avZRTPWarning;
   /*
    [alertView setTitle:@"new title"];
    [alertView setMessage:@"new message"];
    */
   [avZRTPWarning show];
   [avZRTPWarning release];
}

-(IBAction)showSasPopupText{
   CTCall *c=calls.curCall;
   if(!c)return;
   
   NSString *e32=@"You should verbally compare the authentication code with your partner.  If it doesn't match, it indicates the presence of a wiretapper.";
   
      
 //  NSString *eW=@"You should verbally compare these authentication words with your partner.  If it doesn't match, it indicates the presence of a wiretapper.";

   
   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"How to detect a wiretapper"
                                                   message:e32//c->bufSAS[4]==0?e32:eW
                                                  delegate:nil
                                         cancelButtonTitle:@"Dismiss"
                                         otherButtonTitles:nil];
   [alert show];
   [alert release];
   
}

-(IBAction)showSecureView{
   CTCall *c=calls.curCall;
   int cid=c?c->iCallId:0;
   if(!cid)return;
   
   if(c->iShowVerifySas && iCanShowSAS_verify==0 && c->zrtpPEER.getLen()==0){
      iCanShowSAS_verify=1;
      [self updateZRTP_infoMT:c];
      return ;
   }
   
   NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:@"ZRTP_info"
                                                   owner:self options:nil];
   ZRTPInfoView *v=NULL;
   for (id object in bundle) {
      if ([object isKindOfClass:[ZRTPInfoView class]])
         v = (ZRTPInfoView *)object;
   }   
   
   if(!v)return;
   
   [v onReRead:cid pEng:c->pEng peer:&c->zrtpPEER sas:&c->bufSAS[0]];
   v.center=second.view.center;
   [second.view addSubview: v];
   
   v.tag=1001;
   

}
-(IBAction)onAntenaClick:(id)sender{
   iCanShowMediaInfo=!iCanShowMediaInfo;
   [uiMediaInfo setHidden:!iCanShowMediaInfo];
#ifdef T_TEST_MAX_JIT_BUF_SIZE
   if(iCanShowMediaInfo){
      iAudioBufSizeMS+=800;
      if(iAudioBufSizeMS>=3500)iAudioBufSizeMS=500;

   }
#endif
   
   
}

-(IBAction)switchView:(id)sender{
}

-(IBAction)showInCallKeyPad:(id)sender{
   // keyPadInCall 
   
   keyPadInCall.hidden=YES;
   [self setEndCallBT:1 wide:0];
   [UIView transitionWithView:viewCSMiddle
                     duration:1.0
                      options:UIViewAnimationOptionTransitionFlipFromLeft//UIViewAnimationOptionTransitionCurlUp
                   animations:^{
                      infoPanel.hidden=YES;//new
                      view6pad.hidden = YES;
                      keyPadInCall.hidden = NO;
                   }
                   completion:^(BOOL finished){
                      [infoPanel setHidden:YES];//new
                      [view6pad setHidden:YES];
                      [keyPadInCall setHidden:NO];
                      [btHideKeypad setHidden:NO];
                   }];
}

-(void)showInCall6Pad{
   // keyPadInCall 
   CTCall *c=calls.curCall;
   if(c && c->mustShowAnswerBT()){
      [answer setHidden:NO];
      [self setEndCallBT:0 wide:0];
   }
   else
      [self setEndCallBT:1 wide:1];
   
   
   [UIView transitionWithView:viewCSMiddle
                     duration:1.0
                      options:UIViewAnimationOptionTransitionFlipFromLeft//UIViewAnimationOptionTransitionCurlUp
                   animations:^{
                      infoPanel.hidden=NO;//new
                      view6pad.hidden = NO;
                      keyPadInCall.hidden = YES;
                      btHideKeypad.hidden=YES;
                   }
                   completion:^(BOOL finished){
                      [infoPanel setHidden:NO];
                      [view6pad setHidden:NO];
                      [keyPadInCall setHidden:YES];
                      [btHideKeypad setHidden:YES];
                   }];
}


-(IBAction)hideKeypad:(id)sender{
   [btHideKeypad setHidden:YES];
   [self showInCall6Pad]; 
   
}

-(IBAction)switchToVideo:(id)sender{
   [self showVideoScr:1 call:calls.curCall];
}

-(void) checkMedia:(CTCall*)c charp:(const char*)charp intv:(int)intv{
   if(!c)return;
   
   int iIsAudio=intv==5 && strncmp(charp,"audio",5)==0;

   c->iIsVideo=!iIsAudio;
   
   if(c!=calls.curCall && !c->iIsInConferece)return;
   
   if(iIsAudio){
      if(vvcToRelease && iVideoScrIsVisible){
         if(!calls.videoCallsActive(c)){
            dispatch_async(dispatch_get_main_queue(), ^(void) {
               if(!vvcToRelease.isBeingDismissed && iVideoScrIsVisible){
                  iVideoScrIsVisible=0;
                  [vvcToRelease.navigationController popViewControllerAnimated:YES];
               }
            });
         }
      }
   }
   else if(!iVideoScrIsVisible){
      dispatch_async(dispatch_get_main_queue(), ^(void) {
         [self showVideoScr:0 call:c];
      });      
   }
}

-(void)showProvScreen{
   
   Prov *p =[[Prov alloc]initWithNibName:@"Prov" bundle:nil];
   p->_provResponce=self;
   [recentsController presentModalViewController:p animated:NO];
   [p release];
}

-(void)checkProvValues{

   int iHideCfg=-1;
   findIntByServKey(NULL,"iHideCfg",&iHideCfg);
   if(iHideCfg==1){
      
      iCfgOn=0;
      [cfgBT setHidden:1];
   }
   else {
      iCfgOn=1;
      [cfgBT setHidden:0];
   }
   
}

-(void)onProvResponce:(int)ok{
   if(ok){
      
      void t_init_glob();
      t_init_glob();
      [self checkProvValues];
      
      const char *xr[]={"",":reg",":onka",":onforeground"};//
      int z_main_init(int argc, const char* argv[]);
      z_main_init(4,xr);
      
      setPhoneCB(&fncCBRet,self);
   }
}

-(void)showVideoScr:(int)iCanSend call:(CTCall*)c{
   
   //CTCall *c=calls.curCall;
   if(!c)c=calls.curCall;
   if(!c)return;
   
   if( (!c->bufSAS[0] || c->iShowVerifySas) || iVideoScrIsVisible)return;
   iVideoScrIsVisible=1;
   
   if(![AppDelegate isAudioDevConnected])
      [self switchAR:1];
   
   
   VideoViewController *vvc;

   vvc =[[VideoViewController alloc]initWithNibName:@"VideoViewController" bundle:nil];
   
   [[uiCallVC navigationController] pushViewController:vvc animated:YES];
   [vvc setCall:c canAutoStart:iCanSend iVideoScrIsVisible:&iVideoScrIsVisible a:self];
   
   if(vvcToRelease){
      [vvcToRelease release];
   }
   vvcToRelease=vvc;
}

-(IBAction)switchAddCall:(id)sender{
   
   iCanHideNow=1;
   [self hideCallScreen];
   iCanHideNow=0;
   [backToCallBT setHidden:NO];
   
}

-(IBAction)switchMute:(id)sender{
 
   [self muteMic:-1];
   
}

-(void)muteMic:(int)s{
   UIButton *b=muteBT;
   static int prev=5; 
   if(s==-1){s=!prev;}
   if(s){
      UIImage *bti=[UIImage imageNamed:@"fpad_bt_1_down.png"];
      [b setBackgroundImage:bti forState:UIControlStateNormal];
      const char *x[]={"",":mute 1"};
      z_main(0,2,x);
      iOnMute=1;
   }
   else{
      [b setBackgroundImage:nil forState:UIControlStateNormal];
      const char *x[]={"",":mute 0"};
      z_main(0,2,x);
      iOnMute=0;
   }  
   prev=s;
}

-(void)checkVolumeWarning{
   
   [lbVolumeWarning setHidden:isPlaybackVolumeMuted()?NO:YES];
}

-(void)switchAR:(int)loud{
   [self _switchAR:loud];
   if(isPlaybackVolumeMuted())[lbVolumeWarning setHidden:NO];
}

-(void)_switchAR:(int)loud{
   
   UIButton *b=switchSpktBt;
   int setAudioRoute(int iLoudSpkr);
   int  ret=setAudioRoute(loud);
   if(ret<0){
      if(ret==-560557673){
        ret=setAudioRoute(!loud);
         NSLog(@"try fix setAudioRoute()== %d %c%c%c%c" ,ret,(-ret)&0xff,((-ret)>>8)&0xff,((-ret)>>16)&0xff,((-ret)>>24)&0xff);
      }
      if(ret<0){
         NSString *ns=[NSString stringWithFormat:@"ret %d %c%c%c%c" ,ret,(-ret)&0xff,((-ret)>>8)&0xff,((-ret)>>16)&0xff,((-ret)>>24)&0xff];
         [uiCallInfo setText:ns];
      }
   }
   static int iPrev=-1;
   iLoudSpkr=ret;
   if(iPrev==ret)return;
   iPrev=iLoudSpkr;
   if(ret){
      UIImage *bti=[UIImage imageNamed:@"fpad_bt_3_down.png"];
      [b setBackgroundImage:bti forState:UIControlStateNormal];
   }
   else{
      [b setBackgroundImage:nil forState:UIControlStateNormal];
   }
   
   
}

-(IBAction)switchSpkr:(id)sender{
   iLoudSpkr=!iLoudSpkr;
   [self switchAR:iLoudSpkr];
}


-(int)callScrVisible{return  iCallScreenIsVisible;}

-(void)dontAllowCurCallChangeUntilVerifySas{
   NSLog(@"dontAllowCurCallChangeUntilVerifySas");;
   
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
   
   NSLog(@"actionSheet %d",buttonIndex);
   
   if([actionSheet cancelButtonIndex]==buttonIndex)return;

   if(actionSheet.tag){
      
      int iAccId=accountIdByIndex[buttonIndex];
      
      void *p=getAccountByID(iAccId,1);
      if(p){
         setCurrentDOut(iAccId,getAccountTitle(p));
         [self setAccountTitle:p];
      }
      
      return;
   }
   
   [self makeCall:(buttonIndex==0?'c':'v')];
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet{ }

-(void)setAccountTitle:(void*)eng{
   
   if(eng==NULL)eng=getCurrentDOut();
   if(!eng){
      [curServiceLB setText:@"!"];
      return;
   }
   
   const char *p=sendEngMsg(eng,"isON");
   
   int ok=(p && strcmp(p,"yes")==0);
   int not_ok=!ok && (!p || strcmp(p,"no")==0);
   
#define RED_MSG_AND_ERR_LIMIT_SEC 10
   
   int secSinceAppStarted();
   UIColor *col=ok?[UIColor greenColor]:((not_ok &&  secSinceAppStarted()>RED_MSG_AND_ERR_LIMIT_SEC)?[UIColor redColor]:[UIColor grayColor]);
   
   const char *all_on=sendEngMsg(NULL,"all_online");
   
   int iAllOn=all_on && strcmp(all_on,"true")==0;
   
   char bufInfo[1024]; bufInfo[0]=0;
   
   if(not_ok){
      p=sendEngMsg(eng,"regErr");
      if(p && p[0]){
         strcpy(bufInfo,p);
      }
   }
   else {
      strcpy(bufInfo,getAccountTitle(eng));
   }
   
   if(!iAllOn && secSinceAppStarted()>RED_MSG_AND_ERR_LIMIT_SEC){
      strcat(bufInfo," !");
   }

   [curServiceLB setText:[NSString stringWithUTF8String:&bufInfo[0]]];
   
   [curServiceLB setTextColor:col];
}

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet {
   
   if(actionSheet.tag==0)return;
   
   UIButton *bt=[[actionSheet valueForKey:@"_buttons"] objectAtIndex:actionSheet.tag-1];
   if(bt)
      [bt setImage:[UIImage imageNamed:@"ico_call_out2.png"] forState:UIControlStateNormal];

}

-(IBAction)showSelectAccount{
   int iAccounts=2;//TODO getRealCnt
   void *pp[20];
   for(int i=0;i<20;i++){
      pp[i]=getAccountByID(i,1);
      if(pp[i])iAccounts++;else break;
   }
   if(iAccounts<2){
      if(iAccounts==1){
         setCurrentDOut(0,getAccountTitle(pp[0]));
         [self setAccountTitle:pp[0]];
      }
      return;
   }
   
   //http://stackoverflow.com/questions/6130475/adding-images-to-uiactionsheet-buttons-as-in-uidocumentinteractioncontroller
   
   UIActionSheet *as = [[UIActionSheet alloc]initWithTitle:@"Select Account" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
   // [as 
   // as
   int iCurSel=0;
   
   char prevLabel[96];
   char curLabel[96];
   int n=0;
   
   void *pcdo=getCurrentDOut();
   
   for(int i=0;i<iAccounts;i++){
      if(pp[i]){
         
         const char *p=sendEngMsg(pp[i],"name");

         char* findSZByServKey(void *pEng, const char *key);
         char* pNr=findSZByServKey(pp[i], "nr");
         
         char bufz[5];bufz[0]=0;
         if(!pNr)pNr=&bufz[0];
         if(!pNr[0])pNr=findSZByServKey(pp[i], "un");
         if(!pNr)pNr=&bufz[0];
         
         const char *p2=sendEngMsg(pp[i],"isON");
         int iIsOn=p2 && strcmp(p2,"yes")==0;
         
         NSString *ns;

         if(iIsOn)
            ns=[NSString stringWithFormat:@"%s %s \U0001F30D",p,pNr];
         else
            ns=[NSString stringWithFormat:@"%s %s \U0001F4F5",p,pNr];
         
         
         snprintf(&curLabel[0],95,"%s%s",p,pNr);
         if(i && strcmp(prevLabel,curLabel)==0)
            continue;//will not show redundant account
         strcpy(prevLabel,curLabel);
         
         accountIdByIndex[[as addButtonWithTitle:ns]]=i;
         
         if(pp[i]==pcdo){
            iCurSel=n;
         }
         n++;
      }
      else break;
   }
   int ii=[as addButtonWithTitle:@"Cancel"];
   [as setCancelButtonIndex:ii];
   
   as.tag=1+iCurSel;
   [as showFromTabBar:uiTabBar];
   [as release];
}

-(IBAction)askZRTP_cache_name_top{
   CTCall *c=calls.curCall;
   if(!c)return;
   if(!c->zrtpPEER.getLen())return;
   int match = c->nameFromAB==&c->zrtpPEER;
   if(!match)return;
   if(!btChangePN.isHidden)return;
   
   [self askZRTP_cache_name_f:0];
}

-(IBAction)askZRTP_cache_name{
   CTCall *c=calls.curCall;
   if(!c)return;
   
   int iUseNameFromPB=0;
   
   if(c->nameFromAB.getLen() && !(c->nameFromAB==&c->zrtpPEER))
   {
      iUseNameFromPB = c->sipDispalyNameEquals(c->zrtpPEER);
   }
   
   [self askZRTP_cache_name_f:iUseNameFromPB];
}

-(void)askZRTP_cache_name_f:(int)iUseNameFromPB{

   CTCall *c=calls.curCall;
   
   if(c && c->iShowEnroll){
      [verifySAS setHidden:YES];
      c->iShowEnroll=0;
      c->iShowVerifySas=0;
      char buf[32];
      sprintf(&buf[0],"*t%u",c->iCallId);
      const char *x[2]={"",&buf[0]};
      z_main(0,2,x);
      [self refreshZRTP:c];
      return;
   }
   
   if(!c)return ;
   
   [self dontAllowCurCallChangeUntilVerifySas];
   //TODO if sev
   NSString *ns=[NSString stringWithFormat:@"Compare with partner:\n\"%s\"\n\nEnter partner's name here",&c->bufSAS[0]];
   
   UIAlertView *dialog = [[UIAlertView alloc] initWithTitle:ns
                                                    message:@" \n " 
                                                   delegate:self 
                                          cancelButtonTitle:@"Later" 
                                          otherButtonTitles:@"Confirm",nil];
   
   
   
#if defined(T_ALERT_TF_NEW)

   dialog.alertViewStyle = UIAlertViewStylePlainTextInput;dialog.tag=3;[dialog becomeFirstResponder];
   UITextField *tf=[dialog textFieldAtIndex:0];
   tf.autocorrectionType=UITextAutocorrectionTypeYes;
   tf.autocapitalizationType=UITextAutocapitalizationTypeWords;
   if(tf){
      CTEditBase *e=&c->zrtpPEER;
      if(iUseNameFromPB){
         e=&c->nameFromAB;
      }
      else if(!e->getLen() && c->nameFromAB.getLen()){
         int v;
         if(::getCallInfo(c->iCallId,"media.zrtp.nomitm",&v)==0 && v==1){
            e=&c->nameFromAB;
         }
      }
      tf.text=toNSFromTB(e);
      [tf setTextAlignment:UITextAlignmentCenter];
   }
   
   [dialog show];
   [dialog release];
#else
   
   //textFieldAtIndex
   UITextField *nameField = [[UITextField alloc] initWithFrame:CGRectMake(20.0, 50.0+45.0, 245.0, 28.0)];
   [nameField setBackgroundColor:[UIColor whiteColor]];
   
   nameField.text=toNSFromTB(&c->zrtpPEER);
   [nameField setTextAlignment:UITextAlignmentCenter];
   
   [dialog addSubview:nameField];
   //CGAffineTransform moveUp = CGAffineTransformMakeTranslation(0.0, 100.0);
   // [dialog setTransform: moveUp];
   dialog.tag=(int)nameField;
   
   [dialog show];
   [dialog release];
   
   [nameField becomeFirstResponder];
   
   [nameField release];
#endif
}
-(void)showVerifyBT{
   
   if(!verifySAS.isHidden)return;
   
   CGRect originalFrame = verifySAS.frame;
   verifySAS.frame = CGRectMake(originalFrame.origin.x, originalFrame.origin.y
                                , originalFrame.size.width, 1);
   [verifySAS setHidden:NO];
   
   [UIView animateWithDuration:0.5 animations:^{verifySAS.frame = originalFrame;}];
   
}

-(void)refreshZRTP:(CTCall *)c{

   if(c && c==calls.curCall && c->iInUse && c->pEng && !c->iEnded){
      dispatch_async(dispatch_get_main_queue(), ^(void) {
         [self updateZRTP_infoMT:c];
         if(!c->iActive && !c->iEnded && zrtpPanel.isHidden){
            [self showZRTPPanel:1];
            if(strncmp(c->bufMsg,"Ringing",7)==0){//??????
               NSString *ci=[NSString stringWithUTF8String:&c->bufMsg[0]];
               [uiDur setText:ci];
            }
         }
         
      });
      
   }
}

-(int)selfCheck_comp_calls{

   return 0;
}

-(void)engCB{
   
   if(iIsInBackGround)return;
   [self updateLogTab];
}

@end

class CRESET_SEC_STEATE{
public:
   CRESET_SEC_STEATE(void *ret, void *ph, int iCallID, int iIsVideo, CTCall *c)
   :ret(ret),ph(ph),iCallID(iCallID),iIsVideo(iIsVideo),c(c){
   }
   void *ret;
   void *ph;
   int iCallID;
   int iIsVideo;
   CTCall *c;
};

void checkSDES(CTCall *c, void *ret, void *ph, int iCallID, int msgid){
   if(!c || c->iEnded)return ;
   
   int iSDESSecure=0;
   int iErr=0;
   int iVideo=0;
  
   switch(msgid){
      case CT_cb_msg::eZRTPErrA: iSDESSecure=::isSDESSecure(iCallID, 0);iErr=1;break;
      case CT_cb_msg::eZRTPErrV: iSDESSecure=::isSDESSecure(iCallID, 1);iErr=1;iVideo=1;break;
      case CT_cb_msg::eZRTPMsgV: iVideo=1;
      case CT_cb_msg::eZRTPMsgA:
         if(strcmp(iVideo? c->bufSecureMsgV :c->bufSecureMsg,"ZRTP Error")==0)
            iErr=1;
         
         if(!iErr)return ;
         
         iSDESSecure=::isSDESSecure(iCallID, iVideo);
         
         break;
         
      default:
         return;
   }
   if(!iSDESSecure)return ;
   
   if(c->iReplaceSecMessage[iVideo])return;
   c->iReplaceSecMessage[iVideo]=1;
   
   CRESET_SEC_STEATE *rs = new CRESET_SEC_STEATE(ret,ph,iCallID, iVideo,c);
   
   void startThX(int (cbFnc)(void *p),void *data);
   int resetSecStateTH(void *p);
   startThX(resetSecStateTH, rs);

   return ;
}

int resetSecStateTH(void *p){
   
   CRESET_SEC_STEATE *rs = (CRESET_SEC_STEATE*)p;
   for(int i=0;i<5;i++){
      sleep(1);
      if(!rs || !rs->c || rs->c->iEnded || rs->c->iCallId!=rs->iCallID)return 0;
   }
   
   int iSDESSecure=::isSDESSecure(rs->iCallID, rs->iIsVideo);
   if(!iSDESSecure)return 0;
   
   fncCBRet(rs->ret, rs->ph, rs->iCallID,
            rs->iIsVideo? CT_cb_msg::eZRTPMsgV : CT_cb_msg::eZRTPMsgA,
            "SECURE SDES", 0);
   return 0;
}


#pragma mark - engine callback

int fncCBRet(void *ret, void *ph, int iCallID, int msgid, const char *psz, int iSZLen){

   
   AppDelegate *s=(AppDelegate*)ret;
   
   if(!s || s->iExiting)return 0;
   
   CTCall *c=[s findCallById:iCallID];
   CTCall *pc=s->calls.curCall;
   
   //isSDESSecure
   
   int iLen=0;
   const char *p="";
   {
      
      switch(msgid){
         case CT_cb_msg::eNewMedia:
            [s checkMedia:c charp:psz intv:iSZLen];
            break;
         case CT_cb_msg::eEnrroll:
            if(!c)break;
            c->iShowVerifySas=0;
            c->iShowEnroll=1;
            [s refreshZRTP:c];
            
            break;
         case CT_cb_msg::eZRTP_peer_not_verifed:
            if(!c)break;
            c->iShowVerifySas=1;
            if(psz)
               c->zrtpPEER.setText(psz);
            [s refreshZRTP:c];
            
            //[s performSelectorOnMainThread:@selector(showVerifyBT) withObject:nil waitUntilDone:FALSE];
            //if name set peer name
            break;
         case CT_cb_msg::eZRTP_peer:
            if(!c)break;
            if(!psz){
               c->iShowVerifySas=1;
            }
            else{
               c->zrtpPEER.setText(psz);
            }
            [s refreshZRTP:c];
            break;
         case CT_cb_msg::eZRTPMsgV:
            if(!c)break;
            if(psz)strcpy(c->bufSecureMsgV,psz);
            [s refreshZRTP:c];
            break;
         case CT_cb_msg::eZRTPMsgA:
            if(!c)break;
            if(psz)strcpy(c->bufSecureMsg,psz);
            [s refreshZRTP:c];
            break;
         case CT_cb_msg::eZRTPErrV:
            if(!c)break;
            strcpy(c->bufSecureMsgV,"ZRTP Error");
            c->iIsZRTPError=2;
            if(psz){
               c->zrtpWarning.setText(psz);
               c->iZRTPShowPopup=2;
            }
            [s refreshZRTP:c];
            break;
         case CT_cb_msg::eZRTPErrA:
            if(!c)break;
            strcpy(c->bufSecureMsg,"ZRTP Error");
            c->iIsZRTPError=1;
            
         case CT_cb_msg::eZRTPWarn:
            if(!c)break;
            if(psz){
               printf("[w=%s]",psz);
               c->zrtpWarning.setText(psz);
               c->iZRTPShowPopup=1;
            }
            [s refreshZRTP:c];
            break;
         case CT_cb_msg::eZRTP_sas:
            if(!c)break;
            if(psz)strcpy(c->bufSAS,psz);
            [s refreshZRTP:c];
            break;
         case CT_cb_msg::eSIPMsg:
            p=psz;
            iLen=iSZLen;
            break;
            
         case CT_cb_msg::eRinging:p="Ringing";break;
         case CT_cb_msg::eCalling:
            p="Calling...";
            s->iCanShowSAS_verify=0;
            c=s->calls.curCall;
            if(!c)break;
            c->pEng=ph;
            c->iCallId=iCallID;
            c->setPeerName(psz, iSZLen);
            
            break;
         case CT_cb_msg::eEndCall:
            if(!c || !c->iSipHasErrorMessage)p="Call ended";
            if(!c)break;
            if(!c->iEnded){
               c->iEnded=2;
               void vibrateOnce();vibrateOnce();
            }
            [s updateRecents:c];
            [s onStopCall];
            
            
            break;
         case CT_cb_msg::eStartCall:
            if(c){
               
               if(!c->bufSecureMsg[0]){strcpy(c->bufSecureMsg,"Connecting...");[s refreshZRTP:c];}
               p=" ";//Call is active";
               c->iActive=2;
               if(!c->uiStartTime)c->uiStartTime=(unsigned int)get_time();
               if(c==s->calls.curCall){
                  dispatch_async(dispatch_get_main_queue(), ^(void) {
                     [s showZRTPPanel:1];
                     [s checkCallMngrMT];
                  });
               }
               else 
               {
                  [s checkCallMngr];
               }
               if(s->iCallScreenIsVisible){
                  void checkThread(AppDelegate *s);checkThread(s);
               }
               
            }
            break;
         case CT_cb_msg::eError:
         {
            if(s->calls.curCall && !s->calls.curCall->iCallId){
               c=s->calls.curCall;
               p=psz;
            }
            else if(psz && c)p=psz;
            else{
               
               p=sendEngMsg(ph,NULL);
            }
            if(c)c->iSipHasErrorMessage=1;
            //if(curCall->)
         }
      }
      
      checkSDES(c, ret,ph,iCallID,msgid);
      
      if(msgid==CT_cb_msg::eIncomCall){
         s->iCanShowSAS_verify=0;
         c=[s getEmptyCall:0];
         if(!c){
            //TODO add missedCall
            [s endCall_cid:iCallID];
            return 0;
         }
         int vc=isVideoCall(iCallID);
         if(vc)p="Incoming Video Call";else p="Incoming call";
         
         c->pEng=ph;
         c->iCallId=iCallID;
         c->iIsIncoming=1;
         c->iShowVideoSrcWhenAudioIsSecure=vc;
         c->setPeerName(psz, iSZLen);
         
         dispatch_async(dispatch_get_main_queue(), ^(void) {
            [s incomingCall:c];
            
         });
         
      }
      

      
      if(p && p[0] && c){
         NSString *ns=NULL;
         
         if(iLen<1)iLen=strlen(p);
         if(iLen>=sizeof(c->bufMsg))iLen=sizeof(c->bufMsg)-1;
         
         strncpy(c->bufMsg,p,iLen);
         c->bufMsg[iLen]=0;
         if(c->bufMsg[0]<' ')c->bufMsg[0]=' ';
         if(c->bufMsg[1]<' ')c->bufMsg[1]=' ';
         ns=[[NSString alloc]initWithUTF8String:&c->bufMsg[0]];
         
         
         if((c && pc==c) || s->calls.getCallCnt()==0)
            [s->uiCallInfo performSelectorOnMainThread:@selector(setText:) withObject:ns waitUntilDone:FALSE];
         [ns release];
         
         NSLog(@"msg=:[%.*s]:",iLen,p);
         
      }
   }
   if(!s->iIsInBackGround && c)[s checkCallMngr];//TODO else resync cm
   
   if(!c && msgid!=CT_cb_msg::eReg && msgid!=CT_cb_msg::eEndCall){
      //endCall
   }
   
   [s engCB];
   
   if(!c && !s->iIsInBackGround){
      if(msgid==CT_cb_msg::eReg || msgid==CT_cb_msg::eError )
         [s performSelectorOnMainThread:@selector(setAccountTitle:) withObject:nil waitUntilDone:FALSE]; 
   }
   else{
      //TODO check updateScreen Thread
   }
   
   NSLog(@"msg %d ",msgid);
   void freemem_to_log();
   freemem_to_log();
   return 0;
}

int isAudioDevConnected(){
   return [AppDelegate isAudioDevConnected];
}

#pragma mark - config

NSString *toNS(char *p);

static const int translateType[]={CTSettingsCell::eUnknown,CTSettingsCell::eOnOff,CTSettingsCell::eEditBox,CTSettingsCell::eInt,CTSettingsCell::eInt, CTSettingsCell::eSecure,CTSettingsCell::eUnknown};

static const int translateTypeInt[]={-1,1,0,1,1,0,-1,-1};

void startThX(int (cbFnc)(void *p),void *data);
typedef struct{
   CTList *l;
   AppDelegate *s;
}_saveCfgFromListTh;

int saveCfgFromListTh(void *p){
   _saveCfgFromListTh *ptr=(_saveCfgFromListTh*)p;
   CTList *l=ptr->l;
   AppDelegate *s=ptr->s;

   {
      const char *xu[]={"",":beforeCfgUpdate",":waitOffline"};
      z_main(0,3,xu);
   }
   
   usleep(100*1000);
   
   CTSettingsItem *i=(CTSettingsItem*)l->getNext();
   while(i){
      i->save(NULL);
      i=(CTSettingsItem*)l->getNext(i);
   }
   l->removeAll();
   usleep(100*1000);
   
   void t_save_glob();//TODO if title change save
   t_save_glob();
   
   [s checkBattery];
   
   const char *xr[]={"",":afterCfgUpdate"};
   z_main(0,2,xr);
   delete ptr;

   return 0;
}

void saveCfgFromList(CTList *l, AppDelegate *s){
   _saveCfgFromListTh *p=new _saveCfgFromListTh;
   p->l=l;
   p->s=s;
   startThX(saveCfgFromListTh,p);
}


void setValueByKey(CTSettingsCell *sc, const char *key, NSString *label){
   
   char *opt=NULL;
   int iType;
   int iSize;
   
   {
      char bufTmp[32];
      int iKeyLen=strlen(key);
      void *ret=findCfgItemByServiceKey(pCurService, (char*)key, iSize, &opt, &iType);
      
      /*
       printf("[key=%s %p sz%d t=%d ",key,ret,iSize,iType);
       if(ret){
       if(iType==1 || iType==3)printf("v=%d",*(int*)ret);
       if(iType==2)printf("v=%s",ret);
       }
       printf("]\n");
       */
      bufTmp[0]=0;
      
      if(ret){
         
         sc->iType=translateType[iType];
         sc->iPhoneEngineType=iType;;
         sc->iIsInt=translateTypeInt[iType];
         
         if(opt)strcpy(sc->bufOptions,opt);
         if(sc->iType==CTSettingsCell::eInt || sc->iType==CTSettingsCell::eOnOff){
            sprintf(bufTmp,"%d",*(int*)ret);
            ret=&bufTmp[0];
         }
         if(sc->bufOptions[0]){
            sc->iType=CTSettingsCell::eChoose;
            
         }
         //TODO setflag //release on destroy
         if(sc->value)[sc->value release];
         sc->value=[[NSString alloc]initWithUTF8String:(const char *)ret];
         //      sc->value=[NSString stringWithUTF8String:(const char *)ret];
      }
     
      //  else sc->value=nil;
      
      sc->label=label;
      strcpy(sc->key,key);
      sc->iKeyLen=iKeyLen;
      sc->pCfg=pCurCfg;
      sc->pEng=pCurService;
   }
   
}

CTList * addSection(CTList *l, NSString *hdr, NSString *footer, const char *key=NULL){
   if(!l)return NULL;
   CTSettingsItem *i=new CTSettingsItem(l);
   l->addToTail(i);
   l=i->initSection(hdr);
   if(key){
      strcpy(i->sc.key,key);
      i->sc.iKeyLen=strlen(key);
   }
   i->sc.pCfg=pCurCfg;
   i->sc.pEng=pCurService;
   return l;
}

CTList * addNewLevel(CTList *l, NSString *lev, int iIsCodec=0){
   if(!l)return NULL;
   CTSettingsItem *i=new CTSettingsItem(l);
   l->addToTail(i);
   l=i->initNext(lev);
   if(iIsCodec)i->sc.iType=CTSettingsCell::eCodec;
   i->sc.pCfg=pCurCfg;
   i->sc.pEng=pCurService;
   return l;
}

void addChooseKey(CTList *l, const char *key, NSString *label){
   CTSettingsItem *i=new CTSettingsItem(l);
   l->addToTail(i);
   setValueByKey(&i->sc,key,label);
   i->sc.iType=CTSettingsCell::eRadioItem;
}


void addReorderKey(CTList *l, const char *key, NSString *label){
   CTSettingsItem *i=new CTSettingsItem(l);
   l->addToTail(i);
   setValueByKey(&i->sc,key,label);
   i->sc.iType=CTSettingsCell::eReorder;
}

void addCodecKey(CTList *l, const char *key, NSString *hdr, NSString *footer){
   if(!l)return;
   l=addSection(l,hdr,footer,key);
#if 1
   char *opt=NULL;
   int iType;
   int iSize;
   void *ret=findCfgItemByServiceKey(pCurService, (char*)key, iSize, &opt, &iType);
   if(ret && ((char*)ret)[0]){
      char bufTmp[256];
      strcpy(bufTmp,(char*)ret);
      int pos=0;
      int iPrevPos=0;
      int iLast=0;
      
      int ll=strlen(bufTmp);
      printf("[%d,%d]",ll,iSize);
      printf("[%s]",bufTmp);
      
      while(!iLast){
         if(pos>=iSize || bufTmp[pos]=='.' || bufTmp[pos]==',' || bufTmp[pos]==0){
            if(pos>=iSize  || bufTmp[pos]==0)iLast=1;
            bufTmp[pos]=0;
            if(isdigit(bufTmp[iPrevPos])){
               const char *codecID_to_sz(int id);
               const char *pid=codecID_to_sz(atoi(&bufTmp[iPrevPos]));
               if(pid)
                  addReorderKey(l,key,[[NSString alloc]initWithUTF8String:pid]);
            }
            else{
               addReorderKey(l,key,[[NSString alloc]initWithUTF8String:&bufTmp[iPrevPos]]);
            }
            iPrevPos=pos+1;
         }
         pos++;
      }
      
   }

#endif
   
}

CTSettingsItem* addItemByKey(CTList *l, const char *key, NSString *label){
   if(!l)return NULL;
   CTSettingsItem *i=new CTSettingsItem(l);
   l->addToTail(i);
   setValueByKey(&i->sc,key,label);
   if(i->sc.iType==CTSettingsCell::eChoose){
      
      i->root=new CTList();
      l=addSection(i->root,@"Choose",NULL);
      char bufTmp[256];
      strcpy(bufTmp,i->sc.bufOptions);
      int pos=0;
      int iPrevPos=0;
      int iLast=0;
      while(!iLast){
         if(bufTmp[pos]==',' || bufTmp[pos]==0){
            if(bufTmp[pos]==0)iLast=1;
            bufTmp[pos]=0;
            addChooseKey(l,key,[[NSString alloc]initWithUTF8String:&bufTmp[iPrevPos]]);
            iPrevPos=pos+1;
         }
         pos++;
      }
      
   }
   return i;
}

int onDeleteAccount(void *pSelf, void *pRetCB){
   CTSettingsItem *it=(CTSettingsItem*)pSelf;
   if(!it || !it->sc.pEng)return -1;
   
   sendEngMsg(it->sc.pEng,"delete");
   //   it->sc.b
   
   
   return 0;
}

CTList * addSectionP(CTList *l, NSString *hdr, NSString *footer, const char *key=NULL){
   if(!iCfgOn || !l)return NULL;
   return addSection(l, hdr, footer, key);
}

CTSettingsItem* addItemByKeyP(CTList *l, const char *key, NSString *label){
   if(!iCfgOn || !l)return NULL;
   return addItemByKey(l, key, label);
}
CTList * addNewLevelP(CTList *l, NSString *lev, int iIsCodec=0){
   if(!iCfgOn || !l)return NULL;
   return addNewLevel(l ,lev, iIsCodec);
}


CTList *addAcount(CTList *l, const char *name, int iDel){
   
   CTList *n=addNewLevel(l,[[NSString alloc]initWithUTF8String:name]);
   CTSettingsItem *ac=(CTSettingsItem *)l->getLTail();
   ac->sc.iCanDelete=iDel;
   ac->sc.onDelete=onDeleteAccount;
   
   CTList *x=addSectionP(n,@"Server settings",NULL);
   
   addItemByKey(x,"szTitle",@"Account title");
   CTSettingsItem *ii=addItemByKey(x,"iAccountIsDisabled",@"Enabled");
   if(ii)ii->sc.iInverseOnOff=1;
   
   CTList *s=addSection(n,@"",NULL);
   
   addItemByKeyP(s,"un",@"User name");
   addItemByKeyP(s,"pwd",@"Password");
   addItemByKeyP(s,"tmpServ",@"Domain");
   addItemByKey(s,"nick",@"Display name");
   
   
   s=addSectionP(n,@"",NULL);
   CTList *adv=addNewLevelP(s,@"Advanced");
   
   s=addSection(adv,@"ZRTP",NULL);
   addItemByKey(s,"iZRTP_On",@"Enable ZRTP");
   addItemByKey(s,"iSDES_On",@"Enable SDES");
   
   s=addSection(adv,@"",NULL);
   addItemByKey(s,"nr",@"SIP user-ID");
   
   s=addSection(adv,@"Network",NULL);
   addItemByKey(s,"szSipTransport",@"SIP transport");
   addItemByKey(s,"uiExpires",@"Reregistration time(s)");
   addItemByKey(s,"bufpxifnat",@"Proxy");//TODO outgoing 
   
   addItemByKey(s,"iSipPortToBind",@"SIP Port");
   addItemByKey(s,"iRtpPort",@"RTP Port");
   
   
   
   addItemByKey(s,"iSipKeepAlive",@"Send SIP keepalive");
   addItemByKey(s,"iUseStun",@"Use STUN");
   addItemByKey(s,"bufStun",@"STUN server");
   addItemByKey(s,"iUseOnlyNatIp",@"Use device IP only");
   
   
   
   s=addSection(adv,@"Audio",NULL);
   CTList *l2;
   CTList *s2;
   CTList *cod;
   //--------------------->>----
   l2=addNewLevel(s,@"WIFI");
   s2=addSection(l2,@"",NULL);
   cod=addNewLevel(s2,@"Codecs",1);
   
   addCodecKey(cod,"szACodecs",@"Enabled",NULL);
   addCodecKey(cod,"szACodecsDisabled",@"Disabled",NULL);
   
   addItemByKey(s2,"iPayloadSizeSend",@"RTP Packet size(ms)");
   addItemByKey(s2,"iUseVAD",@"Use SmartVAD®");
   //---------------------<<-----
   //---------------------
   l2=addNewLevel(s,@"3G");
   s2=addSection(l2,@"",NULL);
   cod=addNewLevel(s2,@"Codecs",1);
   
   addCodecKey(cod,"szACodecs3G",@"Enabled",NULL);
   addCodecKey(cod,"szACodecsDisabled3G",@"Disabled",NULL);
   
   addItemByKey(s2,"iPayloadSizeSend3G",@"RTP Packet size(ms)");
   addItemByKey(s2,"iUseVAD3G",@"Use SmartVAD®");
   
   
   
   
   //   l2=addNewLevel(s,@"If bad network(TODO)");
   addItemByKey(s,"iResponseOnlyWithOneCodecIn200Ok",@"One codec in 200OK");
   addItemByKey(s,"iPermitSSRCChange",@"Allow SSRC change");
   
   // addItemByKey(s,"iUseAEC",@"Use software EC");
   
   s=addSection(adv,@"Video",NULL);
   
   CTSettingsItem *liv=addItemByKey(s,"iDisableVideo",@"Video call");//TODO rename
   if(liv)liv->sc.iInverseOnOff=1;
   addItemByKey(s,"iCanAttachDetachVideo",@"Can Add Video");
   
   addItemByKey(s,"iVideoKbps",@"Max Kbps");
   addItemByKey(s,"iVideoFrameEveryMs",@"Frame Interval(ms)");
   addItemByKey(s,"iVCallMaxCpu",@"Max CPU usage %");//TODO can change in call
   
   
  /*
   s=addSection(adv,@"",NULL);
   addItemByKey(s,"szUA",@"SIP user agent");
   addItemByKey(s,"szUASDP",@"SDP user agent");
   */
   
   s=addSection(adv,@"",NULL);
   addItemByKey(s,"iDebug",@"Debug");
   liv=addItemByKey(s,"bCreatedByUser",@"Can reprovision");
   if(liv)liv->sc.iInverseOnOff=1;
   
//   addItemByKey(s,"iIsTiViServFlag",@"Is Tivi server?");
   
   return n;
}



int onChangeSHA384(void *pSelf, void *pRetCB){
   
   CTSettingsItem *x;
   CTSettingsItem *it=(CTSettingsItem*)pSelf;
   if(!it)return -1;
   
   const char *p=it->getValue();
   if(p[0]=='1')return 0;
   
   
   CTList *l=(CTList *)it->parent;
   if(!l)return -2;
   
   x=(CTSettingsItem *)l->findItem((void*)"iDisableECDH384", sizeof("iDisableECDH384")-1);
   if(x)x->setValue("0");//inv
   
   return 2;
}

int onChangeAES256(void *pSelf, void *pRetCB){
   
   CTSettingsItem *x;
   CTSettingsItem *it=(CTSettingsItem*)pSelf;
   if(!it)return -1;
   
   const char *p=it->getValue();
   if(p[0]=='1')return 0;
   
   
   CTList *l=(CTList *)it->parent;
   if(!l)return -2;
   
   x=(CTSettingsItem *)l->findItem((void*)"iDisableECDH384", sizeof("iDisableECDH384")-1);
   if(x)x->setValue("0");//inv
   
   return 2;
}


int onChangeECDH386(void *pSelf, void *pRetCB){
   CTSettingsItem *x;
   CTSettingsItem *it=(CTSettingsItem*)pSelf;
   if(!it)return -1;
   
   const char *p=it->getValue();
   if(p[0]=='0')return 0;
   
   
   CTList *l=(CTList *)it->parent;
   if(!l)return -2;
   
   x=(CTSettingsItem *)l->findItem((void*)"iEnableSHA384", sizeof("iEnableSHA384")-1);
   if(x)x->setValue("1");
   
   x=(CTSettingsItem *)l->findItem((void*)"iDisableAES256", sizeof("iDisableAES256")-1);
   if(x)x->setValue("1");//label is inversed

   return 2;
}
int onChangePref2K(void *pSelf, void *pRetCB){
   CTSettingsItem *it=(CTSettingsItem*)pSelf;
   CTSettingsItem *x;
   if(!it)return -1;   
   
   const char *p=it->getValue();
   if(p[0]=='0')return 0;
   
   
   CTList *l=(CTList *)it->parent;
   if(!l)return -2;
   
   
   x=(CTSettingsItem *)l->findItem((void*)"iDisableDH2K", sizeof("iDisableDH2K")-1);
   if(x)x->setValue("1");//label is inversed
   return 2;
}
int onChangeDis2K(void *pSelf, void *pRetCB){
   CTSettingsItem *it=(CTSettingsItem*)pSelf;
   CTSettingsItem *x;
   if(!it)return -1;   
   
   const char *p=it->getValue();
   if(p[0]=='1')return 0;
   
   CTList *l=(CTList *)it->parent;
   if(!l)return -2;
   
   
   x=(CTSettingsItem *)l->findItem((void*)"iPreferDH2K", sizeof("iPreferDH2K")-1);
   if(x)x->setValue("0");//label is inversed
   return 2;
}



static void loadAccountSection(CTList *l){
   CTList *as=addSection(l,@" ",@"");
   CTList *ac=addNewLevel(as,@"Accounts");
   CTList *n=addSection(ac,@"Enabled",@"");
   
   int cnt=0;
   
   for(int i=0;i<20;i++){
      pCurService=getAccountByID(cnt,1);
      if(pCurService){
         cnt++;
         pCurCfg=getAccountCfg(pCurService);
         addAcount(n,getAccountTitle(pCurService),1);
      }
   }
   
   cnt=0;
   for(int i=0;i<20;i++){
      pCurService=getAccountByID(cnt,0);
      
      if(pCurService){
         if(!cnt)n=addSection(ac,@"Disabled",NULL);
         cnt++;
         pCurCfg=getAccountCfg(pCurService);
         addAcount(n,getAccountTitle(pCurService),1);
      }
   }
   
   //TODO check can we add new account
   if(!iCfgOn){
      pCurService=NULL;
      pCurCfg=NULL;
      return;
   }
   
   
   n=addSection(ac,NULL,NULL);
   
   void *getEmptyAccount();
   int createNewAccount(void *pSelf, void *pRet);
   
   pCurService=getEmptyAccount();
   
   if(pCurService){
      pCurCfg=getAccountCfg(pCurService);
      CTList *rr=addAcount(n,"New",0);
      if(rr){
         CTSettingsItem *ri=(CTSettingsItem *)n->getLTail();
         if(ri){
            ri->sc.pRetCB=NULL;
            ri->sc.onChange=createNewAccount;
         }
      }
   }
   
   pCurService=NULL;
   pCurCfg=NULL;
}


void loadSettings(CTList *l){


   CTSettingsItem *it;
   
   loadAccountSection(l);
   
   CTList *n;

   n=addSection(l,NULL,NULL);
   CTList *pref=addNewLevel(n,@"Preferences");

   CTList *zp=addSection(pref,NULL,NULL);
   n=addNewLevel(zp,@"ZRTP");
   
   CTList *zrtp=addSection(n,NULL,NULL);
   
   it=addItemByKeyP(zrtp,"iDisableECDH384",@"ECDH-384");
   if(it)it->sc.onChange=onChangeECDH386;
   if(it)it->sc.iInverseOnOff=1;
   
   it=addItemByKeyP(zrtp,"iDisableECDH256",@"ECDH-256");
   if(it)it->sc.iInverseOnOff=1;

   it=addItemByKeyP(zrtp,"iDisableDH2K",@"DH-2048");
   if(it)it->sc.onChange=onChangeDis2K;
   if(it)it->sc.iInverseOnOff=1;

   it=addItemByKeyP(zrtp,"iPreferDH2K",@"Prefer DH-2048");
   if(it)it->sc.onChange=onChangePref2K;
   
   it=addItemByKeyP(zrtp,"iDisableAES256",@"AES-256");
   if(it)it->sc.iInverseOnOff=1;
   if(it)it->sc.onChange=onChangeAES256;

   it=addItemByKeyP(zrtp,"iDisableTwofish",@"Twofish");
   if(it)it->sc.iInverseOnOff=1;

   
   it=addItemByKeyP(zrtp,"iEnableSHA384",@"SHA-384");
   if(it)it->sc.onChange=onChangeSHA384;
   
   it=addItemByKeyP(zrtp,"iDisableSkein",@"Skein-MAC");
   if(it)it->sc.iInverseOnOff=1;

   it=addItemByKey(zrtp,"iDisable256SAS",@"SAS word list");
   if(it)it->sc.iInverseOnOff=1;
   
   CTList *sn=addSectionP(n,@"Use with caution",NULL);
   it=addItemByKey(sn,"iClearZRTPCaches",@"Clear caches");
   if(it)it->sc.iType=it->sc.eButton;
   //zidu atsevishki vajag lai nekraatos otraa galaa zidi kas nevienam nav vajadziigi
   //--  it=addItemByKey(sn,"iClearZRTP_ZID",@"(Clear ZID and caches)");
   //--  if(it)it->sc.iType=it->sc.eButton;
   
   
   CTList *ui=addSection(pref,NULL,NULL);
   CTList *ui2=addNewLevel(ui,@"User Interface");
   
   /*
   n=addSectionP(ui2,@"Video",NULL);
   
   it=addItemByKey(n,"iDontSimplifyVideoUI",@"Simplify Usage");
   if(it)it->sc.iInverseOnOff=1;
   */
  // addItemByKey(n,"iDisplayUnsolicitedVideo",@"Display Unsolicited");
   n=addSection(ui2,@"",NULL);
   addItemByKey(n,"iAudioUnderflow",@"Audio underflow tone");
   addItemByKey(n,"iShowRXLed",@"Show RX LED");
   addItemByKey(n,"iKeepScreenOnIfBatOk",@"Desktop phone mode");//keep screen on while charging and battery > 50%
   
   addItemByKey(n,"iRetroRingtone",@"Retro Ringtone");

   
   n=addSection(l,@"Build",NULL);
   NSString* ns = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
   addItemByKey(n,"abc",ns);
 
}

#pragma mark - call screen monitoring thread

static int iThreads=0;
static int iThreadIsStarting=0;

void* callMonitorThread(void* data)
{
   
   if(iThreadIsStarting>0)iThreadIsStarting--;
   iThreads++;
   int iThreadID=iThreads;
   AppDelegate *p=(AppDelegate*)data;
   
   int iShowRXLed=0;
   int *pi=(int*)findGlobalCfgKey("iShowRXLed");
   if(pi)iShowRXLed=*pi;

   NSAutoreleasePool* tempPool = [[NSAutoreleasePool alloc] init];
   
   int i2Threads=0;
   int cnt=0;
   
   if(iThreads>1){
      for(int i=0;i<5;i++){
         
         usleep(200*1000);
         if(iThreads==1)break;
      }
   }
   
   int n=0;
   while(1){
      if(iShowRXLed || p->iCanShowMediaInfo || p->iAudioUnderflow){
         [p callThreadLedCB];
         usleep(20*1000);
         n++;
         if(n<40)continue;
         n=0;
      }
      int cs=p->calls.getCallCnt();
      if(!cs && cnt>4)break;
      [p callThreadCB:900];
      cnt++;
      if(iThreads>1){
         i2Threads++;
         if(i2Threads>10 && iThreadID==iThreads)break;
         usleep(5000);
      }
      else{
         i2Threads=0;
      }
   }
   
   
   if(iThreads==1){
      int i;
      for(i=0;[p callScrVisible] && i<3;i++){
         usleep(600*1000);
         
      }
      
      if([p callScrVisible] && !p->calls.getCallCnt()){
         
         p->iCanHideNow=1;
         [p performSelectorOnMainThread:@selector(onEndCall) withObject:nil waitUntilDone:TRUE]; 
      }
   }
   
   iThreads--;
   
   [tempPool drain];
   
   return NULL;
}

void LaunchThread(AppDelegate *c)
{
   // Create the thread using POSIX routines.
   if(iThreadIsStarting)return;
   iThreadIsStarting++;
   pthread_attr_t  attr;
   pthread_t       posixThreadID;
   int             returnVal;
   
   returnVal = pthread_attr_init(&attr);
   assert(!returnVal);
   returnVal = pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
   assert(!returnVal);
   
   int     threadError = pthread_create(&posixThreadID, &attr, &callMonitorThread, c);
   
   returnVal = pthread_attr_destroy(&attr);
   assert(!returnVal);
   
   if (threadError != 0)
   {
      iThreadIsStarting=0;
   }
}

void checkThread(AppDelegate *s){
   if(iThreads==0){
      LaunchThread(s);
   }
}

