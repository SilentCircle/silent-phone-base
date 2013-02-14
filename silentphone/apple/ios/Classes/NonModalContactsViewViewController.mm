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

#import "NonModalContactsViewViewController.h"
#import "AppDelegate.h"




NSString *abMultiValueIdentifier2Phone(ABMultiValueRef phoneNumbers, ABMultiValueIdentifier id){
   
   int iPhCnt=0;
   if(phoneNumbers)iPhCnt=ABMultiValueGetCount(phoneNumbers);
   
   for(int i=0;i<iPhCnt;i++){
      CFIndex index=ABMultiValueGetIdentifierAtIndex(phoneNumbers,i);
      if(index==id){
         return   (__bridge_transfer NSString*)
         ABMultiValueCopyValueAtIndex(phoneNumbers, i);
      }
   }
   return nil;
}

@interface NonModalContacts ()

@end

@implementation NonModalContacts

#if 1
- (void)awakeFromNib{
   picker=nil;
   
}
- (void)viewDidLoad{


   [super viewDidLoad];

   static int xx=0;
   if(xx && !picker)return;
   xx=1;
   picker = [[ABPeoplePickerNavigationController alloc] init];
   
   picker.peoplePickerDelegate=self;
   
   //--picker.allowsCancel = NO;
 //  picker.allowsCardEditing = NO;//YES;   
   
   picker.hidesBottomBarWhenPushed=YES;
   self.hidesBottomBarWhenPushed=YES;
   
   picker.navigationController.delegate=self;
   self.navigationController.delegate=self;
   picker.navigationController.hidesBottomBarWhenPushed=YES;
   
   [picker setHidesBottomBarWhenPushed:YES];
   

   [picker.view setAutoresizesSubviews:YES];

   [c_view addSubview:picker.view];


}

#endif
-(void)viewWillAppear:(BOOL)animated{
   [super viewWillAppear:animated];
   

}
- (void)viewDidAppear:(BOOL)animated{
   
   [super viewDidAppear:animated];
   picker.view.frame=CGRectMake(0,0,picker.view.frame.size.width,480-20-48);
}

- (void)viewDidUnload
{
    [super viewDidUnload];
   [picker release];
   picker=nil;
    // Release any retained subviews of the main view.
   
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker{
   [[self tabBarController]setSelectedIndex:3];//show dialpad
}

// Called after a person has been selected by the user.
// Return YES if you want the person to be displayed.
// Return NO  to do nothing (the delegate is responsible for dismissing the peoplePicker).
-(BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person{
   
   self.hidesBottomBarWhenPushed=YES;
   self.navigationController.hidesBottomBarWhenPushed=YES;
   picker.hidesBottomBarWhenPushed=YES;
   picker.navigationController.hidesBottomBarWhenPushed=YES;
   return YES;
}
// Called after a value has been selected by the user.
// Return YES if you want default action to be performed.
// Return NO to do nothing (the delegate is responsible for dismissing the peoplePicker).

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier{
   
   
   if(property!=kABPersonPhoneProperty && property!=kABPersonURLProperty)return NO;
   
   if( property==kABPersonEmailProperty){}
    
   NSLog(@"selected user contact data %d %d", property,kABPersonEmailProperty);
   
   NSString* phone = nil;
   ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, property);
   
   phone=abMultiValueIdentifier2Phone(phoneNumbers,identifier);

   if(!phone) {
      if(phoneNumbers)CFRelease(phoneNumbers);
      return NO;
   }
   if(phone){
      //[nr setText:phone];
      [appDelegate callTo:'c' dst:[phone UTF8String]];
      
      //--[peoplePicker popViewControllerAnimated:NO];
      //--[[self tabBarController]setSelectedIndex:3];
      
      CFRelease(phone);
   }
   CFRelease(phoneNumbers);
   //if(phone)CFRelease(phone);
   
   return NO;
}


- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
   picker.peoplePickerDelegate=self;
   viewController.hidesBottomBarWhenPushed=YES;
   navigationController.hidesBottomBarWhenPushed=YES;
   picker.hidesBottomBarWhenPushed=YES;

   
}
- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated{
   picker.peoplePickerDelegate=self;
   viewController.hidesBottomBarWhenPushed=YES;
   navigationController.hidesBottomBarWhenPushed=YES;
   picker.hidesBottomBarWhenPushed=YES;
   
   
}

@end
