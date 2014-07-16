#import <Social/Social.h>
#import "SocialPlugin.h"


@interface SocialPlugin()
@property (nonatomic, strong) ACAccountStore *accountStore;
@end

@implementation SocialPlugin

- (id)init
{
    self = [super init];
    if (self) {
        _accountStore = [[ACAccountStore alloc] init];
    }
    return self;
}

NSMutableDictionary* facebookOptions;

- (void) setFacebookIdentityData:(CDVInvokedUrlCommand *)command;
{
    if(_accountStore==nil){
        [self init];
    }
    NSMutableDictionary *args = [command.arguments objectAtIndex:0];
    
    facebookOptions=[[NSMutableDictionary alloc]init];
    
    if(args[@"ACFacebookAppIdKey"]==nil){
        [self.commandDelegate sendPluginResult:[ CDVPluginResult
                                                resultWithStatus    : CDVCommandStatus_ERROR
                                                messageAsString:@"You must provide an AppId"
                                                ] callbackId:command.callbackId];
    }else{
        facebookOptions[ACFacebookAppIdKey]=args[@"ACFacebookAppIdKey"];
    }
    
    if(args[@"ACFacebookPermissionsKey"]!=nil){
        facebookOptions[ACFacebookPermissionsKey]=args[@"ACFacebookPermissionsKey"];
    }else{
        facebookOptions[ACFacebookPermissionsKey]= @[@"email"];
    }
    if(args[@"ACFacebookAudienceKey"]!=nil){
        facebookOptions[ACFacebookAudienceKey]=args[@"ACFacebookAudienceKey"];
    }else{
        facebookOptions[ACFacebookAudienceKey]=ACFacebookAudienceFriends;
    }
    [self.commandDelegate sendPluginResult:[ CDVPluginResult
                                           resultWithStatus    : CDVCommandStatus_OK
                                           messageAsDictionary:facebookOptions
                                           ] callbackId:command.callbackId];
}
- (void) getFacebookAccount:(CDVInvokedUrlCommand*)command;
{
    if(_accountStore==nil){
        [self init];
    }
    
    if(facebookOptions==nil){
        [self.commandDelegate sendPluginResult:[ CDVPluginResult
                                                resultWithStatus    : CDVCommandStatus_ERROR
                                                messageAsString:@"You must set Facebook identity before using any facebook call"
                                                ] callbackId:command.callbackId];
        return;
    }
    if(facebookOptions[ACFacebookAppIdKey]==nil||[facebookOptions[ACFacebookAppIdKey] isEqual:@""]){
        [self.commandDelegate sendPluginResult:[ CDVPluginResult
                                                resultWithStatus    : CDVCommandStatus_ERROR
                                                messageAsString:@"You must set Facebook app Id"
                                                ] callbackId:command.callbackId];
        return;
    }
    
    ACAccountType *type = [_accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    
    //get basic permission
    facebookOptions[ACFacebookPermissionsKey]= @[@"email"];
    
    [_accountStore requestAccessToAccountsWithType:type options:facebookOptions completion:^(BOOL granted, NSError *error)
     {
         NSMutableArray *arrayOfAccounts=[[NSMutableArray alloc] init];
         if (granted == YES)
         {
             NSArray *accounts = [_accountStore accountsWithAccountType:type];
             for(ACAccount *account in accounts)
             {
                 [arrayOfAccounts addObject:account.username];
             }
             [self.commandDelegate sendPluginResult:[ CDVPluginResult
                                                     resultWithStatus    : CDVCommandStatus_OK
                                                     messageAsArray:arrayOfAccounts
                                                     ] callbackId:command.callbackId];
         }else{
             [self.commandDelegate sendPluginResult:[ CDVPluginResult
                                                     resultWithStatus    : CDVCommandStatus_ERROR
                                                     messageAsString:[error localizedDescription]
                                                     ] callbackId:command.callbackId];
         }
     }];
}
-(void) postToFacebook:(CDVInvokedUrlCommand*)command;
{
    if(_accountStore==nil){
        [self init];
    }
    NSMutableDictionary *args = [command.arguments objectAtIndex:0];
    NSString *username=[args objectForKey:@"username"];
    NSString *text=[args objectForKey:@"text"];
    NSString *link=[args objectForKey:@"link"];
    NSString *audience=ACFacebookAudienceFriends;
    
    if(text==nil||[text isEqual:@""]){
        [self.commandDelegate sendPluginResult:[ CDVPluginResult
                                                resultWithStatus    : CDVCommandStatus_ERROR
                                                messageAsString:@"No text message"
                                                ] callbackId:command.callbackId];
    }
    
    if ([[args objectForKeyedSubscript:@"audience"] isEqualToString:@"all"]) {
        audience=ACFacebookAudienceEveryone;
    }else if([[args objectForKeyedSubscript:@"audience"] isEqualToString:@"me"]) {
        audience=ACFacebookAudienceOnlyMe;
    }else{
        audience=ACFacebookAudienceFriends;
    }
    
    ACAccountType *facebookAccountType = [self.accountStore
                                          accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    
    // Specify App ID and permissions
    NSDictionary *options = @{
                              ACFacebookAppIdKey: facebookOptions[ACFacebookAppIdKey],
                              ACFacebookPermissionsKey: @[ @"publish_actions"],
                              ACFacebookAudienceKey: audience
                              };
    
    [_accountStore requestAccessToAccountsWithType:facebookAccountType
                                          options:options completion:^(BOOL granted, NSError *e) {
                                              if (granted) {
                                                  NSArray *accounts = [_accountStore
                                                                       accountsWithAccountType:facebookAccountType];
                                                  NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
                                                  [parameters setValue:text forKeyPath:@"message"];
                                                  if(link!=nil){
                                                      [parameters setValue:link forKeyPath:@"link"];
                                                  }
                                                  
                                                  NSURL *feedURL = [NSURL URLWithString:@"https://graph.facebook.com/me/feed"];
                                                  
                                                  SLRequest *feedRequest = [SLRequest
                                                                            requestForServiceType:SLServiceTypeFacebook
                                                                            requestMethod:SLRequestMethodPOST
                                                                            URL:feedURL
                                                                            parameters:parameters];

                                                  ACAccount *facebookAccount;
                                                  if(username==nil){
                                                      facebookAccount = [accounts lastObject];
                                                  }else{
                                                      ACAccount* account;
                                                      for (account in accounts) {
                                                          if([account.username isEqual:username]){
                                                              facebookAccount=account;
                                                              break;
                                                          }
                                                      }
                                                      if(facebookAccount==nil){
                                                          facebookAccount = [accounts lastObject];
                                                      }
                                                  }
                                                  
                                                  feedRequest.account =facebookAccount;
                                                  
                                                  [feedRequest performRequestWithHandler:^(NSData *responseData, 
                                                                                           NSHTTPURLResponse *urlResponse, NSError *error)
                                                   {
                                                       if([urlResponse statusCode]==200){
                                                           [self.commandDelegate sendPluginResult:[ CDVPluginResult
                                                                                                   resultWithStatus    : CDVCommandStatus_OK
                                                                                                   messageAsString:@"Post sent"
                                                                                                   ] callbackId:command.callbackId];
                                                       }else{
                                                           
                                                           [self.commandDelegate sendPluginResult:[ CDVPluginResult
                                                                                                   resultWithStatus    : CDVCommandStatus_ERROR
                                                                                                   messageAsString:[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]
                                                                                                   ] callbackId:command.callbackId];
                                                       }
                                                   }];
                                              }
                                              else
                                              {
                                                  // Handle Failure
                                                  [self.commandDelegate sendPluginResult:[ CDVPluginResult
                                                                                          resultWithStatus    : CDVCommandStatus_ERROR
                                                                                          messageAsString:[e localizedDescription]
                                                                                          ] callbackId:command.callbackId];

                                              }
                                          }];
    
    
}
- (void) getTwitterAccounts:(CDVInvokedUrlCommand*)command;
{
    if(_accountStore==nil){
        [self init];
    }
    ACAccountType *type = [_accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [_accountStore requestAccessToAccountsWithType:type options:nil completion:^(BOOL granted, NSError *error)
    {
        NSMutableArray *arrayOfAccounts=[[NSMutableArray alloc] init];
        if (granted == YES)
        {
            NSArray *accounts = [_accountStore accountsWithAccountType:type];
            for(ACAccount *account in accounts)
            {
                [arrayOfAccounts addObject:account.username];
            }
            [self.commandDelegate sendPluginResult:[ CDVPluginResult
                                                    resultWithStatus    : CDVCommandStatus_OK
                                                    messageAsArray:arrayOfAccounts
                                                    ] callbackId:command.callbackId];
        }else{
            [self.commandDelegate sendPluginResult:[ CDVPluginResult
                                                    resultWithStatus    : CDVCommandStatus_ERROR
                                                    messageAsArray:arrayOfAccounts
                                                    ] callbackId:command.callbackId];
        }
    }];
}

- (void) postToTwitter:(CDVInvokedUrlCommand*)command;
{
    if(_accountStore==nil){
        [self init];
    }
    NSMutableDictionary *args = [command.arguments objectAtIndex:0];
    NSString *username=[args objectForKey:@"username"];
    NSString *text=[args objectForKey:@"text"];
    
    if(text==nil||[text isEqual:@""]){
        [self.commandDelegate sendPluginResult:[ CDVPluginResult
                                                resultWithStatus    : CDVCommandStatus_ERROR
                                                messageAsString:@"No text message"
                                                ] callbackId:command.callbackId];
    }
    
    ACAccountType *accountType = [_accountStore accountTypeWithAccountTypeIdentifier:
                                  ACAccountTypeIdentifierTwitter];
    
    [_accountStore requestAccessToAccountsWithType:accountType options:nil
                                  completion:^(BOOL granted, NSError *error)
    {
        if (granted == YES)
        {
            NSArray *arrayOfAccounts = [_accountStore
                                        accountsWithAccountType:accountType];
            
            if ([arrayOfAccounts count] > 0)
            {
                ACAccount *twitterAccount;
                if(username==nil){
                    twitterAccount = [arrayOfAccounts lastObject];
                }else{
                    ACAccount* account;
                    for (account in arrayOfAccounts) {
                        if([account.username isEqual:username]){
                            twitterAccount=account;
                            break;
                        }
                    }
                    if(twitterAccount==nil){
                        twitterAccount = [arrayOfAccounts lastObject];
                    }
                }
                
                NSDictionary *message = @{@"status": text};
                
                NSURL *requestURL = [NSURL
                                     URLWithString:@"https://api.twitter.com/1.1/statuses/update.json"];
                
                SLRequest *postRequest = [SLRequest
                                          requestForServiceType:SLServiceTypeTwitter
                                          requestMethod:SLRequestMethodPOST
                                          URL:requestURL parameters:message];
                
                postRequest.account = twitterAccount;
                NSLog(@"Account %@ message %@",twitterAccount.username,message[@"status"]);
                
                [postRequest performRequestWithHandler:^(NSData *responseData,
                                                         NSHTTPURLResponse *urlResponse, NSError *error)
                 {
                     NSLog(@"Twitter HTTP response: %i", [urlResponse
                                                          statusCode]);
                     if([urlResponse statusCode]==200){
                         [self.commandDelegate sendPluginResult:[ CDVPluginResult
                                                                 resultWithStatus    : CDVCommandStatus_OK
                                                                 messageAsString:@"Tweet sent"
                                                                 ] callbackId:command.callbackId];
                     }else{
                         
                         [self.commandDelegate sendPluginResult:[ CDVPluginResult
                                                                 resultWithStatus    : CDVCommandStatus_ERROR
                                                                 messageAsString:[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]
                                                                 ] callbackId:command.callbackId];
                     }
                 }];
            }else{
                [self.commandDelegate sendPluginResult:[ CDVPluginResult
                                                        resultWithStatus    : CDVCommandStatus_ERROR
                                                        messageAsString:@"No Twitter accounts"
                                                        ] callbackId:command.callbackId];
            }
        }else{
            [self.commandDelegate sendPluginResult:[ CDVPluginResult
                                                    resultWithStatus    : CDVCommandStatus_ERROR
                                                    messageAsString:@"User permission denied"
                                                    ] callbackId:command.callbackId];
        }
    }];
}

- (void) chooseAndSend:(CDVInvokedUrlCommand*)command;
{
    NSMutableDictionary *args = [command.arguments objectAtIndex:0];
    NSString *text = [args objectForKey:@"text"];
    NSString *url = [args objectForKey:@"url"];
    NSString *image = [args objectForKey:@"image"];
    NSString *subject = [args objectForKey:@"subject"];
    NSArray *activityTypes = [[args objectForKey:@"activityTypes"] componentsSeparatedByString:@","];

    NSMutableArray *items = [NSMutableArray new];
    if (text)
    {
        [items addObject:text];
    }
    if (url)
    {
        NSURL *formattedUrl = [NSURL URLWithString:[NSString stringWithFormat:@"%@", url]];
        [items addObject:formattedUrl];
    }
    if (image)
    {
        UIImage *imageFromUrl = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", image]]]];
        [items addObject:imageFromUrl];
    }

    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:Nil];
    [activity setValue:subject forKey:@"subject"];

    NSMutableArray *exclusions = [[NSMutableArray alloc] init];

    if (![activityTypes containsObject:@"PostToFacebook"])
    {
        [exclusions addObject: UIActivityTypePostToFacebook];
    }
    if (![activityTypes containsObject:@"PostToTwitter"])
    {
        [exclusions addObject: UIActivityTypePostToTwitter];
    }
    if (![activityTypes containsObject:@"PostToWeibo"])
    {
        [exclusions addObject: UIActivityTypePostToWeibo];
    }
    if (![activityTypes containsObject:@"Message"])
    {
        [exclusions addObject: UIActivityTypeMessage];
    }
    if (![activityTypes containsObject:@"Mail"])
    {
        [exclusions addObject: UIActivityTypeMail];
    }
    if (![activityTypes containsObject:@"Print"])
    {
        [exclusions addObject: UIActivityTypePrint];
    }
    if (![activityTypes containsObject:@"CopyToPasteboard"])
    {
        [exclusions addObject: UIActivityTypeCopyToPasteboard];
    }
    if (![activityTypes containsObject:@"AssignToContact"])
    {
        [exclusions addObject: UIActivityTypeAssignToContact];
    }
    if (![activityTypes containsObject:@"SaveToCameraRoll"])
    {
        [exclusions addObject: UIActivityTypeSaveToCameraRoll];
    }

    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        if (![activityTypes containsObject:@"AddToReadingList"])
        {
            [exclusions addObject: UIActivityTypeAddToReadingList];
        }
        if (![activityTypes containsObject:@"PostToFlickr"])
        {
            [exclusions addObject: UIActivityTypePostToFlickr];
        }
        if (![activityTypes containsObject:@"PostToVimeo"])
        {
            [exclusions addObject: UIActivityTypePostToVimeo];
        }
        if (![activityTypes containsObject:@"TencentWeibo"])
        {
            [exclusions addObject: UIActivityTypePostToTencentWeibo];
        }
        if (![activityTypes containsObject:@"AirDrop"])
        {
            [exclusions addObject: UIActivityTypeAirDrop];
        }
    }

    activity.excludedActivityTypes = exclusions;

    [self.viewController presentViewController:activity animated:YES completion:Nil];
}

@end
