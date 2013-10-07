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

template <class T, int iMax>
class CTArray{
   int iCnt;
public:
   
   T _t[iMax];
   
   CTArray(){reset();}
   
   void reset(){iCnt=0;memset(_t,0,sizeof(_t));}
   
   int count(){return iCnt;}
   
   int add(T *c){
      if(iCnt>=iMax)return -1;
      memcpy(&_t[iCnt],c, sizeof(T));
      iCnt++;
      return 0;
   }
   
   T *get(int index){
      if(index<0 || index>iCnt)return NULL;
      return &_t[index];
   }
   
   void swap(int t1, int t2){
      T _s = _t[t1];
      memcpy(&_t[t1], &_t[t2], sizeof(T));
      memcpy(&_t[t2], &_s, sizeof(T));
   }
   
   int insert(int pos, T *c){
      if(iCnt>=iMax || pos>=iMax || pos<0)return -1;
      int move=iCnt-pos;
      if(move>0)memmove(&_t[pos+1],&_t[pos],sizeof(T)*move);
      memcpy(&_t[pos], c, sizeof(T));
      iCnt++;
      return 0;
   }
   int remove(int pos){
      if(pos>=iMax || pos<0)return -1;
      int move=iCnt-pos;
      if(move>0)memmove(&_t[pos],&_t[pos+1],sizeof(T)*move);
      iCnt--;
      return 0;
   }
   
   inline int add(T c){return add(&c);}
   inline int insert(int pos, T c){return insert(pos,&c);}
   
   int move(int from, int to){
      
      if(from==to)return 0;
      
      T *p=get(from);
      if(!p)return -1;
      
      T t=*p;
      int e = remove(from);
      if(!e)e = insert(to, &t);
      
      return e;
   }
   
};
/*
 int main(int argc, char *argv[]){
 
 CTArray<int,7> a;
 a.add(0);a.add(1);a.add(2);a.add(3);a.add(4);a.add(5);
 // a.insert(2,4);
 a.remove(3);
 //a.swap(2,4);
 
 for(int i=0;i<a.count();i++)printf("index=%d\n",a.get(i));
 
 return 0;
 }
 */

typedef struct {
   enum{eNull, eLabel, eCall, eDescr};
   int eType;
   //union{
   const char *descr;
   const char *label;
   CTCall *c;
   NSString *imgName;
   int iIsConf;
   //};
}CM_CELL;


class CTCMA: public CTArray<CM_CELL,12>{
public:
   CTCMA():CTArray(){}

   CTCall *getCall(int idx){
      CM_CELL *t=get(idx);
      if(!t)return NULL;
      if(t->eType!=CM_CELL::eCall)return NULL;
      return t->c;
   }
   int addDescr(const char *l, NSString *img=NULL){
      if(!l)return -1;
      CM_CELL t; memset(&t, 0, sizeof(t));
      t.eType=t.eDescr;
      t.descr=l;
      t.imgName=img;
      return add(&t);
   }
   
   int addLabel(const char *l, NSString *img=NULL, int iIsConf=0){
      if(!l)return -1;
      CM_CELL t; memset(&t, 0, sizeof(t));
      t.eType=t.eLabel;
      t.label=l;
      t.imgName=img;
      t.iIsConf=iIsConf;
      return add(&t);
   }
   
   int addCall(CTCall *c){
      if(!c)return -1;
      CM_CELL t; memset(&t, 0, sizeof(t));
      t.eType=t.eCall;
      t.c=c;
      return add(&t);
   }
   
   int getH(int idx){
      CM_CELL *t=get(idx);
      if(!t)return 2;
      switch(t->eType){
         case CM_CELL::eCall:return 96;
         case CM_CELL::eLabel:return idx==0 && t->iIsConf?47:31;
         case CM_CELL::eDescr:return 26;
      }
      
      return 2;
   }
};


@interface CallManeger ()

@end

@implementation CallManeger
@synthesize callCell;

CTCMA cm_calls;

