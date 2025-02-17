YSCLTST4 ;DALOI/LB/RLM-TRANSMIT RX AND lAB DATA FOR CLOZAPINE ; 11/27/18 5:15pm
 ;;5.01;MENTAL HEALTH;**92,122**;Dec 30, 1994;Build 112
 ; Reference to ^LAB(60 supported by IA #333
 ; Reference to ^LR7OR1 supported by IA #2503
 ; Reference to ^DIC supported by DBIA #2051
 ; Reference to ^DIQ supported by DBIA #2056
 ; Reference to ^%DTC supported by DBIA #10000
 ;
CL1 ;(DFN,DAYS) ;
 K ^TMP($J,"PSO"),RESULTS,YSCLYWBC,YSCLRANC,YSCLXWBC
 Q:'DFN
 S:'$G(DAYS) DAYS=90
 N ARRAY D LIST^DIC(603.01,,1,"I",,,DFN,"C",,,"ARRAY")
 S YSCLIEN=$G(ARRAY("DILIST",2,1)),YSCLFRQ="" I YSCLIEN S YSCLFRQ=$$GET1^DIQ(603.01,YSCLIEN,2,"I")
 I $$GET1^DIQ(603.03,1,7,"I")=1  Q "-1^0^0^0^0^0^"_YSCLFRQ
 S X1=DT,X2="-"_DAYS D C^%DTC S YSCLSD=X
 K ARRAY D LIST^DIC(603.41,",1,","1;2","I",,,,,,,"ARRAY")
 F I=1:1 Q:'$D(ARRAY("DILIST",2,I))  S YSCLA=ARRAY("DILIST",2,I) D
 . N YSCLTNM,YSCLTTP,YSCLTFR S YSCLTNM=ARRAY("DILIST",1,I) ;$$GET1^DIQ(603.41,YSCLA_",1,",.01,"I")
 . S YSCLTTP=ARRAY("DILIST","ID",I,1)
 . S YSCLTFR=ARRAY("DILIST","ID",I,2)
 . S YSCLTLS(YSCLTTP,YSCLTNM)=YSCLTFR
 F I=1:1 Q:'$D(ARRAY("DILIST",1,I))  S YSCLTL=ARRAY("DILIST",1,I) D
 . D RR^LR7OR1(DFN,,YSCLSD,DT,,YSCLTL,"L")
 . S YSCLSB1="" F  S YSCLSB1=$O(^TMP("LRRR",$J,DFN,YSCLSB1)) Q:YSCLSB1=""  D
 . . S YSCLTDT="" F  S YSCLTDT=$O(^TMP("LRRR",$J,DFN,YSCLSB1,YSCLTDT)) Q:YSCLTDT=""  I $P(YSCLTDT,".",2)]"" D
 . . . S YSCLTA="" F  S YSCLTA=$O(^TMP("LRRR",$J,DFN,YSCLSB1,YSCLTDT,YSCLTA)) Q:YSCLTA=""  I YSCLTA D
 . . . . S RESULTS1=^TMP("LRRR",$J,DFN,YSCLSB1,YSCLTDT,YSCLTA)
 . . . . S RESULTS(YSCLTL,YSCLTDT)=$P(RESULTS1,"^",2)
 ;Find all entries for WBC and sort by inverse date.
 S YSCLA="" F  S YSCLA=$O(YSCLTLS("W",YSCLA)) Q:'YSCLA  S YSCLXWBC(YSCLA)="" D
 . S YSCLA1="" F  S YSCLA1=$O(RESULTS(YSCLA,YSCLA1)) Q:'YSCLA1  D
 . . S YSCLYWBC(YSCLA1)=RESULTS(YSCLA,YSCLA1)*$S(YSCLTLS("W",YSCLA):1000,1:1)
 . . S ^TMP($J,"PSO",YSCLA1)=YSCLYWBC(YSCLA1)
 S YSCLRWBC=0 F  S YSCLRWBC=$O(YSCLYWBC(YSCLRWBC)) Q:YSCLRWBC=""  S YSCLRWBC(YSCLRWBC)=YSCLYWBC(YSCLRWBC) D
 . ;Match all ANC's and WBC's
 . S YSCLMTCH=0 F YSCLA="A","N","S","C" Q:YSCLMTCH  S YSCLTPT="" F  S YSCLTPT=$O(YSCLTLS(YSCLA,YSCLTPT)) Q:'YSCLTPT  D  Q:YSCLMTCH
 . . I $G(RESULTS(YSCLTPT,YSCLRWBC)),YSCLA="A",$D(YSCLRWBC(YSCLRWBC)) S ^TMP($J,"PSO",YSCLRWBC)=YSCLRWBC(YSCLRWBC)_"^"_(RESULTS(YSCLTPT,YSCLRWBC)*$S(YSCLTLS(YSCLA,YSCLTPT):1000,1:1)) Q
 . . I $G(RESULTS(YSCLTPT,YSCLRWBC)),YSCLA="N",$D(YSCLRWBC(YSCLRWBC)) S YSCLMTCH=1,^TMP($J,"PSO",YSCLRWBC)=YSCLRWBC(YSCLRWBC)_"^"_(YSCLRWBC(YSCLRWBC)*((RESULTS(YSCLTPT,YSCLRWBC)*.01))) Q
 . . I $G(RESULTS(YSCLTPT,YSCLRWBC)),YSCLA="S",$D(YSCLRWBC(YSCLRWBC)) D  Q
 . . . S (YSCLSG1,YSCLSGS)="" F  S YSCLSGS=$O(YSCLTLS("B",YSCLSGS)) D  Q:'YSCLSGS!YSCLMTCH
 . . . . I 'YSCLSG1,'YSCLSGS S YSCLSGS="Z",YSCLSG1=1
 . . . . I 'YSCLSGS,YSCLSG1 Q
 . . . . I '$D(RESULTS(YSCLSGS,YSCLRWBC)) S RESULTS(YSCLSGS,YSCLRWBC)=0
 . . . . S YSCLMTCH=1,^TMP($J,"PSO",YSCLRWBC)=YSCLRWBC(YSCLRWBC)_"^"_(YSCLRWBC(YSCLRWBC)*((RESULTS(YSCLTPT,YSCLRWBC)*.01)+(RESULTS(YSCLSGS,YSCLRWBC)*.01))) Q
 . . I $G(RESULTS(YSCLTPT,YSCLRWBC)),YSCLA="C" S YSCLMTCH=1 D
 . . . S YSCLSGS="" F  S YSCLSGS=$O(YSCLTLS("T",YSCLSGS)) D  Q:'YSCLSGS!YSCLMTCH
 . . . . I '$G(YSCLSG1),'YSCLSGS S YSCLSGS="Z",YSCLSG1=1
 . . . . I 'YSCLSGS,$G(YSCLSG1) Q
 . . . . I '$D(RESULTS(YSCLSGS,YSCLRWBC)) S RESULTS(YSCLSGS,YSCLRWBC)=0
 . . . . S YSCLMTCH=1,^TMP($J,"PSO",YSCLRWBC)=YSCLRWBC(YSCLRWBC)_"^"_((RESULTS(YSCLTPT,YSCLRWBC)*$S(YSCLTLS(YSCLA,YSCLTPT):1000,1:1))+(RESULTS(YSCLSGS,YSCLRWBC))) Q
 S YSCLA="A",YSCLTPT="" F  S YSCLTPT=$O(YSCLTLS(YSCLA,YSCLTPT)) Q:'YSCLTPT  D
 . S YSCLRANC="" F  S YSCLRNC=$O(RESULTS(YSCLTPT,YSCLRANC)) Q:'YSCLRANC  D
 . . Q:$D(^TMP($J,"PSO",YSCLRANC))
 . . S ^TMP($J,"PSO",YSCLRANC)="^"_(RESULTS(YSCLTPT,YSCLRANC)*$S(YSCLTLS("A",YSCLTPT):1000,1:1))
 K FDA,YSCLSGS,Y15,YSCLRWBC,YSCLANC,YSCLYWBC,YSCLFRQ,ZIENS,RESULTS,RESULTS1,YSCLA,YSCLA1,YSCLMTCH,YSCLSB1,YSCLSD
 K YSCLTA,YSCLTDT,YSCLTL,YSCLTLS,YSCLTPT,YSCLXWBC,YSCLMULT
 Q
 ;
KILL ;
 K FDA,YSCLSGS,Y15,RESULTS,RESULTS1,YSCLA,YSCLA1,YSCLMTCH,YSCLSB1,YSCLSD,YSCLTA,YSCLMULT
 K YSCLTDT,YSCLTL,YSCLSG1,YSCLTLS,YSCLTPT,YSCLXWBC
 ;
ZEOR ;YSCLTST4
