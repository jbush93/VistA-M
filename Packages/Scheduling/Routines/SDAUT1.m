SDAUT1 ;MAN/GRR - AUTO REBOOK SET REQUIRED AVAILABILITY NODES ;28 MAR 84  1:46 pm
 ;;5.3;Scheduling;**140,674**;Aug 13, 1993;Build 18
 K SDXXX S MAX=$S($D(^SC(SC,"SDP")):$P(^("SDP"),"^",4),1:0)
 Q:MAX=0  S STIME=$S($D(^SC(SC,"SDP")):$P(^("SDP"),"^",3),1:"0800"),X1=CDATE,X2=DT D ^%DTC
 I X<10 S X1=$S(CDATE<DT:DT,1:CDATE),X2=10 D C^%DTC S SDSTRTDT=X G OVR
 S SDSTRTDT=CDATE
OVR S SDSOH=$S('$D(^SC(SC,"SL")):0,$P(^("SL"),"^",8)']"":0,1:1)
 S X1=SDSTRTDT,X2=MAX D C^%DTC S ENDATE=$S('$D(SDIN):X,SDIN>SDSTRTDT&(SDIN<X):SDIN,1:X),X=SDSTRTDT
 N SDX,SDIEN,SDBEG,SDDOW,SDBDT ;New variables for SD*5.3*674 changes
 ;Set beginning date to use for indefinite clinic availabilities
 S SDX=0 F  S SDX=$O(^SC(SC,"T",SDX)) Q:'SDX  S SDBEG=$G(^SC(SC,"T",SDX,0)) I '$D(^SC(SC,"OST",SDX))!($D(^SC(SC,"T"_$$DOW^XLFDT(SDBEG,1),SDX))) S SDDOW($$DOW^XLFDT(SDBEG,1),SDBEG)="" ;SD*5.3*674
 F SDX=0:1:6 S:'$D(SDDOW(SDX)) SDDOW(SDX,9999999)="" ;SD*5.3*674
EN1 S:$O(^SC(+SC,"T",0))>X X=$O(^(0)) D DOW S I=Y+32,SM=X,D=Y D WM  ;Change $N to $O, SD*5.3*674
 K J F Y=0:1:6 I $D(^SC(+SC,"T"_Y)) S J(Y)="",DA=+SC,DOW=Y D:'$D(^SC(+SC,"T"_Y,0)) TX^SDB1
 Q:'$D(J)
X1 Q:X>ENDATE  S X1=X\100_28
W S X=X\1 I '$D(^SC(+SC,"ST",X,1)) S SDBDT=$O(SDDOW($$DOW^XLFDT(X,1),(X+1)),-1) I X>=($S(SDBDT:SDBDT,1:9999999)) S Y=D#7 G L:'$D(J(Y)),H:$D(^HOLIDAY(X))&('SDSOH) D  ;check beginning date, SD*5.3*674
 .S SS=$O(^SC(+SC,"T"_Y,X)) G L:SS="",L:^(SS,1)="" S ^SC(+SC,"ST",X\1,1)=$E($P($T(DAY),U,Y+2),1,2)_" "_$E(X,6,7)_$J("",SI+SI-6)_^(1),^(0)=X\1 ;SD*5.3*674
 I $D(SDXXX) S SDXXX=SDXXX+1 W:'(SDXXX#100) "."
 D WM:X>SM
L I X>ENDATE Q
 S X=X+1,D=D+1 G W:X'>X1 S X2=X-X1 D C^%DTC G X1
 ;
H S ^SC(+SC,"ST",X,1)="   "_$E(X,6,7)_"    "_$P(^(X,0),U,2),^(0)=X S:'$D(^SC(+SC,"ST",0)) ^(0)="^44.005DA^^" G W
 ;
WM S SM=$S($E(X,4,5)[12:$E(X,1,3)+1_"01",1:$E(X,1,3)_$E(X,4,5)+1)_"00" Q
 ;
DOW ;
 S Y=$$DOW^XLFDT(X,1)
 Q
 ;
DAY ;;^SUN^MON^TUES^WEDNES^THURS^FRI^SATUR
