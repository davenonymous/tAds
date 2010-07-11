#if defined _tads_included_
	#endinput
#endif
#define _tads_included_

#define MSG_SIZE 256

enum ad_types {
	TYPE_CENTER,
	TYPE_HINT,
	TYPE_MENU,
	TYPE_SAY,
	TYPE_TOP,
	TYPE_DEBUG
}

stock ad_types:ParseType(String:sText[]) {
	if(StrEqual(sText, "C"))
		return TYPE_CENTER;

	if(StrEqual(sText, "H"))
		return TYPE_HINT;

	if(StrEqual(sText, "M"))
		return TYPE_MENU;

	if(StrEqual(sText, "S"))
		return TYPE_SAY;

	if(StrEqual(sText, "T"))
		return TYPE_TOP;

	if(StrEqual(sText, "D"))
		return TYPE_DEBUG;

	//Default: Center
	return TYPE_CENTER;
}

stock HasType(String:ad[], ad_types:adtype) {
	for (new i = 0; i < strlen(ad); i++) {
		if(ParseType(ad[i]) == adtype)
			return true;
	}

	return false;
}


stock bool:HasFlag(iClient, String:sFlags[16]) {
	decl AdminFlag:fFlagList[16];

	if (!StrEqual(sFlags, "none")) {
		FlagBitsToArray(ReadFlagString(sFlags), fFlagList, sizeof(fFlagList));

		new iFlags = GetUserFlagBits(iClient);
		if (iFlags & ADMFLAG_ROOT) {
			return true;
		} else {
			for (new i = 0; i < sizeof(fFlagList); i++) {
				if (iFlags & FlagToBit(fFlagList[i])) {
					return true;
				}
			}
		}
	}

	return false;
}

native bool:Ads_GetAdText(iAdId, String:AdText[], size);
native Ads_GetAdCount();
native Ads_RegisterAd(Float:interval, String:types[], const String:flags[], const String:text[], const String:trigger[], const String:condition[], const String:filter[]);
native Ads_UnRegisterAds();

forward Action:Ads_OnSendCondition(String:sCondition[]);
forward Action:Ads_OnSendFilter(String:sFilter[], client);
forward Action:Ads_OnSend(String:sText[],length);
forward Action:Ads_OnSendPost(String:sText[],length);