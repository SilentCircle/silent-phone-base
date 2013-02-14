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


#ifndef _C_TIVI_PH_MEDIA_H
#define _C_TIVI_PH_MEDIA_H 

#include "../baseclasses/CTBase.h"
#include "../baseclasses/CTListBase.h"

#include "CTPhMediaBase.h"
#include "../rtp/rtp.h"

#include "../codecs/CTVidCodec.h"

#include "../codecs/gsm/gsm.h"
#include "../codecs/g711/g711.h"
#include "../codecs/g722/t_g722.h"

#include "../os/CTiViSock.h"
#include "../os/CTThread.h"
#include "../os/CTMutex.h"

#include "../codecs/vTiVi/tina_enc_c.h"

#ifdef USE_JPG_VID
#include "../codecs/jpg/CTJpg.h"
#endif


void tivi_log(const char* format, ...);
unsigned int getTickCount();
int isSameSSRC(char *pack, int iLen, unsigned int ssrc);


class CTG729EncDec: public CCodecBase{
public:
   CTG729EncDec():CCodecBase(10,160)
   {
   }
   ~CTG729EncDec(){}
   int hasPLC(){return 1;}
   virtual inline int encodeFrame(short *pIn,unsigned  char *pOut)
   {
      return iCodecFrameSizeEnc; 
   }
   virtual inline int decodeFrame(unsigned char *pIn, short *pOut)
   {
      return iCodecFrameSizeDec;
   }
   
};


class CTRecSendUDP:public CTSock,public CTThread{
public:
   
   CTRecSendUDP(CTSockCB &cb)
   :CTSock(cb),CTThread(){
      iClosed=0;
   }
   
   ~CTRecSendUDP(){close();/*if(iBufCreated && buf) delete buf;*/}
   int start(const CTSockRecvCB &sockCBRecv, ADDR *addrToBind);
   void stop(){
      iRun=0;
      
      ADDR a="127.0.0.1";
      a.setPort(addr.getPort());;
      
      CTSockRecvCB old(NULL,NULL);
      CTSockRecvCB newcb(NULL,NULL);
      setCB(newcb,old);
      sendTo("1",1,&a);
   };
   //int close(){sock.close();th.close();};
   void close(){
      if(iClosed)return;
      iClosed=1;
      printf("[CTRecSendUDP %p]\n",this);
      stop();
      Sleep(5);
      CTSock::closeSocket();
      CTThread::close();
      Sleep(5);
   };
protected:
   
   static int thFnc(void *p);

   int iRun;
   int iClosed;
   
};


class CTAudioEngine{
public:
   CTAudioEngine()
   {
   }
   ~CTAudioEngine(){
   }
   
   CTG711Ulaw gUlaw;
   CTG711Alaw gAlaw;
   
   CTVCodCol vidCodec;
#ifdef USE_JPG_VID
   CTJpgED jpgEnc;
   CTTina_Enc_Dec tinaEncDec;
   int iDecFPS;
#endif
   
};

//send to all dst rtp every 100ms
//if (recv rtp and auth ok) {sendRtp pack back, sendStunBind}
//if(recv_ping){sendPingAnswer}
//if(recv_ping && received_ping_answ)iIceFlag=eUsingICE;

//ping("PING"||24bitTS||8bit-idx||my_ssrc)
//ping("P200"||24bitTS||8bit-idx||my_ssrc)

int isSameRtpSSRC(char *pack, int iLen, unsigned int ssrc);


class CTXIce{
public:
   
   enum{eMaxAddrToTry=6};
   enum{eNoICE=0, eFailed=1, eTesting=2, ePeerPingRecv=4, ePingSent=8, ePingRespRecv=16};
private:
   enum{eIDXByte=7, ePingFreq=50*10};
   
   int iIceFlag;
   int iTestICECnt;//if>0 then
   
   int iP2P_candidate;
   
   int iPingsSent;
   
   int iNextPingSendAfter;
   
   typedef struct{
      unsigned int uiPingTime;
      int iRespReceived;
      int iReqSent;
      int iReqRecv;

      ADDR a;
      
      char szVers[16];//v1 current
      char szType[16];//relay, host - if relay then test start test this peer  5sec later
      char szNatType[16];//informative only
      char szConnType[16];//today only udp4 is supported
      
   }CANDIDATE;
   
   CANDIDATE candidateArr[eMaxAddrToTry+1];
   int iAddrDstToTry;
   
