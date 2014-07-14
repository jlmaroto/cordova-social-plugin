var SocialPlugin = {
	allActivityTypes : ["PostToFacebook", "PostToTwitter", "PostToWeibo", "Message", "Mail", "Print", "CopyToPasteboard", "AssignToContact", "SaveToCameraRoll", "AddToReadingList", "PostToFlickr", "PostToVimeo", "TencentWeibo", "AirDrop"],
	allowedActivityTypes: null,
	availableTypes:null,
	getAvailableAccounts: function(accountTypes,success,failure){
		if(typeof (accountTypes) === undefined || accountTypes === null || accountTypes.length ===0){
			accountTypes=this.availableTypes||this.allActivityTypes;
		}
		cordova.exec(function(accounts){
			console.log(accounts);
		},failure,"SocialPlugin","getAvailableAccounts",[]);
	},
	loginAccount:function(accountType,success,failure){
                cordova.exec(success,failure,"SocialPlugin","loginTo",[accountType]);
	},
	sendPostTo:function(message){
		if (!message) {
                        return;
                }
                if (typeof (message.activityTypes) === "undefined" || message.activityTypes === null || message.activityTypes.length === 0) {
                        return ;
                }
		
		cordova.exec(function(){
			console.log("message sent");
		},function(){
			console.log("message can't be sent");
		},"SocialPlugin","sendPostTo",[message]);
	},
	chooseAndSend:function (message) {
		if (!message) {
			return;
		}
		if (typeof (message.activityTypes) === "undefined" || message.activityTypes === null || message.activityTypes.length === 0) {
			message.activityTypes = this.allowedActivityTypes||this.allActivityTypes;
		}
		message.activityTypes = message.activityTypes.join(",");
		exec(null, null, "SocialPlugin", "chooseAndSend", [message]);
	}
};
module.exports = SocialPlugin;


