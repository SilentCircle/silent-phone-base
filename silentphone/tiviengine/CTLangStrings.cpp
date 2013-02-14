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

#include <string.h>
#include "CTLangStrings.h"



void CTLangStrings::constrLatv()
{
   lInvPhNr.setText("Kljuudains telefona numurs");
   lAllSesBusy.setText("Visas sesijas aiznemtas");
   lError.setText("Kljuuda");
   
   lConTimeOut.setText("Nevar savienoties");
   lCannotDeliv.setText("Nevar nosuutiit zinju");
   lCannotReg.setText("Nevar pieregistreeties");
   lCannotCon.setText("Nevar izveidot savienojumu");
   lReason.setText("Iemesls:\r\n");
   lNoConn.setText("Nav piesleeguma");
   lCalling.setText("Zvanu...");
   lRegist.setText("Registreejos..");
   
   lCallEnded.setText("Zvans izbeigts");
   lRegSucc.setText("Registreeshanaas veiksmiiga");
   lMissCall.setText("Missed call");
   lIncomCall.setText("Ienaakoshais zvans no");
   lConnecting.setText("Savienojos ar tiiklu");
   
   
   lMyUN.setText("Mans lietotaajvards");
   
   lMyPwd.setText("Mana parole");
   lMyPhNr.setText("Mans tivi numurs");
   lFind.setText("Mekleet");
   
   lConfig.setText("Konfiguraacija");
   lPhoneBook.setText("Telefongraamata");
   
   lCall.setText("Zvaniit");lHangUp.setText("Beigt");
   
   lEdit.setText("Labot");
   lRemove.setText("Dzeest");
   lAdd.setText("Pievienot");
   
   lAbout.setText("Par");
   lLogin.setText("Login");
   lLogout.setText("Logout");
   lExit.setText("Iziet");
   
   lDialledNumbers.setText(" Zvaniitie numuri->");
   lReceivedCalls.setText("<-Sanjemtie zvani->");//,lMissedCalls;
   lMissedCalls.setText("<-Nesanemties zvani ");
   lToEnterCfgLogout.setText("Lai labotu, izlogoties");
   lDeleteEntryFromList.setText("Vai dzeest ierakstu no saraksta?");
   
   lVideoCall.setText("Video Call");
}
void CTLangStrings::constrJap()
{
   
   lInvPhNr.setText("\x53\x30\x6e\x30\x6a\x75\xf7\x53\x6b\x30\x4b\x30\x51\x30\x89\x30\x8c\x30\x7e\x30\x5b\x30\x93\x30",12,1); 
   lAllSesBusy.setText("\x59\x30\x79\x30\x66\x30\x6e\x30\xa5\x63\x9a\x7d\x4c\x30\x7f\x4f\x28\x75\x2d\x4e\x67\x30\x59\x30",12,1);
   lError.setText("\xa8\x30\xe9\x30\xfc\x30",3,1);
   lConTimeOut.setText("\xbf\x30\xa4\x30\xe0\x30\xa2\x30\xa6\x30\xc8\x30",6,1); 
   lCannotDeliv.setText("\xe1\x30\xc3\x30\xbb\x30\xfc\x30\xb8\x30\x92\x30\x01\x90\xe1\x4f\x67\x30\x4d\x30\x7e\x30\x5b\x30\x93\x30",13,1);  
   lCannotReg.setText("\x7b\x76\x32\x93\x67\x30\x4d\x30\x7e\x30\x5b\x30\x93\x30",7,1);   
   lCannotCon.setText("\xa5\x63\x9a\x7d\x67\x30\x4d\x30\x7e\x30\x5b\x30\x93\x30",7,1);  
   // :\r\n
   //   lReason.setText("\x9f\x53\xe0\x56\x3a\0\x5c\0\x72\0\x5c\0\x6e\0",7,1); 
   lReason.setText("\x9f\x53\xe0\x56:\0 \0\r\0\n\0",6,1); 
   lNoConn.setText("\xa5\x63\x9a\x7d\x57\x30\x66\x30\x44\x30\x7e\x30\x5b\x30\x93\x30",8,1);
   lCalling.setText("\xa5\x63\x9a\x7d\x2d\x4e\xfb\x30\xfb\x30",5,1);  
   lRegist.setText("\x7b\x76\x32\x93\x2d\x4e\xfb\x30\xfb\x30",5,1);  
   lCallEnded.setText("\xa5\x63\x9a\x7d\x42\x7d\x86\x4e",4,1);  
   lRegSucc.setText("\x7b\x76\x32\x93\x8c\x5b\x86\x4e",4,1);  
   lMissCall.setText("\x0d\x4e\x28\x57\x40\x77\xe1\x4f",4,1);   
   lIncomCall.setText("\xd7\x53\xe1\x4f\x48\x51",3,1);  
   lConnecting.setText("\xa4\x30\xf3\x30\xbf\x30\xfc\x30\xcd\x30\xc3\x30\xc8\x30\x6b\x30\xa5\x63\x9a\x7d\x2d\x4e\xfb\x30\xfb\x30",13,1);  
   lMyUN.setText("\xed\x30\xb0\x30\xa4\x30\xf3\x30\x0d\x54",5,1);  
   lMyPwd.setText("\xd1\x30\xb9\x30\xef\x30\xfc\x30\xc9\x30",5,1);   
   lMyPhNr.setText("\x54\0\x69\0\x56\0\x69\0\xfb\x96\x71\x8a\x6a\x75\xf7\x53",8,1);  
   lFind.setText("\x1c\x69\x22\x7d",2,1);
   lConfig.setText("\x2d\x8a\x9a\x5b",2,1); 
   lPhoneBook.setText("\xfb\x96\x71\x8a\x33\x5e",3,1); 
   
   lCall.setText("\x7a\x76\xe1\x4f",2,1); 
   lHangUp.setText("\xd7\x53\xe1\x4f",2,1); 
   
   lEdit.setText("\xe8\x7d\xc6\x96",2,1);  
   lRemove.setText("\x64\x96\xbb\x53",2,1); 
   lAdd.setText("\xfd\x8f\xa0\x52",2,1);  
   lAbout.setText("\xd8\x30\xeb\x30\xd7\x30",3,1);  
   lLogin.setText("\xed\x30\xb0\x30\xa4\x30\xf3\x30",4,1);  
   lLogout.setText("\xed\x30\xb0\x30\xa2\x30\xa6\x30\xc8\x30",5,1);
   lExit.setText("\x42\x7d\x86\x4e",2,1);    
   lDialledNumbers.setText("\x20\0\x20\0\x7a\x76\xe1\x4f\x6a\x75\xf7\x53\x2d\0\x3e\0",8,1);  
   lReceivedCalls.setText("\x3c\0\x2d\0\xd7\x53\xe1\x4f\x6a\x75\xf7\x53\x2d\0\x3e\0",8,1);//,lMissedCalls;   
   lMissedCalls.setText("\x3c\0\x2d\0\x0d\x4e\x28\x57\x40\x77\xe1\x4f\x20\0",7,1);  
   lToEnterCfgLogout.setText("\x09\x59\xf4\x66\x92\x30\x2d\x8a\x9a\x5b\x59\x30\x8b\x30\x6b\x30\x6f\x30\xed\x30\xb0\x30\xa2\x30\xa6\x30\xc8\x30\x59\x30\x8b\x30\xc5\x5f\x81\x89\x4c\x30\x42\x30\x8a\x30\x7e\x30\x59\x30",23,1); 
   lDeleteEntryFromList.setText("\x53\x30\x6e\x30\xa8\x30\xf3\x30\xc8\x30\xea\x30\xfc\x30\x92\x30\xea\x30\xb9\x30\xc8\x30\x4b\x30\x89\x30\x4a\x52\x64\x96\x57\x30\x7e\x30\x59\x30\x4b\x30\x1f\xff",20,1); 
   //lEnterUN_PWD.setText("Enter username and password");
   lEnterUN_PWD.setText("\xe6\x30\xfc\x30\xb6\x30\xfc\x30\x0d\x54\x68\x30\xd1\x30\xb9\x30\xef\x30\xfc\x30\xc9\x30\x92\x30\x65\x51\x9b\x52\x57\x30\x66\x30\x4f\x30\x60\x30\x55\x30\x44\x30",20,1);
   lRunAtStartup.setText("Run at startup");
   
   lVideoCall.setText("Video Call");
}
void CTLangStrings::constrItalian()
{
   lInvPhNr.setText("Numero di telefono non valido ");
   lAllSesBusy.setText("Tutte le sessioni sono occupate. ");
   lError.setText("Errore");
   
   lConTimeOut.setText("Richiesta scaduta");
   lCannotDeliv.setText("Impossibile inviare il messaggio. ");
   lCannotReg.setText("Non puÚ registrare. ");
   lCannotCon.setText("Impossibile collegarsi. ");
   lReason.setText("Motivo: \r\n");
   lNoConn.setText("Nessun collegamento");
   lCalling.setText("Chiamata...");
   lRegist.setText("Registrazione..");
   
   lCallEnded.setText("Chiamata conclusa");
   lRegSucc.setText("Registrazione riuscita");
   lMissCall.setText("Chiamata sig.na");
   lIncomCall.setText("Chiamata ricevuta da");
   lConnecting.setText("Collegando ad internet...");
   
   
   lMyUN.setText("Nome Utente");
   
   lMyPwd.setText("Password");
   lMyPhNr.setText("Numero di Telefono");
   lFind.setText("Cerca");
   
   lConfig.setText("Configurazione");
   lPhoneBook.setText("Rubrica");
   
   lCall.setText("Chiama");//no nokia tel
   lHangUp.setText("Fine");//no nokia tel
   
   lEdit.setText("Modifica");//no nokia tel
   lRemove.setText("Cancella");//no nokia tel
   lAdd.setText("Aggiungi");//no nokia tel
   
   lAbout.setText("Info");
   lLogin.setText("Entra");
   lLogout.setText("Esci");
   lExit.setText("Uscita");
   
   lDialledNumbers.setText(" Chiamate effettuate>");//no nokia tel
   lReceivedCalls.setText("<Chiamate ricevute>");//,lMissedCalls;
   lMissedCalls.setText("<Chiamate Perse");
   lToEnterCfgLogout.setText("Prima devi Uscire");
   lDeleteEntryFromList.setText("Entrata di cancellazione dalla lista?");
   
   lEnterUN_PWD.setText("Enter username and password");
   lRunAtStartup.setText("Parti all'avvio");
   
   lVideoCall.setText("Video Call");
   //Options Opzioni //no nokia tel
}

