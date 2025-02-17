ECUERPC ;ALB/JAM - Event Capture Data Entry Broker Utilities ;1/25/18  12:38
 ;;2.0;EVENT CAPTURE;**25,32,33,46,47,59,72,95,114,126,129,131,139**;8 May 96;Build 7
 ;
 ; Reference to $$SINFO^ICDEX supported by ICR #5747
 ; Reference to $$ICDDX^ICDEX supported by ICR5747
 ;
USRUNT(RESULTS,ECARY) ;
 ;This broker call returns an array of DSS units for a user & location
 ;        RPC: EC GETUSRDSSUNIT
 ;INPUTS     ECARY  - Contains the following delimited elements
 ;            1. ECL      - Location IEN (if define gives User's DSS 
 ;                          units for a location)
 ;            2. ECDUZ    - New Person IEN (if define gives list of 
 ;                          DSS Units available to user)
 ;            3. ECSUMUSR - Indicates which report is requesting this
 ;                          list. (optional)
 ;            4. ECDUST   - Indicates DSS unit status requested (A)ctive
 ;                          (I)nactive or (B)oth. (optional)
 ;
 ;OUTPUTS     RESULTS - Array of DSS Units. Data pieces as follows:-
 ;            PIECE - Description
 ;              1     IEN of file 724
 ;              2     Name of DSS Unit
 ;              3     Send to PCE Flag
 ;              4     Data Entry Date/Time Default
 N ECL,ECDUZ,CNT,STR,DPT,IEN,ECSUMUSR,ECDUST ;139
 D SETENV^ECUMRPC
 S ECL=$P(ECARY,U),ECDUZ=$P(ECARY,U,2) I ECL="",ECDUZ="" Q
 S ECSUMUSR=$P(ECARY,U,3),ECDUST=$P(ECARY,U,4) S:ECDUST="" ECDUST="B" ;139
 K ^TMP($J,"ECUSRUNT") S (DPT,CNT)=0
 I ECL'="",ECDUZ="" S ECDUZ=$G(DUZ,U) I ECDUZ="" Q
 I $G(ECSUMUSR)="ECSUM" D ECSUM S RESULTS=$NA(^TMP($J,"ECUSRUNT")) Q  ;139 Add special branch for the ECSUM report
 I $D(^XUSEC("ECALLU",ECDUZ)) S DPT="" D
 .I ECL="" S ^TMP($J,"ECUSRUNT",CNT+1)="ALL^ALL" Q
 .I ECL="ALL" S ECL=""
 .F  S DPT=$O(^ECD("B",DPT))  Q:DPT=""  S IEN=0 D
 ..F  S IEN=$O(^ECD("B",DPT,IEN)) Q:'IEN  D UNTCHK
 E  D
 .I ECL="ALL" S ECL=""
 .F  S DPT=$O(^VA(200,ECDUZ,"EC",DPT)) Q:'DPT  S IEN=DPT D UNTCHK
 S RESULTS=$NA(^TMP($J,"ECUSRUNT"))
 Q
