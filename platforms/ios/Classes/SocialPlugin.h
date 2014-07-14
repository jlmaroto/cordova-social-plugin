#import <Cordova/CDVPlugin.h>
#import <Foundation/Foundation.h>

@interface SocialPlugin : CDVPlugin

- (void) chooseAndSend:(CDVInvokedUrlCommand*)command;

@end
