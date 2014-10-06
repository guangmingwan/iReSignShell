//
//  iReSignAppDelegate.h
//  iReSign
//
//  Created by Maciej Swic on 2011-05-16.
//  Copyright (c) 2011 Maciej Swic, Licensed under the MIT License.
//  See README.md for details
//

#import <Cocoa/Cocoa.h>

@interface iReSignAppDelegate : NSObject {
@private

    
    NSUserDefaults *defaults;
    
    NSTask *unzipTask;
    NSTask *provisioningTask;
    NSTask *codesignTask;
    NSTask *verifyTask;
    NSTask *zipTask;
    NSString *originalIpaPath;
    NSString *appPath;
    NSString *workingPath;
    NSString *appName;
    NSString *fileName;
    
    NSString *codesigningResult;
    NSString *verificationResult;
 
    NSString *destinationPath;
    NSString *pathField;
    NSString *provisioningPathField;
    NSString *entitlementField;
    NSString *bundleIDField;
    
    
    NSString *certName;
    NSTask *certTask;
    NSArray *getCertsResult;
    
}
//410042539788665

@property (nonatomic, strong) NSString *workingPath;
- (void)initapp;
- (void)wait;
- (void)resign:(id)sender;
- (void)setCerName:(char*)ccername;
- (void)setNewBundleId:(char*)newBundle;
- (void)setIpaPath:(char*)cipafile;
- (void)setProvisioning:(char*)cProvisioning;
- (void)setDestinationPath:(char*)cDestpath;
- (void)entitlementBrowse:(id)sender;
- (void)changeBundleIDPressed:(id)sender;

- (void)checkUnzip:(NSTimer *)timer;
- (void)doProvisioning;
- (void)checkProvisioning:(NSTimer *)timer;
- (void)doCodeSigning;
- (void)checkCodesigning:(NSTimer *)timer;
- (void)doVerifySignature;
- (void)checkVerificationProcess:(NSTimer *)timer;
- (void)doZip;
- (void)checkZip:(NSTimer *)timer;
- (void)disableControls;
- (void)enableControls;

@end
