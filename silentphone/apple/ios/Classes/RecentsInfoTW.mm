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

#import "RecentsInfoTW.h"
#import "UICellController.h"
#import "Recents.h"
#import <QuartzCore/CALayer.h>


/*
@interface RO:NSObject

@end

*/
@interface RecentsInfoTW ()

@end

CTRecentsItem *getByIdxAndMarker(CTList *l, int idx, int iMarker);
NSString *toNSFromTB(CTStrBase *b);
NSString *toNSFromTBN(CTStrBase *b, int N);
void insertDateTime(CTEditBase *e, int iTime ,int iTimeOrDayOnly);
void insertDateTime(char  *buf, int iTime ,int iTimeOrDayOnly);
void insertDateFriendly(CTEditBase  *e, int iTime ,int iInsertToday);
const char* sendEngMsg(void *pEng, const char *p);
int addToFavorites(CTRecentsItem *i, void *fav, int iFind);

NSString *checkNrPatterns(NSString *ns);

NSString *translateServ(CTEditBase *b){

   char bufTmp[128];
   //int getText(char *p, int iMaxLen, CTStrBase *ed);
   bufTmp[0]='.';
   bufTmp[1]='t';
   bufTmp[2]=' ';
   bufTmp[3]=0;
   
   getText(&bufTmp[3],125,b);
   const char *p=sendEngMsg(NULL,&bufTmp[0]);
   if(p && p[0]){
      return [NSString stringWithUTF8String:p];
   }
   return toNSFromTB(b);                         
   
  
}


NSString *toNSFromRI(CTEditBase *b, CTRecentsItem *i){
   
   b->reset();
   
   //time
   
   
   //duration
   if(i->uiDuration>0){
      int m=i->uiDuration/60;
      int h=m/60;
      if(h){
         //2h 30 minutes
         b->addInt(h,"%d h ");
         b->addInt(m-h*60,"%2d minutes");
      }
      else if(m)b->addInt(m,"%2d minutes");
      else b->addInt((int)i->uiDuration,"%2d seconds");
   }
   else{
      if(i->iDir==i->eMissed){
         b->addText("Missed    ");
      }
      else if(i->iDir==i->eDialed){
         b->addText("Canceled  ");
      }
   }

   b->addText("     ",4);
   
   insertDateFriendly(b,(int)i->uiStartTime,0);
   
   return toNSFromTB(b);
   
}

