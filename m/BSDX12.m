BSDX12	; IHS/OIT/HMW - WINDOWS SCHEDULING RPCS ; 7/18/10 2:14pm
	;;1.3;IHS WINDOWS SCHEDULING;;NOV 01, 2007
    ; 
    ; Change Log:
    ; v 1.3 - i18n support - 3100718
    ; BSDXSTART and BSDXEND passed in FM Dates, not US dates
	;
	;
AVADD(BSDXY,BSDXSTART,BSDXEND,BSDXTYPID,BSDXRES,BSDXSLOTS,BSDXNOTE)	 ;EP
	;Called by BSDX ADD NEW AVAILABILITY
	;Create entry in BSDX ACCESS BLOCK
	;
	;BSDXRES is Resource Name
	;Returns recordset having fields 
	; AvailabilityID and ErrorNumber
	;
	;Test lines:
	;D AVADD^BSDX12(.RES,"3091227.09","3091227.0930","1","WHITT",2,"SCRATCH AV NOTE") ZW RES
	;BSDX ADD NEW AVAILABILITY^3091227.09^3091227.0930^1^WHITT^2^SCRATCH AVAILABILITY NOTE
	;
	N BSDXERR,BSDXIEN,BSDXDEP,BSDXI,BSDXAVID,BSDXI,BSDXERR,BSDXFDA,BSDXMSG,BSDXRESD
	K ^BSDXTMP($J)
	S BSDXERR=0
	S BSDXI=0
	S BSDXY="^BSDXTMP("_$J_")"
	S ^BSDXTMP($J,0)="I00020AVAILABILITYID^I00020ERRORID"_$C(30)
	;Check input data for errors
    ; i18n - FM Dates passed in
	; S:BSDXSTART["@0000" BSDXSTART=$P(BSDXSTART,"@")
	; S:BSDXEND["@0000" BSDXEND=$P(BSDXEND,"@")
	; S %DT="T",X=BSDXSTART D ^%DT S BSDXSTART=Y
	; I BSDXSTART=-1 D ERR(70) Q
	; S %DT="T",X=BSDXEND D ^%DT S BSDXEND=Y
	; I BSDXEND=-1 D ERR(70) Q
    ; Make sure dates are canonical and don't contain extra zeros
    S BSDXSTART=+BSDXSTART,BSDXEND=+BSDXEND
    ;
	I $L(BSDXEND,".")=1 D ERR(70) Q
	I BSDXSTART>BSDXEND S BSDXTMP=BSDXEND,BSDXEND=BSDXSTART,BSDXSTART=BSDXTMP
	;Validate Access Type
	I '+BSDXTYPID,'$D(^BSDXTYPE(BSDXTYPID,0)) D ERR(70) Q
	;Validate Resource
	I '$D(^BSDXRES("B",BSDXRES)) S BSDXERR=70 D ERR(BSDXERR) Q
	S BSDXRESD=$O(^BSDXRES("B",BSDXRES,0)) I '+BSDXRESD S BSDXERR=70 D ERR(BSDXERR) Q
	;
	;Create entry in BSDX ACCESS BLOCK
	S BSDXFDA(9002018.3,"+1,",.01)=BSDXRESD
	S BSDXFDA(9002018.3,"+1,",.02)=BSDXSTART
	S BSDXFDA(9002018.3,"+1,",.03)=BSDXEND
	S BSDXFDA(9002018.3,"+1,",.04)=BSDXSLOTS
	S BSDXFDA(9002018.3,"+1,",.05)=BSDXTYPID
	K BSDXIEN,BSDXMSG
	D UPDATE^DIE("","BSDXFDA","BSDXIEN","BSDXMSG")
	S BSDXAVID=+$G(BSDXIEN(1))
	I 'BSDXAVID D ERR(70) Q
	;
	;Add WP field
	I BSDXNOTE]"" S BSDXNOTE(.5)=BSDXNOTE,BSDXNOTE=""
	I $D(BSDXNOTE(0)) S BSDXNOTE(.5)=BSDXNOTE(0) K BSDXNOTE(0)
	I $D(BSDXNOTE(.5)) D
	. D WP^DIE(9002018.3,BSDXAVID_",",1,"","BSDXNOTE","BSDXMSG")
	;
	;Return Recordset
	S BSDXI=BSDXI+1
	S ^BSDXTMP($J,BSDXI)=BSDXAVID_"^-1"_$C(30)
	S BSDXI=BSDXI+1
	S ^BSDXTMP($J,BSDXI)=$C(31)
	Q
	;
ERR(ERRNO)	;Error processing
	S BSDXERR=ERRNO+134234112 ;vbObjectError
	S BSDXI=BSDXI+1
	S ^BSDXTMP($J,BSDXI)="0^"_BSDXERR_$C(30)
	S BSDXI=BSDXI+1
	S ^BSDXTMP($J,BSDXI)=$C(31)
	Q
