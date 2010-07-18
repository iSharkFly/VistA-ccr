BSDX15	; IHS/OIT/HMW - WINDOWS SCHEDULING RPCS ;
	;;1.3T1;BSDX;;Jul 18, 2010
	;
	;
GRPTYP(BSDXY)	;EP
	;Called by BSDX GET ACCESS GROUP TYPES
	;Returns ADO recordset containing ACTIVE Access types ordered alphabetically
	;by Access Group
	;AccessGroupID, AccessGroup, AccessTypeID, AccessType
	;
	;Test Code:
	;D GRPTYP^BSDX15(.RES) ZW RES
	;
	S BSDXY="^BSDXTMP("_$J_")"
	N BSDX1
	S BSDXI=0
	S X="ETRAP^BSDX15",@^%ZOSF("TRAP")
	S ^BSDXTMP($J,BSDXI)="I00020ACCESS_GROUP_TYPEID^I00020ACCESS_GROUP_ID^T00030ACCESS_GROUP^I00020ACCESS_TYPE_ID^T00030ACCESS_TYPE"_$C(30)
	;
	;N BSDX0,BSDX1,BSDXNOD,BSDXGPN,BSDXTN
	;$O Through "B" x-ref of BSDX ACCESS GROUP file
	;S BSDXGPN=0 F  S BSDXGPN=$O(^BSDXAGP("B",BSDXGPN)) Q:BSDXGPN=""  D
	;. S BSDX0=$O(^BSDXAGP("B",BSDXGPN,0))
	;. Q:'+BSDX0
	;. Q:'$D(^BSDXAGP(BSDX0,0))  ;INDEX VALIDITY CHECK
	;. Q:'$D(^BSDXAGTP("B",BSDX0))
	;. ;$O through "B" x-ref of BSDX ACCESS GROUP TYPE
	;. S BSDX1=0 F  S BSDX1=$O(^BSDXAGTP("B",BSDX0,BSDX1)) Q:'+BSDX1  D
	;. . Q:'$D(^BSDXAGTP(BSDX1,0))
	;. . S BSDX2=$P(^BSDXAGTP(BSDX1,0),U,2)
	;. . Q:'+BSDX2
	;. . Q:'$D(^BSDXTYPE(BSDX2,0))
	;. . S BSDXNOD=^BSDXTYPE(BSDX2,0)
	;. . Q:$P(BSDXNOD,U,2)=1  ;INACTIVE
	;. . S BSDXTN=$P(BSDXNOD,U)
	;. . S BSDXI=BSDXI+1
	;. . S ^BSDXTMP($J,BSDXI)=BSDX1_U_BSDX0_U_BSDXGPN_U_BSDX2_U_BSDXTN_$C(30)
	;. . Q
	;. Q
	;
	;$O Through "AC" x-ref of BSDX ACCESS GROUP TYPE file
	N BSDXAGID,BSDXAGN,BSDXATID,BSDXATN,BSDXAGTID
	S BSDXAGID=0
	F  S BSDXAGID=$O(^BSDXAGTP("AC",BSDXAGID)) Q:'+BSDXAGID  D
	. I '$D(^BSDXAGP(BSDXAGID,0)) Q
	. S BSDXAGN=$P(^BSDXAGP(BSDXAGID,0),U)
	. S BSDXATID=0 F  S BSDXATID=$O(^BSDXAGTP("AC",BSDXAGID,BSDXATID)) Q:'+BSDXATID  D
	. . S BSDXNOD=$G(^BSDXTYPE(BSDXATID,0))
	. . I BSDXNOD="" Q
	. . I $P(BSDXNOD,U,2)=1 Q  ;Inactive
	. . S BSDXATN=$P(BSDXNOD,U)
	. . S BSDXAGTID=$O(^BSDXAGTP("AC",BSDXAGID,BSDXATID,0))
	. . I '+BSDXAGTID Q
	. . I '$D(^BSDXAGTP(BSDXAGTID,0)) Q
	. . S BSDXI=BSDXI+1
	. . S ^BSDXTMP($J,BSDXI)=BSDXAGTID_U_BSDXAGID_U_BSDXAGN_U_BSDXATID_U_BSDXATN_$C(30)
	. . Q
	. Q
	;
	S BSDXI=BSDXI+1
	S ^BSDXTMP($J,BSDXI)=$C(31)
	Q
	;
ERR(BSDXI,BSDXID,BSDXERR)	;Error processing
	S BSDXI=BSDXI+1
	S ^BSDXTMP($J,BSDXI)=BSDXERR_"^^^^"_$C(30)
	S BSDXI=BSDXI+1
	S ^BSDXTMP($J,BSDXI)=$C(31)
	Q
	;
ETRAP	;EP Error trap entry
	I '$D(BSDXI) N BSDXI S BSDXI=999
	S BSDXI=BSDXI+1
	D ERR(BSDXI,99,70)
	Q
