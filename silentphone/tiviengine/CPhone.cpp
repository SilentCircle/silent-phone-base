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

#include "CPhone.h"
#include "../encrypt/md5/md5.h"
#include "../utils/cfg_parser.h"

void bin2Hex(unsigned char *Bin, char * Hex ,int iBinLen);
void tmp_log(const char *p);


#define _T_RELEASE_
#undef _T_DEMO_REL


#ifdef _WIN32
static char szSettingsBuf[2048*8]="";

void setSettings(char *p, int iLen)
{
   strncpy(szSettingsBuf,p,iLen);
   while(!isalnum(p[iLen-1]))iLen--;
   szSettingsBuf[iLen]=0;

}
char *getSettings()
{
   if(szSettingsBuf[0])return &szSettingsBuf[0];
   return NULL;
}
#else
char *getSettings()
{
   return NULL;
}
#endif

int isTiViServ(PHONE_CFG *p)
{
#if (defined(_T_DEMO_REL)|| defined(_T_SOLD_REL)) && !defined(_IS_TIVISRV)
   return p?p->iIsTiViServFlag&1:0;
#else
   return 1;
#endif
}
 

char *getDomain_reg_tivi_lv(char *name) {
#if 1
   strcpy(name,"sip.example.com");
#else
	char chOne = 1;
	char chTwo = 2;

   char chComma = '+';
   char chV = 'v';

   chComma += chOne;

   name[11] = chV - chV;  //  ZERO
   name[5] = chV - 13; // i
   name[chOne] = name[5] - (chTwo + chTwo); // e
   name[chTwo] = name[1] + chTwo; // g
   name[3] = chComma + chTwo; // .
   name[4] = chV     - chTwo; // t
   name[0] = name[4] - chTwo; // r
   name[6] = chV;         // v
   name[7] = name[5];    // i
   name[8] = chComma + chTwo; // .
   name[9] = name[7] + chTwo + chOne; // l
   name[10] = chV;            // v
#endif
	return name;
}

char *getDomain(char *p)
{
   return getDomain_reg_tivi_lv(p);
}


#define _DBG //
//tivi_log 
//_DBG("tsip err=%x",GetLastError());
void tivi_log(const char* format, ...)
#if defined(_WIN32) || defined(__linux__)  || defined(__APPLE__)
{
   /*
    #define T_TLOG_FN "T_log.txt"
    va_list arg;
    va_start(arg, format);
    FILE *f=fopen(T_TLOG_FN,"a+");
    if(f)vfprintf(f,format,arg);
    if(f)fprintf(f,"\r\n");
    if(f)fclose(f);
    va_end( arg );
   */
}
#else
;
#endif
//#define TLOGX tivi_log 
#define TLOGX //

void checkCfgParams(PHONE_CFG &cfg)
{
   if(cfg.iUseOnlyNatIp==0)
   {
      //cfg.iUseStun=*cfg.bufStun?1:0;
   }
   else cfg.iUseStun=0;
   if(cfg.iPayloadSizeSend<1)cfg.iPayloadSizeSend=2;else if(cfg.iPayloadSizeSend>8)cfg.iPayloadSizeSend=8;

}

int isDemoTimeOk()
{

#ifdef _T_DEMO_REL
   int get_time();
   return  get_time()<1209600000;//2008 1may 1209600000
#else
   return 1;
#endif
}

#ifndef __SYMBIAN32__
int getCfgLocation(CTEditBase  &b)
{
   int getPathW(short *p, int iMaxLen);
   short buf[512];
   //CTEditBase  b(512);
   getPathW(buf,512);
   //strcat(buf,"settings.txt");
   b.setText((char*)&buf[0],0,1);
   return 0;
}
#endif

void mBox(char *p, int iWait);
#ifdef __APPLE__
int getSettingsLocation(CTEditBase  &b)
{
   getCfgLocation(b);
   b.addText("settings.txt");
   return 0;
}

#elif !defined(__SYMBIAN32__)

int getSettingsLocation(CTEditBase  &b)
{
   getCfgLocation(b);
   b.addText("settings.txt");
   return 0;
}
int getLicenceLocation(CTEditBase  &b)
{
   getCfgLocation(b);
   b.addText("licence.txt");
   return 0;
}
char *getLicence(int &iLen)
{
   CTEditBase b(250);
   getLicenceLocation(b);
   return loadFileW(b.getText(),iLen);
}
int isValidLicence(char *p, int iLen)
{
   return 0;
}

#endif

static void copyStrSafeCfg(char *dst, int iMaxDstSize, const char *src, int iLen){
   iMaxDstSize--;
   if(iLen>=iMaxDstSize){
      tivi_log("copyStrSafeCfg iLen>=iMaxDstSize");
      exit(1);//?????????????
   }
   strncpy(dst,src, iLen);
   dst[iLen]=0;
}



int readSignedCfg(char *pwd, char *p, int iCfgLen, PHONE_CFG &cfg, CTLangStrings *strings)
{
   char *tmp;
   int iLen;

   char bufCS[32];
   bufCS[0]='c';
   bufCS[1]='s';
   bufCS[2]=0;
   //TODO fix
#if 0
   //ndef __APPLE__
   char *pCs=CTCfgParser::getText(p,bufCS,iLen,iCfgLen);
   if(pCs==NULL)return -1;
   if(pCs-p+iLen!=iCfgLen)return -2;

   char buf[64],Hex[64];
   const char *getSettingsPWD1();

   const char *pp=getSettingsPWD1();
   {
      CTMd5 m;
      m.update((unsigned char *)pp,strlen(pp));
      m.update((unsigned char *)p,pCs-p);
      m.update((unsigned char *)pwd,strlen(pwd));
      m.final((unsigned char*)buf);
      bin2Hex((unsigned char *)buf,Hex,16);
   }
   if(isEqual(Hex,pCs,32)==0)
   {
      //saveFile("signture.txt",(char *)Hex,iLen);
      return -3;//invalid sign
   }
#endif
   
#if 1

#ifdef _T_DEMO_REL
   if(!isDemoTimeOk())return -4;
#endif


   cfg.iSignedCfgRead=1;
   
   int i1;
   int ui1;

#define M_FNC_INT_T(_F2_,_F1_)       {                   \
   int a=CTCfgParser::getInt(iCfgLen,p,#_F1_,i1,1);  \
   if(a==0){ _F2_ =(i1);}}

#define M_FNC_UINT_T(_F2_,_F1_)       {                   \
   int a=CTCfgParser::getInt(iCfgLen,p,#_F1_,ui1,1);  \
   if(a==0){ _F2_ =(ui1);}}

   CTCfgParser::getText2Buf(p,"hdr",&cfg.szTitle[0],sizeof(cfg.szTitle),iCfgLen);
#if defined(_WIN32) && !defined(_WIN32_WCE)
   int iExpires=0;
   M_FNC_INT_T(iExpires,iExpires);
   int get_time();
   if(iExpires && iExpires<get_time()){
      void t_exitApp(int, char *);
      t_exitApp(4,&cfg.szTitle[0]);
   }
#endif
   M_FNC_INT_T(cfg.iSignedCfgRead,iSignedCfgRead);
   M_FNC_INT_T(cfg.iAutoRegister,iAutoRegister);
   M_FNC_INT_T(cfg.iUseOnlyNatIp,iUseOnlyNatIp);
   M_FNC_INT_T(cfg.fToTagIgnore,fToTagIgnore);
   M_FNC_INT_T(cfg.iDisableChat,iDisableChat);
   M_FNC_INT_T(cfg.iDisableVideo,iDisableVideo);
   M_FNC_INT_T(cfg.iDisableBuddys,iDisableBuddys);
   M_FNC_INT_T(cfg.iAddCodecSwitch,iAddCodecSwitch);
   M_FNC_INT_T(cfg.iSwitchCodecsNetwork,iSwitchCodecsNetwork);
   M_FNC_INT_T(cfg.iIsTiViServFlag,iIsTiViServFlag);
   M_FNC_INT_T(cfg.iSkipXMLCfgServAddr,iSkipXMLCfgServAddr);
   
   M_FNC_UINT_T(cfg.uiZZRTP_bus_lic_exp_at,bleat);
   
   if(cfg.iHasAutoShowInCfg==0)
   {
      M_FNC_INT_T(cfg.iAutoShowApi,iAutoShowApi);
   }
   
   
   M_FNC_INT_T(cfg.iPayloadSizeSend3G,iPayloadSizeSend3G);
   M_FNC_INT_T(cfg.iUseVAD3G,iUseVAD3G);
   M_FNC_INT_T(cfg.iPayloadSizeSend,iPayloadSizeSend);
   M_FNC_INT_T(cfg.iUseVAD,iUseVAD);
   M_FNC_INT_T(cfg.iSettingsFlag,iSettingsFlag);
   M_FNC_INT_T(cfg.iCfgHideNumberField,iCfgHideNumberField);
   M_FNC_INT_T(cfg.iCfgUserNameAsNumber,iCfgUserNameAsNumber);
   M_FNC_INT_T(cfg.iCfgPwdAsNumber,iCfgPwdAsNumber);
   M_FNC_INT_T(cfg.iDefaultNumberInput,iDefaultNumberInput);
   M_FNC_INT_T(cfg.iUseSipBuddys,iUseSipBuddys);
   M_FNC_INT_T(cfg.iShowDevID,iShowDevID);
   M_FNC_INT_T(cfg.iPermitSSRCChange,iPermitSSRCChange);
   M_FNC_INT_T(cfg.iDisablePhonebook,iDisablePhonebook);
   M_FNC_INT_T(cfg.iDisableAdvCfg,iDisableAdvCfg);
   M_FNC_INT_T(cfg.iHideIP,iHideIP);
   M_FNC_INT_T(cfg.iResponseOnlyWithOneCodecIn200Ok,iResponseOnlyWithOneCodecIn200Ok);
   M_FNC_INT_T(cfg.iZRTP_On,iZRTP_On);
   M_FNC_INT_T(cfg.iCanAttachDetachVideo,iCanAttachDetachVideo);
   
   
   
   int fTls=0;
   
   M_FNC_INT_T(fTls,iUseTLS);
   if(fTls){
      strcpy(cfg.szSipTransport,"TLS");
   }
   
   if(cfg.iCfgHideNumberField) cfg.user.nr[0]=0;
   
   
   int iHasBud=-1;//cfg.iUseTiViBuddys;
   M_FNC_INT_T(iHasBud,iUseTiViBuddys);
   if(iHasBud!=-1)cfg.iUseTiViBuddys=iHasBud?2:0;
   

int st=cfg.iUseStun;
   cfg.iUseStun=0;
   if(0==CTCfgParser::getText2Buf(p,"stun",&cfg.bufStun[0],sizeof(cfg.bufStun),iCfgLen)){
      cfg.iUseStun=1;
   }
   else cfg.iUseStun=st;
   
   tmp=CTCfgParser::getText(p,"about",iLen,iCfgLen);
   if(strings && tmp)
   {
      strings->lAboutText.setText(tmp,iLen);
      repalceCRLF(&strings->lAboutText);
      
   }

   tmp=CTCfgParser::getText(p,"quit",iLen,iCfgLen);
   if(strings && tmp)strings->lExitText.setText(tmp,iLen);
   
   tmp=CTCfgParser::getText(p,"szApiShortName",iLen,iCfgLen);
   if(tmp){copyStrSafeCfg(cfg.szApiShortName,sizeof(cfg.szApiShortName),tmp,iLen);}
   if(strings &&tmp)strings->lApiShortName.setText(tmp,iLen);
   //   &p_cfg.szApiShortName[0]
   
   CTCfgParser::getText2Buf(p,"padd",cfg.szPwdEndAdd,sizeof(cfg.szPwdEndAdd),iCfgLen);
   CTCfgParser::getText2Buf(p,"prefix",cfg.szPrefix,sizeof(cfg.szPrefix),iCfgLen);
   CTCfgParser::getText2Buf(p,"transl",cfg.szMsgTranslateFN,sizeof(cfg.szMsgTranslateFN),iCfgLen);
   CTCfgParser::getText2Buf(p,"szSupportMail",cfg.szSupportMail,sizeof(cfg.szSupportMail),iCfgLen);
   CTCfgParser::getText2Buf(p,"szLangFN",cfg.szLangFN,sizeof(cfg.szLangFN),iCfgLen);
   CTCfgParser::getText2Buf(p,"szSkinFolder",cfg.szSkinFolder,sizeof(cfg.szSkinFolder),iCfgLen);
   CTCfgParser::getText2Buf(p,"szCountryListFN",cfg.szCountryListFN,sizeof(cfg.szCountryListFN),iCfgLen);
   
   CTCfgParser::getText2Buf(p,"szSkipAdvCfgID",cfg.szSkipAdvCfgID,sizeof(cfg.szSkipAdvCfgID),iCfgLen);
   CTCfgParser::getText2Buf(p,"szUASDP",cfg.szUASDP,sizeof(cfg.szUASDP),iCfgLen);
   CTCfgParser::getText2Buf(p,"szUA",cfg.szUA,sizeof(cfg.szUA),iCfgLen);
   CTCfgParser::getText2Buf(p,"szUNLabel",cfg.szUNLabel,sizeof(cfg.szUNLabel),iCfgLen);
   CTCfgParser::getText2Buf(p,"szPWDLabel",cfg.szPWDLabel,sizeof(cfg.szPWDLabel),iCfgLen);
   CTCfgParser::getText2Buf(p,"szSipTransport",cfg.szSipTransport,sizeof(cfg.szSipTransport),iCfgLen);
   
   CTCfgParser::getText2Buf(p,"szLicServName",cfg.szLicServName,sizeof(cfg.szLicServName),iCfgLen);
   
   CTCfgParser::getText2Buf(p,"pxifnat",cfg.bufpxifnat,sizeof(cfg.bufpxifnat),iCfgLen);
   CTCfgParser::getText2Buf(p,"pxiffw",cfg.bufpxifFW53,sizeof(cfg.bufpxifFW53),iCfgLen);
   tmp=CTCfgParser::getText(p,"gw",iLen);

   if(tmp)
   {
      copyStrSafeCfg(cfg.str32GWaddr.strVal, sizeof(cfg.str32GWaddr.strVal),tmp,iLen);
      cfg.str32GWaddr.uiLen=(unsigned int)iLen;

      if(cfg.iSkipXMLCfgServAddr)cfg.tmpServ[0]=0;
   }
   else cfg.iSignedCfgRead=0;
   if(CTCfgParser::getInt(iCfgLen,p,"gwport",iLen,iCfgLen)>=0)cfg.GW.setPort(iLen);

   int z;

   CTCfgParser::getText2Buf(p,"acodecs3g",cfg.szACodecs3G,sizeof(cfg.szACodecs3G),iCfgLen);
   CTCfgParser::getText2Buf(p,"adisabledcodecs3g",cfg.szACodecsDisabled3G,sizeof(cfg.szACodecsDisabled3G),iCfgLen);
   if(!cfg.szACodecs[0]){
      z=CTCfgParser::getText2Buf(p,"acodecs",cfg.szACodecs,sizeof(cfg.szACodecs),iCfgLen);
      CTCfgParser::getText2Buf(p,"adisabledcodecs",cfg.szACodecsDisabled,sizeof(cfg.szACodecsDisabled),iCfgLen);
      if(!cfg.szACodecs[0]){strcpy(cfg.szACodecs,"3,0,8");}
   }
   else{
      char cl[64];
      char clDis[64];
      z=CTCfgParser::getText2Buf(p,"acodecs",&cl[0],sizeof(cl),iCfgLen);
      int z1=CTCfgParser::getText2Buf(p,"adisabledcodecs",&clDis[0],sizeof(clDis),iCfgLen);
      if(z==0){
         int coAlowed[32];
         int coD[32];
         int coA[32];
         int iCnt=0;
         int iCntA=0;
         int iCntD=0;
         int iResLA=0;
         int iResLD=0;
         int fillInts(char *p, int *i, int iMaxInts);
         iCnt=fillInts(&cl[0],&coAlowed[0],15);
         if(z1==0)iCnt+=fillInts(&clDis[0],&coAlowed[iCnt],15);
         iCntA=fillInts(&cfg.szACodecs[0],&coA[0],15);
         iCntD=fillInts(&cfg.szACodecsDisabled[0],&coD[0],15);
         int hasThisInt(int *il, int iCnt, int id);
         for(int i=0;i<iCntA;i++){
            if(hasThisInt(&coAlowed[0],iCnt,coA[i]))iResLA+=snprintf(&cfg.szACodecs[iResLA],sizeof(cfg.szACodecs)-iResLA,"%d,",coA[i]);
         }
         if(iResLA)iResLA--;
         for(int i=0;i<iCntD;i++){
            if(hasThisInt(&coAlowed[0],iCnt,coD[i]))iResLD+=snprintf(&cfg.szACodecsDisabled[iResLD],sizeof(cfg.szACodecsDisabled)-iResLD,"%d,",coD[i]);
         }
         for(int i=0;i<iCnt;i++){
            if(!hasThisInt(&coA[0],iCntA,coAlowed[i]) && !hasThisInt(&coD[0],iCntD,coAlowed[i]))
               iResLD+=snprintf(&cfg.szACodecsDisabled[iResLD],sizeof(cfg.szACodecsDisabled)-iResLD,"%d,",coAlowed[i]);
         }
         if(iResLD)iResLD--;
         cfg.szACodecs[iResLA]=0;
         cfg.szACodecsDisabled[iResLD]=0;


      }

   }
   if(z==0)cfg.iEnable729=1;

   if(cfg.iSignedCfgRead)checkCfgParams(cfg);
#endif 

   return 0;
}