   int iCandidatesCreated;
   
   
   unsigned int uiMySSRC, uiDstSSRC,uiMySSRCNet;
   
   int iIsSecure;
   
   CTSock *sock;
   
   int getTryAddrCnt(){
      return iAddrDstToTry;
   }
   
 //  int isP2PAvailable(){return !!(iIceFlag & ePeerPingRecv);}
public:
   
#define T_SC_ICE "t-sc-ice:"
 
   CTXIce(){reset();sock=NULL;}
   
   inline int active(){return iAddrDstToTry && iCandidatesCreated; }
   
   int pingTime(){
      int pt=iP2P_candidate;
      if(!(iIceFlag & ePingRespRecv) || pt<0)return -1;
      return (int)candidateArr[pt].uiPingTime;
   }
   
   inline int canUseP2PNow(){
      if(!iIsSecure)return 0;
      if(iP2P_candidate<0 || iAddrDstToTry==0)return 0;
      if((iIceFlag &  (ePeerPingRecv|ePingRespRecv))!=(ePeerPingRecv|ePingRespRecv))return 0;
      return 1;
   }
   
   int trySetP2PAddr(ADDR *a){
      int pt=iP2P_candidate;
      if(pt<0  || !canUseP2PNow())return -1;
      *a = candidateArr[pt].a;
      
      return 0;
   }
   int isP2PAddr(ADDR *a){
      int pt=iP2P_candidate;
      if(pt<0  || (iIceFlag & ePeerPingRecv)==0)return 0;
      
      return *a==candidateArr[pt].a;
   }

   void reset(){
      
      iIceFlag = eNoICE;
      iNextPingSendAfter = ePingFreq;
      uiMySSRCNet=0;
      iCandidatesCreated=0;
      iIsSecure=0;
      
      uiMySSRC=uiDstSSRC=0;
      
      iAddrDstToTry=0;
      iTestICECnt=0;
      memset(candidateArr, 0, sizeof(candidateArr));
      iP2P_candidate=-1;
   }
   
   void setPeerData(CTSock *s, unsigned int _uiMySSRC, unsigned int _uiDstSSRC){
      sock=s;
      this->uiMySSRC=_uiMySSRC;
      this->uiDstSSRC=_uiDstSSRC;
      
      SWAP_INT(_uiMySSRC);
      uiMySSRCNet=_uiMySSRC;
   }
   
   void onSendRTP(int iIsZRTPSecure){
      
      //if no media and we have relay addr  - try it
      
      iIsSecure=iIsZRTPSecure;
      if(!iIsZRTPSecure)return;
      if(!sock)return;
      
      if(canUseP2PNow()){
         iNextPingSendAfter--;
         if(iNextPingSendAfter<0){
            sendPingReq(iP2P_candidate);
            iNextPingSendAfter=ePingFreq;
         }
      }
      
      
      if(iTestICECnt<=0 || iAddrDstToTry<1)return;
      
      iIceFlag|=eTesting;
      
      iTestICECnt--;
      
      //send data every 8 packs
      if(iTestICECnt & 7){
         return;
      }
      
      if(iIceFlag &  (ePeerPingRecv|ePingRespRecv|ePingSent)){
         
         if(!(iIceFlag & ePingRespRecv))sendPingReq(iP2P_candidate);
         
         return ;
      }
      
      int cnt = getTryAddrCnt();
      for(int i=0;i<cnt;i++){
         sendPingReq(i);
      }
   }
   

   

   
   int recData(char *p, int iLen, ADDR *a){
      
      //--if(!active() || iLen!=12)return 0;
      if(uiDstSSRC==0 || !sock || !iIsSecure)return -2;
      if(!active())return -1;
      
      if(iLen<12)return -1;
      
      if(iLen>12){
         if(!isSameRtpSSRC(p,iLen,uiDstSSRC))return -1;
         //TODO idxInList(a);
         return 1;
      }
      
      int iReq = *(int*)p==*(int*)"PING";
      int iResp= *(int*)p==*(int*)"P200";
      
      unsigned int ssrc=0;
      int getRTPSSRC(char *pack, int iLen, unsigned int *resp);
      getRTPSSRC(p,iLen, &ssrc);
      printf("rec [%.*s]ssrc=%x,d=%x,m=%x",4,p,ssrc, uiDstSSRC, uiMySSRC);
      
      if(iReq){
         if(!isSameRtpSSRC(p,iLen,uiDstSSRC))return -1;
         *(int*)p=*(int*)"P200";
         sock->sendTo(p,iLen,a);
         
         int idx = idxInList(a);
         if(idx<0){
            //what to do if iP2P_candidate>=0 should i update "candidateArr[idx].a=*a;" peer addr??
            if(iP2P_candidate>=0)return -1;
            idx=iAddrDstToTry;
            
            iP2P_candidate=idx;
            
            candidateArr[idx].iReqRecv++;
            candidateArr[idx].a=*a;
            iAddrDstToTry++;
         }
          iIceFlag|=ePeerPingRecv;
         //ePingSent
         
         if(!(iIceFlag & ePingSent)){

            iP2P_candidate=idx;
            sendPingReq(idx);
         }
        
         return 0;
      }
      
      if(iResp){
         int idx=p[eIDXByte];
         
         //??if(idx!=idxInList(a))return -1;
         
         if(idx<0 || idx>=getTryAddrCnt())return -1;
         if(!isSameRtpSSRC(p,iLen,uiMySSRC))return -1;
         //TODO check is TS registred
         
         iIceFlag|=ePingSent;
         iIceFlag|=ePingRespRecv;
         candidateArr[idx].iRespReceived++;
         
         iP2P_candidate=idx;
         //startSendRTP


         calcPingTime(p, iLen, &candidateArr[idx].uiPingTime);
         
         return 0;
      }

      return 1;
   }

