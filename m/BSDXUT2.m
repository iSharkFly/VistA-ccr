BSDXUT2	; VEN/SMH - Unit Tests for Scheduling GUI - cont. ; 7/9/12 3:18pm
	;;1.7;BSDX;;Jun 01, 2013;Build 24
	;
EN	; Run all unit tests in this routine
	D UT25,PIMS
	QUIT
	;
UT25	; Unit Tests for BSDX25
	; Make appointment, checkin, then uncheckin
	N $ET S $ET="W ""An Error Occured. Breaking."",! BREAK"
	N RESNAM S RESNAM="UTCLINIC"
	N HLRESIENS ; holds output of UTCR^BSDXUT - HL IEN^Resource IEN
	D
	. N $ET S $ET="D ^%ZTER B"
	. S HLRESIENS=$$UTCR^BSDXUT(RESNAM)
	. I HLRESIENS<0 S $EC=",U1," ; not supposed to happen - hard crash if so
	;
	N HLIEN,RESIEN
	S HLIEN=$P(HLRESIENS,U)
	S RESIEN=$P(HLRESIENS,U,2)
	;
	; Get start and end times
	N TIMES S TIMES=$$TIMES^BSDXUT ; appt time^end time
	N APPTTIME S APPTTIME=$P(TIMES,U)
	N ENDTIME S ENDTIME=$P(TIMES,U,2)
	;
	; Test 1: Make normal appointment and cancel it. See if every thing works
	N ZZZ,DFN
	S DFN=5
	N ZZZ
	D APPADD^BSDX07(.ZZZ,APPTTIME,ENDTIME,DFN,RESNAM,30,"Sam's Note",1)
	N APPTID S APPTID=+^BSDXTMP($J,1)
	N HL S HL=$$GET1^DIQ(9002018.4,APPTID,".07:.04","I")
	D CHECKIN^BSDX25(.ZZZ,APPTID,$$NOW^XLFDT())
	IF '$P(^BSDXAPPT(APPTID,0),U,3) WRITE "ERROR IN CHECKIN 1",!
	IF '+$G(^SC(HL,"S",APPTTIME,1,1,"C")) WRITE "ERROR IN CHECKIN 2",!
	D RMCI^BSDX25(.ZZZ,APPTID)
	IF $P(^BSDXAPPT(APPTID,0),U,3) WRITE "ERROR IN UNCHECKIN 1",!
	IF $G(^SC(HL,"S",APPTTIME,1,1,"C")) WRITE "ERROR IN UNCHECKIN 2",!
	D RMCI^BSDX25(.ZZZ,APPTID)  ; again, test sanity in repeat
	IF $P(^BSDXAPPT(APPTID,0),U,3) WRITE "ERROR IN UNCHECKIN 1",!
	IF $G(^SC(HL,"S",APPTTIME,1,1,"C")) WRITE "ERROR IN UNCHECKIN 2",!
	; now test various error conditions
	; Test Error 1
	D RMCI^BSDX25(.ZZZ,)
	IF +^BSDXTMP($J,1)'=-1 WRITE "ERROR IN ETest 1",!
	; Test Error 2
	D RMCI^BSDX25(.ZZZ,234987234398)
	IF +^BSDXTMP($J,1)'=-2 WRITE "ERROR IN Etest 2",!
	; Tests for 3 to 5 difficult to produce
	; Error tests follow: Mumps error test;
	; Error in RMCI
	N BSDXDIE S BSDXDIE=1
	D RMCI^BSDX25(.ZZZ,APPTID)
	IF +^BSDXTMP($J,1)'=-100 WRITE "ERROR IN Etest 3",!
	K BSDXDIE
	; M Error in CHECKIN
	N BSDXDIE S BSDXDIE=1
	D CHECKIN^BSDX25(.ZZZ,APPTID,$$NOW^XLFDT())
	IF +^BSDXTMP($J,1)'=-100 WRITE "ERROR IN Etest 8",!
	K BSDXDIE
	; M Error in $$CHECKIN^BSDXAPI
	N BSDXDIE2 S BSDXDIE2=1
	D CHECKIN^BSDX25(.ZZZ,APPTID,$$NOW^XLFDT())
	IF +^BSDXTMP($J,1)'=-100 WRITE "ERROR IN Etest 9",!
	K BSDXDIE2
	; M Error in $$RMCI^BSDXAPI1
	N BSDXDIE2 S BSDXDIE2=1
	D RMCI^BSDX25(.ZZZ,APPTID)
	IF +^BSDXTMP($J,1)'=-100 WRITE "ERROR IN Etest 13",!
	K BSDXDIE2
	;
	; Get start and end times
	N TIMES S TIMES=$$TIMES^BSDXUT ; appt time^end time
	N APPTTIME S APPTTIME=$P(TIMES,U)
	N ENDTIME S ENDTIME=$P(TIMES,U,2)
	;
	N ZZZ,DFN
	S DFN=5
	N ZZZ
	D APPADD^BSDX07(.ZZZ,APPTTIME,ENDTIME,DFN,RESNAM,30,"Sam's Note",1)
	N APPTID S APPTID=+^BSDXTMP($J,1)
	N HL S HL=$$GET1^DIQ(9002018.4,APPTID,".07:.04","I")
	;
	; Simulated Error in $$BSDXCHK^BSDX25
	N BSDXSIMERR1 S BSDXSIMERR1=1
	D CHECKIN^BSDX25(.ZZZ,APPTID,$$NOW^XLFDT())
	IF +^BSDXTMP($J,1)'=-3 WRITE "ERROR in Etest 10",!
	IF $P(^BSDXAPPT(APPTID,0),U,3) WRITE "ERROR IN CHECKIN 111",!
	IF +$G(^SC(HL,"S",APPTTIME,1,1,"C")) WRITE "ERROR IN CHECKIN 112",!
	K BSDXSIMERR1
	;
	; Simulated Error in $$CHECKICK^BSDXAPI
	N BSDXSIMERR2 S BSDXSIMERR2=1
	D CHECKIN^BSDX25(.ZZZ,APPTID,$$NOW^XLFDT())
	IF +^BSDXTMP($J,1)'=-10 WRITE "ERROR in Etest 11",!
	IF $P(^BSDXAPPT(APPTID,0),U,3) WRITE "ERROR IN CHECKIN 113",!
	IF +$G(^SC(HL,"S",APPTTIME,1,1,"C")) WRITE "ERROR IN CHECKIN 114",!
	K BSDXSIMERR2
	;
	; Simulated Error in $$CHECKIN^BSDXAPI
	N BSDXSIMERR3 S BSDXSIMERR3=1
	D CHECKIN^BSDX25(.ZZZ,APPTID,$$NOW^XLFDT())
	IF +^BSDXTMP($J,1)'=-10 WRITE "ERROR in Etest 11",!
	IF $P(^BSDXAPPT(APPTID,0),U,3) WRITE "ERROR IN CHECKIN 115",!
	IF +$G(^SC(HL,"S",APPTTIME,1,1,"C")) WRITE "ERROR IN CHECKIN 116",!
	K BSDXSIMERR3
	;
	; Check-in for real for the subsequent tests
	D CHECKIN^BSDX25(.ZZZ,APPTID,$$NOW^XLFDT()) ; Check-in first!
	IF '$P(^BSDXAPPT(APPTID,0),U,3) WRITE "ERROR IN CHECKIN 1110",!
	IF '+$G(^SC(HL,"S",APPTTIME,1,1,"C")) WRITE "ERROR IN RMCI 1120",!
	;
	; Simulated Error in $$BSDXCHK^BSDX25; This time for remove check-in
	N BSDXSIMERR1 S BSDXSIMERR1=1
	D RMCI^BSDX25(.ZZZ,APPTID)
	IF +^BSDXTMP($J,1)'=-6 WRITE "ERROR in Etest 14",!
	IF '$P(^BSDXAPPT(APPTID,0),U,3) WRITE "ERROR IN RMCI 111",!
	IF '+$G(^SC(HL,"S",APPTTIME,1,1,"C")) WRITE "ERROR IN RMCI 112",!
	K BSDXSIMERR1
	;
	; Simulated Error in $$RMCICK^BSDXAPI1
	N BSDXSIMERR2 S BSDXSIMERR2=1
	D RMCI^BSDX25(.ZZZ,APPTID)
	IF +^BSDXTMP($J,1)'=-5 WRITE "ERROR in Etest 15",!
	IF '$P(^BSDXAPPT(APPTID,0),U,3) WRITE "ERROR IN RMCI 113",!
	IF '+$G(^SC(HL,"S",APPTTIME,1,1,"C")) WRITE "ERROR IN RMCI 114",!
	K BSDXSIMERR2
	;
	; Simulated Error in $$RMCI^BSDXAPI1
	N BSDXSIMERR3 S BSDXSIMERR3=1
	D RMCI^BSDX25(.ZZZ,APPTID)
	IF +^BSDXTMP($J,1)'=-5 WRITE "ERROR in Etest 16",!
	IF '$P(^BSDXAPPT(APPTID,0),U,3) WRITE "ERROR IN RMCI 115",!
	IF '+$G(^SC(HL,"S",APPTTIME,1,1,"C")) WRITE "ERROR IN RMCI 116",!
	K BSDXSIMERR3
	;
	; Unlinked Clinic Tests
	N RESNAM S RESNAM="UTCLINICUL" ; Unlinked Clinic
	N RESIEN
	D
	. N $ET S $ET="D ^%ZTER B"
	. S RESIEN=$$UTCRRES^BSDXUT(RESNAM)
	. I RESIEN<0 S $EC=",U1," ; not supposed to happen - hard crash if so
	;
	; Get start and end times
	N TIMES S TIMES=$$TIMES^BSDXUT ; appt time^end time
	N APPTTIME S APPTTIME=$P(TIMES,U)
	N ENDTIME S ENDTIME=$P(TIMES,U,2)
	;
	N ZZZ,DFN
	S DFN=4
	N ZZZ
	D APPADD^BSDX07(.ZZZ,APPTTIME,ENDTIME,DFN,RESNAM,30,"Sam's Note",1)
	N APPTID S APPTID=+^BSDXTMP($J,1)
	N HL S HL=$$GET1^DIQ(9002018.4,APPTID,".07:.04","I")
	I HL'="" W "Error. Hospital Location Exists",!
	;
	D CHECKIN^BSDX25(.ZZZ,APPTID,$$NOW^XLFDT())
	IF '$P(^BSDXAPPT(APPTID,0),U,3) WRITE "ERROR IN CHECKIN 3",!
	;test
	D RMCI^BSDX25(.ZZZ,APPTID)
	IF $P(^BSDXAPPT(APPTID,0),U,3) WRITE "ERROR IN UNCHECKIN 3",!
	D RMCI^BSDX25(.ZZZ,APPTID)  ; again, test sanity in repeat
	IF $P(^BSDXAPPT(APPTID,0),U,3) WRITE "ERROR IN UNCHECKIN 3",!
	; now test various error conditions
	; Test Error 1
	D RMCI^BSDX25(.ZZZ,)
	IF +^BSDXTMP($J,1)'=-1 WRITE "ERROR IN ETest 5",!
	; Test Error 2
	D RMCI^BSDX25(.ZZZ,234987234398)
	IF +^BSDXTMP($J,1)'=-2 WRITE "ERROR IN Etest 6",!
	; Tests for 3 to 5 difficult to produce
	; Error tests follow: Mumps error test; Transaction restartability
	N BSDXDIE S BSDXDIE=1
	D RMCI^BSDX25(.ZZZ,APPTID)
	IF +^BSDXTMP($J,1)'=-100 WRITE "ERROR IN Etest 7",!
	K BSDXDIE
	QUIT
	;