int getCFGItemI(int *ret, char *p, int iCfgLen, const char *key){

   int r=0;
   int a=CTCfgParser::getInt(iCfgLen,p,key,r,1);
   if(a==0){*ret=r;}
   return -1;
}
int getCFGItemSz(char *ret, int iMaxSize, char *p, int iCfgLen, const char *key){
   iMaxSize--;//zero term
   int r=CTCfgParser::getText2Buf(p,key,ret,iMaxSize,iCfgLen);
   return r<0?r:0;
}

#ifdef __SYMBIAN32__
char *getSettingsCfgLocation();
#endif

char *getSettingsContent(int &iLen)
{
   char *p=NULL;
#if defined(__APPLE__)
    char *iosLoadFile(const char *fn, int &iLen );
    p=iosLoadFile("settings.txt",iLen);
   printf("[ptr=%p]",p);
    
#elif  !defined(__SYMBIAN32__)
   CTEditBase  b(512);
   getSettingsLocation(b);
   p=loadFileW(b.getText(),iLen);
#else
   p=loadFile(getSettingsCfgLocation(),iLen);
   if(!p)
   {
      char buf[256];
      strcpy(buf,getSettingsCfgLocation());
      buf[0]='e';
      p=loadFile(buf,iLen);
   }
#endif
   return p;
}

int readSignedCfg(PHONE_CFG &cfg, CTLangStrings *strings)
{
   //return 0;
   char pwd[32];//="secret";
   void getSecret1(char*);
   
   getSecret1(pwd);
   
   pwd[2]+=('a'-'A');//to lowercase

   int iLenFile=0;

   char *p=getSettingsContent(iLenFile);

   if(iLenFile<=0 || !p)return -100;
   int ret=0;
   ret=readSignedCfg(pwd,p,iLenFile,cfg,strings);
   delete p;
   
   return ret;
}

int isContainingCodec(char *p, int id){
   while(p[0] &&  !isdigit(p[0])){
      p++;
   }
   while(*p)
   {
      int c=atoi(p);
      if(c==id)return 1;
      while(isdigit(*p))p++;
      if(*p==0)break;
      p++;
   }
      
   return 0;
}


#define ADD_CODEC(ID,ETYPE) \
{sSdp.u.codec[sSdp.codecCount].eType=SDP::ETYPE;\
sSdp.u.codec[sSdp.codecCount++].uiID=ID;}

void CSessionsBase::setCodecs(char *p, int id)
{

   if(*p==0){
      strcpy(p_cfg.szACodecs,"3,9,0,8");
   }
   else if(p!=(char *)&p_cfg.szACodecs && p!=(char *)&p_cfg.szACodecs3G)
      strcpy(p_cfg.szACodecs,p);
   

   sSdp.codecCount=0;
   int c;

   if(id==SDP::eAudio)
   {
      while(*p)
      {
        // int codecSZ_to_ID(const char *p);
         //if(isdigit(p))
        // int x=codecSZ_to_ID(p);
        // if(x==-1)
         c=atoi(p);
        // else c=x;
       //  printf("codec =%d\n",c);
         if(c>=0 || c<=127)
         {
#if defined(_T_DEMO_REL) || defined(_T_SOLD_REL) || defined(__SYMBIAN32__) || defined(__APPLE__)
            if(c!=120)
#elif  defined(_T_RELEASE_)
            if(c!=18 || p_cfg.iEnable729)
#endif
            {
               ADD_CODEC(c,eAudio)
            }
         }
         while(isdigit(*p))p++;
         if(*p==0)break;
         p++;
      }
    
#ifdef USE_JPG_VID
      p_cfg.iTinaFakeID=34;
      if(p_cfg.iTinaFakeID){
         ADD_CODEC(p_cfg.iTinaFakeID,eVideo)
      }
      else{
         ADD_CODEC(123,eVideo)
      }
#endif
      if(!p_cfg.iTinaFakeID){
          ADD_CODEC(122,eVideo)
      }

   }
   ADD_CODEC(13,eAudio)
   ADD_CODEC(101,eAudio)
}

int showSSLErrorMsgPhone(void *ret, const char *p){
   CTiViPhone *ph=(CTiViPhone*)ret;
   CTEditBuf<128> b;
   //Server TLS certificate validation error, no calls possible
   b.setText("This phone is under MITM attack,\nno calls possible.");
   ph->cPhoneCallback->registrationInfo(&b, ph->cPhoneCallback->eErrorAndOffline);
   return 0;
}

CTiViPhone::CTiViPhone(CTEngineCallBack *cPhoneCallback
                       ,CTLangStrings *strings
                       ,int iMaxSesions)
   :CPhSesions(cPhoneCallback,strings,iMaxSesions)
   ,iNextReRegSeq(0)
{
   bRun=TRUE;
   
#ifdef T_TEST_SYNC_TIMER
   // Mutex and cond variables for new time trigger
   pthread_mutex_init(&timerMutex, NULL);
   pthread_cond_init(&timerConditional, NULL);
   
   pthread_mutex_init(&timerDoneMutex, NULL);
   pthread_cond_init(&timerDoneConditional, NULL);
   
#endif
   

   memset(&sSdp,0,sizeof(SDP));
   
   p_cfg.pCTiViPhone=this;
   
   sockSip.setTLSErrCB(showSSLErrorMsgPhone,this);
   

   int iIsSymb=0;
#ifdef __SYMBIAN32__
   iIsSymb=1;
#endif

   if(iIsSymb)//!p_cfg.iSignedCfgRead)
   {

      int iWasStun=p_cfg.bufStun[0];
      char bufSt[64];
      strcpy(bufSt,p_cfg.bufStun);
      p_cfg.bufStun[0]=0;

      readSignedCfg(p_cfg,strings);
      if(!p_cfg.iSignedCfgRead){
         strcpy(p_cfg.bufStun,bufSt);
      }
      else if(iWasStun && !p_cfg.bufStun[0] && p_cfg.iSignedCfgRead){
         p_cfg.iUseStun=0;
      }
   }
   


   if(p_cfg.szMsgTranslateFN[0]){
      void* loadMsg(char *szMsgTranslateFN);
      if(!pTransMsgList)pTransMsgList=loadMsg(&p_cfg.szMsgTranslateFN[0]);
   }
   
   if(p_cfg.iUseStun){
      if(iIsSymb && p_cfg.iSignedCfgRead){
         addrStun=p_cfg.bufStun;
         addrStun.setPort(CTStun::eDefaultPort);
      }
      p_cfg.iResetStun=1;
      p_cfg.iNet=CTStun::NOT_DETECTDED;
      uiCheckNetworkTypeAt=5;
   }
   


   if(!*p_cfg.szACodecs)
      strcpy(p_cfg.szACodecs, "9.3.0.8");
   
   if(!p_cfg.iSignedCfgRead){
#ifdef __SYMBIAN32__
      if(!isContainingCodec(&p_cfg.szACodecs[0],18)){ //add hardware 729
         if(!isContainingCodec(&p_cfg.szACodecsDisabled[0],18)){
            strcat(&p_cfg.szACodecs[0],".18");
         }
      }   
#endif
      if(!isContainingCodec(&p_cfg.szACodecs[0],9)){
         if(!isContainingCodec(&p_cfg.szACodecsDisabled[0],9)){
            strcat(&p_cfg.szACodecs[0],".9");
         }
      }
      
      if(!p_cfg.szACodecs3G[0])strcpy(p_cfg.szACodecs3G,"3.9.0.8");
      
      if(!isContainingCodec(&p_cfg.szACodecs3G[0],3)){
         if(!isContainingCodec(&p_cfg.szACodecsDisabled3G[0],3)){
            strcat(&p_cfg.szACodecs[0],".3");
         }
      }   
   }
   
   setCodecs(p_cfg.szACodecs);
   
   if(p_cfg.iAutoRegister==0)
   {
      p_cfg.iCanRegister=0;
      p_cfg.iUserRegister=0;
   }
   

   if(p_cfg.iSkipXMLCfgServAddr)p_cfg.tmpServ[0]=0;
#if defined(_WIN32) || defined(ANDROID_NDK) || defined(__SYMBIAN32__) || defined(__APPLE__) || defined(__linux__)

   void checkLicenceSecondPart(PHONE_CFG &p_cfg);
   checkLicenceSecondPart(p_cfg);
   int isLicenceOk(PHONE_CFG *cfg);
   isLicenceOk(&p_cfg);

#else
   if(p_cfg.iIsLKeyValid && p_cfg.tmpServ[0])
   {
      p_cfg.str32GWaddr.uiLen=strlen(p_cfg.tmpServ);
      strcpy(p_cfg.str32GWaddr.strVal,p_cfg.tmpServ);
   }
   else p_cfg.tmpServ[0]=0;

#endif

   if(p_cfg.tmpServ[0]){
      strcpy(p_cfg.str32GWaddr.strVal,p_cfg.tmpServ);
   }
   p_cfg.str32GWaddr.uiLen=strlen(p_cfg.str32GWaddr.strVal);
   
   if(p_cfg.str32GWaddr.uiLen==0)
   {
      if(p_cfg.iSignedCfgRead){
         if(iIsSymb){
            readSignedCfg(p_cfg,strings);
         }
         else{
            PHONE_CFG *_cfg=new PHONE_CFG;
            memset(_cfg,0,sizeof(PHONE_CFG));
            readSignedCfg(*_cfg,strings);
            memcpy(&p_cfg.str32GWaddr,&_cfg->str32GWaddr,sizeof(p_cfg.str32GWaddr));
            delete _cfg;
         }
         p_cfg.str32GWaddr.uiLen=strlen(p_cfg.str32GWaddr.strVal);
      }
      if(p_cfg.str32GWaddr.uiLen==0){
         getDomain(p_cfg.str32GWaddr.strVal);
         p_cfg.str32GWaddr.uiLen=strlen(p_cfg.str32GWaddr.strVal);
      }
   }
   int iport=p_cfg.GW.getPort();
   if(!p_cfg.GW.ip) p_cfg.GW=p_cfg.str32GWaddr.strVal;
   if(iport && p_cfg.GW.getPort()==0)
      p_cfg.GW.setPort(iport);
      
   if(p_cfg.GW.getPort()==0)
      p_cfg.GW.setPort(5060);

   

}

