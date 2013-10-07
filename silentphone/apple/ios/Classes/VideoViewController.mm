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

#import "VideoViewController.h"
#import "CallCell.h"
#include "CTVideoInIOS.h"
#import "AppDelegate.h"

NSString *toNSFromTB(CTStrBase *b);

char* z_main(int iResp, int argc, const char* argv[]);;
unsigned int  getTickCount();
int isPlaybackVolumeMuted();

@implementation VideoViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
   self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
   
   return self;
}

- (void)viewDidLoad
{
   [super viewDidLoad];
   iActionSheetIsVisible=0;
   cvc->iCanAutoStart=0;
   if(btSwitch && !(cvc && [cvc capturing]))btSwitch.width=0.1;
   iWasSendingVideoBeforeEnteringBackgr=-1;
   btAccept.width=.1;
   iAnimating=0;
   iUserTouched=0;
   [btDeclineEnd setTitle:@"End Call"];
   [btDeclineEnd setTintColor:[UIColor blackColor]];
   
   
   CALayer *l;
   
   [lbVolumeWarning setHidden:YES];
   l=lbVolumeWarning.layer;
   l.borderColor = [UIColor whiteColor].CGColor;
   l.cornerRadius = 5;
   l.borderWidth=2;
   
}

- (void)viewDidUnload
{
   [super viewDidUnload];
   
   [cvc teardownAVCapture];
   [cvc release];
   [btSendStop release];
   [btSwitch release];
}

-(void)onGotoBackground{
   
   iWasSendingVideoBeforeEnteringBackgr=cvc && [cvc capturing];
   if(iWasSendingVideoBeforeEnteringBackgr) [self sendStopPress:nil];
   
}
-(void)onGotoForeground{
   if(iWasSendingVideoBeforeEnteringBackgr>0) [self startVideoPress:nil];
   iWasSendingVideoBeforeEnteringBackgr=-1;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
   //return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft);//UIInterfaceOrientationPortrait
   return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
-(void)setupVO{
   QuartzImageView *vo=(QuartzImageView*)[self.view viewWithTag:500];
   
   void g_setQWview(void *p);
   g_setQWview(vo);
   if(vo){
      vo->iCanDrawOnScreen=1;
      //TODO redrawAllLayers
      //vo->pVO->startDraw();
     // vo->pVO->endDraw();//draw last img
   }
   
   //if(vo)vo.touchDetector=self;
   if(vo)vo->_touchDetector=self;
}


-(void)setCall:(CTCall*)c canAutoStart:(int)canAutoStart iVideoScrIsVisible:(int*)iVideoScrIsVisible  a:(AppDelegate*)a{
   app=a;
   *iVideoScrIsVisible=1;
   pIsVisible=iVideoScrIsVisible;
   call=c;
   if(cvc)cvc->iCanAutoStart=canAutoStart;
   iCanStartVideo=canAutoStart;
   iIsIncomingVideoCall=canAutoStart;
   
   int findIntByServKey(void *pEng, const char *key, int *ret);
   
   iHideBackToAudioButton=0;
   
   iSimplifyUI=-1;
   findIntByServKey(c->pEng,"iDontSimplifyVideoUI",&iSimplifyUI);if(iSimplifyUI!=-1)iSimplifyUI=!iSimplifyUI;
   
   int iCanAttachDetachVideo=-1;
   //  if(!iSimplifyUI){
   if(0>=findIntByServKey(c->pEng,"iCanAttachDetachVideo",&iCanAttachDetachVideo)){
      
      if(!iCanAttachDetachVideo)iHideBackToAudioButton=1;
   }
   if(iSimplifyUI)iHideBackToAudioButton=1;
   
}

-(void)checkButtons{
   
   int c=cvc && [cvc capturing];
   
   
   
   if(c){
      [btSendStop setTitle:@"Mute Video" forState:UIControlStateNormal ];
      [btSendStop setTitle:@"Mute Video" forState:UIControlStateHighlighted ];
      if(btSwitch){
         btSwitch.width=0.0;
         
      }
   }
   else {
      [btSendStop setTitle:@"Send Video" forState:UIControlStateNormal];
      [btSendStop setTitle:@"Pause Video" forState:UIControlStateHighlighted ];
      if(btSwitch){
         btSwitch.width=0.1;
      }
   }
   [self checkThumbnailText];
   [btSendStop setEnabled:YES];
   
   float w=self.view.frame.size.width/4;
   btDeclineEnd.width=w;
   if(iAnsweredVideo){
      
      btMute.width=0;
      [btDeclineEnd setTitle:@"End Call"];
      [btDeclineEnd setTintColor:[UIColor blackColor]];
      btAccept.width=0.1;
   }
   else{
      [btDeclineEnd setTitle:@"Decline"];
      [btDeclineEnd setTintColor:[UIColor redColor]];
      btAccept.width=w;
      btMute.width=.1;
      
   }
   if(iSimplifyUI)[btSendStop setHidden:YES];
   if(iSimplifyUI|| iHideBackToAudioButton)[btBack setHidden:YES];
   // btSwitch
}


-(IBAction)endCallPress{
   
   if(iAnsweredVideo){
      [app endCallBt];
   }
   [self backPress:nil];
}

-(IBAction)sendStopPress:(id)bt{
   int c=cvc && [cvc capturing];
   
   void g_setQWview_vi(void *p);
   g_setQWview_vi(cvc);
   
   if(c){
      [self stopVideoPress:bt];
   }
   else{
      [self startVideoPress:bt];
   }
}
-(IBAction)switchMute:(id)bt{
   [app switchMute:bt];
   [muteIco setHidden:!app->iOnMute];
}


-(IBAction)startVideoPress:(id)bt{
   
   static int iStarting=0;
   iAnsweredVideo=1;
   iActiveVideo=1;
   if(iStarting)return;
   iStarting=1;
   cvc->cVI->stop(NULL);
   cvc->cVI->start(NULL);
   [cvc setupAVCapture];
   
   [self checkButtons];
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      
      char buf[64];
      sprintf(&buf[0],"*C%u",call->iCallId);
      const char *x[2]={"",&buf[0]};
      
      z_main(0,2,x);
   });
   
   iStarting=0;
}

