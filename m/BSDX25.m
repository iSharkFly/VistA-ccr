BSDX25	; VEN/SMH - WINDOWS SCHEDULING RPCS ; 7/9/12 5:00pm
	;;1.7;BSDX;;Jun 01, 2013;Build 24
	; Licensed under LGPL
	;
	; Change Log:
	; 3110106: SMH -> Changed Check-in EP - Removed unused paramters. Will change C#
	; 3120630: VEN/SMH -> Extensive Refactoring to remove transactions.
	;                  -> Functionality still the same.
	;                  -> Unit Tests in UT25^BSDXUT2
	;
	;
CHECKIND(BSDXY,BSDXAPPTID,BSDXCDT,BSDXCC,BSDXPRV,BSDXROU,BSDXVCL,BSDXVFM,BSDXOG)	;EP
	;Entry point for debugging
	;
	;I +$G(^BSDXDBUG("BREAK","CHECKIN")),+$G(^BSDXDBUG("BREAK"))=DUZ D DEBUG^%Serenji("CHECKIN^BSDX25(.BSDXY,BSDXAPPTID,BSDXCDT,BSDXCC,BSDXPRV,BSDXROU,BSDXVCL,BSDXVFM,BSDXOG)",$P(^BSDXDBUG("BREAK"),U,2))
	Q
	;
