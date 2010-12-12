BSDX19	; IHS/OIT/HMW - WINDOWS SCHEDULING RPCS ;
	;;1.42;BSDX;;Dec 07, 2010
	;
	;
ADDRGD(BSDXY,BSDXVAL)	;EP
	;Entry point for debugging
	;
	;D DEBUG^%Serenji("ADDRG^BSDX19(.BSDXY,BSDXVAL)")
	Q
	;
ADDRG(BSDXY,BSDXVAL)	;EP
	;Called by BSDX ADD/EDIT RESOURCE GROUP
	;Add a new BSDX RESOURCE GROUP entry
	;BSDXVAL is IEN|NAME of the entry
	;Returns IEN of added/edited entry or 0 if error
	;
	S X="ERROR^BSDX19",@^%ZOSF("TRAP")
	N BSDXIENS,BSDXFDA,BSDXMSG,BSDXIEN,BSDX,BSDXNAM
	S BSDXY="^BSDXTMP("_$J_")"
	S ^BSDXTMP($J,0)="I00020RESOURCEGROUPID^T00030ERRORTEXT"_$C(30)
	I BSDXVAL="" D ERR(0,"BSDX16: Invalid null input Parameter") Q
	S BSDXIEN=$P(BSDXVAL,"|")
	S BSDXNAM=$P(BSDXVAL,"|",2)
	I +BSDXIEN D
	. S BSDX="EDIT"
	. S BSDXIENS=BSDXIEN_","
	E  D
	. S BSDX="ADD"
	. S BSDXIENS="+1,"
	;
	;Prevent adding entry with duplicate name
	I $D(^BSDXDEPT("B",BSDXNAM)),$O(^BSDXDEPT("B",BSDXNAM,0))'=BSDXIEN D  Q
	. D ERR(0,"BSDX19: Cannot have two Resource Groups with the same name.")
	. Q
	;
	S BSDXFDA(9002018.2,BSDXIENS,.01)=BSDXNAM ;NAME
	I BSDX="ADD" D
	. K BSDXIEN
	. D UPDATE^DIE("","BSDXFDA","BSDXIEN","BSDXMSG")
	. S BSDXIEN=+$G(BSDXIEN(1))
	E  D
	. D FILE^DIE("","BSDXFDA","BSDXMSG")
	S ^BSDXTMP($J,1)=$G(BSDXIEN)_"^"_$C(30)_$C(31)
	Q
	;
DELRGD(BSDXY,BSDXGRP)	;EP
	;Entry point for debugging
	;
	;D DEBUG^%Serenji("DELRG^BSDX19(.BSDXY,BSDXGRP)")
	Q
	;
DELRG(BSDXY,BSDXGRP)	;EP
	;Deletes entry name BSDXGRP from BSDX RESOURCE GROUP file
	;Return recordset containing error message or "" if no error
	;Called by BSDX DELETE RESOURCE GROUP
	;Test Line:
	;D DELRU^BSDX18(.RES,99)
	;
	N BSDXI,DIK,DA,BSDXIEN
	S BSDXI=0
	S BSDXY="^BSDXTMP("_$J_")"
	S ^BSDXTMP($J,0)="I00020RESOURCEGROUPID^T00030ERRORTEXT"_$C(30)
	I BSDXGRP="" D ERR(0,"DELRG~BSDX19: Invalid null Resource Group Name") Q
	S BSDXIEN=$O(^BSDXDEPT("B",BSDXGRP,0))
	I '+BSDXIEN D ERR(0,"DELRG~BSDX19: Invalid Resource Group Name") Q
	I '$D(^BSDXDEPT(BSDXIEN,0)) D ERR(0,"DELRG~BSDX19: Invalid Resource Group IEN") Q
	;Delete entry BSDXIEN
	S DIK="^BSDXDEPT("
	S DA=BSDXIEN
	D ^DIK
	;
	S BSDXI=BSDXI+1
	S ^BSDXTMP($J,BSDXI)=BSDXIEN_"^"_$C(30)_$C(31)
	Q
	;
ERR(BSDXERID,ERRTXT)	;Error processing
	S:'+$G(BSDXI) BSDXI=999999
	S BSDXI=BSDXI+1
	S ^BSDXTMP($J,BSDXI)=BSDXERID_"^"_ERRTXT_$C(30)
	S BSDXI=BSDXI+1
	S ^BSDXTMP($J,BSDXI)=$C(31)
	Q
	;
ERROR	;
	D ^%ZTER
	I '+$G(BSDXI) N BSDXI S BSDXI=999999
	S BSDXI=BSDXI+1
	D ERR(0,"BSDX19 M Error: <"_$G(%ZTERROR)_">")
	Q
