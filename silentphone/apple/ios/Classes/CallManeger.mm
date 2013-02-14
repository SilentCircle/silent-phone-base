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

#import "CallManeger.h"
#import "CallCell.h"
#import "AppDelegate.h"

static int iIsVisibleOrShowningNow=0;

void setFlagShowningCallManeger(int f){
   iIsVisibleOrShowningNow=f;
}


NSString *toNSFromTB(CTStrBase *b);



@interface CallManeger ()

@end

@implementation CallManeger
@synthesize callCell;

-(void)updateCD{
   if(!calls)return;
   iIgnoreSelected=0;
   iCallTypeOfs=0;
   iCallsOffset[CTCalls::eConfCall]=0;
   iCallsOffset[CTCalls::ePrivateCall]=calls->getCallCnt(CTCalls::eConfCall)+iCallsOffset[CTCalls::eConfCall]+1;
   iCallsOffset[CTCalls::eStartupCall]=calls->getCallCnt(CTCalls::ePrivateCall)+iCallsOffset[CTCalls::ePrivateCall]+1;
   
   int iCnt=calls->getCallCnt()+2;
   if(calls->getCallCnt(CTCalls::eStartupCall))iCnt++;
   iRows=iCnt;
   NSLog(@"e c=%d, pr=%d, na=%d",iCallsOffset[0],iCallsOffset[1],iCallsOffset[2]);
}

-(void)setCallArray:(CTCalls*)_calls{
   calls=_calls;
   [self updateCD];
}

-(void)redraw{
   
   if(!calls->getCallCnt()){
      [[self navigationController] popViewControllerAnimated:YES];
      return;
   }
   
   [self updateCD];
   [tw reloadData];
}
+(int)isVisibleOrShowningNow{
   return iIsVisibleOrShowningNow;
}

-(CTCall*)findCallByIDX:(int) idx{
   if(idx>iCallsOffset[CTCalls::eStartupCall]){
      return calls->getCall(CTCalls::eStartupCall, idx-iCallsOffset[CTCalls::eStartupCall]-1);
   }
   if(idx>iCallsOffset[CTCalls::ePrivateCall]){
      return calls->getCall(CTCalls::ePrivateCall, idx-iCallsOffset[CTCalls::ePrivateCall]-1);
   }
   if(idx>iCallsOffset[CTCalls::eConfCall]){
      return calls->getCall(CTCalls::eConfCall, idx-iCallsOffset[CTCalls::eConfCall]-1);
   }
   return 0;
}


- (id)initWithStyle:(UITableViewStyle)style
{
   self = [super initWithStyle:style];
   if (self) {
      selected=NULL;
      iIgnoreSelected=0;
      iRows=0;
      calls=NULL;
   }
   return self;
}

- (void) viewWillAppear:(BOOL)animated
{
   iIsVisibleOrShowningNow=1;
   [self updateCD];
   [self.navigationController setNavigationBarHidden:NO animated:animated];
   [super viewWillAppear:animated];
   [tw setEditing:YES];
   [self redraw];
}

