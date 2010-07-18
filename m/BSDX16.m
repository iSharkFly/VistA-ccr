BSDX16	; IHS/OIT/HMW - WINDOWS SCHEDULING RPCS ; 
	;;1.3T1;BSDX;;Jul 18, 2010
	;
	;
RSRCD(BSDXY,BSDXVAL)	;EP
	;Entry point for debugging
	;
	;D DEBUG^%Serenji("RSRC^BSDX16(.BSDXY,BSDXVAL)")
	Q
	;
RSRC(BSDXY,BSDXVAL)	;EP
	;
	;Called by BSDX ADD/EDIT RESOURCE
	;Add/Edit BSDX RESOURCE entry
	;BSDXVAL is sResourceID|sResourceName|sInactive|sHospLocID|TIME_SCALE|LETTER_TEXT|NO_SHOW_LETTER|CANCELLATION_LETTER
	;If IEN=0 Then this is a new Resource
	;Test Line:
	;D RSRC^BSDX16(.RES,"sResourceID|sResourceName|sInactive|sHospLocID")
	;
	S X="ERROR^BSDX16",@^%ZOSF("TRAP")
	N BSDXIENS,BSDXFDA,BSDXIEN,BSDXMSG,BSDX,BSDXINA,BSDXNOTE,BSDXNAM
	S BSDXY="^BSDXTMP("_$J_")"
	K ^BSDXTMP($J)
	S ^BSDXTMP($J,0)="I00020RESOURCEID^T00030ERRORTEXT"_$C(30)
	; Changed following from a $G = "" to $D check: $G didn't work since BSDXVAL is an array. MJL 10/18/2006
	I BSDXVAL="",$D(BSDXVAL)<2 D ERR(0,"BSDX16: Invalid null input Parameter") Q
	;Unpack array at @XWBARY
	I BSDXVAL="" D
	. N BSDXC S BSDXC=0 F  S BSDXC=$O(BSDXVAL(BSDXC)) Q:'BSDXC  D
	. . S BSDXVAL=BSDXVAL_BSDXVAL(BSDXC)
	S BSDXIEN=$P(BSDXVAL,"|")
	I +BSDXIEN D
	. S BSDX="EDIT"
	. S BSDXIENS=BSDXIEN_","
	E  D
	. S BSDX="ADD"
	. S BSDXIENS="+1,"
	;
	S BSDXNAM=$P(BSDXVAL,"|",2)
	;Prevent adding entry with duplicate name
	I $D(^BSDXRES("B",BSDXNAM)),$O(^BSDXRES("B",BSDXNAM,0))'=BSDXIEN D  Q
	. D ERR(0,"BSDX16: Cannot have two Resources with the same name.")
	. Q
	;
	S BSDXINA=$P(BSDXVAL,"|",3)
	S BSDXINA=$S(BSDXINA="YES":1,1:0)
	;
	S BSDXFDA(9002018.1,BSDXIENS,.01)=$P(BSDXVAL,"|",2) ;NAME
	S BSDXFDA(9002018.1,BSDXIENS,.02)=BSDXINA ;INACTIVE
	I +$P(BSDXVAL,"|",5) S BSDXFDA(9002018.1,BSDXIENS,.03)=+$P(BSDXVAL,"|",5) ;TIME SCALE
	I +$P(BSDXVAL,"|",4) S BSDXFDA(9002018.1,BSDXIENS,.04)=$P(BSDXVAL,"|",4) ;HOSPITAL LOCATION
	K BSDXMSG
	I BSDX="ADD" D  ;TODO: Check for error
	. K BSDXIEN
	. D UPDATE^DIE("","BSDXFDA","BSDXIEN","BSDXMSG")
	. S BSDXIEN=+$G(BSDXIEN(1))
	E  D
	. D FILE^DIE("","BSDXFDA","BSDXMSG")
	;
	;LETTER TEXT wp field
	S BSDXNOTE=$P(BSDXVAL,"|",6)
	;
	I BSDXNOTE]"" S BSDXNOTE(.5)=BSDXNOTE,BSDXNOTE=""
	I $D(BSDXNOTE(0)) S BSDXNOTE(.5)=BSDXNOTE(0) K BSDXNOTE(0)
	;
	I $D(BSDXNOTE(.5)) D
	. D WP^DIE(9002018.1,BSDXIEN_",",1,"","BSDXNOTE","BSDXMSG")
	;
	;NO SHOW LETTER wp fields
	K BSDXNOTE
	S BSDXNOTE=$P(BSDXVAL,"|",7)
	;
	I BSDXNOTE]"" S BSDXNOTE(.5)=BSDXNOTE,BSDXNOTE=""
	I $D(BSDXNOTE(0)) S BSDXNOTE(.5)=BSDXNOTE(0) K BSDXNOTE(0)
	;
	I $D(BSDXNOTE(.5)) D
	. D WP^DIE(9002018.1,BSDXIEN_",",1201,"","BSDXNOTE","BSDXMSG")
	;
	;CANCELLATION LETTER wp field
	K BSDXNOTE
	S BSDXNOTE=$P(BSDXVAL,"|",8)
	;
	I BSDXNOTE]"" S BSDXNOTE(.5)=BSDXNOTE,BSDXNOTE=""
	I $D(BSDXNOTE(0)) S BSDXNOTE(.5)=BSDXNOTE(0) K BSDXNOTE(0)
	;
	I $D(BSDXNOTE(.5)) D
	. D WP^DIE(9002018.1,BSDXIEN_",",1301,"","BSDXNOTE","BSDXMSG")
	;
	S ^BSDXTMP($J,1)=$G(BSDXIEN)_"^"_$C(30)_$C(31)
	Q
	;
ERROR	;
	D ^%ZTER
	I '+$G(BSDXI) N BSDXI S BSDXI=999999
	S BSDXI=BSDXI+1
	D ERR(0,"BSDX16 M Error: <"_$G(%ZTERROR)_">")
	Q
	;
ERR(BSDXERID,ERRTXT)	;Error processing
	S:'+$G(BSDXI) BSDXI=999999
	S BSDXI=BSDXI+1
	S ^BSDXTMP($J,BSDXI)=BSDXERID_"^"_ERRTXT_$C(30)
	S BSDXI=BSDXI+1
	S ^BSDXTMP($J,BSDXI)=$C(31)
	Q