CHECKIN(BSDXY,BSDXAPPTID,BSDXCDT)	;Private EP Check in appointment
	; Old additional vars: ,BSDXCC,BSDXPRV,BSDXROU,BSDXVCL,BSDXVFM,BSDXOG)
	; Called by RPC: BSDX CHECKIN APPOINTMENT
	;
	; Private to GUI; use BSDXAPI for general API to checkin patients
	; Parameters:
	; BSDXY: Global Out
	; BSDXAPPTID: Appointment ID in ^BSDXAPPT
	; BSDXCDT: Checkin Date --> Changed
	; BSDXCC: Clinic Stop IEN (not used)
	; BSDXPRV: Provider IEN (not used)
	; BSDXROU: Print Routing Slip? (not used)
	; BSDXVCL: PCC+ Clinic IEN (not used)
	; BSDXVFM: PCC+ Form IEN (not used)
	; BSDXOG: PCC+ Outguide (true or false) (not used)
	;
	; Output:
	; ADO.net table with 1 column ErrorID, 1 row result
	; - 0 if all okay
	; - Another number or text if not
	;
	; Error reference:
	; -1 -> Invalid Appointment ID
	; -2 -> Invalid Check-in Date
	; -3 -> Cannot check-in due to Fileman Filer failure
	; -4 -> Cannot lock ^BSDXAPPT(APPTID)
	; -10 -> BSDXAPI error
	; -100 -> Mumps Error
	;
	; Turn off SDAM Appointment Events BSDX Protocol Processing
	N BSDXNOEV
	S BSDXNOEV=1 ;Don't execute protocol
	;
	; Set min DUZ vars
	D ^XBKVAR
	;
	; $ET
	N $ET S $ET="G ERROR^BSDX25"
	;
	; Test for error trap for Unit Tests
	I $G(BSDXDIE) N X S X=1/0
	;
	N BSDXI S BSDXI=0
	;
	S BSDXY=$NAME(^BSDXTMP($J))
	K @BSDXY
	;
	S ^BSDXTMP($J,0)="T00020ERRORID"_$C(30)
	;
	I '+BSDXAPPTID D ERR("-1~Invalid Appointment ID") QUIT
	I '$D(^BSDXAPPT(BSDXAPPTID,0)) D ERR("-1~Invalid Appointment ID") QUIT
	;
	; Lock BSDX node, only to synchronize access to the globals.
	; It's not expected that the error will ever happen as no filing
	; is supposed to take 5 seconds.
	L +^BSDXAPPT(BSDXAPPTID):5 E  D ERR("-4~Appt record is locked. Please contact technical support.") QUIT
	;
	; Remove Date formatting v.1.5. Client will send date as FM Date.
	;S:BSDXCDT["@0000" BSDXCDT=$P(BSDXCDT,"@")
	;S %DT="T",X=BSDXCDT D ^%DT S BSDXCDT=Y
	S BSDXCDT=+BSDXCDT  ; Strip off zeros if C# sends them
	I BSDXCDT'>2000000 D ERR("-2~Invalid Check-in Date") QUIT
	I BSDXCDT>$$NOW^XLFDT S BSDXCDT=$$NOW^XLFDT
	;
	; Some data
	N BSDXNOD S BSDXNOD=^BSDXAPPT(BSDXAPPTID,0) ; Appointment Node
	N BSDXPATID S BSDXPATID=$P(BSDXNOD,U,5) ; DFN
	N BSDXSTART S BSDXSTART=$P(BSDXNOD,U) ; Appointment Start Time
	;
	; Get Hospital Location IEN from BSDXAPPT to BSDXRES (RESOUCE:HOSPITAL LOCATION)
	N BSDXSC1 S BSDXSC1=$$GET1^DIQ(9002018.4,BSDXAPPTID_",",".07:.04","I")
	I BSDXSC1,'$D(^SC(BSDXSC1,0)) S BSDXSC1="" ; Null it off if it doesn't exist
	;
	; Check if we can check-in using BSDXAPI
	N BSDXERR S BSDXERR=0
	I BSDXSC1 S BSDXERR=$$CHECKIC1^BSDXAPI(BSDXPATID,BSDXSC1,BSDXSTART)
	I BSDXERR D ERR(-10_"~"_$P(BSDXERR,U,2)) QUIT
	;
	; Checkin BSDX APPOINTMENT entry
	; Failure Analysis: If we fail here, no changes were made.
	N BSDXERR S BSDXERR=$$BSDXCHK(BSDXAPPTID,BSDXCDT)
	I BSDXERR D ERR("-3~Fileman Filer failed to check-in appt") QUIT
	;
	; File check-in using BSDXAPI
	; Failure Analysis: If we fail here, we need to roll back first check-in.
	N BSDXERR S BSDXERR=0
	I BSDXSC1 S BSDXERR=$$CHECKIN1^BSDXAPI(BSDXPATID,BSDXSC1,BSDXSTART)
	I BSDXERR D  QUIT
	. N % S %=$$BSDXCHK(BSDXAPPTID,"@") ; No Error checking to prevent loop.
	. D ERR(-10_"~"_$P(BSDXERR,U,2)) ; Send error message to client
	;
	L -^BSDXAPPT(BSDXAPPTID)
	S BSDXI=BSDXI+1
	S ^BSDXTMP($J,BSDXI)="0"_$C(30)
	S BSDXI=BSDXI+1
	S ^BSDXTMP($J,BSDXI)=$C(31)
	Q
	;
BSDXCHK(BSDXAPPTID,BSDXCDT)	; $$ Private Entry Point. File or delete check-in to
	; BSDX Appointment
	; Input: BSDXAPPTID -> Appointment ID
	;        BSDXCDT -> Check-in date, or "@" to remove check-in.
	;
	; Output: 1^Error for error
	;         0 for success
	;
	Q:$G(BSDXSIMERR1) 1_U_"Simulated Error 1"
	;
	N BSDXIENS,BSDXMSG,BSDXFDA ; Filer variables
	S BSDXIENS=BSDXAPPTID_","
	S BSDXFDA(9002018.4,BSDXIENS,.03)=BSDXCDT
	D FILE^DIE("","BSDXFDA","BSDXMSG")
	Q:$D(BSDXMSG) 1_U_BSDXMSG("DIERR",1,"TEXT",1)
	Q 0
	;
RMCI(BSDXY,BSDXAPPTID)	; Private EP - Remove Check-in from BSDX APPT and 2/44
	; Called by RPC BSDX REMOVE CHECK-IN
	; 
	; Parameters to pass:
	; APPTID: IEN in file BSDX APPOINTMENT
	;
	; Return in global array:
	; Record set with Column ERRORID; value of 0 AOK; other value 
	;  --> means that something went wrong
	; 
	; Error Reference:
	; -1~Invalid Appointment ID (not passed)
	; -2~Invalid Appointment ID (Doesn't exist in ^BSDXAPPT)
	; -3~DB has corruption. Call Tech Support. (Resource ID doesn't exist in BSDXAPPT)
	; -4~DB has corruption. Call Tech Support. (Resource ID in BSDXAPPT doesnt exist in BSDXRES)
	; -5~BSDXAPI Error. Message depends on error.
	; -6~Data Filing Error in BSDXCHK
	; -7~Lock not acquired
	; -100~Mumps Error
	; 
	N BSDXNOEV S BSDXNOEV=1 ;Don't execute protocol
	;
	N $ET S $ET="G ERROR^BSDX25" ; Error Trap
	;
	; Set return variable and kill contents
	S BSDXY=$NAME(^BSDXTMP($J))
	K @BSDXY
	; 
	N BSDXI S BSDXI=0 ; Initialize Counter
	;
	S ^BSDXTMP($J,BSDXI)="T00020ERRORID"_$C(30) ; Header of ADO recordset
	;
	;;;test
	I $G(BSDXDIE) N X S X=8/0
	;
	; Check for Appointment ID (passed and exists in file)
	I '+$G(BSDXAPPTID) D ERR("-1~Invalid Appointment ID") QUIT
	I '$D(^BSDXAPPT(BSDXAPPTID,0)) D ERR("-2~Invalid Appointment ID") QUIT
	;
	; Lock
	; Timeout not expected to happen except in error conditions.
	L +^BSDXAPPT(BSDXAPPTID):5 E  D ERR("-7~Appt record is locked. Please contact technical support.") QUIT
	;
	; Get appointment Data
	N BSDXNOD S BSDXNOD=^BSDXAPPT(BSDXAPPTID,0)
	N BSDXPATID S BSDXPATID=$P(BSDXNOD,U,5) ; DFN
	N BSDXSTART S BSDXSTART=$P(BSDXNOD,U) ; Start Date
	N BSDXRESID S BSDXRESID=$P(BSDXNOD,U,7) ; Resource ID
	; 
	; If the resource doesn't exist, error out. DB is corrupt.
	I 'BSDXRESID D ERR("-3~DB has corruption. Call Tech Support.") QUIT
	I '$D(^BSDXRES(BSDXRESID,0)) D ERR("-4~DB has corruption. Call Tech Support.") QUIT 
	;
	; Get HL Data
	N BSDXNOD S BSDXNOD=^BSDXRES(BSDXRESID,0) ; Resource 0 node
	N BSDXSC1 S BSDXSC1=$P(BSDXNOD,U,4) ;HOSPITAL LOCATION IEN
	I BSDXSC1,'$D(^SC(BSDXSC1,0)) S BSDXSC1="" ; Zero out if HL doesn't exist
	;
	; Is it okay to remove check-in from PIMS?
	N BSDXERR S BSDXERR=0 ; Scratch variable
	; $$RMCICK = Remove Check-in Check
	I BSDXSC1 S BSDXERR=$$RMCICK^BSDXAPI1(BSDXPATID,BSDXSC1,BSDXSTART)
	I BSDXERR D ERR("-5~"_$P(BSDXERR,U,2)) QUIT
	;
	; For possible rollback, get old check-in date (internal value)
	N BSDXCDT S BSDXCDT=$$GET1^DIQ(9002018.4,BSDXAPPTID_",",.03,"I")
	;
	; Remove checkin from BSDX APPOINTMENT entry
	; No need to rollback here on failure.
	N BSDXERR S BSDXERR=$$BSDXCHK(BSDXAPPTID,"@")
	I BSDXERR D ERR("-6~Cannot file data in $$BSDXCHK") QUIT
	;
	; Now, remove checkin from PIMS files 2/44
	; Restore BSDXCDT into ^BSDXAPPT if we fail.
	N BSDXERR S BSDXERR=0 ; Scratch variable to hold error message
	I BSDXSC1 S BSDXERR=$$RMCI^BSDXAPI1(BSDXPATID,BSDXSC1,BSDXSTART)
	I BSDXERR D  QUIT
	. N % S %=$$BSDXCHK(BSDXAPPTID,BSDXCDT) ; No error checking here.
	. D ERR("-5~"_$P(BSDXERR,U,2)) ; Send error message to client
	;
	; Unlock
	L -^BSDXAPPT(BSDXAPPTID)
	;
	; Return ADO recordset
	S BSDXI=BSDXI+1
	S ^BSDXTMP($J,BSDXI)="0"_$C(30)
	S BSDXI=BSDXI+1
	S ^BSDXTMP($J,BSDXI)=$C(31)
	Q
	;
CHKEVT(BSDXPAT,BSDXSTART,BSDXSC)	;EP Called by BSDX CHECKIN APPOINTMENT event
	;when appointments CHECKIN via PIMS interface.
	;Propagates CHECKIN to BSDXAPPT and raises refresh event to running GUI clients
	;
	Q:+$G(BSDXNOEV)
	Q:'+$G(BSDXSC)
	N BSDXSTAT,BSDXFOUND,BSDXRES
	S BSDXSTAT=""
	S:$G(SDATA("AFTER","STATUS"))["CHECKED IN" BSDXSTAT=$P(SDATA("AFTER","STATUS"),"^",4)
	S BSDXFOUND=0
	I $D(^BSDXRES("ALOC",BSDXSC)) S BSDXRES=$O(^BSDXRES("ALOC",BSDXSC,0)) S BSDXFOUND=$$CHKEVT1(BSDXRES,BSDXSTART,BSDXPAT,BSDXSTAT)
	I BSDXFOUND D CHKEVT3(BSDXRES) Q
	I $D(^BXDXRES("ASSOC",BSDXSC)) S BSDXRES=$O(^BSDXRES("ASSOC",BSDXSC,0)) S BSDXFOUND=$$CHKEVT1(BSDXRES,BSDXSTART,BSDXPAT,BSDXSTAT)
	I BSDXFOUND D CHKEVT3(BSDXRES)
	Q
	;
CHKEVT1(BSDXRES,BSDXSTART,BSDXPAT,BSDXSTAT)	;
	;Get appointment id in BSDXAPT
	;If found, call BSDXNOS(BSDXAPPT) and return 1
	;else return 0
	N BSDXFOUND,BSDXAPPT
	S BSDXFOUND=0
	Q:'+$G(BSDXRES) BSDXFOUND
	Q:'$D(^BSDXAPPT("ARSRC",BSDXRES,BSDXSTART)) BSDXFOUND
	S BSDXAPPT=0 F  S BSDXAPPT=$O(^BSDXAPPT("ARSRC",BSDXRES,BSDXSTART,BSDXAPPT)) Q:'+BSDXAPPT  D  Q:BSDXFOUND
	. N BSDXNOD S BSDXNOD=$G(^BSDXAPPT(BSDXAPPT,0)) Q:BSDXNOD=""
	. I $P(BSDXNOD,U,5)=BSDXPAT,$P(BSDXNOD,U,12)="" S BSDXFOUND=1 Q
	I BSDXFOUND,+$G(BSDXAPPT) D
	. N BSDXERR S BSDXERR=$$BSDXCHK(BSDXAPPT,BSDXSTAT)
	. I BSDXERR D ^%ZTER ; VEN/SMH - This is silent. This is a last resort
	Q BSDXFOUND
	;
CHKEVT3(BSDXRES)	;
	;Call RaiseEvent to notify GUI clients
	;
	N BSDXRESN
	S BSDXRESN=$G(^BSDXRES(BSDXRES,0))
	Q:BSDXRESN=""
	S BSDXRESN=$P(BSDXRESN,"^")
	D EVENT^BMXMEVN("BSDX SCHEDULE",BSDXRESN)
	Q
	;
ERROR	;
	S $ETRAP="D ^%ZTER HALT"  ; Emergency Error Trap for the wise
	D ^%ZTER
	; VEN/SMH: NB: I make a conscious decision not to roll back anything
	; here in the error trap. Once the error is fixed, users can 
	; undo or redo the check-in.
	; Individual portions of this routine may choose to do rolling back
	; of their own (e.g. a failed call to BSDXAPI causes rollback to occur
	; in CHECKIN and RMCI)
	;
	; Log error message and send to client
	D ERR("-100~Mumps Error")
	Q:$Q "-100^Mumps Error" Q
	;
ERR(BSDXERR)	;Error processing
	; Unlock first
	L:$D(BSDXAPPTID) -^BSDXAPPT(BSDXAPPTID)
	; If last line is $C(31), we are done. No more errors to send to client.
	I ^BSDXTMP($J,$O(^BSDXTMP($J," "),-1))=$C(31) QUIT
	S BSDXERR=$G(BSDXERR)
	S BSDXERR=$P(BSDXERR,"~")_"~"_$TEXT(+0)_":"_$P(BSDXERR,"~",2) ; Append Routine Name
	S BSDXI=$G(BSDXI)+1
	S ^BSDXTMP($J,BSDXI)=BSDXERR_$C(30)
	S BSDXI=BSDXI+1
	S ^BSDXTMP($J,BSDXI)=$C(31)
	QUIT
