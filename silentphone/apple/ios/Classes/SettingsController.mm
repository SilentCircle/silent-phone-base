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

#import "SettingsController.h"
#import "UICellController.h"

CTSettingsItem *findSection(CTList *l, int section){
   CTSettingsItem *item=(CTSettingsItem*)l->getLRoot();
   while(item){
      // CTList *n=item->nextLevel();
      if(item->isSection()){
         if(!section){
            return item;
         }
         section--;
      }
      item=(CTSettingsItem*)l->getNext(item);
   }
   return NULL;
}

CTSettingsItem *findRItem(CTList *l, int row){
   CTSettingsItem *item;
   item=(CTSettingsItem*)l->getLRoot();
   while(item){
      if(!row){
         return item;
      }
      row--;
      item=(CTSettingsItem*)l->getNext(item);
   }
   return NULL;
}

CTSettingsItem *findSItem(CTList *l, NSIndexPath *indexPath){
   CTSettingsItem *item;
   item=findSection(l,indexPath.section);
   if(!item|| !item->root)return NULL;
   l=item->root;
   return findRItem(l,indexPath.row);
}

int countSections(CTList *l){
   return l->countVisItems();
}

int countItemsInSection(CTList *l, int section){
   CTSettingsItem *s=findSection(l,section);
   if(!s || !s->root)return 0;
   return s->root->countVisItems();
}



@implementation SettingsController

@synthesize   prevTView,chooseItem;

- (void)dealloc
{

	[nextView release];
	[super dealloc];
}

- (void)awakeFromNib
{	
	self.title = levelTitle;//@"Level 1";
}

-(void)setLevelTitle:(NSString*)name{
   levelTitle=name;
   self.title = name;
}

-(void)setList:(CTList *)newList{
   list=newList;
   [self.tableView reloadData];
   //   list=new CTList();
   //return list;
}


#pragma mark UIViewController delegates

- (void)viewDidLoad 
{
	[super viewDidLoad];
   iTView_was_visible=0;
   [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(keyboardWillShow:)
                                                name:UIKeyboardWillShowNotification
                                              object:nil];
   
   // Register notification when the keyboard will be hide
   [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(keyboardWillHide:)
                                                name:UIKeyboardWillHideNotification
                                              object:nil];  
   
}
- (void)viewDidDisappear:(BOOL)animated{
   iTView_was_visible=0;
}

- (void)viewWillAppear:(BOOL)animated
{
   iTView_was_visible=0;

}


#pragma mark UITableView delegates


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
   
   CTSettingsItem *i=findSection(list,section);
   if(!i)return @"Error";
   return i->sc.label?i->sc.label:@"";

}
/*
 - (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section;
 - (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section;
 */

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
   CTSettingsItem *i=findSItem(list,indexPath);
   
   return (i && i->sc.iType==CTSettingsCell::eReorder)?YES:NO;
   
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath{
   
   CTSettingsItem *src=findSItem(list,sourceIndexPath);
   if(!src)return;
   if(sourceIndexPath.section==destinationIndexPath.section){
      if(sourceIndexPath.row==destinationIndexPath.row)return;
      CTSettingsItem *s=findSection(list,destinationIndexPath.section);
      CTList *l=s->root;
      
      {
         int iAfter=destinationIndexPath.row;
         //if(iAfter>0)iAfter--;
         
         CTSettingsItem *after=findRItem(l,iAfter);
         if(after && destinationIndexPath.row<sourceIndexPath.row)after=(CTSettingsItem *)l->getPrev(after);
         
         l->remove(src,0);
         //  after=(CTSettingsItem *)l->findItem(after);
         if(destinationIndexPath.row==0){
            l->addToRoot(src);
         }
         else 
            if(!after){
               if(sourceIndexPath.row>destinationIndexPath.row)
                  l->addToRoot(src);
               else
                  l->addToTail(src);
               
            }
            else l->addAfter(after,src);
      }
      
      
   }
   else{
      CTList *l=src->parent;
      CTSettingsItem *dst=findSection(list,destinationIndexPath.section);
      if(!dst || !dst->root)return;
      CTList *dl=dst->root;

      CTSettingsItem *c=findSItem(list,destinationIndexPath);
   
      l->remove(src,0);
      if(c)c=(CTSettingsItem *)c->parent->getPrev(c);
      if(c){
        dl->addAfter(c, src);
      }
      else {
         if(destinationIndexPath.row>=dl->countVisItems()){
            dl->addToTail(src);
         }
         else dl->addToRoot(src);
      }
      src->parent=dl;
      
   }
}


- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
   return NO;
}
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
   return YES;//(indexPath.section==3)?NO:YES;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return countSections(list);//countItemsInSection;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return countItemsInSection(list,section);//[listContent count];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
   CTSettingsItem *i=findSItem(list,indexPath);
   if(!i)return;
   printf("[delete]");
   if(i->sc.onDelete){
      i->sc.onDelete(i,i->sc.pRetCB);
   }
   CTList *r=i->parent;
   if(r)
      r->remove(i);
   
   [tableView reloadData];
   printf("[del ok %p]",r);
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{

   CTSettingsItem *i=findSItem(list,indexPath);
   
   if(i && i->sc.iCanDelete){
      return UITableViewCellEditingStyleDelete;
   }
   return UITableViewCellEditingStyleNone;

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

	[tableView deselectRowAtIndexPath:indexPath animated:NO];
   
   CTSettingsItem *i=findSItem(list,indexPath);
   if(!i)return;
   selectedCell=(UICellController*)i->sc.pRet;
   
   if(i){
      if(i->sc.onChange){
         puts("onChange");
         i->sc.onChange(i,i->sc.pRetCB);
      }
      //TODO onClickMoveFromListToList
   }
   
   if(!i || !i->root){
      if(i && i->sc.iType==CTSettingsCell::eButton){
         [i->sc.value release];
         i->sc.value=[[NSString alloc ] initWithString:@"1"];
         return;
      }
      else if(i && i->sc.iType==CTSettingsCell::eRadioItem){
         UICellController *c=(UICellController*)i->sc.pRet;
         c.accessoryType =UITableViewCellAccessoryCheckmark;
        // i->select(
         UICellController *cell=(UICellController *)chooseItem->sc.pRet;
         [cell.detailTextLabel setText:i->sc.label];
         [[self navigationController] popViewControllerAnimated:YES];

         chooseItem->sc.value =[i->sc.label copy];
      }
      return;
   }
   
   
   nextView=[[SettingsController alloc]initWithStyle:UITableViewStyleGrouped];
   nextView.prevTView=tableView;
   nextView.chooseItem=i;
   [nextView setList:i->root];
   [nextView setLevelTitle:i->sc.label];
   if(i->sc.iType==CTSettingsCell::eCodec)
     [nextView setEditing:YES];
   /*   
    CTX c;
    c.sc=self;
    c.c();
    */ 
	[[self navigationController] pushViewController:nextView animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
   
   CTSettingsItem *i=findSItem(list,indexPath);
//   myTableView=tableView;
   iTView_was_visible=1;
   
   static NSString *kCellIdentifier=@"c1";
   static NSString *kCellIdentifierE=@"c1E";
   static NSString *kCellIdentifierSw=@"c1Sw";
   static NSString *kCellIdentifierC=@"c1Codec";
   
   NSString *c=kCellIdentifier;
   UITableViewCellStyle s=UITableViewCellStyleValue1;
   
   switch(i->sc.iType){
      case CTSettingsCell::eReorder:
         c=kCellIdentifierC;
         break;
      case CTSettingsCell::eOnOff:
         c=kCellIdentifierSw;
         break;
      case CTSettingsCell::eSecure:
      case CTSettingsCell::eEditBox:
      case CTSettingsCell::eInt:
         c=kCellIdentifierE;
         break;
   }
   
	UICellController *cell = [tableView dequeueReusableCellWithIdentifier:c];
   
	if (cell == nil)
	{
		cell = [[[UICellController alloc] initWithStyle:s reuseIdentifier:c] autorelease];
      if(i->sc.iType==CTSettingsCell::eOnOff){

         int swW=27;// ????? 
          
         CGRect r=CGRectMake(215,(44-swW)/2, 0, 0);
         cell.uiSwitch=[[UISwitch alloc] initWithFrame:r];// cell.bounds];
         cell.uiSwitch.center=CGPointMake(cell.bounds.size.width-cell.uiSwitch.frame.size.width/2-25,cell.center.y);
         cell.uiSwitch.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;

         [cell.contentView addSubview:cell.uiSwitch];
         
         [cell.uiSwitch release];
         
         
      }
      else if(i->sc.iType==CTSettingsCell::eEditBox || i->sc.iType==CTSettingsCell::eInt || i->sc.iType==CTSettingsCell::eSecure){
         UICellController *xCell = cell;
         
         UITextField *textField = [[UITextField alloc] init];
         xCell.textField=textField;

         textField.tag = (int)i ;//+ indexPath.row;
         // Add general UITextAttributes if necessary
         textField.returnKeyType=UIReturnKeyDone;
         textField.enablesReturnKeyAutomatically = NO;
         textField.autocorrectionType = UITextAutocorrectionTypeNo;
         textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
         //[textField setText:@"x"];
         [xCell.contentView addSubview:textField];
         [textField release];
         cell=xCell;
         //textField.frame=cell.detailTextLabel.frame;
      }
  	}
   cell.detailTextLabel.text=nil;
   

   if(i->root && (i->sc.iType==CTSettingsCell::eNextLevel || i->sc.iType==CTSettingsCell::eChoose || i->sc.iType==CTSettingsCell::eCodec) ){
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
   }
   else if(i->sc.iType==CTSettingsCell::eRadioItem){
      if(chooseItem && [chooseItem->sc.value isEqualToString :i->sc.label])
         cell.accessoryType =UITableViewCellAccessoryCheckmark;
   }
   cell.showsReorderControl=YES;
   cell.selectionStyle= UITableViewCellSelectionStyleNone;
  // cell.vi
   //tableView.allowsSelection=NO;
   [cell setSI:i newTW:tableView];
   
   switch(i->sc.iType){
      case CTSettingsCell::eButton:
         cell.selectionStyle= UITableViewCellSelectionStyleBlue;
         break;
         
      case CTSettingsCell::eRadioItem:
      case CTSettingsCell::eReorder:
         break;
    
         
      case CTSettingsCell::eOnOff:
         cell.uiSwitch.tag=(int)i;
         
         [cell.uiSwitch setOn:i->getValue()[0]!='0'];
         [cell.uiSwitch addTarget:self action:@selector(onOnOffChage:) forControlEvents:UIControlEventValueChanged];

        // cell.uiSwitch.frame=CGRectMake(0.f,0.f,44.f,320.f);
         
         break;
      case CTSettingsCell::eInt:
         cell.textField.keyboardType = UIKeyboardTypeNumberPad;
      case CTSettingsCell::eSecure:
         if(i->sc.iType==CTSettingsCell::eSecure){
            cell.textField.keyboardType = UIKeyboardTypeDefault;
            cell.textField.secureTextEntry=YES;
         }
      case CTSettingsCell::eEditBox:
         if(i->sc.iType==CTSettingsCell::eEditBox){
            cell.textField.keyboardType = UIKeyboardTypeDefault;
         }
         if(i->sc.iType!=CTSettingsCell::eSecure){
            cell.textField.secureTextEntry=NO;
         }
         [self configureCellE:cell atIndexPath:indexPath];

         if(i->sc.value)[cell.textField  setText:i->sc.value];
         
         cell.textField.tag=(int)i;
         break;


   }
   i->sc.pRet=cell;
   if(i->sc.iType==CTSettingsCell::eNextLevel || i->sc.iType==CTSettingsCell::eChoose || i->sc.iType==CTSettingsCell::eCodec){
      if(i->sc.value)cell.detailTextLabel.text=i->sc.value;
   }
   else if(cell.detailTextLabel)cell.detailTextLabel.text=@"";
	

	cell.textLabel.text = i->sc.label?i->sc.label:@"Err";
   
	return cell;
}
/*
- (void) textFieldDidBeginEditing:(UITextField *)textField {
   UITableViewCell *cell = selectedCell;//(UITableViewCell*) [[textField superview] superview];
   [myTableView scrollToRowAtIndexPath:[myTableView indexPathForCell:cell] atScrollPosition:UITableViewScrollPositionTop animated:YES];
   [UIView commitAnimations];
}
 */
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
   
   if(activeTF){
      UITouch *touch = [[event allTouches] anyObject];
      if ([activeTF isFirstResponder] && [touch view] != activeTF) {
         [activeTF resignFirstResponder];
      }
   }
   [super touchesBegan:touches withEvent:event];
}

