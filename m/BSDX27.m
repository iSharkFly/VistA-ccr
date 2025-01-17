BSDX27	 ; IHS/OIT/HMW - WINDOWS SCHEDULING RPCS ; 4/28/11 10:24am
	   ;;1.7;BSDX;;Jun 01, 2013;Build 24
	   ; Licensed under LGPL
	   ; 
	   ; Change Log: July 15, 2010
	   ; UJO/SMH - i18n: FM Dates passed into routine for Clinic Letters - CLDISP ta
	   ; v 1.42 - 3101208 - SMH
	   ; - Added check to skip cancelled appointments. Check was forgotten
	   ;   in original code.
	   ;   . N BSDXFLAGS S BSDXFLAGS=$P(BSDXNOD,U,2)  ; No show and Cancel Flags
	   ;   . Q:BSDXFLAGS["C"  ; if appt is cancelled, quit
	   ;
	   Q
	   ;
PADISPD(BSDXY,BSDXPAT)	 ;EP
	   ;Entry point for debugging
	   ;
	   ;D DEBUG^%Serenji("PADISP^BSDX27(.BSDXY,BSDXPAT)")
	   Q
	   ;
PADISP(BSDXY,BSDXPAT)	  ;EP
	   ;Return recordset of patient appointments used in listing
	   ;a patient's appointments and generating patient letters.
	   ;Called by rpc BSDX PATIENT APPT DISPLAY
	   ;
	   ; Sam's Notes:
	   ; Relatively complex algorithm.
	   ; 1. First, loop through ^DPT(DA,"S", and get all appointments. 
	   ;   Exclude cancelled appts. Store in BSDXDPT array.
	   ; 2. Go through ^BSDXAPPT("CPAT", (patient index) . 
	   ;   Get the info from there and compar with BSDXDPT array. If 
	   ;   they are the same, get all info, and rm entry from BSDXDPT array.
	   ; 3. If there are any remaining entries in BSDXDPT (PIMS leftovers),
	   ;   Get the data from file 2 and 44.
	   ;
	   N BSDXI,BSDXIEN,BSDXNOD,BSDXNAM,BSDXDOB,BSDXHRN,BSDXSEX,BSDXCNID,BSDXCNOD,BSDXMADE,BSDXCLRK,BSDXNOT,BSDXQ
	   N BSDXSTRT
	   N BSDXSTRE,BSDXCITY,BSDXST,BSDXZIP,BSDXPHON
	   S BSDXY="^BSDXTMP("_$J_")"
	   S BSDXI=0
	   S ^BSDXTMP($J,BSDXI)="T00030Name^D00020DOB^T00030Sex^T00030HRN^D00030ApptDate^T00030Clinic^T00030TypeStatus"
	   S ^BSDXTMP($J,BSDXI)=^(BSDXI)_"^I00010RESOURCEID^T00030APPT_MADE_BY^D00020DATE_APPT_MADE^T00250NOTE^T00030STREET^T00030CITY^T00030STATE^T00030ZIP^T00030HOMEPHONE"_$C(30)
	   S X="ERROR^BSDX27",@^%ZOSF("TRAP")
	   ;Get patient info
	   ;
	   I '+BSDXPAT S ^BSDXTMP($J,1)=$C(31) Q
	   I '$D(^DPT(+BSDXPAT,0)) S ^BSDXTMP($J,1)=$C(31) Q
	   S BSDXNOD=$$PATINFO(BSDXPAT)
	   S BSDXNAM=$P(BSDXNOD,U) ;NAME
	   S BSDXSEX=$P(BSDXNOD,U,2) ;SEX
	   S BSDXDOB=$P(BSDXNOD,U,3) ;DOB
	   S BSDXHRN=$P(BSDXNOD,U,4) ;Health Record Number for location DUZ(2)
	   S BSDXSTRE=$P(BSDXNOD,U,5) ;Street
	   S BSDXCITY=$P(BSDXNOD,U,6) ;City
	   S BSDXST=$P(BSDXNOD,U,7) ;State
	   S BSDXZIP=$P(BSDXNOD,U,8) ;zip
	   S BSDXPHON=$P(BSDXNOD,U,9) ;homephone
	   ;
	   ;Organize ^DPT(BSDXPAT,"S," nodes
	   ; into BSDXDPT(CLINIC,DATE)
	   ;
	   I $D(^DPT(BSDXPAT,"S")) S BSDXDT=0 F  S BSDXDT=$O(^DPT(BSDXPAT,"S",BSDXDT)) Q:'+BSDXDT  D
	   . S BSDXNOD=$G(^DPT(BSDXPAT,"S",BSDXDT,0))
	   . S BSDXCID=$P(BSDXNOD,U)
	   . Q:'+BSDXCID
	   . Q:'$D(^SC(BSDXCID,0))
	   . N BSDXFLAGS S BSDXFLAGS=$P(BSDXNOD,U,2)  ; No show and Cancel Flags
	   . Q:BSDXFLAGS["C"  ; if appt is cancelled, quit
	   . S BSDXDPT(BSDXCID,BSDXDT)=BSDXNOD
	   ;
	   ;$O Through ^BSDX("CPAT",
	   S BSDXIEN=0
	   I $D(^BSDXAPPT("CPAT",BSDXPAT)) F  S BSDXIEN=$O(^BSDXAPPT("CPAT",BSDXPAT,BSDXIEN)) Q:'BSDXIEN  D
	   . N BSDXNOD,BSDXAPT,BSDXCID,BSDXCNOD,BSDXCLN,BSDX44,BSDXDNOD,BSDXSTAT,BSDX,BSDXTYPE,BSDXLIN
	   . S BSDXNOD=$G(^BSDXAPPT(BSDXIEN,0))
	   . Q:BSDXNOD=""
	   . Q:$P(BSDXNOD,U,12)]""  ;CANCELLED
	   . S Y=$P(BSDXNOD,U)
	   . Q:'+Y
	   . X ^DD("DD") S Y=$TR(Y,"@"," ")
	   . S BSDXAPT=Y ;Appointment date time
	   . S BSDXCLRK=$P(BSDXNOD,U,8) ;Appointment made by
	   . S:+BSDXCLRK BSDXCLRK=$G(^VA(200,BSDXCLRK,0)),BSDXCLRK=$P(BSDXCLRK,U)
	   . S Y=$P(BSDXNOD,U,9) ;Date Appointment Made
	   . I +Y X ^DD("DD") S Y=$TR(Y,"@"," ")
	   . S BSDXMADE=Y
	   . ;NOTE
	   . S BSDXNOT=""
	   . I $D(^BSDXAPPT(BSDXIEN,1,0)) S BSDXNOT="",BSDXQ=0 F  S BSDXQ=$O(^BSDXAPPT(BSDXIEN,1,BSDXQ)) Q:'+BSDXQ  D
	   . . S BSDXLIN=$G(^BSDXAPPT(BSDXIEN,1,BSDXQ,0))
	   . . S:(BSDXLIN'="")&($E(BSDXLIN,$L(BSDXLIN)-1,$L(BSDXLIN))'=" ") BSDXLIN=BSDXLIN_" "
	   . . S BSDXNOT=BSDXNOT_BSDXLIN
	   . ;Resource
	   . S BSDXCID=$P(BSDXNOD,U,7) ;IEN of BSDX RESOURCE
	   . Q:'+BSDXCID
	   . Q:'$D(^BSDXRES(BSDXCID,0))
	   . S BSDXCNOD=$G(^BSDXRES(BSDXCID,0)) ;BSDX RESOURCE node
	   . Q:BSDXCNOD=""
	   . S BSDXCLN=$P(BSDXCNOD,U) ;Text name of BSDX Resource
	   . S BSDX44=$P(BSDXCNOD,U,4) ;File 44 pointer
	   . ;If appt entry in ^DPT(PAT,"S" exists for this clinic, get the TYPE/STATUS info from
	   . ;the BSDXDPT array and delete the BSDXDPT node
	   . S BSDXTYPE=""
	   . I +BSDX44,$D(BSDXDPT(BSDX44,$P(BSDXNOD,U))) D  ;BSDXNOD is the BSDX APPOINTMENT node
	   . . S BSDXDNOD=BSDXDPT(BSDX44,$P(BSDXNOD,U)) ;BSDXDNOD is a copy of the ^DPT(PAT,"S" node
	   . . S BSDXTYPE=$$STATUS(BSDXPAT,$P(BSDXNOD,U),BSDXDNOD) ;IHS/OIT/HMW 20050208 Added
	   . . K BSDXDPT(BSDX44,$P(BSDXNOD,U))
	   . S BSDXI=BSDXI+1
	   . S ^BSDXTMP($J,BSDXI)=BSDXNAM_"^"_BSDXDOB_"^"_BSDXSEX_"^"_BSDXHRN_"^"_BSDXAPT_"^"_BSDXCLN_"^"_BSDXTYPE_"^"_BSDXCID_"^"_BSDXCLRK_"^"_BSDXMADE_"^"_BSDXNOT_"^"_BSDXSTRE_"^"_BSDXCITY_"^"_BSDXST_"^"_BSDXZIP_"^"_BSDXPHON_$C(30)
	   . Q
	   ;
	   ;Go through remaining BSDXDPT( entries
	   I $D(BSDXDPT) S BSDX44=0 D
	   . F  S BSDX44=$O(BSDXDPT(BSDX44)) Q:'+BSDX44  S BSDXDT=0 D
	   . . F  S BSDXDT=$O(BSDXDPT(BSDX44,BSDXDT)) Q:'+BSDXDT  D
	   . . . S BSDXDNOD=BSDXDPT(BSDX44,BSDXDT)
	   . . . S Y=BSDXDT
	   . . . Q:'+Y
	   . . . X ^DD("DD") S Y=$TR(Y,"@"," ")
	   . . . S BSDXAPT=Y
	   . . . S BSDXTYPE=$$STATUS(BSDXPAT,BSDXDT,BSDXDNOD) ;IHS/OIT/HMW 20050208 Added
	   . . . S BSDXCLN=$P($G(^SC(BSDX44,0)),U)
	   . . . S BSDXCLRK=$P(BSDXDNOD,U,18)
	   . . . S:+BSDXCLRK BSDXCLRK=$G(^VA(200,BSDXCLRK,0)),BSDXCLRK=$P(BSDXCLRK,U)
	   . . . S Y=$P(BSDXDNOD,U,19)
	   . . . I +Y X ^DD("DD") S Y=$TR(Y,"@"," ")
	   . . . S BSDXMADE=Y
	   . . . S BSDXNOT=""
	   . . . S BSDXI=BSDXI+1
	   . . . S ^BSDXTMP($J,BSDXI)=BSDXNAM_"^"_BSDXDOB_"^"_BSDXSEX_"^"_BSDXHRN_"^"_BSDXAPT_"^"_BSDXCLN_"^"_BSDXTYPE_"^"_"^"_BSDXCLRK_"^"_BSDXMADE_"^"_BSDXNOT_"^"_BSDXSTRE_"^"_BSDXCITY_"^"_BSDXST_"^"_BSDXZIP_"^"_BSDXPHON_$C(30)
	   . . . K BSDXDPT(BSDX44,BSDXDT)
	   ;
	   S BSDXI=BSDXI+1
	   S ^BSDXTMP($J,BSDXI)=$C(31)
	   Q
	   ;
STATUS(PAT,DATE,NODE)	  ; returns appt status
	   ;IHS/OIT/HMW 20050208 Added from BSDDPA
	   NEW TYP
	   S TYP=$$APPTYP^BSDXAPI(PAT,DATE)    ;sched vs. walkin
	   I $P(NODE,U,2)["C" Q TYP_" - CANCELLED"
	   I $P(NODE,U,2)'="NT",$P(NODE,U,2)["N" Q TYP_" - NO SHOW"
	   I $$CO^BSDXAPI(PAT,+NODE,DATE) Q TYP_" - CHECKED OUT"
	   I $$CI^BSDXAPI(PAT,+NODE,DATE) Q TYP_" - CHECKED IN"
	   Q TYP
	   ;
ERROR	  ;
	   D ERR(BSDXI,"RPMS Error")
	   Q
	   ;
ERR(BSDXI,ERRNO,MSG)	   ;Error processing
	   S:'$D(BSDXI) BSDXI=999
	   I +ERRNO S BSDXERR=ERRNO+134234112 ;vbObjectError
	   E  S BSDXERR=ERRNO
	   S BSDXI=BSDXI+1
	   S ^BSDXTMP($J,BSDXI)=MSG_"^^^^^^^^^^^^^^^"_$C(30)
	   S BSDXI=BSDXI+1
	   S ^BSDXTMP($J,BSDXI)=$C(31)
	   Q
PATINFO(BSDXPAT)	   ;EP
	   ;Intrisic Function returns NAME^SEX^DOB^HRN^STREET^CITY^STATE^ZIP^PHONE for patient ien BSDXPAT
	   ;DOB is in external format
	   ;HRN depends on existence of DUZ(2)
	   ;
	   N BSDXNOD,BSDXNAM,BSDXSEX,BSDXDOB,BSDXHRN,BSDXSTRT,BSDXCITY,BSDXST,BSDXZIP,BSDXPHON
	   S BSDXNOD=^DPT(+BSDXPAT,0)
	   S BSDXNAM=$P(BSDXNOD,U) ;NAME
	   S BSDXSEX=$P(BSDXNOD,U,2)
	   S BSDXSEX=$S(BSDXSEX="F":"FEMALE",BSDXSEX="M":"MALE",1:"")
	   S Y=$P(BSDXNOD,U,3) I Y]""  X ^DD("DD") S Y=$TR(Y,"@"," ")
	   S BSDXDOB=Y ;DOB
	   S BSDXHRN=""
	   I $D(DUZ(2)) I DUZ(2)>0 S BSDXHRN=$P($G(^AUPNPAT(BSDXPAT,41,DUZ(2),0)),U,2) ;HRN
	   ;
	   S BSDXNOD=$G(^DPT(+BSDXPAT,.11))
	   S (BSDXSTRT,BSDXCITY,BSDXST,BSDXZIP)=""
	   I BSDXNOD]"" D
	   . S BSDXSTRT=$E($P(BSDXNOD,U),1,50) ;STREET
	   . S BSDXCITY=$P(BSDXNOD,U,4) ;CITY
	   . S BSDXST=$P(BSDXNOD,U,5) ;STATE
	   . I +BSDXST,$D(^DIC(5,+BSDXST,0)) S BSDXST=$P(^DIC(5,+BSDXST,0),U,2)
	   . S BSDXZIP=$P(BSDXNOD,U,6) ;ZIP
	   ;
	   S BSDXNOD=$G(^DPT(+BSDXPAT,.13)) ;PHONE
	   S BSDXPHON=$P(BSDXNOD,U)
	   ;
	   Q BSDXNAM_U_BSDXSEX_U_BSDXDOB_U_BSDXHRN_U_BSDXSTRT_U_BSDXCITY_U_BSDXST_U_BSDXZIP_U_BSDXPHON
	   ;
CLDISPD(BSDXY,BSDXCLST,BSDXBEG,BSDXEND)	;EP
	   ;Entry point for debugging
	   ;
	   ;D DEBUG^%Serenji("CLDISP^BSDX27(.BSDXY,BSDXCLST,BSDXBEG,BSDXEND)")
	   Q
	   ;
CLDISP(BSDXY,BSDXCLST,BSDXBEG,BSDXEND)	 ;EP
	   ;
	   ;Return recordset of patient appointments
	   ;between dates BSDXBEG and BSDXEND for each clinic in BSDXCLST.
	   ;Used in listing a patient's appointments and generating patient letters.
	   ;BSDXCLST is a |-delimited list of BSDX RESOURCE iens.  (The last |-piece is null, so discard it.)
	   ;BSDXBEG and BSDXEND are in external date form.
	   ;Called by BSDX CLINIC LETTERS
	   ;
	      ; July 10, 2010 -- to support i18n, we pass dates from client in
	      ; locale-neutral Fileman format. No need to convert it.
	   N BSDXI,BSDXNOD,BSDXNAM,BSDXDOB,BSDXHRN,BSDXSEX,BSDXCID,BSDXCNOD,BSDXDT
	   N BSDXJ,BSDXAID,BSDXPAT,BSDXPNOD,BSDXCLN,BSDXCLRK,BSDXMADE,BSDXNOT,BSDXLIN
	   N BSDXSTRT
	   N BSDXSTRE,BSDXCITY,BSDXST,BSDXZIP,BSDXPHON
	   S BSDXY="^BSDXTMP("_$J_")"
	   K ^BSDXTMP($J)
	   S BSDXI=0
	   S ^BSDXTMP($J,BSDXI)="T00030Name^D00020DOB^T00030Sex^T00030HRN^D00030ApptDate^T00030Clinic^T00030TypeStatus"
	   S ^BSDXTMP($J,BSDXI)=^(BSDXI)_"^I00010RESOURCEID^T00030APPT_MADE_BY^D00020DATE_APPT_MADE^T00250NOTE^T00030STREET^T00030CITY^T00030STATE^T00030ZIP^T00030HOMEPHONE"_$C(30)
	   S X="ERROR^BSDX27",@^%ZOSF("TRAP")
	   ;
	   ;Convert beginning and ending dates
	   ;
	   S BSDXBEG=BSDXBEG-1,BSDXBEG=BSDXBEG_".9999"
	   S BSDXEND=BSDXEND_".9999"
	   I BSDXCLST="" D ERR(BSDXI,0,"Routine: BSDX27, Error: Null clinic list") Q
	   ;
	   ;For each clinic in BSDXCLST $O through ^BSDXAPPT("ARSRC",ResourceIEN,FMDate,ApptIEN)
	   ;
	   F BSDXJ=1:1:$L(BSDXCLST,"|")-1 S BSDXCID=$P(BSDXCLST,"|",BSDXJ) D
	   . S BSDXCLN=$G(^BSDXRES(BSDXCID,0)) S BSDXCLN=$P(BSDXCLN,U) Q:BSDXCLN=""
	   . S BSDXSTRT=BSDXBEG F  S BSDXSTRT=$O(^BSDXAPPT("ARSRC",BSDXCID,BSDXSTRT)) Q:'+BSDXSTRT  Q:BSDXSTRT>BSDXEND  D
	   . . S BSDXAID=0 F  S BSDXAID=$O(^BSDXAPPT("ARSRC",BSDXCID,BSDXSTRT,BSDXAID)) Q:'+BSDXAID  D
	   . . . S BSDXNOD=$G(^BSDXAPPT(BSDXAID,0))
	   . . . Q:BSDXNOD=""
	   . . . Q:$P(BSDXNOD,U,12)]""  ;CANCELLED
	   . . . Q:$P(BSDXNOD,U,13)="y"  ;WALKIN
	   . . . S Y=$P(BSDXNOD,U)
	   . . . Q:'+Y
	   . . . X ^DD("DD") S Y=$TR(Y,"@"," ")
	   . . . S BSDXAPT=Y ;Appointment date time
	   . . . ;
	   . . . ;NOTE
	   . . . S BSDXNOT=""
	   . . . I $D(^BSDXAPPT(BSDXAID,1,0)) S BSDXQ=0 F  S BSDXQ=$O(^BSDXAPPT(BSDXAID,1,BSDXQ)) Q:'+BSDXQ  D
	   . . . . S BSDXLIN=$G(^BSDXAPPT(BSDXAID,1,BSDXQ,0))
	   . . . . S:(BSDXLIN'="")&($E(BSDXLIN,$L(BSDXLIN)-1,$L(BSDXLIN))'=" ") BSDXLIN=BSDXLIN_" "
	   . . . . S BSDXNOT=BSDXNOT_BSDXLIN
	   . . . ;
	   . . . S BSDXPAT=$P(BSDXNOD,U,5)
	   . . . S BSDXPNOD=$$PATINFO(BSDXPAT)
	   . . . S BSDXNAM=$P(BSDXPNOD,U) ;NAME
	   . . . S BSDXSEX=$P(BSDXPNOD,U,2) ;SEX
	   . . . S BSDXDOB=$P(BSDXPNOD,U,3) ;DOB
	   . . . S BSDXHRN=$P(BSDXPNOD,U,4) ;Health Record Number for location DUZ(2)
	   . . . S BSDXSTRE=$P(BSDXPNOD,U,5) ;Street
	   . . . S BSDXCITY=$P(BSDXPNOD,U,6) ;City
	   . . . S BSDXST=$P(BSDXPNOD,U,7) ;State
	   . . . S BSDXZIP=$P(BSDXPNOD,U,8) ;zip
	   . . . S BSDXPHON=$P(BSDXPNOD,U,9) ;homephone
	   . . . S BSDXTYPE="" ;Type/status doesn't exist for BSDX APPT clinics and it's not needed for clinic letters
	   . . . S BSDXCLRK=$P(BSDXNOD,U,8)
	   . . . S:+BSDXCLRK BSDXCLRK=$G(^VA(200,BSDXCLRK,0)),BSDXCLRK=$P(BSDXCLRK,U)
	   . . . S Y=$P(BSDXNOD,U,9)
	   . . . I +Y X ^DD("DD") S Y=$TR(Y,"@"," ")
	   . . . S BSDXMADE=Y
	   . . . S BSDXI=BSDXI+1
	   . . . S ^BSDXTMP($J,BSDXI)=BSDXNAM_"^"_BSDXDOB_"^"_BSDXSEX_"^"_BSDXHRN_"^"_BSDXAPT_"^"_BSDXCLN_"^"_BSDXTYPE_"^"_BSDXCID_"^"_BSDXCLRK_"^"_BSDXMADE_"^"_BSDXNOT_"^"_BSDXSTRE_"^"_BSDXCITY_"^"_BSDXST_"^"_BSDXZIP_"^"_BSDXPHON_$C(30)
	   ;
	   S BSDXI=BSDXI+1
	   S ^BSDXTMP($J,BSDXI)=$C(31)
	   Q
