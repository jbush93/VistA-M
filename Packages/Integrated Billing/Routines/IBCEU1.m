IBCEU1 ;ALB/TMP - EDI UTILITIES FOR EOB PROCESSING ;10-FEB-99
 ;;2.0;INTEGRATED BILLING;**137,155,296,349,371,432,473,547,608**;21-MAR-94;Build 90
 ;;Per VA Directive 6402, this routine should not be modified.
 ;
CCOB1(IBIFN,NODE,SEQ,IBRSBTST) ; Extract Claim level COB data
 ; for a bill IBIFN
 ; NODE = the file 361.1 node(s) to be returned, separated by commas
 ; SEQ = the specific insurance sequence you want returned.  If not =
 ;       1, 2, or 3, all are returned
 ; Returns IBXDATA(COB,n,node)  where COB = COB insurance sequence,
 ;  n is the entry number in file 361.1 and node is the node requested
 ;   = the requested node's data
 ; IBRSBTST=1, this indicates the claim is being resubmitted as a "TEST"
 ;             claim and should be used be the OUTPUT FORMATTER entries
 ;             to determine what COB information is going out. - IB*2*608 (vd)
 ;
 N IB,IBN,IBBILL,IBS,A,B,C,IBCURR,IBMRAF,Z,CSEQ
 ;
 K IBXDATA
 ;
 S:$G(NODE)="" NODE=1
 S IB=$P($G(^DGCR(399,IBIFN,"M1")),U,5,7)
 S IBCURR=$$COB^IBCEF(IBIFN)
 S CSEQ=$$COBN^IBCEF(IBIFN)
 ; ib*2.0*547 make sure you only set MRA flag if MRA on current sequence being checked
 ;S IBMRAF=$$MCRONBIL^IBEFUNC(IBIFN)
 S IBMRAF=$P($$MCRONBIL^IBEFUNC(IBIFN,$S(IBCURR="P":1,IBCURR="S":2,1:3)),U,2)
 ;
 S:"123"'[$G(SEQ) SEQ=""
 ;
 F B=1:1:3 S IBBILL=$P(IB,U,B) I IBBILL S C=0 F  S C=$O(^IBM(361.1,"B",IBBILL,C)) Q:'C  D
 . I '$$EOBELIG(C,IBMRAF,IBCURR) Q      ; eob not eligible for secondary claim
 . S IBS=$P($G(^IBM(361.1,C,0)),U,15)   ; insurance sequence
 . I +$G(IBRSBTST),((CSEQ=IBS)!(CSEQ<IBS)) Q   ; IB*2.0*608/vd (US2486) added to prevent COB Data from being put on Resubmitted Claims for TEST.
 . I $S('$G(SEQ):1,1:SEQ=IBS) D
 .. F Z=1:1:$L(NODE,",") D
 ... S A=$P(NODE,",",Z)
 ... Q:A=""
 ... S IBN=$G(^IBM(361.1,C,A))
 ... ; Start IB*2.0*473 BI Added to null patient responsibility in OI1
 ... ; if the data is contained at the line level to be sent in LCOB.
 ... ; Perform the following for only OI1.19 using the dictionary 364.6 IEN.
 ... S:+$G(IBX0)=2204&($$LPREXIST(C))&(A=1) $P(IBN,U,2)=""
 ... ; End IB*2.0*473
 ... I $TR(IBN,U)'="" S IBXDATA(IBS,C,A)=IBN
 ;
 Q
 ;
CCAS1(IBIFN,SEQ,IBRSBTST) ; Extract all MEDICARE COB claim level adjustment data
 ; for a bill IBIFN (subfile 361.11 in file 361.1)
 ; SEQ = the specific insurance sequence you want returned.  If not =
 ;       1, 2, or 3, all are returned
 ; Returns IBXDATA(COB,n)  where COB = COB insurance sequence,
 ;       n is the entry number in file 361.1 and
 ;       = the 0-node of the subfile entry (361.11)
 ;    and IBXDATA(COB,n,m) where m is a sequential # and
 ;                         = this level's 0-node
 ; IBRSBTST=1, this indicates the claim is being resubmitted as a "TEST"
 ;             claim and should be used be the OUTPUT FORMATTER entries
 ;             to determine what COB information is going out. - IB*2*608 (vd)
 N IB,IBA,IBS,IB0,IB00,IBBILL,B,C,D,E,CSEQ
 ;
 S IB=$P($G(^DGCR(399,IBIFN,"M1")),U,5,7)
 S:"123"'[$G(SEQ) SEQ=""
 S CSEQ=$$COBN^IBCEF(IBIFN)
 ;
 F B=1:1:3 S IBBILL=$P(IB,U,B) I IBBILL S C=0 F  S C=$O(^IBM(361.1,"B",IBBILL,C)) Q:'C  D
 . I '$$EOBELIG(C) Q      ; eob not eligible for secondary claim
 . S IBS=$P($G(^IBM(361.1,C,0)),U,15)   ; insurance sequence
 . I +$G(IBRSBTST),((CSEQ=IBS)!(CSEQ<IBS)) Q   ; IB*2.0*608/vd (US2486) added to prevent COB Data from being put on Resubmitted Claims for TEST.
 . I $S('$G(SEQ):1,1:SEQ=IBS) D
 .. S (IBA,D)=0 F  S D=$O(^IBM(361.1,C,10,D)) Q:'D  S IB0=$G(^(D,0)) D
 ... S IBXDATA(IBS,D)=IB0
 ... S (IBA,E)=0
 ... F  S E=$O(^IBM(361.1,C,10,D,1,E)) Q:'E  S IB00=$G(^(E,0)) D
 .... S IBA=IBA+1
 .... I $TR(IB00,U)'="" S IBXDATA(IBS,D,IBA)=IB00
 ;
 Q
 ;
SEQ(A) ; Translate sequence # A into corresponding letter representation
 S A=$E("PST",A)
 I $S(A'="":"PST"'[A,1:1) S A="P"
 Q A
 ;
EOBTOT(IBIFN,IBCOBN) ; Total all EOB's for a bill's COB sequence
 ; Function returns the total of all EOB's for a specific COB seq
 ; IBIFN = ien of bill in file 399
 ; IBCOBN = the # of the COB sequence you want EOB/MRA total for (1-3)
 ;
 N Z,Z0,IBTOT
 S IBTOT=0
 I $O(^IBM(361.1,"ABS",IBIFN,IBCOBN,0)) D
 . ; Set up prior payment field here from MRA/EOB(s)
 . S (IBTOT,Z)=0
 . F  S Z=$O(^IBM(361.1,"ABS",IBIFN,IBCOBN,Z)) Q:'Z  D
 .. ; HD64841 IB*2*371 - total up the payer paid amounts
 .. S IBTOT=IBTOT+$P($G(^IBM(361.1,Z,1)),U,1)
 Q IBTOT
 ;
 ;
LCOBOUT(IBXSAVE,IBXDATA,COL) ; Output the line adjustment reasons COB
 ;  line # data for an electronic claim
 ; IBXSAVE,IBXDATA = arrays holding formatter information for claim -
 ;                   pass by reference
 ; COL = the column in the 837 flat file being output for LCAS record
 N LINE,COBSEQ,RECCT,GRPCD,SEQ,RCCT,RCPC,DATA,RCREC,SEQLINE K IBXDATA
 S (LINE,RECCT)=0
 S RCPC=(COL#3) S:'RCPC RCPC=3
 S RCREC=$S(COL'<4:COL-1\3,1:0)
 ;S RCREC=$S(COL'<4:COL+5\6-1,1:0)
 F  S LINE=$O(IBXSAVE("LCOB",LINE)) Q:'LINE  D
 . S COBSEQ=0
 . F  S COBSEQ=$O(IBXSAVE("LCOB",LINE,"COB",COBSEQ)) Q:'COBSEQ  S SEQLINE=0 F  S SEQLINE=$O(IBXSAVE("LCOB",LINE,"COB",COBSEQ,SEQLINE)) Q:'SEQLINE  S GRPCD="" F  S GRPCD=$O(IBXSAVE("LCOB",LINE,"COB",COBSEQ,SEQLINE,GRPCD)) Q:GRPCD=""  D
 .. S RECCT=RECCT+1
 .. ;IB*2.0*432/TAZ Added payer sequence in piece 22 of LCAS record (parameter Z)
 .. I COL="Z" S IBXDATA(RECCT)=$E("PST",COBSEQ) I RECCT>1 D ID^IBCEF2(RECCT,"LCAS")
 .. I COL=2 S IBXDATA(RECCT)=LINE,DATA=LINE D:RECCT>1 ID^IBCEF2(RECCT,"LCAS")
 .. I COL=3 S IBXDATA(RECCT)=$TR(GRPCD," ")
 .. S (SEQ,RCCT)=0
 .. F  S SEQ=$O(IBXSAVE("LCOB",LINE,"COB",COBSEQ,SEQLINE,GRPCD,SEQ)) Q:'SEQ  I $TR($G(IBXSAVE("LCOB",LINE,"COB",COBSEQ,SEQLINE,GRPCD,SEQ)),U)'="" D
 ... S RCCT=RCCT+1
 ... Q:COL'<4&(RCCT'=RCREC)&(RCCT'>6)
 ... S DATA=$S(COL=2:LINE,COL=3:$TR(GRPCD," "),1:$P($G(IBXSAVE("LCOB",LINE,"COB",COBSEQ,SEQLINE,GRPCD,SEQ)),U,RCPC))
 ... I COL'<4,RCCT=RCREC S:DATA'="" IBXDATA(RECCT)=DATA Q
 ... I RCCT>6 S RCCT=1,RECCT=RECCT+1 D:COL=2 ID^IBCEF2(RECCT,"LCAS") I DATA'="",$S(COL'>3:1,1:RCCT=RCREC) S IBXDATA(RECCT)=DATA
 Q
 ;
CCOBOUT(IBXSAVE,IBXDATA,COL) ; Output the claim adjustment reasons COB
 ;  data for an electronic claim
 ; IBXSAVE,IBXDATA = arrays holding formatter information for claim -
 ;                   pass by reference
 ; COL = the column in the 837 flat file being output for CCAS record
 N COBSEQ,RECCT,GRPSEQ,SEQ,RCPC,RCCT,RCREC,DATA K IBXDATA
 S RECCT=0
 S RCPC=(COL#3) S:'RCPC RCPC=3
 S RCREC=$S(COL'<4:COL+5\6-1,1:0)
 S COBSEQ=0
 F  S COBSEQ=$O(IBXSAVE("CCAS",COBSEQ)) Q:'COBSEQ  S GRPSEQ="" F  S GRPSEQ=$O(IBXSAVE("CCAS",COBSEQ,GRPSEQ)) Q:GRPSEQ=""  D
 . S RECCT=RECCT+1
 . I COL=2 S IBXDATA(RECCT)=COBSEQ D:RECCT>1 ID^IBCEF2(RECCT,"CCAS")
 . I COL=3 S IBXDATA(RECCT)=$P($G(IBXSAVE("CCAS",COBSEQ,GRPSEQ)),U)
 . S (SEQ,RCCT)=0
 . F  S SEQ=$O(IBXSAVE("CCAS",COBSEQ,GRPSEQ,SEQ)) Q:'SEQ  I $TR($G(IBXSAVE("CCAS",COBSEQ,GRPSEQ,SEQ)),U)'="" D
 .. S RCCT=RCCT+1
 .. Q:COL'<4&(RCCT'=RCREC)&(RCCT'>6)
 .. S DATA=$S(COL=2:COBSEQ,COL=3:$P($G(IBXSAVE("CCAS",COBSEQ,GRPSEQ)),U),1:$P($G(IBXSAVE("CCAS",COBSEQ,GRPSEQ,SEQ)),U,RCPC))
 .. I COL'<4,RCCT=RCREC S:DATA'="" IBXDATA(RECCT)=DATA Q
 .. I RCCT>6 S RCCT=1,RECCT=RECCT+1 D:COL=2 ID^IBCEF2(RECCT,"CCAS") I DATA'="",$S(COL'>3:1,1:RCCT=RCREC) S IBXDATA(RECCT)=DATA
 Q
 ;
COBOUT(IBXSAVE,IBXDATA,CL) ; build LCOB segment data
 ; The IBXSAVE array used here is built by INS-2, then LCOB-1.9
 ; This is basically the 361.115, but all the piece numbers here in this
 ; local array are one higher than the pieces in subfile 361.115.
 N Z,M,N,P,PCCL
 S (N,Z)=0
 F  S Z=$O(IBXSAVE("LCOB",Z)) Q:'Z  D
 . S M=0 F  S M=$O(IBXSAVE("LCOB",Z,"COB",M)) Q:'M  D
 .. S P=0 F  S P=$O(IBXSAVE("LCOB",Z,"COB",M,P)) Q:'P  D
 ... S N=N+1
 ... I CL="Z" S IBXDATA(N)=$E("PST",M) Q
 ... S PCCL=$P($G(IBXSAVE("LCOB",Z,"COB",M,P)),U,CL)
 ... ;IB*2.0*432/TAZ - If the revenue code is blank for the EOB get it from the Primary Level
 ... I PCCL="",CL=11 S PCCL=$P($G(IBXSAVE("LCOB",Z)),U)
 ... S:PCCL'="" IBXDATA(N)=PCCL
 Q
 ;
 ;IB*2.0*432/TAZ - XCOBOUT is the original code which did not capture all the LCOB records.
XCOBOUT(IBXSAVE,IBXDATA,CL) ; build LCOB segment data
 ; The IBXSAVE array used here is built by INS-2, then LCOB-1.9
 ; This is basically the 361.115, but all the piece numbers here in this
 ; local array are one higher than the pieces in subfile 361.115.
 N Z,M,N,P,PCCL
 S (N,Z,P)=0 F  S Z=$O(IBXSAVE("LCOB",Z)) Q:'Z  D
 . S N=N+1
 . S M=$O(IBXSAVE("LCOB",Z,"COB",""),-1) Q:'M
 . S P=$O(IBXSAVE("LCOB",Z,"COB",M,""),-1) Q:'P
 . ;IB*2.0*432/TAZ Added Payer Sequence to piece 18 of the LCOB record
 . I CL="Z" S IBXDATA(N)=$E("PST",M) Q
 . S PCCL=$P($G(IBXSAVE("LCOB",Z,"COB",M,P)),U,CL)
 . S:PCCL'="" IBXDATA(N)=PCCL
 . Q
 Q
 ;
COBPYRID(IBXIEN,IBXSAVE,IBXDATA) ; cob insurance company payer id
 N CT,N,NUM,Z
 K IBXDATA
 I '$D(IBXSAVE("LCOB")) G COBPYRX
 ;
 ;IB*2.0*432/TAZ - Replaced following code with loop to insure that all LCOB records have the Payer ID
 ;D ALLPAYID^IBCEF2(IBXIEN,.NUM,1)
 ;S NUM=$G(NUM(1))
 ;S NUM=$E(NUM_$J("",5),1,5)
 ;S (CT,N)=0
 ;F  S N=$O(IBXSAVE("LCOB",N)) Q:'N  S CT=CT+1,IBXDATA(CT)=NUM
 ;
 D ALLPAYID^IBCEF2(IBXIEN,.NUM)
 S (CT,N)=0
 F  S N=$O(IBXSAVE("LCOB",N)) Q:'N  D
 . S Z=0
 . F  S Z=$O(IBXSAVE("LCOB",N,"COB",Z)) Q:'Z  D
 .. S CT=CT+1,IBXDATA(CT)=$G(NUM(Z))
COBPYRX ;
 Q
 ;
EOBELIG(IBEOB,IBMRAF,IBCURR) ; EOB eligibility for secondary claim
 ; Function to decide if EOB entry in file 361.1 (ien=IBEOB) is
 ; eligible to be included for secondary claim creation process
 ; The EOB is not eligible if the review status is not 3, or if there
 ; is no insurance sequence indicator, or if the EOB has been DENIED
 ; and the patient responsibility for that EOB is $0 and that EOB is
 ; not a split EOB.  Split EOB's need to be included (IB*2*371).
 ;
 ; 432 - added new flag IBMRAF to indicate if we need to check only MRA's or all EOB's
 ; IBMRAF = 1 if only need MRA EOB's
 ;
 NEW ELIG,IBDATA,PTRESP
 S ELIG=0
 ; IB*2.0*432/TAZ Get current Payer sequence if not passed in.
 I '$G(IBCURR) S IBCURR=$$COB^IBCEF(IBIFN)
 I '$G(IBEOB) G EOBELIGX
 S IBDATA=$G(^IBM(361.1,IBEOB,0))
 I $G(IBMRAF)=1,$P(IBDATA,U,4)'=1 G EOBELIGX      ; Only MRA EOB's for now if flag = 1
 I $D(^IBM(361.1,IBEOB,"ERR")) G EOBELIGX     ; filing error
 I $P(IBDATA,U,16)'=3 G EOBELIGX     ; review status - accepted-complete
 I '$P(IBDATA,U,15) G EOBELIGX       ; insurance sequence must exist
 ; IB*2.0*432/TAZ Don't send EOB data for current payer
 I $P(IBDATA,U,15)=IBCURR G EOBELIGX ; Don't send EOB data for current payer (this is for retransmits)
 S PTRESP=$P($G(^IBM(361.1,IBEOB,1)),U,2)     ; Pt Resp Amount for 1500s
 I $$FT^IBCEF(+IBDATA)=3 S PTRESP=$$PTRESPI^IBCECOB1(IBEOB)  ; for UBs
 I PTRESP'>0,$P(IBDATA,U,13)=2,'$$SPLIT^IBCEMU1(IBEOB) G EOBELIGX     ; Denied & No Pt. Resp. & not a split MRA
 ;
 S ELIG=1
EOBELIGX ;
 Q ELIG
 ;
EOBCNT(IBIFN) ; This function counts up the number of EOBs that are eligible
 ; for the secondary claim creation process for a given bill#.
 NEW CNT,IEN
 S (CNT,IEN)=0
 F  S IEN=$O(^IBM(361.1,"B",+$G(IBIFN),IEN)) Q:'IEN  D
 . I $$EOBELIG(IEN) S CNT=CNT+1
 . Q
EOBCNTX ;
 Q CNT
 ;
LPTRESP(IBIFN,IBXSAVE,IBXDATA,CL)  ; Line level patient responsibility.
 ; Added with IB*2.0*473 BI
 N IBPTZ,IBPTM,IBPTP,IBPTPR,IBPRDATA,IBPTCNT
 S:'$D(CL) CL=17
 S IBPTCNT=0
 S IBPTZ=0 F  S IBPTZ=$O(IBXSAVE("LCOB",IBPTZ)) Q:'IBPTZ  D
 . S IBPTM=0 F  S IBPTM=$O(IBXSAVE("LCOB",IBPTZ,"COB",IBPTM)) Q:'IBPTM  D
 .. S IBPTP=0 F  S IBPTP=$O(IBXSAVE("LCOB",IBPTZ,"COB",IBPTM,IBPTP)) Q:'IBPTP  D
 ... S IBPTCNT=IBPTCNT+1
 ... I $$CHKCCOB1(IBIFN,IBPTM) S IBXDATA(IBPTCNT)="" Q
 ... I CL=16 S IBXDATA(IBPTCNT)="EAF" Q
 ... S IBXDATA(IBPTCNT)=0
 ... S IBPTPR=0 F  S IBPTPR=$O(IBXSAVE("LCOB",IBPTZ,"COB",IBPTM,IBPTP,"PR",IBPTPR)) Q:'IBPTPR  D
 .... S IBPRDATA=$G(IBXSAVE("LCOB",IBPTZ,"COB",IBPTM,IBPTP,"PR",IBPTPR))
 .... I +IBPRDATA S IBXDATA(IBPTCNT)=IBXDATA(IBPTCNT)+$P(IBPRDATA,U,2)
 ... S IBXDATA(IBPTCNT)=$$DOLLAR^IBCEFG1(IBXDATA(IBPTCNT))
 Q
 ;
LPREXIST(EOBIEN)  ; Tests to see if Line Level Patient Responsibility Segments exists.
 ; Added with IB*2.0*473 BI
 N CL,CAS,PR,PRSEQ,PRZ,RESULT
 S RESULT=0
 Q:'$G(EOBIEN) RESULT
 S CL=0 F  S CL=$O(^IBM(361.1,EOBIEN,15,CL)) Q:+CL=0  D
 . S CAS=0 F  S CAS=$O(^IBM(361.1,EOBIEN,15,CL,CAS)) Q:+CAS=0  D
 .. S PR=$O(^IBM(361.1,EOBIEN,15,CL,CAS,"B","PR",0)) Q:+PR=0
 .. S PRSEQ=0 F  S PRSEQ=$O(^IBM(361.1,EOBIEN,15,CL,CAS,PR,1,PRSEQ)) Q:+PRSEQ=0  D
 ... S PRZ=$G(^IBM(361.1,EOBIEN,15,CL,CAS,PR,1,PRSEQ,0)) Q:'+PRZ
 ... S RESULT=1
 Q RESULT
 ;
CHKCCOB1(IBIFN,IBS)  ; Test to see if Patient Responsibility pieces should be included
 ; Added with IB*2.0*473 BI
 N RESULTS,IBXDATA,EOBIEN
 S RESULTS=1
 ; INPUTS:  IBIFN - BILL/CLAIM INTERNAL NUMBER
 ;          IBS   - INSURANCE SEQUENCE NUMBER
 ; RETURNS: 0     - IF LCOB RECORDS ARE TO BE INCLUDED
 ;          1     - IF LCOB RECORDS SHOULD NOT BE INCLUDED
 D CCOB1(IBIFN,0,IBS)
 S EOBIEN=$O(IBXDATA(IBS,0))
 S RESULT='$$LPREXIST(EOBIEN)
 Q RESULT
 ;
 ;/IB*2*608 (vd) (US2486) - Added this module of code to be referenced by the Output Formatter.
CKCOBTST(IBXIEN,IBXSAVE,Z0,Z,IBRSBTST)  ; Check Primary, Secondary & Tertiary COBS for Claims Resubmitted as Test.
 ; INPUT:  IBXIEN   - Current Claim number
 ;         IBXSAVE  - Array containing current claim COB data.
 ;         Z0       - Will equal "INPT", "OUTPT" or "RX"
 ;         Z        - Is the LINE
 N A,CURSEQ,XX
 I '+$G(IBRSBTST) M IBXSAVE("LCOB",Z)=IBXSAVE(Z0,Z) Q  ; Only concerned with Claims that are Resubmitted as Test.
 S A="",CURSEQ=$$COBN^IBCEF(IBXIEN)
 ; With the line below, ideally, we want to merge all of IBXSAVE(Z0,Z) into IBXSAVE("LCOB",Z),
 ; but the COB node should be handled separately for the current sequence.
 S IBXSAVE("LCOB",Z)=IBXSAVE(Z0,Z)
 S XX="" F  S XX=$O(IBXSAVE(Z0,Z,XX)) Q:XX=""  I XX'="COB" M IBXSAVE("LCOB",Z,XX)=IBXSAVE(Z0,Z,XX)
 ; Now handle the COB node for the current sequence.
 F  S A=$O(IBXSAVE(Z0,Z,"COB",A)) Q:A=""  D   ; Only want to merge those COBS that are previous to the current
 . I (CURSEQ=A)!(CURSEQ<A) Q   ; Only want to merge those COBS that are previous to the current sequence.
 . M IBXSAVE("LCOB",Z,"COB",A)=IBXSAVE(Z0,Z,"COB",A)
 Q
 ;
