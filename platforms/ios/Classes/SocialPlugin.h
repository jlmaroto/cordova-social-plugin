#import <Cordova/CDVPlugin.h>
#import <Foundation/Foundation.h>
#import <Accounts/Accounts.h>

@interface SocialPlugin : CDVPlugin

- (void) chooseAndSend:(CDVInvokedUrlCommand*)command;

- (void) setFacebookIdentityData:(CDVInvokedUrlCommand *)command;
- (void) getFacebookAccount:(CDVInvokedUrlCommand*)command;
- (void) postToFacebook:(CDVInvokedUrlCommand*)command;
- (void) getTwitterAccounts:(CDVInvokedUrlCommand*)command;
- (void) postToTwitter:(CDVInvokedUrlCommand*)command;


@end
