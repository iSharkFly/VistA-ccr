BSDX35	; IHS/OIT/HMW - WINDOWS SCHEDULING RPCS ;
	;;1.5T1;BSDX;;Apr 06, 2011
	;
	;
	Q
	;
RSRCLTRD(BSDXY,BSDXLIST)	;EP
	;Entry point for debugging
	;
	;D DEBUG^%Serenji("RSRCLTR^BSDX35(.BSDXY,BSDXLIST)")
	Q
	;
RSRCLTR(BSDXY,BSDXLIST)	;EP
	;
	;Return recordset of RESOURCES and associated LETTERS
	;Used in generating rebook letters for a clinic
	;BSDXLIST is a |-delimited list of BSDX RESOURCE iens.  (The last |-piece is null, so discard it.)
	;Called by BSDX RESOURCE LETTERS
	;
	;
	S X="ERROR^BSDX35",@^%ZOSF("TRAP")
	S BSDXY="^BSDXTMP("_$J_")"
	N BSDXIEN,BSDX,BSDXLTR,BSDXNOS,BSDXCAN,BSDXIEN1
	S BSDXI=0
	S ^BSDXTMP($J,BSDXI)="I00010RESOURCEID^T00030RESOURCE_NAME^T00030LETTER_TEXT^T00030NO_SHOW_LETTER^T00030CLINIC_CANCELLATION_LETTER"_$C(30)
	;
	;
	;If BSDXLIST is a list of resource NAMES, look up each name and convert to IEN
	F BSDXJ=1:1:$L(BSDXLIST,"|")-1 S BSDX=$P(BSDXLIST,"|",BSDXJ) D  S $P(BSDXLIST,"|",BSDXJ)=BSDY
	. S BSDY=""
	. I BSDX]"",$D(^BSDXRES(BSDX,0)) S BSDY=BSDX Q
	. I BSDX]"",$D(^BSDXRES("B",BSDX)) S BSDY=$O(^BSDXRES("B",BSDX,0)) Q
	. Q
	;
	;Get letter text from wp fields
	S BSDXIEN=0
	F BSDX=1:1:$L(BSDXLIST,"|")-1 S BSDXIEN=$P(BSDXLIST,"|",BSDX) D
	. Q:'$D(^BSDXRES(BSDXIEN))
	. S BSDXNAM=$P(^BSDXRES(BSDXIEN,0),U)
	. S BSDXLTR=""
	. I $D(^BSDXRES(BSDXIEN,1)) D
	. . S BSDXIEN1=0 F  S BSDXIEN1=$O(^BSDXRES(BSDXIEN,1,BSDXIEN1)) Q:'+BSDXIEN1  D
	. . . S BSDXLTR=BSDXLTR_$G(^BSDXRES(BSDXIEN,1,BSDXIEN1,0))
	. . . S BSDXLTR=BSDXLTR_$C(13)_$C(10)
	. S BSDXNOS=""
	. I $D(^BSDXRES(BSDXIEN,12)) D
	. . S BSDXIEN1=0 F  S BSDXIEN1=$O(^BSDXRES(BSDXIEN,12,BSDXIEN1)) Q:'+BSDXIEN1  D
	. . . S BSDXNOS=BSDXNOS_$G(^BSDXRES(BSDXIEN,12,BSDXIEN1,0))
	. . . S BSDXNOS=BSDXNOS_$C(13)_$C(10)
	. S BSDXCAN=""
	. I $D(^BSDXRES(BSDXIEN,13)) D
	. . S BSDXIEN1=0 F  S BSDXIEN1=$O(^BSDXRES(BSDXIEN,13,BSDXIEN1)) Q:'+BSDXIEN1  D
	. . . S BSDXCAN=BSDXCAN_$G(^BSDXRES(BSDXIEN,13,BSDXIEN1,0))
	. . . S BSDXCAN=BSDXCAN_$C(13)_$C(10)
	. S BSDXI=BSDXI+1
	. S ^BSDXTMP($J,BSDXI)=BSDXIEN_U_BSDXNAM_U_BSDXLTR_U_BSDXNOS_U_BSDXCAN_$C(30)
	;
	S BSDXI=BSDXI+1
	S ^BSDXTMP($J,BSDXI)=$C(31)
	Q
	;
ERROR	;
	D ERR("RPMS Error")
	Q
	;
ERR(ERRNO)	;Error processing
	S:'$D(BSDXI) BSDXI=999
	I +ERRNO S BSDXERR=ERRNO+134234112 ;vbObjectError
	E  S BSDXERR=ERRNO
	S BSDXI=BSDXI+1
	S ^BSDXTMP($J,BSDXI)="^^^^"_$C(30)
	S BSDXI=BSDXI+1
	S ^BSDXTMP($J,BSDXI)=$C(31)
	Q