   //c1) priv.ip priv.port;
   //c2) if(priv.ip!=publ.ip)publ.ip      publ.port;
   //c3) if(publ.port!=priv.port)publ.ip      priv.port;
   
   //a=t-sc-ice:v1 host|relay non|fc|rc|prc|sym|fw|unkn udp|tcp|https ip port
//a=t-sc-ice:v1 host sym udp4 25.215.155.22 51234 10.0.0.1 18000

   int createCandidates(ADDR *priv, ADDR *publ, char *pOut, int iMaxLen){
      char b1[64];
      char b2[64];
      publ->toStr(b1,1);
      const char *natType = "unkn";//TODO get type
      iCandidatesCreated=1;
      if(*publ == *priv){
         return snprintf(pOut, iMaxLen-1, "a=t-sc-ice:v1 host %s udp4 %s\r\n", natType, b1);
      }
      priv->toStr(b2,1);
      return snprintf(pOut, iMaxLen-1, "a=t-sc-ice:v1 host %s udp4 %s %s\r\n", natType, b1,b2);
   }
   
   int addDstCandidate(const char *p, int iLen){
      //a=t-sc-ice:v1 host|relay non|fc|rc|prc|sym|fw|unkn udp|tcp|tls ip port
      //a=t-sc-ice:v1 host sym udp4 25.215.155.22:51234 10.0.0.1:18000
      
      if(iLen<30)return -1;
      
      
      if(strncmp(p,T_SC_ICE,sizeof(T_SC_ICE)-1)){
         return -1;
      }
      
      p+=sizeof(T_SC_ICE)-1;
      iLen-=sizeof(T_SC_ICE)-1;
      
      CANDIDATE cStack;
      memset(&cStack,0, sizeof(cStack));
      
      CANDIDATE *c=&cStack;
      

      
      int l=0;
      l = getToken(p, iLen);
      if(copyToken(c->szVers, p, l, sizeof(c->szVers))<0)return -1;
      p+=l+1;
      
      l = getToken(p, iLen);
      if(copyToken(c->szType, p, l, sizeof(c->szType))<0)return -1;
      p+=l+1;
      
      l = getToken(p, iLen);
      if(copyToken(c->szNatType, p, l, sizeof(c->szNatType))<0)return -1;
      p+=l+1;
      
      l = getToken(p, iLen);
      if(copyToken(c->szConnType, p, l, sizeof(c->szConnType))<0)return -1;
      p+=l+1;
      
      //we are supporting only udp4
      if(strcmp(c->szConnType,"udp4"))return 0;
      
#define T_MIN_IP_PORT_LEN 9
      
      if(iLen<T_MIN_IP_PORT_LEN)return 0;
      l = getToken(p, iLen);
      if(l<T_MIN_IP_PORT_LEN)return -1;
      c->a=p;
      
      if(!c->a.getPort() || !c->a.ip)return 0;
      
      int idx = idxInList(&c->a);
      if(idx>=0)return 0;
      
      memcpy(&candidateArr[iAddrDstToTry], c, sizeof(CANDIDATE));
      
      iAddrDstToTry++;if(iAddrDstToTry>=eMaxAddrToTry)return 0;
      
      iTestICECnt = 50 * 10;
      
      if(iLen<T_MIN_IP_PORT_LEN)return 0;
      
      p+=l+1;
      l = getToken(p, iLen);
      
      
      if(l<T_MIN_IP_PORT_LEN){
         return 0;
      }
      ADDR a=p;
      
      if(!a.getPort() || !a.ip)return 0;
      idx = idxInList(&a);
      if(idx>=0)return 0;
      
      CANDIDATE *cPriv=&candidateArr[iAddrDstToTry];
      memcpy(cPriv, c, sizeof(CANDIDATE));
      cPriv->a=a;
      
      iAddrDstToTry++;if(iAddrDstToTry>=eMaxAddrToTry)return 0;
      
      if(cPriv->a.getPort() != c->a.getPort()){
         CANDIDATE *c3 = &candidateArr[iAddrDstToTry];
         memcpy(c3, c, sizeof(CANDIDATE));
         
         c3->a=c->a;
         c3->a.setPort(cPriv->a.getPort());
         iAddrDstToTry++;if(iAddrDstToTry>=eMaxAddrToTry)return 0;
      }
      
      for(int i=0;i<iAddrDstToTry;i++){
         char b[64];
         CANDIDATE *c=&candidateArr[i];
         
         printf("addr=%s v=%s t=%s nt=%s ct=%s\n",c->a.toStr(&b[0],1),c->szVers, c->szType, c->szNatType, c->szConnType);
      }
      
      return 0;
   }

private:
   void sendPingReq(int idx){
      if(!sock)return;
      if(idx<0 || idx>eMaxAddrToTry)return;
      
      iPingsSent++;
      
      if(idx==iP2P_candidate)iIceFlag|=ePingSent;
      candidateArr[idx].iReqSent++;
      
      char buf[16];
      
      *(int*)&buf[0]=*(int*)"PING";
      *(unsigned int*)&buf[8]=uiMySSRCNet;
      
      *(unsigned int*)&buf[4]=getTickCount();
      buf[eIDXByte]=(char)idx;
      
      sock->sendTo(buf,12,&candidateArr[idx].a);
   }
   