@implementation RecentsInfoTW


 - (void) viewWillAppear:(BOOL)animated
{
   [self.navigationController setNavigationBarHidden:NO animated:animated];
   [super viewWillAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{

 [super viewDidUnload];
   [self.navigationController setNavigationBarHidden:YES animated:NO];


}
-(void)fillData:(CTRecentsItem*)i list:(CTList*)list{
   
   iItemsInList=0;
   lastList=list;
   item=i;

   
   CTRecentsItem *r=(CTRecentsItem *)list->getNext(NULL,1);
   while(r){
      if(i && i->isSameRecord(r)){
         
         r->iTmpMarker=(int)self;
         iItemsInList++;
      }
      else if(r->iTmpMarker==(int)self)r->iTmpMarker=0;
      
      r=(CTRecentsItem *)list->getNext(r,1);
   }
   
 //  array=[NSArray alloc]objectAtIndex:1
}
-(IBAction)showVCard:(id)sender{
   [recents showPersonVCard:item];
}

-(IBAction)addToFavorites:(id)sender{
   
   
   addToFavorites(item,NULL,0);
   UIButton *b=(UIButton*)[self.view viewWithTag:10]; 
   if(b){
      [b setHidden:YES];
   }
   

}
-(void)setViewData:(RecentsViewController*)rec item:(CTRecentsItem*)i list:(CTList*)list im:(UIImage*)im{
   
   recents=rec; 
  
   img=(UIImageView*)[self.view viewWithTag:1]; 
   lbName=(UILabel*)[self.view viewWithTag:2]; 
   lbNr=(UILabel*)[self.view viewWithTag:3]; 
   lbService=(UILabel*)[self.view viewWithTag:4]; 
   
    UIButton *b=(UIButton*)[self.view viewWithTag:10]; 
   if(b){
      [b setHidden:addToFavorites(i,NULL,1)?YES:NO];
         
   }

   lbName.text=toNSFromTB(&i->name);
   i->findAT_char();

   int iLCmp=i->peerAddr.getLen()-i->iAtFoundInPeer-1;
   
   if(iLCmp>3 && i->lbServ.getLen()==iLCmp && 
      memcmp(i->lbServ.getText(),i->peerAddr.getText()+i->iAtFoundInPeer+1,iLCmp*2)==0){

      lbNr.text=checkNrPatterns(toNSFromTBN(&i->peerAddr,i->iAtFoundInPeer));
   }
   else{
      lbNr.text=checkNrPatterns(toNSFromTB(&i->peerAddr));
   }
   
   UIImageView *flw=(UIImageView *)[self.view viewWithTag:301];
   if(flw){
      int findCSC_C_S(const char *nr, char *szCountry, char *szCity, char *szID, int iMaxLen);
      char bufC[64],szCity[64],sz2[64];
      if(findCSC_C_S(lbNr.text.UTF8String, &bufC[0], &szCity[0], &sz2[0],64)>0){
         strcat(sz2,".png");
         UIImage *im=[UIImage imageNamed: [NSString stringWithUTF8String:&sz2[0]]];
         lbNr.center=CGPointMake(lbNr.center.x+28,lbNr.center.y);
         [flw setImage:im];
      }
      else{
         
         [flw setImage:nil];
      }
   }
   
   lbService.text=translateServ(&i->lbServ);
   if(!im && (!i->name.getLen() || i->iABChecked==1)){
      im=[UIImage imageNamed: @"ico_user_plus.png"];
   }
   
   if(im){
      img.image=nil;
      img.image=im;
      CALayer *l=img.layer;
      l.shadowOffset = CGSizeMake(0, 3);
      l.shadowRadius = 5.0;
      l.shadowColor = [UIColor blackColor].CGColor;
      l.shadowOpacity = 0.8;

   }

   [self fillData:i list:list];
   
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
   return 1;//3;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {

   return @"All Calls";
   
   /*
   NSString *ns=@"Incoming";
   if(section==1)ns=@"Outgoing";
   else if(section==2)ns=@"Missed";
   
   return ns;
    */
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return iItemsInList;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CellRecentsInfo";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
   CTEditBuf<128> b;
   if (cell == nil)
   {
      cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
   }
   cell.showsReorderControl=NO;
   
   CTRecentsItem *i=getByIdxAndMarker(lastList,indexPath.row,(int)self);
   if(!i){cell.textLabel.text=@"";cell.tag=0;cell.imageView.image=nil; return cell;}
   
   cell.textLabel.text=toNSFromRI(&b,i);
   cell.tag=(int)i;
   
   if(i->iDir==i->eMissed){
      cell.imageView.image=nil;
      [cell.textLabel setTextColor:[UIColor redColor]];
      //[UIImage imageNamed: @"ico_missed.png"];
   }
   else if(i->iDir==i->eDialed){
      cell.imageView.image=[UIImage imageNamed: @"ico_call_out.png"];
      [cell.textLabel setTextColor:[UIColor blackColor]];
   }
   else if(i->iDir==i->eReceived){
      cell.imageView.image=[UIImage imageNamed: @"ico_call_in.png"];
      [cell.textLabel setTextColor:[UIColor blackColor]];
   }


    return cell;
}


- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
   return NO;
}
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
   return YES;
}
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
   
   return UITableViewCellEditingStyleDelete;//Insert;
}

//show delete when swipe left
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
   
   CTRecentsItem *i=getByIdxAndMarker(lastList,indexPath.row,(int)self);
   if(i)lastList->remove(i);
   
   CTRecentsItem *n=getByIdxAndMarker(lastList,0,(int)self);
   if(n)
      [self fillData:n list:lastList];
   else {
      n=getByIdxAndMarker(lastList,1,(int)self);
      if(n)[self fillData:n list:lastList];
      else [self fillData:nil list:lastList];
   }
      
   
   [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
   

}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   
}

- (void)dealloc {
   [super dealloc];
}
@end
