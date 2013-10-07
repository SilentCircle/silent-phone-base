/*
Created by Janis Narbuts
Copyright © 2004-2012 Tivi LTD,www.tiviphone.com. All rights reserved.
Copyright © 2012-2013, Silent Circle, LLC.  All rights reserved.

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


#ifndef _C_TIVI_SES_H
#define _C_TIVI_SES_H 


#include "main.h"
#include "../sipparser/client/CTSip.h"

#include "CTSipSock.h"

#include "../os/CTThread.h"
#include "../os/CTMutex.h"


#include "../baseclasses/CTEditBase.h"
#include "CTLangStrings.h"

#include "../stun/CTStun.h"
#include "../utils/CTNetwCheck.h"

unsigned int getTickCount();

#include "CTPhMediaBase.h"

typedef struct _STORAGE {
   int  offset;//bytes in buf
   char rawData[DATA_SIZE];
} STORAGE;

typedef struct{
   int iRetransmitAuthAdded;
   int iRetransmitPeriod;
   int iRetransmitions;
   int iFirstPackPeriod;//gprs hack
   int iContentAdded;
   int iContentLen;
   
   t_ph_tick uiNextRetransmit;
   
   char *pContent;
   const char *pContentType;
   
   int iIsTCPorTLS;
   STORAGE data;
   void stopRetransmit()
   {
      iRetransmitions=0;
      uiNextRetransmit=0;
   }
   inline void setPeriod(int i)
   {
      if(i<T_GT_HSECOND)i=T_GT_HSECOND;else if(i>12*T_GT_SECOND)i=12*T_GT_SECOND;
      iRetransmitPeriod=i;

   }
   inline void setRetransmit(int iCnt=5,int iStartPeriod=0)
   {
      iIsTCPorTLS=0;
      stopRetransmit();
      if(iCnt>10 || iCnt<2)iCnt=5;

      iRetransmitions=iCnt;
#ifdef __SYMBIAN32__ 
      if(iStartPeriod==0)
         iStartPeriod=T_GT_SECOND;//TODO if prev sent pack less than 4 sec
#else
      if(iStartPeriod==0)
         iStartPeriod=T_GT_HSECOND;
#endif
      iFirstPackPeriod=iStartPeriod;
      if(iStartPeriod>6*T_GT_SECOND)iStartPeriod=6*T_GT_SECOND;
      iRetransmitPeriod=iStartPeriod/2;
      if(iRetransmitPeriod<T_GT_HSECOND)iRetransmitPeriod=T_GT_HSECOND;
      setPeriod(iRetransmitPeriod);
      
   }
   inline void updateRetransmit(t_ph_tick uiGT)
   {
      if(iIsTCPorTLS){
         uiNextRetransmit=uiGT+T_GT_SECOND*4;
         iRetransmitPeriod=T_GT_SECOND*6;
      }
      else if(iFirstPackPeriod)
         {uiNextRetransmit=uiGT+(unsigned int)iFirstPackPeriod;iFirstPackPeriod=0;}
      else 
         uiNextRetransmit=uiGT+(unsigned int)iRetransmitPeriod;
     
      setPeriod(iRetransmitPeriod*2);
      iRetransmitions--;
   }
}SEND_TO;


#define T_CHAT_PHONE

class CHAT_MSG{
public:
   enum ECHAT_TYPE {EUtf8=1, EUtf16};
   CHAT_MSG(CTStrBase *e=NULL)
   {
      memset(this,0,sizeof(*this));
      if(e)
      {
         strMsg.p=(char*)e->getText();
         strMsg.iLen=e->getLen()*2;
         strMsg.eType=EUtf16;
      }
   }
   ~CHAT_MSG(){}
   inline int msgHasCRLF()
   {
      return(strMsg.p && *strMsg.p=='\r');
   }
   
   struct{
      int iLen;
      char *p;
   }strUN;
   
   struct{
      int iLen;
      char *p;
      ECHAT_TYPE eType;//1 utf8, 2utf16
   }strMsg;
   
};

//used only for chat
typedef struct{ //TODO class
   
   int iRet;
   int iUseContact;
   int iErrorTransm;
   
   STR_T<128> str128CID;
   STR_T<128> str128AddrFromTo;
   STR_T<128> str128Contact;
   STR_T<128> str128CallTo;
   STR_T<256> str256RouteList;
   ADDR addrRec;
   
}MSG_CTX;


void tivi_log(const char* format, ...);

class CTEngineCallBack: public CTSockCB{
   
public:
#ifdef __SYMBIAN32__
   CTEngineCallBack(RSocketServ &iSocketServ, RConnection &rConn, int &iMustRecreateSockets)
      :CTSockCB(iSocketServ, rConn,iMustRecreateSockets)
#else
   CTEngineCallBack()
#endif
   {

      memset(&p_cfg,0,sizeof(PHONE_CFG));
      p_cfg.setDefaults();

      mediaFinder=NULL;
      iEngineIndex=0;

   }
   enum{eInfo, eErrorAndOffline, eOffline, eOnline, eConnecting};
   
   virtual  ~CTEngineCallBack(){};//{if(mediaFinder)delete mediaFinder;mediaFinder=NULL;}
   virtual int message(CHAT_MSG *msg, int iType, int SesId, char *from, int iFromLen)=0;//or fnc ptr

   virtual int info(CTStrBase *e, int iType, int SesId)=0;
   virtual int registrationInfo(CTStrBase *e, int iType)=0;
   virtual int onIncomCall(ADDR *addr, char *sz, int iLen, int SesId)=0;
   virtual int onCalling(ADDR *addr, char *sz, int iLen, int SesId)=0;
   virtual int onStartCall(int SesId)=0;//when 200 ok rec or answer call

   virtual int onNewBalance(char *pVaule, int iValLen, char *pCurency, int iCLen){return -1;}
   virtual int onSip(SIP_MSG *sMsg){return -1;}

   virtual int onContent(char *pContent, int iContentLen, char *contType, int iLen , int SesId, int iMethId){return -1;}


   virtual int onRecMsg(int id, int SesId, char *sz, int iLen)=0;
   virtual int onEndCall(int SesId)=0;
   virtual void onTimer(){}
   virtual void dbg(char *p, int iLen){}

   virtual int getLocalIp()=0;
   virtual int getLocalIpNow(){
      return getLocalIp();
   }
   virtual int getIpByHost(char *sz, int iLen)=0;
   
   virtual int onSdpMedia(int SesId, const char *media)=0;

   virtual int canAccept(ADDR *addr, char *sz, int iLen, int iSesId, CTSesMediaBase **media)=0;
   virtual CTSesMediaBase* tryGetMedia(const char *name)=0;


   CTMediaBase *mediaFinder;

   PHONE_CFG p_cfg;
   
   int iEngineIndex;
};


static int timeDiff(unsigned int uiCmp, unsigned int uiNow){
   int d = (int)(uiNow-uiCmp);
   return d;
}



typedef struct {

   void clear(CSessionsBase *sb,int iFirstTime=0)
   {
      if(!iFirstTime && pMediaIDS && pMediaIDS->pOwner==this){
         void releaseMediaIDS(CSessionsBase *sb, CTMediaIDS *p, void *pThis);
         releaseMediaIDS(sb,pMediaIDS,this);
      }
      memset(this,0,sizeof(*this));
   }

   inline int isSesActive()
   {
      CTSesMediaBase *m=mBase;//MUST use m , mBase can be set to NULL, but destroyed later
      return cs.iBusy && m && m->isSesActive() && (cs.iCallStat!=CALL_STAT::EEnding);
   }

   inline int isSession()
   {
      return iIsSession;//(int)mBase;//iIsSession;
   }

   int destroy()
   {
      puts("destroy ses");
    
      cs.iSendS=0;
      cs.iWaitS=0;
      if(uiClearMemAt==0)uiClearMemAt=1;
      cs.iCallStat=CALL_STAT::EEnding;

      return 0;//cSock.
   }

   inline int canDestroy(){return 1;}
   
   int getInfo(const char *key, char *p, int iMax){
      
      p[0]=0;
      if(!cs.iBusy || uiClearMemAt || cs.iCallStat==CALL_STAT::EEnding)return 0;
      // ?? use "sip." prefix
      if(strcmp(key,"peername")==0){
         
         HDR_TO_FROM *tf=&sSIPMsg.hdrTo;
         
         if((tf->dstrTag.uiLen==0  ||  cs.iCallSubStat==cs.EWaitUserAnswer) ||
            (str16Tag.uiLen==tf->dstrTag.uiLen && strncmp(str16Tag.strVal,tf->dstrTag.strVal, str16Tag.uiLen)==0)){
            tf=&sSIPMsg.hdrFrom;
         }
         
         if(!tf->dstrName.uiLen)return 0;
       
         return snprintf(p,iMax,"%.*s",tf->dstrName.uiLen,tf->dstrName.strVal);
      }
      return 0;
   }

   CALL_STAT cs; 
 
   int iKillCalled;
   int iIsSession;
   
 //  int iIsInConference; - moved to cs
   
 //  int iMediaType;//from media base
   void setMBase(CTSesMediaBase *m){
   //   iMediaType=m?m->getMediaType():0;
      if(m){
         m->setBaseData(pMediaIDS?pMediaIDS->pzrtp:NULL,&cs,pMediaIDS);
      }
      if(pMediaIDS)pMediaIDS->pOwner=this;
      iIsSession=1;
      mBase=m;
      
   }
   void stopMediaIDS(){
      if(pMediaIDS)pMediaIDS->stop();
   }
   CTMediaIDS *pMediaIDS;
   CTSesMediaBase *mBase;//private
   
   t_ph_tick uiClearMemAt;
   
   //todo keepalive ses
   //todo reg ses

   SIP_MSG sSIPMsg;
	
   STR_T<16> str16Tag;
   STR_T<128> dstSipAddr,userSipAddr;
	
   ADDR dstConAddr;
	
   STR_64 *pIPVisble;
   STR_64 *pIPLocal;
   
   SEND_TO sSendTo;
   
   unsigned int uiUserVisibleSipPort;

   int iSessionStopedByCaller;
   int iReturnParam;

   int iDoAnswerCall;
   int iDoEndCall;
   int iCallingAccept;
   int iOnEndCalled;
   int iOnIncmingCalled;

   int iDestIsNotInSameNet;
   int iRespReceived;
   int iSendingReinvite;
   
   unsigned int uiSipCseq;
   
  // unsigned int uiSend480At;//if not answered, dont use if os can suspend
   unsigned int uiSend480AfterTicks;//if not answered
   

   int iStopReasonSet;
   int *ptrResp;//must be static //  static int v=0; ses->ptrResp=&v;
   CTEditBase *retMsg;
   
   int iReceivedVideoSDP;

}CSesBase;

CSesBase *g_getSesByCallID(int iCallID);

static int getUniqueIDBySes(CSesBase *ses){
   unsigned long long ret = (unsigned long long)ses;
   
   ret >>= 10;// sizeof(CSesBase) is more than 1K, then it is safe to shift. 
   ret &= 0x7fffffff; // we need 32bit positive.
   return (int)ret;
}



class CTKeepAlive{ //udp only
   CTSipSock &sc;
   
   ADDR &addrTo;
   ADDR &addrExt;

   int &ipBinded;
   t_ph_tick &uiGT;
   
   t_ph_tick uiNextSendKaAt;
   int iInitInterval;
   int iMaxDetectedInterval;
   int iIntervalToUse;
   int iBytesSent;
   int iIntervalDetected;
   int iPrevInterval;
   int iCanIncrese;
   int iKASendOk;
   int iSendEverySec;
   
   typedef struct{
      int id;
      unsigned int ip;
      unsigned short portNF;
      char buf[10];
   }TKEEP_ALIVE;
   
   TKEEP_ALIVE ka;

public:
   enum{
      eKaFreqStep=1*T_GT_SECOND,
      eDefaultKaFreq=20*T_GT_SECOND,
      eMinKaFreq=3*T_GT_SECOND,
      eMaxKaFreq=50*T_GT_SECOND,
      eNoNatSymbKaFreq=80*T_GT_SECOND
   };
   int iKACounter;
   CTKeepAlive(CTSipSock &sc,ADDR &addrTo, ADDR &addrExt,int &ipBinded, t_ph_tick &uiGT, int iInterval=0)
      :sc(sc),addrTo(addrTo),addrExt(addrExt),ipBinded(ipBinded),uiGT(uiGT),iInitInterval(iInterval),iIntervalToUse(eDefaultKaFreq)
   {
      iSendEverySec=0;
      iKASendOk++;
      reset(); 
      
   }
   void setInitInerval(int iNew){iInitInterval=iNew;iIntervalDetected=1;}
   inline int getInterval()
   {
      return iIntervalToUse;
   }
   void reset()
   {
      iCanIncrese=1;
      iIntervalDetected=0;
      iKACounter=0;
      iBytesSent=0;
      iMaxDetectedInterval=0;
      uiNextSendKaAt=1;
      iPrevInterval=iIntervalToUse=(iInitInterval==0) ? eDefaultKaFreq : iInitInterval;

   }
   inline void update()
   {
      if(!hasNat() && iInitInterval==0)iIntervalToUse=eNoNatSymbKaFreq;
      else  if(isNatIP(addrExt.ip))iIntervalToUse=eDefaultKaFreq;
      if(sc.isTCP())
         uiNextSendKaAt=uiGT+(unsigned int)eDefaultKaFreq*5;
      else 
         uiNextSendKaAt=uiGT+(unsigned int)iIntervalToUse;
   }
   int iKAEverySecCnt;
   void sendEverySec(int iTrue)
   {
      iSendEverySec=iTrue;
   }

   void onTimer()
   {
      if(iSendEverySec)
      {
         iKAEverySecCnt++;
         if(iKAEverySecCnt&1)
            sendNow();
      }
      else if(uiNextSendKaAt<uiGT)
      {
         
         sendNow();
         iKASendOk++;
         if(!iIntervalDetected && iInitInterval==0)// && iCanIncrese)
         {
            
            
            if(iCanIncrese)
            {
               iPrevInterval=iIntervalToUse-1000;
               int inc=(eMaxKaFreq-iIntervalToUse)/15;
               if (inc<eKaFreqStep)inc=eKaFreqStep;
               iIntervalToUse+=inc;//=(iIntervalToUse+eMaxKaFreq)/4;
            }
            else if(iKASendOk>20)//TODO check ??????????
            {
               iPrevInterval=iIntervalToUse-1000;
               iIntervalToUse+=200;
            }

            if(iIntervalToUse>eMaxKaFreq)iIntervalToUse=eMaxKaFreq;else if(iIntervalToUse<eMinKaFreq) iIntervalToUse=eMinKaFreq;
            update();
         }
         
         //sendka
      }
   }
   inline void sendNow()
   {

      iKACounter++;
      update();
      ka.id=0;
      ka.ip=addrExt.ip;
      ka.portNF=addrExt.getPortNF();
      sc.sendTo((char*)&ka,10,&addrTo);
      
   }

   ADDR addrNew;
   inline int hasNat(){return ipBinded!=addrExt.ip || isNatIP(ipBinded);}

   int onResp(ADDR &from, char *buf, int iLen)
   {
      if(iLen!=10)return 0;
      if(from!=addrTo)return 0;
      
      addrNew.ip=(*(int*)(buf+4));
      addrNew.setPortNF(*(unsigned short *)(buf+8));

      if(addrExt.ip && iInitInterval==0)
      {
         if(addrExt!=addrNew)
         {
            
            iCanIncrese=0;
            iMaxDetectedInterval=iIntervalToUse;
            //iPrevInterval-=1000;
            iIntervalToUse=iPrevInterval;
            if(iKASendOk<5) iPrevInterval-=T_GT_SECOND*5;
            else if(iKASendOk<20)iPrevInterval-=T_GT_SECOND;
            iKASendOk=0;
            iIntervalDetected=1;
            if(iIntervalToUse>eMaxKaFreq)iIntervalToUse=eMaxKaFreq;else if(iIntervalToUse<eMinKaFreq) iIntervalToUse=eMinKaFreq;
            if(uiGT+(unsigned int)iIntervalToUse<uiNextSendKaAt)
               update();
         }

      }

      return 1;
   }

};

class CTReinviteMonitor{
   t_ph_tick uiReinviteAt;
   int iNewIP;
   int iNewExtIP;
public:
   CTReinviteMonitor(){reset();}
   void reset(){iNewIP=0;uiReinviteAt=0;}
   void onNewIP(){iNewIP=1;}
   void onNewExtIP(){iNewExtIP=1;}
   void onOnline(t_ph_tick *now){
      if((iNewIP|iNewExtIP) && now){
         uiReinviteAt=*now+2*T_GT_SECOND;
         iNewExtIP=iNewIP=0;
      }
   }
   int mustReinvite(t_ph_tick *now){
      t_ph_tick _now=*now;
      if(!uiReinviteAt)return 0;
      if(_now>=uiReinviteAt){
         uiReinviteAt=0;
         iNewIP=0;
         iNewExtIP=0;
         return 1;
      }
      return 0;
   }
};

class CPhSesions :  public CSessionsBase{
   
   unsigned int uiRegistarationCallIdRandom[2];

   
protected:
   int iMaxSesions;

   int iIsClosing;
   int iOptionsSent;
   
   int iCanCheckStunIP;
   
   t_ph_tick uiNextRegTry;
   
   int iRegTryParam;
   
   CTCheckNetwork port53Check;

   t_ph_tick uiSIPKeepaliveSentAt,uiSuspendRegistrationUntil,uiPrevCheckGWAt,uiCheckNetworkTypeAt;
   
   CTReinviteMonitor reinviteMonitor;
   
   void notifyIncomingCall(CSesBase *spSes);
   
public:
   CTLangStrings &strings;
   int iBytesSent;
   int iBytesRec;

   void *pTransMsgList;

   int iActiveCallCnt;
   


   CTThread threadSip;

   ADDR extNewAddr;
   ADDR addrPx;
   ADDR addrGWOld;

   CTEngineCallBack *cPhoneCallback;//ADD tobase
   
   CTSipSock sockSip;
   CTKeepAlive keepAlive;
   
   STR_64 str64BindedAddr;
   STR_64 str64ExternalAddr;
   
   CSip cSip;
   
   CTMutex cMutexSip;
 
   CSesBase *getRoot(){return pSessionArray;}
   
   CSesBase* isValidSes(CSesBase *ses){
      if(!ses)return NULL;
      for(int i=0;i<iMaxSesions;i++)
      {
         if(&pSessionArray[i]==ses)return ses;
      }
      return NULL;
   }
   
   CSesBase *findSessionByID(int id){
      if(!id)return NULL;
      for(int i=0;i<iMaxSesions;i++)
      {
         if((int)&pSessionArray[i]==id)return &pSessionArray[i];
      }
      return NULL;
   }
   int sdpRec(SIP_MSG *sMsg,CSesBase *spSes);
   
   CSesBase *findSessionByZRTP(CTZRTP *z);
   CTAudioOutBase *findSessionAO(CSesBase *ses);
   CTZRTP *findSessionZRTP(CSesBase *ses);
   
   void onDataSend(char *buf, int iLen, unsigned int uiPos,int iDataType, int iIsVoice);

   STR_128 *getDstAddrBySSRC(unsigned int ssrc);
   STR_128 *getDstAddrByPACK(char *p, int iLen);
   int getCallCnt(){
      int n=0;
      for(int i=0;i<iMaxSesions;i++)
      {
         if(!pSessionArray[i].cs.iBusy)continue;
         if(!pSessionArray[i].isSession() || pSessionArray[i].cs.iCallStat==pSessionArray[i].cs.EEnding)continue;
         n++;
         
      }
      return 0;
   }
   
   int isSecondIncomingCallFromSameUser(SIP_MSG *sMsg){
      int i;
    //  return 0;
      
      CSesBase *spSes=NULL;
      for(i=0;i<iMaxSesions;i++)
      {
         if(!pSessionArray[i].cs.iBusy)continue;
          spSes=&pSessionArray[i];
         
         if(spSes->cs.iCallSubStat!=CALL_STAT::EWaitUserAnswer)continue;
         if(sMsg->sipHdr.uiMethodID!=METHOD_INVITE)continue;
         
         if(sMsg->hdrFrom.sipUri.dstrUserName.uiLen!=spSes->sSIPMsg.hdrFrom.sipUri.dstrUserName.uiLen)continue;
         
         if(memcmp(sMsg->hdrFrom.sipUri.dstrUserName.strVal,
                   spSes->sSIPMsg.hdrFrom.sipUri.dstrUserName.strVal,sMsg->hdrFrom.sipUri.dstrUserName.uiLen))continue;
         
         return 1;
         
      }
      return 0;
   }

   CSesBase *findSes(char *pCID, int iCIDLen, char *pTag, int iTagLen, ADDR *addr, int iUseTag)
   {
      int i=0;
      CSesBase *spSes=NULL;
      if(pSessionArray==NULL)return NULL;
//      spSes=pSes;

      for(i=0;i<iMaxSesions;i++)
      {
        if(!pSessionArray[i].cs.iBusy)continue;

       spSes=&pSessionArray[i];

       if(iCIDLen!=(int)spSes->sSIPMsg.dstrCallID.uiLen)continue;
       if(memcmp(pCID,spSes->sSIPMsg.dstrCallID.strVal,iCIDLen))continue;

       DEBUG_T(0,"Call id ok")

       if(spSes->str16Tag.uiLen && iUseTag)
       {
          if(iTagLen!=(int)spSes->str16Tag.uiLen || !pTag)continue;
          if(memcmp(pTag,spSes->str16Tag.strVal,iTagLen))continue;
       }
       //TODO check addr

       DEBUG_T(0,"tag ok")
       return spSes;
      }
      //while(1);
      return NULL;
      
   }
    //CALL_SES *getRootSes(){return pSes;}
    void resetSesParams(CSesBase *spSes, int iMeth) 
    {
       //TODO if(iMeth!=METHOD_REGISTER && online())use contact the same as register
       spSes->pIPLocal=&str64BindedAddr;
       unsigned int po=extAddr.getPort();
       if(po && extAddr.ip)
       {
          if(p_cfg.iUseOnlyNatIp)
          {
             spSes->uiUserVisibleSipPort=sockSip.addr.getPort();
          }
          else
          {
             spSes->uiUserVisibleSipPort=po;
          }

          spSes->pIPVisble=&str64ExternalAddr;
          //TODO if in same nat
       }
       else
       {
          spSes->pIPVisble=&str64BindedAddr;
          spSes->uiUserVisibleSipPort=sockSip.addr.getPort();
       }

       if(p_cfg.isOnline() || iMeth==METHOD_REGISTER)
       {
          char *u=NULL;
          if(*p_cfg.user.nr)
             u=p_cfg.user.nr;
          else if(*p_cfg.user.un)
             u=p_cfg.user.un;
          else 
             spSes->userSipAddr.uiLen=sprintf(spSes->userSipAddr.strVal
             ,"sip:%.*s",p_cfg.str32GWaddr.uiLen,p_cfg.str32GWaddr.strVal);
          if(u)
             spSes->userSipAddr.uiLen=sprintf(spSes->userSipAddr.strVal,
                "sip:%s@%s",u,p_cfg.str32GWaddr.strVal);
       }
       else 
       {
          spSes->userSipAddr.uiLen=sprintf(spSes->userSipAddr.strVal,
             "sip:%.*s:%u",spSes->pIPVisble->uiLen, spSes->pIPVisble->strVal,spSes->uiUserVisibleSipPort);
       }

    }
   CSesBase *prevRetSes;
   
    CSesBase *getNewSes(int bCaller, ADDR *paddr, int iMeth=0)
    {
       int i;

       if(pSessionArray==NULL)return NULL;

       CSesBase *spSes=NULL;
       for(int rep=0;rep<2;rep++){
       
       for(i=0;i<iMaxSesions;i++)//iMaxSesions;i++)
       {
          if(pSessionArray[i].cs.iBusy)
          {
             
              if(iMeth==METHOD_REGISTER && pSessionArray[i].cs.iSendS==METHOD_REGISTER)
              {
                 spSes=&pSessionArray[i];
                 if(bCaller)
                 {
                    createCallId(spSes,1);
                 }
                 createTag(spSes);
                 spSes->cs.iCallStat=CALL_STAT::EInit;
                 resetSesParams(spSes,iMeth);
                 return (CSesBase *)spSes;
              }
            
             continue;
          }
          if(rep==0 && prevRetSes==&pSessionArray[i] && iMeth!=METHOD_REGISTER){prevRetSes=NULL;continue;}
          spSes=&pSessionArray[i];
          if(iMeth!=METHOD_REGISTER)prevRetSes=spSes;
          
          spSes->cs.iBusy=1;
          spSes->cs.iCaller=bCaller;

          spSes->dstConAddr=*paddr;

          iActiveCallCnt++;
          spSes->cs.iCallStat=CALL_STAT::EInit;
          if(bCaller)
          {
             createCallId(spSes,iMeth==METHOD_REGISTER);
          }
          createTag(spSes);
          
          spSes->uiSipCseq=getTickCount();

          while(spSes->uiSipCseq>1000000000)spSes->uiSipCseq-=1000000000;///SIP Thor on OpenSIPS XS 1.4.5 
          
          //spSes->uiSipCseq=0;
          
          CTMediaIDS* initMediaIDS(void *pThis, CSessionsBase *sb, int iCaller);
          if(iMeth==METHOD_INVITE){
             
             spSes->pMediaIDS = initMediaIDS(spSes,this,bCaller);
          }

          resetSesParams(spSes, iMeth);

          return (CSesBase *)spSes;
       }
       }
       return NULL;
    }
    void freeSes(CSesBase *spSes)
    {
       if(spSes)
       {
          iActiveCallCnt--;
          spSes->clear(this);
       }
    }
   
   void setStopReason(CSesBase *spSes, int code, const char *msg, DSTR *dstr=NULL, CTEditBase *e=NULL);
   

   void onKillSes(CSesBase *spSes, int iReason, SIP_MSG *sMsg, int meth);
   void handleSessions();

   int iSocketsPaused;
   void stopSockets()
   {
      if(!iSocketsPaused){
         iSocketsPaused=1;
         this->sockSip.closeSocket();
         this->cPhoneCallback->mediaFinder->stopSockets();
      }
   }
   void startSockets()
   {
      if(iSocketsPaused){
         iSocketsPaused=0;
         this->sockSip.reCreate();
         this->cPhoneCallback->mediaFinder->startSockets();
      }
   }
   int getFreeSesCnt()
   {
      int ret=0;
      int i;
      for(i=0;i<iMaxSesions;i++)if(!pSessionArray[i].cs.iBusy)ret++;
      return ret;
   }
   int getSessionsCnt(){
      int ret=0;
      int i;
      for(i=0;i<iMaxSesions;i++)if(pSessionArray[i].cs.iBusy)ret++;
      return ret;
   }
   
   int getMediaSessionsCnt(){
      int ret=0;
      int i;
      for(i=0;i<iMaxSesions;i++)if(pSessionArray[i].cs.iBusy && pSessionArray[i].isSession())ret++;
      return ret;
   }



   int onSipMsgSes(CSesBase *spSes, SIP_MSG *sMsg);
   int onSipMsg(CSesBase * spSes, SIP_MSG *sMsg);
   int send200Sdp(CSesBase *spSes, SIP_MSG *sMsg=NULL);



#define LOCK_MUTEX_SES   cMutexSip.lock();
#define UNLOCK_MUTEX_SES   cMutexSip.unLock();
#define CREATE_MUTEX_SES  // csSes.CreateLocal();
#define CLOSE_MUTEX_SES  // csSes.Close();

protected:
   CPhSesions(CTEngineCallBack *cPhoneCallback,CTLangStrings *strings, int iMaxSesions)
      :CSessionsBase(cPhoneCallback->p_cfg),
       strings(*strings),
      iBytesSent(0),
      iBytesRec(0),
      iMaxSesions(iMaxSesions),
      iActiveCallCnt(0),
      threadSip(),
      cPhoneCallback(cPhoneCallback),
      sockSip(*cPhoneCallback),
      port53Check(*cPhoneCallback),
#if defined(__SYMBIAN32__) && !defined(DEMO_PROJECT)
      keepAlive(sockSip,p_cfg.GW,extAddr,ipBinded,uiGT),
#else
      keepAlive(sockSip,p_cfg.GW,extAddr,ipBinded,uiGT,CTKeepAlive::eDefaultKaFreq*2/3),
#endif
      pSessionArray(NULL)
   {
      iIsClosing=0;
      uiPrevCheckGWAt=0;
      uiSIPKeepaliveSentAt=0;
      uiSuspendRegistrationUntil=0;
      iOptionsSent=0;
      pTransMsgList=NULL;
      iSocketsPaused=0;
      uiNextRegTry=0;
      uiGT = 1;//must not be zero

      bRun=1;
      iRegTryParam=0;
      iCanCheckStunIP=1;

      ipBinded=0;

      int get_time();

      uiRegistarationCallIdRandom[0]=getTickCount();
      uiRegistarationCallIdRandom[1]=get_time();
      

      uiCheckNetworkTypeAt=0;
      iPingTime=0;


      p_cfg.iUseTiViBuddys=1;


      CREATE_MUTEX_SES

      str64ExternalAddr.uiLen=0;
      str64ExternalAddr.strVal[0]=0;
      pSessionArray=new CSesBase[iMaxSesions];

      {
         int i;
         for(i=0;i<iMaxSesions;i++)
         {//
            pSessionArray[i].clear(this,1);
         }
      }

   }
 
   virtual ~CPhSesions()
   {
      if(pSessionArray)
         delete []pSessionArray;
      pSessionArray=NULL;

      void relTransMsgList(CPhSesions *ph);
      relTransMsgList(this);
      iMaxSesions=0;
      CLOSE_MUTEX_SES
   }
  
   void createCallId(CSesBase *spSes, int iIsReg);
   void createTag(CSesBase *spSes);

   int sendSip(CTSipSock &sc, CSesBase *spSes)
   {

      if(spSes->cs.iWaitS==0 || spSes->iKillCalled)
      {
         spSes->cs.iSendS=0;
         spSes->sSendTo.stopRetransmit();
      }

      int ret=-5;
      ADDR aa;
      ADDR *a=&spSes->dstConAddr;
      
      if(hasNetworkConnect(ipBinded))
      {
         if(p_cfg.iDebug){
            cPhoneCallback->dbg(spSes->sSendTo.data.rawData,spSes->sSendTo.data.offset);;
         }
         /*
   struct{
      int iFound;
      DSTR dstrAddr;
      DSTR dstrPort;
   }maddr;
         */

         if(spSes->cs.iWaitS==200 && 
            spSes->sSIPMsg.hldRecRoute.uiCount 
            && spSes->sSIPMsg.hldRecRoute.x[spSes->sSIPMsg.hldRecRoute.uiCount-1].sipUri.maddr.iFound 
            && spSes->sSIPMsg.hldRecRoute.x[spSes->sSIPMsg.hldRecRoute.uiCount-1].sipUri.maddr.dstrAddr.uiVal 
            ){
               aa.ip=spSes->sSIPMsg.hldRecRoute.x[spSes->sSIPMsg.hldRecRoute.uiCount-1].sipUri.maddr.dstrAddr.uiVal;
               aa.setPort(spSes->sSIPMsg.hldRecRoute.x[spSes->sSIPMsg.hldRecRoute.uiCount-1].sipUri.maddr.dstrPort.uiVal);
               a=&aa;

         }
         ret=sc.sendTo((char *)&spSes->sSendTo.data.rawData[0],spSes->sSendTo.data.offset,a);
       //  void tmp_log(const char *p);  tmp_log(spSes->sSendTo.data.rawData);
      }
    //  char cc[64];sprintf(cc,"send-ret=%d ip=%x",ret,a->ip);
     // void tmp_log(const char *p);
     // tmp_log(cc);
      
      iBytesSent+=spSes->sSendTo.data.offset;

      spSes->sSendTo.iIsTCPorTLS=sc.isTCP()|sc.isTLS();
      if(spSes->cs.iWaitS)
      {
         spSes->sSendTo.updateRetransmit(uiGT);
      }


      return ret;
   }
   inline CSesBase* getSesByIndex(int idx){
      if(idx<0 || idx>=iMaxSesions)return NULL;
      return &pSessionArray[idx];
   }

    