- (IBAction)textFieldDidBeginEditing:(UITextField *)textField
{
   activeTF = textField;
}

-(IBAction)onOnOffChage:(id)v{
   UISwitch *sw=(UISwitch*)v;
   CTSettingsItem *i=(CTSettingsItem *)sw.tag;
   if(i){
      i->setValue([sw isOn]?"1":"0");
   }
}

- (IBAction)textFieldDidEndEditing:(UITextField *)textField
{

   [textField resignFirstResponder];
   activeTF=NULL;
   CTSettingsItem *i=(CTSettingsItem *)textField.tag;
   if(i && i->sc.pRet){
      UICellController *r=(UICellController*)i->sc.pRet;
      if(r->textField == textField){
        [i->sc.value release];
      
        i->sc.value=[[textField text]copy];
         //show save
      }
      else {NSLog(@"ch uitf");}
   }
 //  selectedCell->item->sc.value=[textField text];
   //self.actifText = nil;
}


-(void) keyboardWillShow:(NSNotification *)note
{
   // Get the keyboard size
   if(iTView_was_visible!=1)return;
   
  // if(!tableView)return ;
   CGRect keyboardBounds;
   [[note.userInfo valueForKey:UIKeyboardFrameBeginUserInfoKey] getValue: &keyboardBounds];
   
   // Detect orientation
   UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
   CGRect frame = self.tableView.frame;
   
   // Start animation
   [UIView beginAnimations:nil context:NULL];
   [UIView setAnimationBeginsFromCurrentState:YES];
   [UIView setAnimationDuration:0.3f];
   
   // Reduce size of the Table view 
   if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
      frame.size.height -= keyboardBounds.size.height;
   else 
      frame.size.height -= keyboardBounds.size.width;
   
   // Apply new size of table view
   self.tableView.frame = frame;
   
   // Scroll the table view to see the TextField just above the keyboard
   if (activeTF)
   {
      CGRect textFieldRect = [self.tableView convertRect:activeTF.bounds fromView:activeTF];
      [self.tableView scrollRectToVisible:textFieldRect animated:NO];
   }
   
   [UIView commitAnimations];
}

