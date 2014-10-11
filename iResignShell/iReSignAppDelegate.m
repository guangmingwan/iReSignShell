//
//  iReSignAppDelegate.m
//  iReSign
//
//  Created by Maciej Swic on 2011-05-16.
//  Copyright (c) 2011 Maciej Swic, Licensed under the MIT License.
//  See README.md for details
//

#import "iReSignAppDelegate.h"

static NSString *kKeyPrefsBundleIDChange        = @"keyBundleIDChange";

static NSString *kKeyBundleIDPlistApp           = @"CFBundleIdentifier";
static NSString *kKeyBundleIDPlistiTunesArtwork = @"softwareVersionBundleId";

static NSString *kPayloadDirName                = @"Payload";
static NSString *kInfoPlistFilename             = @"Info.plist";
static NSString *kiTunesMetadataFileName        = @"iTunesMetadata";

@implementation iReSignAppDelegate

@synthesize workingPath;

- (void)initapp
{
    
    
    defaults = [NSUserDefaults standardUserDefaults];
    
    // Look up available signing certificates
    [self getCerts];
    
    if ([defaults valueForKey:@"ENTITLEMENT_PATH"])
        entitlementField = [defaults valueForKey:@"ENTITLEMENT_PATH"];
    if ([defaults valueForKey:@"MOBILEPROVISION_PATH"])
        provisioningPathField = [defaults valueForKey:@"MOBILEPROVISION_PATH"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/zip"]) {
        [self showAlertOfKind:NSCriticalAlertStyle WithTitle:@"Error" AndMessage:@"This app cannot run without the zip utility present at /usr/bin/zip"];
        exit(0);
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/unzip"]) {
        [self showAlertOfKind:NSCriticalAlertStyle WithTitle:@"Error" AndMessage:@"This app cannot run without the unzip utility present at /usr/bin/unzip"];
        exit(0);
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/codesign"]) {
        [self showAlertOfKind:NSCriticalAlertStyle WithTitle:@"Error" AndMessage:@"This app cannot run without the codesign utility present at /usr/bin/codesign"];
        exit(0);
    }
    
}

- (void)wait {
  
}
- (void)resign:(id)sender {
    //Save cert name
    //[defaults setValue:[NSNumber numberWithInteger:[certComboBox indexOfSelectedItem]] forKey:@"CERT_INDEX"];
    [defaults setValue: entitlementField  forKey:@"ENTITLEMENT_PATH"];
    [defaults setValue: provisioningPathField forKey:@"MOBILEPROVISION_PATH"];
    [defaults setValue: bundleIDField forKey:kKeyPrefsBundleIDChange];
    [defaults synchronize];
    
    codesigningResult = nil;
    verificationResult = nil;
    
    originalIpaPath = pathField;
    workingPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"com.adouming.iresignshell"];
    
    if (certName) {
        if ([[[originalIpaPath pathExtension] lowercaseString] isEqualToString:@"ipa"]) {
            [self disableControls];
            
            NSLog(@"Setting up working directory in %@",workingPath);
            
            
            [[NSFileManager defaultManager] removeItemAtPath:workingPath error:nil];
            
            [[NSFileManager defaultManager] createDirectoryAtPath:workingPath withIntermediateDirectories:TRUE attributes:nil error:nil];
            
            if (originalIpaPath && [originalIpaPath length] > 0) {
                NSLog(@"Unzipping %@",originalIpaPath);
            }
            
            unzipTask = [[NSTask alloc] init];
            [unzipTask setLaunchPath:@"/usr/bin/unzip"];
            [unzipTask setArguments:[NSArray arrayWithObjects:@"-q", originalIpaPath, @"-d", workingPath, nil]];
            NSLog(@"/usr/bin/unzip %@",[unzipTask arguments]);
            //[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkUnzip:) userInfo:nil repeats:TRUE];
            
            [unzipTask launch];
            [unzipTask waitUntilExit];
            [self checkUnzip:nil];
            
        } else {
            [self showAlertOfKind:NSCriticalAlertStyle WithTitle:@"Error" AndMessage:@"You must choose an *.ipa file"];
            [self enableControls];
            NSLog(@"Please try again");
        }
    } else {
        [self showAlertOfKind:NSCriticalAlertStyle WithTitle:@"Error" AndMessage:@"You must choose an signing certificate from dropdown."];
        [self enableControls];
        NSLog(@"Please try again");
    }
}

