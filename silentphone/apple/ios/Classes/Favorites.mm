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

#import "Favorites.h"
#import "AppDelegate.h"


#define _T_WO_GUI
#include "../../../baseclasses/CTListBase.h"
#include "../../../baseclasses/CTEditBase.h"
#include "../../../tiviengine/CTRecentsItem.h"


NSString *toNSFromTB(CTStrBase *b);
NSString *toNSFromTBN(CTStrBase *b, int N);
NSString *translateServ(CTEditBase *b);
NSString *checkNrPatterns(NSString *ns);

static  NSString *toNS(CTEditBase *b, int N=0){
   if(N)return toNSFromTBN(b,N);
   return toNSFromTB(b);
}

int addToFavorites(CTRecentsItem *i, void *fav, int iFind){
   Favorites *pFav=(Favorites *)fav;
   static Favorites *f=pFav;
   if(fav){
      f=pFav;
   }
   if(!i || !f)return 0;
   
   f->fl->load();
   
   if(f->fl->hasRecord(i))return 1;
   if(iFind)return 0;
   
   
   
   CTRecentsItem *n=new CTRecentsItem();
   if(!n)return 0;
   
   *n=*i;
   n->next=NULL;
   n->prev=NULL;
   
   f->fl->getList()->addToTail(n);
   f->fl->activateAll();
   f->fl->save();
   
   [[f tableView] reloadData];

   
   return 0;
   
}

@interface Favorites ()

@end




@implementation Favorites

@synthesize favCell;
/*
-(void)awakeFromNib{
   
}
 */
-(void)editPress:(id)unused
{
   
   if(tw.editing){
      [tw setEditing:NO]; 
      self.navigationItem.leftBarButtonItem=btEdit;
   }
   else{
      [tw setEditing:YES]; 
      self.navigationItem.leftBarButtonItem=btDone;
   }
   //UITableView 
  // [self dismissModalViewControllerAnimated:YES];
}

-(void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker{
   [self dismissModalViewControllerAnimated:YES];
}

// Called after a person has been selected by the user.
// Return YES if you want the person to be displayed.
// Return NO  to do nothing (the delegate is responsible for dismissing the peoplePicker).
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person{
   return YES;
}
// Called after a value has been selected by the user.
// Return YES if you want default action to be performed.
// Return NO to do nothing (the delegate is responsible for dismissing the peoplePicker).
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier{
   
   if(property!=kABPersonPhoneProperty && property!=kABPersonURLProperty)return NO;
   if( property==kABPersonEmailProperty){}
   NSString* phone = nil;
   ABMultiValueRef phoneNumbers = ABRecordCopyValue(person,
                                                    property);
   
   NSString *abMultiValueIdentifier2Phone(ABMultiValueRef phoneNumbers, ABMultiValueIdentifier id);
   
   phone=abMultiValueIdentifier2Phone(phoneNumbers,identifier);
   if(!phone){
      CFRelease(phoneNumbers);
      return NO;
   }
   
   CFStringRef first = (CFStringRef)ABRecordCopyValue(person, kABPersonFirstNameProperty);
   CFStringRef last = (CFStringRef)ABRecordCopyValue(person, kABPersonLastNameProperty);
   NSString *f=(NSString*)first;
   NSString *l=(NSString*)last;


   
   CTRecentsItem *n=new CTRecentsItem();
   if(n){
   
      if(f){
         n->name.setText([f UTF8String]);
         if(l)n->name.addChar(' ');
      }
      if(l)n->name.addText([l UTF8String]);
      
      n->peerAddr.setText([phone UTF8String]);
      fl->getList()->addToTail(n);
      fl->countVisItems();
      fl->save();
      [tw reloadData];
   }
   if(f)CFRelease(first);
   if(l)CFRelease(last);
   
   [self dismissModalViewControllerAnimated:YES];
   CFRelease(phone);
   CFRelease(phoneNumbers);
   return NO;
   
}

-(void)addPress:(id)unused
{
      
      
      ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
      picker.peoplePickerDelegate = self;
      [self presentModalViewController:picker animated:YES];
      [picker release];
}


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
       // Custom initialization
       fl=NULL;
       addToFavorites(NULL,self,0);
    }
    return self;
}

