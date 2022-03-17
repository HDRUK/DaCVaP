-----------------------------------------------------------
--vac17: 	Vaccine Safety
--BY:		fatemeh.torabi@swansea.ac.uk
--DT: 		2021-04-08
--aim:		analysis ready table
-----------------------------------------------------------
CALL FNC.DROP_IF_EXISTS ('SAILW0911V.vac17_ANALYSIS');

CREATE TABLE SAILW0911V.vac17_ANALYSIS AS
(
SELECT
						A.ALF_E,
						A.ALF_TYPE,
						B.AGE,
						B.C20_GNDR_CD SEX,
						CASE
						WHEN A.ALF_TYPE='CASE' THEN 1
						WHEN A.ALF_TYPE='CONTROL' THEN 0
						END AS event,
						B.INCIDENT_DT AS EVENT_TIME,
						B.INCIDENT_TYPE AS EVENT_TYPE,
						B.INCIDENT_CAT AS EVENT_CAT, 
					---
					--clearance: 2019-01-09 to 2020-12-06
					    B.gp_clearance_vte_dt 							,  
					    B.gp_clearance_csvt_dt				 			, 
						B.gp_clearance_haemorrhage_dt			 		,
					    B.gp_clearance_thrombocytopenia_dt	 			, 
					    B.gp_clearance_ITP_dt					 		,
					    B.gp_clearance_at_dt					 		,    
					
					--post     2020-12-07 to 2021-02-28   
					  	B.gp_post_vte_dt				 				,  
					    B.gp_post_csvt_dt					 			, 
					    B.gp_post_haemorrhage_dt		 				,    
					    B.gp_post_thrombocytopenia_dt		 			, 
					    B.gp_post_ITP_dt 					 			,
					    B.gp_post_at_dt 					 			,
					 --all in one
					    B.gp_incident_dt              ,
					    B.gp_incident_type            ,
					    B.gp_incident_cat             ,   
					 --clearance: 2019-01-09 to 2020-12-06
					    B.pedw_clearance_vte_dt 						,  
					    B.pedw_clearance_csvt_dt				 		, 
						B.pedw_clearance_haemorrhage_dt			 		,
					    B.pedw_clearance_thrombocytopenia_dt	 		, 
					    B.pedw_clearance_ITP_dt					 		,
					    B.pedw_clearance_at_dt					 		,    
					
					--post     2020-12-07 to 2021-02-28   
					  	B.pedw_post_vte_dt				 				,  
					    B.pedw_post_csvt_dt					 			, 
					    B.pedw_post_haemorrhage_dt		 				,    
					    B.pedw_post_thrombocytopenia_dt		 			, 
					    B.pedw_post_ITP_dt 					 			,
					    B.pedw_post_at_dt 					 			,    
					 --all in one
					    B.pedw_incident_dt        ,
					    B.pedw_incident_type      ,
					    B.pedw_incident_cat       ,   
					 ---END/incident categories and dates  
						B.pre_vacc_followup,
						B.post_vacc_followup,
						B.person_days_exposed,

						A.GROUPS,
						CASE
						WHEN B.VACC_FIRST_DATE >= '2020-12-07' THEN VACC_FIRST_DATE
						ELSE NULL
						END AS VACC_DT,
						B.VACC_SECOND_DATE AS VACC_DOSE2_DT,
						CASE
						WHEN B.VACC_FIRST_DATE >= '2020-12-07' AND B.VACC_FIRST_NAME ='COVID-19 (PFIZER BIONTECH)' 	THEN 'PB'
						WHEN B.VACC_FIRST_DATE >= '2020-12-07' AND B.VACC_FIRST_NAME ='COVID-19 (ASTRAZENECA)' 		THEN 'AZ'
						END AS VACC_TYPE,
						DAYS(A.INCIDENT_DT) - DAYS(b.VACC_FIRST_DATE)
						AS EVENT_TO_VACC_DAYS,
						CASE
						WHEN (DAYS(A.INCIDENT_DT) - DAYS(b.VACC_FIRST_DATE)) BETWEEN 0 	AND 6 	THEN 	'0-6 DAYS'
						WHEN (DAYS(A.INCIDENT_DT) - DAYS(b.VACC_FIRST_DATE)) BETWEEN 7 	AND 13 	THEN 	'7-13 DAYS'
						WHEN (DAYS(A.INCIDENT_DT) - DAYS(b.VACC_FIRST_DATE)) BETWEEN 14 AND 20 	THEN 	'14-20 DAYS'
						WHEN (DAYS(A.INCIDENT_DT) - DAYS(b.VACC_FIRST_DATE)) BETWEEN 21 AND 27 	THEN  	'21-27 DAYS'
						WHEN (DAYS(A.INCIDENT_DT) - DAYS(b.VACC_FIRST_DATE))  >= 28		THEN  	'28+ DAYS'
						ELSE NULL
						END AS VS,
						CASE
						WHEN (DAYS(A.INCIDENT_DT) - DAYS(b.VACC_FIRST_DATE)) BETWEEN 0 	AND 28 	THEN 	'0-28 DAYS'
						ELSE NULL
						END AS VS_0_28,
						CASE
						WHEN B.VACC_FIRST_DATE >= '2020-12-07' THEN 'V'
						ELSE NULL END AS VACC_STATUS,
						B.WIMD_2019_QUINTILE,
						A.MSOA2011_CD ,
						CASE
						WHEN b.age < 16 				THEN '0-15'
						WHEN b.age BETWEEN 16 AND 19 	THEN '16-19'
						WHEN b.age BETWEEN 20 AND 39	THEN '20-39'
						WHEN b.age BETWEEN 40 AND 59 	THEN '40-59'
						WHEN b.age BETWEEN 60 AND 79	THEN '60-79'
						WHEN b.age >=80					THEN '80+'
						END AS AGE_BAND,
						B.Prior_testing_n AS N_TESTS,
						B.has_positive_test,
						CASE
						WHEN B.has_positive_test=0 THEN 'no pos test'
						WHEN B.has_positive_test=1 THEN 'pos test'
						ELSE NULL END AS POS_TEST_status,
				    B.qc_b2_82             ,
				    B.qc_b2_leukolaba        ,
				    B.qc_b2_prednisolone     ,
				    B.qc_b_af                ,
				    B.qc_b_ccf               ,
				    B.qc_b_asthma            ,
				    B.qc_b_bloodcancer       ,
				    B.qc_b_cerebralpalsy     ,
				    B.qc_b_chd               ,
				    B.qc_b_cirrhosis         ,
				    B.qc_b_congenheart       ,
				    B.qc_b_copd              ,
				    B.qc_b_dementia          ,
				    B.qc_b_epilepsy          ,
				    B.qc_b_fracture4         ,
				    B.qc_b_neurorare         ,
				    B.qc_b_parkinsons        ,
				    B.qc_b_pulmhyper         ,
				    B.qc_b_pulmrare          ,
				    B.qc_b_pvd               ,
				    B.qc_b_ra_sle            ,
				    B.qc_b_respcancer        ,
				    B.qc_b_semi              ,
				    B.qc_b_sicklecelldisease ,
				    B.qc_b_stroke            ,
				    B.qc_diabetes_cat        ,
				    B.qc_b_vte               ,
				    B.qc_bmi                 ,
				    B.qc_chemo_cat           ,
				    B.qc_home_cat            ,
				    B.qc_learn_cat           ,
				    B.qc_p_marrow6           ,
				    B.qc_p_radio6            ,
				    B.qc_p_solidtransplant   ,
				    B.qc_renal_cat           ,
				    B.smoking_cat            ,
				   	B.hypertension_event	 ,
				    B.hypertension_cat
				FROM SAILW0911V.vac17_CC 	A
				LEFT JOIN
				SAILW0911V.vac17_COHORT	B
				ON
				A.ALF_E =B.ALF_E
)WITH NO DATA;