   int calcPingTime(char *p, int iLen, unsigned int *resp){
      
      if(iLen!=12 || !resp)return -1;
      
      unsigned int uiSendTS=*(unsigned int*)(p+4);
      unsigned int uiTS=getTickCount();
      //we use 24bits, ignore eIDXByte
      uiSendTS&=0x00ffffff;
      uiTS&=0x00ffffff;
      unsigned int d=(uiTS-uiSendTS);
      if(d>100*1000){
         uiTS|=0x01000000;
         d=(uiTS-uiSendTS);
      }
      *resp = d;
      return 0;
   }
   
   int idxInList(ADDR *a){
      
      for(int i=0;i<iAddrDstToTry;i++){
         if(*a==candidateArr[i].a)return i;
      }
      return -1;
   }
   
   int getToken(const char *p, int &iLen){
      int l=0;
      while(l<iLen && p[l]>' '){
         l++;
      }
      iLen-=l;
      
      return l;
   }
   
   int copyToken(char *dst, const char *src, int len, int iMaxDstSize){
      if(len>=iMaxDstSize || len<1)return -1;
      strncpy(dst, src, len);
      dst[len]=0;
      return 0;
   }
   
};

class CRTPX{
public:
   
   enum{eRtpOk, eRtpBad=-1, eRtpNotMine=-2};
   
   CTXIce ice;
   
   int iCanSend;//TODO
   RTP_PACKET_S rtpSend;
   RTP_PACKET_P rtpRec;
   unsigned int uiSSRC;//dst
   unsigned int uiSSRC_toIgnore;//dst
   struct CODECS codec[128];
   int iCodecCnt;
   
   unsigned char codecMatches[2][128];
   int iCodecsMatching[2];
   
   
   int iPrevPT,iLost,iPrevId;
   
   //unsigned short  lastSeqNr;
   unsigned int    rtpPackLost;
   unsigned int    uiStopAudio;
   unsigned int    uiPrevSendRTPpt;
   unsigned int uiIP2;//test addr

   unsigned int uiPrevRecTS;
  
   ADDR addrDst;
   
   ADDR addrPublic;
   