- (void)checkUnzip:(NSTimer *)timer {
    if ([unzipTask isRunning] == 0) {
        [timer invalidate];
        unzipTask = nil;
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:[workingPath stringByAppendingPathComponent:@"Payload"]]) {
            NSLog(@"Unzipping done");
           
            
            if (bundleIDField && bundleIDField.length > 0) {
                [self doBundleIDChange:bundleIDField];
            }
            
            if ([provisioningPathField  isEqualTo:@""]) {
                [self doCodeSigning];
            } else {
                [self doProvisioning];
            }
        } else {
            [self showAlertOfKind:NSCriticalAlertStyle WithTitle:@"Error" AndMessage:@"Unzip failed"];
            [self enableControls];
            
        }
    }
}

- (BOOL)doBundleIDChange:(NSString *)newBundleID {
    BOOL success = YES;
    
    success &= [self doAppBundleIDChange:newBundleID];
    success &= [self doITunesMetadataBundleIDChange:newBundleID];
    
    return success;
}


- (BOOL)doITunesMetadataBundleIDChange:(NSString *)newBundleID {
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:workingPath error:nil];
    NSString *infoPlistPath = nil;
    
    for (NSString *file in dirContents) {
        if ([[[file pathExtension] lowercaseString] isEqualToString:@"plist"]) {
            infoPlistPath = [workingPath stringByAppendingPathComponent:file];
            break;
        }
    }
    
    return [self changeBundleIDForFile:infoPlistPath bundleIDKey:kKeyBundleIDPlistiTunesArtwork newBundleID:newBundleID plistOutOptions:NSPropertyListXMLFormat_v1_0];
    
}

- (BOOL)doAppBundleIDChange:(NSString *)newBundleID {
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[workingPath stringByAppendingPathComponent:kPayloadDirName] error:nil];
    NSString *infoPlistPath = nil;
    
    for (NSString *file in dirContents) {
        if ([[[file pathExtension] lowercaseString] isEqualToString:@"app"]) {
            infoPlistPath = [[[workingPath stringByAppendingPathComponent:kPayloadDirName]
                              stringByAppendingPathComponent:file]
                             stringByAppendingPathComponent:kInfoPlistFilename];
            break;
        }
    }
    
    return [self changeBundleIDForFile:infoPlistPath bundleIDKey:kKeyBundleIDPlistApp newBundleID:newBundleID plistOutOptions:NSPropertyListBinaryFormat_v1_0];
}

- (BOOL)changeBundleIDForFile:(NSString *)filePath bundleIDKey:(NSString *)bundleIDKey newBundleID:(NSString *)newBundleID plistOutOptions:(NSPropertyListWriteOptions)options {
    
    NSMutableDictionary *plist = nil;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        plist = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
        [plist setObject:newBundleID forKey:bundleIDKey];
        
        NSData *xmlData = [NSPropertyListSerialization dataWithPropertyList:plist format:options options:kCFPropertyListImmutable error:nil];
        
        return [xmlData writeToFile:filePath atomically:YES];
        
    }
    
    return NO;
}


- (void)doProvisioning {
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[workingPath stringByAppendingPathComponent:@"Payload"] error:nil];
    
    for (NSString *file in dirContents) {
        if ([[[file pathExtension] lowercaseString] isEqualToString:@"app"]) {
            appPath = [[workingPath stringByAppendingPathComponent:@"Payload"] stringByAppendingPathComponent:file];
            if ([[NSFileManager defaultManager] fileExistsAtPath:[appPath stringByAppendingPathComponent:@"embedded.mobileprovision"]]) {
                NSLog(@"Found embedded.mobileprovision, deleting.");
                [[NSFileManager defaultManager] removeItemAtPath:[appPath stringByAppendingPathComponent:@"embedded.mobileprovision"] error:nil];
            }
            break;
        }
    }
    
    NSString *targetPath = [appPath stringByAppendingPathComponent:@"embedded.mobileprovision"];
    
    provisioningTask = [[NSTask alloc] init];
    [provisioningTask setLaunchPath:@"/bin/cp"];
    [provisioningTask setArguments:[NSArray arrayWithObjects:provisioningPathField, targetPath, nil]];
    NSLog(@"/bin/cp %@", [provisioningTask arguments] );
    
    [provisioningTask launch];
    //[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkProvisioning:) userInfo:nil repeats:TRUE];
    [provisioningTask waitUntilExit];
    [self checkProvisioning:nil];
    
    
    
}