-(void)updateCD{
   if(!calls)return;
   iIgnoreSelected=0;
   
   int cc=calls->getCallCnt(CTCalls::eConfCall);
   int cp=calls->getCallCnt(CTCalls::ePrivateCall);
   int cs=calls->getCallCnt(CTCalls::eStartupCall);
   /*
    drag_call_into_conf.png
    private_panel.png
    conf_panel.png
    drag_kick_out.png
    out_in_panel.png
    */

   
   cm_calls.reset();

   int i;
   iCallsOffset[CTCalls::eConfCall]=0;
   
   if(cc || cp){
      cm_calls.addLabel("CONFERENCE", @"conf_panel.png",1);
      for(i=0;i<cc;i++) cm_calls.addCall(calls->getCall(CTCalls::eConfCall,i));
      if(cp)cm_calls.addDescr("Drag call into conference", @"drag.png");
   }
   if(1){
      cm_calls.addLabel("PRIVATE", @"private_panel.png");
      iCallsOffset[CTCalls::ePrivateCall]=cm_calls.count();
      if(cc) cm_calls.addDescr("Drag here to remove from conference", @"drag.png");
      for(i=0;i<cp;i++) cm_calls.addCall(calls->getCall(CTCalls::ePrivateCall,i));
   }
   iCallsOffset[CTCalls::eStartupCall]=cm_calls.count();
   if(cs){
      cm_calls.addLabel("INCOMING, OUTGOING", @"out_in_panel.png");
      for(i=0;i<cs;i++) cm_calls.addCall(calls->getCall(CTCalls::eStartupCall,i));
   }
   
   NSLog(@"e c=%d, pr=%d, na=%d",cc,cp,cs);
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
/*
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
*/

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
   //tw.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg_main.png"]];
   
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
   return cm_calls.count();
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
   return cm_calls.getH(indexPath.row);
}


-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
   
   int v = indexPath.row;
   CTCall *c = cm_calls.getCall(v);
   if(!c){/*puts("!c");*/return;}
   /*
   if(1)
   {
      for (UIControl *control in cell.subviews)
      {
         if ([control isMemberOfClass:NSClassFromString(@"UITableViewCellReorderControl")] && [control.subviews count] > 0)
         {
            for (UIControl *someObj in control.subviews)
            {
               if ([someObj isMemberOfClass:[UIImageView class]])
               {
                  UIImage *img = [UIImage imageNamed:@"ico_user_plus.png"];
                  int h = cm_calls.getH(indexPath.row);
                  ((UIImageView*)someObj).frame = CGRectMake(0.0, 0.0, 43.0, h);//43.0
                  ((UIImageView*)someObj).image = img;
               }
            }
         }
      }
   }
   */

   CallCell *cc = (CallCell*)cell;
   if(!c || !tableView || (int)tableView==1){puts("!c || !tw");return;}
   int a=c->iActive && !c->iIsOnHold;
//   puts(a?"selected":"not selected");

   cell.highlighted=!!a;
   cell.selected = !!a;
   [cell setHighlighted:!!a];
#if 1
   cc.uiBacgrImg.highlighted=!!a;
   [cc.uiBacgrImg setHighlighted:!!a];
