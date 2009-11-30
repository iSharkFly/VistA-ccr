BSDX06	; IHS/OIT/HMW - WINDOWS SCHEDULING RPCS ;
	;;2.0;IHS WINDOWS SCHEDULING;;NOV 01, 2007
	;
	;
TPBLKOV(BSDXY,BSDXSTART,BSDXEND,BSDXRES)	 ;EP
	;Called by BSDXD TYPE BLOCKS OVERLAP
	;(Duplicates old qryTypeBlocksOverlapB)
	;BSDXRES is resource name
	;
	;Test lines:
	;D TPBLKOV^BSDX06(.RES,"5-12-2003","5-16-2003","REMILLARD,MIKE") ZW RES
	;BSDX TYPE BLOCKS OVERLAP^1-1-2000^12-14-2004^REMILLARD,MIKE
	;S ^HW("BSDXD06")=BSDXSTART_U_BSDXEND_U_BSDXRES
	;
	N BSDXERR,BSDXIEN,BSDXDEP,BSDXBS,BSDXI,BSDXNEND,BSDXNSTART,BSDXPEND,BSDXRESD,BSDXRESN,BSDXS,BSDXTPID,BSDXNOD,BSDXAD
	K ^BSDXTMP($J)
	S BSDXERR=""
	S BSDXY="^BSDXTMP("_$J_")"
	S ^BSDXTMP($J,0)="D00030StartTime^D00030EndTime^I00010AppointmentTypeID^I00010AvailabilityID^T00030ResourceName"_$C(30)
	S BSDXI=0
	D
	. S BSDXBS=0
	. S:BSDXSTART["@0000" BSDXSTART=$P(BSDXSTART,"@")
	. S:BSDXEND["@0000" BSDXEND=$P(BSDXEND,"@")
	. S %DT="T",X=BSDXSTART D ^%DT S BSDXSTART=Y
	. I BSDXSTART=-1 S ^BSDXTMP($J,1)=$C(31) Q
	. S %DT="T",X=BSDXEND D ^%DT S BSDXEND=Y
	. I BSDXEND=-1 S ^BSDXTMP($J,1)=$C(31) Q
	. I $L(BSDXEND,".")=1 S BSDXEND=BSDXEND+.9999 ;Go to end of day
	. S BSDXRESN=BSDXRES
	. Q:BSDXRESN=""
	. Q:'$D(^BSDXRES("B",BSDXRESN))
	. S BSDXRESD=$O(^BSDXRES("B",BSDXRESN,0))
	. Q:'+BSDXRESD
	. D STCOMM(BSDXRESN,BSDXRESD)
	. Q
	;
	S BSDXI=$G(BSDXI)+1
	S ^BSDXTMP($J,BSDXI)=$C(31)
	Q
	;
STCOMM(BSDXRESN,BSDXRESD)	;EP
	;
	Q:'$D(^BSDXAB("ARSCT",BSDXRESD))
	Q:'$D(^BSDXRES(BSDXRESD,0))
	;$O THRU "ARSCT" XREF OF ^BSDXAB
	S BSDXNEND=0,BSDXNSTART=0,BSDXPEND=0
	;Start at the beginning of the day -- AV Blocks can't overlap days
	S BSDXS=$P(BSDXSTART,"."),BSDXS=BSDXS-.0001
	F  S BSDXS=$O(^BSDXAB("ARSCT",BSDXRESD,BSDXS)) Q:'+BSDXS  Q:BSDXS>BSDXEND  D
	. S BSDXAD=0 F  S BSDXAD=$O(^BSDXAB("ARSCT",BSDXRESD,BSDXS,BSDXAD)) Q:'+BSDXAD  D
	. . Q:'$D(^BSDXAB(BSDXAD,0))
	. . S BSDXNOD=^BSDXAB(BSDXAD,0)
	. . S BSDXNSTART=$P(BSDXNOD,U,2)
	. . S BSDXNEND=$P(BSDXNOD,U,3)
	. . I BSDXNEND'>BSDXSTART Q
	. . S Y=BSDXNSTART X ^DD("DD") S BSDXNSTART=$TR(Y,"@"," ")
	. . S Y=BSDXNEND X ^DD("DD") S BSDXNEND=$TR(Y,"@"," ")
	. . S BSDXTPID=$P(BSDXNOD,U,5)
	. . S BSDXI=BSDXI+1
	. . S ^BSDXTMP($J,BSDXI)=BSDXNSTART_U_BSDXNEND_U_BSDXTPID_U_BSDXAD_U_BSDXRESN_$C(30)
	. . Q
	. Q
	Q
