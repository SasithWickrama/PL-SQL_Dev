CREATE OR REPLACE PACKAGE
---------------------------------------------------------------
-- Copyright Clarity International Limited 2007
--
-- Product: Service Manager
-- Module: Service Manager command parameters value calculation
-- Version 1
--
-- $Revision: 1$
-- $Workfile: CPRG.p_sop_param_slt.psc.sql$
-- $Folder: Specifications$
-- $Project: C10$
-- $Label:$
-- The function parameter must be:
-- pi_seit_id IN service_implementation_tasks.seit_id%TYPE, -- task ID
-- pi_sopc_id IN sop_commands.sopc_id%TYPE, -- command id
-- pi_param1 IN VARCHAR2, -- Not used
-- pi_param2 IN VARCHAR2) -- Not used
-- RETURN VARCHAR2;
--
-----------------------------------------------------------------
-- $Id: p_sop_param_slt.psc.sql,v 1.0, 2007-10-25 01:05:45Z, Rana Balwan$
                                         CPRG.p_sop_param_slt
 AS
-----
 FUNCTION get_snb (
 pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;
---------------------------------------------------------------------------------

   FUNCTION get_dslam_vlan_type (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;
---------------------------------------------------------------------------------

   FUNCTION get_domain (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;


----------- Fayaz 10/08/2011 ----------------------------------------------------
   FUNCTION get_dslam_lprofid (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;


----------- Fayaz 10/08/2011 ----------------------------------------------------
   FUNCTION get_dslam_vlan_id (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;
---------------------------------------------------------------------------------

----------- Fayaz 10/08/2011 ----------------------------------------------------
   FUNCTION get_upload_policy (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;
---------------------------------------------------------------------------------


----------- Fayaz 10/08/2011 ----------------------------------------------------
   FUNCTION get_download_policy (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;
---------------------------------------------------------------------------------

---- Jayan Liyanage 2011 08 27 --------------------------------------------------
   FUNCTION get_dslam_rx (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;
--- Jayan Liyanage 2011 08 27 --------------------------------------------------

---- Jayan Liyanage 2011 08 27 --------------------------------------------------
 FUNCTION get_dslam_tx (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

---- Jayan Liyanage 2011 08 27 --------------------------------------------------

---- Janaka 2012 02 21 --------------------------------------------------
 FUNCTION get_dslam_svlan_id (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2,
      p_ret_msg   OUT    VARCHAR2
   )
      RETURN VARCHAR2;

---- Janaka 2012 02 21 --------------------------------------------------

---- Gihan 2012 12 17 --------------------------------------------------
   FUNCTION get_next_billdate (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_ldap_password (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

---- Gihan 2012 12 17 --------------------------------------------------

---- Gihan 2013 06 26 --------------------------------------------------

   FUNCTION get_dslam_pvcid (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

---- Gihan 2013 06 26 --------------------------------------------------

---------------- Dinesh 2013 08 13 ---------------
FUNCTION GET_PRV_ATTR_ADSL_CIRCUIT_ID (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

---------------- Dinesh 2013 08 13 ---------------

---- Janaka 2013 05 17 --------------------------------------------------
 FUNCTION GET_MIN (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

 FUNCTION GET_NEWMIN (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

 FUNCTION GET_MDN (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

 FUNCTION GET_NEWMDN (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;


 FUNCTION GET_OLDMIN (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;


 FUNCTION GET_OLDMDN (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

---- Janaka 2013 05 17 --------------------------------------------------

---- Janaka 2013 06 11 ****HLR****
 FUNCTION GET_ACTIV_VAL (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

       FUNCTION GET_BAROUT_IDD (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;
---- Janaka 2013 06 11 ****HLR****

---- Janaka 2013 06 26 ****IN****
 FUNCTION GET_IN_ACCOUNT (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;


 FUNCTION GET_IN_FUNCT (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

---- Janaka 2013 06 26 ****IN****

 ----- Dinesh 2013 07 31 ---- CDMA CRBT NUMBER-----
FUNCTION GET_CRBT_NUM (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

FUNCTION GET_ACTTYPE (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

 FUNCTION GET_ACTTYPE2 (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

 FUNCTION GET_ATTRMOD (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

 FUNCTION GET_CIRCUITNO (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;
 FUNCTION GET_CODE1 (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

 FUNCTION GET_CODE2 (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

 FUNCTION GET_CODE3 (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

 FUNCTION GET_CODE4 (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

 FUNCTION GET_DEACTTYPE (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

 FUNCTION GET_DEACTTYPE2 (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

 FUNCTION GET_DN (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

 FUNCTION GET_IPADDR (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

 FUNCTION GET_LATA (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;



 FUNCTION GET_NEWLATA (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

 FUNCTION GET_NEWSDN (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;


 FUNCTION GET_OLDLATA (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

 FUNCTION GET_OLDSDN (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

 FUNCTION GET_RMODEL (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

 FUNCTION GET_SDN (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;
 FUNCTION GET_SDN1 (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

 FUNCTION GET_SDN2 (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

 FUNCTION GET_SDN1_NEW (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

 FUNCTION GET_SDN2_NEW (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

 FUNCTION GET_SUBUNIT (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;
 FUNCTION GET_TIDNAME (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

 FUNCTION GET_UNIT (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

---- Janaka 2013 09 16 ****SOFTSWITCH****
FUNCTION GET_CODE1_OLD (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

FUNCTION GET_CODE2_OLD (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

      FUNCTION GET_CODE3_OLD (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

      FUNCTION GET_CODE4_OLD (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;
---- Janaka 2013 09 16 ****SOFTSWITCH****

-----Dinesh 16 09 2013 --------
 FUNCTION GET_DN_MOD (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

---- Janaka 2013 07 30 ****ZTE_ADSL****

FUNCTION GET_PID (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

 FUNCTION GET_DNAME (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

 FUNCTION GET_UID (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

---- Janaka 2013 07 30 ****ZTE_ADSL****

---- Janaka 2013 05 22

FUNCTION GET_PCRF_CUST_CONT  (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

---- Janaka 2013 05 22

-----Dinesh 28-09-2013 ----------
 FUNCTION GET_SUBID (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;
-----Dinesh 28-09-2013 -------

------Dinesh 14-10-2013----
FUNCTION GET_PRV_SUBID (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

------Samankula Owitipana 28-10-2013----
FUNCTION get_so_order_type (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

----- Dinesh 2014 01 12 ---- SIP EID -----
FUNCTION GET_SIP_EID (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

----- Dinesh 2014 01 14 ---- SIP D -----
FUNCTION GET_SIP_D (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

----- Dinesh 2014 01 14 ---- SIP LP -----
FUNCTION GET_SIP_LP (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

----- Dinesh 2014 01 21 ---- SIP EID OLD -----
FUNCTION GET_SIP_D_OLD (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

----- Dinesh 2014 01 21 ---- SIP EID OLD -----
FUNCTION GET_SIP_LP_OLD (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

----- Dinesh 2014 01 21 ---- SIP EID OLD -----
FUNCTION GET_SIP_EID_OLD (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

----- Dinesh 2014 01 23 ---- UID LTE OLD -----
FUNCTION GET_UID_LTE_OLD (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

----- Dinesh 2014 01 25 ---- GET SIP PASSWORD-----
FUNCTION GET_SIP_PASSWORD (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

---- Janaka 2014 04 10 --- GET_PWD_BBINTE ----
 FUNCTION GET_PWD_BBINTE (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

----- Dinesh 2014 05 23 ---- LTE LDAP DESCRIPTION-----
FUNCTION GET_LTE_DESC (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

------Samankula Owitipana 30-12-2013---- IMSI Number for HUAWEI HLR ----
FUNCTION GET_CDMA_IMSI (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

------Samankula Owitipana 30-12-2013---- MDN Number for HUAWEI HLR ----
FUNCTION GET_CDMA_MDN (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

------Samankula Owitipana 28-01-2014---- OLD MDN Number for HUAWEI HLR ----
FUNCTION GET_CDMA_OLD_MDN (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

---- Samankula Owitipana 2014 07 28
 FUNCTION GET_ENT_CUS_NAME_WIFI (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

---- Samankula Owitipana 2014 08 07
 FUNCTION GET_IPTV_SO_WG (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

---- Dinesh Perera 26-08-2014 -----
 FUNCTION GET_CUST_ADDRESS (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

---- Samankula Owitipana 2014 08 14
FUNCTION GET_SO_TYPE_ZTE (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

---- Samankula Owitipana 2014 06 18
 FUNCTION GET_ZTE_PID (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

---- Samankula Owitipana 2014 06 18
 FUNCTION GET_ADSL_IPTV_PVC (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

---- Samankula Owitipana 2014 05 02
 FUNCTION GET_EQUIP_IP (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

------Dinesh Perera 28-08-2014----
FUNCTION GET_SEVEN_DIGIT_UID (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

------Dinesh Perera 28-08-2014----
FUNCTION GET_SEVEN_DIGIT_PRV_UID (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

---- Samankula Owitipana 2014 06 27
 FUNCTION GET_BND_VLAN (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

---- Samankula Owitipana 2014 06 25
 FUNCTION GET_USR_CHECK (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

---- Samankula Owitipana 2014 07 28
 FUNCTION GET_ENT_WIFI_CUS_NAME (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

---- Samankula Owitipana 2014 10 21
FUNCTION GET_HUAWEI5_SHELF (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;
---- Samankula Owitipana 2014 10 21

---- Samankula Owitipana 2014 10 21
FUNCTION GET_HUAWEI5_SLOT (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;
---- Samankula Owitipana 2014 10 21

---- Samankula Owitipana 2014 10 21
FUNCTION GET_HUAWEI5_PORT (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;
---- Samankula Owitipana 2014 10 21

------Dinesh Perera 23-12-2014----
 FUNCTION GET_SIP_URL (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;
------Dinesh Perera 23-12-2014----

---- Samankula Owitipana 2014 11 24

FUNCTION GET_FTTH_VIRTUAL_PORT (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

---- Samankula Owitipana 2014 11 24

---- Samankula Owitipana 2014 12 12

FUNCTION GET_FTTH_ZTE_PID (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

---- Samankula Owitipana 2014 12 12

---- Samankula Owitipana 2014 11 24

FUNCTION  GET_FTTH_SERVICE_TYPE  (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

---- Samankula Owitipana 2014 11 24

---- Samankula Owitipana 2014 11 24

FUNCTION GET_FTTH_SHELF (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

---- Samankula Owitipana 2014 11 24

---- Samankula Owitipana 2014 11 24

FUNCTION GET_FTTH_PORT (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

---- Samankula Owitipana 2014 11 24

 -- Samitha Sagara 30032015 IPTV PRV PKG
   FUNCTION get_iptv_prvpkg (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
   RETURN VARCHAR2;
  -- Samitha Sagara finish  IPTV PRV PKG

---- -- LTE Voice Check Dhanushka 04042015

   FUNCTION GET_LTE_VOICEID (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
   RETURN VARCHAR2;

---- -- LTE Voice Check Dhanushka 04042015 Finish

  -- Samankula Owitipana 2015 01 19 RTOM with R
FUNCTION get_so_rtom_area (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
   RETURN VARCHAR2;
 -- Samankula Owitipana 2015 01 19 RTOM with R

 -- Samitha Sagara 30032015 IPTV Customer City
FUNCTION GET_CUST_CITYNAME (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
   RETURN VARCHAR2;
 -- Samitha Sagara 30032015 Finish IPTV Customer City

---- Samankula Owitipana 2014 11 24
FUNCTION GET_FTTH_SLOT (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;
---- Samankula Owitipana 2014 11 24

---- Dhanushka Fernando 04-10-2015

FUNCTION GET_PSTN_VAS (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

---- Dhanushka Fernando 04-10-2015

---- Dhanushka Fernando 29-09-2015

FUNCTION GET_PSTN_FEATURES_MODIFY (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

---- Dhanushka Fernando 29-09-2015

---- Dhanushka Fernando 29-09-2015
FUNCTION GET_PSTN_FEATURES (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

---- Dhanushka Fernando 29-09-2015


---- Samitha Sagara 2015 09 07
FUNCTION GET_TP_ADSL (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

---- Samitha Sagara 2015 09 07

---- Samitha Sagara 2015 09 07
FUNCTION GET_IMS_PID (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

---- Samitha Sagara 2015 09 07

--- Samitha Sagara 2015 09 11
FUNCTION GET_IMSEQ_IP (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;
--- Samitha Sagara 2015 09 11

---Dhanushka Fernando 04112015

 FUNCTION GET_PSTN_AREACODE  (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;

---Dhanushka Fernando 04112015

---Dhanushka Fernando 06112015
 FUNCTION GET_PSTN_PHNCON  (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;
---Dhanushka Fernando 06112015

---Dhanushka Fernando 06112015
 FUNCTION GET_PSTN_NETINFO  (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;
---Dhanushka Fernando 06112015

---- Dinesh Perera 16-09-2015 -----
 FUNCTION GET_EQUIP_IP_HUAWEI (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;
---- Dinesh Perera 16-09-2015 -----

---- Jayan Liyanage 18-02-2016 ----
 FUNCTION GET_IPTV_CCT_ID (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;
---- Jayan Liyanage 18-02-2016 ----

---- Dhanushka Fernando 19-03-2016 ----
 FUNCTION GET_OLD_PSTN (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;
---- Dhanushka Fernando 19-03-2016 ----


----- Dinesh 2016 03 14 ---- UID FTTH OLD -----
FUNCTION GET_UID_FTTH_OLD (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;
----- Dinesh 2016 03 14 ---- UID FTTH OLD -----

---- Dinesh Perera 25-04-2016 ----
FUNCTION GET_FTTH_PROFILE (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2;
---- Dinesh Perera 25-04-2016 ----

END p_sop_param_slt;
/