short * getLine(short *line, short *end, char *name, int iMaxNameLen, int &iNameLen,CTEditBase *val){
   short *s=line;
   char *ps=(char*)s;
   int iBigEnd=(ps[0]==0);
   if(iBigEnd){
      
      iNameLen=0;
      name[0]=0;
      while(s<end){
         if(s[0]==('^'<<8)){name[iNameLen]=0;s++;break;}
         name[iNameLen]=s[0]>>8;
         if(iNameLen+1<iMaxNameLen)iNameLen++;
         s++;
      }
      //if(s>=end)return end;
      while((s[0]&0xff00) ){
         //&& s[0]<=(' '<<8)
         int c=(((s[0]>>8)&0xff)|((s[0]<<8)&0xff00))&0xffff;
         if(c>' ')break;
         s++;
      }
      val->setLen(0);
      while(s<end){
         if(s[0]==('\\'<<8)){
            if(s[1]==('n'<<8)){val->addChar('\n');s+=2;continue;}
            else if(s[1]==('r'<<8)){val->addChar('\r');s+=2;continue;}
            
         }
         if(s[0]==('\n'<<8) || s[0]==('\r'<<8))break;
         int c=(((s[0]>>8)&0xff)|((s[0]<<8)&0xff00))&0xffff;
         val->addChar(c);
         s++;
      }
      //if(s>=end)return end;
      //      while((s[0]&0xff00) && s[0]<(' '<<8))s++;
      while((s[0]&0xff00) ){
         //&& s[0]<=(' '<<8)
         int c=(((s[0]>>8)&0xff)|((s[0]<<8)&0xff00))&0xffff;
         if(c>=' ')break;
         s++;
      }
      
   }
   else{
      
      iNameLen=0;
      name[0]=0;
      while(s<end){
         if(s[0]=='^'){name[iNameLen]=0;s++;break;}
         name[iNameLen]=s[0];
         if(iNameLen+1<iMaxNameLen)iNameLen++;
         s++;
      }
      //if(s>=end)return end;
      while(((unsigned short*)s)[0]<=' ')s++;
      val->setLen(0);
      while(s<end){
         if(s[0]=='\\'){
            if(s[1]=='n'){val->addChar('\n');s+=2;continue;}
            else if(s[1]=='r'){val->addChar('\r');s+=2;continue;}
            
         }
         if(s[0]=='\n' || s[0]=='\r' || s[0]==0)break;
         val->addChar((unsigned short)s[0]);
         s++;
      }
      //if(s>=end)return end;
      while(s[0]<' ')s++;
      
   }
   while(0){
      //<=' '
      int iLastC=val->getChar(val->getLen()-1);
      if(iLastC>' ')break;
      if(iLastC=='\n')break;
      val->remLastChar();
   }
   
   return s;
}
int CTLangStrings::loadLang(CTEditBase *langFile){
   int iLen;
   char *p=loadFileW(langFile->getText(),iLen);
   if(!p)return -1;
   void debugss(char *,int ,int);
   //debugss("loadLang1",1,1);
   
   if((unsigned char)p[0]==0xff && (unsigned char)p[1]==0xfe){
      //little endian
   }
   else if((unsigned char)p[0]==0xfe && (unsigned char)p[1]==0xff){
      //big  endian
   }
   else
      return -2;
   //debugss("loadLang2",1,1);
   
   short *sh=new short[(iLen>>1)+2];
   
   int iDataLen=(iLen+1)>>1;
   if(0&& (iLen&1)==0){
      char *tmp=p;
      while(*tmp!='l' && tmp[1]!=0){
         if(tmp<p+10){
            delete p;
            delete sh;
            return -1;
         }
         tmp++;
      }
      
      memcpy(sh,tmp,iLen+p-tmp);
      iDataLen++;
   }
   else{
      memcpy(sh,p+2,iLen-2);
   }
   
   //debugss("loadLang3",1,1);
   short *end=sh+iDataLen;
   short *tmp=sh;
   end[0]=0;
   
   char name[128];
   int iNameLen;
   CTEditBase val(1024); 
   
   while(tmp+5<end){
      //debugss("getL",val.getLen(),1);
      //debugss("getL",iNameLen,tmp[0]);
      tmp=getLine(tmp,end,&name[0],sizeof(name)-1,iNameLen,&val);
      //debugss(name,iNameLen,1);
      //debugss("val",val.getLen(),1);
      setGetTextById(&name[0],iNameLen,val,1);
      
   }
   
endFnc:
   delete p;
   delete sh;
   return 0;
   
}

