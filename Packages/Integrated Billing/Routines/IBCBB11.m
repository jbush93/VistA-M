IBCBB11 ;ALB/AAS/OIFO-BP/PIJ - CONTINUATION OF EDIT CHECK ROUTINE ;12 Jun 2006  3:45 PM
 ;;2.0;INTEGRATED BILLING;**51,343,363,371,395,392,401,384,400,436,432,516,550,577,568,591,592**;21-MAR-94;Build 58
 ;;Per VA Directive 6402, this routine should not be modified.
 ;
WARN(IBDISP) ; Set warning in global
 ; DISP = warning text to display
 ;
 N Z
 S Z=+$O(^TMP($J,"BILL-WARN",""),-1)
 I Z=0 S ^TMP($J,"BILL-WARN",1)=$J("",5)_"**Warnings**:",Z=1
 S Z=Z+1,^TMP($J,"BILL-WARN",Z)=$J("",5)_IBDISP
 Q
 ;
MULTDIV(IBIFN,IBND0) ; Check for multiple divisions on a bill ien IBIFN
 ; IBND0 = 0-node of bill
 ;
 ;  Function returns 1 if more than 1 division found on bill
 N Z,Z0,Z1,MULT
 S MULT=0,Z1=$P(IBND0,U,22)
 I Z1 D
 . S Z=0 F  S Z=$O(^DGCR(399,IBIFN,"RC",Z)) Q:'Z  S Z0=$P(^(Z,0),U,7) I Z0,Z0'=Z1 S MULT=1 Q
 . S Z=0 F  S Z=$O(^DGCR(399,IBIFN,"CP",Z)) Q:'Z  S Z0=$P(^(Z,0),U,6) I Z0,Z0'=Z1 S MULT=2 Q
 I 'Z1 S MULT=3
 Q MULT
 ;
 ;; PREGNANCY DX CODES: V22**-V24**, V27**-V28**, 630**-677**
 ;; FLU SHOTS PROCEDURE CODES: 90724, G0008, 90732, G0009
 ;
NPICHK ; Check for required NPIs
 N IBNPIS,IBNONPI,IBNPIREQ,Z,IBNFI,IBTF,IBWC,IBXSAVE,IBPRV,IBLINE,IBPRVNT1,IBPRVNT2
 ;*** pij start IB*20*436 ***
 N IBRATYPE,IBLEGAL
 S (IBRATYPE,IBLEGAL)=""
 S IBRATYPE=$P($G(^DGCR(399,IBIFN,0)),U,7)
 ; Legal types for this use.
 ;  7=NO FAULT INS.
 ; 10=TORT FEASOR
 ; 11=WORKERS' COMP.
 S IBNFI=$O(^DGCR(399.3,"B","NO FAULT INS.",0)) S:'IBNFI IBNFI=7
 S IBTF=$O(^DGCR(399.3,"B","TORT FEASOR",0)) S:'IBTF IBTF=10
 S IBWC=$O(^DGCR(399.3,"B","WORKERS' COMP.",0)) S:'IBWC IBWC=11
 ;
 I IBRATYPE=IBNFI!(IBRATYPE=IBTF)!(IBRATYPE=IBWC) D
 . ; One of the legal types - force local print
 . S IBLEGAL=1
 ;*** pij end ***
 S IBNPIREQ=$$NPIREQ^IBCEP81(DT)  ; Check if NPI is required
 ; Check providers
 ; IB*2.0*432 changed the NPI check to the new Provider Array
 ;S IBNPIS=$$PROVNPI^IBCEF73A(IBIFN,.IBNONPI)
 D ALLIDS^IBCEFP(IBIFN,.IBXSAVE,1)
 S IBPRV=""
 F  S IBPRV=$O(IBXSAVE("PROVINF",IBIFN,"C",1,IBPRV)) Q:'IBPRV  D
 . I $P($G(IBXSAVE("PROVINF",IBIFN,"C",1,IBPRV,0)),U,4)="" S IBNONPI(IBPRV)=""
 S IBLINE=""
 F  S IBLINE=$O(IBXSAVE("L-PROV",IBIFN,IBLINE)) Q:'IBLINE  D
 . S IBPRV=""
 . F  S IBPRV=$O(IBXSAVE("L-PROV",IBIFN,IBLINE,"C",1,IBPRV)) Q:IBPRV=""  D
 .. I $P($G(IBXSAVE("L-PROV",IBIFN,IBLINE,"C",1,IBPRV,0)),U,4)="" S IBNONPI(IBPRV)=""
 I $D(IBNONPI) S IBPRV="" F  S IBPRV=$O(IBNONPI(IBPRV)) Q:'IBPRV  D
 . ;JWS;IB*2.0*592;Assistant Surgeon for dental
 . I IBPRV=6 S IBER=IBER_"IB358;" Q
 . S IBER=IBER_"IB"_(140+IBPRV)_";" Q  ; If required, set error IB*2*516
 ; Check organizations
 S IBNONPI=""
 S IBNPIS=$$ORGNPI^IBCEF73A(IBIFN,.IBNONPI)
 I $L(IBNONPI) F Z=1:1:$L(IBNONPI,U) D
 . S IBER=IBER_$P("IB339;^IB340;^IB341;",U,$P(IBNONPI,U,Z))  ; DEM;432 Added NPI errors.
 Q
 ;