   int iCanResetMedia;
   void clear()
   {
      ice.reset();
      iCanSend=0;
      memset(&rtpRec,0,(int)&iCanResetMedia-(int)&rtpRec+4);
      iPrevPT=-1;
   }
   void clearAll()
   {
      iCanSend=0;
      memset(&iCanSend,0,(int)&iCanResetMedia-(int)&iCanSend+4);
      iPrevPT=-1;
   }
   
   CRTPX(){clearAll();}

   int onSdp(SDP &sdp , int eType, CSessionsBase &eng);
   int makeSdp(char *p, int iMaxLen, unsigned int uiPort, 
               const char *media, int eType, CSessionsBase &eng, unsigned uiSSRC);
   
   inline int onRtp(char *p, int iLen, ADDR *a)
   {
#if 1
      if(ice.active() && addrDst.ip!=a->ip){
         int r = ice.recData(p,iLen, a);
         if(r==-2 && !iCanResetMedia)return  eRtpNotMine;
         if(r==-1)return eRtpNotMine;
         if(r==0)return eRtpOk;
       
      }
      else if (iCanResetMedia==0 && (addrDst.ip!=a->ip))
         return eRtpNotMine;
      if(iLen<12)return eRtpBad;
#else
      if(iLen<12)return eRtpBad;
      if (iCanResetMedia==0 && (addrDst.ip!=a->ip))return eRtpNotMine;
#endif
      if(parseRtp(p,iLen)<0)return eRtpBad;
      
      return eRtpOk;
   }
   void setHdr(unsigned int uiSSRC);
   int parseRtp(char *p, int iLen);//{ return 0;}
   int makeRTP(int iPt, CTMediaIDS::MEDIA *m);//{ return 0;}
   int setSendCodec(int iType, CSessionsBase &eng);
   
};

class CRTPA: public CTSesMediaBase, public CtZrtpSendCb{

   
   CGsmcodec gDec;
   CGsmcodec gEnc;
   
   CTG729EncDec g729Dec; 
   CTG729EncDec g729Enc; 
   
   CTG711Ulaw uLawDec;
   CTG711Alaw aLawDec;

   CTG722_16khz g722enc;
   CTG722_16khz g722dec;
   
   CCodecBase *prevRecCodec;
   
   char *bufPcm;
   char bufPcmBuf[4096*2];

protected:
   int iSdpParsed;//--//
   int iMediaSent;//--//
   int iWillStop;//--//

   unsigned int uiMaxDecodeBufSize;
   
   t_ph_tick uiStopMediaAt;//obsolete
   unsigned int uiTimeStampOffset;;//--//
   CTAudioEngine &cb;
   CTAudioInBase &cAI;
   CTMediaMngrBase &mediaMngr;
public:
   CRTPX rtp;//--//
   CTRecSendUDP &sockth;

   CRTPA(CTRecSendUDP &sockth, CSessionsBase &eng, CTAudioEngine &cb,CTAudioInBase &cAI ,  CTMediaMngrBase &mediaMngr)
   :CTSesMediaBase(eng)
   ,sockth(sockth)
   ,mediaMngr(mediaMngr)
   ,cb(cb),cAI(cAI)
   {
      iWillStop=0;
      iSdpParsed=0;
      
      cAO=NULL;
      iMediaSent=0;
      iType=eAudio;
      uiMaxDecodeBufSize=sizeof(bufPcmBuf);//
      bufPcm=&bufPcmBuf[0];
      prevRecCodec=NULL;
   }
   ~CRTPA(){
      onStop();
      if(cAO)mediaMngr.relAO(cAO);
      cAO=NULL;
      
   }
   void clear()
   {
      
      prevRecCodec=0;
      iSdpParsed=0;
      iMediaSent=0;
      iWillStop=0;
      CTSesMediaBase::clear();
      uiTimeStampOffset=uiStopMediaAt=0;
      rtp.clear();
      
   }
   virtual inline void onTimer()
   {
      if(uiStopMediaAt && uiStopMediaAt<cbEng.uiGT)
      {
         //clears audio buffer
         uiStopMediaAt=0;
         if(cAO)cAO->update(NULL,0,0);//TODO rem later
      }
      if(rtp.iCanResetMedia && !iMediaSent)
      {
         onSend(NULL,0,eAudio,NULL,0);
      }

   }
   int sendPacket(char *p, unsigned int uiLen);
   
   virtual int onData(char *p, int iLen, ADDR *a);