void CTLangStrings::constrEng()
{
   lRestartLang.setText("Instant language switch requires phone restart, continue?");
   
   lInvPhNr.setText("Invalid phone number");
   lAllSesBusy.setText("All sessions are busy");
   lError.setText("Error");
   
   lConTimeOut.setText("Connection timed out");
   lCannotDeliv.setText("Cannot deliver a message. ");
   lCannotReg.setText("Cannot register. ");
   lCannotCon.setText("Cannot connect. ");
   lReason.setText("Reason: \r\n");
   lNoConn.setText("No connection");
   lCalling.setText("Calling...");
   lRegist.setText("Registering...");
   
   lCallEnded.setText("Call ended");
   lRegSucc.setText("Registration successful");
   lMissCall.setText("Missed call");
   lIncomCall.setText("Incoming call from");
   lConnecting.setText("Connecting to ");//i-net...");
   lConnecting.addText(lApiShortName);
   lConnecting.addText("...");
   
   
   lMyUN.setText("My login name");
   
   lMyPwd.setText("My password");
   lMyPhNr.setText("My ");
   lMyPhNr.addText(lApiShortName);
   //
   lMyPhNr.addText(" number, (if you have one)");
   
   lEnterUN_PWD.setText("Enter username and password");
   
   lFind.setText("Find");
   lConfig.setText("Config");
   lPhoneBook.setText("Phone book");
   
   lCall.setText("Call");lHangUp.setText("End call");
   
   lEdit.setText("Edit");
   lRemove.setText("Remove");
   lAdd.setText("Add");
   
   lAbout.setText("About");
   lLogin.setText("Login");
   lLogout.setText("Logout");
   lExit.setText("Exit");
   
   lDialledNumbers.setText("  Dialled numbers ->");
   lReceivedCalls.setText("<- Received calls ->");//,lMissedCalls;
   lMissedCalls.setText("<- Missed calls  ");
   lToEnterCfgLogout.setText("To enter config Logout.");
   lDeleteEntryFromList.setText("Delete entry from list?");
   
   
   lRunAtStartup.setText("Run at startup");
   lUsingAP.setText("Using AP - ");
   
   lVideoCall.setText("Video Call");
   lEnterNumberChatWith.setText("Enter the username or number you want to chat with\nand press Chat button again.");
   
   lOptions.setText("Options");
   lOk.setText("Ok");
   lCancel.setText("Cancel");
   lChat.setText("Chat");
   
   lNetworkConfiguration.setText("Network Configuration");
   lDefault.setText("Default");
   
   lSoundAlertMsg.setText("Sound an alert on incoming messages");
   lShowTSFrontMsg.setText("Show timestamp in front of messages");
   lOutputSpeakersHead.setText("Output - speakers or headset");
   lInputMicHead.setText("Input - microphone or headset");
   lNRingsDings.setText("Notifications - ring and dings");
   lAudio.setText("Audio");
   lCalls.setText("Calls");
   lEnterNumberHere.setText("Enter number here");
   
   lSend.setText("Send");
   lMyScreenName.setText("My screen name");
   lDoUWantSelectNewAp.setText("Do you want to select new access point?");
   lDontShowMsgAgain.setText("Don't show this message again.");
   
   lForYourInfo.setText("For your information");
   lNotifyMicCameraUsage.setText(
                                 "This application will use of the following "
                                 "features of your phone. If you have any questions or "
                                 "concerns, please contact us at info@tivi.com:\n\n"
                                 "* Using camera and microphone\n"
                                 "* Making a connection to the internet\n"
                                 );
   lBillableEvent.setText("Billable event");
   lAllowApiConnect.setText("Allow  this application to connect to the internet?");
   
   lKeyInvalid.setText("Licence is wrong... :(\nYou can get it from\nwww.tivi.com");
   lKeyValid.setText("Thank You,\nkey is valid.");
   
   lKeyInvalidUnlimited.setText("Can not use ZRTP in unlimited mode!\n Please enter a valid ZRTP key or get it from\nwww.tivi.com");
   lKeyInvalidActive.setText("Can not use ZRTP in active mode!\n Please enter a valid ZRTP key or get it from\nwww.tivi.com");
   
   
}

#define T_LOAD_STRINGS
#include "CTLangStrings.h"


