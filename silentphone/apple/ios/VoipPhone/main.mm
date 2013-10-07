 //
//  main.m
//  VoipPhone
//
//  Created by Janis Narbuts on 4.2.2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AppDelegate.h"
#import "KeychainItemWrapper.h"


int isBackgroundReadable(const char *fn);
void log_file_protection_prop(const char *fn);
void setFileAttributes(const char *fn, int iProtect);
char *loadFile(const  char *fn, int &iLen);
void saveFile(const char *fn,void *p, int iLen);
void bin2Hex(unsigned char *Bin, char * Hex ,int iBinLen);
int hex2BinL(unsigned char *Bin, char *Hex, int iLen);



//http://www.ios-developer.net/iphone-ipad-programmer/development/file-saving-and-loading/using-the-document-directory-to-store-files
void setFileStorePath(const char *p);
char *getFileStorePath();

void setFSPath(char *p){
   
  // char *b=getFileStorePath();
   NSString *path;
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	path = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"tivi"];
   NSError *error;
	if (![[NSFileManager defaultManager] fileExistsAtPath:path])	//Does directory already exist?
	{
      NSString * const pr = NSFileProtectionCompleteUntilFirstUserAuthentication;// NSFileProtectionNone;
      NSDictionary *d=[NSDictionary dictionaryWithObject:pr
                                                  forKey:NSFileProtectionKey];
      
		if (![[NSFileManager defaultManager] createDirectoryAtPath:path
                                     withIntermediateDirectories:NO
                                                      attributes:d
                                                           error:&error])
		{
			NSLog(@"Create directory error: %@", error);
		}
	}
   else{
      const char *str=[path UTF8String];
      
      if(!isBackgroundReadable(str)){
         setFileAttributes(str,0);
      }
   }
   
   setFileStorePath([path UTF8String]);

}


NSString *findFilePathNS(const char *fn){
   char bufFN[256];
   const char *pExt="";
   int l=strlen(fn);
   strncpy(bufFN,fn,255);
   bufFN[255]=0;
   if(l>255)l=255;
   for(int i=l-1;i>=0;i--){
      bufFN[i]=fn[i];
      if(fn[i]=='.'){
         bufFN[i]=0;
         pExt=&bufFN[i+1];
         
      }
      
   }
   printf("[f=%s ext=%s]\n",&bufFN[0],pExt);
   // return "";
   NSString *ns= [[NSBundle mainBundle] pathForResource: [NSString stringWithUTF8String:&bufFN[0]] ofType: [NSString stringWithUTF8String:pExt]];
   return ns;
   
}
const char *findFilePath(const char *fn){
   NSString *ns=findFilePathNS(fn);
   if(!ns)return NULL;
   return [ns UTF8String];
   
}


char *iosLoadFile(const char *fn, int &iLen )
{  NSString *ns=findFilePathNS(fn);
   iLen=0;
   if(!ns)return 0;
   NSData *data = [NSData dataWithContentsOfFile:ns];//autorelease];
   if(!data)return NULL;
   
   char *p=new char[data.length+1];
   if(p){
      iLen=data.length;
      memcpy(p,data.bytes,iLen);
      p[iLen]=0;
   }
   //--printf("[ptr=%p,%p]",data,p);
   //[data release];//?? crash
   return p;
}

int showSSLErrorMsg(void *ret, const char *p){
   NSLog(@"tls err --exiting %s",p);
   exit(1);
   return 0;
}

void *initARPool(){
   return (void*)[[NSAutoreleasePool alloc] init];
}
void relARPool(void *p){
   NSAutoreleasePool *pool=(NSAutoreleasePool*)p;
   [pool release];
}

void testD(){
   int get_time();
  // CFDateRef date = CFDateCreate(NULL, get_time()-kCFAbsoluteTimeIntervalSince1970);
   CFLocaleRef currentLocale = CFLocaleCopyCurrent();
   
   CFDateFormatterRef dateFormatter = CFDateFormatterCreate
   (NULL, currentLocale, kCFDateFormatterLongStyle, kCFDateFormatterLongStyle);
   
   CFStringRef formattedString = CFDateFormatterCreateStringWithAbsoluteTime
   (NULL, dateFormatter, get_time()-kCFAbsoluteTimeIntervalSince1970);//date);
   CFShow(formattedString);
   
   // Memory management
   //CFRelease(date);
   CFRelease(currentLocale);
   CFRelease(dateFormatter);
   CFRelease(formattedString);
}
void testD2(){
   int get_time();
   CFDateRef date = CFDateCreate(NULL, get_time()-kCFAbsoluteTimeIntervalSince1970);
   CFLocaleRef currentLocale = CFLocaleCopyCurrent();
   
   CFDateFormatterRef dateFormatter = CFDateFormatterCreate
   (NULL, currentLocale, kCFDateFormatterNoStyle, kCFDateFormatterShortStyle);
   
   CFStringRef formattedString = CFDateFormatterCreateStringWithDate
   (NULL, dateFormatter, date);
   CFShow(formattedString);
   
   // Memory management
   CFRelease(date);
   CFRelease(currentLocale);
   CFRelease(dateFormatter);
   CFRelease(formattedString);
}