   virtual const char *getMediaName(){return "audio";}
  
   virtual void sendRtp(CtZrtpSession const *session, uint8_t* packet, size_t length, CtZrtpSession::streamName streamNm); 
   
   int onWillStop(){iWillStop=1;return 0;}
   
   int getInfo(const char *key, char *p, int iMax);
   unsigned int getSSRC(){return rtp.rtpSend.ssrc;}
   inline  int isSesActive(){return iIsActive && rtp.addrDst.ip;}
   virtual int onSdp(char *pSdp, int iLen);
   virtual int onSend(char *p, int iLen, int iCurType, void* pMediaParam, int iIsVoice);
   virtual int onSendUAlawSpliter(char *p, int iLen, int iCurType, void* pMediaParam, int iIsVoice);

   virtual int onStart();//old
   virtual int onStop();
   virtual void onRel();
   virtual int makeSdp(char *p, int iMaxLen, int fUseExtPort);
protected:
   int tryEncryptSendPack(CRTPX *r, CTSock *s, int iIsVideo);

};

class CRTPV: public CRTPA{

   CTVideoOutBase &cVO;
   CTVideoInBase &cVI;
   
   int iCanSendVideo;
#ifdef USE_JPG_VID
   CTJpgED jpgDec;
#endif
   int iDestHasTina;

public:   
   
   int iIsInUse;
   
   int iAskKey;
   
   CRTPX rtpV;
   
   void clear()
   {
      iAskKey=1;
      iDestHasTina=-1;
      uiStopMediaAt=0;
      rtpV.clear();
      CRTPA::clear();
   }
   CRTPV(CTRecSendUDP &sockth, CSessionsBase &eng, CTAudioEngine &cb ,CTAudioInBase &cAI
         ,CTVideoOutBase &cVO, CTVideoInBase &cVI, CTMediaMngrBase &mediaMngr)
   :CRTPA(sockth, eng,cb,cAI,mediaMngr),cVO(cVO),cVI(cVI)
   {
      iType=eVideo|eAudio;
      iIsInUse=0;
      
   }
   ~CRTPV(){
      onStop();

   }
   int onSend(char *p, int iLen, int iType, void* pMediaParam, int iIsVoice)
   {
      if(iType & eAudio)
         return CRTPA::onSend(p,iLen,iType,pMediaParam,iIsVoice);
      
      return onVideoSend(p,iLen,iType,pMediaParam);
   }
   
   
   virtual void sendRtp(CtZrtpSession const *session, uint8_t* packet, size_t length, CtZrtpSession::streamName streamNm); 
   
   virtual int onData(char *p, int iLen, ADDR *a);
   virtual int onSdp(char *pSdp, int iLen);
   virtual int makeSdp(char *p, int iMaxLen, int fUseExtPort);
   virtual const char *getMediaName(){return "audio video";}
   int onVideoSend(char *p, int iLen, int iType, void* pMediaParam);
//   int sendVideoPack(char *p, int iLen);
   inline void onTimer()
   {
      CRTPA::onTimer();
      if(rtpV.iCanResetMedia)
         onVideoSend(NULL,0,eVideo,NULL);
      
   }
   virtual int onStart();
   virtual int onStop();
   
};

class CTMediaListItem: public CListItem{
public:
   CTMediaListItem():CListItem(0){
      video=NULL;audio=NULL;
      iCanDelete=1;
   }
   ~CTMediaListItem(){
      if(iCanDelete){
         iCanDelete=0;
         if(video)delete video;
         if(audio)delete audio;
      }
   }
   int isItem(void *p, int iSize){
      if(p==video)return 1;
      if(p==audio)return 1;
      return 0;
   }
   inline int onRtp(char *p, int iLen, ADDR *a)
   {
      
      if(audio && audio->iIsActive){int r=audio->onData(p,iLen,a);return r;}
      if(video && video->iIsActive){int r=video->onData(p,iLen,a);return r;}
      return -1;
   }
   int iCanDelete;
   CRTPV *video;
   CRTPA *audio;
   
};


class CTMedia: public CTMediaBase{
public:
   CTAudioEngine audioEng;
protected:
   CTAudioInBase &cAI;
   
   
   //?? var buut probl ar sho iespejams katram zv vajag savu
   //delj nat, ja nav fullcone, ienaks rtp tik ne viena lega
   CTRecSendUDP sockth;
   
   
   CRTPV video;//TODO mark in Use
   
