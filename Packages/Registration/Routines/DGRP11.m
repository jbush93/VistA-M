DGRP11 ;ALB/MRL,RTK,PHH,PWC,HM - REGISTRATION SCREEN 11/VERIFICATION INFORMATION ;3/23/06 8:10am
 ;;5.3;Registration;**327,631,709,871,987**;Aug 13, 1993;Build 22
 ;
 S DGRPS=11 D H^DGRPU F I=.3,.32,.36,.361,"TYPE","VET" S DGRP(I)=$S($D(^DPT(DFN,I)):^(I),1:"")
 S (DGRPW,Z)=1 D WW^DGRPV W " Eligibility Status: " S DGRPX=DGRP(.361),X=$P(DGRPX,"^",1),Z=$S(X']"":"NOT VERIFIED",X="V":"VERIFIED",X="R":"PENDING RE-VERIFICATION",1:"PENDING VERIFICATION"),Z1=28 D WW1^DGRPV S DGRPVR=$S(X]"":1,1:0)
 W "Status Date: " S Y=$P(DGRPX,"^",2) X:Y]"" ^DD("DD") W $S(Y]"":Y,DGRPVR:DGRPU,1:DGRPNA),!?5,"Status Entered By: ",$S($D(^VA(200,+$P(DGRPX,"^",6),0)):$P(^(0),"^",1)_" (#"_+$P(DGRPX,"^",6)_")",DGRPVR:DGRPU,1:DGRPNA)
 W !?6,"Interim Response: " S Y=$P(DGRPX,"^",4) X:Y]"" ^DD("DD") W $S(Y]"":Y,1:DGRPU_" (NOT REQUIRED)"),!?9,"Verif. Method: ",$S($P(DGRPX,"^",5)]"":$P(DGRPX,"^",5),DGRPVR:DGRPU,1:DGRPNA)
 ;Added display of ELIGIBILITY VERIF. SOURCE for Ineligible Project:
 W !?9,"Verif. Source: ",$S($P(DGRPX,"^",3)="H":"HEC",$P(DGRPX,"^",3)="V":"VISTA",1:"NOT AVAILABLE")
 S Z=2 D WW^DGRPV W "     Money Verified: " S Y=$P(DGRP(.3),"^",6) X:Y]"" ^DD("DD") W $S(Y]"":Y,1:"NOT VERIFIED") S Z=3 D WW^DGRPV W "   Service Verified: " S Y=$P(DGRP(.32),"^",2) X:Y]"" ^DD("DD") W $S(Y]"":Y,1:"NOT VERIFIED")
 S Z=4 D WW^DGRPV W " Rated Disabilities: " I $P(DGRP("VET"),"^",1)'="Y",$S('$D(^DG(391,+DGRP("TYPE"),0)):1,$P(^(0),"^",2):0,1:1) W DGRPNA," - NOT A VETERAN" G HBP
 N DGEC,DGEFF
 S DGEC=$P($G(DGRP(.36)),U)
 I $G(DGEC) I $D(^DIC(8,DGEC)) S DGEC=$P(^DIC(8,DGEC,0),U)
 W " SC%: ",$S($G(DGEC)="NSC":"",$P($G(DGRP(.3)),U,2)="":"",1:$P($G(DGRP(.3)),U,2))
 S DGEFF=$P($G(DGRP(.3)),U,14)
 I $G(DGEFF)]"" S Y=DGEFF X ^DD("DD") S DGEFF=Y
 W "    EFF. DATE OF COMBINED SC%: "_$G(DGEFF),!
 N DGQUIT
 W ?55,"Orig",?70,"Curr"
 W !?3,"Rated Disability",?46,"Extr",?55,"Eff Dt",?70,"Eff Dt"
 S I3=0
 I '$$RDIS^DGRPDB(DFN,.DGARR) W !,"NONE STATED" G HBP
 F DGC=0:0 S DGC=$O(DGARR(DGC)) Q:'DGC  D
 . S I3=I3+1
 . N DGCURR,DGORIG,DG0,DG1,DG2,DG4,DG5
 . I $G(DGARR(DGC))']"" Q
 . S DGZERO=+DGARR(DGC)
 . I '$D(^DIC(31,DGZERO,0)) Q
 . S DG0=$P(^DIC(31,DGZERO,0),U,3)
 . S DG1=$P(^DIC(31,DGZERO,0),U)
 . S DG2="("_$S($P(DGARR(DGC),U,3)=1:$P(DGARR(DGC),U,2)_"% SC",$P(DGARR(DGC),U,3)]"":$P(DGARR(DGC),U,2)_"% NSC",1:"unspec")_")"
 . S DG4=$P(DGARR(DGC),U,4),DG5=$P(DGARR(DGC),U,5),DG6=$P(DGARR(DGC),U,6)
 . I DG5]"" S Y=DG5 X ^DD("DD") S DGORIG=Y
 . I DG6]"" S Y=DG6 X ^DD("DD") S DGCURR=Y
 . I $Y>(IOSL-3) D PAUSE^DGRPDB I $G(DGQUIT)=0 W @IOF
 . I $G(DGQUIT)=1 Q
 . W !,$G(DG0)_"-",DG1,DG2,?47,$G(DG4),?50," - ",?53,$G(DGORIG),?64," - ",?68,$G(DGCURR)
 W:'I3 !,"NONE STATED"
HBP ; LINE FOR HEALTH BENEFIT PLAN (DG*53*871)
 W ! S Z=5
 W:DGRPW ! S Z="["_Z_"]"
 I DGRPCM!($E(Z)="[") W @DGVI,Z,@DGVO
 I 'DGRPCM&($E(Z)'="[") W Z
 ; D WW^DGRPV     Removed to always have #5 selectable then sub screens of 11 will control edit and view capabilities
 W " Veteran Medical Benefit Plan (VMBP): " N CNT,PLN D  ;DG*5.3*987 HM
 . S (CNT,PLN)=0 F  S PLN=$O(^DPT(DFN,"HBP",PLN)) Q:PLN<1  S CNT=CNT+1
 W $S(CNT>0:" ("_CNT_" Plan"_$S(CNT=1:"",1:"s")_" on file)",1:" (None Specified)")
Q G ^DGRPP