- (void)viewDidLoad
{
   [super viewDidLoad];

   
   fl=NULL;
   addToFavorites(NULL,self,0);
   
   btDone=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(editPress:)];
   self.navigationItem.leftBarButtonItem=btDone;

   btEdit=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editPress:)];
   self.navigationItem.leftBarButtonItem=btEdit;

   UIBarButtonItem *bba=[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addPress:)];
   self.navigationItem.rightBarButtonItem=bba;
   
   [bba release];
   
   if(!fl)
      fl=new CTRecentsList(1);

}

-(void)loadFavorites{
   static int iFavLoaded=0;
   if(!iFavLoaded){
      iFavLoaded=1;
      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
         usleep(1000);
         dispatch_async(dispatch_get_main_queue(), ^{
            fl->load(); //countItemsGrouped
            //[self.tableView reloadData];
            [self.tableView reloadSections: [NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
         });
      });
   }
}

- (void)viewWillAppear:(BOOL)animated{
   [super viewWillAppear: animated];
  // fl->load(); 
   [self loadFavorites];
   
}

- (void)viewDidUnload
{
   [super viewDidUnload];
   delete fl;fl=NULL;
   [btEdit release];
   [btDone release];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   int r=fl->countVisItems();

   return r;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
 //  return nil;
   static NSString *CellIdentifier = @"CellFav";
   UITableViewCell *aCell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	if (aCell == nil)
	{
      [[NSBundle mainBundle] loadNibNamed:@"Favorite" owner:self options:nil];
		aCell = favCell;self.favCell = nil;
	}
   
   CTRecentsItem *i=fl->getByIndex(indexPath.row);

   {
      
      UILabel *lbName=(UILabel*)[aCell viewWithTag:1]; 
      UILabel *lbNr=(UILabel*)[aCell viewWithTag:2];
      if(!i){
         lbNr.text=nil;
         lbName.text=nil;
         return aCell;
      }
 
      int iHideSipDomain=1;
      
      i->findAT_char();
      int L=i->peerAddr.getLen();
      
      if(iHideSipDomain){
         L=i->iAtFoundInPeer;
      }
      if(i->name.getLen()>0){
         NSString *nn=[NSString stringWithFormat:@"%@  %@",checkNrPatterns(toNS(&i->peerAddr,L)),translateServ(&i->lbServ)];
         lbNr.text=nn;
         lbName.text=toNS(&i->name);
      }
      else{
         lbNr.text=translateServ(&i->lbServ);
         lbName.text=checkNrPatterns(toNS(&i->peerAddr,L));
      }
      
   }
   i->cell=aCell;
   
   aCell.showsReorderControl=YES;
   
   return aCell;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
   CTRecentsItem *f=fl->getByIndex(fromIndexPath.row);
   if(!f)return;
   CTRecentsItem *t=fl->getByIndex(toIndexPath.row);
   if(!t || f==t)return;
   
   CTList *l=fl->getList();
   fl->enableAutoSave(0);
   
   {
      if(t && toIndexPath.row<fromIndexPath.row)t=(CTRecentsItem *)l->getPrev(t);
      
      l->remove(f,0);
      if(toIndexPath.row==0){
         l->addToRoot(f);
      }
      else 
         if(!t){
            if(fromIndexPath.row>toIndexPath.row)
               l->addToRoot(f);
            else
               l->addToTail(f);
            
         }
         else l->addAfter(t,f);
   }
   fl->enableAutoSave(1);
   fl->save();
   
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
   return YES;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
   return NO;
}
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
   return YES;
}

//show delete when swipe left
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
   
   fl->removeByIndex(indexPath.row);
   fl->activateAll();
   
   [tableView reloadSections: [NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];

}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
   
   return UITableViewCellEditingStyleDelete;//Insert;
}
#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   [tableView deselectRowAtIndexPath:indexPath animated:NO];
   
   CTRecentsItem *i=fl->getByIndex(indexPath.row);
   
   [appDelegate callToR:i];
   /*

   if(i && i->peerAddr.getLen()>0){

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
         return;
      }
      
      [appDelegate callToS:'c' dst:&buf[0] eng:eng];
   }
    */
}

@end
