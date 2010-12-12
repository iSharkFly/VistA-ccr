BSDX04	; IHS/OIT/HMW - WINDOWS SCHEDULING RPCS ;  ; 7/15/10 12:44pm
	;;1.42;BSDX;;Dec 07, 2010
	   ; Change Log:
	   ; July 11 2010: Pass BSDXSTART and END as FM dates rather than US formatted dates
	   ;       for i18n
	;
	;
CASSCHD(BSDXY,BSDXRES,BSDXSTART,BSDXEND,BSDXTYPES,BSDXSRCH)	;EP
	;
	;D DEBUG^%Serenji("CASSCH^BSDX04(.BSDXY,BSDXRES,BSDXSTART,BSDXEND,BSDXTYPES,BSDXSRCH)")
	;
	Q
	;
CASSET	;EP
	;Error Trap
	D ^%ZTER
	I '$D(BSDXI) N BSDXI S BSDXI=99999
	S BSDXI=BSDXI+1
	S ^BSDXTMP($J,BSDXI)=$C(31)
	Q
	;
CASSCH(BSDXY,BSDXRES,BSDXSTART,BSDXEND,BSDXTYPES,BSDXSRCH)	;EP
	;Called by BSDX CREATE ASGND SLOT SCHED
	;Create Assigned Slot Schedule recordset
	;This call is used both to create a schedule of availability for the calendar display
	;and to search for availability in the Find Appointment function
	;
	;BSDXRES is resource name
	   ;
	   ;//smh
	   ; BSDXSTART and BSDXEND both passed in FM Format.
	   ; BSDXSTART is the Date Portion of FM Date
	   ; BSDXEND -- pass date and h,m,s as well
	   ;//smh
	;
	;BSDXTYPES is |-delimited list of Access Type Names
	;If BSDXTYPES is "" then the screen passes all types.
	;
	;BSDXSRCH is |-delimited search info for the Find Appointment function
	;First piece is 1 if we are in a Find Appointment call
	;Second piece is weekday info in the format MTWHFSU
	;Third piece is AM PM info in the form AP
	;If 2nd or 3rd pieces are null, the screen for that piece is skipped
	;
	;Test lines:
	;D CASSCH^BSDX04(.RES,"REMILLARD,MIKE","<fmdate>","<fmdate>") ZW RES
	;BSDX CREATE ASGND SLOT SCHED^ROGERS,BUCK^<fmdate>^<fmdate>^2
	;S ^HW("BSDX04")=BSDXRES_U_BSDXSTART_U_BSDXEND
	;
	N BSDXERR,BSDXIEN,BSDXDEP,BSDXTYPED,BSDXTYPE,BSDXALO,BSDXBS,BSDXI,BSDXNEND,BSDXNSTART,BSDXPEND,BSDXRESD,BSDXRESN,BSDXS,BSDXZ,BSDXTMP,BSDXQ,BSDXNOT,BSDXNOD,BSDXAD
	N BSDXSUBCD
	S X="CASSET^BSDX04",@^%ZOSF("TRAP")
	K ^BSDXTMP($J)
	S BSDXERR=""
	S BSDXY="^BSDXTMP("_$J_")"
	S ^BSDXTMP($J,0)="D00030START_TIME^D00030END_TIME^I00010SLOTS^T00030RESOURCE^T00010ACCESS_TYPE^T00250NOTE^I00030AVAILABILITYID"_$C(30)
	S BSDXALO=0,BSDXI=2
	;
	;Get Access Type IDs
	N BSDXK,BSDXTYPED,BSDXL
	I '+BSDXSRCH S BSDXTYPED=""
	I +BSDXSRCH F BSDXK=1:1:$L(BSDXTYPES,"|") D
	. S BSDXL=$P(BSDXTYPES,"|",BSDXK)
	. I BSDXL="" S $P(BSDXTYPED,"|",BSDXK)=0 Q
	. I '$D(^BSDXTYPE("B",BSDXL)) S $P(BSDXTYPED,"|",BSDXK)=0 Q
	. S $P(BSDXTYPED,"|",BSDXK)=$O(^BSDXTYPE("B",BSDXL,0))
	;
	D
	. S BSDXBS=0
	. S BSDXRESN=BSDXRES
	. Q:BSDXRESN=""
	. Q:'$D(^BSDXRES("B",BSDXRESN))
	. S BSDXRESD=$O(^BSDXRES("B",BSDXRESN,0)) Q:'+BSDXRESD
	. Q:'$D(^BSDXAB("ARSCT",BSDXRESD))
	. D STRES(BSDXRESN,BSDXRESD)
	. Q
	;
	;start, end, slots, resource, accesstype, note, availabilityid
	;I '+BSDXSRCH,BSDXALO D
	I BSDXALO D
	. ;If first block start time > input start time then pad with new block
	. I BSDXBS>BSDXSTART K BSDXTMP D
	. . S Y=BSDXSTART X ^DD("DD") S Y=$TR(Y,"@"," ")
	. . S BSDXTMP=Y
	. . S Y=BSDXBS X ^DD("DD") S Y=$TR(Y,"@"," ")
	. . S BSDXTMP=BSDXTMP_"^"_Y_"^0^"_BSDXRESN_"^0^^0"_$C(30)
	. . S ^BSDXTMP($J,1)=BSDXTMP
	. ;
	. ;If first block start time < input start time then trim
	. I BSDXBS<BSDXSTART D
	. . S Y=BSDXSTART
	. . X ^DD("DD") S Y=$TR(Y,"@"," ")
	. . S $P(^BSDXTMP($J,2),U,1)=Y
	. ;
	. ;If last block end time < input end time then pad end with new block
	. I BSDXPEND<BSDXEND D
	. . S Y=BSDXPEND X ^DD("DD") S Y=$TR(Y,"@"," ")
	. . S BSDXTMP=Y
	. . S Y=BSDXEND X ^DD("DD") S Y=$TR(Y,"@"," ")
	. . S BSDXTMP=BSDXTMP_"^"_Y_"^0^"_BSDXRESN_"^0^^0"_$C(30)
	. . S ^BSDXTMP($J,BSDXI-1)=BSDXTMP
	. ;
	S ^BSDXTMP($J,BSDXI)=$C(31)
	Q
	;
