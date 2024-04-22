/*============================================================================================
Project:   CCDR Togo
Author:    Kolohotia Kadidia Kone
Creation Date:  October 2023
Output: Consumption data 
============================================================================================*/


//Consumption
use "$data/ehcvm_conso_tgo2018.dta",clear
	ren hhid idh

	preserve
	use "$temp/02 Load groups.dta", clear 
	collapse (max) quanturb quantrural weight, by(idh) 
	tempfile groupuniq
	save `groupuniq'
	restore
	
	merge m:1 idh using `groupuniq' 
	
	preserve 
	
	clear 
	set obs 38
	gen cod_product=_n
	
	gen product="e"
	replace	product="A01 PRODUITS DE L'AGRICULTURE" if  cod_product==	1
	replace	product="A02 PRODUITS DE L'ELEVAGE ET DE LA CHASSE" if  cod_product==	2
	replace	product="A03 PRODUITS DE LA SYLVICULTURE, DE L'EXPLOITATIO" if  cod_product==	3
	replace	product="A04 PRODUITS DE LA PÊCHE ET DE L'AQUACULTURE" if  cod_product==	4
	replace	product="B05 PRODUITS DES INDUSTRIES EXTRACTIVES" if  cod_product==	5
	replace	product="B06 PRODUITS ALIMENTAIRES" if  cod_product==	6
	replace	product="B07 BOISSONS" if  cod_product==	7
	replace	product="C08 PRODUITS A BASE DE TABAC" if  cod_product==	8
	replace	product="C09 PRODUITS TEXTILES, ARTICLES D'HABILLEMENT, EN" if  cod_product==	9
	replace	product="C10 PRODUITS EN BOIS, EN PAPIER OU EN CARTON, TRA" if  cod_product==	10
	replace	product="C11 PRODUITS DU RAFFINAGE ET DE LA COKÉFACTION ET" if  cod_product==	11
	replace	product="C12 PRODUITS PHARMACEUTIQUES" if  cod_product==	12
	replace	product="C13 PRODUITS DU TRAVAIL DU CAOUTCHOUC ET DU PLAST" if  cod_product==	13
	replace	product="C14 MATERIAUX MINERAUX" if  cod_product==	14
	replace	product="C15 PRODUITS MÉTALLURGIQUES ET DE FONDERIE" if  cod_product==	15
	replace	product="C16 MACHINES, MATERIELS ET EQUIPEMENTS DIVERS" if  cod_product==	16
	replace	product="C17 PRODUITS DES AUTRES INDUSTRIES MANUFACTURIERE" if  cod_product==	17