- (void) viewWillDisappear:(BOOL)animated
{
   
   [self.navigationController setNavigationBarHidden:YES animated:NO];
   [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated{
   iIsVisibleOrShowningNow=0;
   [super viewDidDisappear:animated];
   
   [self.navigationController setNavigationBarHidden:YES animated:NO];
   CTCall *c=calls->curCall;
   if(!iIgnoreSelected && selected){
      
      AppDelegate *d=(AppDelegate*)appDelegate;
      [d  setCurCallMT:selected];
      selected=NULL;
   }
   else if(c && !c->iEnded){
      AppDelegate *d=(AppDelegate*)appDelegate;
      [d  setCurCallMT:c];
   }
   
   // selected=c;
   
}


- (void)viewDidLoad
{
   [super viewDidLoad];
   
}

- (void)viewDidUnload
{
   [super viewDidUnload];
   // Release any retained subviews of the main view.
   // e.g. self.myOutlet = nil;
   [callCell release];
   callCell=nil;
   
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
   return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
   return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   return iRows;
}




- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
   int v=indexPath.row;
   if(v==iCallsOffset[0])return 32;
   if(v==iCallsOffset[1])return 32;
   if(v==iCallsOffset[2])return 32;
   
   return 96;
}


-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
   int v=indexPath.row;
   CTCall *c=(CTCall *)callsPtr[v];
   if(!c)return;
   CallCell *cc=(CallCell*)cell;
   if(!c || !tableView || (int)tableView==1)return;
   int a=c->iActive && !c->iIsOnHold;
   if(!a && c==calls->curCall)a=1;
   
   cell.highlighted=!!a;
#if 1
   cc.uiBacgrImg.highlighted=!!a;
   [cc.uiBacgrImg setHighlighted:!!a];
#endif
   
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   static NSString *CellIdentifierSP = @"CellSP";
   static NSString *CellIdentifierCC = @"CallCell";
   
   int v=indexPath.row;
   UITableViewCell *cell;// = [tableView dequeueReusableCellWithIdentifier:CellIdentifierSP];
   
   // getConfCall
   NSString *ns=NULL;
   
   if(v==iCallsOffset[0]){
      ns=@"Conference";
      iCallTypeOfs=0;
   }
   else if(v==iCallsOffset[1]){
      ns=@"Private";
      iCallTypeOfs=0;
   }
   else if(v==iCallsOffset[2]){
      ns=@"Incoming, Outgoing";
      iCallTypeOfs=0;
   }
   int iType=-1;
   if(!ns){
      if(v>iCallsOffset[2])
         iType=2;
      else if(v>iCallsOffset[1])
         iType=1;
      else iType=0;
   }
   
   
   if(ns){
      UITableViewCell *xcell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierSP];
      if (xcell == nil)
      {
         xcell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifierSP] autorelease];
      }
      cell=xcell;
      cell.showsReorderControl=NO;
      
      cell.tag=0;
      callsPtr[v]=0;
      
      /*
       cell.backgroundView = [ [[UIImageView alloc] initWithImage:[ [UIImage imageNamed:@"cell_normal.png"] stretchableImageWithLeftCapWidth:0.0 topCapHeight:5.0] ]autorelease];
       
       cell.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"cell_normal.PNG"]];
       */
   }
   else {
#if 1
      CallCell *xcell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierCC];
      if (xcell == nil)
      {
         
         [[NSBundle mainBundle] loadNibNamed:@"CallCell" owner:self options:nil];
         xcell = callCell;
         self.callCell = nil;
      }
      cell=(UITableViewCell*)xcell;
      cell.showsReorderControl=iType!=CTCalls::eStartupCall;
      
      CTCall *c=[self findCallByIDX:v];
      if(c){
         if(selected && c->iIsInConferece && !c->iIsOnHold && !c->iEnded){iIgnoreSelected=1;}
         if(!selected && !c->iIsOnHold && !c->iEnded)selected=c;
         if(c->iIsOnHold){iIgnoreSelected=1;}
         
         UIImageView *iv=(UIImageView*)[xcell viewWithTag:505];
         if(iv){
            int isVideoCall(int iCallID);
            int iHide=iType!=CTCalls::eStartupCall;
            if(!iHide)iHide=!isVideoCall(c->iCallId);
            [iv setHidden:!!iHide];
         }
         
         
         int a=iType!=CTCalls::eStartupCall && !c->iIsOnHold;
         callsPtr[v]=c;
         cell.tag=(int)c;
         iCallTypeOfs++;
         
         [xcell.uiBacgrImg setHighlighted:!!a];
         xcell.highlighted=!!a;
         
         if(iType==CTCalls::eStartupCall){
            xcell.lbZRTP.text=@"";
            [xcell.sas setHidden:YES];
            [xcell.uiAnswerBt setHidden:!c->mustShowAnswerBT()];
            
         }
         else {
            [xcell.uiAnswerBt setHidden:YES];
            [xcell.sas setHidden:NO];
            [xcell.sas setTitle:[NSString stringWithUTF8String:&c->bufSAS[0]] forState:UIControlStateNormal];
            xcell.lbZRTP.text=[NSString stringWithUTF8String:&c->bufSecureMsg[0]];
            
            
         }
         
         AppDelegate *d=(AppDelegate*)appDelegate;
         NSString *p2=[d loadUserData:c];
         
         
         [xcell.uiImg setImage:nil];
         if(c->img){
            c->iImgRetainCnt++;
            
            [xcell.uiImg setImage:[c->img retain]];
         }
         else{
            [xcell.uiImg setImage:[UIImage imageNamed: @"ico_user.png"]];
         }
         
         
         xcell.uiName.text=toNSFromTB(&c->nameFromAB);
         xcell.uiDstNr.text=p2;
         
         xcell.uiAnswerBt.tag=v;
         xcell.uiEndCallBt.tag=v;
         
         [xcell.uiAnswerBt addTarget:self  action:@selector(onAnswerPress:) forControlEvents:UIControlEventTouchUpInside];
         [xcell.uiEndCallBt addTarget:self  action:@selector(onEndCallPress:) forControlEvents:UIControlEventTouchUpInside];
         
         c->cell=xcell;
         xcell.cTCall=c;
      }