- (void)onTouch:(UIView *)v updown:(int)updown x:(int)x y:(int)y{
   //NSLog(@"x=%d y=%d",x,y);
   iUserTouched=1;
   
   [self volumeCheck:nil];
   
   CGPoint p=CGPointMake((float)x,(float)y);
   
   UILabel *l=(UILabel*)[self.view viewWithTag:20010];
   
   if(updown!=1 && CGRectContainsPoint(cvc.frame,p)){
      cvc.center=p;
      muteIco.center=p;
      if(l)l.center=CGPointMake(p.x,p.y-32-2);
      iMoving=1;
      return;
   }
   if(updown==1 && iMoving){
      iMoving=0;
      CGPoint nearest;
      float ofs=cvc.frame.size.width/8;
      
      nearest.x=cvc.frame.size.width/2+ofs;
      nearest.y=cvc.frame.size.height/2+ofs;
      
      // self.t
      
      float bbh=44;//(self.tabBarController  && self.tabBarController.view)?self.tabBarController.view.frame.size.height:0;
      
      float w=self.view.frame.size.width;
      float h=self.view.frame.size.height-bbh;
      if(x>w/2) nearest.x=w-cvc.frame.size.width/2-ofs;
      if(y>h/2) nearest.y=h-cvc.frame.size.height/2-ofs;
      
      
      
      //CGPointMake(cvc.frame.size.width/2,cvc.frame.size.height/2);
      
      [UIView animateWithDuration:.5
                            delay:0.0
                          options:UIViewAnimationCurveEaseInOut
                       animations:^ {
                          
                          muteIco.center=nearest;
                          cvc.center=nearest;
                          if(l)l.center=CGPointMake(nearest.x,nearest.y-32);
                       }
                       completion:^(BOOL finished) {
                       }];
   }
   
   iMoving=0;
   
   if(updown==-1)[self showInfoView];
}
/*
 - (void)verticalFlip{
 [UIView animateWithDuration:someDuration delay:someDelay animations:^{
 yourView.transform = CATransform3DMakeRotation(M_PI_2,1.0,0.0,0.0); //flip halfway
 } completion:^{
 while ([yourView.subviews count] > 0)
 [[yourView.subviews lastObject] removeFromSuperview]; // remove all subviews
 // Add your new views here
 [UIView animateWithDuration:someDuration delay:someDelay animations:^{
 yourView.transform = CATransform3DMakeRotation(M_PI,1.0,0.0,0.0); //finish the flip
 } completion:^{
 // Flip completion code here
 }];
 }];
 }
 */