- (void)checkProvisioning:(NSTimer *)timer {
    if ([provisioningTask isRunning] == 0) {
        [timer invalidate];
        provisioningTask = nil;
        
        NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[workingPath stringByAppendingPathComponent:@"Payload"] error:nil];
        
        for (NSString *file in dirContents) {
            if ([[[file pathExtension] lowercaseString] isEqualToString:@"app"]) {
                appPath = [[workingPath stringByAppendingPathComponent:@"Payload"] stringByAppendingPathComponent:file];
                if ([[NSFileManager defaultManager] fileExistsAtPath:[appPath stringByAppendingPathComponent:@"embedded.mobileprovision"]]) {
                    
                    BOOL identifierOK = FALSE;
                    NSString *identifierInProvisioning = @"";
                    
                    NSString *embeddedProvisioning = [NSString stringWithContentsOfFile:[appPath stringByAppendingPathComponent:@"embedded.mobileprovision"] encoding:NSASCIIStringEncoding error:nil];
                    NSArray* embeddedProvisioningLines = [embeddedProvisioning componentsSeparatedByCharactersInSet:
                                                          [NSCharacterSet newlineCharacterSet]];
                    
                    for (int i = 0; i <= [embeddedProvisioningLines count]; i++) {
                        if ([[embeddedProvisioningLines objectAtIndex:i] rangeOfString:@"application-identifier"].location != NSNotFound) {
                            
                            NSInteger fromPosition = [[embeddedProvisioningLines objectAtIndex:i+1] rangeOfString:@"<string>"].location + 8;
                            
                            NSInteger toPosition = [[embeddedProvisioningLines objectAtIndex:i+1] rangeOfString:@"</string>"].location;
                            
                            NSRange range;
                            range.location = fromPosition;
                            range.length = toPosition-fromPosition;
                            
                            NSString *fullIdentifier = [[embeddedProvisioningLines objectAtIndex:i+1] substringWithRange:range];
                            
                            NSArray *identifierComponents = [fullIdentifier componentsSeparatedByString:@"."];
                            
                            if ([[identifierComponents lastObject] isEqualTo:@"*"]) {
                                identifierOK = TRUE;
                            }
                            
                            for (int i = 1; i < [identifierComponents count]; i++) {
                                identifierInProvisioning = [identifierInProvisioning stringByAppendingString:[identifierComponents objectAtIndex:i]];
                                if (i < [identifierComponents count]-1) {
                                    identifierInProvisioning = [identifierInProvisioning stringByAppendingString:@"."];
                                }
                            }
                            break;
                        }
                    }
                    
                    NSLog(@"Mobileprovision identifier: %@",identifierInProvisioning);
                    
                    NSString *infoPlist = [NSString stringWithContentsOfFile:[appPath stringByAppendingPathComponent:@"Info.plist"] encoding:NSASCIIStringEncoding error:nil];
                    if ([infoPlist rangeOfString:identifierInProvisioning].location != NSNotFound) {
                        NSLog(@"Identifiers match");
                        identifierOK = TRUE;
                    }
                    
                    if (identifierOK) {
                        NSLog(@"Provisioning completed.");
                        [self doCodeSigning];
                    } else {
                        [self showAlertOfKind:NSCriticalAlertStyle WithTitle:@"Error" AndMessage:@"Product identifiers don't match"];
                        [self enableControls];
                    }
                } else {
                    [self showAlertOfKind:NSCriticalAlertStyle WithTitle:@"Error" AndMessage:@"Provisioning failed"];
                    [self enableControls];
                }
                break;
            }
        }
    }
}

