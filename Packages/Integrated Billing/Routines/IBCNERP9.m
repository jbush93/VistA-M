IBCNERP9 ;DAOU/BHS - eIV STATISTICAL REPORT PRINT ;12-JUN-2002
 ;;2.0;INTEGRATED BILLING;**184,271,416,506,528,621**;21-MAR-94;Build 14
 ;;Per VA Directive 6402, this routine should not be modified.
 ;
 ; eIV - Insurance Verification Interface
 ;
 ; Input variables from IBCNERP7:
 ;  IBCNERTN = "IBCNERP7"
 ; **IBCNESPC array ONLY passed by reference
 ;  IBCNESPC("BEGDTM") = Start Date/Time for date/time report range
 ;  IBCNESPC("ENDDTM") = End Date/Time for date/time report range
 ;  IBCNESPC("SECTS") = 1 - All, includes all sections OR
 ;   list of one or more of the following:
 ;   2 - Outgoing Data, Inquiry Transmission data,
 ;   3 - Incoming Data, Inquiry Response data,
 ;   4 - General Data, Insurance Buffer data,
 ;   Communication Failures, Outstanding Inquiries
 ;   IBCNESPC("MM") = "", do not generate MailMan message OR
 ;                    MAILGROUP, mailgroup to send MailMan message to
 ;                               based on IB site parameter
 ;   Assumes report data exists in ^TMP($J,IBCNERTN,...)
 ;   Based on IBCNESPC("SECTS") parameter the following scratch globals
 ;   will be built
 ;   1 OR contains 2 --> 
 ;    ^TMP($J,RTN,"OUT")=TotInq^InsBufExtSubtotal^PreRegExtSubtotal^...
 ;                       NonVerifInsExtSubtotal^NoActInsExtSubtotal
 ;   1 OR contains 3 --> 
 ;    ^TMP($J,RTN,"IN")=TotResp^InsBufExtSubtotal^PreRegExtSubtotal^...
 ;                       NonVerifInsExtSubtotal^NoActInsExtSubtotal
 ;   1 OR contains 4 --> 
 ;    ^TMP($J,RTN,"CUR")=TotOutstandingInq^TotInqRetries^...
 ;                       TotInqCommFailure^TotInsBufVerified^...
 ;                       ManVerifedSubtotal^eIVProcessedSubtotal...
 ;                       TotInsBufUnverified^! InsBufSubtotal^...
 ;                       ? InsBufSubtotal^- InsBufSubtotal^...
 ;                       Other InsBufSubtotal^TQReadyToTransmit^...
 ;                       TQHold^TQRetry
 ;    and ^TMP($J,RTN","PYR",PAYER NAME,IEN of file 365.12)=""
 ;    IBOUT = "E" for Excel or "R" for report format        
 ; Must call at EN
 Q
 ;
EN(IBCNERTN,IBCNESPC,IBOUT) ; Entry pt
 ;
 ; Init vars
 N CRT,MAXCNT,IBPXT,IBPGC,IBBDT,IBEDT,IBSCT,IBMM,RETRY,OUTINQ,ATTEMPT
 N X,Y,DIR,DTOUT,DUOUT,LIN,IBMBI,IBQUERY
 ;
 S IBBDT=$G(IBCNESPC("BEGDTM")),IBEDT=$G(IBCNESPC("ENDDTM"))
 S IBSCT=$G(IBCNESPC("SECTS")),IBMM=$G(IBCNESPC("MM"))
 ;
 S (IBPXT,IBPGC,CRT,MAXCNT)=0
 ;
 ; Determine IO parameters if output device is NOT MailMan message
 I IBMM="" D
 . I IOST["C-" S MAXCNT=IOSL-3,CRT=1 Q
 . S MAXCNT=IOSL-6,CRT=0
 ;
 D PRINT(IBCNERTN,IBBDT,IBEDT,IBSCT,IBMM,.IBPGC,.IBPXT,MAXCNT,CRT,IBOUT)
 I $G(ZTSTOP)!IBPXT G EXIT
 I CRT,IBPGC>0,'$D(ZTQUEUED) D  G EXIT
 . I MAXCNT<51 F LIN=1:1:(MAXCNT-$Y) W !
 . S DIR(0)="E" D ^DIR K DIR
 ;
EXIT ; Exit pt
 Q
 ;
 ;
PRINT(RTN,BDT,EDT,SCT,MM,PGC,PXT,MAX,CRT,IBOUT) ; Print data
 ; Init vars
 N EORMSG,NONEMSG,LINECT,DISPDATA,HDRDATA,OFFSET,TMP,DTMRNG,SITE
 ;
 S LINECT=0
 ;
 ; Build End-Of-Report Message for display
 S EORMSG="*** END OF REPORT ***"
 S OFFSET=80-$L(EORMSG)\2
 S EORMSG=$$FO^IBCNEUT1(EORMSG,OFFSET+$L(EORMSG),"R")
 ; Build No-Data-Found Message for display
 S NONEMSG="* * * N O  D A T A  F O U N D * * *"
 S OFFSET=80-$L(NONEMSG)\2
 S NONEMSG=$$FO^IBCNEUT1(NONEMSG,OFFSET+$L(NONEMSG),"R")
 ; Build Site for display
 S SITE=$P($$SITE^VASITE,U,2)
 ; Build Date/Time Range for display
 ;  Build Date/Time display for Starting date/time
 S TMP=$$FMTE^XLFDT(BDT,"5Z")
 S DTMRNG=$P(TMP,"@")_" "_$P(TMP,"@",2)
 ;  Calculate Date/Time display for Ending date/time
 S TMP=$$FMTE^XLFDT(EDT,"5Z")
 S DTMRNG=DTMRNG_" - "_$P(TMP,"@")_" "_$P(TMP,"@",2)
 ;
 ; Print header to DISPDATA for MailMan message ONLY
 I IBOUT="R" D HEADER^IBCNERP0(.HDRDATA,.PGC,.PXT,MAX,CRT,SITE,DTMRNG,MM)
 I MM'="" M DISPDATA=HDRDATA S LINECT=+$O(DISPDATA(""),-1)
 I MM="" KILL HDRDATA
 ;
 ; If global does not exist - display No Data message
 I '$D(^TMP($J,RTN)) S LINECT=LINECT+1,DISPDATA(LINECT)=NONEMSG G PRINT2
 ;
 ; Display Outgoing Data - if selected
 I SCT=1!(SCT[2) D  I PXT!$G(ZTSTOP) G PRINTX
 . ; Build lines of data to display
 . D DATA(.DISPDATA,.LINECT,RTN,"OUT",MM,IBOUT)
 ;
 ; Display Incoming Data - if selected
 I SCT=1!(SCT[3) D  I PXT!$G(ZTSTOP) G PRINTX
 . ; Build lines of data to display
 . D DATA(.DISPDATA,.LINECT,RTN,"IN",MM,IBOUT)
 ;
 ; Display General Data - if selected
 I SCT=1!(SCT[4) D  I PXT!$G(ZTSTOP) G PRINTX
 . ; Build lines of data to display
 . D DATA(.DISPDATA,.LINECT,RTN,"CUR",MM,IBOUT)
 . D DATA(.DISPDATA,.LINECT,RTN,"PYR",MM,IBOUT)
 . D DATA(.DISPDATA,.LINECT,RTN,"FLG",MM,IBOUT)
 ;
PRINT2 S LINECT=LINECT+1
 S DISPDATA(LINECT)=EORMSG
 ;
 I MM="" D LINE(.DISPDATA,.PGC,.PXT,MAX,CRT,SITE,DTMRNG,MM)
 ; Generate MailMan message, if flag is set
 I MM'="" D MSG^IBCNEUT5(MM,"** eIV Statistical Rpt **","DISPDATA(")
 ;
PRINTX ; PRINT exit pt
 Q
 ;
LINE(DISPDATA,PGC,PXT,MAX,CRT,SITE,DTMRNG,MM) ; Print line of data
 ; Init vars
 N CT,II,ARRAY,NWPG
 ;
 S NWPG=0
 S CT=+$O(DISPDATA(""),-1)
 I $Y+1+CT>MAX,PGC>1 D HEADER^IBCNERP0(.ARRAY,.PGC,.PXT,MAX,CRT,SITE,DTMRNG,MM) S NWPG=1 I PXT!$G(ZTSTOP) G LINEX
 F II=1:1:CT D  Q:PXT!$G(ZTSTOP)
 . I $Y+1>MAX!('PGC) D HEADER^IBCNERP0(.ARRAY,.PGC,.PXT,MAX,CRT,SITE,DTMRNG,MM) S NWPG=1 I PXT!$G(ZTSTOP) Q
 . I 'NWPG!(NWPG&($D(DISPDATA(II)))) I $G(DISPDATA(II))'="" W !,?1,DISPDATA(II)
 . I NWPG S NWPG=0
 ;
LINEX ; LINE exit pt
 Q
 ;
DATA(DISPDATA,LINECT,RTN,TYPE,MM,IBOUT) ; Format lines of data to be printed
 ; Init vars
 ; 528 - baa : added code to output to Excel 
 N DASHES,PEND,RPTDATA,CT,DEFINQ,INSCOS,PAYERS,QUEINQ,TXT,TYPE1
 ;
 S $P(DASHES,"=",14)="",TYPE1=TYPE ; IB*2.0*621
 I LINECT>0,MM="" S LINECT=LINECT+1,DISPDATA(LINECT)=""
 ;
 ; Copy report data to local variable
 S RPTDATA=$G(^TMP($J,RTN,TYPE))      ; does not work for "PYR"
 ; Outgoing and Incoming Totals
 I TYPE="OUT"!(TYPE="IN") D  S:IBOUT="R" LINECT=LINECT+1,DISPDATA(LINECT)=" " G DATAX  ; IB*2.0*621 
 . S LINECT=LINECT+1
 . I IBOUT="R" S DISPDATA(LINECT)=$$FO^IBCNEUT1($S(TYPE="OUT":"Outgoing Data (Inquiries Sent)",1:"Incoming Data (Responses Received)"),46)_$$FO^IBCNEUT1(+$P(RPTDATA,U,1),14,"R") ; IB*2.0*621 
 . I IBOUT="E" S DISPDATA(LINECT)=$S(TYPE="OUT":"OUTGOING DATA",1:"INCOMING DATA")_U_+$P(RPTDATA,U,1)
 . S LINECT=LINECT+1
 . I IBOUT="R" S DISPDATA(LINECT)=DASHES ; IB*2.0*621
 . F CT=1:1:5 D  ; Updated for IB*2.0*621
 . . N TYPE ; 
 . . I TYPE1="IN" S TYPE=$S(CT=1:"Insurance Buffer",CT=2:"Appointment",CT=3:"Electronic Insurance Coverage Discovery (EICD)",CT=4:"EICD-Triggered eInsurance Verification",CT=5:"MBI Response")
 . . I TYPE1="OUT" S TYPE=$S(CT=1:"Insurance Buffer",CT=2:"Appointment",CT=3:"Electronic Insurance Coverage Discovery (EICD)",CT=4:"EICD-Triggered eInsurance Verification",CT=5:"MBI Inquiry")
 . . S LINECT=LINECT+1
 . . I IBOUT="E" S DISPDATA(LINECT)=TYPE_U_+$P(RPTDATA,U,CT+1)
 . . I IBOUT="R" S DISPDATA(LINECT)=$$FO^IBCNEUT1("   "_TYPE,50)_$$FO^IBCNEUT1(+$P(RPTDATA,U,CT+1),25,"R")
 ;
 ; General Data
 I TYPE="CUR" D  G DATAX
 . S LINECT=LINECT+1 ; IB*2.0*621 - Added Status Label
 . I IBOUT="R" S DISPDATA(LINECT)="Current Status"
 . I IBOUT="E" S DISPDATA(LINECT)="CURRENT STATUS"
 . I IBOUT="R" S LINECT=LINECT+1
 . I IBOUT="R" S DISPDATA(LINECT)="=============="
 . ; Responses Pending
 . S PEND=+$P(RPTDATA,U,1)
 . S LINECT=LINECT+1
 . I IBOUT="E" S DISPDATA(LINECT)="Responses Pending"_U_PEND
 . I IBOUT="R" S DISPDATA(LINECT)=$$FO^IBCNEUT1("Responses Pending:",46)_$$FO^IBCNEUT1(PEND,14,"R")
 . ; IB*2.0*621
 . ; Insurance Buffer
 . S PEND=+$P(RPTDATA,U,17)
 . S LINECT=LINECT+1
 . I IBOUT="E" S DISPDATA(LINECT)="Insurance Buffer"_U_PEND
 . I IBOUT="R" S DISPDATA(LINECT)=$$FO^IBCNEUT1("   Insurance Buffer",60)_$$FO^IBCNEUT1(PEND,15,"R")
 . ; Appointment
 . S PEND=+$P(RPTDATA,U,18)
 . S LINECT=LINECT+1
 . I IBOUT="E" S DISPDATA(LINECT)="Appointment"_U_PEND
 . I IBOUT="R" S DISPDATA(LINECT)=$$FO^IBCNEUT1("   Appointment",60)_$$FO^IBCNEUT1(PEND,15,"R")
 . ; Electronic Insurance Coverage Discovery (EICD)
 . S PEND=+$P(RPTDATA,U,19)
 . S LINECT=LINECT+1
 . I IBOUT="E" S DISPDATA(LINECT)="Electronic Insurance Coverage Discovery (EICD)"_U_PEND
 . I IBOUT="R" S DISPDATA(LINECT)=$$FO^IBCNEUT1("   Electronic Insurance Coverage Discovery (EICD)",60)_$$FO^IBCNEUT1(PEND,15,"R")
 . ; EICD-Triggered eInsurance Verification
 . S PEND=+$P(RPTDATA,U,20)
 . S LINECT=LINECT+1
 . I IBOUT="E" S DISPDATA(LINECT)="EICD-Triggered eInsurance Verification"_U_PEND
 . I IBOUT="R" S DISPDATA(LINECT)=$$FO^IBCNEUT1("   EICD-Triggered eInsurance Verification",60)_$$FO^IBCNEUT1(PEND,15,"R")
 . ; MBI Inquiry
 . S PEND=+$P(RPTDATA,U,21)
 . S LINECT=LINECT+1
 . I IBOUT="E" S DISPDATA(LINECT)="MBI Inquiry"_U_PEND
 . I IBOUT="R" S DISPDATA(LINECT)=$$FO^IBCNEUT1("   MBI Inquiry",60)_$$FO^IBCNEUT1(PEND,15,"R")
 . ; IB*2.0*621 - End
 . ; Queued Inqs
 . S QUEINQ=+$P(RPTDATA,U,2)
 . S LINECT=LINECT+1
 . I IBOUT="E" S DISPDATA(LINECT)="Queued Inquiries"_U_QUEINQ
 . I IBOUT="R" S DISPDATA(LINECT)=$$FO^IBCNEUT1("Queued Inquiries:",46)_$$FO^IBCNEUT1(QUEINQ,14,"R")
 . ; Deferred Inqs
 . S DEFINQ=+$P(RPTDATA,U,3)
 . S LINECT=LINECT+1
 . I IBOUT="E" S DISPDATA(LINECT)="Deferred Inquiries:"_U_DEFINQ
 . I IBOUT="R" S DISPDATA(LINECT)=$$FO^IBCNEUT1("Deferred Inquiries:",46)_$$FO^IBCNEUT1(DEFINQ,14,"R")
 . ; Ins Cos w/o Nat ID
 . S INSCOS=+$P(RPTDATA,U,4)
 . S LINECT=LINECT+1
 . I IBOUT="E" S DISPDATA(LINECT)="Insurance Companies w/o National ID"_U_INSCOS
 . I IBOUT="R" S DISPDATA(LINECT)=$$FO^IBCNEUT1("Insurance Companies w/o National ID:",46)_$$FO^IBCNEUT1(INSCOS,14,"R")
 . ; Payers disabled locally
 . S PAYERS=+$P(RPTDATA,U,5)
 . S LINECT=LINECT+1
 . I IBOUT="E" S DISPDATA(LINECT)="eIV Payers Disabled Locally"_U_PAYERS
 . I IBOUT="R" S DISPDATA(LINECT)=$$FO^IBCNEUT1("eIV Payers Disabled Locally:",46)_$$FO^IBCNEUT1(PAYERS,14,"R")
 . I IBOUT="R" S LINECT=LINECT+1
 . I IBOUT="R" S DISPDATA(LINECT)=" "
 . ; Insurance Buffer statistics
 . S LINECT=LINECT+1
 . I IBOUT="E" S DISPDATA(LINECT)="Insurance Buffer Entries: "_U_($P(RPTDATA,U,6)+$P(RPTDATA,U,9))
 . I IBOUT="R" S DISPDATA(LINECT)=$$FO^IBCNEUT1("Insurance Buffer Entries: ",46)_$$FO^IBCNEUT1(($P(RPTDATA,U,6)+$P(RPTDATA,U,9)),14,"R") ; IB*2.0*621
 . ; *,+,#,! or -  symbol entries - User action required
 . S LINECT=LINECT+1
 . I IBOUT="E" S DISPDATA(LINECT)="User Action Required"_U_+$P(RPTDATA,U,6)
 . I IBOUT="R" S DISPDATA(LINECT)=$$FO^IBCNEUT1("  User Action Required: ",46)_$$FO^IBCNEUT1(+$P(RPTDATA,U,6),22,"R")
 . I IBOUT="R" F CT=8,15,16,13,10,11 D  ; IB*2.0*621
 . . S LINECT=LINECT+1
 . . ; Added # to report
 . . S TYPE="    # of "
 . . I CT=7 S TXT="* entries (User Verified policy)"
 . . I CT=8 S TXT="+ entries (Payer indicated Active policy)"
 . . I CT=10 S TXT="# entries (Policy status undetermined)"
 . . I CT=11 S TXT="! entries (eIV needs user assistance for entry)"
 . . I CT=13 S TXT="- entries (Payer indicated Inactive policy)"
 . . I CT=15 S TXT="$ entries (Escalated, Active policy)"
 . . I CT=16 S TXT="% entries (MBI value received)" ; IB*2.0*621
 . . S TYPE=TYPE_TXT
 . . S DISPDATA(LINECT)=$$FO^IBCNEUT1(TYPE,56)_$$FO^IBCNEUT1(+$P(RPTDATA,U,CT),19,"R")
 . ;
 . S LINECT=LINECT+1
 . I IBOUT="E" S DISPDATA(LINECT)="Entries Awaiting Processing"_U_+$P(RPTDATA,U,9)
 . I IBOUT="R" S DISPDATA(LINECT)=$$FO^IBCNEUT1("  Entries Awaiting Processing: ",46)_$$FO^IBCNEUT1(+$P(RPTDATA,U,9),22,"R")
 . ; Subtotal of ? entries (eIV is waiting for a response)
 . S LINECT=LINECT+1
 . I IBOUT="E" S DISPDATA(LINECT)="# of ? entries (eIV is waiting for a response)"_U_+$P(RPTDATA,U,12)
 . I IBOUT="R" S DISPDATA(LINECT)=$$FO^IBCNEUT1("    # of ? entries (eIV is waiting for a response)",56)_$$FO^IBCNEUT1(+$P(RPTDATA,U,12),19,"R")
 . ; Subtotal of blank entries (yet to be processed or accepted)
 . S LINECT=LINECT+1
 . I IBOUT="E" S DISPDATA(LINECT)="# of blank entries (yet to be processed or accepted)"_U_+$P(RPTDATA,U,14)
 . I IBOUT="R" S DISPDATA(LINECT)=$$FO^IBCNEUT1("    # of blank entries (yet to be processed or accepted)",56)_$$FO^IBCNEUT1(+$P(RPTDATA,U,14),19,"R")
 ;
 ; Blank Line 
 S LINECT=LINECT+1 ; IB*2.0*621 
 I IBOUT="R" S DISPDATA(LINECT)=" " ; IB*2.0*621 
 ; New Payers added to File 365.12
 I TYPE="PYR" D  G DATAX
 . ; Payers added to file 365.12
 . D DATAX
 . S LINECT=LINECT+1 ; IB*2.0*621
 . I IBOUT="E" S DISPDATA(LINECT)="PAYER ACTIVITY (During Report Date Range)" ; IB*2.0*621
 . I IBOUT="R" S DISPDATA(LINECT)="Payer Activity (During Report Date Range)" ; IB*2.0*621
 . I IBOUT="R" S LINECT=LINECT+1
 . I IBOUT="R" S DISPDATA(LINECT)="=============="
 . S LINECT=LINECT+1
 . S DISPDATA(LINECT)="New eIV Payers received:" ; IB*2.0*621
 . S LINECT=LINECT+1
 . I '$D(^TMP($J,RTN,TYPE)) S DISPDATA(LINECT)=" No new Payers added" Q
 . S DISPDATA(LINECT)="  Please link the associated active insurance companies to these payers at your"
 . S LINECT=LINECT+1,DISPDATA(LINECT)="  earliest convenience.  Locally activate the payers after you link insurance"
 . S LINECT=LINECT+1,DISPDATA(LINECT)="  companies to them.  For further details regarding this process, please refer"
 . S LINECT=LINECT+1,DISPDATA(LINECT)="  to the Integrated Billing eIV Interface User Guide."
 . N PYR,PIEN
 . S PYR="",PIEN="" F  S PYR=$O(^TMP($J,RTN,TYPE,PYR)) Q:PYR=""  D
 . . F  S PIEN=$O(^TMP($J,RTN,TYPE,PYR,PIEN)) Q:'PIEN  D
 . . . S LINECT=LINECT+1
 . . . I IBOUT="E" S DISPDATA(LINECT)=PYR Q
 . . . I IBOUT="R" S DISPDATA(LINECT)="    "_PYR
 ;
 ; Active/Trusted flag logs
 I TYPE="FLG" D  G DATAX ; IB*2.0*621 Added Payer Received
 .N DATA,PNAME,Z,FLG
 .F FLG="A","T" D
 ..I FLG="A" D
 ...I IBOUT="R" S DISPDATA(LINECT)=" "
 ...S LINECT=LINECT+1,DISPDATA(LINECT)="National Payers - ACTIVE flag changes at FSC:"
 ...Q
 ..I FLG="T" D
 ...I IBOUT="R" S LINECT=LINECT+1,DISPDATA(LINECT)=" "
 ...S LINECT=LINECT+1,DISPDATA(LINECT)="Nationally Active Payers - TRUSTED flag changes at FSC:"
 ...Q
 ..I '$D(^TMP($J,RTN,"CUR","FLAGS",FLG)) S LINECT=LINECT+1,DISPDATA(LINECT)=" No information available",LINECT=LINECT+1 Q
 ..S PNAME="" F  S PNAME=$O(^TMP($J,RTN,"CUR","FLAGS",FLG,PNAME)) Q:PNAME=""  D
 ...S Z="" F  S Z=$O(^TMP($J,RTN,"CUR","FLAGS",FLG,PNAME,Z)) Q:Z=""  D
 ....S DATA=$G(^TMP($J,RTN,"CUR","FLAGS",FLG,PNAME,Z))
 ....S LINECT=LINECT+1
 ....I IBOUT="E" S DISPDATA(LINECT)=PNAME_U_$P(DATA,U)_U_$P(DATA,U,2)
 ....I IBOUT="R" S DISPDATA(LINECT)=$$FO^IBCNEUT1(" "_PNAME,47)_$$FO^IBCNEUT1($P(DATA,U),19)_" Set: "_$P(DATA,U,2)
 ....Q
 ...Q
 .Q
DATAX ; DATA exit pt
 S LINECT=LINECT+1
 S DISPDATA(LINECT)=""
 Q
 ;