   CTMutex mutex;
   
   CTList list;
   CTList listRem; //TODO make this global
   
   static int onRcv(char *p, int iLen, ADDR *a, void *pUser)
   {
      //  printf("[rec=%x:%d ]",a->ip,a->getPort());
      if(pUser)
      {
         int ret=CRTPX::eRtpNotMine;//-1
         CTMedia *m=(CTMedia*)pUser;
         m->mutex.lock();
         CTMediaListItem *i=(CTMediaListItem *)m->list.getLRoot();
         CTMediaListItem *next;
         //TODO tryFindMediaBy( SSRC , ADDR, CTMediaListItem *from)
         //if fail tryFindMediaBy( SSRC, CTMediaListItem *from)
         //if fail tryFindMediaByWhereNoSSRC( ADDR, CTMediaListItem *from)
         //if fail tryFindStartupNoSSRC(ADDR_IP,CTMediaListItem *from)
         //if fail tryFindStartupNoSSRC(CTMediaListItem *from)
         while(i && ret<0)
         {
            next=(CTMediaListItem *)i->next;
            ret=i->onRtp(p,iLen,a);
            i=next;
         }
         m->mutex.unLock();
         
         if(ret<0 && m->video.iIsActive)
            ret=m->video.onData(p,iLen,a);
         
         return ret;
      }
      return -1;
   }

   
   CTMediaMngrBase &mediaMngr;
   CSessionsBase &eng;
   CTSockRecvCB sockCB_RCV;
public:
   
   CTMedia(CSessionsBase &eng,CTSockCB *cbSock,
           CTVideoOutBase &cVO, CTVideoInBase &cVI, CTAudioInBase &cAI , CTMediaMngrBase &mediaMngr
           )
   :audioEng()
   ,cAI(cAI)
   ,eng(eng)//move this to CTSesMediaBase::setBaseData(eng,
   ,list(),listRem(),mutex()
   ,mediaMngr(mediaMngr)
   ,sockCB_RCV(NULL,NULL)
   ,sockth(*cbSock)
   ,video(sockth,eng,audioEng,cAI,cVO, cVI,mediaMngr)
   {
      ADDR a;
      if(eng.p_cfg.iRtpPort<1024)eng.p_cfg.iRtpPort=1024;
      else if(eng.p_cfg.iRtpPort>65534)eng.p_cfg.iRtpPort=65534;
      a.setPort((unsigned int)eng.p_cfg.iRtpPort);
      
      sockCB_RCV=CTSockRecvCB(onRcv,this);//makes copy
      sockth.start(sockCB_RCV,&a);

   }
   void setZrtpCB(CTZrtpCb *p)
   {
//move to CTiViPhone 
      if(p)eng.zrtpCB=p;
      if(eng.pZrtpGlob==NULL)
      {
         eng.pZrtpGlob=initZrtpG();
      }
      
   }
   virtual ~CTMedia()
   {

      list.removeAll();
      listRem.removeAll();

      relZrtpG(eng.pZrtpGlob);
   }
   void stop()
   {
      sockth.close();
   }
   void startSockets()
   {
      sockth.reCreate();
   }
   void stopSockets()
   {
      sockth.closeSocket();
   }
   
