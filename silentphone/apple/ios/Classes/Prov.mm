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

#import "Prov.h"

int hasIP();
char *trim(char *sz);
int checkProv(const char *pUserCode, void (*cb)(void *p, int ok, const char *pMsg), void *cbRet);

@interface Prov ()

@end

@implementation Prov

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
       iProvStat=0;
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
   [super viewDidLoad];
   tfToken.delegate=self;
   [btSignIn setEnabled:NO];
   
   tfToken.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
   
}

- (void)viewDidUnload
{
    [super viewDidUnload];
   
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
   
   [btSignIn setEnabled:(textField.text.length>range.length || string.length)];
   return YES;
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
   [self onSignInPress];
   return YES;
}

-(void)provOk{
   [_provResponce onProvResponce:1];
   [self dismissModalViewControllerAnimated:YES];
}

-(void)startCheckPorv:(void *)unused{
   iProvStat=0;
   iPrevErr=0;
   
   void cbFnc(void *p, int ok, const char *pMsg);
   
   [uiProg setProgress:0 animated:NO];
   [uiProg setHidden:NO];
   [tfToken setHidden:YES];
   
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      
      const char *p=[tfToken.text UTF8String];
      char bufC[128];
      strncpy(bufC,p,127);
      bufC[127]=0;
      

      trim(&bufC[0]);
      
      int r=checkProv(&bufC[0], cbFnc, self);
      
      dispatch_async(dispatch_get_main_queue(), ^{
         [uiProg setHidden:YES];
         [tfToken setHidden:NO];
         [btSignIn setEnabled:YES];
         
         if(r==0)[self provOk];
      });
   });
   

     
}

-(IBAction)onBtPress{
   const char *p=[tfToken.text UTF8String];
  //    [self provOk];
}

-(IBAction)onSignUpPress{
   NSString* launchUrl = [NSString stringWithFormat:@"https://accounts.silentcircle.com"];
   [[UIApplication sharedApplication] openURL:[NSURL URLWithString: launchUrl]];
}

-(IBAction)onSignInPress{
   
   if(!hasIP()){
      [self showMsgMT:@"The Internet connection appears to be offline." msg:""];
      return;
   }
   
   [tfToken resignFirstResponder];

   [self performSelector:@selector(startCheckPorv:) withObject:nil afterDelay:.1];
   
}

-(void)showMsgMT:(NSString *)title msg:(const char*)msg{
   NSString *m= [NSString stringWithUTF8String:msg];  
   UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                   message:m 
                                                  delegate:nil 
                                         cancelButtonTitle:nil
                                         otherButtonTitles:@"Ok",Nil];
   [alert show];
   [alert release];
}
-(void)cbTLS:(int)ok  msg:(const char*)msg {
   NSLog(@"prov=[%s] %d",msg,ok);
   
   if(ok<=0){
      if(iPrevErr==-2)return;
      iPrevErr=ok;
      dispatch_async(dispatch_get_main_queue(), ^{
         
         [self showMsgMT:@"Can not download configuration, check code ID and try again."  msg:msg];

      });
   }
   else{
         iProvStat++;
      
         dispatch_async(dispatch_get_main_queue(), ^{
            float f=(float)iProvStat/14.;
            if(f>1.)f=1.;
            [uiProg setProgress:f animated:YES];
         });
   }
}

@end

void cbFnc(void *p, int ok, const char *pMsg){
   Prov *pr=(Prov*)p;
   if(pr){
      [pr cbTLS:ok msg:pMsg];
   }
}