-(IBAction)switchCameraAnim:(id)sender{
   
   [cvc stopR];
   [cvc switchCamerasStep:1];
   [UIView transitionWithView:cvc
                     duration:1
                      options:UIViewAnimationOptionTransitionFlipFromLeft//UIViewAnimationOptionTransitionCurlUp
                   animations:^{
                      //  cvc.transform = CATransform3DMakeRotation(M_PI_2,1.0,0.0,0.0);
                      [UIView setAnimationDelay:.3];
                      [cvc switchCamerasStep:2];
                      //  [UIView setAnimationRepeatCount:.5];
                      
                   }
                   completion:^(BOOL finished){
                      [cvc startR];
                      
                   }];
   
}

-(void)checkThumbnailText{
   UILabel *l=(UILabel*)[self.view viewWithTag:20010];
   if(l){
      int c=cvc && [cvc capturing];
      if(c && strncmp(&call->bufSecureMsgV[0],"SECURE",6)==0){
         int  isSilentCircleSecure(int cid, void *pEng);
         int iSecureInGreen=isSilentCircleSecure(call->iCallId, call->pEng);
         [l setTextColor:iSecureInGreen?[UIColor greenColor]:[UIColor whiteColor]];
         [l setHidden:NO];
      }
      else{
         [l setHidden:YES];
      }
      
   }
}

-(void)showInfoView{
   UIView *info=(UIView*)[self.view viewWithTag:2000];
   if(info){
      if(iUserTouched){
         if(!iSimplifyUI && !iHideBackToAudioButton)[btBack setHidden:NO];
         if(!iSimplifyUI)[btSendStop setHidden:NO];
         
      }
      UILabel *l=(UILabel*)[self.view viewWithTag:2001];
      if(l){
         UILabel *l2=(UILabel*)[self.view viewWithTag:20001];
         call->setSecurityLines(l, l2, 1);
      }
      l=(UILabel*)[self.view viewWithTag:2002];
      if(l){
         [l setText:toNSFromTB(&call->zrtpPEER)];
      }
      [self checkThumbnailText];
      [muteIco setHidden:!app->iOnMute];
      if(info.isHidden){
         if(iAnimating)return;
         iAnimating=1;
         info.alpha=0;
         info.hidden=NO;
         
         //uiDur
         
         [UIView animateWithDuration:.5
                               delay:0.0
                             options:UIViewAnimationCurveEaseInOut
                          animations:^ {
                             info.alpha=0.6;
                          }
                          completion:^(BOOL finished) {
                             [info setHidden:NO];
                             info.alpha=.6;
                             iAnimating=0;
                             uiCanHideInfoAt=getTickCount()+2000;
                             [self performSelector:@selector(hideInfoView:) withObject:info afterDelay:3];
                          }];
      }
      else{
         uiCanHideInfoAt=getTickCount()+2000;
         [self performSelector:@selector(hideInfoView:) withObject:info afterDelay:3];
      }
   }
}

-(void)hideInfoView:(UIView *)v{
   if(uiCanHideInfoAt>getTickCount()){
      return;
   }
   if(iAnimating)return;
   
   UIView *info=(UIView*)[self.view viewWithTag:2000];
   if(info && !info.isHidden){
      iAnimating=1;
      info.alpha=0.6;
      [UIView animateWithDuration:.5
                            delay:0.0
                          options:UIViewAnimationCurveEaseInOut
                       animations:^ {
                          info.alpha=0.0;
                       }
                       completion:^(BOOL finished) {
                          
                          [info setHidden:YES];
                          info.alpha=.6;
                          iAnimating=0;
                          
                       }];
   }
   
}

-(IBAction)stopVideoPress:(id)bt{
   if(cvc && cvc->cVI)cvc->cVI->stop(NULL);
   if(cvc) cvc->iCanAutoStart=0;
   [self checkButtons];
   if(cvc)[cvc teardownAVCapture];
   
}