private:
    CSesBase *pSessionArray;//root
    const static char szTagChars[80];

};


unsigned int addRoute(char *p, int iMaxLen, HLD_ROUTE *hld, const char *sz, int iUp, int iReplaceRoute, DSTR *dstrContact);
int hasRouteLR(HLD_ROUTE *hld, unsigned int id);

//#define T_USE_LOW_STACK_SPACE

class CMakeSip{

private:
   CSesBase *spSes;
   SIP_MSG *sMsg;
   int *iRetLen;
   unsigned int uiLen;
   char *buf;
   int iContentAdded;
   unsigned int uiPosToContentLen;
   unsigned int uiPosContentStart;
   STR strDstAddr;
   


public:
   int iIsTLS;
   int iIsTCP;
   int fToTagIgnore;
   int iContactId;

   CTEngineCallBack *cPhoneCallback;

   SIP_MSG *getSipMsg(){return sMsg;}
   

   CMakeSip(CTSipSock & sc)
      :spSes(NULL),sMsg(NULL),iRetLen(NULL),uiLen(0)
      ,iContentAdded(0),uiPosToContentLen(0)
      ,iBufMalloced(0)
   {
      cPhoneCallback=NULL;
      fToTagIgnore=0;
      iContactId=0;
      iIsTLS=sc.isTLS();
      iIsTCP=sc.isTCP();
      
   }
   int sendResp(CTSipSock & sc, int iCode, SIP_MSG *psMsg)
   {
      sMsg=psMsg;
      buf=new char [psMsg->uiOffset+512];//bufData;
      if(buf==NULL)return -1;

      iIsTLS=sc.isTLS();
      iIsTCP=sc.isTCP();

      //SWAP_SHORT(addr.port);
      makeResp(iCode,cPhoneCallback?&cPhoneCallback->p_cfg:0);
      addContent();
      sendSip(sc, buf,(int) uiLen, &sMsg->addrSipMsgRec);
      delete buf;

      iBufMalloced=0;
      return 0;
   }
   CMakeSip(int x, CTSipSock & sc, SIP_MSG *psMsg)
   :spSes(NULL),sMsg(psMsg),iRetLen(NULL),uiLen(0)
   ,iContentAdded(0),uiPosToContentLen(0)
   {
      cPhoneCallback=NULL;
      iContactId=fToTagIgnore=0;
      buf=new char [DATA_SIZE];
      iBufMalloced=1;
   
   }
   CMakeSip(CTSipSock & sc, int iCode, SIP_MSG *psMsg)
      :spSes(NULL),sMsg(psMsg),iRetLen(NULL),uiLen(0)
      ,iContentAdded(0),uiPosToContentLen(0)
   {
      cPhoneCallback=NULL;
      iContactId=fToTagIgnore=0;
      sendResp(sc,iCode,psMsg);
   }