replace	product="C18 REPARATION ET INSTALLATION DE MACHINES ET D'E" if  cod_product==	18
replace	product="D19 ÉLECTRICITÉ ET GAZ" if  cod_product==	19
replace	product="E20 TRAVAUX DE PRODUCTION ET DISTRIBUTION D'EAU, " if  cod_product==	20
replace	product="F21 TRAVAUX DE CONSTRUCTION " if  cod_product==	21
replace	product="G22 VENTE" if  cod_product==	22
replace	product="H23 SERVICES DE TRANSPORTS, ENTREPOSAGE" if  cod_product==	23
replace	product="I24 SERVICES D'HEBERGEMENT ET DE RESTAURATION" if  cod_product==	24
replace	product="J25 SERVICES D'INFORMATION ET DE COMMUNICATION" if  cod_product==	25
replace	product="K26 SERVICES FINANCIERS ET D'ASSURANCE" if  cod_product==	26
replace	product="L27 SERVICES IMMOBILIERS" if  cod_product==	27
replace	product="M28 SERVICES SPECIALISES, SCIENTIFIQUES ET TECHNI" if  cod_product==	28
replace	product="N29 SERVICES DE SOUTIEN ET DE BUREAU" if  cod_product==	29
replace	product="O30 SERVICES D'ADMINISTRATION PUBLIQUE" if  cod_product==	30
replace	product="P31 SERVICES D'ENSEIGNEMENT" if  cod_product==	31
replace	product="Q32 SERVICES DE SANTÉ HUMAINE ET D'ACTION SOCIALE" if  cod_product==	32
replace	product="R33 SERVICES ARTISTIQUES, SPORTIFS ET RECREATIFS" if  cod_product==	33
replace	product="S34 AUTRES SERVICES N.C.A." if  cod_product==	34
replace	product="T35 SERVICES SPECIAUX DES MÉNAGES" if  cod_product==	35
replace	product="U36 SERVICES DES ORGANISATIONS EXTRATERRITORIALES" if  cod_product==	36
replace	product="Y37 CORRECTION TERRITORIALE" if  cod_product==	37
replace	product="Z99 PRODUITS D'ATTENTE" if  cod_product==	38

	tempfile product_IO
	save `product_IO'
	
	restore

*****Create variable "categorie" with 900 as arbitrary value*******
gen categorie= 900

**********Attribute products to one category of IO matrix *******

replace categorie=	1	if codpr==	1
replace categorie=	1	if codpr==	2
replace categorie=	1	if codpr==	3
replace categorie=	1	if codpr==	4
replace categorie=	1	if codpr==	5
replace categorie=	1	if codpr==	6
replace categorie=	1	if codpr==	7
replace categorie=	1	if codpr==	8
replace categorie=	1	if codpr==	9
replace categorie=	1	if codpr==	10
replace categorie=	1	if codpr==	11
replace categorie=	6	if codpr==	12
replace categorie=	6	if codpr==	13
replace categorie=	6	if codpr==	14
replace categorie=	6	if codpr==	15
replace categorie=	6	if codpr==	16
replace categorie=	6	if codpr==	17
replace categorie=	6	if codpr==	18
replace categorie=	6	if codpr==	19
replace categorie=	6	if codpr==	20
replace categorie=	6	if codpr==	21
replace categorie=	6	if codpr==	22
replace categorie=	2	if codpr==	23
replace categorie=	2	if codpr==	24
replace categorie=	2	if codpr==	25
replace categorie=	2	if codpr==	26
replace categorie=	2	if codpr==	27
replace categorie=	2	if codpr==	28
replace categorie=	2	if codpr==	29
replace categorie=	2	if codpr==	30
replace categorie=	2	if codpr==	31
replace categorie=	6	if codpr==	32
replace categorie=	2	if codpr==	33
replace categorie=	2	if codpr==	34
replace categorie=	4	if codpr==	35
replace categorie=	4	if codpr==	36
replace categorie=	4	if codpr==	37
replace categorie=	4	if codpr==	38
replace categorie=	4	if codpr==	39
replace categorie=	4	if codpr==	40
replace categorie=	4	if codpr==	41
replace categorie=	4	if codpr==	42
replace categorie=	6	if codpr==	43
replace categorie=	6	if codpr==	44
replace categorie=	6	if codpr==	45
replace categorie=	6	if codpr==	46
replace categorie=	6	if codpr==	47
replace categorie=	6	if codpr==	48
replace categorie=	6	if codpr==	49
replace categorie=	6	if codpr==	50
replace categorie=	6	if codpr==	51
replace categorie=	2	if codpr==	52
replace categorie=	6	if codpr==	53
replace categorie=	6	if codpr==	54
replace categorie=	6	if codpr==	55
replace categorie=	6	if codpr==	56
replace categorie=	6	if codpr==	57
replace categorie=	6	if codpr==	58
replace categorie=	6	if codpr==	59
replace categorie=	1	if codpr==	60
replace categorie=	1	if codpr==	61
replace categorie=	1	if codpr==	62
replace categorie=	1	if codpr==	63
replace categorie=	1	if codpr==	64
replace categorie=	1	if codpr==	65
replace categorie=	1	if codpr==	66
replace categorie=	1	if codpr==	67
replace categorie=	1	if codpr==	68
replace categorie=	1	if codpr==	69
replace categorie=	1	if codpr==	70
replace categorie=	1	if codpr==	71
replace categorie=	1	if codpr==	72
replace categorie=	1	if codpr==	73
replace categorie=	1	if codpr==	74
replace categorie=	1	if codpr==	75
replace categorie=	1	if codpr==	76
replace categorie=	1	if codpr==	77
replace categorie=	1	if codpr==	78
replace categorie=	1	if codpr==	79
replace categorie=	1	if codpr==	80
replace categorie=	1	if codpr==	81
replace categorie=	1	if codpr==	82
replace categorie=	1	if codpr==	83
replace categorie=	1	if codpr==	84
replace categorie=	1	if codpr==	85
replace categorie=	1	if codpr==	86
replace categorie=	1	if codpr==	87
replace categorie=	1	if codpr==	88
replace categorie=	1	if codpr==	89
replace categorie=	1	if codpr==	90
replace categorie=	6	if codpr==	91
replace categorie=	1	if codpr==	92
replace categorie=	1	if codpr==	93
replace categorie=	1	if codpr==	94
replace categorie=	1	if codpr==	95
replace categorie=	1	if codpr==	96
replace categorie=	1	if codpr==	97
replace categorie=	1	if codpr==	98
replace categorie=	1	if codpr==	99
replace categorie=	1	if codpr==	100
replace categorie=	1	if codpr==	101
replace categorie=	1	if codpr==	102
replace categorie=	1	if codpr==	103
replace categorie=	1	if codpr==	104
replace categorie=	1	if codpr==	105
replace categorie=	1	if codpr==	106
replace categorie=	1	if codpr==	107
replace categorie=	1	if codpr==	108
replace categorie=	1	if codpr==	109
replace categorie=	1	if codpr==	110
replace categorie=	6	if codpr==	111
replace categorie=	6	if codpr==	112
replace categorie=	6	if codpr==	113
replace categorie=	6	if codpr==	114
replace categorie=	6	if codpr==	115
replace categorie=	6	if codpr==	116
replace categorie=	6	if codpr==	117
replace categorie=	6	if codpr==	118
replace categorie=	6	if codpr==	119
replace categorie=	6	if codpr==	120
replace categorie=	6	if codpr==	121
replace categorie=	6	if codpr==	122
replace categorie=	6	if codpr==	123
replace categorie=	6	if codpr==	124
replace categorie=	6	if codpr==	125
replace categorie=	6	if codpr==	126
replace categorie=	1	if codpr==	127
replace categorie=	6	if codpr==	128
replace categorie=	6	if codpr==	129
replace categorie=	6	if codpr==	130
replace categorie=	6	if codpr==	131
replace categorie=	6	if codpr==	132
replace categorie=	6	if codpr==	133
replace categorie=	6	if codpr==	134
replace categorie=	6	if codpr==	135
replace categorie=	6	if codpr==	136
replace categorie=	6	if codpr==	137
replace categorie=	6	if codpr==	138
replace categorie=	6	if codpr==	139
replace categorie=	6	if codpr==	140
replace categorie=	6	if codpr==	151
replace categorie=	6	if codpr==	152
replace categorie=	1	if codpr==	161
replace categorie=	2	if codpr==	162
replace categorie=	2	if codpr==	163
replace categorie=	4	if codpr==	164
replace categorie=	8	if codpr==	201
replace categorie=	11	if codpr==	202
replace categorie=	3	if codpr==	203
replace categorie=	3	if codpr==	204
replace categorie=	3	if codpr==	205
replace categorie=	17	if codpr==	206
replace categorie=	17	if codpr==	207
replace categorie=	11	if codpr==	208
replace categorie=	11	if codpr==	209
replace categorie=	23	if codpr==	210
replace categorie=	23	if codpr==	211
replace categorie=	23	if codpr==	212
replace categorie=	23	if codpr==	213
replace categorie=	23	if codpr==	214
replace categorie=	23	if codpr==	215
replace categorie=	25	if codpr==	216
replace categorie=	6	if codpr==	217
replace categorie=	7	if codpr==	301
replace categorie=	7	if codpr==	302
replace categorie=	19	if codpr==	303
replace categorie=	11	if codpr==	304
replace categorie=	17	if codpr==	305
replace categorie=	17	if codpr==	306
replace categorie=	17	if codpr==	307
replace categorie=	35	if codpr==	308
replace categorie=	35	if codpr==	309
replace categorie=	35	if codpr==	310
replace categorie=	35	if codpr==	311
replace categorie=	35	if codpr==	312
replace categorie=	25	if codpr==	313
replace categorie=	34	if codpr==	314
replace categorie=	25	if codpr==	315
replace categorie=	34	if codpr==	316
replace categorie=	17	if codpr==	317
replace categorie=	17	if codpr==	318
replace categorie=	10	if codpr==	319
replace categorie=	20	if codpr==	320
replace categorie=	17	if codpr==	321
replace categorie=	17	if codpr==	322
replace categorie=	35	if codpr==	331
replace categorie=	20	if codpr==	332
replace categorie=	20	if codpr==	333
replace categorie=	19	if codpr==	334
replace categorie=	25	if codpr==	335
replace categorie=	25	if codpr==	336
replace categorie=	25	if codpr==	337
replace categorie=	25	if codpr==	338
replace categorie=	9	if codpr==	401
replace categorie=	17	if codpr==	402
replace categorie=	17	if codpr==	403
replace categorie=	18	if codpr==	404
replace categorie=	23	if codpr==	405
replace categorie=	23	if codpr==	406
replace categorie=	23	if codpr==	407
replace categorie=	26	if codpr==	408
replace categorie=	26	if codpr==	409
replace categorie=	17	if codpr==	410
replace categorie=	34	if codpr==	411
replace categorie=	33	if codpr==	412
replace categorie=	33	if codpr==	413
replace categorie=	33	if codpr==	414
replace categorie=	17	if codpr==	415
replace categorie=	17	if codpr==	416
replace categorie=	17	if codpr==	417
replace categorie=	34	if codpr==	418
replace categorie=	9	if codpr==	501
replace categorie=	9	if codpr==	502
replace categorie=	9	if codpr==	503
replace categorie=	9	if codpr==	504
replace categorie=	9	if codpr==	505
replace categorie=	9	if codpr==	506
replace categorie=	9	if codpr==	507
replace categorie=	9	if codpr==	508
replace categorie=	9	if codpr==	509
replace categorie=	9	if codpr==	510
replace categorie=	9	if codpr==	511
replace categorie=	9	if codpr==	512
replace categorie=	9	if codpr==	521
replace categorie=	21	if codpr==	601
replace categorie=	21	if codpr==	602
replace categorie=	21	if codpr==	603
replace categorie=	21	if codpr==	604
replace categorie=	27	if codpr==	605
replace categorie=	27	if codpr==	606
replace categorie=	21	if codpr==	607
replace categorie=	20	if codpr==	608
replace categorie=	19	if codpr==	609
replace categorie=	20	if codpr==	610
replace categorie=	19	if codpr==	611
replace categorie=	17	if codpr==	612
replace categorie=	17	if codpr==	613
replace categorie=	18	if codpr==	614
replace categorie=	17	if codpr==	615
replace categorie=	17	if codpr==	616
replace categorie=	17	if codpr==	617
replace categorie=	17	if codpr==	618
replace categorie=	17	if codpr==	619
replace categorie=	17	if codpr==	620
replace categorie=	17	if codpr==	621
replace categorie=	17	if codpr==	622
replace categorie=	35	if codpr==	623
replace categorie=	35	if codpr==	624
replace categorie=	17	if codpr==	625
replace categorie=	23	if codpr==	626
replace categorie=	23	if codpr==	627
replace categorie=	35	if codpr==	628
replace categorie=	23	if codpr==	629
replace categorie=	23	if codpr==	630
replace categorie=	23	if codpr==	631
replace categorie=	23	if codpr==	632
replace categorie=	17	if codpr==	633
replace categorie=	17	if codpr==	634
replace categorie=	17	if codpr==	635
replace categorie=	18	if codpr==	636
replace categorie=	17	if codpr==	637
replace categorie=	33	if codpr==	638
replace categorie=	10	if codpr==	639
replace categorie=	10	if codpr==	640
replace categorie=	35	if codpr==	641
replace categorie=	31	if codpr==	642
replace categorie=	31	if codpr==	643
replace categorie=	24	if codpr==	644
replace categorie=	17	if codpr==	645
replace categorie=	17	if codpr==	646
replace categorie=	17	if codpr==	647
replace categorie=	26	if codpr==	648
replace categorie=	26	if codpr==	649
replace categorie=	26	if codpr==	650
replace categorie=	26	if codpr==	651
replace categorie=	30	if codpr==	652
replace categorie=	25	if codpr==	653
replace categorie=	31	if codpr==	661
replace categorie=	31	if codpr==	662
replace categorie=	31	if codpr==	663
replace categorie=	31	if codpr==	664
replace categorie=	31	if codpr==	665
replace categorie=	31	if codpr==	666
replace categorie=	31	if codpr==	667
replace categorie=	31	if codpr==	668
replace categorie=	31	if codpr==	669
replace categorie=	31	if codpr==	670
replace categorie=	31	if codpr==	671
replace categorie=	31	if codpr==	672
replace categorie=	32	if codpr==	681
replace categorie=	32	if codpr==	682
replace categorie=	32	if codpr==	683
replace categorie=	32	if codpr==	684
replace categorie=	32	if codpr==	685
replace categorie=	12	if codpr==	686
replace categorie=	32	if codpr==	691
replace categorie=	32	if codpr==	692
replace categorie=	17	if codpr==	801
replace categorie=	17	if codpr==	802
replace categorie=	17	if codpr==	803
replace categorie=	17	if codpr==	804
replace categorie=	17	if codpr==	805
replace categorie=	17	if codpr==	806
replace categorie=	17	if codpr==	807
replace categorie=	17	if codpr==	808
replace categorie=	17	if codpr==	809
replace categorie=	17	if codpr==	810
replace categorie=	17	if codpr==	811
replace categorie=	17	if codpr==	812
replace categorie=	17	if codpr==	813
replace categorie=	17	if codpr==	814
replace categorie=	17	if codpr==	815
replace categorie=	17	if codpr==	816
replace categorie=	17	if codpr==	817
replace categorie=	17	if codpr==	818
replace categorie=	17	if codpr==	819
replace categorie=	17	if codpr==	820
replace categorie=	17	if codpr==	821
replace categorie=	17	if codpr==	822
replace categorie=	17	if codpr==	823
replace categorie=	17	if codpr==	824
replace categorie=	17	if codpr==	825
replace categorie=	17	if codpr==	826
replace categorie=	17	if codpr==	827
replace categorie=	17	if codpr==	828
replace categorie=	17	if codpr==	829
replace categorie=	17	if codpr==	830
replace categorie=	17	if codpr==	831
replace categorie=	17	if codpr==	832
replace categorie=	17	if codpr==	833
replace categorie=	17	if codpr==	834
replace categorie=	17	if codpr==	835
replace categorie=	17	if codpr==	836
replace categorie=	17	if codpr==	837
replace categorie=	17	if codpr==	838
replace categorie=	17	if codpr==	839
replace categorie=	17	if codpr==	840
replace categorie=	17	if codpr==	841
replace categorie=	17	if codpr==	842
replace categorie=	17	if codpr==	843

***************Verification of category **************

****Normally categorie==900 musn't be appear
tab categorie

ren categorie cod_product



**********recode category to new categories***********************
/*
replace categorie=	1	if categorie==	1
replace categorie=	2	if categorie==	2
replace categorie=	1	if categorie==	3
replace categorie=	2	if categorie==	4
replace categorie=	1	if categorie==	5
replace categorie=	4	if categorie==	6
replace categorie=	4	if categorie==	7
replace categorie=	4	if categorie==	8
replace categorie=	4	if categorie==	9
replace categorie=	4	if categorie==	10
replace categorie=	4	if categorie==	11
replace categorie=	4	if categorie==	12
replace categorie=	4	if categorie==	13
replace categorie=	4	if categorie==	14
replace categorie=	4	if categorie==	15
replace categorie=	4	if categorie==	16
replace categorie=	4	if categorie==	17
replace categorie=	5	if categorie==	18
replace categorie=	7	if categorie==	19
replace categorie=	7	if categorie==	20
replace categorie=	5	if categorie==	21
replace categorie=	7	if categorie==	22
replace categorie=	6	if categorie==	23
replace categorie=	6	if categorie==	24
replace categorie=	6	if categorie==	25
replace categorie=	7	if categorie==	26
replace categorie=	5	if categorie==	27
replace categorie=	7	if categorie==	28
replace categorie=	7	if categorie==	29
replace categorie=	7	if categorie==	30
replace categorie=	7	if categorie==	31
replace categorie=	7	if categorie==	32
replace categorie=	7	if categorie==	33
replace categorie=	7	if categorie==	34
replace categorie=	7	if categorie==	35

	
//Label of products	
label def categorie 1 "Agriculture Mining and forestry" 2	"Fishery & livestock"  4	"Manufacturing"	5	"Construction and repair" 6 "Transport Commun Hotel and rest" 7	"Business, Finance, Government and other services"
*/

merge m:1 cod_product using `product_IO', nogen

ren cod_product categorie


replace quantrural=1 if depan==.
replace quanturb=1 if depan==.
replace hhweight=1 if depan==.
replace depan=0 if depan==.

//Define excel sheet 
putexcel set "$results/SAMshares.xlsx", sheet(HH Consumption) modify


///Consumption by urban area
preserve
collapse (sum) depan [iw=hhweight], by(categorie product quanturb) cw
drop if quanturb==.
reshape wide depan , i(categorie product) j(quanturb)

 
//write in the excel sheetsheet

tabstat depan*, by(categorie) save
qui tabstatmat A, nototal
putexcel I5 = matrix(A)

restore

///Consumption by rural area
preserve
collapse (sum) depan [iw=hhweight], by(categorie product quantrural)
drop if quantrural==.
reshape wide depan , i(categorie product ) j(quantrural)


//write in the excel sheetsheet

tabstat depan*, by(categorie) save
qui tabstatmat A, nototal
putexcel D5 = matrix(A)

restore