void CTiViPhone::checkSIPTransport(){
#if 0
   if(strcmp(&p_cfg.szSipTransport[0],"TLS")==0){sockSip.setSockType(sockSip.eTLS);}
   else if(strcmp(&p_cfg.szSipTransport[0],"TCP")==0){sockSip.setSockType(sockSip.eTCP);}
   else if(strcmp(&p_cfg.szSipTransport[0],"UDP")==0){sockSip.setSockType(sockSip.eUDP);}
   else sockSip.setSockType(sockSip.eUDP);
#else
   sockSip.setSockType(p_cfg.szSipTransport);
#endif
}


void CTiViPhone::start()
{

   if(threadSip.iInThread==0)
   {
      onNewIp(cPhoneCallback->getLocalIp(),0);

      checkSIPTransport();

      ADDR addr;
      addr.setPort(p_cfg.iSipPortToBind);//5060;
      sockSip.createSock(&addr,true);

      strcpy(threadSip.thName,"_sip");
      
      threadSip.create(&CTiViPhone::thSipRec,(void *)this);


      CTMd5 md5;
      md5.update((unsigned char *)this,sizeof(*this));
      md5.update((unsigned char *)&p_cfg,sizeof(PHONE_CFG));
      iRandomCounter+=(int)md5.final();
     
   }
  
}
CTiViPhone::~CTiViPhone()
{
   bRun=0;
   Sleep(100);
 
   if(cPhoneCallback->mediaFinder)delete cPhoneCallback->mediaFinder;cPhoneCallback->mediaFinder=NULL;
};

void CTiViPhone::checkServDomainName(int iHasNewIP, int iNow){
   
   if(!hasNetworkConnect(ipBinded))return;
   
   int ok=hasNetworkConnect(p_cfg.GW.ip);
   if(ok && iHasNewIP && !iNow)return;
   int iWasOk=ok;
   
   if(!ok && !iHasNewIP && !iNow){
      int d=(int)(uiGT-uiPrevCheckGWAt);
      if(d<T_GT_MINUTE){
         return;
      }
      ok=0;
   }
   if(!ok || iNow){
      uiPrevCheckGWAt=uiGT;
      
      iCanCheckStunIP=1;
      
      CTEditBuf<32> b;
      
      trim(p_cfg.str32GWaddr.strVal);
      p_cfg.str32GWaddr.uiLen = strlen(p_cfg.str32GWaddr.strVal);
      
      p_cfg.GW=p_cfg.str32GWaddr.strVal;
      
      unsigned int gwIP=0;
      
      if(!hasNetworkConnect(p_cfg.GW.ip)){
         
         if(!iWasOk){
            b.setText("Connecting...");
            cPhoneCallback->registrationInfo(&b, cPhoneCallback->eErrorAndOffline);
         }
         printf("[res_gw %s %u]",p_cfg.str32GWaddr.strVal, getTickCount());
         gwIP=cPhoneCallback->getIpByHost(p_cfg.str32GWaddr.strVal,p_cfg.str32GWaddr.uiLen);
      }
      
      ok=hasNetworkConnect(p_cfg.GW.ip);
      
      if(p_cfg.GW.getPort()==0)p_cfg.GW.setPort(5060);
      
      if(p_cfg.bufpxifnat[0]){
         addrPx=p_cfg.bufpxifnat;
         if(addrPx.getPort()==0)addrPx.setPort(5060);
         
         if(addrPx.ip==0)
         {
            printf("[res_px %s %u]",addrPx.bufAddr, getTickCount());
            addrPx.ip=this->cPhoneCallback->getIpByHost(addrPx.bufAddr,0);
         }
         
         if(!ok){
            gwIP=p_cfg.GW.ip=addrPx.ip;
            p_cfg.GW.setPort(addrPx.getPort());
         }
      }
      else {
         addrPx.clear();
         p_cfg.GW.ip=gwIP;
      }
      
      if(!ok && !hasNetworkConnect(p_cfg.GW.ip)){
         b.setText("Resolving DNS failed");
         cPhoneCallback->registrationInfo(&b, cPhoneCallback->eErrorAndOffline);
      }
      
      if(p_cfg.iSettingsFlag & p_cfg.eSFConvertDnsToIp && hasNetworkConnect(p_cfg.GW.ip))//TODO
      {
         p_cfg.GW.toStr(p_cfg.str32GWaddr.strVal);
         p_cfg.str32GWaddr.uiLen=strlen(p_cfg.str32GWaddr.strVal);
      }
   }

}


void CTiViPhone::onNewIp(unsigned int ip, int iCanRecreate)
{
   int iPrevIp=ipBinded;
   ipBinded=ip;
   sockSip.addr.ip=ip;
//   sockAudio.addr.ip=ip;
LOCK_MUTEX_SES
   intToIPStr(ip,str64BindedAddr.strVal, sizeof(str64BindedAddr.strVal)-1);
   str64BindedAddr.uiLen=strlen(str64BindedAddr.strVal);
   if(extAddr.ip==0)//??? TODO check
      memcpy(&str64ExternalAddr, &str64BindedAddr,sizeof(str64ExternalAddr));
   //
UNLOCK_MUTEX_SES
   

   if(!hasNetworkConnect(ip))
   {
      if(!p_cfg.iUseStun)
         p_cfg.iNet=CTStun::NO_IP_STUN_OFF;

      p_cfg.iHasNetwork=0;
#ifdef __SYMBIAN32__
if(!this->iSocketsPaused)stopSockets();
#endif
      cPhoneCallback->registrationInfo(&strings.lNoConn, cPhoneCallback->eErrorAndOffline);

      extNewAddr.clear();
      
      uiCheckNetworkTypeAt=uiGT;//will check net when ip will be available
   }
   else
   {
#ifdef __SYMBIAN32__
      int iSockPaused=iSocketsPaused;
if(iSocketsPaused)startSockets();
iSockPaused=0;
#endif
      if(!p_cfg.iUseStun)
         p_cfg.iNet=CTStun::HAS_IP_STUN_OFF;
      
      p_cfg.iHasNetwork=1;
      extNewAddr.clear();
      
      
#ifndef __SYMBIAN32__
      checkServDomainName(1);//TODO  check this every 1h
#endif
      
      if(iPrevIp!=ipBinded)
      {
         uiCheckNetworkTypeAt=uiGT;
         iOptionsSent=0;
         extAddr.clear();//ipBinded
         //TODO sockSip.onNewIP(ipBinded);
         //recreat taisiit tik ja iepireksh addr bija 0 vai bija timeout 
//         if(sockSip.isTCP() && iSockPaused && iCanRecreate)sockSip.reCreate();//izveod
         if((sockSip.isTCP() || sockSip.isTLS())  && iCanRecreate)
            sockSip.reCreate();//izveod
         
         CTEditBuf<32> b;
         b.addText("IP ");
         b.addText(str64BindedAddr.strVal,(int)str64BindedAddr.uiLen);
         cPhoneCallback->info(&b,0,0);
         
         if(uiGT>T_GT_SECOND*3){//if threads are on
            sendSipKA();
            if(p_cfg.iUserRegister && p_cfg.iCanRegister)p_cfg.iReRegisterNow=1;
         }
         
      }
      reinviteMonitor.onNewIP();
     // if(p_cfg.reg.uiRegUntil==0)reInvite();
      //else will reinvite after rereg
   }
}
void CTiViPhone::restoreServ()
{
   if(addrPx.ip==0)return;
   puts("restoreServ");
   addrPx.ip=0;
   
   checkServDomainName(0);

   if(p_cfg.reg.uiRegUntil && p_cfg.reg.bReReg==0 && p_cfg.reg.bUnReg==0)
   {
      p_cfg.reg.uiRegUntil=uiGT+T_GT_SECOND;
   }

}
int CTiViPhone::canPlayRingtone(){
   CSesBase *spSes;//=getRoot();
   for (int i=0;i<iMaxSesions;i++)
   {
      spSes=getSesByIndex(i);
      if(!spSes)continue;
      
      if(spSes->cs.iBusy==FALSE)continue;
      if(spSes->cs.iCallStat==CALL_STAT::EInit 
         && spSes->cs.iCallSubStat==CALL_STAT::EWaitUserAnswer)return 1;
   }
   return 0;
}

void setExtAddrToBuf(CTiViPhone &ph, CTEditBase &b)
{
   ph.extAddr.toStr(ph.str64ExternalAddr.strVal,0);
   ph.str64ExternalAddr.uiLen=strlen(ph.str64ExternalAddr.strVal);
   
   b.addText("My Addr ext ");
   b.addText(ph.str64ExternalAddr.strVal,(int)ph.str64ExternalAddr.uiLen);
   b.addChar(':');
   b.addInt(ph.extAddr.getPort());
}

void CTiViPhone::onTimer()
{
   CSesBase *spSes;
   
   for (int i=0;i<iMaxSesions;i++)
   {
      spSes=getSesByIndex(i);
      if(!spSes || !spSes->cs.iBusy)continue;
      
      if(spSes->iDoEndCall)endCall((int)spSes);
      else if(spSes->iDoAnswerCall)answerCall((int)spSes);
      else if(spSes->uiSend480AfterTicks){
         spSes->uiSend480AfterTicks--;
         if(!spSes->uiSend480AfterTicks && spSes->cs.iCallSubStat==CALL_STAT::EWaitUserAnswer)
            endCall((int)spSes,480);
      }
   }
   
   chechRereg();
   onNetCheckTimer();
   
   if(!p_cfg.reg.bReReg && reinviteMonitor.mustReinvite(&uiGT)){
      reInvite();
   }
}


int CTiViPhone::setNewGW(CTiViPhone *ph, PHONE_CFG *cfg, char *szAddr, ADDR *a)
{
   if(!ph && !cfg)return -1;
   if(cfg && !ph)
   {
      strncpy(cfg->str32GWaddr.strVal,szAddr,sizeof(cfg->str32GWaddr.strVal)-1);
      cfg->str32GWaddr.uiLen=strlen(cfg->str32GWaddr.strVal);
      return 0;
   }
   if(!cfg)cfg=&ph->p_cfg; 
   if(!a)
   {
      URI uri;
      if(!ph)return -2;
      if(ph->checkUri(szAddr,strlen(szAddr),cfg->str32GWaddr.strVal, sizeof(cfg->str32GWaddr.strVal)-1,&uri,1)<0)
      {
         return -1;
      }
      cfg->GW=uri.addr;
   }
   else
   {
      strncpy(cfg->str32GWaddr.strVal,szAddr,sizeof(cfg->str32GWaddr.strVal)-1);
      cfg->GW=*a;
   }
   cfg->str32GWaddr.uiLen=strlen(cfg->str32GWaddr.strVal);

   return 0;
}

int CTiViPhone::cleanNumber(char *p, int iLen){
   
   char *dst=p;
   int iOutLen=0;
   int iAtFound=0;
   
   for(int i=0;i<iLen;i++){
      if(p[i] && (p[i]!='-' || iAtFound) && p[i]!='(' && p[i]!=')' && p[i]!=' '){
         dst[iOutLen]=p[i];
         iOutLen++;
         if(p[i]=='@')iAtFound=1;
      }
   }
   dst[iOutLen]=0;
   
   return iOutLen;
}