   CMakeSip(CTSipSock &sc, CSesBase *pSes, SIP_MSG *psMsg=NULL,char *outBuf=NULL, int *iOutLen=NULL)
      :spSes(pSes),uiLen(0),iContentAdded(0),uiPosToContentLen(0)
      ,uiPosContentStart(0),iBufMalloced(0)
   {
      cPhoneCallback=NULL;
      iContactId=fToTagIgnore=0;
      
      iIsTLS=sc.isTLS();
      iIsTCP=sc.isTCP();

      if(pSes)
      {
         sMsg=psMsg?psMsg:&pSes->sSIPMsg;

         pSes->sSendTo.data.offset=0;
         buf=pSes->sSendTo.data.rawData;
         iRetLen=&pSes->sSendTo.data.offset;

      }
      else
      {
         if(outBuf==NULL)
         {
            outBuf=new char [DATA_SIZE];
            iBufMalloced=1;
         }
         buf=outBuf;
         iRetLen=iOutLen;
         sMsg=psMsg;
      }
      
   };
   ~CMakeSip(){if(iBufMalloced && buf)delete buf;buf=NULL;}
   void addContent()
   {
      
      if(uiPosToContentLen && uiPosContentStart)
      {
         int iLen=
            sprintf(buf + uiPosToContentLen,"%u",uiLen - uiPosContentStart);
         if(spSes)
         {
            spSes->sSendTo.iContentLen=uiLen - uiPosContentStart;
            spSes->sSendTo.pContent=buf+uiPosContentStart;
         }
         buf[uiPosToContentLen+iLen]=' ';//removes '\0' at end of sprintf
      }
      else if(!iContentAdded)
      {
         uiLen+=addDefaultContent(buf+uiLen);
         if(spSes)
         {
            spSes->sSendTo.iContentLen=0;
            spSes->sSendTo.pContent=NULL;
            spSes->sSendTo.pContentType=NULL;
         }
      }
      

      if(iRetLen)
         *iRetLen=(int)uiLen;
   };
   int makeReq(int id, PHONE_CFG * cfg, ADDR *addrExt=NULL,STR_64 *str64ExtADDR=NULL);
   
