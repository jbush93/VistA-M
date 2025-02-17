GMPL1 ; SLC/MKB/AJB/TC -- Problem List actions ;10/04/17  06:46
 ;;2.0;Problem List;**3,20,28,43,42,45,49**;Aug 25, 1994;Build 43
 ; 10 MAR 2000 - MA - Added to the routine another user prompt
 ; to backup and refine Lexicon search if ICD code 799.9 or R69.
ADD ;add new entry to list - Requires GMPDFN
 N GMPROB,GMPTERM,GMPICD,Y,DUP,GMPIMPDT W !
 S GMPIMPDT=$$IMPDATE^LEXU("10D")
 S GMPROB=$$TEXT^GMPLEDT4("") I GMPROB="^" S GMPQUIT=1 Q
 I 'GMPARAM("CLU")!('$D(GMPLUSER)&('$D(^XUSEC("GMPL ICD CODE",DUZ)))) S GMPTERM="",GMPICD=$S(DT<GMPIMPDT:"799.9",1:"R69.") G ADD1
 F  D  Q:$D(GMPQUIT)!(+$G(Y))
 . D SEARCH^GMPLX(.GMPROB,.Y,"PROBLEM: ","1")
 . I +Y'>0 S GMPQUIT=1 Q
 . S DUP=$$DUPL^GMPLX(+GMPDFN,+Y,GMPROB)
 . I DUP,'$$DUPLOK^GMPLX(DUP) S (Y,GMPROB)=""
 . I +Y=1 D ICDMSG
 Q:$D(GMPQUIT)
 S GMPTERM=$S(+$G(Y)>1:Y,1:""),GMPICD=$G(Y(1))
 S:'$L(GMPICD) GMPICD=$S(DT<GMPIMPDT:"799.9",1:"R69.")
ADD1 ; set up default values
 ; -- May enter here with GMPROB=text,GMPICD=code,GMPTERM=#^term
 ; added for Code Set Versioning (CSV)
 N I,GMPSTAT,GMPCSREC,GMPCSPTR,GMPCSNME,GMPSCTC,GMPSCTD,GMPTXT,GMPTYP,GMPNUM,GMPQT,GMPSYN
 S (GMPSCTC,GMPSCTD,GMPTXT,GMPTYP)="",(GMPNUM,GMPQT)=0
 I GMPICD["/" F I=1:1:$L(GMPICD,"/") D  Q:GMPSTAT
 . N GMPCODE S GMPCODE=$P(GMPICD,"/",I),GMPSTAT=0
 . S GMPCSREC=$$CODECS^ICDEX(GMPCODE,80,DT),GMPCSPTR=$P(GMPCSREC,U),GMPCSNME=$P(GMPCSREC,U,2)
 . S:'+$$STATCHK^ICDXCODE(GMPCSPTR,GMPCODE,DT) GMPSTAT=1
 E  D
 . S GMPSTAT=0,GMPCSREC=$$CODECS^ICDEX(GMPICD,80,DT),GMPCSPTR=$P(GMPCSREC,U),GMPCSNME=$P(GMPCSREC,U,2)
 . S:'+$$STATCHK^ICDXCODE(GMPCSPTR,GMPICD,DT) GMPSTAT=1
 I GMPSTAT W !,GMPROB,!,"has an inactive ICD code.  Please edit before adding." H 3 Q
 I (GMPROB["(SCT"),(GMPROB[")") D
 . S GMPSCTC=$$ONE^LEXU(+GMPTERM,DT,"SCT")
 . I 'GMPSCTC S GMPSCTC=$P($P(GMPROB,"SCT ",2),")")
 . S GMPTXT=$$STRIPSPC^GMPLX($$TRIM^XLFSTR($RE($P($RE(GMPROB),"(",2,99))))
 . S GMPSCTD=$$GETSYN^LEXTRAN1("SCT",GMPSCTC,DT,"GMPSYN",1,1)
 . I $P(GMPSCTD,U)'=1 S GMPSCTD="" Q
 . F  S GMPTYP=$O(GMPSYN(GMPTYP)) Q:GMPTYP=""!(GMPQT)  D
 . . I GMPTYP="S" F  S GMPNUM=$O(GMPSYN(GMPTYP,GMPNUM)) Q:GMPNUM=""!(GMPQT)  D
 . . . I $$STRIPSPC^GMPLX($P(GMPSYN(GMPTYP,GMPNUM),U))=GMPTXT S GMPSCTD=$P(GMPSYN(GMPTYP,GMPNUM),U,3),GMPQT=1 Q
 . . I (GMPNUM=""),(GMPSCTD="") S GMPQT=1 Q
 . . Q:GMPQT
 . . I $$STRIPSPC^GMPLX($P(GMPSYN(GMPTYP),U))=GMPTXT S GMPSCTD=$P(GMPSYN(GMPTYP),U,3),GMPQT=1 Q
 N OK,GMPI,GMPFLD K GMPLJUMP,GMPSYN
 S GMPFLD(1.01)=GMPTERM,GMPFLD(.05)=U_GMPROB
 S GMPFLD(.01)=$P($$ICDDATA^ICDXCODE(GMPCSPTR,$P(GMPICD,"/"),DT,"E"),U)_U_GMPICD
 S GMPFLD(80202)=$$SAB^ICDEX(GMPCSPTR,DT)_U_$G(GMPCSNME)
 S:'GMPFLD(.01)!($P(GMPFLD(.01),U)<0) GMPFLD(.01)=$$NOS^GMPLX($P(GMPFLD(80202),U),DT) ; cannot resolve code
 S (GMPFLD(1.04),GMPFLD(1.05))=$G(GMPROV),GMPFLD(1.03)=DUZ
 S GMPFLD(1.06)=$$SERVICE^GMPLX1(+GMPFLD(1.04)),GMPFLD(1.08)=$G(GMPCLIN)
 S (GMPFLD(.08),GMPFLD(80201),GMPFLD(1.09))=DT_U_$$EXTDT^GMPLX(DT)
 S GMPFLD(.12)="A^ACTIVE",GMPFLD(1.14)="",GMPFLD(10,0)=0
 S GMPFLD(1.02)=$S('$G(GMPARAM("VER")):"P",$D(GMPLUSER):"P",1:"T")
 S (GMPFLD(.13),GMPFLD(1.07))="" ; initialize dates
 S GMPFLD(1.1)=$S('GMPSC:"0^NO",1:""),GMPFLD(1.11)=$S('GMPAGTOR:"0^NO",1:"")
 S GMPFLD(1.12)=$S('GMPION:"0^NO",1:""),GMPFLD(1.13)=$S('GMPGULF:"0^NO",1:"")
 S GMPFLD(80001)=GMPSCTC_U_GMPSCTC,GMPFLD(80002)=GMPSCTD_U_GMPSCTD
ADD2 ; prompt for values
 D FLDS^GMPLEDT3 ; set GMPFLD("FLD") of editable fields
 F GMPI=2:1:7 D @(GMPFLD("FLD",GMPI)_"^GMPLEDT1") Q:$D(GMPQUIT)  K GMPLJUMP ; cannot ^-jump here
 Q:$D(GMPQUIT)
ADD3 ; Ok to save?
 S OK=$$ACCEPT^GMPLDIS1(.GMPFLD),GMPLJUMP=0 ; ok to save values?
 I OK="^" W !!?10,"< Nothing Saved !! >",! S GMPQUIT=1 H 1 Q
 I OK D  Q  ; ck DA for error?
 . N I W !!,"Saving ..." D NEW^GMPLSAVE
 . S I=$S(GMPLIST(0)'>0:1,GMPARAM("REV"):$O(GMPLIST(0))-.01,1:GMPLIST(0)+1)
 . S GMPLIST(I)=DA,GMPLIST("B",DA)=I,GMPLIST(0)=$G(GMPLIST(0))+1
 . W " done."
 ; Not ok -- edit values, ask again
 F GMPI=1:1:GMPFLD("FLD",0) D @(GMPFLD("FLD",GMPI)_"^GMPLEDT1") Q:$D(GMPQUIT)!($D(GMPSAVED))  I $G(GMPLJUMP) S GMPI=GMPLJUMP-1 S GMPLJUMP=0 ; reset GMPI to desired fld
 Q:$D(DTOUT)  K GMPQUIT,DUOUT G ADD3
 Q
 ;
 ; *********************************************************************
 ; *  GMPIFN expected for the following calls:
 ;
STATUS ; -- inactivate problem
 N DIE,DA,DR,X,Y,CHNGE,GMPFLD,PROMPT,DEFAULT
 S GMPFLD(.13)=$P($G(^AUPNPROB(GMPIFN,0)),U,13) ; Onset
 W !!,$$PROBTEXT^GMPLX(GMPIFN) D RESOLVED^GMPLEDT4 Q:$D(GMPQUIT)
 S PROMPT="COMMENT (<60 char): ",DEFAULT="" D EDNOTE^GMPLEDT4 Q:$D(GMPQUIT)
 W ! I Y'="" S GMPFLD(10,"NEW",1)=Y D NEWNOTE^GMPLSAVE W "."
 S DIE="^AUPNPROB(",DR=".12///I;1.07////"_$P($G(GMPFLD(1.07)),U)
 S DA=GMPIFN D ^DIE W "."
 S CHNGE=GMPIFN_"^.12^"_$$HTFM^XLFDT($H)_U_DUZ_"^A^I^^"_+$G(GMPROV)
 D AUDIT^GMPLX(CHNGE,"") W "." ; audit trail
 D DTMOD^GMPLX(GMPIFN) W "." ; update Dt Last Mod
 W "... inactivated!",!
 H 1 S GMPSAVED=1
 Q
 ;
NEWNOTE ; -- add a new comment
 N GMPFLD
 W !!,$$PROBTEXT^GMPLX(GMPIFN)
 D NOTE^GMPLEDT1 Q:$D(GMPQUIT)!($D(GMPFLD(10,"NEW"))'>9)
 D NEWNOTE^GMPLSAVE,DTMOD^GMPLX(GMPIFN)
 S GMPSAVED=1
 Q
 ;
DELETE ; -- delete a problem
 N PROMPT,DEFAULT,X,Y,CHNGE,GMPFLD
 W !!,$$PROBTEXT^GMPLX(GMPIFN)
 S PROMPT="REASON FOR REMOVAL: ",DEFAULT=""
 D EDNOTE^GMPLEDT4 Q:$D(GMPQUIT)  W !
 I Y'="" S GMPFLD(10,"NEW",1)=Y D NEWNOTE^GMPLSAVE W "."
 S CHNGE=GMPIFN_"^1.02^"_$$HTFM^XLFDT($H)_U_DUZ_"^P^H^Deleted^"_+$G(GMPROV)
 S $P(^AUPNPROB(GMPIFN,1),U,2)="H",GMPSAVED=1 W "."
 D AUDIT^GMPLX(CHNGE,""),DTMOD^GMPLX(GMPIFN) W "."
 W "... removed!",! H 1
 Q
 ;
VERIFY ; -- verify a transcribed problem, if parameter on
 N NOW,CHNGE S NOW=$$HTFM^XLFDT($H)
 W !!,$$PROBTEXT^GMPLX(GMPIFN),!
 I '$$CODESTS^GMPLX(GMPIFN,DT) W "has an inactive ICD code. Edit the problem before verification.",! H 2 Q
 I $P($G(^AUPNPROB(GMPIFN,1)),U,2)'="T" W "does not require verification.",! H 2 Q
 L +^AUPNPROB(GMPIFN,0):1 I '$T W $C(7),$$LOCKED^GMPLX,! H 2 Q
 S $P(^AUPNPROB(GMPIFN,1),U,2)="P",GMPSAVED=1 W "."
 S CHNGE=GMPIFN_"^1.02^"_NOW_U_DUZ_"^T^P^Verified^"_DUZ W "."
 D AUDIT^GMPLX(CHNGE,""),DTMOD^GMPLX(GMPIFN) W "."
 L -^AUPNPROB(GMPIFN,0) W " verified.",!
 Q
ICDMSG ; If Lexicon returns ICD code 799.9 or R69.
 N DIR,DTOUT,DUOUT,GMPLY,GMPROB,GMPCODE,GMPDESC,GMPIMPDT
 S GMPIMPDT=$$IMPDATE^LEXU("10D"),GMPCODE=$S(DT<GMPIMPDT:"799.9",1:"R69. ")
 S GMPDESC=$S(GMPCODE="799.9":"OTHER UNKNOWN AND UNSPECIFIED CAUSE OF MORBIDITY OR MORTALITY",1:"ILLNESS, UNSPECIFIED")
 S DIR(0)="YAO"
 S DIR("A",1)="<< If you PROCEED WITH THIS NON SPECIFIC TERM, an ICD CODE OF"_GMPCODE_" >>"
 I GMPCODE="799.9" D
 . S DIR("A",2)="<< "_GMPDESC_"    >>"
 . S DIR("A",3)="<< will be assigned.  Adding more specificity to your diagnosis may >>"
 . S DIR("A",4)="<< allow a more accurate ICD code.                                  >>"
 . S DIR("A",5)=""
 E  D
 . S DIR("A",2)="<< "_GMPDESC_" will be assigned.  Adding more specificity  >>"
 . S DIR("A",3)="<< to your diagnosis may allow a more accurate ICD code.            >>"
 . S DIR("A",4)=""
 S DIR("A")="Continue (YES/NO) ",DIR("B")="NO"
 S DIR("T")=DTIME
 D ^DIR
 I $D(DTOUT)!$D(DUOUT) S Y=0
 I +Y=0 S (GMPLY,GMPROB)=""
 Q