int CTiViPhone::checkUri(char *pUriIn,int iInLen, char *pUriOut, int iMaxOutSize, URI *pUri, int iCheckDomain)
{
   
   //strcpy(p_cfg.SIP_USER.un,"ab");
   int iSame=pUriIn==pUriOut;
   int iSip=0;
   if(iInLen==0)
      return -100000;
   
   iInLen=cleanNumber(pUriIn,iInLen);
   
   
   if(iInLen>4 && strncmp(pUriIn,"sip:",4)==0)
   {
      pUriIn+=4;
      iInLen-=4;
      iSip=1;
   }
   if(isPhone(pUriIn,iInLen))
   {
      if(iInLen+10+strlen(p_cfg.szPrefix)+p_cfg.str32GWaddr.uiLen>iMaxOutSize)return -1;
      
      if(iSame)
      {
         if(p_cfg.szPrefix[0]){
            int pl=strlen(&p_cfg.szPrefix[0]);
            strcpy(pUriOut,p_cfg.szPrefix);
            memmove(pUriOut+pl,pUriIn,iInLen+1);
         }
         
         if(iSip)
         {
            memmove(pUriOut,pUriIn,iInLen+1);
            //strcat(pUriOut,pUriIn);
         }
         strcat(pUriOut+iInLen,"@");
         strcat(pUriOut+iInLen,p_cfg.str32GWaddr.strVal);
      }
      else{
         if(p_cfg.szPrefix[0])
            sprintf(pUriOut,"%s%s@%s",p_cfg.szPrefix,pUriIn,p_cfg.str32GWaddr.strVal);
         else 
            sprintf(pUriOut,"%s@%s",pUriIn,p_cfg.str32GWaddr.strVal);
      }
   }
   else
   {
      
      if(!iSame || iSip){
         if(iInLen+1>=iMaxOutSize)iInLen=iMaxOutSize-1;
         memmove(pUriOut,pUriIn,iInLen+1);
      }
   }

   return parseUri(cPhoneCallback,p_cfg,pUriOut, pUri,iCheckDomain);
}



int CTiViPhone::call(char *uri, CTSesMediaBase *media, const char *contactUri, int icontactUriLen)
{
   //TODO if  (nat==mob) {add_call_to_3sec_que(); start_send_ka(); || keepAlive.sendNow(); Sleep(2000);}
   URI sUri;
   CSesBase  *spSes=NULL;
   int useDc=0;
   trim(uri);
   int len=strlen(uri);
   
   if(len>=127)return 0;

   if(len>5 && (strncmp(uri,"dc:",3)==0 || strncmp(uri,"*#*",3)==0))
   {
      useDc=1;
      uri+=3;
      len-=3;
   }
   char bufUri[128];

   int ret=checkUri(uri,len, &bufUri[0], sizeof(bufUri)-1, &sUri,useDc || !p_cfg.isOnline());

   if(ret<=0)
   {
      if(ret==-37){//TODO global  error codes
         //TODO getIPNow
         if(!::hasNetworkConnect(this->ipBinded)){

            cPhoneCallback->info(&strings.lNoConn,*(int *)"ERRO",0);
            
         }
         else {
            CTEditBuf<128> b;
            b.setText("DNS failed for ");
            b.addText(uri,len);
            cPhoneCallback->info(&b,*(int *)"ERRO",0);
         }
      }
      else 
         cPhoneCallback->info(&strings.lInvPhNr,*(int *)"ERRO",0);
      return (int)spSes;
   }

   
   LOCK_MUTEX_SES
   
   setCodecs(p_cfg.getCodecs());


   if(!useDc)
   {
      if(addrPx.ip)
      {
         sUri.addr=addrPx;
      }
      else
      if(p_cfg.reg.uiRegUntil)
      {
         sUri.addr=p_cfg.GW;
      }
   }
   
   spSes=(CSesBase  *)getNewSes(1,&sUri.addr,METHOD_INVITE);
   
   if(spSes==NULL)
   {
      UNLOCK_MUTEX_SES
      cPhoneCallback->info(&strings.lAllSesBusy,*(int *)"ERRO",0);
      return (int)spSes;
   }
   
   
   if(media==NULL)
      media=cPhoneCallback->tryGetMedia("audio");
   
   spSes->setMBase(media);
   
   
   //---add cc if necessary --
   //TODO if(isNumber(bufUri)){ if(!numberHasCC(bufUri)) add_CC_from_own_number(dst_nr, p_cfg.user.nr, bufCC);}
   char bufCC[16];
   bufCC[0]=0;
   if(sUri.iUserLen == 10 && bufUri[0]!='+' && isdigit(bufUri[0]) && p_cfg.user.nr[0]=='1' && strlen(p_cfg.user.nr)==11){
      strncpy(bufCC, "+1", sizeof(bufCC));
      bufCC[sizeof(bufCC)-1]=0;
   }
   //---add cc if necessary --end
   
   spSes->dstSipAddr.uiLen = snprintf(spSes->dstSipAddr.strVal, spSes->dstSipAddr.getMaxSize(), "sip:%s%s", bufCC, bufUri);
   printf("[dst=%.*s]\n",spSes->dstSipAddr.uiLen, spSes->dstSipAddr.strVal);
   
   if(contactUri)
   {
      if(icontactUriLen==0)
         icontactUriLen=strlen(contactUri);
      char *szToUri=spSes->sSIPMsg.rawDataBuffer+spSes->sSIPMsg.uiOffset;
      strncpy(szToUri,contactUri,icontactUriLen);
      spSes->sSIPMsg.hldContact.x[0].sipUri.dstrSipAddr.strVal=(char*)contactUri;
      spSes->sSIPMsg.hldContact.x[0].sipUri.dstrSipAddr.uiLen=icontactUriLen;
      spSes->sSIPMsg.uiOffset+=icontactUriLen;
   }
   
   cPhoneCallback->onCalling(&sUri.addr,spSes->dstSipAddr.strVal,spSes->dstSipAddr.uiLen,(int)spSes);
     
   keepAlive.sendNow();
   keepAlive.sendEverySec(1);
   CMakeSip ms(sockSip,spSes);

   media->onStart();
   ms.makeReq(METHOD_INVITE,&p_cfg);
   makeSDP(*this,spSes,ms);
   ms.addContent();
   sendSip(sockSip,spSes);
    

   UNLOCK_MUTEX_SES
   cPhoneCallback->info(&strings.lCalling,0,(int)spSes);//TODO create msg id

   //TODO return getUniqueCallIdBySes(spSes);
   return (int)spSes;
}

int CTiViPhone::hold(int iPutOnHold, int SesId){
   CSesBase *spSes=findSessionByID(SesId);
   if(!spSes)return -1;
   if( !spSes->isSession())return -2;
   int wasOnHold=spSes->cs.iIsOnHold;
   spSes->cs.iIsOnHold=iPutOnHold;
   printf("\n[sethold %d]\n",iPutOnHold);
   //if(iPutOnHold)
   if(!iPutOnHold && wasOnHold && spSes->iReceivedVideoSDP){spSes->iReceivedVideoSDP=0; reInvite(SesId,NULL);}

   return 0;
}

int CTiViPhone::answerCall(int SesId)
{
   CSesBase *spSes=findSessionByID(SesId);
   if(!spSes)return -1;
   if(!spSes->isSession())return -4;
   if(spSes->iCallingAccept)
   {
      spSes->iDoAnswerCall=1;
      return 0;
   }
   spSes->iDoAnswerCall=0;

   keepAlive.sendEverySec(0);
  LOCK_MUTEX_SES
   
   if(!spSes->cs.iBusy || spSes->cs.iCaller || spSes->cs.iCallStat!=CALL_STAT::EInit){
      UNLOCK_MUTEX_SES
      return -2;   
   }
   spSes->uiSend480AfterTicks=0;

   
   CTSesMediaBase *m=spSes->mBase;
   if(m){
      
      spSes->cs.iCallStat=CALL_STAT::EOk;
      spSes->cs.iCallSubStat=0;
      
      m->onStart();
      
      cPhoneCallback->onStartCall((int)spSes);
      
      send200Sdp(spSes);
   }
//   startSession(spSes);
   UNLOCK_MUTEX_SES

   return 0;
}


int CTiViPhone::endCall(int SesId, int iReasonCode)
{
   CSesBase *spSes=findSessionByID(SesId);
 
   if(!spSes)return -1;
   if( spSes->cs.iCallStat==CALL_STAT::EEnding)return -1;
   if(!spSes->isSession())return -1;
   if(!spSes->cs.iCallStat)return -2;
   int iMeth=0;

   if(spSes->iCallingAccept)//TODO or mutex locked
   {
      spSes->iDoEndCall=1;
      return 0;
   }
   spSes->iDoEndCall=0;
   keepAlive.sendEverySec(0);

   LOCK_MUTEX_SES
   
   if(!spSes->cs.iBusy ||  spSes->cs.iCallStat==CALL_STAT::EEnding || !spSes->isSession()|| !spSes->cs.iCallStat){
      UNLOCK_MUTEX_SES
      return -2;   
   }
   
   if (spSes->cs.iCallStat!=CALL_STAT::EInit)
   {
      iMeth=METHOD_BYE;
   }
   else if(spSes->cs.iCaller)
   {
      iMeth=METHOD_CANCEL;
   }
   spSes->cs.iCallStat=CALL_STAT::EEnding;
   spSes->iSessionStopedByCaller=1;

   CMakeSip ms(sockSip,spSes);

   if(iMeth)
   {
      ms.makeReq(iMeth,&p_cfg);
      spSes->cs.iWaitS=200;
   }
   else
   {
      spSes->cs.iCallStat=CALL_STAT::ESendError;
      spSes->cs.iWaitS=METHOD_ACK;
      ms.makeResp(iReasonCode?iReasonCode:603,&p_cfg);//603 - decline
   }
   ms.addContent();
   
   CTSesMediaBase *mb=spSes->mBase;
   spSes->setMBase(NULL);
   sendSip(sockSip,spSes);
   if(mb)mb->onWillStop();
 
   spSes->iOnEndCalled=1;
   
   UNLOCK_MUTEX_SES

   if(mb)
   {
      cPhoneCallback->mediaFinder->release(mb);
   }
   
  
   cPhoneCallback->onEndCall((int)spSes);
   
   cPhoneCallback->info(&strings.lCallEnded,0,(int)spSes);
   return 0;
}

int saveDstr(char *pToSave, unsigned int &uiOffset,DSTR *dstr,char *p,unsigned int uiPLen)
{
   char *pStore=pToSave+uiOffset;
   uiOffset+=uiPLen+1;
   dstr->strVal=pStore;
   strncpy(pStore,p,uiPLen);
   pStore[uiPLen]=0;
   dstr->uiLen=uiPLen;
   return 0;
}

int CTiViPhone::isDstOnline(const char *dst, int *resp, CTEditBase *retMsg){
   *resp=0;
   int ses=sendSipMsg(0,"OPTIONS",(char*)dst,NULL,NULL);
   CSesBase *spSes=findSessionByID(ses);
   if(!spSes){
      *resp=-1;
      return 0;
   }
   spSes->ptrResp=resp;
   spSes->retMsg=retMsg;
   return ses;
}

void CTiViPhone::removeRetMsg(int SesId){
   LOCK_MUTEX_SES
   
   CSesBase *spSes=findSessionByID(SesId);
   
   if(!spSes || !spSes->cs.iBusy){
      UNLOCK_MUTEX_SES
      return ;
   }
   spSes->ptrResp=NULL;
   spSes->retMsg=NULL;
   
   UNLOCK_MUTEX_SES
}