#import <mach/mach.h>
#import <mach/mach_host.h>

void apple_log_CFStr(const char *p, CFStringRef str){
   NSLog(@"%s %@",p,str);
   
}
void apple_startup_log(const char *p){
   NSLog(@"%s\n", p);
}
void apple_log_x(const char *p){
   NSLog(@"%s", p);
}
void tmp_log(const char *p){
   NSLog(@"%s", p);
}


void tivi_log1(const char *p, int val){
   NSLog(@"%s=%d\n", p, val);
}

vm_size_t usedMemory(void) {
   struct task_basic_info info;
   mach_msg_type_number_t size = sizeof(info);
   kern_return_t kerr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
   return (kerr == KERN_SUCCESS) ? info.resident_size : 0; // size in bytes
}

unsigned int get_free_memory() {
   mach_port_t host_port;
   mach_msg_type_number_t host_size;
   vm_size_t pagesize;
   host_port = mach_host_self();
   host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
   host_page_size(host_port, &pagesize);
   vm_statistics_data_t vm_stat;
   
   if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS) {
      NSLog(@"Failed to fetch vm statistics");
      return 0;
   }
   
   /* Stats in bytes */
   unsigned int mem_free = vm_stat.free_count * pagesize;
   return mem_free;
}
void freemem_to_log(){
   unsigned int uiU=usedMemory();
   unsigned int ui=get_free_memory();
   NSLog(@"freemem=%dK, used-mem=%dK",ui>>10, uiU>>10);
}

#define T_MAX_DEV_ID_LEN 63
#define T_MAX_DEV_ID_LEN_BIN (T_MAX_DEV_ID_LEN/2)

static char bufDevID[T_MAX_DEV_ID_LEN+2];
static char bufMD5[T_MAX_DEV_ID_LEN+32+1];



void initDevID(){
   
   memset(bufDevID,0,sizeof(bufDevID));
#if 0
   //depricated  6.0
   NSString *n = [[UIDevice currentDevice]uniqueIdentifier];
   
   const char *pn=n.UTF8String;
#else
   int iDevIdLen=0;
   char fn[1024];
   snprintf(fn,sizeof(fn)-1, "%s/devid-hex.txt", getFileStorePath());
   
   char *pn=loadFile(fn, iDevIdLen);
   
   if(!pn || iDevIdLen<=0){
      
      pn=&bufDevID[0];
      
      FILE *f=fopen("/dev/urandom","rb");
      if(f){
         unsigned char buf[T_MAX_DEV_ID_LEN_BIN+1];
         fread(buf,1,T_MAX_DEV_ID_LEN_BIN,f);
         fclose(f);
         
         bin2Hex(buf, bufDevID, T_MAX_DEV_ID_LEN_BIN);
         bufDevID[T_MAX_DEV_ID_LEN]=0;
         
         saveFile(fn, bufDevID, T_MAX_DEV_ID_LEN);
         setFileAttributes(fn,0);
      }
      
   }
   
#endif
   void safeStrCpy(char *dst, const char *name, int iMaxSize);
   safeStrCpy(&bufDevID[0],pn,sizeof(bufDevID)-1);
   
   int calcMD5(unsigned char *p, int iLen, char *out);
   calcMD5((unsigned char*)pn,strlen(pn),&bufMD5[0]);
   
   
}

const char *t_getDevID(int &l){
   l=63;
   return &bufDevID[0];
}

const char *t_getDevID_md5(){

   return &bufMD5[0];
}

const char *t_getDev_name(){
   NSString *n = [[UIDevice currentDevice]model];
   return n.UTF8String;
}

int iAppStartTime; 
int get_time();

int secSinceAppStarted(){
   return get_time()-iAppStartTime;
}

void rememberAppStartupTime(){
   iAppStartTime=get_time();
}



void loadPWDKey(){
#define T_AES_KEY_SIZE 32
   NSLog(@"KC");
   unsigned char buf[T_AES_KEY_SIZE+2];
   char bufHex[T_AES_KEY_SIZE*2+2];
   memset(buf, 0, sizeof(buf));
   
   KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:@"SC-SP-key" accessGroup:nil];
   [keychain setObject:(__bridge id)kSecAttrAccessibleAlways forKey:(__bridge id)kSecAttrAccessible];
   NSString *key=[keychain objectForKey:(id)kSecValueData];
   if(!key || key.length<1){
      FILE *f=fopen("/dev/urandom","rb");
      if(f){
         
         fread(buf,1,T_AES_KEY_SIZE,f);
         bin2Hex(buf, bufHex, T_AES_KEY_SIZE);
         [keychain setObject:[NSString stringWithUTF8String: bufHex ] forKey:(id)kSecValueData];
         fclose(f);
      }
   }
   else{
      int l = key.length;
      if(l > T_AES_KEY_SIZE*2)l = T_AES_KEY_SIZE*2;
      hex2BinL(buf, (char*)key.UTF8String, l);
   }
   void setPWDKey(unsigned char *k, int iLen);
   setPWDKey(buf, T_AES_KEY_SIZE);
   
   [keychain release];
   NSLog(@"KC - ok");
}

