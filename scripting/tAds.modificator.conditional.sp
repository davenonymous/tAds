#pragma semicolon 1

#include <sourcemod>
#include <regex>
#include <tads>

#define PL_VERSION    "0.0.1"

public Plugin:myinfo = {
	name        = "tAds, Conditional Modificators",
	author      = "Thrawn",
	description = "Replaces based on conditions",
	version     = PL_VERSION,
	url         = "http://aaa.wallbash.com"
};

enum Ops {
	EQ,
	NE,
	GT,
	LT,
	GE,
	LE
}

enum Types {
	STR,
	INT,
	FLT
}

//Regular Expressions
new Handle:g_rCond = INVALID_HANDLE;
new g_bDebug = false;

public OnPluginStart() {
	CreateConVar("sm_tads_conditional_version", PL_VERSION, "Display conditional infos in ads", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	decl String:types[255];
	types = "string|s|int|i|float|f";

	decl String:operators[255];
	operators = "==|!=|<|>|<=|>=";

	decl String:pattern[512];
	Format(pattern,sizeof(pattern),"{if:(%s):(%s):'(.*)'(%s)'(.*)'?'(.*)':'(.*)'}",types,types,operators);

	g_rCond = CompileRegex(pattern, PCRE_CASELESS|PCRE_UNGREEDY);
}

public Action:Ads_OnSendPost(String:sText[], size) {
	decl String:buffer[255];
	if(g_bDebug) LogMessage("Input: %s", sText);
	while(MatchRegex(g_rCond, sText) > 0) {
		new String:full[255];
		new String:sCondA[255], String:sCondB[255];
		new Float:fCondA, Float:fCondB;
		new String:ifTrue[255], String:ifFalse[255];

		new Ops:op;
		new Types:typeA, Types:typeB;

		new cnt = 0;
		while(GetRegexSubString(g_rCond, cnt, buffer, sizeof(buffer))) {
			switch(cnt) {
				case 0: {
					full = buffer;
				}
				case 1: {
					typeA = StringToType(buffer);
					if(g_bDebug) LogMessage("TypeA: %s", buffer);
				}
				case 2: {
					typeB = StringToType(buffer);
					if(g_bDebug) LogMessage("TypeB: %s", buffer);
				}
				case 3: {
					if(typeA == INT || typeA == FLT)
						fCondA = StringToFloat(buffer);

					if(typeA == STR)
						sCondA = buffer;

					if(g_bDebug) LogMessage("WertA: %s", buffer);
				}
				case 4: {
					op = StringToOperator(buffer);
					if(g_bDebug) LogMessage("Opera: %s", buffer);
				}
				case 5: {
					if(typeB == INT || typeB == FLT)
						fCondB = StringToFloat(buffer);

					if(typeB == STR)
						sCondB = buffer;

					if(g_bDebug) LogMessage("WertB: %s", buffer);
				}
				case 6: {
					ReplaceString(buffer,sizeof(buffer),"?'","");
					ifTrue = buffer;
					if(g_bDebug) LogMessage("Posit: %s", buffer);
				}
				case 7: {
					ifFalse = buffer;
					if(g_bDebug) LogMessage("Negat: %s", buffer);
				}
			}

			cnt++;
		}

		if((typeA == STR && typeB != STR) || (typeA != STR && typeB == STR)) {
			if(g_bDebug) LogMessage("Tag mismatch in: %s", full);
		}

		if(typeA == STR && typeB == STR) {
			if(op != EQ && op != NE) {
				if(g_bDebug) LogMessage("Operator not supported for String in: %s", full);
			}

			ReplaceString(sText, size, full, StrEqual(sCondA,sCondB) ? (op == EQ ? ifTrue : ifFalse) : (op == EQ ? ifFalse : ifTrue));
		} else {
			if(op == EQ) {
				ReplaceString(sText, size, full, fCondA == fCondB ? ifTrue : ifFalse);
			}

			if(op == NE) {
				ReplaceString(sText, size, full, fCondA != fCondB ? ifTrue : ifFalse);
			}

			if(op == LT) {
				ReplaceString(sText, size, full, fCondA < fCondB ? ifTrue : ifFalse);
			}

			if(op == GT) {
				ReplaceString(sText, size, full, fCondA > fCondB ? ifTrue : ifFalse);
			}

			if(op == GE) {
				ReplaceString(sText, size, full, fCondA >= fCondB ? ifTrue : ifFalse);
			}

			if(op == LE) {
				ReplaceString(sText, size, full, fCondA <= fCondB ? ifTrue : ifFalse);
			}
		}
	}
	if(g_bDebug) LogMessage("Result: %s", sText);
	return Plugin_Changed;
}


stock Types:StringToType(const String:buffer[]) {
	new Types:typeA;
	typeA = STR;

	if(StrEqual(buffer,"string") || StrEqual(buffer,"s"))
		typeA = STR;

	if(StrEqual(buffer,"int") || StrEqual(buffer,"i"))
		typeA = INT;

	if(StrEqual(buffer,"float") || StrEqual(buffer,"f"))
		typeA = FLT;

	return typeA;
}

stock Ops:StringToOperator(const String:buffer[]) {
	new Ops:op;
	op = EQ;

	if(StrEqual(buffer,"=="))
		op = EQ;

	if(StrEqual(buffer,"!="))
		op = NE;

	if(StrEqual(buffer,"<"))
		op = LT;

	if(StrEqual(buffer,">"))
		op = GT;

	if(StrEqual(buffer,"<="))
		op = LE;

	if(StrEqual(buffer,">="))
		op = GE;

	return op;
}