int CTiViPhone::sendSipMsg(int ises, const char *szMeth, char * uri, const char *szCType, CTStrBase *e, char *pSipParams, int iSipParamLen)
{
   URI sUri;
   CSesBase  *spSes=NULL;
   MSG_CTX *pCtx=(MSG_CTX *)ises;//TODO fix

   char bufUri[128];
   int ret;

   if(uri==NULL)
   {
      if(p_cfg.GW.ip)
      {
         uri=p_cfg.str32GWaddr.strVal;
         sUri.clear();
         sUri.addr=p_cfg.GW;
         ret=p_cfg.str32GWaddr.uiLen;
         strcpy((char *)&bufUri,uri);
      }
      else
         ret=-1;
   }
   else
   {
      ret=checkUri(uri,strlen(uri), (char *)&bufUri[0], sizeof(bufUri)-1, &sUri ,!(pCtx && pCtx->addrRec.ip));
   }
   if(ret<=0)
   {
      
      if(pCtx)
      {
         CHAT_MSG cm(&strings.lInvPhNr);
         cPhoneCallback->message(&cm,*(int *)"ERRO",pCtx->iRet,NULL,0);
      }
      else
         cPhoneCallback->info(&strings.lInvPhNr,*(int *)"ERRO",ises);

      return (int)spSes;
   }

   LOCK_MUTEX_SES
   if(addrPx.ip)
   {
      sUri.addr=addrPx;
   }
   else if(p_cfg.reg.uiRegUntil)
   {
      sUri.addr=p_cfg.GW;
   }
   spSes=(CSesBase  *)getNewSes(1,&sUri.addr);
   if(spSes==NULL)
   {
      UNLOCK_MUTEX_SES

      if(pCtx)
      {
         CHAT_MSG cm(&strings.lAllSesBusy);
         cPhoneCallback->message(&cm,*(int *)"ERRO",pCtx->iRet,NULL,0);
      }
      else
         cPhoneCallback->info(&strings.lAllSesBusy,*(int *)"ERRO",ises);

      return (int)spSes;
   }
   if(pCtx)
   {
      //setInfo(uri);
      
      spSes->iReturnParam=pCtx->iRet;
      pCtx->addrRec=sUri.addr;
      if(pCtx->str128CID.uiLen)
      {
         saveDstr(spSes->sSIPMsg.rawDataBuffer,spSes->sSIPMsg.uiOffset,&spSes->sSIPMsg.dstrCallID,
            pCtx->str128CID.strVal,pCtx->str128CID.uiLen);
      }
      else
      {
         //set
         CPY_DSTR(pCtx->str128CID,spSes->sSIPMsg.dstrCallID,120);
      }

      if(pCtx->str128Contact.uiLen)
      {
        // setInfo(pCtx->str128Contact.strVal,pCtx->str128Contact.uiLen);
         saveDstr(spSes->sSIPMsg.rawDataBuffer,spSes->sSIPMsg.uiOffset,&spSes->sSIPMsg.hldContact.x[0].sipUri.dstrSipAddr,
            pCtx->str128Contact.strVal,pCtx->str128Contact.uiLen);
      }

   }
   spSes->dstSipAddr.uiLen = snprintf(
                                      &spSes->dstSipAddr.strVal[0],
                                      spSes->dstSipAddr.getMaxSize()-1,
                                      "sip:%s",bufUri
                                      );
   
   
   CMakeSip ms(sockSip,spSes);
   int iMeth=METHOD_MESSAGE;
   if(szMeth)
   {
      if(strcmp(szMeth,"OPTIONS")==0)iMeth=METHOD_OPTIONS;
      else if(strcmp(szMeth,"SUBSCRIBE")==0)iMeth=METHOD_SUBSCRIBE;
      else if(strcmp(szMeth,"PUBLISH")==0)iMeth=METHOD_PUBLISH;
   }
   ms.makeReq(iMeth,&p_cfg);//TODO string
   if(pCtx && pCtx->str256RouteList.uiLen)//TODO check len
   {
      ms.addParams(pCtx->str256RouteList.strVal,(int)pCtx->str256RouteList.uiLen);
   }
   if(iSipParamLen && pSipParams)
   {
      ms.addParams(pSipParams,iSipParamLen);
   }
   if(e)
   {
      if(e->isASCII())
      {
         ms.addContent8(szCType,e);
      }
      else
      {
         ms.addContent16("text/plain; charset=UTF-16",e);
        // iUni=1;
      }
   }
   else
   {
      ms.addContent();
   }
   sendSip(sockSip,spSes);

   UNLOCK_MUTEX_SES

   return (int)spSes;
}
int CTiViPhone::addRegister(char *uri){
/*
   if(!hasNetworkConnect())
   { 
      //TODO
      info
      try later
      if(unreg) rem old contact later and save into file
        
      return 0;
   } 
*/
   //TODO check old sip-contact-hdr and save new into file

   if(!*p_cfg.user.un  || !*p_cfg.user.pwd)
   {
      cPhoneCallback->info(&strings.lEnterUN_PWD,*(int*)"UNPW",1);
      cPhoneCallback->registrationInfo(&strings.lEnterUN_PWD, cPhoneCallback->eErrorAndOffline);
      return 0;
   }

   if(!p_cfg.GW.ip && !addrPx.ip ){
      CTEditBase b("Connecting...");//TODO
      cPhoneCallback->registrationInfo(&b, cPhoneCallback->eErrorAndOffline);
      return 0;//TODO
   }

   CSesBase  *spSes=NULL;
   
   LOCK_MUTEX_SES
   
   if(uri==NULL)
   {
      uri=p_cfg.str32GWaddr.strVal;
   }
   URI sUri;

   parseUri(cPhoneCallback,p_cfg,uri,&sUri);
   
   if(p_cfg.uiPrevExpires==0)p_cfg.uiPrevExpires=p_cfg.uiExpires;
#ifdef __APPLE__
   //apple ios backgrouding wakes up device only every 600 sec
   if(p_cfg.uiExpires<800 && !p_cfg.iIsInForeground){
      p_cfg.uiPrevExpires=p_cfg.uiExpires;
      p_cfg.uiExpires=800;
   }
#endif

   if(p_cfg.uiExpires<20)p_cfg.uiExpires=20;
   else if(p_cfg.uiExpires>3600*24)p_cfg.uiExpires=3600*24;
   
   if(uiNextRegTry && p_cfg.reg.uiRegUntil>uiNextRegTry){
      unsigned int uiDif=(p_cfg.reg.uiRegUntil-uiNextRegTry);
      if(uiDif>T_GT_SECOND*20){
         uiNextRegTry = uiGT+uiDif*2/3;
      }
      else{
         uiNextRegTry = 0;
      }
   }

   if(addrPx.ip)
   {
      sUri.addr=addrPx;
   }
   
   p_cfg.GW=sUri.addr;
   
   if(!p_cfg.GW.ip){
      CTEditBuf<32> b;
      b.setText("Connecting...");
      cPhoneCallback->registrationInfo(&b, cPhoneCallback->eErrorAndOffline);
      if(p_cfg.reg.bUnReg){
         //setOffline
      }
      UNLOCK_MUTEX_SES
      return 0;
   }

   
   if(!p_cfg.reg.bUnReg)p_cfg.iReRegisterNow=0;
   
   spSes = getNewSes(1,&p_cfg.GW,METHOD_REGISTER);
   if(spSes)
   {

      if(!p_cfg.reg.bUnReg)
      {
         if(iRegTryParam==0){uiNextRegTry=uiGT+T_GT_SECOND*15;iRegTryParam=1;}
         else uiNextRegTry=uiGT+T_GT_MINUTE*2;//2 min
         cPhoneCallback->registrationInfo(&strings.lRegist, cPhoneCallback->eConnecting);

      }
      else
         uiNextRegTry=0;
         
      p_cfg.reg.bRegistring=1;

      *(int*)spSes->dstSipAddr.strVal=*(int*)"sip:";
      spSes->dstSipAddr.uiLen=4;
      ADD_0_STR(spSes->dstSipAddr.strVal,spSes->dstSipAddr.uiLen,uri);


      CMakeSip ms(sockSip,spSes);
      ms.makeReq(METHOD_REGISTER,&p_cfg);
      ms.addContent();

      sendSip(sockSip,spSes);
      
   }
   UNLOCK_MUTEX_SES

   
   return (int)spSes;
}
int CTiViPhone::remRegister(char *uri){

   
   if(p_cfg.reg.uiRegUntil && p_cfg.iHasNetwork)
   {
      if(p_cfg.reg.uiRegUntil>uiGT){
         p_cfg.reg.bUnReg=1;

         if(addRegister(uri)==0)
         {
            p_cfg.reg.bUnReg=0;
            p_cfg.reg.uiRegUntil=0;
         }
      }
      else p_cfg.reg.uiRegUntil=0;
   }
   return 0;
}

#define D_STR_CI(a) (a).strVal,(a).uiLen

int CTiViPhone::addMsgToWin(SIP_MSG *sMsg, char *p)//pec shis fnc sMsg lietot nedriikst
{
  if(sMsg->dstrContLen.uiVal &&
     !cChatMem.hasItem(
     (int)sMsg->hdrCSeq.uiMethodID,
      sMsg->dstrContLen.uiVal,
      (int)sMsg->dstrCallID.uiLen,
      sMsg->dstrCallID.strVal,
      (int)sMsg->hdrFrom.dstrTag.uiLen,
      sMsg->hdrFrom.dstrTag.strVal)
     )
   
  {
     //char *p=cSip.getContent()-5;
    // p -=5;
     int iUnLen=0;
     char *pp=NULL;
     int iIsUnicode=0;
     if(sMsg->hdrContType.dstrAttrib.uiLen && sMsg->hdrContType.dstrValue.uiLen)
     {
        char utf[]="UTF\r16";
        utf[4]='1' & 0xdf; //utf[4]&=0xdf;
        utf[5]='6' & 0xdf;

        iIsUnicode=CMP(sMsg->hdrContType.dstrAttrib,"CHARSET",7) &&
                   CMP(sMsg->hdrContType.dstrValue,utf,6);

     }
     if(sMsg->hdrFrom.dstrName.uiLen)
     {
        iUnLen=(int)sMsg->hdrFrom.dstrName.uiLen;
        pp=sMsg->hdrFrom.dstrName.strVal;
     }
     else if(sMsg->hdrFrom.sipUri.dstrUserName.uiLen)
     {
        iUnLen=(int)sMsg->hdrFrom.sipUri.dstrUserName.uiLen;
        pp=sMsg->hdrFrom.sipUri.dstrUserName.strVal;
     }
     else if(sMsg->hdrFrom.sipUri.dstrSipAddr.uiLen)
     {
        iUnLen=(int)sMsg->hdrFrom.sipUri.dstrSipAddr.uiLen;
        pp=sMsg->hdrFrom.sipUri.dstrSipAddr.strVal;
     }

     MSG_CTX mCtx;
     
     MSG_CTX * ctx=&mCtx;
     memset(ctx,0,sizeof(MSG_CTX));
     DSTR dstr;
     dstr.strVal=sMsg->hdrFrom.sipUri.dstrSipAddr.strVal+4;
     dstr.uiLen=sMsg->hdrFrom.sipUri.dstrSipAddr.uiLen-4;//- sip:

     CPY_DSTR(ctx->str128AddrFromTo,dstr, ctx->str128AddrFromTo.getMaxSize());
     ctx->addrRec=sMsg->addrSipMsgRec;

  //   
     int iReplaceRoute=0;

     if(sMsg->hldContact.x[0].sipUri.dstrSipAddr.uiLen)
     {
#if 1
        if(sMsg->hldRecRoute.uiCount)
        {
           iReplaceRoute=!hasRouteLR(&sMsg->hldRecRoute,0);
        }
#endif
        if(iReplaceRoute)
        {
           CPY_DSTR(ctx->str128Contact,sMsg->hldRecRoute.x[0].sipUri.dstrSipAddr,ctx->str128Contact.getMaxSize());
        }
        else
        {
           CPY_DSTR(ctx->str128Contact,sMsg->hldContact.x[0].sipUri.dstrSipAddr,ctx->str128Contact.getMaxSize());
        }
     }
#if 1
     CPY_DSTR(ctx->str128CID,sMsg->dstrCallID,ctx->str128CID.getMaxSize());//save call id,

     ctx->str256RouteList.uiLen
        =addRoute(ctx->str256RouteList.strVal, ctx->str256RouteList.getMaxSize() ,&sMsg->hldRecRoute,"Route: ",1
        ,iReplaceRoute, &sMsg->hldContact.x[0].sipUri.dstrSipAddr);
#endif 
     CHAT_MSG cm;

     cm.strMsg.p=p;
     cm.strMsg.iLen=sMsg->dstrContLen.uiVal;
     cm.strMsg.eType=iIsUnicode?CHAT_MSG::EUtf16:CHAT_MSG::EUtf8;

     cm.strUN.iLen=iUnLen;
     cm.strUN.p=pp;

     cPhoneCallback->message(&cm,0,0,(char *)ctx,sizeof(MSG_CTX));
  }
  return 0;
}

int CTiViPhone::checkAddr(ADDR *addr, int iIsRegResp)
{
   if(iNextReRegSeq==0 && extNewAddr.ip==0 && (extAddr!=*addr))//TODO ????
   {
      onNewIp(cPhoneCallback->getLocalIpNow(), 0);
      uiSuspendRegistrationUntil=0;
      
      if(iIsRegResp)extAddr=*addr;else extNewAddr=*addr;
      reinviteMonitor.onNewExtIP();

      if(p_cfg.iUseStun && uiCheckNetworkTypeAt && p_cfg.iNet==CTStun::FIREWALL)
         uiCheckNetworkTypeAt=uiGT+T_GT_SECOND;
      else 
         uiCheckNetworkTypeAt=uiGT+T_GT_MINUTE*2;

      if(!iIsRegResp){
         if(p_cfg.reg.uiRegUntil){
            

            if(!p_cfg.reg.bRegistring){
               unsigned int nextTry=uiGT+T_GT_SECOND*10;
               if(nextTry<p_cfg.reg.uiRegUntil){
                  uiNextRegTry=nextTry;
               }
            }
         }
         else{
            reRegSeq(1);//rem prev register, add new register
         }
      }
   }
   return 0;
}


int CTiViPhone::sendSipKA(int iForce, int *respCode){
   //TODO checkDNS
   
   //tivi keepalive not supported
   //iKeepaliveSupported=0;//TODO add TO CPhone
   //TODO set session return param if no connection
   //TODO rem prev option keepalives
   //TODO mark as keeplive
   //TODO send KA from one session
   
   puts("try send opt");
   if(!hasNetworkConnect( p_cfg.GW.ip)){
      checkServDomainName(0);
      return 0;
   }
   if(!iForce && uiSIPKeepaliveSentAt && uiSIPKeepaliveSentAt+10*T_GT_SECOND>uiGT)return 0;
   
   uiSuspendRegistrationUntil = uiGT+8*T_GT_SECOND;//TODO if mobile network, wait longer
   int s=sendSipMsg(0,"OPTIONS",NULL,NULL,NULL);
   //TODO find keeaplive ses
   if(s){
      iOptionsSent=1;
      
      if(respCode){
         CSesBase *spSes=findSessionByID(s);
         if(!spSes){
            *respCode=-1;
            return 0;
         }
         spSes->ptrResp=respCode;
      }
   }
   printf("[opt sent ses=%d]",s);
   uiSIPKeepaliveSentAt=uiGT;
   keepAlive.reset();
   
   
   return s;
}