-(void) keyboardWillHide:(NSNotification *)note
{
   // Get the keyboard size
   if(!self.tableView)return ;
   if(iTView_was_visible!=1)return;
   CGRect keyboardBounds;
   [[note.userInfo valueForKey:UIKeyboardFrameBeginUserInfoKey] getValue: &keyboardBounds];
   
   // Detect orientation
   UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
   CGRect frame = self.tableView.frame;
   
   [UIView beginAnimations:nil context:NULL];
   [UIView setAnimationBeginsFromCurrentState:YES];
   [UIView setAnimationDuration:0.3f];
   
   // Reduce size of the Table view 
   if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
      frame.size.height += keyboardBounds.size.height;
   else 
      frame.size.height += keyboardBounds.size.width;
   
   self.tableView.frame = frame;
   
   [UIView commitAnimations];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
   [textField resignFirstResponder];
   return YES;
}
-(IBAction)textFieldReturn:(id)sender
{
   activeTF=NULL;
   [sender resignFirstResponder];
} 


- (void)configureCellE:(UICellController *)theCell atIndexPath:(NSIndexPath *)indexPath {

   UITextField *textField =theCell.textField;
   // Position the text field within the cell bounds
   CGRect cellBounds = theCell.bounds;//bounds;
   CGFloat ch=CGRectGetHeight(cellBounds);
   CGFloat cw=CGRectGetWidth(cellBounds);
   
   CGRect aRect2 = CGRectMake(cw*.3f,0,cw*.65-10,ch);
   
   textField.frame = aRect2;
   textField.textAlignment=UITextAlignmentRight;
   textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
   
   [textField setDelegate:self];
   
}



- (void)viewDidAppear:(BOOL)animated
{
   [super viewDidAppear:animated];
   iTView_was_visible=1;

}

@end