   void setNewPort(int i)
   {
#if !defined(__SYMBIAN32__)
      sockth.setNewPort(i);
#endif
   }
   CTSock *getMediaSocket(int id=0)
   {
      //id==1 return video socket
      return &sockth;
   }
   ////TODO find by sdp
   CTSesMediaBase* findMedia(const char *p, int iLen)
   {
      int iIsAudio=iLen==5 && strncmp(p,"audio",5)==0;
      int iIsVideo=0;
#ifndef DONT_USE_VIDEO   
      iIsVideo=!iIsAudio && iLen==5 && strncmp(p,"video",5)==0;
#else
      if(iIsVideo)iIsAudio=1;
#endif

      if(iIsAudio)
      {
         mutex.lock();//--new

         CTMediaListItem *i=(CTMediaListItem *)listRem.getLRoot();
         int _TODO_CHECK_IS_AUDIO;
         if(i) listRem.remove(i,0);//TODO listrem global
         if(!i)i=new CTMediaListItem();

         if(!i->audio){
            i->audio=new CRTPA(sockth,eng,audioEng,cAI,mediaMngr);
            
         }
         i->audio->clear();
         i->audio->rtp.clearAll();//fix this

         list.addToTail(i);
         mutex.unLock();//--new
         return (CTSesMediaBase* )i->audio;
      }
      if(iIsVideo)
      {
         if(video.isSesActive() || video.iIsInUse)return NULL;
         video.iIsInUse=1;
         video.clear();
         video.rtpV.clearAll();
         video.rtp.clearAll();
         int _TODO_VIDEO_SES;
         return (CTSesMediaBase* )&video;
      }
      
      return NULL;
   }
   void release(CTSesMediaBase * m)
   {
      if(!m)return;
      
      if(m==(CTSesMediaBase* )&video)
      {
         //TODO release codec data
         int iActive=m->isSesActive();
         m->onWillStop();
         if(iActive)Sleep(20);
         m->onStop();
         if(iActive)Sleep(20);
         m->onRel();
         video.iIsInUse=0;
      }
      else
      {
         CListItem *i=list.findItem(m,sizeof(m));
         if(i)
         {
            int iActive=m->isSesActive();
            m->onWillStop();
            if(iActive)Sleep(20);
            m->onStop();
            if(iActive)Sleep(20);//max encode time
            m->onRel();
            mutex.lock();//--new
            list.remove(i,0);
            if(i)listRem.addToTail(i);
            mutex.unLock();//--new
         }
         else puts("rel ERR media is not found");
         // tivi_log("rel-a<<");
         
      }
      

   }
};


#if 0
class CRTPFileTransf: public CTSesMediaBase{
   
public:
   char bufFN[1024];
   CRTPX rtp;
   enum{eConnecting=1,
      eReceivedConnection=2,
      eReceivedConnectionAnswer=4,//connected
      eConnected=eReceivedConnectionAnswer,//connected
      eSending=8,
      eReceiving=16,
      eEnding=32
   };
   int iStatus;
protected:
   unsigned int uiFileSize;
   unsigned int uiNeedResendAt;
   unsigned int uiRespPos;
   unsigned int uiFileOffset,uiSendBytes;
   CTRecSendUDP sockth;
   
public:
   static int onRcv(char *p, int iLen,ADDR *a, void *pUser)
   {
      if(iLen<13)return -1;
      if(pUser)return ((CRTPFileTransf*)pUser)->onData(p,iLen,a);
      return -1;
   }
   
   CRTPFileTransf(CSessionsBase &eng,CTSockCB *cbSock, char *fn=NULL, unsigned int uiFileSize=0)
   :CTSesMediaBase(eng)
   ,uiFileSize(uiFileSize)
   ,sockth(*cbSock,(char *)&rtp.rtpRec.dataBuf, sizeof(rtp.rtpRec.dataBuf))
   {
      
      if(fn)
      {
         strcpy(bufFN,fn);
         iStatus=eSending;
      }
      else
      {
         iStatus=eReceiving;
      }
      iType=eFileTransf;
      clear();
      
      ADDR a;
      a.setPort((unsigned int)eng.p_cfg.iRtpPort);
      sockth.start(CTSockRecvCB(onRcv,this),&a);
      
   }
   ~CRTPFileTransf(){
      sockth.close();
   }
   void clear()
   {
      uiSendBytes=uiNeedResendAt=uiRespPos=uiFileOffset=0;
      rtp.clear();
      CTSesMediaBase::clear();
   }
   //retransmito
   //checko stat, iepseejams kilo
   virtual void onTimer();
   
   virtual int onData(char *p, int iLen, ADDR *a);
   //virtual CTSock * getSocket(int iIndex)=0;//old
   virtual char *getMediaName(){return "file transfer";}
   
   inline  int isSesActive(){return iIsActive && rtp.addrDst.ip;}
   
   
   virtual int onSend(char *p, int iLen, int iCurType, void* pMediaParam){return 0;}
   //virtual int onTimer(unsigned int uiTS){};
   virtual int onStart()
   {
      if((iStatus&eConnected)==0)
         iStatus|=eConnecting;
      
      rtp.iCanSend=1;
      //sendFirst
   }
   virtual int onStop()
   {
      rtp.iCanSend=0;
      iStatus=eEnding;
   }
   //dabuun fila nosaukumu un izmeru
   virtual int onSdp(char *pSdp, int iLen);
   virtual int makeSdp(char *p, int iMaxLen, int fUseExtPort);
protected:
   int sendPacket();
   int sendLastPacket();
   int sendConnect();
   int sendAnswer();
};
#endif



#endif //_C_TIVI_SES_H