#endif
      
   }
   
   if(ns)cell.textLabel.text=ns;
   return cell;
}
-(IBAction)onAnswerPress:(id)sender{
   UIButton *b=(UIButton *)sender;
   CTCall *c=[self findCallByIDX:b.tag];
   if(!c || !c->cell || c->cell.cTCall!=c)return;
   
   
   if(c->iCallId==0){
      NSLog(@"TODO endCall err 0");
      return;
   }
   dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      usleep(200*1000);
      dispatch_async(dispatch_get_main_queue(), ^{
         
         AppDelegate *d=(AppDelegate*)appDelegate;
         selected=c;
         [d  setCurCallMT:c];
         [d  answerCallN:c];
      });
   });
   
   NSLog(@"TODO answer %@", toNSFromTB(&c->nameFromAB));
   
   
}
-(IBAction)onEndCallPress:(id)sender{
   UIButton *b=(UIButton *)sender;
   CTCall *c=[self findCallByIDX:b.tag];
   if(!c || !c->cell || c->cell.cTCall!=c)return;
   
   
   if(c->iCallId==0){
      NSLog(@"TODO endCall err 0");
      return;
   }
   int cc=calls->getCallCnt();
   if(cc==1){
      iIsVisibleOrShowningNow=0;
      
      [[self navigationController] popViewControllerAnimated:NO];
   }
   AppDelegate *d=(AppDelegate*)appDelegate;
   [d  endCallN:c];
   if(c==selected){
      selected=0;
      iIgnoreSelected=0;
   }
   
   NSLog(@"TODO endCall %@", toNSFromTB(&c->nameFromAB));
   
}



- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
   return NO;
}
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
   return YES;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
   [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
   if(fromIndexPath.row==toIndexPath.row)return;
   CTCall *fr=callsPtr[fromIndexPath.row];
   if(toIndexPath.row>fromIndexPath.row){
      for(int i=fromIndexPath.row;i<toIndexPath.row;i++){
         callsPtr[i]=callsPtr[i+1];
      }
      callsPtr[toIndexPath.row]=fr;
   }
   else{
      for(int i=fromIndexPath.row;i>toIndexPath.row;i--){
         callsPtr[i]=callsPtr[i-1];
      }
      callsPtr[toIndexPath.row]=fr;
   }
   
   CTCall *c=fr;
   
   int privPos=0;
   for(int i=1;i<16;i++){
      if(callsPtr[i]==0){
         privPos=i;
         iCallsOffset[CTCalls::ePrivateCall]=i;
         break;
      }
   }
   
   if(c){
      int iPrevV=c->iIsInConferece;
      c->iIsInConferece=toIndexPath.row<privPos;
      [self redraw];
      
      if(iPrevV!=c->iIsInConferece){
         AppDelegate *d=(AppDelegate*)appDelegate;
         [d confCallN:c add:c->iIsInConferece];
         [d unholdAndPutOthersOnHold:c];
      }
   }
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath{
   
   int sc=iCallsOffset[CTCalls::eStartupCall];
   
   if(proposedDestinationIndexPath.row==0 || proposedDestinationIndexPath.row>=sc){
      int s=proposedDestinationIndexPath.section;
      if(proposedDestinationIndexPath.row>=sc){
         
         return [NSIndexPath indexPathForRow:(sc-1) inSection:s];
      }
      if(proposedDestinationIndexPath.row==0 ){
         //proposedDestinationIndexPath.row=1;
         return [NSIndexPath indexPathForRow:1 inSection:s];
         //return proposedDestinationIndexPath;
      }
      return sourceIndexPath;
   }
   return proposedDestinationIndexPath;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
   
   return UITableViewCellEditingStyleNone;
}



// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
   int v=indexPath.row;
   return v<iCallsOffset[CTCalls::eStartupCall] && [self findCallByIDX:indexPath.row]?YES:NO;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   
   CTCall *c=callsPtr[indexPath.row];//[self findCallByIDX:indexPath.row];
   if(!c){
      
      return ;
   }
   if(c!=[self findCallByIDX:indexPath.row])return;
   
   AppDelegate *d=(AppDelegate*)appDelegate;
   iIsVisibleOrShowningNow=0;
   selected=NULL;
   iIgnoreSelected=1;
   [d  setCurCallMT:c];
   
   [[self navigationController] popViewControllerAnimated:YES];
   
}

@end