int CTiViPhone::recMsg(SIP_MSG *sMsg, int rec, ADDR &addr)//called from thread
{
  // ADDR addr;
  //int rec=sockSip.recvFrom((char *)&sMsg->rawDataBuffer[0],MSG_BUFFER_SIZE-100,&addr);
//   CTCpuWakeLock wakeLock;//should it be after recv or recvfrom
 
   if(rec<0)
   {
      if(sockSip.needRecreate(1)){
         sendSipKA();
         if(p_cfg.isOnline()){
            //TODO rereg if ext_ip!=ext_prev_ip
            p_cfg.iReRegisterNow=1;
         }
      }
      Sleep(30);
      return rec;
   }


   iBytesRec+=rec;

   if (rec<MIN_SIP_MSG_LEN)
   {

      if(p_cfg.reg.bReReg==0 && p_cfg.reg.bUnReg==0 && p_cfg.reg.bRegistring==0 && keepAlive.onResp(addr,sMsg->rawDataBuffer,rec))
      {

         if(!p_cfg.iUseStun)
            p_cfg.iNet=ipBinded!=keepAlive.addrNew.ip;//*(int*)(sMsg->rawDataBuffer+4);

         checkAddr(&keepAlive.addrNew,0);

      }
      
      else if (rec<0)
      {
         Sleep(1);
      }

      return 10;
   }
   
   if(p_cfg.iDebug){
      cPhoneCallback->dbg(sMsg->rawDataBuffer,rec);;
      DEBUG_T(rec,sMsg->rawDataBuffer);
   }
   
   
   if(cSip.parseSip(rec, sMsg)<0)
   {
      DEBUG_T(0,"error: rec bad sip-----");
      return -1;
   }

   
   if(rec>0){
      uiSuspendRegistrationUntil=0;//
   }

   if (IS_NOT_ALL_REQ_SIP_FIELDS(*sMsg))
      {DEBUG_T(0,"Bad sip rec-drop");return -2;}

   sMsg->addrSipMsgRec=addr;


   LOCK_MUTEX_SES

   CSesBase *spSes = NULL;
   

   if(sMsg->sipHdr.uiMethodID & (METHOD_INVITE|METHOD_CANCEL) && !sMsg->hdrTo.dstrTag.uiLen)
   {
      spSes = findSes(D_STR_CI(sMsg->dstrCallID),NULL,0,&addr,0);//TODO check addr
      //TODO if recv invite with "to tag" send back bye
      if(!spSes){
         if(p_cfg.iGSMActive || isSecondIncomingCallFromSameUser(sMsg)){//freeSwitch, 2-nd incoming calls from same nr
            CMakeSip mm(sockSip);
            mm.cPhoneCallback=cPhoneCallback;
            mm.sendResp(sockSip,486,sMsg);
            UNLOCK_MUTEX_SES
            return 0;
         }
      }
      
   }
   else
   if(sMsg->sipHdr.uiMethodID)
      spSes=findSes(D_STR_CI(sMsg->dstrCallID),D_STR_CI(sMsg->hdrTo.dstrTag),&addr,1);
   else
      spSes=findSes(D_STR_CI(sMsg->dstrCallID),D_STR_CI(sMsg->hdrFrom.dstrTag),&addr,1);
   
   if(spSes)spSes->iRespReceived++;

   if(spSes && (sMsg->sipHdr.dstrStatusCode.uiVal==401 ||
         sMsg->sipHdr.dstrStatusCode.uiVal==407))
   {
      
      int iCSeqOk=(sMsg->hdrCSeq.dstrID.uiVal==spSes->uiSipCseq);//
      {
         CMakeSip ss(1,sockSip,sMsg);
         ss.makeResp(METHOD_ACK,&p_cfg,&spSes->dstSipAddr.strVal[0],(int)spSes->dstSipAddr.uiLen);
         ss.addContent();
         ss.sendSip(sockSip,&addr);

      }
      if(!iCSeqOk)
      {
         UNLOCK_MUTEX_SES
         tmp_log("auth !iCSeqOk");
         return 0;
      }
      int res=-1;
      
      p_cfg.fToTagIgnore=1;//SIP default
      CMakeSip ms(sockSip,spSes,sMsg);
      
// #SP-238 (spSes->cs.iCaller) received reinvite without a tag , we must have a tag if we are UAS
      if(spSes->cs.iCallStat == spSes->cs.EInit && spSes->cs.iCaller)
         ms.fToTagIgnore=p_cfg.fToTagIgnore;
      else ms.fToTagIgnore = 0;
      
      ms.makeReq(sMsg->hdrCSeq.uiMethodID,&p_cfg,&extAddr,&str64ExternalAddr);
      
      if(*p_cfg.user.un && *p_cfg.user.pwd)
      {
         char *pwd=&p_cfg.user.pwd[0];
         char bufPwd[64];
         if(*p_cfg.szPwdEndAdd)
         {
            pwd=&bufPwd[0];
            strcat(pwd,p_cfg.szPwdEndAdd);
         }

         res=ms.addAuth(p_cfg.user.un,pwd,sMsg);
      }
      else{
         
         char d[64];
         snprintf(d,sizeof(d), "[WARN: addAuth-fail, un=%d pwd=%d]",!!p_cfg.user.un[0],!!p_cfg.user.pwd[0]);
         d[63]=0;
         tmp_log(d);
      }

      if(res>=0)
      {
         if(sMsg->hdrCSeq.uiMethodID==METHOD_INVITE && spSes->isSession())
         {
            makeSDP(*this,spSes,ms);
         }
         ms.addContent();
         if(spSes->sSendTo.iRetransmitAuthAdded==0)
         {
            spSes->sSendTo.iRetransmitAuthAdded=2;
            spSes->sSendTo.setRetransmit();
         }//GPRS net
         else if(spSes->sSendTo.iRetransmitAuthAdded==2)
         {
            spSes->sSendTo.iRetransmitAuthAdded=1;
            spSes->sSendTo.setRetransmit();
         }
         if(spSes->sSendTo.iRetransmitions<0)
         {
            onKillSes(spSes,-2,sMsg,sMsg->hdrCSeq.uiMethodID);
         }
         else{
            sendSip(sockSip,spSes);
         }
      }
      else
      {     
         onKillSes(spSes,-2,sMsg,sMsg->hdrCSeq.uiMethodID);
      }
      UNLOCK_MUTEX_SES
      return 0;
   }

   if(spSes==NULL)
   {

      CMakeSip mm(sockSip);
      mm.cPhoneCallback=cPhoneCallback;

      switch(sMsg->sipHdr.uiMethodID)
      {
         case 0:
            DEBUG_T(0,"Ses does not exist");
            break;
         case METHOD_INVITE:
            //TODO if call id 
            {
               if(sMsg->hdrTo.dstrTag.strVal && sMsg->hdrTo.dstrTag.uiLen>0){
                  mm.sendResp(sockSip,486,sMsg);
                  break;
               }
               
               
               int iSent=0;
               CTSesMediaBase *media=NULL;
               //----
               spSes = getNewSes(0,&addr,METHOD_INVITE);
               if(!spSes)
               {
                  if(!iSent)
                     mm.sendResp(sockSip,486,sMsg);
                  iSent=1;
                  DEBUG_T(0,"all ses busy");
                  break;
               }
               spSes->iCallingAccept=1;
               DSTR *dstr=&sMsg->hdrFrom.sipUri.dstrSipAddr;
               if(p_cfg.iHideIP && sMsg->hdrFrom.sipUri.dstrUserName.uiLen){
                  dstr=&sMsg->hdrFrom.sipUri.dstrUserName;
               }

               int ret=cPhoneCallback->canAccept(&addr,dstr->strVal,(int)dstr->uiLen,(int)spSes,&media);
               spSes->iCallingAccept=0;
               if(ret==0 || spSes->iDoEndCall)
               {
                  mm.sendResp(sockSip,486,sMsg);
                  if(media)cPhoneCallback->mediaFinder->release(media);
                  media=NULL;
                  iSent=1;
                  freeSes(spSes);
                  spSes=NULL;
                  break;
               }

               if(media==NULL){
                  mm.sendResp(sockSip,415,sMsg);
                  iSent=1;
                  freeSes(spSes);
                  spSes=NULL;

                  break;
               }
           
               setCodecs(p_cfg.getCodecs());

               spSes->setMBase(media);
               
            }
            break;
         case METHOD_MESSAGE:
            {
               if(p_cfg.iDisableChat)
               {
                  mm.sendResp(sockSip,501,sMsg);
                  break;
               }
               mm.sendResp(sockSip,200,sMsg);
               addMsgToWin(sMsg,cSip.getContent());
            }
            break;
         case METHOD_OPTIONS:
            {
               mm.sendResp(sockSip,200,sMsg);
               
            }
            break;
         case METHOD_NOTIFY:
            {
               if(CMP(sMsg->dstrEvent,"PRESENCE",8))
               {
                  mm.sendResp(sockSip,200,sMsg);
                  if(sMsg->dstrContLen.uiVal)
                     cPhoneCallback->onContent(cSip.getContent(),sMsg->dstrContLen.uiVal,sMsg->hdrContType.dstrSubType.strVal,(int)sMsg->hdrContType.dstrSubType.uiLen,(int)spSes,sMsg->hdrCSeq.uiMethodID);
               }
               else
                   mm.sendResp(sockSip,501,sMsg);//not impl
               break;
            }
         case METHOD_REFER:
         case METHOD_SUBSCRIBE:
         case METHOD_PUBLISH:
            {
               mm.sendResp(sockSip,501,sMsg);//not impl
               break;
            }
         default:
            {
               
               if(sMsg->sipHdr.dstrStatusCode.uiVal!=481 && 
                  sMsg->sipHdr.uiMethodID!=METHOD_ACK){

                   mm.sendResp(sockSip,481,sMsg);
               }
            }
      }
   }


   if(spSes)
   {
      //TODO if !METHOD_OPTIONS and registring

      if(cSip.getContent() && sMsg->dstrContLen.uiVal)// && CMP(sMsg->hdrContType.dstrSubType,"USER\rLIST",9))
      {
         cPhoneCallback->onContent(cSip.getContent(),sMsg->dstrContLen.uiVal,sMsg->hdrContType.dstrSubType.strVal,(int)sMsg->hdrContType.dstrSubType.uiLen,(int)spSes,sMsg->hdrCSeq.uiMethodID);
         //sMsg->dstrContLen.uiVal
      }
      
      ADDR a;
      int iSetAddr=0;
      int iViaID=sMsg->hldVia.uiCount-1;
      if(sMsg->hdrCSeq.uiMethodID & (METHOD_OPTIONS|METHOD_REGISTER) &&
         sMsg->sipHdr.uiMethodID==0 && 
         sMsg->addrSipMsgRec==addr && 
         sMsg->hldVia.uiCount==1) 
      {
         iSetAddr=1;
         iViaID=0;


      }

      if(sMsg->hldVia.x[iViaID].dstrRPort.uiLen)
         a.setPort(sMsg->hldVia.x[iViaID].dstrRPort.uiVal);
      else
         a.setPort(sMsg->hldVia.x[iViaID].dstrPort.uiVal);

      if(sMsg->hldVia.x[iViaID].dstrRecived.uiLen && sMsg->hldVia.x[iViaID].dstrRecived.uiLen<20)
         a.ip=ipstr2long(sMsg->hldVia.x[iViaID].dstrRecived.uiLen,sMsg->hldVia.x[iViaID].dstrRecived.strVal);
      else
         a.ip=ipstr2long(sMsg->hldVia.x[iViaID].dstrViaAddr.uiLen,sMsg->hldVia.x[iViaID].dstrViaAddr.strVal);
      //
      if(spSes->isSession()){
         if(sMsg->sipHdr.uiMethodID){
            int ipa=a.ip;
            SWAP_INT(ipa);
            spSes->iDestIsNotInSameNet=ipa!=extAddr.ip;

         }

         onSipMsgSes(spSes,sMsg);
      }
      else {
         onSipMsg(spSes,sMsg);
      }
      if(sMsg->addrSipMsgRec==p_cfg.GW)
      {
         if(sMsg->hdrPortaBill.dstrFullRow.uiLen)
         {
            this->cPhoneCallback->onNewBalance
               (sMsg->hdrPortaBill.dstrValue.strVal,(int)sMsg->hdrPortaBill.dstrValue.uiLen,
               sMsg->hdrPortaBill.dstrCurrency.strVal,(int)sMsg->hdrPortaBill.dstrCurrency.uiLen
               );
         }
      }

      if(a.ip && iSetAddr)
      {
         UNLOCK_MUTEX_SES
         SWAP_INT(a.ip);
       //  a.setPort(a.getPort()+2);
         checkAddr(&a,sMsg->hdrCSeq.uiMethodID==METHOD_REGISTER);
         return 0;

      }
     
   }   
   
   //puts("search found\n");


     UNLOCK_MUTEX_SES

   //puts("onSipMsgSes ok\n");


   return 0;
}


