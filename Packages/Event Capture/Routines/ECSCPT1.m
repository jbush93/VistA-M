ECSCPT1 ;ALB/JAM - Event Code Screens with CPT Codes ;9/18/18  15:12
 ;;2.0;EVENT CAPTURE;**72,95,119,131,139,145**;8 May 96;Build 6
EN ;entry point
 N UCNT,ECDO,ECCO,ECNT,ECINDT,ECP0
 S (ECMORE,ECNT,ECDO,ECCO)=0,ECPG=$G(ECPG,1),ECCPT=$G(ECCPT,"B")
 ;Process all DSS Units
 I ECALL S ECD=0 D  G END
 .F  S ECD=$O(^ECJ("AP",ECL,ECD)) Q:'ECD  D  Q:ECOUT
 ..D SET,CATS,PAGE:'ECOUT&UCNT
 ;Process a specific DSS Unit
 S UCNT=0 D
 .I ECC="ALL" D CATS Q
 .I 'ECJLP S ECC=0,ECCN="None",ECCO=999
 .D PROC
END I 'ECNT,$G(ECPTYP)'="E" W !!!,"Nothing Found." ;119 Nothing to write if exporting
 S ECPG=$G(ECPG,1)
 Q
SET ;set var
 S ECDN=$S($P($G(^ECD(+ECD,0)),"^")]"":$P(^(0),"^"),1:"UNKNOWN"),UCNT=0
 S ECDN=ECDN_$S($P($G(^ECD(+ECD,0)),"^",6):" **Inactive**",1:"")
 Q
SETC ;set cats
 I ECC=0 S ECCN="None" Q
 S ECCN=$S($P($G(^EC(726,+ECC,0)),"^")]"":$P(^(0),"^"),1:"ZZ #"_ECC_" MISSING DATA")
 S ECMORE=1
 Q
HEADER ;
 W:$E(IOST,1,2)="C-"!(ECPG>1) @IOF
 W !!,?24,"EVENT CODE SCREENS WITH"
 W $S(ECCPT="I":" INACTIVE",ECCPT="A":" ACTIVE",1:"")_" CPT CODES"
 W ?70,"Page: ",ECPG,!?25,"Run Date: ",ECRDT,!?25,"LOCATION:  "_ECLN
 W !?25,"DSS UNIT:  "_ECDN,! S ECPG=ECPG+1
 F I=1:1:80 W "-"
 Q
CATS ;
 S ECC="",ECCO=0
 F  S ECC=$O(^ECJ("AP",ECL,ECD,ECC)) Q:ECC=""  D  Q:ECOUT  ;131 Moved calls to dot structure
 .I ECC,'$P(^ECD(ECD,0),U,11) Q  ;131 Don't include categories if unit is set to "no categories"
 .D SETC,PROC ;131 Moved from for loop
 S ECMORE=0
 Q
PROC ;
 S ECP=""
 F  S ECP=$O(^ECJ("AP",ECL,ECD,ECC,ECP)) Q:ECP=""  D SETP Q:ECOUT
 S ECMORE=0
 Q
SETP ;set procs
 S ECPSY=+$O(^ECJ("AP",ECL,ECD,ECC,ECP,"")),ECPI=""
 S ECPSYN=$P($G(^ECJ(ECPSY,"PRO")),"^",2),ECFILE=$P(ECP,";",2)
 S ECACIEN=+$P($G(^ECJ(ECPSY,"PRO")),U,4) ;Get clinic IEN
 S ECAC=$$GET1^DIQ(44,ECACIEN,.01) ;139 Get associated clinic
 S NODE=$G(^ECX(728.44,+ECACIEN,0)) ;145
 S ECSC=$P(NODE,U,2) ;145 Stop Code
 S ECCSC=$P(NODE,U,3) ;145 Credit Stop Code
 S ECCHAR=$$GET1^DIQ(728.441,$P(NODE,U,8),.01) ;145 Char 4 code
 S ECMCA=$$GET1^DIQ(728.442,$P(NODE,U,14),.01) ;139,145 Get MCA Labor Code for associated clinic
 S ECFILE=$S($E(ECFILE)="I":81,$E(ECFILE)="E":725,1:"")
 I ECFILE="" Q
 S (ECPN,ECPT,NATN)="",ECPI=0
 I ECFILE=81 S ECPI=$$CPT^ICPTCOD(+ECP) I +ECPI>0 D
 .S ECPN=$P(ECPI,"^",3),ECPT=$P(ECPI,"^",2),ECINDT=$P(ECPI,"^",7)
 I ECFILE=725 D
 .S ECP0=$G(^EC(725,+ECP,0)),ECPT="",ECPN=$P(ECP0,"^")
 .S NATN=$P(ECP0,"^",2)
 .I $P(ECP0,"^",5)'="" S ECPI=$$CPT^ICPTCOD($P(ECP0,"^",5)) I +ECPI>0 D 
 ..S ECPT=$P(ECPI,"^",2),ECINDT=$P(ECPI,"^",7)
 I +ECPI<1 Q
 I ECCPT="A",'ECINDT Q
 I ECCPT="I",ECINDT Q
 I $G(ECPTYP)="E" D EXPORT Q  ;119 Nothing to write if exporting
 I ECD'=ECDO D HEADER S ECDO=ECD
 I ECC'=ECCO D  S ECCO=ECC I ECOUT Q
 .W !!,"Category:  "_ECCN D:$Y+4>IOSL CONTD
 S ECNT=ECNT+1,UCNT=UCNT+1 ;139
 W !,"Procedure: ",$E(ECPN,1,30)," (",$S(ECFILE=81:"CPT",1:"EC"),")",?48,"Nat'l #: ",NATN,?64,"CPT: ",ECPT
 I ECCPT="B",'ECINDT W ?70," *I*"
 I $G(ECPSYN)'="" W !,"  Synonym: ",ECPSYN ;139
 I $G(ECAC)'="" W !,"  Associated Clinic: ",ECAC,!,"  Stop Code: ",ECSC,?19,"Credit Stop: ",ECCSC,?38,"CHAR4: ",ECCHAR,?52,"MCA Labor Code: ",ECMCA ;139,145
 D:($Y+3)>IOSL CONTD I ECOUT Q
 Q
CONTD ;Check whether to continue or exit
 D PAGE I ECOUT Q
 D HEADER:ECPG,MORE:$D(ECCN)
 Q
 ;
PAGE ;
 N SS,JJ
 I $D(ECPG),$E(IOST,1,2)="C-" D
 . S SS=22-$Y F JJ=1:1:SS W !
 . S DIR(0)="E" W ! D ^DIR K DIR I 'Y S ECOUT=1
 Q
MORE I ECMORE W !!,"Category:  "_ECCN
 Q
 ;
EXPORT ;Section added in patch 119
 S CNT=CNT+1
 S ^TMP($J,"ECRPT",CNT)=ECLN_U_ECDN_U_ECCN_U_ECPT_$S('ECINDT:" **Inactive**",1:"")_U_NATN_U_ECPN_" ("_$S(ECFILE=81:"CPT",1:"EC")_")"_U_ECPSYN_U_ECAC_U_ECSC_U_ECCSC_U_ECCHAR_U_ECMCA ;139,145
 Q
