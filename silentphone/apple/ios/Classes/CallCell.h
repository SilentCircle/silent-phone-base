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

#import <UIKit/UIKit.h>

#define _T_WO_GUI
#include "../../../baseclasses/CTEditBase.h"
@class CallCell;

/*
typedef struct{
   int iShowVerifySas;
   int iShowEnroll;
   int iShowWarningForNSec;
}T_CALL_DATA;
*/
 
int getCallInfo(int iCallID, const char *key, char *p, int iMax);


class CTCall{
   int iIsNameFromSipChecked;
public:
   CTCall(){iUserDataLoaded=0;img=nil;reset();}
   
   void reset(){
      //should be 
      if(img && (iUserDataLoaded==2 || iUserDataLoaded==4)){
        // 
         iUserDataLoaded=0;
         int rc=[img retainCount];
         //?? vajadzeetu buut iImgRetainCnt+1
         printf("[%p rc=%d %d]",img,rc,iImgRetainCnt);void freemem_to_log();freemem_to_log();
         for(int i=0;i<iImgRetainCnt;i++)
            [img release];
         img=nil;
         iImgRetainCnt=0;
         printf("[rel img ok]");freemem_to_log();
      }
      img=nil;


      nameFromAB.reset();
      zrtpWarning.reset();
      zrtpPEER.reset();
      iIsNameFromSipChecked=0;
      img=NULL;
      memset(bufDialed,0,sizeof(bufDialed));
      memset(bufServName,0,sizeof(bufServName));
      memset(bufPeer,0,sizeof(bufPeer));
      memset(bufMsg,0,sizeof(bufMsg));

      memset(bufSAS,0,sizeof(bufSAS));
      memset(bufSecureMsg,0,sizeof(bufSecureMsg));
      memset(bufSecureMsgV,0,sizeof(bufSecureMsgV));
      
      iShowVideoSrcWhenAudioIsSecure=0;
      
      uiStartTime=0;
      iInUse=0;
      iDuration=0;
      iIsIncoming=0;
      iActive=0;
      iEnded=0;
      iIsOnHold=0;
      iIsInConferece=0;
      iMuted=0;
      iSipHasErrorMessage=0;
      iRecentsUpdated=0;
      iUserDataLoaded=0;
      uiRelAt=0;
      iCallId=0;
      pEng=NULL;
      iImgRetainCnt=0;
      cell=NULL;
      
      iShowEnroll=iShowWarningForNSec=iShowVerifySas=0;
      

   }
   
   UIImage *img;//TODO void *userDataFromGui;
   CTEditBuf<128> zrtpWarning;
   CTEditBuf<128> zrtpPEER;
   CTEditBuf<128> nameFromAB;//or from sip
   
   int findSipName(){
      if(iIsNameFromSipChecked || nameFromAB.getLen())return 0;
      
      char bufRet3[128];
      int l=getCallInfo(iCallId,"peername", bufRet3,127);
      if(l>0){
         nameFromAB.setText(bufRet3,l);
      }
      iIsNameFromSipChecked=1;
      return 1;
   }
   
   
   inline int mustShowAnswerBT(){
      return iInUse && iIsIncoming && !iEnded && !iActive;
   }
   
   void setPeerName(const char *p, int iLen){
      if(!iInUse){
         NSLog(@"Err call !iInUse");
         return ;
      }
      if(!p){p="Err";iLen=3;}
      if(iLen==0)strlen(p);
      if(p && strncmp(p,"sip:",4)==0){p+=4;iLen-=4;}
      else if(p && strncmp(p,"sips:",5)==0){p+=5;iLen-=5;}
      
      safeStrCpy(&this->bufPeer[0],p,min(iLen,(sizeof(this->bufPeer)-1)));
      
   }
   
   int iShowEnroll,iShowVerifySas,iShowWarningForNSec;
   
   
   char bufDialed[128];
   char bufPeer[128];
   char bufServName[128];
   char bufMsg[512];
   char bufSAS[64];
   char bufSecureMsg[64];

   char bufSecureMsgV[64];
   
   int iInUse;
   
   unsigned int uiStartTime;
   int iDuration;
   int iTmpDur;
   
   int iIsIncoming;
   int iActive;
   int iEnded;
   int iIsOnHold;
   int iMuted;
   
   int iShowVideoSrcWhenAudioIsSecure;
   
   int iIsInConferece;
   
   int iSipHasErrorMessage;
   
   // int iReleased;
   int iRecentsUpdated;
   int iUserDataLoaded;
   
   unsigned int uiRelAt;
   
   int iCallId;//from eng
   void *pEng;
   
   
   int iImgRetainCnt;
   
   
   CallCell *cell;///tmp
};
#define T_MAX_CALLS 16

unsigned int getTickCount();

class CTCalls{
   int iLocked;
public:
   CTCall *curCall;
   enum{eConfCall, ePrivateCall, eStartupCall};
   
   void syncCallsWithEng(){
      //warn if probl deteced
   }
   
   CTCalls(){
   }
   ~CTCalls(){
      for(int i=0;i<T_MAX_CALLS;i++)calls[i].reset();
   }
   void lock(){
      int n=0;
      //TODO mutex
      while(iLocked>0){n++;usleep(1000);if(n>1000)break;}
      iLocked++;
   }
   void unLock(){
      iLocked--;
      if(iLocked<0){
         NSLog(@"c m err");
      }
   }
   
   void init(){
      iLocked=0;
      iCurrentCallID=0;
      for(int i=0;i<T_MAX_CALLS;i++)calls[i].reset();
      curCall=NULL;
   }
   void setCurCall(CTCall *c){
      curCall=c;
   }
   