int CTiViPhone::reRegSeq(int iStart=0)//TODO check
{
   if(iStart)
   {
      if(p_cfg.isOnline())
        iNextReRegSeq=1;
      else
        iNextReRegSeq=2;
   }
   // TODO ja mainaas ieksaajaa addr uzsetot areejo par 0 un dabuut aatri to

   switch(iNextReRegSeq)
   {
      case 1:
         //unregold
         iNextReRegSeq++;
         remRegister(p_cfg.str32GWaddr.strVal);
         break;
      case 2:
         if(!p_cfg.isOnline())//unregold)
         {

            extAddr=extNewAddr;
            extNewAddr.clear();
            if(p_cfg.iUseOnlyNatIp)
            {
               memcpy(&str64ExternalAddr, &str64BindedAddr,sizeof(str64ExternalAddr));
            }
            else
            {
               CTEditBuf<64> b;

               setExtAddrToBuf(*this,b);

               cPhoneCallback->info(&b,0,0);

            }
            if(p_cfg.iUserRegister)
            {
               p_cfg.iCanRegister=1;
               if(!p_cfg.isOnline())
               {

                  p_cfg.reg.bUnReg=0;
                  p_cfg.reg.bReReg=1;
                  if(0==addRegister(p_cfg.str32GWaddr.strVal))
                  {
                     p_cfg.reg.bReReg=0;
                     p_cfg.iCanRegister=0;
                  }
               }
               else
               {
                  iNextReRegSeq=0;
                  break;
               }
            }
            iNextReRegSeq++;
         }
         else iNextReRegSeq++;
         if(p_cfg.iUserRegister)
            break;
      case 3:
         if(p_cfg.reg.uiRegUntil || p_cfg.iCanRegister==0)//??
         {
            iNextReRegSeq=0;
            //oldpos reInvite();//move this after recv "200ok online"

            if(p_cfg.iUseStun && uiCheckNetworkTypeAt==0)
               uiCheckNetworkTypeAt=uiGT;
            
         }
         else iNextReRegSeq++;
         break;
      default:
         iNextReRegSeq=0;
         break;
   }
   
   return 0;
}//195.219.218.153

int CTiViPhone::reInvite(int SesId, const char *media){
   
   CSesBase *ses=findSessionByID(SesId);

   if(!ses || !ses->cs.iBusy )return -1;
   if(!ses->isSession() || ses->cs.iCallStat==ses->cs.EEnding)return -2;
   if(!ses->cs.iCaller && ses->cs.iCallStat==CALL_STAT::EInit)return -3;

   //TODO check if call is active
   LOCK_MUTEX_SES
   
   CTSesMediaBase *pm=ses->mBase;
   CTSesMediaBase *nm=NULL;
   if(!pm){
      UNLOCK_MUTEX_SES
      return -5;
   }
   if(!ses->cs.iBusy || !ses->isSession() || ses->cs.iCallStat==ses->cs.EEnding){
      UNLOCK_MUTEX_SES
      return -2;
   }
   
   if(media){
      if(ses->mBase && ses->mBase->getMediaType()==ses->mBase->eAudio && strcmp(media,"audio")==0){
         UNLOCK_MUTEX_SES
         return -3;
      }
      if(ses->mBase && ses->mBase->getMediaType()!=ses->mBase->eAudio && strcmp(media,"video")==0){
         UNLOCK_MUTEX_SES
         return -3;
      }
      
      
      nm=cPhoneCallback->tryGetMedia(media);
      if(!nm){
         UNLOCK_MUTEX_SES
         return -5;
      }
      
      
      ses->setMBase(nm);
      nm->onStart();
      
      if(pm)pm->onWillStop();
   }

   
   //TODO set flag trying add video
   
   ses->iSendingReinvite = 1;
   
   
   int iMeth = METHOD_INVITE;//METHOD_UPDATE;//METHOD_INVITE
   

   CMakeSip ms(sockSip,ses);
   ms.makeReq(iMeth,&p_cfg);
   makeSDP(*this,ses,ms);
   ms.addContent();
   
   sendSip(sockSip,ses);

   UNLOCK_MUTEX_SES
   printf("[pm %p %p]",pm,nm);
   if(pm && nm){
      cPhoneCallback->mediaFinder->release(pm);
   }
   
   
   
   return 0;
}

int CTiViPhone::reInvite()
{
   int i;
   int did=0;
   CSesBase * ses=getRoot();
   for (i=0;i<iMaxSesions;i++)
   {
      if(!ses[i].cs.iBusy)continue;
      if(ses[i].isSession())
      {
         LOCK_MUTEX_SES
         //
         if(ses[i].cs.iBusy && ses[i].isSession() && ses[i].cs.iCallStat!=CALL_STAT::EEnding){
            
            resetSesParams(&ses[i], METHOD_INVITE);
            
            if(ses[i].cs.iCaller || ses[i].cs.iCallStat!=CALL_STAT::EInit){
               
               if(!did && p_cfg.szACodecs3G[0])
               {
                  did=1;
                  setCodecs(p_cfg.getCodecs());
               }
               
               CMakeSip ms(sockSip,&ses[i]);
               ms.makeReq(METHOD_INVITE,&p_cfg);//TODO if ses is actie
               makeSDP(*this,&ses[i],ms);
               ms.addContent();
               
               sendSip(sockSip,&ses[i]);
            }
         }

         UNLOCK_MUTEX_SES
         
      }
   }
   return 0;
}

void CTiViPhone::save(){
   p_cfg.pCTiViPhone=this;
   saveCfg(&p_cfg,cPhoneCallback?cPhoneCallback->iEngineIndex:p_cfg.iIndex);//TODO saveIfIT
}
int CTiViPhone::closeEngine()
{
   if(iIsClosing)return 1;
   iIsClosing=2;

  // tivi_log("close eng");
   int i=0;
   if(p_cfg.uiPrevExpires<600 && p_cfg.uiPrevExpires>0)p_cfg.uiExpires=p_cfg.uiPrevExpires;
   p_cfg.uiPrevExpires=0;
   
   
   save();
   
   CSesBase * ses=getRoot();
   for (i=0;i<iMaxSesions;i++)
   {
      if(ses[i].cs.iBusy==FALSE)continue;
      if(ses[i].isSession())
      {
         endCall((int)&ses[i]);
         Sleep(15);
      }
   }
  
   p_cfg.iUserRegister=p_cfg.iCanRegister=0;
   
   if(!p_cfg.reg.bUnReg)
      remRegister(p_cfg.str32GWaddr.strVal);
   
   bRun=2;
   for(i=50;p_cfg.reg.uiRegUntil>uiGT+T_GT_SECOND*10 && i>0 ; i--)
   {
      Sleep(50);
   }
   
   bRun=0;//FALSE;
  
   if(cPhoneCallback->mediaFinder)
      cPhoneCallback->mediaFinder->stop();
   //tivi_log("close eng 4");

   ADDR a="127.0.0.1";
   a.setPort(sockSip.addr.getPort());;
   //tivi_log("close eng 5");

   sockSip.sendTo("1",1,&a);
   Sleep(20);
   sockSip.closeSocket();
   thTimer.wait();
   threadSip.wait();
   
   iIsClosing=1;
   
   return 0;
}

//typedef int (FNC_ADD_TEXT_CALLBACK)(short *pUni, int iMaxLen, void *pUserData);
char* splitBuf(char *pRet, char *buf)
{
   int l=0;
   while(buf[l]){
      l++;
      if(!isdigit(buf[l])){
         strcpy(pRet,buf);
         return pRet;
      }
   }

   if(l==28)
   {
      sprintf(pRet,"%.*s %.*s %.*s %.*s %.*s %.*s %.*s",4,buf,4,&buf[4],4,&buf[8],4,&buf[12],4,&buf[16],4,&buf[20],4,&buf[24]);
   }
   else
   if(l==24)
   {
      sprintf(pRet,"%.*s %.*s %.*s %.*s %.*s %.*s",4,buf,4,&buf[4],4,&buf[8],4,&buf[12],4,&buf[16],4,&buf[20]);
   }
   else
   if(l==20)
   {
      sprintf(pRet,"%.*s %.*s %.*s %.*s %.*s",4,buf,4,&buf[4],4,&buf[8],4,&buf[12],4,&buf[16]);
   }
   else
   {
      sprintf(pRet,"%.*s %.*s %.*s %.*s %.*s",3,buf,3,&buf[3],3,&buf[6],3,&buf[9],3,&buf[12]);
   }
   return pRet;
   
}

int getInfo(char *buf, int iMaxLen,CTiViPhone *ph, PHONE_CFG* cfg)
{

   int iLen=0;
   
   if(cfg && cfg->iShowDevID)
   {
      char bufId[64];
      char *t_getDevUniqID(char *buf);
      if(cfg->szDevidAbout[0]==0)t_getDevUniqID(&cfg->szDevidAbout[0]);
      char *res=splitBuf(&bufId[0],&cfg->szDevidAbout[0]);
      iLen += sprintf(buf + iLen,"\nDevice-ID:\n%s\n",res);
   }
   
   if(ph)
      iLen+=ph->getInfo(buf+iLen,iMaxLen-iLen);

   char *getBuildNr();
   iLen+=sprintf(buf+iLen,"\nBuild(%s)\n",getBuildNr());

   return iLen;
}
int getInfoCBUni(short *pUni, int iMaxLen, void *pUserData)
{
   
   CTiViPhone *p=((CTiViPhone*)pUserData);
   int iLen=p?p->strings.lAboutText.getLen():0;
   int l=0;
   if(iLen)
   {
      CTEditBuf2 b(pUni, iMaxLen);
      b.setText(p->strings.lAboutText);
      l=getInfo((char *)pUni+iLen*2,iMaxLen,p, p?&p->p_cfg:NULL);
      if(l)convert8_16((char *)pUni+iLen*2,l);
   }
   else
   {
    //  getInfo(
#ifdef _T_SOLD_REL
#ifdef L_SYMB_VERS
      l=sprintf((char *)pUni,"Version " L_SYMB_VERS "\nDeveloped by Tivi\n");
#else
      l=sprintf((char *)pUni,"Version " L_VERSION "\nDeveloped by Tivi\n");
#endif
#else
#ifdef L_SYMB_VERS
      l=sprintf((char *)pUni,"TiVi SIP Phone - Version " L_SYMB_VERS "\nDeveloped by TiVi\nMore info: www.tivi.com\n");
#else
      l=sprintf((char *)pUni,"SilentEyes - Version 1.0.1\nDeveloped by Silent Circle\nMore info: www.silentcircle.com\n");
#endif
#endif
      l+=getInfo((char *)pUni+l,iMaxLen,p,p?&p->p_cfg:NULL);
      if(l)convert8_16((char *)pUni,l);

   }
   return l+iLen;

}

int CTiViPhone::getInfo(char *buf, int iMaxLen)
{
   
   if(uiGT<T_GT_SECOND) {buf[0]=0;return 0;}
   
   int iLen=0;

   iLen += sprintf(buf + iLen,"\nYour username: %s",p_cfg.user.un);
   if(*p_cfg.user.nr)
      iLen += sprintf(buf + iLen,"\nYour No: %s",p_cfg.user.nr);
   
   if(p_cfg.isOnline() && p_cfg.reg.uiRegUntil>uiGT)
   {
      iLen+=sprintf(buf+iLen,"\nReregistration after %d sec",((int)p_cfg.reg.uiRegUntil-(int)uiGT)/T_GT_SECOND);
   }
   else
      iLen+=sprintf(buf+iLen,"\nOffline");
   
   iLen+=sprintf(buf+iLen,"\nNetwork type: %s", CTStun::getNatName(p_cfg.iNet));
   
   if(p_cfg.iNetworkIsMobile)
      iLen+=sprintf(buf+iLen,", mobile");
   
   if(p_cfg.iUseStun)
   {
      if(iPingTime)
         iLen+=sprintf(buf+iLen,". Ping %dms", iPingTime);
   }
   
   if(!hasNetworkConnect(ipBinded))
   {
      iLen+=sprintf(buf+iLen,"\n");
      iLen+=strings.lNoConn.getLen();
      convert16to8(buf+iLen,strings.lNoConn.getText(),strings.lNoConn.getLen());
   }
   else
   {
      CTEditBuf<64> b;
      iLen+=sprintf(buf+iLen,"\nIP %.*s\n",(int)str64BindedAddr.uiLen,str64BindedAddr.strVal);
      setExtAddrToBuf(*this,b);
      convert16to8(buf+iLen,b.getText(),b.getLen());//b.getLen()+1
      iLen+=b.getLen();
   }


   return iLen;
}

