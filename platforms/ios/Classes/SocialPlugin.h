#import <Cordova/CDVPlugin.h>
#import <Foundation/Foundation.h>
#import <Accounts/Accounts.h>

@interface SocialPlugin : CDVPlugin

- (void) chooseAndSend:(CDVInvokedUrlCommand*)command;
- (void) getAvailableAccounts:(CDVInvokedUrlCommand*)command;

@end