- (void)viewWillAppear:(BOOL)animated{
   [super viewWillAppear:animated];
   
   
   [self setupVO];
   
   void g_setQWview_vi(void *p);
   if(cvc)g_setQWview_vi(cvc);
   
   
}
- (void)viewDidAppear:(BOOL)animated{
   [super viewDidAppear:animated];
   
   if(iCanStartVideo){
      iCanStartVideo=0;
      dispatch_async(dispatch_get_main_queue(), ^{
         [self startVideoPress:nil];
      });
   }
   else [self checkButtons];
   
   [self showInfoView];
   
   [[ UIApplication sharedApplication ] setIdleTimerDisabled: YES ];
   
   [self performSelector:@selector(volumeCheck:) withObject:nil afterDelay:3];
   
}
-(void)volumeCheck:(id)v{
   
   if(isPlaybackVolumeMuted()){
      [lbVolumeWarning setHidden:NO];
       [self performSelector:@selector(volumeCheckLoop:) withObject:nil afterDelay:1];
   }
   else{
      [lbVolumeWarning setHidden:YES];
   }
}

-(void)volumeCheckLoop:(id)v{
   
   if(!isPlaybackVolumeMuted()){
      [lbVolumeWarning setHidden:YES];
   }
   else{
      [self performSelector:@selector(volumeCheckLoop:) withObject:nil afterDelay:1];
   }
}

- (void)viewWillDisappear:(BOOL)animated{
   
   
   [super viewWillDisappear:animated];
   
   [self stopVideoPress:nil];
   
   QuartzImageView *vo=(QuartzImageView*)[self.view viewWithTag:500];
   if(vo){
      vo->iCanDrawOnScreen=0;
   }
  // void g_setQWview(void *p);
   //g_setQWview(NULL);
    
   [[ UIApplication sharedApplication ] setIdleTimerDisabled: NO];
   
   
}
- (void)viewDidDisappear:(BOOL)animated{
   [super viewDidDisappear:animated];
   *pIsVisible=0;
}

-(IBAction)backPress:(id)bt{
   [self.navigationController popViewControllerAnimated:YES];
   *pIsVisible=0;
   cvc->iCanAutoStart=0;
   
   
   if(!call->iEnded){
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
         char buf[64];
         sprintf(&buf[0],"*c%u",call->iCallId);//TODO reinvite all calls
         const char *x[2]={"",&buf[0]};
         z_main(0,2,x);
      });
   }
}

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet {
   
   
}
- (void)actionSheetCancel:(UIActionSheet *)actionSheet{
   iActionSheetIsVisible=0;
   newCall=NULL;
}
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
   if(!newCall || actionSheet.tag !=newCall->iCallId)return;
   
   if(actionSheet.cancelButtonIndex==buttonIndex || !newCall){
      iActionSheetIsVisible=0;
      newCall=NULL;
      
      return;
   }
   // return;//
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      
      [app endCallN:call];
      usleep(100*1000);
      [self backPress:nil];
      [app answerCallFromVidScr:newCall];
      
      [app setCurCallMT: newCall];
      newCall=NULL;
      
   });
   iActionSheetIsVisible=0;
   
   
}
-(void)showIncomingCallMT{
   
   //http://stackoverflow.com/questions/6130475/adding-images-to-uiactionsheet-buttons-as-in-uidocumentinteractioncontroller
   if(!toolBar)return;
   
   CTCall *c=app->calls.getCall(app->calls.eStartupCall,0);
   printf("[c=%p]",c);
   if(!c || (c && c==newCall) || iActionSheetIsVisible)return;
   iActionSheetIsVisible=1;
   
   
   
   NSString *p2= [app loadUserData:c];
   
   int isVideoCall(int iCallID);
   const char *vc=isVideoCall(c->iCallId)?"video ":"";
   NSString *nsIncom;
   if(c->nameFromAB.getLen()){
      nsIncom=[NSString stringWithFormat:@"Incoming %scall %@, %@",vc,toNSFromTB(&c->nameFromAB),p2];
   }
   else nsIncom=[NSString stringWithFormat:@"Incoming %scall %@",vc,p2];
   
   UIActionSheet *as = [[UIActionSheet alloc]initWithTitle:nsIncom delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
   
   as.cancelButtonIndex=[as addButtonWithTitle:@"Ignore"];
   
   as.destructiveButtonIndex=[as addButtonWithTitle:@"End Call + Answer"];
   
   
   
   newCall=c;
   
   as.tag=c->iCallId;
   
   [as showFromToolbar:toolBar];
   [as release];
}


@end
