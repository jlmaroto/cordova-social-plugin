var SocialPlugin = {
	allActivityTypes : ["PostToFacebook", "PostToTwitter", "PostToWeibo", "Message", "Mail", "Print", "CopyToPasteboard", "AssignToContact", "SaveToCameraRoll", "AddToReadingList", "PostToFlickr", "PostToVimeo", "TencentWeibo", "AirDrop"],
	chooseAndSend:function (message) {
		if (!message) {
			return;
		}
		if (typeof (message.activityTypes) === "undefined" || message.activityTypes === null || message.activityTypes.length === 0) {
			message.activityTypes = this.allowedActivityTypes||this.allActivityTypes;
		}
		message.activityTypes = message.activityTypes.join(",");
		cordova.exec(null, null, "socialplugin", "chooseAndSend", [message]);
	},
	setFacebookAppId:function (appId, success,error){
		if(!appId){
			return;
		}
		cordova.exec(success,error,"SocialPlugin","setFacebookIdentityData",[{ACFacebookAppIdKey: appId}]);
	},
	getFacebookAccount:function(success,error){
		cordova.exec(success,error,"SocialPlugin","getFacebookAccount",[]);
	},
	postToFacebook:function(messageData,success,error){
		//message is an object with this keys
		//text: post text
		//link: post link (optional)
		//username: the username of the account. if it's not set or no matches found it tooks the last account in the accountStore (optional)
		//audience: who can see the post (default to friends). the values are "friends", "all", "me"
		if(!messageData||!messageData.text){
			error("You must set post text");
		}
		cordova.exec(success,error,"SocialPlugin","postToFacebook",[messageData]);
	},getTwitterAccounts:function(success,error){
		cordova.exec(success,error,"SocialPlugin","getTwitterAccounts",[]);
	},
	postToTwitter:function(messageData,success,error){
		//message is an object with this keys
		//text: post text
		//username: the username of the account. if it's not set or no matches found it tooks the last account in the accountStore (optional)
		if(!messageData||!messageData.text){
			error("You must set post text");
		}
		cordova.exec(success,error,"SocialPlugin","postToTwitter",[messageData]);
	}

};
module.exports = SocialPlugin;