--granting access to team mates
GRANT ALL ON TABLE SAILW0911V.vac17_ANALYSIS TO ROLE NRDASAIL_SAIL_0911_ANALYST;


INSERT INTO SAILW0911V.vac17_ANALYSIS
SELECT
						A.ALF_E,
						A.ALF_TYPE,
						B.AGE,
						B.C20_GNDR_CD SEX,
						CASE
						WHEN A.ALF_TYPE='CASE' THEN 1
						WHEN A.ALF_TYPE='CONTROL' THEN 0
						END AS event,
						B.INCIDENT_DT AS EVENT_TIME,
						B.INCIDENT_TYPE AS EVENT_TYPE,
						B.INCIDENT_CAT AS EVENT_CAT, 
					---
					--clearance: 2019-01-09 to 2020-12-06
					    B.gp_clearance_vte_dt 							,  
					    B.gp_clearance_csvt_dt				 			, 
						B.gp_clearance_haemorrhage_dt			 		,
					    B.gp_clearance_thrombocytopenia_dt	 			, 
					    B.gp_clearance_ITP_dt					 		,
					    B.gp_clearance_at_dt					 		,    

					--post     2020-12-07 to 2021-02-28   
					  	B.gp_post_vte_dt				 				,  
					    B.gp_post_csvt_dt					 			, 
					    B.gp_post_haemorrhage_dt		 				,    
					    B.gp_post_thrombocytopenia_dt		 			, 
					    B.gp_post_ITP_dt 					 			,
					    B.gp_post_at_dt 					 			,
					 --all in one
					    B.gp_incident_dt              ,
					    B.gp_incident_type            ,
					    B.gp_incident_cat             ,   
					 --clearance: 2019-01-09 to 2020-12-06
					    B.pedw_clearance_vte_dt 						,  
					    B.pedw_clearance_csvt_dt				 		, 
						B.pedw_clearance_haemorrhage_dt			 		,
					    B.pedw_clearance_thrombocytopenia_dt	 		, 
					    B.pedw_clearance_ITP_dt					 		,
					    B.pedw_clearance_at_dt					 		,    

					--post     2020-12-07 to 2021-02-28   
					  	B.pedw_post_vte_dt				 				,  
					    B.pedw_post_csvt_dt					 			, 
					    B.pedw_post_haemorrhage_dt		 				,    
					    B.pedw_post_thrombocytopenia_dt		 			, 
					    B.pedw_post_ITP_dt 					 			,
					    B.pedw_post_at_dt 					 			,    
					 --all in one
					    B.pedw_incident_dt        ,
					    B.pedw_incident_type      ,
					    B.pedw_incident_cat       ,   
					 ---END/incident categories and dates  
						B.pre_vacc_followup,
						B.post_vacc_followup,
						B.person_days_exposed,

						A.GROUPS,
						CASE
						WHEN B.VACC_FIRST_DATE >= '2020-12-07' THEN VACC_FIRST_DATE
						ELSE NULL
						END AS VACC_DT,
						B.VACC_SECOND_DATE AS VACC_DOSE2_DT,
						CASE
						WHEN B.VACC_FIRST_DATE >= '2020-12-07' AND B.VACC_FIRST_NAME ='COVID-19 (PFIZER BIONTECH)' 	THEN 'PB'
						WHEN B.VACC_FIRST_DATE >= '2020-12-07' AND B.VACC_FIRST_NAME ='COVID-19 (ASTRAZENECA)' 		THEN 'AZ'
						END AS VACC_TYPE,
						DAYS(A.INCIDENT_DT) - DAYS(b.VACC_FIRST_DATE)
						AS EVENT_TO_VACC_DAYS,
						CASE
						WHEN (DAYS(A.INCIDENT_DT) - DAYS(b.VACC_FIRST_DATE)) BETWEEN 0 	AND 6 	THEN 	'0-6 DAYS'
						WHEN (DAYS(A.INCIDENT_DT) - DAYS(b.VACC_FIRST_DATE)) BETWEEN 7 	AND 13 	THEN 	'7-13 DAYS'
						WHEN (DAYS(A.INCIDENT_DT) - DAYS(b.VACC_FIRST_DATE)) BETWEEN 14 AND 20 	THEN 	'14-20 DAYS'
						WHEN (DAYS(A.INCIDENT_DT) - DAYS(b.VACC_FIRST_DATE)) BETWEEN 21 AND 27 	THEN  	'21-27 DAYS'
						WHEN (DAYS(A.INCIDENT_DT) - DAYS(b.VACC_FIRST_DATE))  >= 28		THEN  	'28+ DAYS'
						ELSE NULL
						END AS VS,
						CASE
						WHEN (DAYS(A.INCIDENT_DT) - DAYS(b.VACC_FIRST_DATE)) BETWEEN 0 	AND 28 	THEN 	'0-28 DAYS'
						ELSE NULL
						END AS VS_0_28,
						CASE
						WHEN B.VACC_FIRST_DATE >= '2020-12-07' THEN 'V'
						ELSE NULL END AS VACC_STATUS,
						B.WIMD_2019_QUINTILE,
						A.MSOA2011_CD ,
						CASE
						WHEN b.age < 16 				THEN '0-15'
						WHEN b.age BETWEEN 16 AND 19 	THEN '16-19'
						WHEN b.age BETWEEN 20 AND 39	THEN '20-39'
						WHEN b.age BETWEEN 40 AND 59 	THEN '40-59'
						WHEN b.age BETWEEN 60 AND 79	THEN '60-79'
						WHEN b.age >=80					THEN '80+'
						END AS AGE_BAND,
						B.Prior_testing_n AS N_TESTS,
						B.has_positive_test,
						CASE
						WHEN B.has_positive_test=0 THEN 'no pos test'
						WHEN B.has_positive_test=1 THEN 'pos test'
						ELSE NULL END AS POS_TEST_status,
				    B.qc_b2_82             ,
				    B.qc_b2_leukolaba        ,
				    B.qc_b2_prednisolone     ,
				    B.qc_b_af                ,
				    B.qc_b_ccf               ,
				    B.qc_b_asthma            ,
				    B.qc_b_bloodcancer       ,
				    B.qc_b_cerebralpalsy     ,
				    B.qc_b_chd               ,
				    B.qc_b_cirrhosis         ,
				    B.qc_b_congenheart       ,
				    B.qc_b_copd              ,
				    B.qc_b_dementia          ,
				    B.qc_b_epilepsy          ,
				    B.qc_b_fracture4         ,
				    B.qc_b_neurorare         ,
				    B.qc_b_parkinsons        ,
				    B.qc_b_pulmhyper         ,
				    B.qc_b_pulmrare          ,
				    B.qc_b_pvd               ,
				    B.qc_b_ra_sle            ,
				    B.qc_b_respcancer        ,
				    B.qc_b_semi              ,
				    B.qc_b_sicklecelldisease ,
				    B.qc_b_stroke            ,
				    B.qc_diabetes_cat        ,
				    B.qc_b_vte               ,
				    B.qc_bmi                 ,
				    B.qc_chemo_cat           ,
				    B.qc_home_cat            ,
				    B.qc_learn_cat           ,
				    B.qc_p_marrow6           ,
				    B.qc_p_radio6            ,
				    B.qc_p_solidtransplant   ,
				    B.qc_renal_cat           ,
				    B.smoking_cat            ,
				   	B.hypertension_event	 ,
				    B.hypertension_cat
				FROM SAILW0911V.vac17_CC 	A
				LEFT JOIN
				SAILW0911V.vac17_COHORT	B
				ON
				A.ALF_E =B.ALF_E;



COMMIT;		

--SELECT * FROM SAILW0911V.vac17_ANALYSIS
--ORDER BY groups;
--
SELECT DISTINCT ALF_TYPE, COUNT(*)
FROM SAILW0911V.vac17_ANALYSIS
GROUP BY ALF_TYPE;
