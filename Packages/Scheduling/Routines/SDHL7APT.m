SDHL7APT ;MS/TG,PH - TMP HL7 Routine;AUG 17, 2018
 ;;5.3;Scheduling;**704**;AUG 17, 2018;Build 64
 ;
 ;  Integration Agreements:
 Q
 ;
PROCSIU ;Process SIU^S12 messages from the "TMP VISTA" Subscriber protocol
 ;ENT ;
 ;EN ;
 ;
 ; This routine and subroutines assume that all VistA HL7 environment
 ; variables are properly initialized and will produce a fatal error
 ; if they are missing.
 ;
 ;  The message will be checked to see if it is a valid SIU. If valid - the SIU will process the 1st RGS group
 ;  on the current facility. Any subsequent RGS groups will be sent to facilities as specified in AIL.3.4
 ;  In the event the appointment does not file on the remote facility (ie; an AE is received from that remote facility)
 ;  an AE (with the appropriate error text) will be returned to HealthShare.
 ;  Input:
 ;          HL7 environment variables
 ;
 ; Output:
 ;          Positive (AA) or negative acknowledgement (AE - with appropriate error text)
 ;    
 ;
 ;  Integration Agreements: NONE
 ;
 N MSGROOT,DATAROOT,QRY,XMT,ERR,RNAME,IX
 K SDTMPHL
 S (MSGROOT,QRY,XMT,ERR,RNAME)=""
 S U="^"
 ;
 ; Inbound SIU messages are small enough to be held in a local array.
 ; The following lines commented out support use of temporary globals and are
 ; left for debugging purposes.
 ;
 S MSGROOT="SDHL7APT"
 K @MSGROOT
 N EIN
 S EIN=$$FIND1^DIC(101,,,"SD TMP S12 SERVER EVENT DRIVER")
 ;
 D LOADXMT^SDHL7APU(.HL,.XMT)         ;Load inbound message information
 K ACKMSG S ACKMSG=$G(HL("MID"))
 S RNAME=XMT("MESSAGE TYPE")_"-"_XMT("EVENT TYPE")_" RECEIVER"
 ;
 N CNT,SEG
 K @MSGROOT
 D LOADMSG^SDHL7APU(MSGROOT)
 ;
 D PARSEMSG^SDHL7APU(MSGROOT,.HL)
 ;
 N DFN,RET,CNT,PID,PV1,RGS,AIS,AIG,AISNTE,AIP,AIPNTE,INP,SETID,EXTIME,SCHNTE,SCH,SDMTC,QRYDFN,MSGCONID,LST,MYRESULT,HLA,PTIEN,SCPER,ATYPIEN
 N AIGNTE,AIL,AILNTE,ARSETE,CURDTTM,ERROR,FLMNFMT,GRPCNT,GRPNO,OBX,PREVSEG,PTIEN,SCHDFN,SCPERC,SDDDT,SDECATID,SDUSER,CHILD
 N SDECCR,SDECEND,SDECLEN,SDECNOTE,SDECRES,SDECSTART,SDECY,SDEKG,SDEL,SDID,SDLAB,SDMRTC,SDPARENT,SDCHILD,SDECAPTID,SDECDATE,FIRST
 N SDREQBY,SDSVCP,SDSVCPR,SDXRAY,SEGTYPE,SETID,SITE,STA,STATUS,STOP,PROVIEN,ERRCND,ERRSND,ERRTXT,URL,MSH,SDECNOT
 ;
 S (MSGCONID,SCHDFN)=""
 S CNT=1,SETID=1,PREVSEG="",GRPCNT=0,PTIEN="",ERRTXT="",ERRSND=""
 ;
 ; Loop to receive HL7 message segments.
 S ERR=0
 F  Q:'$D(@MSGROOT@(CNT))  Q:ERR  D  S CNT=CNT+1,PREVSEG=SEGTYPE
 .S SEGTYPE=$G(@MSGROOT@(CNT,0))
 .I SEGTYPE="MSH" M MSH=@MSGROOT@(CNT) Q
 .I SEGTYPE="SCH" M SCH=@MSGROOT@(CNT) Q
 .I SEGTYPE="NTE",(PREVSEG="SCH") M SCHNTE=@MSGROOT@(CNT) Q
 .I SEGTYPE="PID" M PID=@MSGROOT@(CNT) Q
 .I SEGTYPE="PV1" M PV1=@MSGROOT@(CNT) Q
 .I SEGTYPE="OBX" M OBX=@MSGROOT@(CNT) Q
 .I SEGTYPE="RGS" D  Q
 ..S SETID=$G(@MSGROOT@(CNT,1))
 ..I +SETID=0 S ERR=1,ERRTXT="Invalid RGS SetID received" Q
 ..M RGS(SETID)=@MSGROOT@(CNT)
 ..S GRPCNT=GRPCNT+1
 ..Q
 .I SEGTYPE="AIS" M AIS(SETID)=@MSGROOT@(CNT) Q
 .I SEGTYPE="NTE",(PREVSEG="AIS") M AISNTE(SETID)=@MSGROOT@(CNT) Q
 .I SEGTYPE="AIG" M AIG(SETID)=@MSGROOT@(CNT) Q
 .I SEGTYPE="NTE",(PREVSEG="AIG") M AIGNTE(SETID)=@MSGROOT@(CNT) Q 
 .I SEGTYPE="AIL" M AIL(SETID)=@MSGROOT@(CNT) Q
 .I SEGTYPE="NTE",(PREVSEG="AIL") M AILNTE(SETID)=@MSGROOT@(CNT) Q 
 .I SEGTYPE="AIP" M AIP(SETID)=@MSGROOT@(CNT) Q
 .I SEGTYPE="NTE",(PREVSEG="AIP") M AIPNTE(SETID)=@MSGROOT@(CNT)
 .Q
 I $G(AIL(2,4))="R" D  ;Check to see if this is an intrafacility rtc order and set the rtc number to null on the second AIL second so both appointments file.
 .I $G(AIL(2,4))=$G(AIL(1,4)) S AIL(2,4)="",AIL(2,4)=""
 ;
 I +ERR D  Q
 .S ERR="MSA^1^^100^AE^"_$E(ERRTXT,1,50)
 .D SENDERR^SDHL7APU(ERR)
 .K @MSGROOT
 .Q
 ;
 K SCHNW,INP,PCE,SCPER,ATYPIEN
 ;
 ; Loop to populate MSGARY, INP arrays which are used in ^SDECAR2 (to create appt request) and ^SDEC07 (to create appt)
 N MSGARY,SDCL2,SDCL3
 D MSH^SDHL7APU(.MSH,.INP,.MSGARY)
 D SCH^SDHL7APU(.SCH,.INP,.MSGARY)
 D SCHNTE^SDHL7APU(.SCHNTE,.INP,.MSGARY)
 D PID^SDHL7APU(.PID,.INP,.MSGARY)
 D PV1^SDHL7APU(.PV1,.INP,.MSGARY)
 D OBX^SDHL7APU(.OBX,.INP)
 F IX=1:1:GRPCNT D
 .D RGS^SDHL7APU(.RGS,IX,.INP)
 .D AIS^SDHL7APU(.AIS,IX,.INP,.MSGARY)
 .D AISNTE^SDHL7APU(.AISNTE,IX,.INP)
 .D AIG^SDHL7APU(.AIG,IX,.INP)
 .D AIGNTE^SDHL7APU(.AIGNTE,IX,.INP)
 .D AIL^SDHL7APU(.AIL,IX,.INP,.MSGARY)
 .D AILNTE^SDHL7APU(.AILNTE,IX,.INP)
 .D AIP^SDHL7APU(.AIP,IX,.INP,.MSGARY)
 .D AIPNTE^SDHL7APU(.AIPNTE,IX,.INP)
 .Q
 N %,NOW
 D NOW^%DTC S CURDTTM=$$TMCONV^SDHLAPT2(%)
 S NOW=$$HTFM^XLFDT($H),INP(3)=$$FMTE^XLFDT(NOW)
 S INP(11)=INP(3)
 S INP(5)="APPT"
 S INP(8)="FUTURE"
 ;
 N X11 S X11=$P($G(SDAPTYP),"|") S:$G(X11)="" X11="A"
 S INP(9)=$S(X11="A":"PATIENT",1:"PROVIDER") ;request by provider or patient. RTC orders and consults will always be PROVIDER otherwise it is PATIENT
 ;
 K DFN
 S (DFN,INP(2),MSGARY("DFN"))=$$GETDFN^MPIF001(MSGARY("MPI"))
 I $P(DFN,U,2)="NO ICN"!($P(DFN,U,2)="ICN NOT IN DATABASE") D  Q
 .S ERR="MSA^1^^100^AE^PATIENT ICN NOT FOUND"
 .D SENDERR^SDHL7APU(ERR)
 .K @MSGROOT
 .Q
 ;
 N STOPME
 I $P($G(SDAPTYP),"|",1)="C"!($P($G(SDAPTYP),"|",1)="R") D CHKCON^SDHLAPT2(DFN,SDAPTYP) I $G(STOPME)=1 Q
 ;
  I $G(SDCL)="" D  Q
 .S ERR="MSA^1^^100^AE^CLINIC ID IS NULL",STOPME=1
 .D SENDERR^SDHL7APU(ERR)
 .K @MSGROOT
 .Q
 ;
 Q:$G(STOPME)=1
 ;
 I '$D(^SC($G(SDCL),0)) D  Q
 .S ERR="MSA^1^^100^AE^NOT A CLINIC AT THIS SITE"
 .D SENDERR^SDHL7APU(ERR)
 .K @MSGROOT
 .Q
 ;
 K INP D INP^SDHL7APU
 ;
 S RET=""
 ;I a regular appt, not rtc or consult check to see if the appointment is in 409.85
 I $P(SDAPTYP,"|",1)="A" D
 .Q:$$UPPER^SDUL1(MSGARY("HL7EVENT"))'="S12"
 .;D CHKAPT^SDHL7APU(.RET,INP(2),INP(6))
 .;I $G(RET)>0 S (SDAPTYP,MSGARY("SDAPTYP"))="A|"_$G(RET)
 .;I $G(RET)'>0 S:INP(3)="" INP(3)=DT S RTN=0 D ARSET^SDHLAPT1(.RTN,.INP) S:$P($G(RTN),U,2) (SDAPTYP,MSGARY("SDAPTYP"))="A|"_$P($G(RTN),U,2)
 .S:INP(3)="" INP(3)=DT S RTN=0 D ARSET^SDHLAPT1(.RTN,.INP) S:$P($G(RTN),U,2) (SDAPTYP,MSGARY("SDAPTYP"))="A|"_$P($G(RTN),U,2)
 I $G(SDMTC)=1 D CHKCHILD^SDHL7APU ; if multi check to see if the child order is in 409.85, if not add it
 ;
 S MSGARY("SDECEND")=""
 S MSGARY("SDDDT")=$TR($G(MSGARY("SDDDT")),"-","")
 N TMPSTART
 S FLMNFMT=$$CONVTIME^SDHL7APU(MSGARY("SDECSTART")),TMPSTART=FLMNFMT,MSGARY("SDECSTART")=$$FMTE^XLFDT(FLMNFMT)
 I FLMNFMT<1 D  Q
 .S ERR="MSA^1^^100^AE^Invalid Start Date sent"
 .D SENDERR^SDHL7APU(ERR)
 .K @MSGROOT
 .Q
 ;
 I $L(MSGARY("SDECLEN")),$L(MSGARY("SDECLENUNITS")) D
 .I MSGARY("SDECLENUNITS")="MIN" S MSGARY("SDECEND")=$$FMADD^XLFDT(FLMNFMT,,,MSGARY("SDECLEN"))
 .I MSGARY("SDECLENUNITS")="HR" S MSGARY("SDECEND")=$$FMADD^XLFDT(FLMNFMT,,MSGARY("SDECLEN"))
 .Q
 ;
 N TMPARR,LEN
 S LEN=0
 S ERRSND=0
 S ERRTXT=""
 S MSGROOT="SDTMPHL"
 K @MSGROOT
 ; Loop to send RGS>1 groups to remote facilities. Abort entire SIU if any facility returns AE from remote.
 N INTRA S INTRA=0
 F GRPNO=2:1:GRPCNT D  Q:+ERRSND
 .K @MSGROOT
 .S CNT=1
 .I $D(SCH) S:$G(FCHILD)>0 SCH(7,1,4)=FCHILD S @MSGROOT@(CNT)=$$BLDSEG^SDHL7UL(.SCH,.HL),LEN=LEN+$L(@MSGROOT@(CNT)) K FCHILD
 .I $D(SCHNTE) S CNT=CNT+1,@MSGROOT@(CNT)=$$BLDSEG^SDHL7UL(.SCHNTE,.HL),LEN=LEN+$L(@MSGROOT@(CNT))
 .I $D(PID) S CNT=CNT+1,@MSGROOT@(CNT)=$$BLDSEG^SDHL7UL(.PID,.HL),LEN=LEN+$L(@MSGROOT@(CNT))
 .I $D(PV1) S CNT=CNT+1,@MSGROOT@(CNT)=$$BLDSEG^SDHL7UL(.PV1,.HL),LEN=LEN+$L(@MSGROOT@(CNT))
 .M TMPARR=RGS(GRPNO)
 .I $D(TMPARR) S CNT=CNT+1,@MSGROOT@(CNT)=$$BLDSEG^SDHL7UL(.TMPARR,.HL),LEN=LEN+$L(@MSGROOT@(CNT))
 .K TMPARR
 .M TMPARR=AIS(GRPNO)
 .I $D(TMPARR) S CNT=CNT+1,@MSGROOT@(CNT)=$$BLDSEG^SDHL7UL(.TMPARR,.HL),LEN=LEN+$L(@MSGROOT@(CNT))
 .K TMPARR
 .M TMPARR=AISNTE(GRPNO)
 .I $D(TMPARR) S CNT=CNT+1,@MSGROOT@(CNT)=$$BLDSEG^SDHL7UL(.TMPARR,.HL),LEN=LEN+$L(@MSGROOT@(CNT))
 .K TMPARR
 .M TMPARR=AIG(GRPNO)
 .I $D(TMPARR) S CNT=CNT+1,@MSGROOT@(CNT)=$$BLDSEG^SDHL7UL(.TMPARR,.HL),LEN=LEN+$L(@MSGROOT@(CNT))
 .K TMPARR
 .M TMPARR=AIL(GRPNO)
 .I $D(TMPARR) D
 ..S MSGARY("INSTIEN")=$G(TMPARR(3,1,4))
 ..S CNT=CNT+1,@MSGROOT@(CNT)=$$BLDSEG^SDHL7UL(.TMPARR,.HL),LEN=LEN+$L(@MSGROOT@(CNT))
 .K TMPARR
 .M TMPARR=AILNTE(GRPNO)
 .I $D(TMPARR) S CNT=CNT+1,@MSGROOT@(CNT)=$$BLDSEG^SDHL7UL(.TMPARR,.HL),LEN=LEN+$L(@MSGROOT@(CNT))
 .K TMPARR
 .M TMPARR=AIP(GRPNO)
 .I $D(TMPARR) S CNT=CNT+1,@MSGROOT@(CNT)=$$BLDSEG^SDHL7UL(.TMPARR,.HL),LEN=LEN+$L(@MSGROOT@(CNT))
 .K TMPARR
 .M TMPARR=AIPNTE(GRPNO)
 .I $D(TMPARR) S CNT=CNT+1,@MSGROOT@(CNT)=$$BLDSEG^SDHL7UL(.TMPARR,.HL),LEN=LEN+$L(@MSGROOT@(CNT))
 .K TMPARR
 .I MSGARY("INSTIEN")=MSGARY("HLTHISSITE") S INTRA=1
 .I INTRA=1 D NEWTIME^SDHLAPT2
 .N HLRESLT,X
 .I INTRA=0 D
 ..I '$$CHKLL^HLUTIL($G(MSGARY("INSTIEN"))) D  Q
 ...S ERRSND=1,ERRTXT=$E("Invalid Link assoc with institution: "_$G(MSGARY("INSTIEN")),1,48)
 ..Q
 .K HLA,HLEVN
 .N MC,HLFS,HLCS
 .N IXX
 .F IXX=1:1:CNT S HLA("HLS",IXX)=$G(@MSGROOT@(IXX))
 .M HLA("HLA")=HLA("HLS")
 .S EIN=$$FIND1^DIC(101,,,"SD IFS EVENT DRIVER")
 .;the following HL* variables are created by DIRECT^HLMA
 .N HL,HLCS,HLDOM,HLECH,HLFS,HLINST,HLINSTN
 .N HLMTIEN,HLNEXT,HLNODE,HLPARAM,HLPROD,HLQ
 .N HLQUITQ,SDLINK,OROK,MSASEG,ERRRSP
 .;
 .I $$UPPER^SDUL1(MSGARY("HL7EVENT"))="S12" D
 ..K HL
 ..D:$G(INTRA)=0 INIT^HLFNC2("SD IFS EVENT DRIVER",.HL)
 ..D:$G(INTRA)=1 INIT^HLFNC2("SD TMP SEND INTRAFACILITY",.HL) ;if intra
 ..Q
 .I $$UPPER^SDUL1(MSGARY("HL7EVENT"))="S15" D
 ..K HL
 ..D:$G(INTRA)=0 INIT^HLFNC2("SD TMP S15 SERVER EVENT DRIVER",.HL)
 ..D:$G(INTRA)=1 INIT^HLFNC2("SD TMP SEND CANCEL INTRA",.HL) ;if intra
 ..Q
 .S SITE=MSGARY("INSTIEN")
 .S STA=$$STA^XUAF4(SITE)
 .S:$G(STA)="" STA=+$G(AIL(2,3,1,4))
 .D LINK^HLUTIL3(STA,.SDLINK,"I")
 .S SDLINK=$O(SDLINK(0))
 .I SDLINK="" D  Q
 ..Q:$G(INTRA)=1
 ..S ERRSND=1,ERRTXT=$E("Message link undefined for facility: "_$G(MSGARY("INSTIEN")),1,48)
 ..Q 
 .S SDLINK=SDLINK(SDLINK)
 .I $$UPPER^SDUL1(MSGARY("HL7EVENT"))="S12" D
 ..S:$G(INTRA)=0 HLL("LINKS",1)="SD IFS SUBSCRIBER"_U_$G(SDLINK)
 ..S:$G(INTRA)=1 HLL("LINKS",1)="SD TMP RECEIVE INTRAFACILITY"_U_$G(SDLINK)
 ..Q
 .I $$UPPER^SDUL1(MSGARY("HL7EVENT"))="S15" D
 ..S:$G(INTRA)=0 HLL("LINKS",1)="SD TMP S15 CLIENT SUBSCRIBER"_U_$G(SDLINK)
 ..S:$G(INTRA)=1 HLL("LINKS",1)="SD TMP RECEIVE CANCEL INTRA"_U_$G(SDLINK)
 ..Q
 .S HLMTIEN=""
 .I $$UPPER^SDUL1(MSGARY("HL7EVENT"))="S12" D
 ..D:$G(INTRA)=0 DIRECT^HLMA("SD IFS EVENT DRIVER","LM",1,.OROK) ;GENERATE   /SD IFS EVENT DRIVER/////SD TMP S12 CLIENT SUBSCRIBER TOMS CODE
 ..D:$G(INTRA)=1 GENERATE^HLMA("SD TMP SEND INTRAFACILITY","LM",1,.OROK) S HLMTIEN=+OROK ;GENERATE   /SD IFS EVENT DRIVER/////SD TMP S12 CLIENT SUBSCRIBER TOMS CODE
 ..Q
 .I $$UPPER^SDUL1(MSGARY("HL7EVENT"))="S15" D
 ..D:$G(INTRA)=0 DIRECT^HLMA("SD TMP S15 SERVER EVENT DRIVER","LM",1,.OROK) ;GENERATE   /SD IFS EVENT DRIVER/////SD TMP S12 CLIENT SUBSCRIBER
 ..D:$G(INTRA)=1 GENERATE^HLMA("SD TMP SEND CANCEL INTRA","LM",1,.OROK) S HLMTIEN=+OROK  ;GENERATE   /SD IFS EVENT DRIVER/////SD TMP S12 CLIENT SUBSCRIBER
 ..Q
 .I 'HLMTIEN D  Q
 ..S ERRSND=1,ERRTXT=$E("Message sent to remote facility unsuccessful: "_$G(MSGARY("INSTIEN")),1,48)
 ..Q
 .K @MSGROOT
 .;Process response
 .I $G(INTRA)=0 D
 ..N HLNODE,SEG,I,RESP,IK
 ..;H 2
 ..F IK=1:1 X HLNEXT Q:HLQUIT'>0  D
 ...S RESP(IK)=HLNODE
 ...Q
 ..S MSASEG=$G(RESP(2))
 ..I $E(MSASEG,1,3)="MSA",$P(MSASEG,"|",2)="AE" S ERRSND=1,ERRTXT=$$STRIP^SDHL7APU($P(MSASEG,"|",4)),ERRTXT=$E(ERRTXT,1,50)
 .Q
 ;
 I +ERRSND D  Q
 .S ERR="MSA^1^^100^AE^"_ERRTXT
 .D SENDERR^SDHL7APU(ERR)
 .K @MSGROOT
 .Q
 K @MSGROOT
 D INIT^HLFNC2(EIN,.HL)
 S HL("FS")="|",HL("ECH")="^~\&"
 N SDSVCP,SDSVCPR,SDEKG,SDXRAY,SDCL,SDECRES,SDAPTYP,APPTYPE,EESTAT,SDPARENT,SDEL,OVB,SDECY,SDECLEN,SDREQBY,SDSVCP,APPTYPE,SDDDT,SDCL
 S SDSVCP=""
 S SDSVCPR=""
 S (SDEKG,SDXRAY)=""
 S SDCL=$G(MSGARY("SDCL"))
 D RESLKUP^SDHL7APU(SDCL)
 S:$G(RET1) SDECRES=RET1
 S APPTYPE="",EESTAT="",SDPARENT="",SDEL="",MSGARY("SDECCR")="",MSGARY("OVB")=1,(MSGARY("SDEKG"),MSGARY("SDXRAY"))=""
 S MSGARY("SDECRES")=$$RESLKUP^SDHL7APU($G(MSGARY("SDCL")))
 S (MSGARY("SDEKG"),MSGARY("SDXRAY"))="",(MSGARY("SDEL"),MSGARY("EESTAT"),MSGARY("APPTYPE"),MSGARY("SDLAB"),MSGARY("SDECCR"),MSGARY("SDID"))="",(MSGARY("SDSVCP"),MSGARY("SDSVCPR"))=""
 S SDECY="",SDECSTART=MSGARY("SDECSTART"),SDECEND=MSGARY("SDECEND"),DFN=MSGARY("DFN"),SDECRES=MSGARY("SDECRES"),SDECLEN=MSGARY("SDECLEN"),SDECNOTE=MSGARY("SDECNOTE"),SDECATID=MSGARY("SDECATID")
 S (SDMRTC,MSGARY("SDMRTC"))=$S($G(SDMRTC)=1:"TRUE",1:"FALSE"),SDREQBY=MSGARY("SDREQBY"),SDLAB=MSGARY("SDLAB"),PROVIEN=MSGARY("PROVIEN"),SDID=MSGARY("SDID")  ;,SDAPTYP=MSGARY("SDAPTYP")
 S SDSVCP=MSGARY("SDSVCP"),SDSVCPR=MSGARY("SDSVCPR"),SDCL=MSGARY("SDCL"),SDEKG=MSGARY("SDEKG"),SDXRAY=MSGARY("SDXRAY")
 S APPTYPE=MSGARY("APPTYPE"),EESTAT=MSGARY("EESTAT"),OVB=MSGARY("OVB"),SDPARENT=$G(MSGARY("SDPARENT")),SDEL=MSGARY("SDEL"),SDECCR=""
 S SDDDT=$G(MSGARY("SDDDT")),SDAPTYP=$G(MSGARY("SDAPTYP"))
 I $P(SDAPTYP,"|",1)="R" D
 .S $P(SDAPTYP,"|",1)="A"
 .I $P(SDAPTYP,"|",2)=$G(SDPARENT) S:$P($G(^SDEC(409.85,$G(SDPARENT),3)),"^")="" SDPARENT=""
 ;
 K INP D INP^SDHL7APU
 S (ERRCND,ERRTXT)=""
 N SUCCESS
 S SUCCESS=0
 S (PROVIEN,DUZ)=$G(MSGARY("DUZ"))
 S:$G(DUZ)="" (PROVIEN,DUZ)=.5
 S:$G(DUZ(2))="" DUZ(2)=$G(MSGARY("HLTHISSITE"))
 I $$UPPER^SDUL1(MSGARY("HL7EVENT"))="S12" D
 .S URL=MSGARY("AILNTE")
 .S:$P($G(SDAPTYP),"|",1)="R" $P(SDAPTYP,"|",1)="A"
 .I ($P($G(SDAPTYP),"|")="A"&($P($G(SDAPTYP),"|",2)="")) S $P(SDAPTYP,"|",2)=$G(SDCHILD)
 .S:$P($G(SDAPTYP),"|")="" SDAPTYP="A|"_$G(SDCHILD)
 .D APPADD^SDEC07(.SDECY,SDECSTART,SDECEND,DFN,SDECRES,SDECLEN,SDECNOTE,SDECATID,SDECCR,SDMRTC,SDDDT,SDREQBY,SDLAB,PROVIEN,SDID,SDAPTYP,SDSVCP,SDSVCPR,SDCL,SDEKG,SDXRAY,APPTYPE,EESTAT,OVB,SDPARENT,SDEL) ;ADD NEW APPOINTMENT
 .K SDAPT S SDAPT=+$P($G(^TMP("SDEC07",$J,2)),"^") ;if appointment is made this is the appointment number ien from 409.84
 .S URL=$G(MSGARY("AILNTE"))
 .D:$L(URL) GETAPT^SDHL7APU(URL,SDCL,$G(TMPSTART)) ; If the appointment has been made in SDEC(409,84, update the url in the Hospital Location file.
 .N TMP2 S TMP2=$G(^TMP("SDEC07",$J,2))
 .I ((+$P(TMP2,"^",1)>0)&($L($P(TMP2,"^",3))<1)) S SUCCESS=1
 .I SUCCESS=0 S ERRTXT=$P($G(^TMP("SDEC07",$J,2)),"^",3)
 .I ((SUCCESS=0)&(ERRTXT="")) D
 ..S ERRTXT=$P($G(^TMP("SDEC07",$J,3)),"^",2)
 ..Q
 .I $L(ERRTXT) S ERRCND=9999
 .S DUZ(2)=$G(STA)
 .I $G(SUCCESS)>0 D
 ..N INPA S INPA(1)=$P(SDAPTYP,"|",2),INPA(2)="SA",INPA(3)=$G(DUZ),DUZ(2)=$G(STA) ;INP(1) is the IEN of the PARENT order
 ..S INPA(4)=$$FMTE^XLFDT(DT)
 ..N RET D ARCLOSE^SDECAR(.RET,.INPA) ; Dispositions the order.
 ..N RTN S INP(24)=$G(SDAPT)_"~"_$G(SDCHILD) D ARSET^SDECAR2(.RTN,.INP) ;Update files for RTC orders.
 ..N CLOSEOUT S CLOSEOUT=0 I $G(MSGARY("RTCID"))>0 S:$G(MSGARY("RTCID"))=$P($G(^SDEC(409.85,+$G(SDPARENT),3)),"^",3) CLOSEOUT=1
 ..I $G(CLOSEOUT)=1 D   ;if this is the last child close out the parent and all child orders
 ...N INP S INP(1)=+SDPARENT,INP(2)="SA",INP(3)=$G(DUZ),DUZ(2)=$G(STA)
 ...S INP(4)=$$FMTE^XLFDT(DT)
 ...D ARCLOSE^SDECAR(.RET,.INP)
 ...;Parent Appointment Request Closed now loop thru the 3 node and update each of the children to disposition of "MC"
 ...I $G(SDPARENT)>0 K X12 S X12=0 F  S X12=$O(^SDEC(409.85,SDPARENT,2,X12)) Q:X12'>0  D
 ....S INP(1)=$P(^SDEC(409.85,SDPARENT,2,X12,0),"^"),INP(2)="MC",INP(3)=$G(DUZ),DUZ(2)=$G(STA)
 ....S INP(4)=$$FMTE^XLFDT(DT)
 ....D ARCLOSE^SDECAR(.RET,.INP)
 ....Q
 ...;S $P(^SDEC(409.85,+SDPARENT,0),"^",5)="APPT"
 ...Q
 ..Q
 .Q
 ;SECAPPT ; If this is an intrafacility appointment make the second appointment
 I $$UPPER^SDUL1(MSGARY("HL7EVENT"))="S15" D
 .N XDT,%D,X,Y,SDECTYP,STARTDT
 .S SDECTYP=$G(MSGARY("CSDAPTYP")),SDECNOT=$G(MSGARY("CANREMARKS")),SDECCR=""
 .S SDUSER=$G(MSGARY("DUZ"))
 .S:$G(SDUSER)="" SDUSER=.5
 .S %DT="RXT",X=SDECSTART D ^%DT S STARTDT=Y
 .S SDECAPTID=$$GETAPP^SDHLAPT1(DFN,SDECRES,STARTDT)
 .S SDECCR=$G(MSGARY("CANCODE"))
 .S DUZ=$G(MSGARY("DUZ"))
 .S:$G(DUZ)="" DUZ=.5
 .S:$G(DUZ(2))="" DUZ(2)=$G(MSGARY("HLTHISSITE"))
 .D APPDEL^SDEC08(.SDECY,SDECAPTID,SDECTYP,$G(SDECCR),$G(SDECNOT),$G(SDECDATE),$G(SDUSER))
 .S ERRTXT=$P($G(^TMP("SDEC",$J,2)),"^")
 .I +$L(ERRTXT) S ERRCND=9999
 .D CHKCAN^SDHLAPT2(DFN,SDCL,STARTDT)
 .;N SDECDA S SDECDA=$G(AIL(1,4))
 .;S:$G(SDECDA)'="" $P(^SDEC(409.85,SDECDA,0),"^",5)="RTC"
 ;
 I +ERRCND D
 .S ERRTXT=$$ERRLKP^SDHL7APU(ERRTXT)
 .Q 
 S ERRTXT=$$STRIP^SDHL7APU(ERRTXT)
 ;S HIT=0,EXTIME=""
 ;
 ;****BUILD THE RESPONSE MSA
 K @MSGROOT
 N HLA
 ;
 D INIT^HLFNC2(EIN,.HL)
 S HL("FS")="|",HL("ECH")="^~\&"
 ;
 N ERR,LEN S ERR=""
 N FOUNDCN
 S FOUNDCN=0
 ;
 S HLA("HLA",1)="MSA"_HL("FS")_$S(ERRCND:"AE",1:"AA")_HL("FS")_HL("MID")_HL("FS")_$S(ERRCND:$E(ERRTXT,1,50),1:"")_HL("FS")
 D GENACK^HLMA1(HL("EID"),HLMTIENS,HL("EIDS"),"LM",1,.MYRESULT)
 Q
