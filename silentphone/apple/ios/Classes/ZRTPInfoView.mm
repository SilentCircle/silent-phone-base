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

#import "ZRTPInfoView.h"
#import <QuartzCore/CALayer.h>

#define _T_WO_GUI

#include "../../../baseclasses/CTEditBase.h"

char* z_main(int iResp,int argc, const char* argv[]);
int getMediaInfo(int iCallID, const char *key, char *p, int iMax);
const char* sendEngMsg(void *pEng, const char *p);
NSString *toNSFromTB(CTStrBase *b);

static int iZRTPInfoViewIsVisible=0;

int isZRTPInfoVisible(){
   return iZRTPInfoViewIsVisible;
}

int  isSilentCircleSecure(int cid, void *pEng){
   char buf[64];
   int r=getMediaInfo(cid,"zrtp.sc_secure",&buf[0],63);
   if(r==1 && buf[0]=='1'){
      const char *p=sendEngMsg(pEng,".isTLS");
      if(p && p[0]=='1')return 1;
   }
   return 0;
}


@implementation ZRTPInfoView

- (id)initWithFrame:(CGRect)frame 
{
   self = [super initWithFrame:frame];
   if (self) 
   {
   }
   return self;
}

- (void) dealloc
{
   [super dealloc];
}

-(void)setFlag:(UIImageView *)im key:(const char *)key{

   char buf[64];
   char bufZ[32]="zrtp.";
   strcat(bufZ,key);
   buf[0]=0;
   int r=getMediaInfo(iCallID,&bufZ[0],&buf[0],63);
   
   if(r==1){
      UIImage *img = nil;
      switch(buf[0]){
         case '1':
            img=[UIImage imageNamed: @"panel_meta_ball_red.png"];
            break;
         case '2':
            img=[UIImage imageNamed: @"panel_meta_ball_green.png"];
            break;
         default:
            img=[UIImage imageNamed: @"panel_meta_ball_gray.png"];
            
      }

      
      [im setImage:nil];
      [im setImage:img];
   }
   else {
      UIImage *img=[UIImage imageNamed: @"panel_meta_ball_gray.png"];
      [im setImage:img];
   }
   //panel_meta_ball_gray
      
}
-(void)setFlag2:(UIButton *)bt key:(const char *)key{
   
   char buf[64];
   char bufZ[32]="zrtp.";
   strcat(bufZ,key);
   buf[0]=0;
   int r=getMediaInfo(iCallID,&bufZ[0],&buf[0],63);
   
   if(r==1){
      iVFlag=buf[0]=='1';
      UIImage *im=[UIImage imageNamed:iVFlag?@"main_lock_verified.png":@"main_lock_locked.png"];
      [bt setImage:nil forState:UIControlStateNormal];
      [bt setImage:im forState:UIControlStateNormal];
   }
   else iVFlag=-1;
   
}


-(void)setLabel:(UILabel *)lb key:(const char *)key{
   
   char buf[64];
   char bufZ[32]="zrtp.";
   strcat(bufZ,key);
   buf[0]=0;
   int r=getMediaInfo(iCallID,&bufZ[0],&buf[0],63);
   
   if(r>0){
      [lb setText:[NSString stringWithUTF8String:&buf[0]]];
   }
   else [lb setText:@""];
   
}
-(IBAction)dimissScrPress:(id)sender{
   [self removeFromSuperview];
   iZRTPInfoViewIsVisible=0;
}

-(IBAction)padLockClick:(id)sender{
   
   if(iVFlag<0)return;
   
   char buf[32];
   sprintf(buf,"*%c%d",iVFlag==1?'v':'V',iCallID);
   const char *p[]={0,&buf[0]};
   z_main(0,2,p);
   
   [self setFlag2:sender key:"v"];
}


- (void)willMoveToSuperview:(UIView *)newSuperview{
   [super willMoveToSuperview:newSuperview];
   if(!newSuperview)
      iZRTPInfoViewIsVisible=0;
}

-(IBAction)willDimissScr:(id)sender{
   iZRTPInfoViewIsVisible=0;
}


- (void) onReRead:(int)cid pEng:(void*)pEng  peer:(CTEditBase *)peer sas:(const char *)sas
{
   iZRTPInfoViewIsVisible=1;
   iCallID=cid;
   

   lbPeer=(UILabel*)[self viewWithTag:1]; 
   lbSas=(UILabel*)[self viewWithTag:2]; 
   
   if(lbSas)[lbSas setText:[NSString stringWithUTF8String:sas] ];
   if(lbPeer)[lbPeer setText: toNSFromTB(peer)];

   
   rs1=(UIImageView*)[self viewWithTag:101]; 
   rs2=(UIImageView*)[self viewWithTag:102]; 
   aux=(UIImageView*)[self viewWithTag:103]; 
   pbx=(UIImageView*)[self viewWithTag:104]; 
   
   lbClient=(UILabel*)[self viewWithTag:3]; 
   lbVersion=(UILabel*)[self viewWithTag:4]; 
   lbTLS=(UILabel*)[self viewWithTag:5]; 
   sdp_hash=(UILabel*)[self viewWithTag:6]; 
   lbKeyExchange=(UILabel*)[self viewWithTag:7]; 
   lbChiper=(UILabel*)[self viewWithTag:8]; 
   lbHash=(UILabel*)[self viewWithTag:9]; 
   lbAuthTag=(UILabel*)[self viewWithTag:10]; 
   
   btPadlock=(UIButton*)[self viewWithTag:500];
   
   
   [self setFlag:rs1 key:"rs1"];
   [self setFlag:rs2 key:"rs2"];
   [self setFlag:aux key:"aux"];
   [self setFlag:pbx key:"pbx"];
   
   [self setFlag2:btPadlock key:"v"];

#define T_SET_LABEL(_V) [self setLabel:_V key:#_V]
   T_SET_LABEL(sdp_hash);

   T_SET_LABEL(lbClient);
   T_SET_LABEL(lbVersion);
   T_SET_LABEL(lbChiper);
   T_SET_LABEL(lbAuthTag);
   T_SET_LABEL(lbHash);
   T_SET_LABEL(lbKeyExchange);
  
   
   [lbTLS setText:[NSString stringWithUTF8String:sendEngMsg(pEng,".sock")]];
   
   UIImageView *imv=(UIImageView*)[self viewWithTag:1000]; 
   

   CALayer *l=imv?imv.layer:self.layer;
   l.cornerRadius=12;

   l.shadowOffset = CGSizeMake(0, 10);
   l.shadowRadius = 5.0;
   l.shadowColor = [UIColor blackColor].CGColor;
   l.shadowOpacity = 0.8;

   
}


@end
