-- March 2022  DacVap2 CYP vaccine uptake meta analsysi and household project

-- Creating a table structure to record CYP in Wales based around the C20 cohort 

-- extracting details or children born from 2004 to 2017 
-- basing the table on one create by SB for the other dacvap work 


-- grant permissions
GRANT ALL ON TABLE sailw1151v.dacvap_cohort
TO ROLE nrdasail_sail_1151_analyst;


--  1.set date of first vaccine roll out to be the date when we want people resident in Wales 
CREATE OR REPLACE VARIABLE sailw1151v.dacvap2_start_date DATE DEFAULT '2020-12-07';
CREATE OR REPLACE VARIABLE sailw1151v.dacvap2_17_start_date DATE DEFAULT '2021-08-04';



SELECT 1 FROM sailw1151v.dacvap2_17_start_date;

-- will also  extract my version of the CYP using all the WDSD, NCCH and the C20 
-- still in WMC project folder at the moment
-- created a spine of just the alfs so Sarah can work on her bits 
--  CALL FNC.DROP_IF_EXISTS(' sailw1151v.dacvap2_CYP_spine');
CREATE TABLE   sailw1151v.dacvap2_CYP_spine (
         alf_e   bigint,
		 wob  date,
		 age_aug21 integer, --    children vaccines offered at 4th Oct 21 I think..  
		 age_Dec20  integer,    -- also use date when vaccines made available 7th DEc 2020
		 gndr_cd  integer,		 	 
		 wdds_FLAG  CHAR(1),
		 ncch_flag  char(1),
		 c20_flag   char(1),        
         vulnerable_flag char(1), -- are they in vulnerable  dataset??
         include_flag  char(1)  DEFAULT 'Y'-- are they wanted in final cohort d
           )
 distribute BY hash ( alf_e) ;


--DROP TABLE sailw1151v.dacvap2_CYP_spine
-- truncate table  sailw1151v.dacvap2_CYP_spine immediate;

INSERT INTO  sailw1151v.dacvap2_CYP_spine (alf_e, wob, age_aug21, age_dec20,gndr_cd,wdds_flag) 
-- select count(*), count( distinct alf_e) from (  --   
SELECT DISTINCT alf_e,
			date(wob) AS wob,           
            cast((DAYS(sailw1151v.dacvap2_17_start_date) - days(wob))/365.25 AS integer)  AS age_aug21, 
            cast((DAYS(sailw1151v.dacvap2_start_date) - days(wob))/365.25 AS integer)  AS age_Dec20, 
			gndr_cd,
			'Y'
			FROM SAILWMC_V.C19_COHORT_WDSD_AR_PERS
		WHERE year( wob) BETWEEN 2004 AND 2017
	    --AND alf_sts_cd in( 1,4,39)
	    AND alf_e IS NOT NULL
 --) --end count


 -- now just add the new ones from the ncch
INSERT INTO 	sailw1151v.dacvap2_CYP_spine (alf_e, wob,age_aug21,age_dec20,gndr_cd,ncch_flag ) 
	 SELECT DISTINCT alf_e,
	        date(wob) AS wob,           
            cast((DAYS(sailw1151v.dacvap2_17_start_date) - days(wob))/365.25 AS integer)  AS age_aug21, 
            cast((DAYS(sailw1151v.dacvap2_start_date) - days(wob))/365.25 AS integer)  AS age_Dec20, 
			CASE WHEN gndr_cd	='F' THEN 2
			     WHEN gndr_cd = 'M' THEN 1
			     ELSE 9
			     END AS gndr_cd,
			     'Y'
	       FROM SAILWMC_V.C19_COHORT_NCCH_CHILD_BIRTHS
	    WHERE year( wob) BETWEEN 2004 AND 2017
	        AND alf_sts_cd in( 1,4,39) 
	        AND alf_e NOT IN ( SELECT alf_e FROM sailw1151v.dacvap2_CYP_spine) -- not in here already 
 
	        
	        -- now add in any other child in C20 not in spine already ..was about 2
INSERT into sailw1151v.dacvap2_CYP_spine (alf_e, wob,age_aug21,age_dec20,gndr_cd,c20_flag ) 
	    SELECT DISTINCT alf_e,
	    			wob,
	    			cast((DAYS(sailw1151v.dacvap2_17_start_date) - days(wob))/365.25 AS integer)  AS age_aug21, 
            		cast((DAYS(sailw1151v.dacvap2_start_date) - days(wob))/365.25 AS integer)  AS age_Dec20, 
	    			gndr_cd,
	    			'Y'  -- c20_flag
	    FROM SAILWMC_V.C19_COHORT20 
	    WHERE year( wob) BETWEEN 2004 AND 2017
	       -- AND alf_sts_cd in( 1,4,39) 
	        AND alf_e NOT IN ( SELECT alf_e FROM sailw1151v.dacvap2_CYP_spine) -- not in here already    
	        