   int makeResp(int id, PHONE_CFG * cfg =NULL, char *pDst=NULL, int iDstLen=0);
   int addAuth(char *un, char *pwd, SIP_MSG *psMsg);
   int addContent(const char *type, char *pCont, int iContLen);//NEW
   int addContent8(const char *type, CTStrBase *e);
   int addContent16(const char *type, CTStrBase *e);
   int addParams(char *p, int iLenAdd);


   int makeSdpHdr(char *pIP_Orig, int iIPLen);
   int addSdpMC(int iMediaType, int iPort, char *pIP_Cont, int iIPLen, SDP *my, SDP *dest);
   int addSdpUdptl(int iMediaType, int iPort, char *pIP_Cont, int iIPLen);
   int addSdpMC(char *mediaName, unsigned int uiPort, char *pIP_Cont, int iIPLen);
   int addSdpConnectIP(char *pIP_Cont, int iIPLen, PHONE_CFG *cfg);


   int makeSDPMedia(CTMakeSdpBase &b, int fUseExtPort)
   {
     uiLen+=(unsigned int )b.makeSdp(buf+uiLen, 500,fUseExtPort);//TODO
     return 0;
   }
   inline static int addDefaultContent(char *buf)
   {
      int iLen=0;
      ADD_0_STR(buf,iLen,"Content-Length: 0\r\n\r\n");
      return iLen;
   }

   int sendSip(CTSipSock &sc, ADDR *addr)
   {
      if(cPhoneCallback && cPhoneCallback->p_cfg.iDebug){
         cPhoneCallback->dbg(buf,(int)uiLen);;
      }
      
      return sc.sendTo(buf,(int)uiLen,addr);
   }
   inline  static int sendSip(CTSipSock &sc, char *buf, int iLen, ADDR *addr)
   {

      return sc.sendTo(buf,iLen,addr);
   }
private:
   int iBufMalloced;
   static const struct SIP_METH sip_meth[13];

};
int makeSDP(CPhSesions &ph, CSesBase *spSes, CMakeSip &ms);
#endif //_C_TIVI_SES_H
