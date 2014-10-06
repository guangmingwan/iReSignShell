//
//  main.m
//  iResignShell
//
//  Created by 阿兜明 on 14-10-6.
//  Copyright (c) 2014年 阿兜明. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "iReSignAppDelegate.h"
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        int hflag = 0;
        int bflag = 0;
        char *ivalue = NULL;
        char *svalue = NULL;
        char *ovalue = NULL;
        char *mvalue = NULL;
        char *fvalue = NULL;
        int index;
        int c;
        
        opterr = 0;
        
        while ((c = getopt (argc, argv, "hbi:c:o:s:m:")) != -1)
            switch (c)
        {
            case 'i':
                ivalue = optarg;
            case 'h':
                hflag = 1;
                break;
            case 'b':
                bflag = 1;
                break;
            case 'o':
                ovalue = optarg;
                break;
            case 's':
                svalue = optarg;
                break;
            case 'm':
                mvalue = optarg;
                break;
            case '?':
                if (optopt == 'c')
                    fprintf (stderr, "Option -%c requires an argument.\n", optopt);
                else if (isprint (optopt))
                    fprintf (stderr, "Unknown option `-%c'.\n", optopt);
                else
                    fprintf (stderr,
                             "Unknown option character `\\x%x'.\n",
                             optopt);
                return 1;
            default:
                abort ();
        }
        
        if(hflag) {
            usage();
            return 0;
        }
        
        for (index = optind; index < argc; index++)
            fvalue = argv[index];
        
        //printf ("hflag = %d, bflag = %d\n ivalue = %s\n svalue = %s\n fvalue = %s\n ovalue = %s\n",
        //        ivalue, hflag, bflag, svalue, fvalue, ovalue);
        if(argc <=1) {
            fprintf (stderr, "for help `-h'.\n", optopt);
            return 1;
        }
            //printf ("Non-option argument %s\n", argv[index]);
        /*
        ovalue = "/Users/akabutoakira/";
        ivalue = "com.adouming.testapp";
        mvalue = "/Users/akabutoakira/AllAppInHouse.mobileprovision";
        fvalue = "/Users/akabutoakira/Downloads/MobileClass.ipa";
        svalue = "iPhone Distribution: YiZhi  Information Technology Co.,Ltd.";
        */
         
        iReSignAppDelegate* app = [[iReSignAppDelegate alloc] init];
        [app initapp];
        if(ivalue) {
            [app setNewBundleId:ivalue];
        }
        if(mvalue) {
            [app setProvisioning:mvalue];
        }
        if(ovalue) {
            [app setDestinationPath:ovalue];
        }
        if(fvalue) {
            [app setIpaPath:fvalue];
        }
        if(svalue) {
            [app setCerName: svalue];
        }
        [app resign:nil];
        //[app wait];
        return 0;
        //NSLog(@"Hello, World!");
    }
    return 0;
}
int usage() {
    
    char* helpstr = "iResignShell Re-signs an IPA file.\n"
                    "Usage: iResignShell [-h]\n"
                    "Usage: iResignShell [options] [-s cer_name] -m mobileprovision target.app(ipa)"
                    "\n"
                    "options:\n"
                    "    -h				显示帮助\n"
                    "    -i <new BundleID>		新的App ID\n"
                    "    -e <Entitlements.plist> 	指定Entitlements.plist\n"
                    "    -o <output file/path>		输出位置\n"
                    "    -s <cer_name>			证书名，如：iPhone Developer: xxxx\n"
                    "    -m <mobileprovision>		对应App ID的mobileprovision\n"
  
                    "    Usage  examples :\n"
    
                    "#打印帮助\n"
                    "    iResignShell -h\n"

    
                    "#使用证书名+mobileprovision签名，默认输出到同目录下，输出文件名为\"代签名文件-resigned.ipa\"\n"
                    "    iResignShell -s \"iPhone Distribution: SMARTMZ\" -m My.mobileprovision My.ipa\n"
    

                    "#修改Bundle ID为com.mai.App，然后签名\n"
                    "    iResignShell -i com.mai.App -c My_cer.p12 -p passwd -m My.mobileprovision My.ipa\n"
    
                    "#-o 可以指定输出目录，或者输出的文件名\n"
                    "    iResignShell -s \"iPhone Distribution: SMARTMZ\" -m My.mobileprovision -o ~/rename.ipa My.ipa\n"
                    "    iResignShell -s \"iPhone Distribution: SMARTMZ\" -m My.mobileprovision -o ~/ My.ipa\n";
    printf("%s", helpstr);
    return 0;
}