   static inline int isCallType(CTCall *c, int iType){
      if(!c->iInUse || c->iRecentsUpdated || c->uiRelAt)return 0;
      if(iType==eConfCall && !c->iEnded && c->iActive && c->iIsInConferece)return 1;
      if(iType==ePrivateCall && !c->iEnded && c->iActive && !c->iIsInConferece)return 1;
      if(iType==eStartupCall && !c->iEnded && !c->iActive)return 1;
      return 0;
   }
   CTCall* getCall(int ofs){
      int n=0;
      for(int i=0;i<T_MAX_CALLS;i++){
         if(isCallType(&calls[i],eConfCall) || isCallType(&calls[i],ePrivateCall)){
            if(n==ofs)return &calls[i];
            n++;
         }
      }
      return  0;
   }
   
   CTCall* getCall(int iType, int ofs){
      int n=0;
      for(int i=0;i<T_MAX_CALLS;i++){
         if(isCallType(&calls[i],iType)){
            if(n==ofs)return &calls[i];
            n++;
         }
      }
      return  0;
   }

   int getCallCnt(int iType){
      int n=0;
      for(int i=0;i<T_MAX_CALLS;i++){
         if(isCallType(&calls[i],iType))n++;
      }
      return n;
   }   
  
   
   int getCallCnt(){
      int n=0;
      for(int i=0;i<T_MAX_CALLS;i++){
         if(calls[i].iInUse && !calls[i].iEnded && !calls[i].uiRelAt)n++;
      }
      if(!n)curCall=NULL;
     // if(n && !curCall)curCall=getLastCall();
      return n;
   }
   CTCall* getLastCall(){
      
      CTCall *c=NULL;
      for(int i=0;i<T_MAX_CALLS;i++){
         if(calls[i].iInUse && !calls[i].iEnded &&  !calls[i].uiRelAt){c=&calls[i];break;}
      }
      return c;
   }
   CTCall *getEmptyCall(int iIsMainThread){
      lock();
    //  if(iCurrentCallID>=)
      unsigned int ui=getTickCount();
      int rc=0;
    //  void freemem_to_log();
     // freemem_to_log();
      
      //if(iIsMainThread){
      for(int i=0;i<T_MAX_CALLS;i++){
         int d=((int)calls[i].uiRelAt-(int)ui);//loops ui>0xffff fffa
         if(d<0)d=-d;
         if(calls[i].iInUse && calls[i].uiRelAt && d>10000){
            if(iIsMainThread)calls[i].reset();
            calls[i].iInUse=0;calls[i].uiRelAt=0;
            rc++;
            //TODO rel img
         }
      }
   
      //freemem_to_log();
      if(iCurrentCallID>=T_MAX_CALLS)iCurrentCallID=T_MAX_CALLS;
      
      for(int i=iCurrentCallID;i<T_MAX_CALLS;i++){
         if(!calls[i].iInUse){
            calls[i].reset();
            calls[i].iInUse=1;
            iCurrentCallID=i+1;
            unLock();
            return &calls[i]; 
         }
         
      }
      for(int i=0;i<iCurrentCallID;i++){
         if(!calls[i].iInUse){
            calls[i].reset();
            calls[i].iInUse=1;
            iCurrentCallID=i+1;
            unLock();
            return &calls[i]; 
         }
      }
      for(int i=iCurrentCallID;i<T_MAX_CALLS;i++){
         if(!calls[i].iInUse){
            calls[i].reset();
            calls[i].iInUse=1;
            iCurrentCallID=i+1;
            unLock();
            return &calls[i]; 
         }
         
      }
      unLock();
      return NULL;
   }
   
   
   CTCall *findCallById(int iCallId){
      //curCall->reset();
      if(!iCallId)return NULL;
      
      int i;
      for(i=iCurrentCallID;i<T_MAX_CALLS;i++){
         if(calls[i].iInUse && iCallId==calls[i].iCallId && !calls[i].iEnded){
       //--     NSLog(@"found call [Aidx=%d]",i);
            return &calls[i];
         }
      }
      for(i=0;i<iCurrentCallID;i++){
         if(calls[i].iInUse && iCallId==calls[i].iCallId && !calls[i].iEnded){
       //--     NSLog(@"found call [Bidx=%d]",i);
            return &calls[i];
         }
      }
      for(i=0;i<T_MAX_CALLS;i++){
         //   NSLog(@"i=%d,%d %d",i,iCallId,calls[i].iCallId);
         if(calls[i].iInUse && iCallId==calls[i].iCallId){
          //--  NSLog(@"found call [Cidx=%d]",i);
            return &calls[i];
         }
      }
      return NULL;
   }
   
   
private:
   CTCall calls[T_MAX_CALLS];
   int iCurrentCallID;
   
};




@interface CallCell : UITableViewCell
@property CTCall *cTCall; 

@property (retain, nonatomic) IBOutlet UIButton *sas;
@property (retain, nonatomic) IBOutlet UILabel *lbZRTP;
@property (retain, nonatomic) IBOutlet UILabel *uiName;
@property (retain, nonatomic) IBOutlet UIButton *uiEndCallBt;
@property (retain, nonatomic) IBOutlet UIImageView *uiImg;
@property (retain, nonatomic) IBOutlet UIButton *uiAnswerBt;
@property (retain, nonatomic) IBOutlet UILabel *uiDstNr;
@property (retain, nonatomic) IBOutlet UIImageView *uiBacgrImg;



@end