TAXCHK ; Check for required taxonomies
 N IBDT,IBLINE,IBNOTAX,IBNOTAX1,IBNOTAX2,IBPRV,IBTAXS,IBXSAVE,Z
 ;
 ; MRD;IB*2.0*516 - This check is now moot; 'today' is always on or
 ; after May 23, 2008, so taxonomy codes are always required
 ; for certain providers.
 ;S IBTAXREQ=$$TAXREQ^IBCEP81(DT)  ; Check if taxonomy is required
 ;
 ; Check providers
 ; IB*2.0*432 changed the Taxonomy check to the new Provider Array
 ;S IBTAXS=$$PROVTAX^IBCEF73A(IBIFN,.IBNOTAX)
 D ALLIDS^IBCEFP(IBIFN,.IBXSAVE,1)
 ;JWS;IB*2.0*592; prevent having both RENDERING and ASSISTANT SURGEON providers at the claim level
 ;   ;performing check here after providers are 'merged' into the claim level, if only at line level
 ;   ;done in ALLIDS^IBCEFP
 I $$FT^IBCEF(IBIFN)=7 D
 . I $D(IBXSAVE("PROVINF",IBIFN,"C",1,3)),$D(IBXSAVE("PROVINF",IBIFN,"C",1,6)) D
 .. I '$F(IBER,"IB363;") S IBER=IBER_"IB363;"
 .. Q
 . ;JWS;IB*2.0*592 - US1108 start
 . I '$D(IBXSAVE("PROVINF",IBIFN,"C",1,3)),'$D(IBXSAVE("PROVINF",IBIFN,"C",1,6)) D
 .. N IBX,OK S OK=0,IBX=""
 .. F  S IBX=$O(IBXSAVE("L-PROV",IBX)) Q:IBX=""  D  Q:OK
 ... I $D(IBXSAVE("L-PROV",IBX,"C",1,3)) S OK=1 Q
 ... I $D(IBXSAVE("L-PROV",IBX,"C",1,6)) S OK=1 Q
 .. I 'OK S IBER=IBER_"IB357;"
 .. Q
 . Q
 ;JWS;IB*2.0*592 - US1108 end
 S IBPRV=""
 F  S IBPRV=$O(IBXSAVE("PROVINF",IBIFN,"C",1,IBPRV)) Q:'IBPRV  D
 . I $G(IBXSAVE("PROVINF",IBIFN,"C",1,IBPRV,"TAXONOMY"))="" D
 .. S IBNOTAX(IBPRV)=""
 .. S IBNOTAX1=$P(IBXSAVE("PROVINF",IBIFN,"C",1,IBPRV),";",1)  ; New variables IBNOTAX1 and IBNOTAX2 for IB*2.0*568 - Deactivated Provider 
 .. S IBNOTAX2(IBPRV,IBNOTAX1)=""
 .. Q
 . Q
 ;
 S IBLINE=""
 F  S IBLINE=$O(IBXSAVE("L-PROV",IBIFN,IBLINE)) Q:'IBLINE  D
 . S IBPRV=""
 . F  S IBPRV=$O(IBXSAVE("L-PROV",IBIFN,IBLINE,"C",1,IBPRV)) Q:IBPRV=""  D
 .. I $G(IBXSAVE("L-PROV",IBIFN,IBLINE,"C",1,IBPRV,"TAXONOMY"))="" D
 ... S IBNOTAX(IBPRV)=""
 ... S IBNOTAX1=$P(IBXSAVE("L-PROV",IBIFN,IBLINE,"C",1,IBPRV),";",1)  ; New variables IBNOTAX1 and IBNOTAX2 for IB*2.0*568 - Deactivated Provider 
 ... S IBNOTAX2(IBPRV,IBNOTAX1)=""
 ... Q
 .. Q
 . Q
 ;
 ; IB251 = Referring provider taxonomy missing.
 ; IB253 = Rendering provider taxonomy missing.
 ; IB254 = Attending provider taxonomy missing.
 ; IB256 = Assistant Surgeon taxonomy missing.  ;JWS;IB*2.0*592
 ;JWS;IB*2.0*592;dental start
 I $D(IBNOTAX) S IBPRV="" F  S IBPRV=$O(IBNOTAX(IBPRV)) Q:'IBPRV  D
 . ; Only Referring, Rendering and Attending are currently sent to the payer
 . ;I IBTAXREQ,"134"[IBPRV S IBER=IBER_"IB"_(250+IBPRV)_";" Q  ; MRD;IB*2.0*516 - Always required.
 . I "134"[IBPRV D  Q
 .. S IBER=IBER_"IB"_(250+IBPRV)_";" ; If required, set error
 .. S IBPRVNT1=$O(IBNOTAX2(IBPRV,"")) ; New check for Deactivated Provider IB*2.0*568 next three lines
 .. S IBPRVNT2=$$SPEC^IBCEU(IBPRVNT1,IBEVDT)
 .. I '$G(IBPRVNT2) D WARN($P("Referring^Operating^Rendering^Attending^Supervising^^^^Other",U,IBPRV)_" Provider PERSON CLASS/taxonomy was not active at DOS.")  ; set warning
 . D WARN("Taxonomy for the "_$P("referring^operating^rendering^attending^supervising^^^^other",U,IBPRV)_" provider has no value")  ; Else, set warning
 . Q
 ;JWS;IB*2.0*592;end
 ;
 ; Check organizations.  The function ORGTAX will set IBNOTAX to be a
 ; list of entities missing taxonomy codes, if any (n, n^m, n^m^p,
 ; where each 1 is service facility, 2 is non-VA service facility and
 ; 3 is billing provider.
 ;
 S IBNOTAX=""
 S IBTAXS=$$ORGTAX^IBCEF73A(IBIFN,.IBNOTAX)
 I $L(IBNOTAX) F Z=1:1:$L(IBNOTAX,U) D
 . ; IB167 = Billing Provider taxonomy missing.
 . ;I IBTAXREQ,$P(IBNOTAX,U,Z)=3 S IBER=IBER_"IB167;" Q  ; MRD;IB*2.0*516 - Always required.
 . I $P(IBNOTAX,U,Z)=3 S IBER=IBER_"IB167;" Q
 . ; MRD;IB*2.0*516 - Remove warning message for missing taxonomy code for lab or facility.
 . ; D WARN("Taxonomy for the "_$P("Service Facility^Non-VA Service Facility^Billing Provider",U,$P(IBNOTAX,U,Z))_" has no value")  ; Else, set warning
 . Q
 ;
 Q
 ;
VALNDC(IBIFN,IBDFN) ; Moving pharmacy checks to reduce likelihood of patch collision
 D VALNDC^IBCBB14(IBIFN,IBDFN)
 Q
 ;
PRIIDCHK ; Check for required Pimarary ID (SSN/EIN)
 ; If the provider is on the claim, he must have one
 ; 
 N IBI,IBZ
 I $$TXMT^IBCEF4(IBIFN) D
 . D F^IBCEF("N-ALL ATT/REND PROV SSN/EI","IBZ",,IBIFN)
 . S IBI="" F  S IBI=$O(^DGCR(399,IBIFN,"PRV","B",IBI)) Q:IBI=""  D
 .. I $P(IBZ,U,IBI)="" S IBER=IBER_$S(IBI=1:"IB151;",IBI=2:"IB152;",IBI=3!(IBI=4):"IB321;",IBI=5:"IB153;",IBI=9:"IB154;",1:"")
 Q
 ;
RXNPI(IBIFN) ; Moving pharmacy checks to reduce likelihood of patch collision
 D RXNPI^IBCBB14(IBIFN)
 Q
 ;
ROICHK(IBIFN,IBDFN,IBINS) ; Moving pharmacy checks to reduce likelihood of patch collision
 Q $$ROICHK^IBCBB14(IBIFN,IBDFN,IBINS)
 ;
AMBCK(IBIFN)    ; IB*2.0*432 - if ambulance location defined, address must be defined
 ; if there is anything entered in any of the address fields (either p/up or drop/off fields), than there needs to be: 
 ; Address 1, State and ZIP unless the State is not a US state or possession, then zip code is not needed (CMS1500 only)
 ; input - IBIFN = IEN of the Bill/Claims file (#399)
 ; OUTPUT - 0 = no error        
 ;          1 = Error
 ;
 N IBPAMB,IBDAMB,IBAMBR,IBCK
 S IBAMBR=0
 Q:$$INSPRF^IBCEF(IBIFN)'=0 IBAMBR
 S IBPAMB=$G(^DGCR(399,IBIFN,"U5")),IBDAMB=$G(^DGCR(399,IBIFN,"U6"))
 S IBCK(5)=$$NOPUNCT^IBCEF($P(IBPAMB,U,2,6),1),IBCK(6)=$$NOPUNCT^IBCEF($P(IBDAMB,U,1,6),1)
 I IBCK(5)="",IBCK(6)="" Q IBAMBR
 ; at this point we know that at least one ambulance field has data, so check to see if all have data
 I IBCK(5)'="" F I=2,4,5 I $P(IBPAMB,U,I)="" S IBAMBR=1
 I IBCK(6)'="" F I=1,2,4,5 I $P(IBDAMB,U,I)="" S IBAMBR=1
 Q:IBAMBR=1 IBAMBR
 ; now check zip code.  OK to be null if state is not a US Posession
 F I="IBPAMB","IBDAMB" I $P(I,U,5)'="",$P($G(^DIC(5,$P(I,U,5),0)),U,6)=1,$P(I,U,6)="" S IBAMBR=1
 Q IBAMBR
 ;
COBAMT(IBIFN)   ; IB*2.0*432 - IF there is a COB amt. it must equal the Total Claim Charge Amount
 ; input - IBIFN = IEN of the Bill/Claims file (#399)
 ; OUTPUT - 0 = no error        
 ;          1 = Error
 ;
 Q:IBIFN="" 0
 Q:$P($G(^DGCR(399,IBIFN,"U4")),U)="" 0
 Q:+$P($G(^DGCR(399,IBIFN,"U1")),U)'=+$P($G(^DGCR(399,IBIFN,"U4")),U) 1
 Q 0
 ;
COBMRA(IBIFN)   ; IB*2.0*432 - If there is a 'COB total non-covered amount' (File#399, Field#260), 
 ; Primary Insurance must be Medicare that never went to Medicare, and this must be a 2ndary or tertiary claim
 ; input - IBIFN = IEN of the Bill/Claims file (#399)
 ; OUTPUT - 0 = no error        
 ;          1 = Error
 ;
 N IBP
 Q:IBIFN="" 0
 Q:$P($G(^DGCR(399,IBIFN,"U4")),U)="" 0
 S IBP=$P($G(^DGCR(399,IBIFN,"M1")),U,5) S:IBP="" IBP=IBIFN
 I $$WNRBILL^IBEFUNC(IBIFN,1),$P($G(^DGCR(399,IBP,"S")),U,7)="",$$COBN^IBCEF(IBIFN)>1 Q 0
 Q 1
 ;
COBSEC(IBIFN)   ; IB*2.0*432 - If there is NOT a 'COB total non-covered amount' (File#399, Field#260), 
 ; and Primary Insurance is Medicare that never went to Medicare, 2ndary or tertiary claim cannot be set to transmit
 ; input - IBIFN = IEN of the Bill/Claims file (#399)
 ; OUTPUT - 0 = no error        
 ;          1 = Error
 ;
 N IBP
 Q:IBIFN="" 0
 Q:$P($G(^DGCR(399,IBIFN,"U4")),U)'="" 0
 Q:$$COBN^IBCEF(IBIFN)<2 0
 S IBP=$P($G(^DGCR(399,IBIFN,"M1")),U,5) S:IBP="" IBP=IBIFN
 I $$WNRBILL^IBEFUNC(IBIFN,1),$P($G(^DGCR(399,IBP,"S")),U,7)="",$P($G(^DGCR(399,IBIFN,"TX")),U,8)'=1 Q 1
 Q 0
 ;
TMCK(IBIFN) ;  IB*2.0*432 - Attachment Control Number - REQUIRED when Transmission Method = BM, EL, EM, or FT
 ; input - IBIFN = IEN of the Bill/Claims file (#399)
 ; OUTPUT - 0 = no error        
 ;          1 = Error
 ;
 N IBAC
 Q:IBIFN="" 0
 F I=1,3 S IBAC(I)=$P($G(^DGCR(399,IBIFN,"U8")),U,I)
 Q:IBAC(3)="" 0
 Q:IBAC(1)'="" 0
 Q:IBAC(3)="AA" 0
 Q 1
 ;
ACCK(IBIFN) ; IB*2.0*432 If any of the loop info is present, then Report Type & Transmission Method req'd
 ; input - IBIFN = IEN of the Bill/Claims file (#399)
 ; OUTPUT - 0 = no error        
 ;          1 = Error
 ;
 N IBAC
 Q:IBIFN="" 0
 F I=1:1:3 S IBAC(I)=$P($G(^DGCR(399,IBIFN,"U8")),U,I)
 ; All fields null, no error
 I IBAC(1)="",IBAC(2)="",IBAC(3)="" Q 0
 ; Both required fields complete, no error
 I IBAC(2)'="",IBAC(3)'="" Q 0
 ; At this point, one of the 2 required fields has data and one does not, so error
 Q 1
 ;
LNTMCK(IBIFN) ;  DEM;IB*2.0*432 - (Line Level) Attachment Control Number - REQUIRED when Transmission Method = BM, EL, EM, or FT
 ; input - IBIFN = IEN of the Bill/Claims file (#399)
 ; OUTPUT - IBLNERR = 0 = no error        
 ;          IBLNERR = 1 = Error
 ;
 N IBAC,IBPROCP,I,IBLNERR
 S IBLNERR=0  ; DEM;432 - Initialize error flag IBLNERR to '0' for no errors.
 Q:IBIFN="" IBLNERR
 S IBPROCP=0 F  S IBPROCP=$O(^DGCR(399,IBIFN,"CP",IBPROCP)) Q:'IBPROCP  D  Q:IBLNERR
 . Q:'($D(^DGCR(399,IBIFN,"CP",IBPROCP,0))#10)  ; DEM;432 - Node '0' is procedure node.
 . Q:'($D(^DGCR(399,IBIFN,"CP",IBPROCP,1))#10)  ; DEM;432 - Node '1' is line level Attachment Control fields.
 . F I=1,3 S IBAC(I)=$P(^DGCR(399,IBIFN,"CP",IBPROCP,1),U,I)
 . I IBAC(3)="" S IBLNERR=0 Q
 . I IBAC(1)'="" S IBLNERR=0 Q
 . I (IBAC(3)="AA") S IBLNERR=0 Q
 . S IBLNERR=1
 . Q
 ;
 Q IBLNERR
 ;
LNACCK(IBIFN) ; DEM;IB*2.0*432 (Line Level) If any of the loop info is present, then Report Type & Transmission Method req'd
 ; input - IBIFN = IEN of the Bill/Claims file (#399)
 ; OUTPUT - IBLNERR = 0 = no error        
 ;          IBLNERR = 1 = Error
 ;
 N IBAC,IBPROCP,I,IBLNERR
 S IBLNERR=0  ; DEM;432 - Initialize error flag IBLNERR to '0' for no errors.
 Q:IBIFN="" IBLNERR
 S IBPROCP=0 F  S IBPROCP=$O(^DGCR(399,IBIFN,"CP",IBPROCP)) Q:'IBPROCP  D  Q:IBLNERR
 . Q:'($D(^DGCR(399,IBIFN,"CP",IBPROCP,0))#10)  ; DEM;432 - Node '0' is procedure node.
 . Q:'($D(^DGCR(399,IBIFN,"CP",IBPROCP,1))#10)  ; DEM;432 - Node '1' is line level Attachment Control fields.
 . F I=1:1:3 S IBAC(I)=$P(^DGCR(399,IBIFN,"CP",IBPROCP,1),U,I)
 . ; All fields null, no error
 . I IBAC(1)="",IBAC(2)="",IBAC(3)="" S IBLNERR=0 Q
 . ; Both required fields complete, no error
 . I IBAC(2)'="",IBAC(3)'="" S IBLNERR=0 Q
 . ; At this point, one of the 2 required fields has data and one does not, so error
 . S IBLNERR=1
 . Q
 ;
 Q IBLNERR
 ;
 ;vd/Beginning of IB*2*577 - Validate Line Level for NDC
LNNDCCK(IBIFN) ;IB*2*577 (Line Level) The Units and Units/Basis of Measurement fields are required if the NDC field is populated.
 ; INPUT  - IBIFN = IEN of the Bill/Claims file (#399)
 ; OUTPUT - IBLNERR = 0 = no error
 ;          IBLNERR = 1 = Error
 ;
 N IBAC,IBPROCP,I,IBLNERR
 S IBLNERR=0  ; IB*2*577 - Initialize error flag IBLNERR to '0' for no errors.
 Q:IBIFN="" IBLNERR
 S IBPROCP=0 F  S IBPROCP=$O(^DGCR(399,IBIFN,"CP",IBPROCP)) Q:'IBPROCP  D  Q:IBLNERR
 . Q:($$GET1^DIQ(399.0304,IBPROCP_","_IBIFN_",","NDC","I")="")   ; IB*2*577 - No NDC Code
 . ; If there is an NDC Code, then the UNITS and UNITS/BASIS OF MEASUREMENT are Required.
 . I $$GET1^DIQ(399.0304,IBPROCP_","_IBIFN_",","UNITS/BASIS OF MEASUREMENT","I")="" S IBLNERR=1 Q
 . I $$GET1^DIQ(399.0304,IBPROCP_","_IBIFN_",","UNITS","I")="" S IBLNERR=1 Q  ;Units (Quantity) is required if there is an NDC Code.
 . Q
 ;
 Q IBLNERR
 ;vd/End of IB*2*577