UPDATE 	sailw1151v.dacvap2_CYP_spine 
SET ncch_flag ='Y' 
WHERE alf_e IN (SELECT DISTINCT alf_e 
                 FROM SAILWMC_V.C19_COHORT_NCCH_CHILD_BIRTHS
	              -- WHERE year( wob) BETWEEN 2004 AND 2017
	                   -- AND alf_sts_cd in( 1,4,39) 
	        )
 
UPDATE   sailw1151v.dacvap2_CYP_spine rg  
SET c20_flag='Y' WHERE     rg.alf_e IN ( SELECT DISTINCT alf_e 
                         FROM SAILWMC_V.C19_COHORT20 )   
                         
--  !!!       LEAVE setting the include flag FOR now AS may NOT need it. 
COMMIT;

-- *********************************** end of creation of ALL found  CYP spine ***********************
-- *********************************************************************************************


-- quick checks 
SELECT count(*), count( DISTINCT alf_e)  
FROM sailw1151v.dacvap2_CYP_spine
   WHERE c20_flag='Y'  

   
   
-- *********************************** Begin creation of main cohort**************************************
--
--  
--                                    !!!!!!!!!!!!!!!!!!!!!        
-- For now keep the spine in case someone changes their mind about how we identify the children 
--                                  from these tables


-- NOTE:  At the moment ( March 23rd 2022) only want the children flagged in c20  

   
   -- This will be our group of eligbleyoung folk 

--  CALL FNC.DROP_IF_EXISTS('sailw1151v.dacvap2_CYP');   
CREATE TABLE   sailw1151v.dacvap2_CYP (
-- main id
	alf_e                         bigint not null,  -- c20
-- c19 cohort 20
	pers_id_e                     bigint,   -- ?? not sure where Stu gets this from as in several table.. check
	wob                           date,   -- overwrite original with C20 vesion for consitency
	age_dec_2020                  SMALLINT,   -- calculate from dec 7th 2020
	age_aug_2021				  SMALLINT,  -- calculate from aug 4th
	gndr_cd                       smallint,    -- from C20 
	wds_start_date                date,        -- from WDSD
	wds_end_date                  date,
	gp_start_date                 date,        -- from WLGP
	gp_end_date                   date,
	c20_start_date                date,        -- from C20 
	c20_end_date                  date,     
	-- Mortality 
	dod    						  date,
	ICD_main_Dth                 varchar(5),
	ICD_UNDR_dth                 varchar(5),
-- latest ethnicity up to 2021-12-31
	ethn_cat                      varchar(8),
	ethn_date                     date,
	ethn_src                      varchar(4),

-- area and household info at 2020-12-07
-- not sure if we need tis for the meta analysis vaccine uptake work
	
	lsoa2011_cd                   varchar(10),
	wimd2019_quintile             smallint, --rename to 2019 ??
	lad2011_name                    varchar(48), -- name of HB   
	health_board                  varchar(48),-- varchar( 3) name or code? 
	urban_rural_class             varchar(56),
	ralf_e                        bigint,
	ralf_sts_cd                   varchar(2),
	--hh_all_n                      smallint,
	--hh_child_n                    smallint,
	--hh_adult_n                    smallint,
-- shielded patient
	shielded_flg                  smallint, -- char(1) ??is this needed ?? use date IS blank?? 
	shielded_start_date           date --, --
	-- PCR tests
	--pcr_pos_test_n                SMALLINT,
--	pcr_neg_test_n				  SMALLINT,
--	pcr_all_tests_n               SMALLINT   -- needed ?? check
	--pcr_date   					  date   -- ??not sure what date was meant here..?? 

)
distribute BY hash (alf_e) ;	
	



COMMIT;

-- drop table sailw1151v.dacvap2_CYP
-- truncate table sailw1151v.dacvap2_CYP IMMEDIATE;

--  now get all wob, gndr cd etc from C20 for consistency not from the original dataset where they were found
--  not really necessary but  might have to revert to original 
--  data if the WDSD or NCCH only children included at a later date ..??