UNTCHK ;Check if DSS unit exist as event code screen and if active
 N DSSF,DFD
 ;I '$D(^ECJ("AP",ECL,IEN))!($P($G(^ECD(IEN,0)),U,6)) Q
 I ECL'="",'$D(^ECJ("AP",ECL,IEN)) Q
 I ($P($G(^ECD(IEN,0)),U,6))!('$P($G(^ECD(IEN,0)),U,8)) Q
 ;Check if event code screens associated with DSS unit are active
 I ECL'="",'$$ECSCHK(ECL,IEN) Q
 S DSSF=$P(^ECD(IEN,0),"^",14) S:DSSF="" DSSF="N"
 S DFD=$S($P(^ECD(IEN,0),"^",12)="N":"N",1:"X") ; added by VMP
 S CNT=CNT+1,STR=IEN_"^"_$P(^ECD(IEN,0),"^")_U_DSSF_"^"_DFD
 S ^TMP($J,"ECUSRUNT",CNT)=STR
 Q
ECSCHK(ECL,ECIEN) ;Check if any event code screens associated with DSS unit are active; EC*129
 N ECAT,ECPRX,ECS,ECNODE,ECFLG
 S ECAT="",ECFLG=0
 F  S ECAT=$O(^ECJ("AP",ECL,ECIEN,ECAT)) Q:ECAT=""  D  Q:ECFLG
 .S ECPRX="" F  S ECPRX=$O(^ECJ("AP",ECL,ECIEN,ECAT,ECPRX)) Q:ECPRX=""  D  Q:ECFLG
 ..S ECS=0 F  S ECS=$O(^ECJ("AP",ECL,ECIEN,ECAT,ECPRX,ECS)) Q:'ECS  D  Q:ECFLG
 ...S ECNODE=$G(^ECJ(ECS,0)) I $P(ECNODE,"^",2)="" S ECFLG=1
 Q ECFLG
 ;
ECSUM ;139 Section added to allow for sorting DSS units by status
 N DSSIEN,DSSNAME,NODE,STAT,DSSF,DFO,STR
 S DSSNAME="" F  S DSSNAME=$O(^ECD("B",DSSNAME)) Q:DSSNAME=""  S DSSIEN=0 F  S DSSIEN=$O(^ECD("B",DSSNAME,DSSIEN)) Q:'+DSSIEN  D
 .S NODE=$G(^ECD(DSSIEN,0)) Q:NODE=""
 .I '$P(NODE,U,8) Q  ;DSS Unit not for use in Event Capture
 .S STAT=$S($P(NODE,U,6):"I",1:"A") ;DSS Unit status
 .I ECDUST'="B",STAT'=ECDUST Q  ;If not getting both active and inactive units, quit if unit status isn't what we're looking for
 .I ECL'="ALL",'$D(^ECJ("AP",ECL,DSSIEN)) Q  ;For all locations, no need to check for event code screens. For single location, DSS unit must have at least one event code screen
 .S DSSF=$P(NODE,U,14) S:DSSF="" DSSF="N" ;Send to PCE setting
 .S DFD=$S($P(NODE,U,12)="N":"N",1:"X") ;Unit's default date/time setting
 .S CNT=CNT+1,STR=DSSIEN_U_$P(NODE,U)_U_DSSF_U_DFD
 .S ^TMP($J,"ECUSRUNT",CNT)=STR
 Q
 ;
CAT(RESULTS,ECARY) ;
 ;This broker entry point returns an array of categories for an Event 
 ;Code screen based on location and DSS unit.
 ;        RPC: EC GETECSCATS
 ;INPUTS     ECARY  - Contains the following values separated by "^"
 ;            ECL  - Location IEN
 ;            ECD  - DSS Unit IEN
 ;            ECCSTA-Active or inactive category
 ;                   A-ctive (default), I-nactive, B-oth
 ;
 ;OUTPUTS     RESULTS - Array of categories. Data pieces as follows:-
 ;            PIECE - Description
 ;              1 - Category IEN
 ;              2 - Category description
 ;
 N ECL,ECD,ECC,CNT,DATA,ECCSTA
 D SETENV^ECUMRPC
 S ECL=$P(ECARY,U),ECD=$P(ECARY,U,2) I (ECL="")!(ECD="") Q
 S ECCSTA=$P(ECARY,U,3)
 K ^TMP($J,"ECSCATS")
 D CATS^ECHECK1
 M ^TMP($J,"ECSCATS")=ECC
 S RESULTS=$NA(^TMP($J,"ECSCATS"))
 Q
PROC(RESULTS,ECARY) ;
 ;This broker entry point returns an array of procedures for an Event 
 ;Code screen (file #720.3) based on location, DSS unit, and Category
 ;        RPC: EC GETECSPROCS
 ;INPUTS     ECARY  - Contains the following values separated by "^"
 ;            ECL  - Location IEN
 ;            ECD  - DSS Unit IEN
 ;            ECC  - Category IEN
 ;            ECDT - Procedure Date
 ;
 ;OUTPUTS     RESULTS - Array of procedures. Data pieces as follows:-
 ;            PIECE - Description
 ;              1  - EC National Number SPACE Procedure Name SPACE
 ;                - [Synonym]
 ;              2  - Procedure Code
 ;              3  - CPT Code
 ;              4  - Default volume (1 if no default volume)
 ;              5  - Event code screen IEN
 ;
 N ECL,ECD,ECC,CNT,DATA,STR,ECCPT,PX,NAME,NUM ;126
 D SETENV^ECUMRPC
 S ECL=$P(ECARY,U),ECD=$P(ECARY,U,2),ECC=$P(ECARY,U,3)
 I (ECL="")!(ECD="") Q
 S:$P($G(^ECD(ECD,0)),U,11)=0 ECC="" S:ECC="" ECC=0 ;131
 S ECDT=$P(ECARY,U,4)
 K ^TMP($J,"ECPRO")
 D PROS^ECHECK1
 S CNT=1,NAME="" F  S NAME=$O(^TMP("ECPRO",$J,"N2",NAME)) Q:NAME=""  S NUM=$O(^TMP("ECPRO",$J,"N2",NAME,0)) D  ;126
 .S DATA=^TMP("ECPRO",$J,NUM),PX=$P(DATA,U) ;126
 .S ECCPT=$S(PX["EC":$P($G(^EC(725,+PX,0)),"^",5),1:+PX)
 .S STR=$P(DATA,U,5)_" "_$P(DATA,U,4)_" ["_$P(DATA,U,3)_"]"_U_PX
 .S STR=STR_U_ECCPT_U_$S($P(DATA,U,6):+$P(DATA,U,6),1:1)_U_$P(DATA,U,2)
 .S ^TMP($J,"ECPRO",CNT)=STR,CNT=CNT+1 ;126
 S RESULTS=$NA(^TMP($J,"ECPRO"))
 K ^TMP("ECPRO",$J)
 Q
ECPXMOD(RESULTS,ECARY) ;
 ;Broker call returns modifier entries for a CPT Procedure
 ;        RPC: EC GETPXMODIFIER
 ;INPUTS   ECARY  - Contains the following values separated by "^"
 ;          ECCPT - CPT code ien (file #81)
 ;          ECDT  - Procedure date and time (fileman format)
 ;
 ;OUTPUTS  RESULTS - Array of procedure modifiers
 ;          2-character modifier^modifer name^modifier ien #81.3
 ;
 N CNT,SUB,ECCPT,ECDT,DATA,ECMOD
 D SETENV^ECUMRPC
 S ECCPT=$P(ECARY,U),ECDT=$P(ECARY,U,2) I ECDT="" D NOW^%DTC S ECDT=%
 I ECCPT="" Q
 K ^TMP($J,"ECPXMODS") S (SUB,CNT)=0
 S DATA=$$CODM^ICPTCOD(ECCPT,"ECMOD","",ECDT) I +DATA<0 Q
 F  S SUB=$O(ECMOD(SUB)) Q:SUB=""  I $P(ECMOD(SUB),U,2)'="" D
 . I +$$MODP^ICPTMOD(ECCPT,$P(ECMOD(SUB),U,2),"I",ECDT)>0 D
 . . S CNT=CNT+1,^TMP($J,"ECPXMODS",CNT)=SUB_U_ECMOD(SUB)
 S RESULTS=$NA(^TMP($J,"ECPXMODS"))
 Q
PRVDER(RESULTS,ECARY) ;
 ;remove this rpc before release;JAM 6/4/01
 ;This broker entry point returns an array of valid providers
 ;        RPC: EC GETPROVIDER
 ;INPUTS     ECARY  - Contains the following subscripted elements
 ;            ECDT  - Procedure date
 ;
 ;OUTPUTS     RESULTS - Array of providers. Data pieces as follows:-
 ;            PIECE - Description
 ;             IEN of file 200^Provider Name^occupation^specialty^
 ;             subspecialty
 ;
 N IEN,CNT,ECUTN,KEY,USR
 D SETENV^ECUMRPC
 S ECDT=$P($G(ECARY),U),ECDT=$S(ECDT="":DT,1:ECDT)
 K ^TMP($J,"ECPRVDRS") S CNT=0
 F KEY="PROVIDER" S IEN=0 D
 .F  S IEN=$O(^XUSEC(KEY,IEN)) Q:'IEN  S USR=$G(^VA(200,IEN,0)) D:USR'=""
 ..S ECUTN=$$GET^XUA4A72(IEN,ECDT) I +ECUTN'>0 Q
 ..S CNT=CNT+1,^TMP($J,"ECPRVDRS",CNT)=IEN_U_$P(USR,U)_U_$P(ECUTN,2,4)
 S RESULTS=$NA(^TMP($J,"ECPRVDRS"))
 Q
 ;
ELIG(RESULTS,ECARY) ;
 ;
 ;Broker call returns a list of patient eligibilities
 ;        RPC: EC GETPATELIG
 ;INPUTS   ECARY  - Contains the following subscripted elements
 ;          DFN - Patient ien (file #2)
 ;
 ;OUTPUTS  RESULTS - Array of eligibilities
 ;          primary/secondary elig flag^elig ien^elig description
 ;
 N CNT,SUB,DFN,VAEL
 D SETENV^ECUMRPC
 S DFN=$P(ECARY,U) I DFN="" Q
 K ^TMP($J,"ECPATELIG")
 D ELIG^VADPT I $G(VAEL(1))="" Q
 S ^TMP($J,"ECPATELIG",1)="1^"_VAEL(1),SUB=0,CNT=1
 F  S SUB=$O(VAEL(1,SUB)) Q:SUB=""  D
 . S CNT=CNT+1,^TMP($J,"ECPATELIG",CNT)="0^"_VAEL(1,SUB)
 S RESULTS=$NA(^TMP($J,"ECPATELIG"))
 Q
PRDEFS(RESULTS,ECARY) ;
 ;This broker entry point returns the defaults for procedure data entry
 ;        RPC: EC GETPRODEFS
 ;INPUTS     ECARY  - Contains the following values separated by "^"
 ;            ECL  - Location IEN
 ;            ECD  - DSS Unit IEN
 ;            ECC  - Category IEN
 ;
 ;OUTPUTS    RESULTS - Data pieces as follows:-
 ;           PIECE - Description
 ;             1 - Associated Clinic IEN
 ;             2 - Associated Clinic
 ;             3 - Medical Specialty IEN
 ;             4 - Medical Specialty
 ;
 N ECL,ECD,ECC,ECP,IEN,ASC,ASCNM,MEDSP,MEDSPNM,ECCH
 D SETENV^ECUMRPC
 S ECL=$P(ECARY,U),ECD=$P(ECARY,U,2),ECC=$P(ECARY,U,3),ECP=$P(ECARY,U,4)
 S:ECC="" ECC=0 I (ECL="")!(ECD="") Q
 S (ASCNM,MEDSPNM)="",ECCH=ECL_"-"_ECD_"-"_ECC_"-"_ECP
 I '$D(^ECJ("B",ECCH)) Q
 S IEN=$O(^ECJ("B",ECCH,0)) I IEN="" Q
 S ASC=$P($G(^ECJ(IEN,"PRO")),U,4) I ASC D
 .S ASCNM=$$GET1^DIQ(44,ASC,.01,"I")
 S MEDSP=$P($G(^ECD(ECD,0)),U,3) I MEDSP D 
 .S MEDSPNM=$$GET1^DIQ(723,MEDSP,.01,"I")
 S RESULTS=ASC_U_ASCNM_U_MEDSP_U_MEDSPNM
 Q
PATPROC(RESULTS,ECARY) ;
 ;
 ;Broker call returns the entries from EVENT CAPTURE PATIENT FILE #721
 ;
 ;RPC: EC GETPATPROCS
 ;
 ;INPUTS   ECARY - Contains the following values separated by "^"
 ;         ECLOC - Location ien
 ;         ECPAT - Patient DFN ien
 ;         ECUNT - DSS unit ien
 ;         ECSD  - Start Date
 ;         ECED  - End Date
 ;                                                                         
 ;OUTPUTS  RESULTS - Array of Event Capture Patient entries contain
 ;          721 IEN^Procedure date/time^Category^Procedure^Volume^
 ;          Provider^ordering section^associated clinic^
 ;          (ICD Coding system) primary dx code primary dx code description
 ;          ^Provider IEN
 ;
 N IEN,CNT,ECCS,ECV,ECLOC,ECUNT,ECPAT,PX,NODE,DATA,PDT,PDX,PND,PDXD,CAT,ECI
 N ORS,PRV,PRO,PROV,ECU
 D SETENV^ECUMRPC ;set environment variables for RPC broker
 S ECV="ECLOC^ECPAT^ECUNT^ECSD^ECED"
 D PARSE(ECV,ECARY) I (ECLOC="")!(ECPAT="")!(ECUNT="") Q
 K ^TMP($J,"ECPATPX")
 S ECSD=$G(ECSD,DT),ECED=$G(ECED,DT)
 S %DT="X" F ECI="ECSD","ECED" S X=@ECI D ^%DT S @ECI=Y
 K X,Y
 S ECSD=$S(ECSD=-1:DT,1:ECSD)-.0001,ECED=$S(ECED=-1:DT,1:ECED)+.9999
 Q:ECED'>ECSD  S PDT=ECSD,CNT=0
 F  S PDT=$O(^ECH("ADT",ECLOC,ECPAT,ECUNT,PDT)) Q:'PDT!(PDT>ECED)  D
 . S IEN=0 F  S IEN=$O(^ECH("ADT",ECLOC,ECPAT,ECUNT,PDT,IEN)) Q:'IEN  D
 . . S NODE=$G(^ECH(IEN,0)),PND=$G(^ECH(IEN,"P")),PX=$P(NODE,U,9)
 . . Q:NODE=""  S (PRV,CAT,ORS,ASC,PDXD)="",PDX=$P(PND,U,2)
 . . I PX["EC" D
 . . . S PRO=$G(^EC(725,$P(PX,";"),0)),PX=$P(PRO,U,2)_" "_$P(PRO,U)
 . . E  S PRO=$$CPT^ICPTCOD($P(PX,";"),PDT) S PX=$P(PRO,U,2)_" "_$P(PRO,U,3)
 . . S:$P(NODE,U,8) CAT=$$GET1^DIQ(726,$P(NODE,U,8),.01,"I")
 . . K PROV S ECU=$$GETPPRV^ECPRVMUT(IEN,.PROV),PRV=$S(ECU:"UNKNOWN",1:$P(PROV,"^",2)),ECU=$S('ECU:+PROV,1:"")
 . . S:$P(NODE,U,12) ORS=$$GET1^DIQ(723,$P(NODE,U,12),.01,"I")
 . . S:$P(NODE,U,19) ASC=$$GET1^DIQ(44,$P(NODE,U,19),.01,"I")
 . . I PDX D
 . . . ; ICD10 Changes
 . . . S ECCS=$$SINFO^ICDEX("DIAG",PDT) ; Supported by ICR 5747
 . . . S PDXD=$$ICDDX^ICDEX(PDX,PDT,+ECCS,"I") ; Supported by ICR 5747
 . . . S ECCS=$P(ECCS,U,2),ECCS=" ("_$P(ECCS,"-",1)_$P(ECCS,"-",2)_")"
 . . . S PDXD=$P(PDXD,U,2)_" "_$P(PDXD,U,4)_ECCS
 . . S DATA=$P(NODE,U)_U_$$FMTE^XLFDT($P(NODE,U,3),"2F")_U_CAT_U_PX
 . . S DATA=DATA_U_$P(NODE,U,10)_U_PRV_U_ORS_U_ASC_U_PDXD_U_ECU
 . . S CNT=CNT+1,^TMP($J,"ECPATPX",CNT)=DATA
 S RESULTS=$NA(^TMP($J,"ECPATPX"))
 Q
PARSE(ECV,ECARY) ;Parse Variable
 N I
 F I=1:1:$L(ECARY,U) S @$P(ECV,U,I)=$P(ECARY,U,I)
 Q