PIMS	; Tests for running PIMS by itself.
	N $ET S $ET="W ""An Error Occured. Breaking."",! BREAK"
	N RESNAM S RESNAM="UTCLINIC"
	N HLRESIENS ; holds output of UTCR^BSDXUT - HL IEN^Resource IEN
	D
	. N $ET S $ET="D ^%ZTER B"
	. S HLRESIENS=$$UTCR^BSDXUT(RESNAM)
	. I HLRESIENS<0 S $EC=",U1," ; not supposed to happen - hard crash if so
	;
	N HLIEN,RESIEN
	S HLIEN=$P(HLRESIENS,U)
	S RESIEN=$P(HLRESIENS,U,2)
	;
	;
	N APPTTIME S APPTTIME=$$TIMEHL^BSDXUT(HLIEN) ; appt time
	N DFN S DFN=2
	;
	; TEST $$MAKE1^BSDXAPI
	N % S %=$$MAKE1^BSDXAPI(DFN,HLIEN,3,APPTTIME,15,"Sam Test Appt"_DFN)
	I % W "Error in $$MAKE1^BSDXAPI for TIME "_APPTTIME_" for DFN "_DFN,!,%,!
	I '$D(^BSDXAPPT("APAT",DFN,APPTTIME)) W "No BSDX Appointment Created",!
	N RESID S RESID=$O(^(APPTTIME,""))
	N APPTID S APPTID=$O(^(RESID,""))
	I 'APPTID W "Can't get appointment",!
	IF $P(^BSDXAPPT(APPTID,0),U,3) WRITE "ERROR IN CHECKIN 3",!
	;
	; TEST CHECKIN1 AND RMCI ^BSDXAPI[1]
	N % S %=$$CHECKIN1^BSDXAPI(DFN,HLIEN,APPTTIME) ; Checkin via PIMS
	I % W "Error in Checking in via BSDXAPI",!
	IF '+$G(^SC(HLIEN,"S",APPTTIME,1,1,"C")) WRITE "ERROR IN CHECKIN 10",!
	IF '$P(^BSDXAPPT(APPTID,0),U,3) WRITE "ERROR IN CHECKIN 11",!
	N % S %=$$RMCI^BSDXAPI1(DFN,HLIEN,APPTTIME)
	I % W "Error removing Check-in via PIMS",!
	I +$G(^SC(HLIEN,"S",APPTTIME,1,1,"C")) WRITE "ERROR IN UNCHECKIN 12",!
	IF $P(^BSDXAPPT(APPTID,0),U,3) WRITE "ERROR IN CHECKIN 13",!
	N % S %=$$CHECKIN1^BSDXAPI(DFN,HLIEN,APPTTIME) ; Checkin via PIMS again
	I % W "Error in Checking in via BSDXAPI",!
	IF '+$G(^SC(HLIEN,"S",APPTTIME,1,1,"C")) WRITE "ERROR IN CHECKIN 14",!
	IF '$P(^BSDXAPPT(APPTID,0),U,3) WRITE "ERROR IN CHECKIN 15",!
	;
	; TEST CANCEL1^BSDXAPI
	N APPTTIME S APPTTIME=$$TIMEHL^BSDXUT(HLIEN) ; appt time
	N DFN S DFN=2
	N % S %=$$MAKE1^BSDXAPI(DFN,HLIEN,3,APPTTIME,15,"Sam Test Appt"_DFN)
	I % W "Error in $$MAKE1^BSDXAPI for TIME "_APPTTIME_" for DFN "_DFN,!,%,!
	I '$D(^BSDXAPPT("APAT",DFN,APPTTIME)) W "No BSDX Appointment Created",!
	N RESID S RESID=$O(^(APPTTIME,""))
	N APPTID S APPTID=$O(^(RESID,""))
	I 'APPTID W "Can't get appointment",!
	N % S %=$$CANCEL1^BSDXAPI(DFN,HLIEN,"PC",APPTTIME,1,"Afraid of Baby Foxes")
	I % W "Error cancelling via $$CANCEL1^BSDXAPI",!
	I ^BSDXAPPT(APPTID,0) ; Change $R
	I '$P(^(0),U,12) W "No cancel date found in BSDXAPPT",!
	; Make same appointment again!
	; NB: Index APAT will have two identical entries, one for the cancelled
	; appointment, and one for the new one. I won't check it for that reason.
	N % S %=$$MAKE1^BSDXAPI(DFN,HLIEN,3,APPTTIME,15,"Sam Test Appt"_DFN)
	I % W "Error in $$MAKE1^BSDXAPI for TIME "_APPTTIME_" for DFN "_DFN,!,%,!
	;
	; TEST NOSHOW^BSDXAPI1
	N APPTTIME S APPTTIME=$$TIMEHL^BSDXUT(HLIEN) ; appt time
	N DFN S DFN=3
	N % S %=$$MAKE1^BSDXAPI(DFN,HLIEN,3,APPTTIME,15,"Sam Test Appt"_DFN)
	I % W "Error in $$MAKE1^BSDXAPI for TIME "_APPTTIME_" for DFN "_DFN,!,%,!
	I '$D(^BSDXAPPT("APAT",DFN,APPTTIME)) W "No BSDX Appointment Created",!
	N RESID S RESID=$O(^(APPTTIME,""))
	N APPTID S APPTID=$O(^(RESID,""))
	I 'APPTID W "Can't get appointment",!
	; No show via PIMS
	N % S %=$$NOSHOW^BSDXAPI1(DFN,HLIEN,APPTTIME,1)
	I % W "Error no-showing via $$NOSHOW^BSDXAPI1",!
	I ^BSDXAPPT(APPTID,0) ; Change $R
	I '$P(^(0),U,10) W "No-show not present in ^BSDXAPPT",!
	; un-noshow via PIMS
	N % S %=$$NOSHOW^BSDXAPI1(DFN,HLIEN,APPTTIME,0)
	I % W "Error no-showing via $$NOSHOW^BSDXAPI1",!
	I ^BSDXAPPT(APPTID,0) ; Change $R
	I $P(^(0),U,10) W "No-show present in ^BSDXAPPT when it shouldn't",!
	;
	; NB: UPDATENT^BSDXAPI is updates the note. Right now, we don't have any
	; way to update the note from BSDXAPI back to ^BSDXAPPT as the protocol
	; file is currently not involved. Right now I can't even find the code 
	; that lets you change an appointment note in PIMS.
	;
	QUIT