INSERT INTO sailw1151v.dacvap2_CYP (alf_e, wob, age_dec_2020, age_aug_2021, gndr_cd) 
--SELECT count(*) FROM (
SELECT rg.alf_e,
		jl.wob,
		cast((DAYS(sailw1151v.dacvap2_start_date) - days(jl.wob))/365.25 AS integer)  AS age_dec_2020, 
		cast((DAYS(sailw1151v.dacvap2_17_start_date) - days(jl.wob))/365.25 AS integer)  AS age_aug_2021, 
		jl.gndr_cd
FROM sailw1151v.dacvap2_CYP_spine  rg 
JOIN SAILWMC_V.C19_COHORT20  jl 
      ON jl.alf_e = rg.alf_e
    WHERE rg.c20_flag = 'Y'  -- bit belt and braces!!
   -- AND year(jl.wob) BETWEEN 2004 and 2017  -- more accurate below ?
   AND (cast((DAYS(sailw1151v.dacvap2_17_start_date) - days(jl.wob))/365.25 AS integer)) BETWEEN 4 AND 17-- chcek this as need to capture children entering the vacines age..
   ORDER BY rg.alf_e
--) -- end count

-- now merge in the ethnicity data based on Stus code
MERGE INTO sailw1151v.dacvap2_CYP tgt  
USING (
		  SELECT alf_e, ethn_cat, ethn_date, ethn_src
		     FROM (
				SELECT
					ethn.alf_e,
					lkp_ons.ec_ons_desc       AS ethn_cat,
					ethn.ethn_date            AS ethn_date,
					ethn.ethn_data_source     AS ethn_src,
					row_number () OVER (PARTITION BY ethn.alf_e ORDER BY ethn.ethn_date DESC) AS rank_latest
				FROM   -- was c20 cohort in original code
					sailw1151v.dacvap2_CYP   AS cohort
				INNER JOIN
					sailw1151v.rrda_ethn_prep_date AS ethn  -- seems to be any ethnicity data from any sources flagged 
						ON cohort.alf_e = ethn.alf_e        -- most recent is 1 SB flagged them 
				LEFT JOIN
					sailw1151v.rrda_ethn_lkp_ons AS lkp_ons
					ON ethn.ethn_ec_ons_code = lkp_ons.ec_ons_code
				WHERE
					ethn.ethn_date <= '2021-12-31' -- not sure why we need this date?
			      )
		    WHERE rank_latest = 1
   ) src
   ON src.alf_e = tgt.alf_e
  WHEN MATCHED THEN UPDATE 
   SET 	tgt.ethn_cat =src.ethn_cat,
   		tgt.ethn_date=src.ethn_date,
   		tgt.ethn_src=src.ethn_src    ;
    
COMMIT;
-- quick checks 

SELECT count(*), count( distinct alf_e) 
FROM sailw1151v.dacvap2_CYP 
WHERE ethn_date IS   NULL   

-- ----------------------------- merge in deaths --------------------
-- which table is best ??
/*
MERGE INTO sailw1151v.dacvap2_CYP tgt  
USING (
		SELECT alf_e,
				date(death_dt) AS death_dt,
				DEATHCAUSE_DIAG_UNDERLYING_CD,
				DEATHCAUSE_DIAG_1_CD		
        FROM SAILWMC_V.C19_COHORT_ADDE_DEATHS
         WHERE alf_e IN ( SELECT distinct alf_e 
                 FROM sailw1151v.dacvap2_CYP  )
       ) src
       on src.alf_e = tgt.alf_e
   WHEN MATCHED THEN UPDATE 
     SET tgt.dod = src.death_dt,
     tgt.ICD_MAIN_DTH =src.DEATHCAUSE_DIAG_1_CD,
     tgt.ICD_UNDR_DTH =src.DEATHCAUSE_DIAG_UNDERLYING_CD
     
*/
/*  try mortality table 
 * */
MERGE INTO sailw1151v.dacvap2_CYP tgt   
USING (
		SELECT alf_e,
			dod,
				COD_UNDERLYING,
				COD1
        FROM SAILWMC_V.C19_COHORT20_MORTALITY
         WHERE alf_e IN ( SELECT distinct alf_e 
                 FROM sailw1151v.dacvap2_CYP  )
       ) src
       on src.alf_e = tgt.alf_e
   WHEN MATCHED THEN UPDATE 
     SET tgt.dod = src.dod,
     tgt.ICD_MAIN_DTH =src.cod1,
     tgt.ICD_UNDR_DTH =src.COD_UNDERLYING
    
     
--   ---------------------------  now merge in the shielded data   -----------------------------

MERGE INTO sailw1151v.dacvap2_CYP tgt  
USING (
		SELECT
			shield.alf_e,
			min(shield.to_nwssp) AS shielded_date
		FROM sailw1151v.dacvap2_CYP   AS cohort
		INNER JOIN sail0911v.cvsp_df_shielded_patients AS shield
			ON cohort.alf_e = shield.alf_e
		WHERE  shield.alf_sts_cd IN (1, 4, 39)
		GROUP BY  	shield.alf_e
      ) src
          ON src.alf_e = tgt.alf_e
  WHEN MATCHED THEN UPDATE
  SET tgt.shielded_flg =1,  -- not sure we need this but going with the flow for now as some with no start date
      tgt.shielded_start_date = src.shielded_date