- (void)doCodeSigning {
    appPath = nil;
    
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[workingPath stringByAppendingPathComponent:@"Payload"] error:nil];
    
    for (NSString *file in dirContents) {
        if ([[[file pathExtension] lowercaseString] isEqualToString:@"app"]) {
            appPath = [[workingPath stringByAppendingPathComponent:@"Payload"] stringByAppendingPathComponent:file];
            NSLog(@"Found %@",appPath);
            appName = file;
            NSLog([NSString stringWithFormat:@"Codesigning %@",file]);
            break;
        }
    }
    
    if (appPath) {
        NSMutableArray *arguments = [NSMutableArray arrayWithObjects:@"-fs", certName, nil];
		
	NSDictionary *systemVersionDictionary = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
	float systemVersionFloat = [[systemVersionDictionary objectForKey:@"ProductVersion"] floatValue];
	if (systemVersionFloat < 10.9f) {
		
		/*
		 Before OSX 10.9, code signing requires a version 1 signature.
		 The resource envelope is necessary.
		 To ensure it is added, append the resource flag to the arguments.
		 */
		
		NSString *resourceRulesPath = [[NSBundle mainBundle] pathForResource:@"ResourceRules" ofType:@"plist"];
		NSString *resourceRulesArgument = [NSString stringWithFormat:@"--resource-rules=%@",resourceRulesPath];
		[arguments addObject:resourceRulesArgument];
	} else {
		
		/*
		 For OSX 10.9 and later, code signing requires a version 2 signature.
		 The resource envelope is obsolete.
		 To ensure it is ignored, remove the resource key from the Info.plist file.
		 */
		
		NSString *infoPath = [NSString stringWithFormat:@"%@/Info.plist", appPath];
		NSMutableDictionary *infoDict = [NSMutableDictionary dictionaryWithContentsOfFile:infoPath];
		[infoDict removeObjectForKey:@"CFBundleResourceSpecification"];
		[infoDict writeToFile:infoPath atomically:YES];
	}
        
        if (entitlementField && ![entitlementField isEqualToString:@""]) {
            [arguments addObject:[NSString stringWithFormat:@"--entitlements=%@", entitlementField ]];
        }
        else
        {
         
            NSString* shellcmd = @"/usr/libexec/PlistBuddy";
            NSString* EntitlementsOutpath = [NSString stringWithFormat:@"%@/Entitlements.plist", workingPath ];
            
            NSString* p1 = @" -x -c 'Print :Entitlements' /dev/stdin <<< `security cms -D -i '";
            NSString* p2 = @"'` > ";
            NSString* script = [NSString stringWithFormat:@"%@%@%@%@%@",
                                            shellcmd,
                                            p1,
                                            provisioningPathField,
                                            p2,
                                            EntitlementsOutpath];
    		
            
            NSLog(@"%@",script);
            system([script UTF8String]);
            
            [arguments addObject:[NSString stringWithFormat:@"--entitlements=%@", EntitlementsOutpath ]];
        }
        
        [arguments addObjectsFromArray:[NSArray arrayWithObjects:appPath, nil]];
        
        codesignTask = [[NSTask alloc] init];
        [codesignTask setLaunchPath:@"/usr/bin/codesign"];
        [codesignTask setArguments:arguments];
        
        
        
        NSLog(@"/usr/bin/codesign %@",[codesignTask arguments]);
		
//        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkCodesigning:) userInfo:nil repeats:TRUE];
        
        
        NSPipe *pipe=[NSPipe pipe];
        [codesignTask setStandardOutput:pipe];
        [codesignTask setStandardError:pipe];
        NSFileHandle *handle=[pipe fileHandleForReading];
        
        [codesignTask launch];
        //[NSThread detachNewThreadSelector:@selector(watchCodesigning:)
        //                         toTarget:self withObject:handle];
        [codesignTask waitUntilExit];
        codesigningResult = [[NSString alloc] initWithData:[handle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
        [self checkCodesigning:nil];
        
    }
}

- (void)watchCodesigning:(NSFileHandle*)streamHandle {
    @autoreleasepool {
        
        codesigningResult = [[NSString alloc] initWithData:[streamHandle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
        
    }
}

- (void)checkCodesigning:(NSTimer *)timer {
    if ([codesignTask isRunning] == 0) {
        [timer invalidate];
        codesignTask = nil;
        NSLog(@"Codesigning done");
       
        [self doVerifySignature];
    }
}

- (void)doVerifySignature {
    if (appPath) {
        verifyTask = [[NSTask alloc] init];
        [verifyTask setLaunchPath:@"/usr/bin/codesign"];
        [verifyTask setArguments:[NSArray arrayWithObjects:@"-v", appPath, nil]];
		
        NSLog(@"/usr/bin/codesign %@",[verifyTask arguments]);
//        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkVerificationProcess:) userInfo:nil repeats:TRUE];
        
        NSLog(@"Verifying %@",appPath);
        
        
        NSPipe *pipe=[NSPipe pipe];
        [verifyTask setStandardOutput:pipe];
        [verifyTask setStandardError:pipe];
        NSFileHandle *handle=[pipe fileHandleForReading];
        
        [verifyTask launch];
        //[NSThread detachNewThreadSelector:@selector(watchVerificationProcess:)
        //                         toTarget:self withObject:handle];
        [verifyTask waitUntilExit];
        verificationResult = [[NSString alloc] initWithData:[handle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
        [self checkVerificationProcess:nil];
        
        
    }
}

- (void)watchVerificationProcess:(NSFileHandle*)streamHandle {
    @autoreleasepool {
        
        verificationResult = [[NSString alloc] initWithData:[streamHandle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
        
    }
}

- (void)checkVerificationProcess:(NSTimer *)timer {
    if ([verifyTask isRunning] == 0) {
        [timer invalidate];
        verifyTask = nil;
        if ([verificationResult length] == 0) {
            NSLog(@"Verification done");
            
            [self doZip];
        } else {
            NSString *error = [[codesigningResult stringByAppendingString:@"\n\n"] stringByAppendingString:verificationResult];
            [self showAlertOfKind:NSCriticalAlertStyle WithTitle:@"Signing failed" AndMessage:error];
            [self enableControls];
            NSLog(@"Please try again");
        }
    }
}

- (void)doZip {
    if (appPath) {
        NSArray *destinationPathComponents = [originalIpaPath pathComponents];
        NSString *_destinationPath = @"";
        
        for (int i = 0; i < ([destinationPathComponents count]-1); i++) {
            _destinationPath = [destinationPath stringByAppendingPathComponent:[destinationPathComponents objectAtIndex:i]];
        }
        
        fileName = [originalIpaPath lastPathComponent];
        fileName = [fileName substringToIndex:[fileName length]-4];
        fileName = [fileName stringByAppendingString:@"-resigned"];
        fileName = [fileName stringByAppendingPathExtension:@"ipa"];
        
        if(destinationPath && destinationPath.length > 0) {
            _destinationPath = destinationPath;
        }
        
        _destinationPath = [_destinationPath stringByAppendingPathComponent:fileName];
        
        
        NSLog(@"Dest: %@",_destinationPath);
        
        zipTask = [[NSTask alloc] init];
        [zipTask setLaunchPath:@"/usr/bin/zip"];
        [zipTask setCurrentDirectoryPath:workingPath];
        [zipTask setArguments:[NSArray arrayWithObjects:@"-qry", _destinationPath, @".", nil]];
		
//      [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkZip:) userInfo:nil repeats:TRUE];
        
        NSLog(@"Zipping to %@", _destinationPath);
        
        
        [zipTask launch];
        [zipTask waitUntilExit];
        
        [self checkZip:nil];
    }
}

- (void)checkZip:(NSTimer *)timer {
    if ([zipTask isRunning] == 0) {
        [timer invalidate];
        zipTask = nil;
        NSLog(@"Zipping done");
        NSLog([NSString stringWithFormat:@"Saved %@",fileName]);
        
        [[NSFileManager defaultManager] removeItemAtPath:workingPath error:nil];
        
        [self enableControls];
        
        NSString *result = [[codesigningResult stringByAppendingString:@"\n\n"] stringByAppendingString:verificationResult];
        NSLog(@"Codesigning result: %@",result);
    }
}
- (void)setCerName:(char*)ccername {
    NSString* cert = [[NSString alloc] initWithCString:ccername encoding:NSUTF8StringEncoding];
    certName = cert;
}
- (void)setNewBundleId:(char*)newBundle {
    bundleIDField = [[NSString alloc] initWithCString:newBundle encoding:NSUTF8StringEncoding];
}

- (void)setIpaPath:(char*)cipafile {
    
    NSString* fileNameOpened = [[NSString alloc] initWithCString:cipafile encoding:NSUTF8StringEncoding];
    pathField  = fileNameOpened;
   
}

- (void)setProvisioning:(char*)cProvisioning {
    NSString* fileNameOpened = [[NSString alloc] initWithCString:cProvisioning encoding:NSUTF8StringEncoding];
    provisioningPathField = fileNameOpened;
    
}

-(void)setDestinationPath:(char*)cDestpath {
    destinationPath = [[NSString alloc] initWithCString:cDestpath encoding:NSUTF8StringEncoding];
}
- (IBAction)entitlementBrowse:(id)sender {
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    
    [openDlg setCanChooseFiles:TRUE];
    [openDlg setCanChooseDirectories:FALSE];
    [openDlg setAllowsMultipleSelection:FALSE];
    [openDlg setAllowsOtherFileTypes:FALSE];
    [openDlg setAllowedFileTypes:@[@"plist", @"PLIST"]];
    
    if ([openDlg runModal] == NSOKButton)
    {
        NSString* fileNameOpened = [[[openDlg URLs] objectAtIndex:0] path];
        entitlementField = fileNameOpened;
    }
}

- (IBAction)changeBundleIDPressed:(id)sender {
    
//    if (sender != changeBundleIDCheckbox) {
//        return;
//    }
    
//    bundleIDField.enabled = changeBundleIDCheckbox.state == NSOnState;
}

- (void)disableControls {
    
}

- (void)enableControls {
    
}


- (void)getCerts {
    
    getCertsResult = nil;
    
    NSLog(@"Getting Certificate IDs");
    
    
    certTask = [[NSTask alloc] init];
    [certTask setLaunchPath:@"/usr/bin/security"];
    [certTask setArguments:[NSArray arrayWithObjects:@"find-identity", @"-v", @"-p", @"codesigning", nil]];
    
    NSLog(@"/usr/bin/security %@",[certTask arguments]);
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkCerts:) userInfo:nil repeats:TRUE];
    
    NSPipe *pipe=[NSPipe pipe];
    [certTask setStandardOutput:pipe];
    [certTask setStandardError:pipe];
    NSFileHandle *handle=[pipe fileHandleForReading];
    
    [certTask launch];
    
    [certTask waitUntilExit];
    
    //[NSThread detachNewThreadSelector:@selector(watchGetCerts:) toTarget:self withObject:handle];
}

- (void)watchGetCerts:(NSFileHandle*)streamHandle {
    @autoreleasepool {
        
        NSString *securityResult = [[NSString alloc] initWithData:[streamHandle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
        // Verify the security result
        if (securityResult == nil || securityResult.length < 1) {
            // Nothing in the result, return
            return;
        }
        NSArray *rawResult = [securityResult componentsSeparatedByString:@"\""];
        NSMutableArray *tempGetCertsResult = [NSMutableArray arrayWithCapacity:20];
        for (int i = 0; i <= [rawResult count] - 2; i+=2) {
            
            NSLog(@"i:%d", i+1);
            if (rawResult.count - 1 < i + 1) {
                // Invalid array, don't add an object to that position
            } else {
                // Valid object
                [tempGetCertsResult addObject:[rawResult objectAtIndex:i+1]];
            }
        }
        
    }
}

- (void)checkCerts:(NSTimer *)timer {
    if ([certTask isRunning] == 0) {
        [timer invalidate];
        certTask = nil;
    }
}


#pragma mark - Alert Methods

/* NSRunAlerts are being deprecated in 10.9 */

// Show a critical alert
- (void)showAlertOfKind:(NSAlertStyle)style WithTitle:(NSString *)title AndMessage:(NSString *)message {
    NSAlert *alert = [[NSAlert alloc] init];
    NSLog(@"%@-%@", title, message);
//    [alert addButtonWithTitle:@"OK"];
//    [alert setMessageText:title];
//    [alert setInformativeText:message];
//    [alert setAlertStyle:style];
//    [alert runModal];
}

@end