void CTiViPhone::onNetCheckTimer(){
   
   int iCanCheckStun=1;
#ifdef __APPLE__
   if(!p_cfg.iIsInForeground){
      iCanCheckStun=0;
   }
#endif
   
   //TODO move to mediaFinder
   if(p_cfg.iUseStun && hasNetworkConnect(ipBinded) && p_cfg.bufStun[0]){
      
      if(p_cfg.iResetStun){
         addrStun=p_cfg.bufStun;
         if(!addrStun.getPort())
            addrStun.setPort(CTStun::eDefaultPort);
         p_cfg.iResetStun=0;
         iCanCheckStunIP=1;
      }
      
      if(addrStun.ip==0 && iCanCheckStunIP)
      {
         iCanCheckStunIP=0;
         addrStun.ip = cPhoneCallback->getIpByHost(&addrStun.bufAddr[0],0);
      }
   }
   else if(!p_cfg.bufStun[0] && addrStun.ip){
      addrStun.clear();
   }
   
   if(iCanCheckStun && !iSocketsPaused && cPhoneCallback->mediaFinder && p_cfg.iUseStun && p_cfg.iUseOnlyNatIp==0 && !getMediaSessionsCnt()
      && (p_cfg.iNet==CTStun::NOT_DETECTDED || (uiCheckNetworkTypeAt && uiCheckNetworkTypeAt<uiGT)) && hasNetworkConnect(ipBinded) &&
      p_cfg.reg.bReReg==0 && p_cfg.GW.ip)
   {
      int _TODO_SET_PREV_STUN_CHECKED_IP__________FULLCONE_DET_ERR;//
      
      uiCheckNetworkTypeAt=0;
      do{
         if(ipBinded==(int)extAddr.ip)
         {
            p_cfg.iNet=CTStun::NO_NAT;
            break;
         }
         
         if(addrStun.ip==0)
         {
            break;
         }
         CTSock *so=cPhoneCallback->mediaFinder->getMediaSocket();
         CTStun st(ipBinded, so);
         
         st.addrStun=addrStun;
         st.getNatType();//TODO set pingType
         
         int iIsTcpOrTls=sockSip.isTCP()|sockSip.isTLS();
         
         if(!st.iHasStunResp)//stun is not answering
         {
            //try check port 53
            //TODO if port 53 works - notify server , use media relay on 53
            if(!iIsTcpOrTls && p_cfg.iFWInUse53==0 && (*p_cfg.bufpxifFW53 || isTiViServ(&p_cfg)))
            {
               ADDR a=*p_cfg.bufpxifFW53?p_cfg.bufpxifFW53:p_cfg.GW;
               if(a.getPort()==0)a.setPort(53);
               port53Check.addrToCheck=a;
               port53Check.test();
               p_cfg.iFWInUse53=2;
            }
            //TODO test TCP
         }
         else if(p_cfg.iFWInUse53==1)
         {
            puts("addrPx.clear()");
            p_cfg.iFWInUse53=0;
            if(!p_cfg.bufpxifnat[0])addrPx.clear();
            p_cfg.GW=addrGWOld;
         }
         
         iPingTime=st.iPingTime;
         
         uiGT+=(unsigned int)st.iTimeStamp;
         if(ipBinded==(int)st.addrExt1.ip)
         {
            st.iNatType=CTStun::NO_NAT;
         }
         else
         {
            if((*p_cfg.bufpxifnat && strcmp(addrPx.bufAddr, p_cfg.bufpxifnat)) || (addrPx.bufAddr[0] && !p_cfg.bufpxifnat[0])) {
               puts("[checkServDomainName px]");
               this->checkServDomainName(0,1);
               
               if(p_cfg.reg.uiRegUntil && p_cfg.reg.bReReg==0 && p_cfg.reg.bUnReg==0)
               {
                  p_cfg.reg.uiRegUntil=uiGT+T_GT_SECOND;
               }
            }
            
         }
         printf("[idx=%d ping=%d nat=%x]",p_cfg.iIndex, iPingTime,st.iNatType);
         
         if(p_cfg.iNet!=st.iNatType)
         {
            p_cfg.iNet=st.iNatType;
            
            if(p_cfg.iNet!=CTStun::FIREWALL && p_cfg.reg.uiRegUntil && p_cfg.reg.bReReg==0 && p_cfg.reg.bUnReg==0)
            {
               p_cfg.reg.uiRegUntil=uiGT+T_GT_SECOND;
            }
         }
         
         uiCheckNetworkTypeAt=0;
         if(p_cfg.iNet==CTStun::FIREWALL || so==NULL)
            uiCheckNetworkTypeAt=uiGT+T_GT_MINUTE*5; //after 5 min
         else if(p_cfg.iNet==CTStun::FULL_CONE && uiGT<T_GT_MINUTE*6)
            uiCheckNetworkTypeAt=uiGT+T_GT_MINUTE*10;//after 5 min
         else
            uiCheckNetworkTypeAt=uiGT+T_GT_MINUTE*300;//after 5h
      }while(0);
   }
   
   if(p_cfg.iFWInUse53==2)
   {
      if(port53Check.works()){
         printf("[pxif53w]");
         p_cfg.iFWInUse53=1;
         addrPx=port53Check.addrToCheck;
         addrGWOld=p_cfg.GW;
         p_cfg.GW=addrPx;
         uiCheckNetworkTypeAt=uiGT+T_GT_MINUTE*4;
      }
      else if(!port53Check.testing())
      {
         p_cfg.iFWInUse53=0;
         uiCheckNetworkTypeAt=uiGT+T_GT_MINUTE*4;
      }
   }
   
}

void CTiViPhone::chechRereg(){
   
   if(p_cfg.reg.uiRegUntil && p_cfg.reg.uiRegUntil+T_GT_MINUTE<uiGT){
      
      p_cfg.reg.uiRegUntil=0;
      
      CTEditBuf<64>  b;
      b.setText("Offline");
      cPhoneCallback->registrationInfo(&b,cPhoneCallback->eErrorAndOffline);
      
      if(::hasNetworkConnect(cPhoneCallback->getLocalIp())){
         sendSipKA();
      }
      p_cfg.iReRegisterNow=1;
   }
   
   reRegSeq(0);
   
#if 0
   {
      static int iVV=0;
      if((iVV&127)<6){
         printf("\n[%28s %d ip%x r=%u on%d t=%d s=%d o=%d]", p_cfg.str32GWaddr.strVal,p_cfg.iCanRegister+ p_cfg.iUserRegister,extAddr.ip,p_cfg.reg.uiRegUntil,p_cfg.isOnline(),uiGT,uiSuspendRegistrationUntil,iOptionsSent);
      }
      iVV++;
   }
#endif
   
   if(iOptionsSent>0 &&  p_cfg.iUserRegister==1 && p_cfg.iCanRegister && this->iNextReRegSeq==0 && uiSuspendRegistrationUntil<uiGT)
   {
      
      if(extNewAddr.ip && extAddr!=extNewAddr){
         extAddr=extNewAddr;
         extNewAddr.clear();
         if(p_cfg.iUseOnlyNatIp)
         {
            memcpy(&str64ExternalAddr, &str64BindedAddr,sizeof(str64ExternalAddr));
         }
         else
         {
            CTEditBuf<64> b;
            setExtAddrToBuf(*this,b);
            cPhoneCallback->info(&b,0,0);
            
         }
         p_cfg.iReRegisterNow=1;
      }
      
      if(bRun==1 && extAddr.ip &&
         
         (p_cfg.iUseStun==0 || !p_cfg.iIsInForeground || p_cfg.iNet!=CTStun::NOT_DETECTDED || p_cfg.iUseOnlyNatIp) &&
         
         ((uiNextRegTry && uiNextRegTry<uiGT) ||p_cfg.reg.uiRegUntil<uiGT || p_cfg.iReRegisterNow) &&
         p_cfg.reg.bReReg==0 &&
         p_cfg.reg.bUnReg==0 &&
         p_cfg.reg.bRegistring==0 &&
         *p_cfg.user.un  && *p_cfg.user.pwd)
      {
         
         if(hasNetworkConnect(ipBinded))//TODO
         {
            uiNextRegTry=uiGT+T_GT_MINUTE*3;//3 min
            p_cfg.reg.bReReg=1;
            p_cfg.reg.bUnReg=0;
            if(0==addRegister())
               p_cfg.reg.bReReg=0;
         }
         else uiNextRegTry=uiGT+T_GT_SECOND*30;//30 sec
      }
   }
   if(p_cfg.iUserRegister && (uiNextRegTry==0 || (uiNextRegTry && uiGT>uiNextRegTry)) && p_cfg.reg.bReReg==0 && p_cfg.reg.bUnReg==0)
      p_cfg.iCanRegister=1;
   ///TODO move to thread like apple android main::checkCfgChanges
   //TODO destroy changeUserParams use thread
   if(p_cfg.changeUserParams.iSeq)
   {
      if(p_cfg.changeUserParams.iSeq==1)
      {
         p_cfg.changeUserParams.iSeq=2;
         p_cfg.iCanRegister=0;
         remRegister(NULL);
      }
      else if(p_cfg.changeUserParams.iSeq==3)
      {
         p_cfg.changeUserParams.iSeq=0;
         memcpy(&p_cfg.user,&p_cfg.changeUserParams,sizeof(PHONE_CFG::_SIP_USER));
         save();
         memset(&p_cfg.changeUserParams,0,sizeof(PHONE_CFG::_SIP_USER));
         p_cfg.iCanRegister=1;
      }
   }
   if(addrPx.ip && *p_cfg.bufpxifnat==0 && p_cfg.iFWInUse53==0)
   {
      restoreServ();
   }
   
}



int CTiViPhone::parseUri(CTEngineCallBack *cPhoneCallback,PHONE_CFG& p_cfg,char *szUri, URI *uri, int iCheckDomain)
{
   char *p;
   int iLen=-1;
   int atFound=0;
   int iDots=0,i;
   int iIsAlfaNum=1;
   int iPrev=1;
   int iIsDigitsOrDots=1;
   //trim
   //memset(uri,0,sizeof(URI));
   uri->clear();
   szUri=trim(szUri);
   p=szUri;
   uri->pUser=p;
   for(i=0;;i++,szUri++)
   {
      iLen++;
      
      if(iIsDigitsOrDots)iIsDigitsOrDots=isdigit(*szUri) || *szUri=='.' || *szUri==':';
      iIsAlfaNum=isalnum(*szUri);
      // if(i==0 && iIsAlfaNum==0)
      //    return -1;
      if(iIsAlfaNum==0 && iPrev==0)
      {
         return -2;
      }
      switch(*szUri)
      {
            
         case '&':
         case '?':
            if(!atFound || iDots==0)return -31;
         case 0:
         case ':':
            if(iLen<5)
            {
               return -33;
            }
            if(uri->addr.ip==0)
            {
               int iIpLen=iLen;
               if(uri->iUserLen)
                  iIpLen-=(uri->iUserLen+1);
               //getIp
               //check end
               // printf("[%.*s]\n",iIpLen,p);
               // uri->addr.ip=1;
               if(iDots==0)
               {
                  return -35;
               }
               if(iDots==3 && iIsDigitsOrDots && isdigit(p[0]) && isdigit(p[iIpLen-1]))
               {
                  uri->addr.ip=(int)ipstr2long(iIpLen,p);
                  if(uri->addr.ip)
                     SWAP_INT(uri->addr.ip)
                     }
               else
               {
                  if(iCheckDomain)
                  {
                     //TODO
                     if(p_cfg.GW.ip && p_cfg.str32GWaddr.strVal && strncmp(p_cfg.str32GWaddr.strVal,p,iIpLen)==0)
                     {
                        uri->addr.ip=p_cfg.GW.ip;
                     }
                     else
                     {
                        uri->addr.ip=cPhoneCallback->getIpByHost(p,iIpLen);//CTSock::getHostByName(p,iIpLen);
                        if(p_cfg.iSettingsFlag & p_cfg.eSFConvertDnsToIp && strncmp(p_cfg.str32GWaddr.strVal,p,iIpLen)==0)
                        {
                           p_cfg.GW.toStr(p_cfg.str32GWaddr.strVal);
                           p_cfg.str32GWaddr.uiLen=strlen(p_cfg.str32GWaddr.strVal);
                        }
                     }
                     if(uri->addr.ip==0)
                        return -37;
                  }
                  //  uri->addr.ip=(int)ipstr2long(iIpLen,p);
                  //gethostname
               }
               
               
               
            }
            if(*szUri==':')
            {
               szUri++;
               iLen++;
               uri->addr.setPort(strToUint(szUri));
               iDots=0;
               while(isdigit(*szUri))
               {
                  szUri++;
                  iLen++;
               }
            }
            else
               uri->addr.setPort(DEAFULT_SIP_PORT);
            if(*szUri==0)
            {
               if(i==0)
                  return -3;
               if(!iPrev)
                  return -4;
               return iLen;
            }
            
         case '.':
            iDots++;
            break;
         case '@':
            iDots=0;
            iIsDigitsOrDots=1;
            if(atFound)return -1;
            uri->iUserLen=iLen;
            uri->pUser=p;
            atFound=1;
            // printf("[%.*s]\n",iLen,p);
            p=szUri+1;
            break;
         case '*':
         case '#':
         case '+':
            iIsAlfaNum=1;
         case '-':
         case '_':
         case '=':
            
            break;
            
         default:
            if(!iIsAlfaNum)
            {
               return -1;
            }
      }
      iPrev=iIsAlfaNum;
      
   }
   return iLen;
}