--                           merge in RALF data 
-- ****************  Now use Stu's code as basis of adding in the RALf information only 


MERGE INTO sailw1151v.dacvap2_CYP tgt    
USING (     
 -- select count(*), count(distinct alf_e) from (  
   SELECT in_tab.*,
		lkp_wimd.overall_quintile                               AS wimd2019_quintile,
		lkp_health_board.ua_desc                                AS lad2011_name,
		lkp_health_board.lhb19nm                                AS health_board,
		lkp_urban_rural.ruc11cd || ' ' || lkp_urban_rural.ruc11 AS urban_rural
		FROM (
				SELECT
					cohort.alf_e,
					sailw1151v.dacvap2_17_start_date AS res_date,
					wds_add.ralf_e,
					wds_add.ralf_sts_cd,
					wds_add.from_dt,
					wds_add.to_dt,
					wds_add.lsoa2011_cd,
					ROW_NUMBER() OVER (PARTITION BY cohort.alf_e, sailw1151v.dacvap2_17_start_date ORDER BY wds_add.from_dt, wds_add.to_dt DESC) AS ralf_seq
				FROM 		sailw1151v.dacvap2_CYP  cohort
				INNER JOIN 			sail0911v.wdsd_ar_pers AS wds_prs
					ON wds_prs.alf_e = cohort.alf_e
				INNER JOIN 			sail0911v.wdsd_ar_pers_add AS wds_add
					ON  wds_add.pers_id_e = wds_prs.pers_id_e
					AND wds_add.from_dt <= sailw1151v.dacvap2_17_start_date  -- splitting by vaccine start date 
					AND wds_add.to_dt >= sailw1151v.dacvap2_17_start_date
					--ORDER BY cohort.alf_e
	        )  in_tab
	
		LEFT JOIN sailrefrv.wimd2019_index_and_domain_ranks_by_small_area AS lkp_wimd
			ON in_tab.lsoa2011_cd = lkp_wimd.lsoa2011_cd
		LEFT JOIN sailw0911v.st_lsoa_hb_lookup_200424 AS lkp_health_board
			ON in_tab.lsoa2011_cd = lkp_health_board.lsoa2011_cd
		LEFT JOIN sailrefrv.rural_urban_class_2011_of_llsoareas_in_eng_and_wal AS lkp_urban_rural
			ON in_tab.lsoa2011_cd = lkp_urban_rural.lsoa11cd
		WHERE ralf_seq = 1
		ORDER BY in_tab.alf_e
    )   src       -- also end count!! 
  ON src.alf_e = tgt.alf_e
WHEN MATCHED THEN UPDATE 
SET  tgt.wds_start_date  =  src.from_dt,
	 tgt.wds_end_date  =    src.to_dt,
      tgt.lsoa2011_cd   =   src.lsoa2011_cd,
	tgt.wimd2019_quintile  =  src.wimd2019_quintile, -- check version ??         
	tgt.lad2011_name      = src.lad2011_name ,   -- forgot to add in..           
	tgt.health_board      =src.health_board, 
	tgt.urban_rural_class  =src.urban_rural,            
	tgt.ralf_e         =src.ralf_e,                
	tgt.ralf_sts_cd  =src.ralf_sts_cd                

	
	
	-- quick checks 
SELECT *
	FROM sailw1151v.dacvap2_CYP
	ORDER BY alf_e

-- ********************  now merge in c20 cohort_start_date and cohortend date ************************ 
--               not sure how these are used bt they ere included in another dacvap analysis

MERGE INTO sailw1151v.dacvap2_CYP tgt    
USING (     
 -- select count(*), count(distinct alf_e) from (  
   SELECT DISTINCT c20.alf_e,
		   --wds_start_date,
		   --wds_end_date,
		   c20.gp_start_date,
		   c20.GP_end_date,
		   c20.cohort_start_date,
		   c20.cohort_end_date
   FROM SAILWMC_V.C19_COHORT20   c20
   JOIN sailw1151v.dacvap2_CYP  cyp 
      ON cyp.alf_e = c20.alf_e
      ) src 
   ON src.alf_e = tgt.alf_e   
 WHEN MATCHED THEN UPDATE 
   SET  tgt.gp_start_date=src.gp_start_date,
   		tgt.gp_end_date= src.gp_end_date,
   		tgt.c20_start_date=src.cohort_start_date,
   		tgt.c20_end_date = src.cohort_end_date
          

COMMIT;   		