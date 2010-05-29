#if defined _tads_included_
	#endinput
#endif
#define _tads_included_

#define MSG_SIZE 255

enum ad_types {
	TYPE_CENTER,
	TYPE_HINT,
	TYPE_MENU,
	TYPE_SAY,
	TYPE_TOP,
	TYPE_DEBUG
}

stock ad_types:ParseType(const String:sText[]) {
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

native Ads_RegisterAd(Float:interval, ad_types:type, const String:flags[], const String:text[], const String:trigger[]);
native Ads_UnRegisterAds();

forward Action:Ads_OnSend(String:sText[],length);
forward Action:Ads_OnSendPost(String:sText[],length);