STRES(BSDXRESN,BSDXRESD)	;
	;BSDXRESD is a Resource ID
	;$O THRU "ARSCT" XREF OF ^BSDXAB
	S BSDXS=$P(BSDXSTART,"."),BSDXS=BSDXS-.0001
	S BSDXNEND=0,BSDXNSTART=0,BSDXPEND=0
	F  S BSDXS=$O(^BSDXAB("ARSCT",BSDXRESD,BSDXS)) Q:'+BSDXS  Q:BSDXS>BSDXEND  D
	. S BSDXAD=0 F  S BSDXAD=$O(^BSDXAB("ARSCT",BSDXRESD,BSDXS,BSDXAD)) Q:'+BSDXAD  D STCOMM(BSDXRESN,BSDXRESD,BSDXS,BSDXAD) ;BSDXAD Is the AvailabilityID
	. Q
	Q
	;
STCOMM(BSDXRESN,BSDXRESD,BSDXS,BSDXAD)	;
	N BSDXNSTART,BSDXNEND,BSDXNOD,Y,BSDXQ,BSDXZ,BSDXATID,BSDXATOK
	Q:'$D(^BSDXAB(BSDXAD,0))
	S BSDXNOD=^BSDXAB(BSDXAD,0)
	S BSDXATID=$P(BSDXNOD,U,5)
	;
	;Screen for Access Type
	;S BSDXATOK=0
	;I BSDXTYPED="" S BSDXATOK=1
	;E  D
	;. F J=1:1:$L(BSDXTYPED,"|") I BSDXATID=$P(BSDXTYPED,"|",J) S BSDXATOK=1 Q
	;Q:'BSDXATOK
	;
	;I +BSDXSRCH
	;Screen for Weekday
	;
	;Screen for AM PM
	;
	S BSDXZ=""
	S BSDXNSTART=$P(BSDXNOD,U,2)
	S BSDXNEND=$P(BSDXNOD,U,3)
	I BSDXNEND'>BSDXSTART Q  ;End is less than start
	I +BSDXBS=0 S BSDXBS=$P(BSDXNOD,U,2) ;First block start time
	F BSDXQ=2:1:3 D  ;Start and End times
	. S Y=$P(BSDXNOD,U,BSDXQ)
	. X ^DD("DD") S Y=$TR(Y,"@"," ")
	. S BSDXZ=BSDXZ_Y_"^"
	S BSDXZ=BSDXZ_$P(BSDXNOD,U,4)_"^" ;SLOTS
	S BSDXZ=BSDXZ_BSDXRESN_"^" ;Resource name
	S BSDXZ=BSDXZ_BSDXATID_"^" ;Access type ID
	S BSDXNOT="",BSDXQ=0 F  S BSDXQ=$O(^BSDXAB(BSDXAD,1,BSDXQ)) Q:'+BSDXQ  D
	. S BSDXNOT=BSDXNOT_$G(^BSDXAB(BSDXAD,1,BSDXQ,0))_" "
	S BSDXZ=BSDXZ_BSDXNOT ;_"^"
	;I '+BSDXSRCH,BSDXPEND,BSDXNSTART>BSDXPEND D  ;Fill in gap between appointment
	I BSDXPEND,BSDXNSTART>BSDXPEND D  ;Fill in gap between appointment
	. S Y=BSDXPEND X ^DD("DD") S Y=$TR(Y,"@"," ")
	. S BSDXTMP=Y
	. S Y=BSDXNSTART X ^DD("DD") S Y=$TR(Y,"@"," ")
	. S BSDXTMP=BSDXTMP_"^"_Y_"^0^"_BSDXRESN_"^0^^0"_$C(30)
	. S ^BSDXTMP($J,BSDXI-1)=BSDXTMP
	S BSDXPEND=BSDXNEND
	S ^BSDXTMP($J,BSDXI)=BSDXZ_"^"_BSDXAD_$C(30)
	S BSDXI=BSDXI+2
	S BSDXALO=1 ;At Least One record will be returned
	Q