#endif
   
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   static NSString *CellIdentifierLabelConf = @"CellLabelConf";
   static NSString *CellIdentifierLabel = @"CellLabel";
   static NSString *CellIdentifierCC = @"CallCell";
   static NSString *CellIdentifierCDescr = @"CellDescr";
   
   int v=indexPath.row;
   UITableViewCell *cell = NULL;// = [tableView dequeueReusableCellWithIdentifier:CellIdentifierSP];
   
   NSString *ns=NULL;
   
   CM_CELL *cmc = cm_calls.get(v);
   CTCall *c = cm_calls.getCall(v);
   
   if(cmc && !c){
      const char *p = cmc->eType == cmc->eDescr ? cmc->descr : cmc->label;
      if(p) ns = [NSString stringWithUTF8String: p];
   }
   
   if(cmc && cmc->eType == cmc->eDescr){
      
      UILabel *lbDescr;
      
      UITableViewCell *xcell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierCDescr];
      if (xcell == nil)
      {
         
         
         xcell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifierCDescr] autorelease];
         cell=xcell;
         
         CGRect f = cell.frame;
         CGFloat h = cm_calls.getH(v);
         CGFloat tOfs=5.0;
         
         lbDescr = [[[UILabel alloc] initWithFrame:
                     CGRectMake( 20.0, tOfs, f.size.width-40.0, h+8 )] autorelease];

         
         lbDescr.tag = 55;
         lbDescr.font = [UIFont systemFontOfSize: 14];
         lbDescr.textAlignment = UITextAlignmentCenter;
         lbDescr.textColor = [UIColor colorWithRed:.6 green:.6 blue:.6 alpha:1.0];
         lbDescr.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
         lbDescr.backgroundColor = [UIColor clearColor];
         [cell.contentView addSubview: lbDescr];
      
      }
      else{
         cell=xcell;
         lbDescr = (UILabel*)[cell.contentView viewWithTag:55];
      }
      [lbDescr setText:ns];
      
   }
   if(cmc && cmc->eType == cmc->eLabel){
      
      UILabel *lb;
      CGFloat tOfs=cmc->iIsConf?-4.0:5.0;
      
      UITableViewCell *xcell;
      
      NSString *nsCI = cmc->iIsConf ? CellIdentifierLabelConf : CellIdentifierLabel;
      
      xcell = [tableView dequeueReusableCellWithIdentifier:nsCI];
      if (xcell == nil)
      {
         xcell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nsCI] autorelease];
         
         cell=xcell;
         CGRect f = cell.frame;
         
         CGFloat ofs = 37.0;
         CGFloat h = cm_calls.getH(v);
         
         
         lb = [[[UILabel alloc] initWithFrame:
                CGRectMake( ofs , tOfs, f.size.width - ofs * 2, h )] autorelease];
         
         lb.tag = 55;
         lb.font = [UIFont boldSystemFontOfSize: 18];
         lb.textAlignment = UITextAlignmentLeft;
         lb.textColor = [UIColor whiteColor];
         lb.backgroundColor = [UIColor clearColor];
         lb.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
         [cell.contentView addSubview: lb];

      }
      else
      {
         cell=xcell;
         lb = (UILabel*)[cell.contentView viewWithTag:55];
      }
      [lb setText:ns];
      
   }
   if(!c || ns || !cmc){
      
      if(!cmc)return cell;
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      cell.showsReorderControl=NO;
      
      cell.tag=0;
      if(ns){
         cell.accessibilityLabel=ns;
      }

      if(cmc->imgName){
         ns=NULL;
         cell.backgroundView = [[[UIImageView alloc] initWithImage: [UIImage imageNamed:cmc->imgName] ]autorelease];
      }
      ns=NULL;
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
      
      int bIsStartup = CTCalls::isCallType(c,CTCalls::eStartupCall);
      
      cell.showsReorderControl = bIsStartup ? NO : YES;
      

      if(c){
         if(selected && c->iIsInConferece && !c->iIsOnHold && !c->iEnded){iIgnoreSelected=1;}
         if(!selected && !c->iIsOnHold && !c->iEnded)selected=c;
         if(c->iIsOnHold){iIgnoreSelected=1;}
         
         UIImageView *iv=(UIImageView*)[xcell viewWithTag:505];
         if(iv){
            int isVideoCall(int iCallID);
            int iHide=!isVideoCall(c->iCallId);
            [iv setHidden:!!iHide];
         }
         
         int a=!bIsStartup && !c->iIsOnHold;
         
         [xcell setHighlighted:!!a];
         [xcell.uiBacgrImg setHighlighted:!!a];
         xcell.selected = !!a;
         
         if(bIsStartup){
            xcell.lbZRTP.text=@"";
            [xcell.sas setHidden:YES];
            [xcell.uiAnswerBt setHidden:!c->mustShowAnswerBT()];
            
         }
         else {
            [xcell.uiAnswerBt setHidden:YES];
            [xcell.sas setHidden:YES];
            //[xcell.sas setHidden:NO];
            //[xcell.sas setTitle:[NSString stringWithUTF8String:&c->bufSAS[0]] forState:UIControlStateNormal];
            
            c->setSecurityLines(xcell.lbZRTP, NULL);
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
   CTCall *c=cm_calls.getCall(b.tag);
   
   if(!c || !c->cell || c->cell.cTCall!=c)return;
   
   
   if(c->iCallId==0){
      NSLog(@"onAnswerPress err 0");
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
   
}
-(IBAction)onEndCallPress:(id)sender{
   UIButton *b=(UIButton *)sender;
   CTCall *c=cm_calls.getCall(b.tag);
   if(!c || !c->cell || c->cell.cTCall!=c)return;
   
   
   if(c->iCallId==0){
      NSLog(@"onEndCallPress err 0");
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
   puts("moveRowAtIndexPath");
   if(fromIndexPath.row==toIndexPath.row){[self redraw];return;}
   CTCall *c=cm_calls.getCall(fromIndexPath.row);
   if(!c){puts("moveRowAtIndexPath !c");return;}
   

   cm_calls.move(fromIndexPath.row, toIndexPath.row);
   
  // c=cm_calls.getCall(toIndexPath.row);

   int iPrevV=c->iIsInConferece;

   c->iIsInConferece=toIndexPath.row < iCallsOffset[CTCalls::ePrivateCall];
   
   if(iPrevV!=c->iIsInConferece){
      AppDelegate *d=(AppDelegate*)appDelegate;
      [d confCallN:c add:c->iIsInConferece];
      [d unholdAndPutOthersOnHold:c];
      [self redraw];
   }

}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath{
   
   puts("targetIndexPathForMoveFromRowAtIndexPath");
   CTCall *c=cm_calls.getCall(sourceIndexPath.row);
   if(!c)return sourceIndexPath;
   
  // return proposedDestinationIndexPath;//
   
   int s=proposedDestinationIndexPath.section;
   
   int sc=iCallsOffset[CTCalls::eStartupCall];
   int sp=iCallsOffset[CTCalls::ePrivateCall];
   
   int bIsPriv = CTCalls::isCallType(c, CTCalls::ePrivateCall);

   if(bIsPriv && proposedDestinationIndexPath.row==0 )
      return [NSIndexPath indexPathForRow:1 inSection:s];
   
   if(bIsPriv){
      if(proposedDestinationIndexPath.row>=sp)
         return sourceIndexPath;
      
      if(proposedDestinationIndexPath.row<sp && sp>2)
         return [NSIndexPath indexPathForRow:(sp-2) inSection:s];
   }
   else{
      if(proposedDestinationIndexPath.row<sp)
         return sourceIndexPath;
      
      if(proposedDestinationIndexPath.row>=sc)
         return [NSIndexPath indexPathForRow:(sc-1) inSection:s];
      
      if(proposedDestinationIndexPath.row>sp)
         return [NSIndexPath indexPathForRow:(sp+1) inSection:s];
      
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
   return v<iCallsOffset[CTCalls::eStartupCall] && cm_calls.getCall(indexPath.row)?YES:NO;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   
   CTCall *c=cm_calls.getCall(indexPath.row);//[self findCallByIDX:indexPath.row];
   if(!c){
      
      return ;
   }
   //if(c!=[self findCallByIDX:indexPath.row])return;
   
   AppDelegate *d=(AppDelegate*)appDelegate;
   iIsVisibleOrShowningNow=0;
   selected=NULL;
   iIgnoreSelected=1;
   [d  setCurCallMT:c];
   
   [[self navigationController] popViewControllerAnimated:YES];
   
}
@end