int isBackgroundReadable(const char *fn){
   NSString *p = [[[NSFileManager defaultManager] attributesOfItemAtPath: [NSString stringWithUTF8String: fn ]
                                                                   error:NULL] valueForKey:NSFileProtectionKey];
   return [p isEqualToString:NSFileProtectionNone];
}

void log_file_protection_prop(const char *fn){
   /*
    NSFileProtectionKey
    NSFileProtectionNone
    
    */

   NSString *p = [[[NSFileManager defaultManager] attributesOfItemAtPath: [NSString stringWithUTF8String: fn ]
                                                                             error:NULL] valueForKey:NSFileProtectionKey];
   NSLog(@"[fn(%s)=%@",fn,p);
}

void setFileAttributes(const char *fn, int iProtect){
   
   NSString * const pr = iProtect? NSFileProtectionComplete : NSFileProtectionNone;
   NSDictionary *d=[NSDictionary dictionaryWithObject:pr
                                               forKey:NSFileProtectionKey];
   /*
    attributes:[NSDictionary dictionaryWithObject:NSFileProtectionComplete
    forKey:NSFileProtectionKey]];
    */
   /*
    - (BOOL)setAttributes:(NSDictionary *)attributes ofItemAtPath:(NSString *)path error:(NSError **)error
    */
   
   
   [[NSFileManager defaultManager]  setAttributes: d ofItemAtPath:[NSString stringWithUTF8String: fn ]error:NULL  ];
}


int main(int argc, char *argv[])
{
   
  // void test_pwd_ed(int iSetKey);test_pwd_ed(1);exit(0);
   
   NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
   
   
   setFSPath(argv[0]);

   
#if defined(DEBUG)
   NSLog(@"[path=%s] build=debug",argv[0]);
#else
   NSLog(@"[path=%s] build=release",argv[0]);
#endif
   

   initDevID();
   
   rememberAppStartupTime();
   
   loadPWDKey();
   
   int isProvisioned(int iCheckNow);
   int z_main_init(int argc, const char* argv[]);
   void t_init_glob();
  
   if(isProvisioned(1)){
      
      t_init_glob();
 
      const char *x[]={""};
      z_main_init(0,x);
   }
   else{
      
   }
   
   freemem_to_log();
   
   int retVal = UIApplicationMain(argc, argv, nil, nil);// NSStringFromClass([AppDelegate class]));

   [pool release];
   return retVal;
   
}

#import <mach/mach.h>

float cpu_usage()
{
   //--
   return 0.1;
   //cpu_usage is  leaking memory????
   kern_return_t kr;
   task_info_data_t tinfo;
   mach_msg_type_number_t task_info_count;
   
   task_info_count = TASK_INFO_MAX;
   kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count);
   if (kr != KERN_SUCCESS) {
      return -1;
   }
   
   task_basic_info_t      basic_info;
   thread_array_t         thread_list;
   mach_msg_type_number_t thread_count;
   
   thread_info_data_t     thinfo;
   mach_msg_type_number_t thread_info_count;
   
   thread_basic_info_t basic_info_th;
   uint32_t stat_thread = 0; // Mach threads
   
   basic_info = (task_basic_info_t)tinfo;
   
   
   
   // get threads in the task
   kr = task_threads(mach_task_self(), &thread_list, &thread_count);
   if (kr != KERN_SUCCESS) {
      return -1;
   }
   if (thread_count > 0)
      stat_thread += thread_count;
   
   long tot_sec = 0;
   long tot_usec = 0;
   float tot_cpu = 0;
   int j;
   
   for (j = 0; j < thread_count; j++)
   {
      thread_info_count = THREAD_INFO_MAX;
      kr = thread_info(thread_list[j], THREAD_BASIC_INFO,
                       (thread_info_t)thinfo, &thread_info_count);
      if (kr != KERN_SUCCESS) {
         return -1;
      }
      
      basic_info_th = (thread_basic_info_t)thinfo;
      
      if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
         tot_sec = tot_sec + basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
         tot_usec = tot_usec + basic_info_th->user_time.microseconds + basic_info_th->system_time.microseconds;
         tot_cpu = tot_cpu + basic_info_th->cpu_usage *100/ (float)TH_USAGE_SCALE;
      }
      
   } // for each thread
   
   return tot_cpu;
}
/*
[[NSNotificationCenter defaultCenter] addObserver: self
                                         selector:@selector(receivedRotate:)
                                             name:UIDeviceOrientationDidChangeNotification
                                           object: nil];

- (void)receivedRotate:(NSNotification*)notif {
   UIDeviceOrientation interfaceOrientation = [[UIDevice currentDevice] orientation];
   switch (interfaceOrientation) {
      case UIInterfaceOrientationPortrait: {
         break;
      }
      case UIInterfaceOrientationLandscapeLeft: {
         break;
      }
      case UIInterfaceOrientationLandscapeRight: {
         break;
      }
      default:
         break;
   }   
}

*/