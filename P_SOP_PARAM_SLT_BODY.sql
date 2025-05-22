CREATE OR REPLACE PACKAGE BODY
--*****************************************************************************************
--Project : SLT
--File Name : CPRG.p_sop_param_slt.pbc.sql
-- SLT specific functions
--Version No : 10.1.8
--PURPOSE : This package get the value for sop parameters.
-- $Id: p_sop_param_slt.pbc.sql,v 1.23, 2009-04-14 04:02:12Z, Rana Balwan$

                                                                                                     CPRG.p_sop_param_slt AS

--Last Modification:
--==================
--02-AUG-2011   SLT  Initialy created

--==============================================================================================
   FUNCTION get_snb (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS
      CURSOR numb_cur
      IS
         SELECT   numb_nucc_code || numb_number
             FROM service_orders so, service_implementation_tasks, numbers
            WHERE seit_sero_id = sero_id
              AND sero_serv_id = numb_serv_id
              AND numb_nums_id IN (3, 4, 6)
              -- 3 = reserved, 4 = allocated 6 = Reserved for Qaurtine
              AND seit_id = pi_seit_id
         ORDER BY DECODE (numb_nums_id, 6, 3, numb_nums_id) ASC;

      -- Reserved takes precedence so that the newly reserved number is returned
      -- in all conditions.
      -- Allocated is also considered if no new number has been reserved, say for a modify-feature
      -- order.
      l_snb   numbers.numb_number%TYPE;
   BEGIN
      OPEN numb_cur;

      FETCH numb_cur
       INTO l_snb;

      CLOSE numb_cur;

      RETURN (l_snb);
   END get_snb;


----------------------------------------------------------------------------------------------
   FUNCTION get_dslam_vlan_type (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS
/*   CURSOR c_dslam_model_type IS
      SELECT SEOA_DEFAULTVALUE
      FROM   service_order_attributes, service_implementation_tasks
      WHERE  seit_id = pi_seit_id
        AND  seoa_sero_id = seit_sero_id
        AND SEOA_NAME = 'ADSL_EQIP_MODEL';  'SA_DSLAM_MODEL_TYPE'; */

      CURSOR c_dslam_model_type
      IS
         SELECT REPLACE (MAX (equp_equm_model), ' ', '')
           FROM service_implementation_tasks,
                service_orders,
                circuits,
                port_links,
                port_link_ports,
                ports,
                equipment
          WHERE seit_id = pi_seit_id
            AND sero_id = seit_sero_id
            AND cirt_name = sero_cirt_name
            AND porl_cirt_name = cirt_name
            AND polp_porl_id = porl_id
            AND polp_commonport = 'T'
            AND port_id = polp_port_id
            AND equp_id = port_equp_id;

      l_dslam_model_type   equipment.equp_equm_model%TYPE;
-- service_order_attributes.SEOA_DEFAULTVALUE%TYPE;
   BEGIN
      OPEN c_dslam_model_type;

      FETCH c_dslam_model_type
       INTO l_dslam_model_type;

      CLOSE c_dslam_model_type;

      IF l_dslam_model_type LIKE '%5605%'
      THEN
         RETURN ('COMMON');
      ELSIF l_dslam_model_type LIKE '%5600%'
      THEN
         RETURN ('SMART');
      ELSIF l_dslam_model_type LIKE '%IPMB%'
      THEN
         RETURN ('SMART');
      ELSIF l_dslam_model_type LIKE '%UA5000%'
      THEN
         RETURN ('COMMON');
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END get_dslam_vlan_type;


------------------------------------------------------------------------------------------------

   FUNCTION get_domain (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS
      CURSOR c_domain
      IS
         SELECT seoa_defaultvalue
           FROM service_order_attributes,
                service_order_features,
                service_implementation_tasks
          WHERE seit_id = pi_seit_id
            AND seit_sero_id = seoa_sero_id
            AND seit_sero_id = sofe_sero_id
            AND seoa_sofe_id = sofe_id
            AND sofe_feature_name = pi_param1
            AND seoa_name LIKE '%DOMAIN%';

      CURSOR seoa_cur
      IS
         SELECT seoa_defaultvalue
           FROM service_order_attributes, service_implementation_tasks
          WHERE seit_id = pi_seit_id
            AND seoa_sero_id = seit_sero_id
            AND seoa_sero_revision = seit_sero_revision
            AND seoa_name = 'DOMAIN_NAME';

      CURSOR c_sopc
      IS
         SELECT sopc_command
           FROM sop_commands
          WHERE sopc_id = pi_sopc_id;

      l_command   sop_commands.sopc_command%TYPE;
      l_domain    VARCHAR2 (200)                   := NULL;
   BEGIN
      OPEN c_domain;

      FETCH c_domain
       INTO l_domain;

      CLOSE c_domain;

      IF l_domain IS NULL
      THEN
         OPEN seoa_cur;

         FETCH seoa_cur
          INTO l_domain;

         CLOSE seoa_cur;
      END IF;

      l_domain := NVL (l_domain, 'sltnet.lk');

      IF l_domain = 'slt.lk'
      THEN
         OPEN c_sopc;

         FETCH c_sopc
          INTO l_command;

         CLOSE c_sopc;

         IF l_command LIKE '%AUTH%'
         THEN
            l_domain := 'sltnet.lk';
         ELSIF l_command IN ('LDAP_ADD_WEBACC', 'LDAP_DEL_WEBACC')
         THEN
            l_domain := 'sltnet.lk';
         END IF;
      END IF;

      RETURN (l_domain);
   END get_domain;


------------------------------------------------------------------------------------------------

--==================== Fayaz 10/08/2011 ========================================================

   FUNCTION get_dslam_lprofid (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR c_int_feature
      IS
         SELECT sofe_defaultvalue,
                sofe_prev_value
           FROM service_order_features, service_implementation_tasks
          WHERE seit_id = pi_seit_id
            AND sofe_sero_id = seit_sero_id
            AND sofe_feature_name = 'INTERNET';

      CURSOR c_iptv_feature
      IS
         SELECT sofe_defaultvalue,
                sofe_prev_value
           FROM service_order_features, service_implementation_tasks
          WHERE seit_id = pi_seit_id
            AND sofe_sero_id = seit_sero_id
            AND sofe_feature_name = 'IPTV';


      CURSOR c_package_name
      IS
         SELECT seoa_defaultvalue
           FROM service_order_attributes, service_implementation_tasks
          WHERE seit_id = pi_seit_id
            AND seoa_sero_id = seit_sero_id
            AND seoa_name = 'SA_PACKAGE_NAME';

      CURSOR cur_ordtype
      IS
         SELECT sero_ordt_type
           FROM service_orders, service_implementation_tasks
          WHERE sero_id = seit_sero_id
            AND sero_revision = seit_sero_revision
            AND seit_id = pi_seit_id;

      l_order_type          service_orders.sero_ordt_type%TYPE;
      l_package_name        service_order_attributes.seoa_defaultvalue%TYPE;

        --l_int_feature service_order_features.SOFE_DEFAULTVALUE%TYPE;
        --l_iptv_feature service_order_features.SOFE_DEFAULTVALUE%TYPE;



      l_curr_int_feature    service_order_features.sofe_defaultvalue%TYPE;
      l_prev_int_feature    service_order_features.sofe_prev_value%TYPE;
      l_curr_iptv_feature   service_order_features.sofe_defaultvalue%TYPE;
      l_prev_iptv_feature   service_order_features.sofe_prev_value%TYPE;

   BEGIN

  --OPEN c_iptv_feature;
  --FETCH c_iptv_feature INTO l_iptv_feature;
  --CLOSE c_iptv_feature;

      --OPEN c_int_feature;
  --FETCH c_int_feature INTO l_int_feature;
  --CLOSE c_int_feature;


      OPEN c_iptv_feature;

      FETCH c_iptv_feature
       INTO l_curr_iptv_feature, l_prev_iptv_feature;

      CLOSE c_iptv_feature;

      OPEN c_int_feature;

      FETCH c_int_feature
       INTO l_curr_int_feature, l_prev_int_feature;

      CLOSE c_int_feature;

      OPEN cur_ordtype;

      FETCH cur_ordtype
       INTO l_order_type;

      CLOSE cur_ordtype;

      OPEN c_package_name;

      FETCH c_package_name
       INTO l_package_name;

      CLOSE c_package_name;

      IF l_order_type LIKE 'DELETE%'
      THEN
         RETURN ('Default');

      ELSIF l_order_type LIKE 'SUSPEND'
      THEN
         IF (    (    NVL (l_curr_int_feature, 'N') = 'N'
                  AND NVL (l_prev_int_feature, 'N') = 'Y'
                 )
             AND (    NVL (l_curr_iptv_feature, 'N') = 'N'
                  AND NVL (l_prev_iptv_feature, 'N') = 'Y'
                 )
            )
         THEN
            IF l_package_name = 'HOME'
            THEN
               RETURN ('IPTV_HomeExpress');
            ELSIF l_package_name = 'HOME PLUS'
            THEN
               RETURN ('IPTV_HomePlus');
            --------------- Jayan Liyanage  ADD 2009 02 13 -----
            ELSIF l_package_name IN ('OFFICE', 'OFFICE 1IP')
            THEN
               RETURN ('IPTV_OfficeExpress');
            ELSIF l_package_name LIKE 'ENTREE%'
            THEN
               RETURN ('IPTV_Entree');
            ELSIF l_package_name = 'XCITE'
            THEN
               RETURN ('IPTV_Xcite');
            ELSIF l_package_name IN ('XCEL', 'XCEL 1IP')
            THEN
               RETURN ('IPTV_Xcel');
            ELSIF l_package_name = 'OFFICE PLUS'
            THEN
               RETURN ('IPTV_OfficePlus');
            ELSIF l_package_name = 'XCITE PLUS'
            THEN
               RETURN ('IPTV_XcitePlus');
            ELSIF l_package_name = 'XCEL PLUS'
            THEN
               RETURN ('IPTV_XcelPlus');
            ----------------- Jayan Liyanage Add 2009 02 13 ------

            --------------------------Dinesh edit 29/11/2011 8:00 AM  ----------------------------------

            ELSIF l_package_name IN ('WEB SURFER PLUS','WebSurferPlus')
            THEN
               RETURN ('IPTV_WebSurferPlus');
            ELSIF l_package_name IN ('WEB PRO PLUS','WebProPlus')
            THEN
               RETURN ('IPTV_WebProPlus');
            ELSIF l_package_name IN ('WEB MASTER PLUS','WebMasterPlus')
            THEN
               RETURN ('IPTV_WebMasterPlus');
            ELSIF l_package_name IN ('WEB MATE','WebMate')
            THEN
               RETURN ('IPTV_WebMate');
            ELSIF l_package_name IN ('WEB SURFER','WebSurfer')
            THEN
               RETURN ('IPTV_WebSurfer');
            ELSIF l_package_name IN ('WEB PRO','WebPro')
            THEN
               RETURN ('IPTV_WebPro');
            ELSIF l_package_name IN ('WEB MASTER','WebMaster')
            THEN
               RETURN ('IPTV_WebMaster');

           --------------------------edit 29/11/2011 8:00 AM  ----------------------------------




            END IF;
         ELSIF (    (    NVL (l_curr_int_feature, 'N') = 'N'
                     AND NVL (l_prev_int_feature, 'N') = 'Y'
                    )
                AND (    NVL (l_curr_iptv_feature, 'N') = 'N'
                     AND NVL (l_prev_iptv_feature, 'N') = 'N'
                    )
               )
         THEN
            IF l_package_name = 'HOME'
            THEN
               RETURN ('HomeExpress');
            ELSIF l_package_name = 'HOME PLUS'
            THEN
               RETURN ('HomePlus');
            ----------------- Jayan Liyanage Add 2009 02 13 ------
            ELSIF l_package_name IN ('OFFICE', 'OFFICE 1IP')
            THEN
               RETURN ('OfficeExpress');
            ELSIF l_package_name LIKE 'ENTREE%'
            THEN
               RETURN ('Entree');
            ELSIF l_package_name = 'XCITE'
            THEN
               RETURN ('Xcite');
            ELSIF l_package_name IN ('XCEL', 'XCEL 1IP')
            THEN
               RETURN ('Xcel');
            ELSIF l_package_name = 'OFFICE PLUS'
            THEN
               RETURN ('OfficePlus');
            ELSIF l_package_name = 'XCITE PLUS'
            THEN
               RETURN ('XcitePlus');
            ELSIF l_package_name = 'XCEL PLUS'
            THEN
               RETURN ('XcelPlus');
            ----------------- Jayan Liyanage Add 2009 02 13 ------

            ---=======================================================Fayaz 8/8/2011 ==========================
            ELSIF l_package_name IN ('WEB SURFER PLUS','WebSurferPlus')
            THEN
               RETURN ('WebSurferPlus');
            ELSIF l_package_name IN ('WEB PRO PLUS','WebProPlus')
            THEN
               RETURN ('WebProPlus');
            ELSIF l_package_name IN ('WEB MASTER PLUS','WebMasterPlus')
            THEN
               RETURN ('WebMasterPlus');
            ELSIF l_package_name IN ('WEB MATE','WebMate')
            THEN
               RETURN ('WebMate');
            ELSIF l_package_name IN ('WEB SURFER','WebSurfer')
            THEN
               RETURN ('WebSurfer');
            ELSIF l_package_name IN ('WEB PRO','WebPro')
            THEN
               RETURN ('WebPro');
            ELSIF l_package_name IN ('WEB MASTER','WebMaster')
            THEN
               RETURN ('WebMaster');
            ---======================================================= Fayaz 8/8/2011==========================

            END IF;
         END IF;
      ELSIF l_order_type LIKE 'RESUME'
      THEN
         IF (    (    NVL (l_curr_int_feature, 'N') = 'Y'
                  AND NVL (l_prev_int_feature, 'N') = 'N'
                 )
             AND (    NVL (l_curr_iptv_feature, 'N') = 'Y'
                  AND NVL (l_prev_iptv_feature, 'N') = 'N'
                 )
            )
         THEN
            IF l_package_name = 'HOME'
            THEN
               RETURN ('IPTV_HomeExpress');
            ELSIF l_package_name = 'HOME PLUS'
            THEN
               RETURN ('IPTV_HomePlus');
            ----------------- Jayan Liyanage Add 2009 02 13 ------
            ELSIF l_package_name IN ('OFFICE', 'OFFICE 1IP')
            THEN
               RETURN ('IPTV_OfficeExpress');
            ELSIF l_package_name LIKE 'ENTREE%'
            THEN
               RETURN ('IPTV_Entree');
            ELSIF l_package_name = 'XCITE'
            THEN
               RETURN ('IPTV_Xcite');
            ELSIF l_package_name IN ('XCEL', 'XCEL 1IP')
            THEN
               RETURN ('IPTV_Xcel');
            ELSIF l_package_name = 'OFFICE PLUS'
            THEN
               RETURN ('IPTV_OfficePlus');
            ELSIF l_package_name = 'XCITE PLUS'
            THEN
               RETURN ('IPTV_XcitePlus');
            ELSIF l_package_name = 'XCEL PLUS'
            THEN
               RETURN ('IPTV_XcelPlus');
            ----------------- Jayan Liyanage Add 2009 02 13 ------

            --------------------------edit 29/28/2011 8:00 AM  ----------------------------------

            ELSIF l_package_name IN ('WEB SURFER PLUS','WebSurferPlus')
            THEN
               RETURN ('IPTV_WebSurferPlus');
            ELSIF l_package_name IN ('WEB PRO PLUS','WebProPlus')
            THEN
               RETURN ('IPTV_WebProPlus');
            ELSIF l_package_name IN ('WEB MASTER PLUS','WebMasterPlus')
            THEN
               RETURN ('IPTV_WebMasterPlus');
            ELSIF l_package_name IN ('WEB MATE','WebMate')
            THEN
               RETURN ('IPTV_WebMate');
            ELSIF l_package_name IN ('WEB SURFER','WebSurfer')
            THEN
               RETURN ('IPTV_WebSurfer');
            ELSIF l_package_name IN ('WEB PRO','WebPro')
            THEN
               RETURN ('IPTV_WebPro');
            ELSIF l_package_name IN ('WEB MASTER','WebMaster')
            THEN
               RETURN ('IPTV_WebMaster');

           --------------------------edit 29/28/2011 8:00 AM  ----------------------------------


            END IF;
         ELSIF (    (    NVL (l_curr_int_feature, 'N') = 'Y'
                     AND NVL (l_prev_int_feature, 'N') = 'N'
                    )
                AND (    NVL (l_curr_iptv_feature, 'N') = 'N'
                     AND NVL (l_prev_iptv_feature, 'N') = 'N'
                    )
               )
         THEN
            IF l_package_name = 'HOME'
            THEN       ----------------- Jayan Liyanage Add 2009 02 13 ------
               RETURN ('HomeExpress');
            ELSIF l_package_name = 'HOME PLUS'
            THEN
               RETURN ('HomePlus');
            ELSIF l_package_name IN ('OFFICE', 'OFFICE 1IP')
            THEN
               RETURN ('OfficeExpress');
            ELSIF l_package_name LIKE 'ENTREE%'
            THEN
               RETURN ('Entree');
            ELSIF l_package_name = 'XCITE'
            THEN
               RETURN ('Xcite');
            ELSIF l_package_name IN ('XCEL', 'XCEL 1IP')
            THEN
               RETURN ('Xcel');
            ELSIF l_package_name = 'OFFICE PLUS'
            THEN
               RETURN ('OfficePlus');
            ELSIF l_package_name = 'XCITE PLUS'
            THEN
               RETURN ('XcitePlus');
            ELSIF l_package_name = 'XCEL PLUS'
            THEN
               RETURN ('XcelPlus');
            ----------------- Jayan Liyanage Add 2009 02 13 ------

            ---======================================================= Fayaz 8/8/2011==========================
            ELSIF l_package_name IN ('WEB SURFER PLUS','WebSurferPlus')
            THEN
               RETURN ('WebSurferPlus');
            ELSIF l_package_name IN ('WEB PRO PLUS','WebProPlus')
            THEN
               RETURN ('WebProPlus');
            ELSIF l_package_name IN ('WEB MASTER PLUS','WebMasterPlus')
            THEN
               RETURN ('WebMasterPlus');
            ELSIF l_package_name IN ('WEB MATE','WebMate')
            THEN
               RETURN ('WebMate');
            ELSIF l_package_name IN ('WEB SURFER','WebSurfer')
            THEN
               RETURN ('WebSurfer');
            ELSIF l_package_name IN ('WEB PRO','WebPro')
            THEN
               RETURN ('WebPro');
            ELSIF l_package_name IN ('WEB MASTER','WebMaster')
            THEN
               RETURN ('WebMaster');
            ---======================================================= Fayaz 8/8/2011==========================

            END IF;
         END IF;

      ELSE

        /* IF l_package_name LIKE 'HOME%' THEN
             RETURN ('HomeExpress');
        ELSIF l_package_name LIKE 'OFFICE%' THEN
          RETURN ('OfficeExpress');
        ELSIF l_package_name LIKE 'ENTREE%' THEN
          RETURN ('Entree');
         END IF; */
         IF     NVL (l_curr_int_feature, 'N') = 'N'
            AND NVL (l_curr_iptv_feature, 'N') = 'Y'
         THEN                                                     -- IPTV only
            RETURN ('IPTV');
         ELSIF     NVL (l_curr_int_feature, 'N') = 'Y'
               AND NVL (l_curr_iptv_feature, 'N') = 'N'
         THEN                                                      -- HSI only
            IF l_package_name = 'HOME'
            THEN       ----------------- Jayan Liyanage Add 2009 02 13 ------
               RETURN ('HomeExpress');
            ELSIF l_package_name = 'HOME PLUS'
            THEN
               RETURN ('HomePlus');
            ELSIF l_package_name IN ('OFFICE', 'OFFICE 1IP')
            THEN
               RETURN ('OfficeExpress');
            ELSIF l_package_name LIKE 'ENTREE%'
            THEN
               RETURN ('Entree');
            ELSIF l_package_name = 'XCITE'
            THEN
               RETURN ('Xcite');
            ELSIF l_package_name IN ('XCEL', 'XCEL 1IP')
            THEN
               RETURN ('Xcel');
            ELSIF l_package_name = 'OFFICE PLUS'
            THEN
               RETURN ('OfficePlus');
            ELSIF l_package_name = 'XCITE PLUS'
            THEN
               RETURN ('XcitePlus');
            ELSIF l_package_name = 'XCEL PLUS'
            THEN
               RETURN ('XcelPlus');
            ----------------- Jayan Liyanage Add 2009 02 13 ------

            ------------------jayan Liyanage 2011 08 27 ------------------------------
             ELSIF l_package_name IN ('WEB SURFER PLUS','WebSurferPlus')
            THEN
               RETURN ('WebSurferPlus');
            ELSIF l_package_name IN ('WEB PRO PLUS','WebProPlus')
            THEN
               RETURN ('WebProPlus');
            ELSIF l_package_name IN ('WEB MASTER PLUS','WebMasterPlus')
            THEN
               RETURN ('WebMasterPlus');
            ELSIF l_package_name IN ('WEB MATE','WebMate')
            THEN
               RETURN ('WebMate');
            ELSIF l_package_name IN ('WEB SURFER','WebSurfer')
            THEN
               RETURN ('WebSurfer');
            ELSIF l_package_name IN ('WEB PRO','WebPro')
            THEN
               RETURN ('WebPro');
            ELSIF l_package_name IN ('WEB MASTER','WebMaster')
            THEN
               RETURN ('WebMaster');

            END IF;
            --------------------------jayan Liyanage 2011 08 27  ----------------------------------
         ELSE                                                  -- HSI and IPTV
            IF l_package_name = 'HOME'
            THEN       ----------------- Jayan Liyanage Add 2009 02 13 ------
               RETURN ('IPTV_HomeExpress');
            ELSIF l_package_name = 'HOME PLUS'
            THEN
               RETURN ('IPTV_HomePlus');
            ELSIF l_package_name IN ('OFFICE', 'OFFICE 1IP')
            THEN
               RETURN ('IPTV_OfficeExpress');
            ELSIF l_package_name LIKE 'ENTREE%'
            THEN
               RETURN ('IPTV_Entree');
            ELSIF l_package_name = 'XCITE'
            THEN
               RETURN ('IPTV_Xcite');
            ELSIF l_package_name IN ('XCEL', 'XCEL 1IP')
            THEN
               RETURN ('IPTV_Xcel');
            ELSIF l_package_name = 'OFFICE PLUS'
            THEN
               RETURN ('IPTV_OfficePlus');
            ELSIF l_package_name = 'XCITE PLUS'
            THEN
               RETURN ('IPTV_XcitePlus');
            ELSIF l_package_name = 'XCEL PLUS'
            THEN
               RETURN ('IPTV_XcelPlus');
            ----------------- Jayan Liyanage Add 2009 02 13 ------

            ----======================================================= Fayaz 8/8/2011==========================---

            --------------------------jayan Liyanage   edit 8/28/2011 9:24:08 PM  ----------------------------------

            ELSIF l_package_name IN ('WEB SURFER PLUS','WebSurferPlus')
            THEN
               RETURN ('IPTV_WebSurferPlus');
            ELSIF l_package_name IN ('WEB PRO PLUS','WebProPlus')
            THEN
               RETURN ('IPTV_WebProPlus');
            ELSIF l_package_name IN ('WEB MASTER PLUS','WebMasterPlus')
            THEN
               RETURN ('IPTV_WebMasterPlus');
            ELSIF l_package_name IN ('WEB MATE','WebMate')
            THEN
               RETURN ('IPTV_WebMate');
            ELSIF l_package_name IN ('WEB SURFER','WebSurfer')
            THEN
               RETURN ('IPTV_WebSurfer');
            ELSIF l_package_name IN ('WEB PRO','WebPro')
            THEN
               RETURN ('IPTV_WebPro');
            ELSIF l_package_name IN ('WEB MASTER','WebMaster')
            THEN
               RETURN ('IPTV_WebMaster');

           --------------------------jayan Liyanage  edit 28/28/2011 9:24:08 PM  ----------------------------------


            ---======================================================= Fayaz 8/8/2011==========================

            END IF;
         END IF;

      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END get_dslam_lprofid;

----------------------------------------------------------------------------------------------

--==================== Fayaz 10/08/2011 ========================================================

FUNCTION get_dslam_vlan_id (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR c_seitname
      IS
         SELECT seit_taskname
           FROM service_implementation_tasks
          WHERE seit_id = pi_seit_id;




      CURSOR c_command
      IS
         SELECT sopc_command
           FROM sop_commands
          WHERE sopc_id = pi_sopc_id;

      CURSOR c_service_order
      IS
         SELECT *
           FROM service_orders, service_implementation_tasks
          WHERE seit_id = pi_seit_id AND sero_id = seit_sero_id;

      CURSOR c_int_feature
      IS
         SELECT sofe_defaultvalue
           FROM service_order_features, service_implementation_tasks
          WHERE seit_id = pi_seit_id
            AND sofe_sero_id = seit_sero_id
            AND sofe_feature_name = 'INTERNET';

      CURSOR c_iptv_feature
      IS
         SELECT sofe_defaultvalue
           FROM service_order_features, service_implementation_tasks
          WHERE seit_id = pi_seit_id
            AND sofe_sero_id = seit_sero_id
            AND sofe_feature_name = 'IPTV';

      CURSOR c_package_name
      IS
         -- SELECT SEOA_DEFAULTVALUE
         SELECT seoa_defaultvalue, seoa_prev_value

         FROM   service_order_attributes, service_implementation_tasks
          WHERE seit_id = pi_seit_id
            AND seoa_sero_id = seit_sero_id
            AND seoa_name = 'SA_PACKAGE_NAME';

      CURSOR c_home_vlan_id
      IS
         SELECT podi_value
           FROM service_implementation_tasks,
                service_orders,
                circuits,
                port_links,
                port_link_ports,
                ports,
                port_detail_instance
          WHERE seit_id = pi_seit_id
            AND sero_id = seit_sero_id
            AND cirt_name = sero_cirt_name
            AND porl_cirt_name = cirt_name
            AND polp_porl_id = porl_id
            AND port_id = polp_port_id
            AND podi_port_id = port_id
            AND podi_name = 'PA_DSLAM_HOME_VLANID';

      CURSOR c_homeplus_vlan_id
      IS
         SELECT podi_value
           FROM service_implementation_tasks,
                service_orders,
                circuits,
                port_links,
                port_link_ports,
                ports,
                port_detail_instance
          WHERE seit_id = pi_seit_id
            AND sero_id = seit_sero_id
            AND cirt_name = sero_cirt_name
            AND porl_cirt_name = cirt_name
            AND polp_porl_id = porl_id
            AND port_id = polp_port_id
            AND podi_port_id = port_id
            AND podi_name = 'PA_DSLAM_HOMEPLUS_VLANID';

      CURSOR c_office_vlan_id
      IS
         SELECT podi_value
           FROM service_implementation_tasks,
                service_orders,
                circuits,
                port_links,
                port_link_ports,
                ports,
                port_detail_instance
          WHERE seit_id = pi_seit_id
            AND sero_id = seit_sero_id
            AND cirt_name = sero_cirt_name
            AND porl_cirt_name = cirt_name
            AND polp_porl_id = porl_id
            AND port_id = polp_port_id
            AND podi_port_id = port_id
            AND podi_name = 'PA_DSLAM_OFFICE_VLANID';

      CURSOR c_officeplus_vlan_id
      IS
         SELECT podi_value
           FROM service_implementation_tasks,
                service_orders,
                circuits,
                port_links,
                port_link_ports,
                ports,
                port_detail_instance
          WHERE seit_id = pi_seit_id
            AND sero_id = seit_sero_id
            AND cirt_name = sero_cirt_name
            AND porl_cirt_name = cirt_name
            AND polp_porl_id = porl_id
            AND port_id = polp_port_id
            AND podi_port_id = port_id
            AND podi_name = 'PA_DSLAM_OFFICEPLUS_VLANID';

      CURSOR c_entree_vlan_id
      IS
         SELECT podi_value
           FROM service_implementation_tasks,
                service_orders,
                circuits,
                port_links,
                port_link_ports,
                ports,
                port_detail_instance
          WHERE seit_id = pi_seit_id
            AND sero_id = seit_sero_id
            AND cirt_name = sero_cirt_name
            AND porl_cirt_name = cirt_name
            AND polp_porl_id = porl_id
            AND port_id = polp_port_id
            AND podi_port_id = port_id
            AND podi_name = 'PA_DSLAM_ENTREE_VLANID';


      CURSOR c_xcite_vlan_id
      IS
         SELECT podi_value
           FROM service_implementation_tasks,
                service_orders,
                circuits,
                port_links,
                port_link_ports,
                ports,
                port_detail_instance
          WHERE seit_id = pi_seit_id
            AND sero_id = seit_sero_id
            AND cirt_name = sero_cirt_name
            AND porl_cirt_name = cirt_name
            AND polp_porl_id = porl_id
            AND port_id = polp_port_id
            AND podi_port_id = port_id
            AND podi_name = 'PA_DSLAM_XCITE_VLANID';

      CURSOR c_xciteplus_vlan_id
      IS
         SELECT podi_value
           FROM service_implementation_tasks,
                service_orders,
                circuits,
                port_links,
                port_link_ports,
                ports,
                port_detail_instance
          WHERE seit_id = pi_seit_id
            AND sero_id = seit_sero_id
            AND cirt_name = sero_cirt_name
            AND porl_cirt_name = cirt_name
            AND polp_porl_id = porl_id
            AND port_id = polp_port_id
            AND podi_port_id = port_id
            AND podi_name = 'PA_DSLAM_XCITEPLUS_VLANID';

      CURSOR c_xcel_vlan_id
      IS
         SELECT podi_value
           FROM service_implementation_tasks,
                service_orders,
                circuits,
                port_links,
                port_link_ports,
                ports,
                port_detail_instance
          WHERE seit_id = pi_seit_id
            AND sero_id = seit_sero_id
            AND cirt_name = sero_cirt_name
            AND porl_cirt_name = cirt_name
            AND polp_porl_id = porl_id
            AND port_id = polp_port_id
            AND podi_port_id = port_id
            AND podi_name = 'PA_DSLAM_XCEL_VLANID';

      CURSOR c_xcelplus_vlan_id
      IS
         SELECT podi_value
           FROM service_implementation_tasks,
                service_orders,
                circuits,
                port_links,
                port_link_ports,
                ports,
                port_detail_instance
          WHERE seit_id = pi_seit_id
            AND sero_id = seit_sero_id
            AND cirt_name = sero_cirt_name
            AND porl_cirt_name = cirt_name
            AND polp_porl_id = porl_id
            AND port_id = polp_port_id
            AND podi_port_id = port_id
            AND podi_name = 'PA_DSLAM_XCELPLUS_VLANID';


      CURSOR c_iptv_vlan_id
      IS
         SELECT podi_value
           FROM service_implementation_tasks,
                service_orders,
                circuits,
                port_links,
                port_link_ports,
                ports,
                port_detail_instance
          WHERE seit_id = pi_seit_id
            AND sero_id = seit_sero_id
            AND cirt_name = sero_cirt_name
            AND porl_cirt_name = cirt_name
            AND polp_porl_id = porl_id
            AND port_id = polp_port_id
            AND podi_port_id = port_id
            AND podi_name = 'PA_DSLAM_IPTV_VLANID';

    ------================================= Fayaz 8/8/2011 ========================
      /*CURSOR c_websurferplus_vlan_id
      IS
         SELECT podi_value
           FROM service_implementation_tasks,
                service_orders,
                circuits,
                port_links,
                port_link_ports,
                ports,
                port_detail_instance
          WHERE seit_id = pi_seit_id
            AND sero_id = seit_sero_id
            AND cirt_name = sero_cirt_name
            AND porl_cirt_name = cirt_name
            AND polp_porl_id = porl_id
            AND port_id = polp_port_id
            AND podi_port_id = port_id
            AND podi_name = 'PA_DSLAM_WEBSURFERPLUS_VLANID';

      CURSOR c_webproplus_vlan_id
      IS
         SELECT podi_value
           FROM service_implementation_tasks,
                service_orders,
                circuits,
                port_links,
                port_link_ports,
                ports,
                port_detail_instance
          WHERE seit_id = pi_seit_id
            AND sero_id = seit_sero_id
            AND cirt_name = sero_cirt_name
            AND porl_cirt_name = cirt_name
            AND polp_porl_id = porl_id
            AND port_id = polp_port_id
            AND podi_port_id = port_id
            AND podi_name = 'PA_DSLAM_WEBPROPLUS_VLANID';

      CURSOR c_webmasterplus_vlan_id
      IS
         SELECT podi_value
           FROM service_implementation_tasks,
                service_orders,
                circuits,
                port_links,
                port_link_ports,
                ports,
                port_detail_instance
          WHERE seit_id = pi_seit_id
            AND sero_id = seit_sero_id
            AND cirt_name = sero_cirt_name
            AND porl_cirt_name = cirt_name
            AND polp_porl_id = porl_id
            AND port_id = polp_port_id
            AND podi_port_id = port_id
            AND podi_name = 'PA_DSLAM_WEBMASTERPLUS_VLANID';

      CURSOR c_webmate_vlan_id
      IS
         SELECT podi_value
           FROM service_implementation_tasks,
                service_orders,
                circuits,
                port_links,
                port_link_ports,
                ports,
                port_detail_instance
          WHERE seit_id = pi_seit_id
            AND sero_id = seit_sero_id
            AND cirt_name = sero_cirt_name
            AND porl_cirt_name = cirt_name
            AND polp_porl_id = porl_id
            AND port_id = polp_port_id
            AND podi_port_id = port_id
            AND podi_name = 'PA_DSLAM_WEBMATE_VLANID';

      CURSOR c_websurfer_vlan_id
      IS
         SELECT podi_value
           FROM service_implementation_tasks,
                service_orders,
                circuits,
                port_links,
                port_link_ports,
                ports,
                port_detail_instance
          WHERE seit_id = pi_seit_id
            AND sero_id = seit_sero_id
            AND cirt_name = sero_cirt_name
            AND porl_cirt_name = cirt_name
            AND polp_porl_id = porl_id
            AND port_id = polp_port_id
            AND podi_port_id = port_id
            AND podi_name = 'PA_DSLAM_WEBSURFER_VLANID';


      CURSOR c_webpro_vlan_id
      IS
         SELECT podi_value
           FROM service_implementation_tasks,
                service_orders,
                circuits,
                port_links,
                port_link_ports,
                ports,
                port_detail_instance
          WHERE seit_id = pi_seit_id
            AND sero_id = seit_sero_id
            AND cirt_name = sero_cirt_name
            AND porl_cirt_name = cirt_name
            AND polp_porl_id = porl_id
            AND port_id = polp_port_id
            AND podi_port_id = port_id
            AND podi_name = 'PA_DSLAM_WEBPRO_VLANID';

      CURSOR c_webmaster_vlan_id
      IS
         SELECT podi_value
           FROM service_implementation_tasks,
                service_orders,
                circuits,
                port_links,
                port_link_ports,
                ports,
                port_detail_instance
          WHERE seit_id = pi_seit_id
            AND sero_id = seit_sero_id
            AND cirt_name = sero_cirt_name
            AND porl_cirt_name = cirt_name
            AND polp_porl_id = porl_id
            AND port_id = polp_port_id
            AND podi_port_id = port_id
            AND podi_name = 'PA_DSLAM_WEBMASTER_VLANID';
*/
    ---================================= Fayaz 8/8/2011 ========================


      r_service_order        c_service_order%ROWTYPE;
      l_command              sop_commands.sopc_command%TYPE;
      l_package_name_old     service_order_attributes.seoa_prev_value%TYPE;
      l_iptv_vlan_id         port_detail_instance.podi_value%TYPE;
      l_int_feature          service_order_features.sofe_defaultvalue%TYPE;
      l_iptv_feature         service_order_features.sofe_defaultvalue%TYPE;

      l_package_name         service_order_attributes.seoa_defaultvalue%TYPE;
      l_home_vlan_id         port_detail_instance.podi_value%TYPE;
      l_homeplus_vlan_id     port_detail_instance.podi_value%TYPE;
      l_office_vlan_id       port_detail_instance.podi_value%TYPE;
      l_officeplus_vlan_id   port_detail_instance.podi_value%TYPE;
      l_entree_vlan_id       port_detail_instance.podi_value%TYPE;

      l_xcite_vlan_id        port_detail_instance.podi_value%TYPE;
      l_xcel_vlan_id         port_detail_instance.podi_value%TYPE;
      l_xciteplus_vlan_id    port_detail_instance.podi_value%TYPE;
      l_xcelplus_vlan_id     port_detail_instance.podi_value%TYPE;

      l_taskname             service_implementation_tasks.seit_taskname%TYPE;


    ---================================= Fayaz 8/8/2011 ========================
/*
      l_websurferplus_vlan_id         port_detail_instance.podi_value%TYPE;
      l_webproplus_vlan_id         port_detail_instance.podi_value%TYPE;
      l_webmasterplus_vlan_id         port_detail_instance.podi_value%TYPE;
      l_webmate_vlan_id         port_detail_instance.podi_value%TYPE;
      l_websurfer_vlan_id         port_detail_instance.podi_value%TYPE;
      l_webpro_vlan_id         port_detail_instance.podi_value%TYPE;
      l_webmaster_vlan_id         port_detail_instance.podi_value%TYPE;
*/
    -----================================= Fayaz 8/8/2011 ========================

   BEGIN

      OPEN c_command;

      FETCH c_command
       INTO l_command;

      CLOSE c_command;

      OPEN c_iptv_feature;

      FETCH c_iptv_feature
       INTO l_iptv_feature;

      CLOSE c_iptv_feature;

      OPEN c_int_feature;

      FETCH c_int_feature
       INTO l_int_feature;

      CLOSE c_int_feature;

      OPEN c_service_order;

      FETCH c_service_order
       INTO r_service_order;

      CLOSE c_service_order;

      OPEN c_iptv_vlan_id;

      FETCH c_iptv_vlan_id
       INTO l_iptv_vlan_id;

      CLOSE c_iptv_vlan_id;


      OPEN c_package_name;

      FETCH c_package_name
       INTO l_package_name, l_package_name_old;

      CLOSE c_package_name;

      OPEN c_home_vlan_id;

      FETCH c_home_vlan_id
       INTO l_home_vlan_id;

      CLOSE c_home_vlan_id;

      OPEN c_homeplus_vlan_id;

      FETCH c_homeplus_vlan_id
       INTO l_homeplus_vlan_id;

      CLOSE c_homeplus_vlan_id;

      OPEN c_office_vlan_id;

      FETCH c_office_vlan_id
       INTO l_office_vlan_id;

      CLOSE c_office_vlan_id;

      OPEN c_officeplus_vlan_id;

      FETCH c_officeplus_vlan_id
       INTO l_officeplus_vlan_id;

      CLOSE c_officeplus_vlan_id;

      OPEN c_entree_vlan_id;

      FETCH c_entree_vlan_id
       INTO l_entree_vlan_id;

      CLOSE c_entree_vlan_id;


      OPEN c_xcite_vlan_id;

      FETCH c_xcite_vlan_id
       INTO l_xcite_vlan_id;

      CLOSE c_xcite_vlan_id;

      OPEN c_xciteplus_vlan_id;

      FETCH c_xciteplus_vlan_id
       INTO l_xciteplus_vlan_id;

      CLOSE c_xciteplus_vlan_id;

      OPEN c_xcel_vlan_id;

      FETCH c_xcel_vlan_id
       INTO l_xcel_vlan_id;

      CLOSE c_xcel_vlan_id;

      OPEN c_xcelplus_vlan_id;

      FETCH c_xcelplus_vlan_id
       INTO l_xcelplus_vlan_id;

      CLOSE c_xcelplus_vlan_id;


      OPEN c_seitname;

      FETCH c_seitname
       INTO l_taskname;

      CLOSE c_seitname;



    -----================================= Fayaz 8/8/2011 ========================
/*
      OPEN c_websurferplus_vlan_id;
        FETCH c_websurferplus_vlan_id
            INTO l_websurferplus_vlan_id;
      CLOSE c_websurferplus_vlan_id;

      OPEN c_webproplus_vlan_id;
        FETCH c_webproplus_vlan_id
            INTO l_webproplus_vlan_id;
      CLOSE c_webproplus_vlan_id;

      OPEN c_webmasterplus_vlan_id;
        FETCH c_webmasterplus_vlan_id
            INTO l_webmasterplus_vlan_id;
      CLOSE c_webmasterplus_vlan_id;

      OPEN c_webmate_vlan_id;
        FETCH c_webmate_vlan_id
            INTO l_webmate_vlan_id;
      CLOSE c_webmate_vlan_id;

      OPEN c_websurfer_vlan_id;
        FETCH c_websurfer_vlan_id
            INTO l_websurfer_vlan_id;
      CLOSE c_websurfer_vlan_id;

      OPEN c_webpro_vlan_id;
        FETCH c_webpro_vlan_id
            INTO l_webpro_vlan_id;
      CLOSE c_webpro_vlan_id;

      OPEN c_webmaster_vlan_id;
        FETCH c_webmaster_vlan_id
            INTO l_webmaster_vlan_id;
      CLOSE c_webmaster_vlan_id;
*/
    -----================================= Fayaz 8/8/2011 ========================



      IF     r_service_order.sero_ordt_type = 'MODIFY-SPEED'
         AND (l_command = 'DACT-SERVICEPORT' OR l_command = 'DEL-SERVICEPORT'
             )
      THEN
         l_package_name := l_package_name_old;
      END IF;


      IF r_service_order.sero_ordt_type = 'MODIFY-SERVICE'
      THEN
         IF l_taskname LIKE '%IPTV SERVICE%'
         THEN
            RETURN (l_iptv_vlan_id);
         ELSE
            IF l_package_name = 'HOME'
            THEN
               RETURN (l_home_vlan_id);
            ELSIF l_package_name = 'HOME PLUS'
            THEN
               RETURN (l_homeplus_vlan_id);
            ELSIF l_package_name IN ('OFFICE', 'OFFICE 1IP')
            THEN
               RETURN (l_office_vlan_id);
            ELSIF l_package_name LIKE 'ENTREE%'
            THEN
               RETURN (l_entree_vlan_id);

            ELSIF l_package_name = 'XCITE'
            THEN
               RETURN (l_xcite_vlan_id);
            ELSIF l_package_name IN ('XCEL', 'XCEL 1IP')
            THEN
               RETURN (l_xcel_vlan_id);
            ELSIF l_package_name = 'OFFICE PLUS'
            THEN
               RETURN (l_officeplus_vlan_id);
            ELSIF l_package_name = 'XCITE PLUS'
            THEN
               RETURN (l_xciteplus_vlan_id);
            ELSIF l_package_name = 'XCEL PLUS'
            THEN
               RETURN (l_xcelplus_vlan_id);


    ---================================= Fayaz 8/8/2011 ========================
            ELSIF l_package_name = 'WEB SURFER PLUS'
            THEN
               RETURN (l_entree_vlan_id);
            ELSIF l_package_name = 'WEB PRO PLUS'
            THEN
               RETURN (l_entree_vlan_id);
            ELSIF l_package_name = 'WEB MASTER PLUS'
            THEN
               RETURN (l_entree_vlan_id);
            ELSIF l_package_name = 'WEB MATE'
            THEN
               RETURN (l_entree_vlan_id);
            ELSIF l_package_name = 'WEB SURFER'
            THEN
               RETURN (l_entree_vlan_id);
            ELSIF l_package_name = 'WEB PRO'
            THEN
               RETURN (l_entree_vlan_id);
            ELSIF l_package_name = 'WEB MASTER'
            THEN
               RETURN (l_entree_vlan_id);
            ELSIF l_package_name = 'WEB FAMILY'
            THEN
               RETURN (l_entree_vlan_id);
            ELSIF l_package_name = 'WEB STARTER'
            THEN
               RETURN (l_entree_vlan_id);
            ELSIF l_package_name = 'WEB PAL'
            THEN
               RETURN (l_entree_vlan_id);
            ELSIF l_package_name = 'WEB CHAMP'
            THEN
               RETURN (l_entree_vlan_id);
            ELSIF l_package_name = 'WEB LIFE'
            THEN
               RETURN (l_entree_vlan_id);

            --------------Dinesh Edited on 20/03/2012--------------

            ELSIF l_package_name = 'GMOA_MEDICAL'
            THEN
               RETURN (l_entree_vlan_id);
            ELSIF l_package_name = 'GMOA_ADMIN'
            THEN
               RETURN (l_entree_vlan_id);
            ELSIF l_package_name = 'GMOA_CONSULTANT'
            THEN
               RETURN (l_entree_vlan_id);

            --------------Dinesh Edited on 20/03/2012--------------

            -------------Dinesh Edited on 19/09/2012--------------

            ELSIF l_package_name = 'ABHIMAANA'
            THEN
               RETURN (l_entree_vlan_id);

            ELSIF l_package_name = 'SLT STAFF TRIPLE PLAY'
            THEN
               RETURN (l_entree_vlan_id);

            ELSIF l_package_name = 'STUDENT PACKAGE 1'
            THEN
               RETURN (l_entree_vlan_id);

            ELSIF l_package_name = 'STUDENT PACKAGE 2'
            THEN
               RETURN (l_entree_vlan_id);

            --------------Dinesh Edited on 19/09/2012--------------


    ---================================= Fayaz 8/8/2011 ========================

            END IF;
         END IF;
      ELSE

         IF NVL (l_int_feature, 'N') = 'N' AND NVL (l_iptv_feature, 'N') =
                                                                          'Y'
         THEN                                                    -- IPTV only
            RETURN (l_iptv_vlan_id);
         ELSIF NVL (l_int_feature, 'N') = 'Y'
               AND NVL (l_iptv_feature, 'N') = 'N'
         THEN                                                      -- HSI only

            IF l_package_name = 'HOME'
            THEN
               RETURN (l_home_vlan_id);
            ELSIF l_package_name = 'HOME PLUS'
            THEN
               RETURN (l_homeplus_vlan_id);
            ELSIF l_package_name IN ('OFFICE', 'OFFICE 1IP')
            THEN
               RETURN (l_office_vlan_id);
            ELSIF l_package_name LIKE 'ENTREE%'
            THEN
               RETURN (l_entree_vlan_id);

            ELSIF l_package_name = 'XCITE'
            THEN
               RETURN (l_xcite_vlan_id);
            ELSIF l_package_name IN ('XCEL', 'XCEL 1IP')
            THEN
               RETURN (l_xcel_vlan_id);
            ELSIF l_package_name = 'OFFICE PLUS'
            THEN
               RETURN (l_officeplus_vlan_id);
            ELSIF l_package_name = 'XCITE PLUS'
            THEN
               RETURN (l_xciteplus_vlan_id);
            ELSIF l_package_name = 'XCEL PLUS'
            THEN
               RETURN (l_xcelplus_vlan_id);


    ----================================= Fayaz 8/8/2011 ========================
            ELSIF l_package_name = 'WEB SURFER PLUS'
            THEN
               RETURN (l_entree_vlan_id);
            ELSIF l_package_name = 'WEB PRO PLUS'
            THEN
               RETURN (l_entree_vlan_id);
            ELSIF l_package_name = 'WEB MASTER PLUS'
            THEN
               RETURN (l_entree_vlan_id);
            ELSIF l_package_name = 'WEB MATE'
            THEN
               RETURN (l_entree_vlan_id);
            ELSIF l_package_name = 'WEB SURFER'
            THEN
               RETURN (l_entree_vlan_id);
            ELSIF l_package_name = 'WEB PRO'
            THEN
               RETURN (l_entree_vlan_id);
            ELSIF l_package_name = 'WEB MASTER'
            THEN
               RETURN (l_entree_vlan_id);
            ELSIF l_package_name = 'WEB FAMILY'
            THEN
               RETURN (l_entree_vlan_id);
            ELSIF l_package_name = 'WEB STARTER'
            THEN
               RETURN (l_entree_vlan_id);
            ELSIF l_package_name = 'WEB PAL'
            THEN
               RETURN (l_entree_vlan_id);
            ELSIF l_package_name = 'WEB CHAMP'
            THEN
               RETURN (l_entree_vlan_id);
            ELSIF l_package_name = 'WEB LIFE'
            THEN
               RETURN (l_entree_vlan_id);

            --------------Edited on 20/03/2012--------------

            ELSIF l_package_name = 'GMOA_MEDICAL'
            THEN
               RETURN (l_entree_vlan_id);
            ELSIF l_package_name = 'GMOA_ADMIN'
            THEN
               RETURN (l_entree_vlan_id);
            ELSIF l_package_name = 'GMOA_CONSULTANT'
            THEN
               RETURN (l_entree_vlan_id);

            --------------Edited on 20/03/2012--------------

            -------------Dinesh Edited on 19/09/2012--------------

            ELSIF l_package_name = 'ABHIMAANA'
            THEN
               RETURN (l_entree_vlan_id);


            ELSIF l_package_name = 'SLT STAFF TRIPLE PLAY'
            THEN
               RETURN (l_entree_vlan_id);

            ELSIF l_package_name = 'STUDENT PACKAGE 1'
            THEN
               RETURN (l_entree_vlan_id);

            ELSIF l_package_name = 'STUDENT PACKAGE 2'
            THEN
               RETURN (l_entree_vlan_id);

            --------------Dinesh Edited on 19/09/2012--------------

    ---================================= Fayaz 8/8/2011 ========================

            END IF;
         ELSE                                                  -- HSI and IPTV

            IF    l_command = 'CRT-SERVICEPORT-IPTV'
               OR l_command = 'DEL-SERVICEPORT-IPTV'
            THEN                   -- CRT-SERVICEPORT/DEL-SERVICEPORT for IPTV
               RETURN (l_iptv_vlan_id);
            ELSE                    -- CRT-SERVICEPORT/DEL-SERVICEPORT for HSI
               IF l_package_name = 'HOME'
               THEN
                  RETURN (l_home_vlan_id);
               ELSIF l_package_name = 'HOME PLUS'
               THEN
                  RETURN (l_homeplus_vlan_id);
               ELSIF l_package_name IN ('OFFICE', 'OFFICE 1IP')
               THEN
                  RETURN (l_office_vlan_id);
               ELSIF l_package_name LIKE 'ENTREE%'
               THEN
                  RETURN (l_entree_vlan_id);

               ELSIF l_package_name = 'XCITE'
               THEN
                  RETURN (l_xcite_vlan_id);
               ELSIF l_package_name IN ('XCEL', 'XCEL 1IP')
               THEN
                  RETURN (l_xcel_vlan_id);
               ELSIF l_package_name = 'OFFICE PLUS'
               THEN
                  RETURN (l_officeplus_vlan_id);
               ELSIF l_package_name = 'XCITE PLUS'
               THEN
                  RETURN (l_xciteplus_vlan_id);
               ELSIF l_package_name = 'XCEL PLUS'
               THEN
                  RETURN (l_xcelplus_vlan_id);

    ---------================================= Fayaz 8/8/2011 ========================
                ELSIF l_package_name = 'WEB SURFER PLUS'
                THEN
                   RETURN (l_entree_vlan_id);
                ELSIF l_package_name = 'WEB PRO PLUS'
                THEN
                   RETURN (l_entree_vlan_id);
                ELSIF l_package_name = 'WEB MASTER PLUS'
                THEN
                   RETURN (l_entree_vlan_id);
                ELSIF l_package_name = 'WEB MATE'
                THEN
                   RETURN (l_entree_vlan_id);
                ELSIF l_package_name = 'WEB SURFER'
                THEN
                   RETURN (l_entree_vlan_id);
                ELSIF l_package_name = 'WEB PRO'
                THEN
                   RETURN (l_entree_vlan_id);
                ELSIF l_package_name = 'WEB MASTER'
                THEN
                   RETURN (l_entree_vlan_id);
                ELSIF l_package_name = 'WEB FAMILY'
                THEN
                    RETURN (l_entree_vlan_id);
                ELSIF l_package_name = 'WEB STARTER'
                THEN
                    RETURN (l_entree_vlan_id);
                ELSIF l_package_name = 'WEB PAL'
                THEN
                    RETURN (l_entree_vlan_id);
                ELSIF l_package_name = 'WEB CHAMP'
                THEN
                    RETURN (l_entree_vlan_id);
                ELSIF l_package_name = 'WEB LIFE'
                THEN
                    RETURN (l_entree_vlan_id);

               --------------Edited on 20/03/2012--------------

                ELSIF l_package_name = 'GMOA_MEDICAL'
                THEN
                    RETURN (l_entree_vlan_id);
                ELSIF l_package_name = 'GMOA_ADMIN'
                THEN
                    RETURN (l_entree_vlan_id);
                ELSIF l_package_name = 'GMOA_CONSULTANT'
                THEN
                    RETURN (l_entree_vlan_id);

               --------------Edited on 20/03/2012--------------

               -------------Dinesh Edited on 19/09/2012--------------

                ELSIF l_package_name = 'ABHIMAANA'
                THEN
                    RETURN (l_entree_vlan_id);


                ELSIF l_package_name = 'SLT STAFF TRIPLE PLAY'
                THEN
                    RETURN (l_entree_vlan_id);

                ELSIF l_package_name = 'STUDENT PACKAGE 1'
                THEN
                    RETURN (l_entree_vlan_id);

                ELSIF l_package_name = 'STUDENT PACKAGE 2'
                THEN
                    RETURN (l_entree_vlan_id);

            --------------Dinesh Edited on 19/09/2012--------------

    ---------================================= Fayaz 8/8/2011 ========================
               END IF;
            END IF;

         END IF;


      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END get_dslam_vlan_id;



--==================== Fayaz 10/08/2011 ========================================================

    FUNCTION get_upload_policy (
          PI_SEIT_ID   IN   SERVICE_IMPLEMENTATION_TASKS.SEIT_ID%TYPE,
          PI_SOPC_ID   IN   SOP_COMMANDS.SOPC_ID%TYPE,
          PI_PARAM1    IN   VARCHAR2,
          PI_PARAM2    IN   VARCHAR2
       )
          RETURN VARCHAR2
       IS


            CURSOR CUR_LDAP_SPEED IS
            --SELECT TRIM(SUBSTR(A.SEOA_DEFAULTVALUE,0,(INSTR(A.SEOA_DEFAULTVALUE,'/'))-2)) CURR_DWN, TRIM(SUBSTR(A.SEOA_PREV_VALUE,0,(INSTR(A.SEOA_PREV_VALUE ,'/'))-2)) PRV_DWN
            SELECT TRIM(SUBSTR(A.SEOA_DEFAULTVALUE,(INSTR(A.SEOA_DEFAULTVALUE,'/'))+1,3)) CURR_UP, TRIM(SUBSTR(A.SEOA_PREV_VALUE,(INSTR(A.SEOA_PREV_VALUE,'/'))+1,3)) PRV_UP
            FROM CLARITY.SERVICE_ORDER_ATTRIBUTES A, SERVICE_IMPLEMENTATION_TASKS I
            WHERE A.SEOA_SERO_ID=I.SEIT_SERO_ID
                AND I.SEIT_ID = PI_SEIT_ID
                AND A.SEOA_NAME='SERVICE_SPEED';

            CURSOR CUR_LDAP_PKG IS
            SELECT TRIM(UPPER(A.SEOA_DEFAULTVALUE)) CURR_PKG ---,TRIM(UPPER(A.SEOA_PREV_VALUE)) PRV_PKG
            FROM CLARITY.SERVICE_ORDER_ATTRIBUTES A, SERVICE_IMPLEMENTATION_TASKS I
            WHERE A.SEOA_SERO_ID=I.SEIT_SERO_ID
                AND I.SEIT_ID = PI_SEIT_ID
                AND A.SEOA_NAME='SA_PACKAGE_NAME';
               --- AND A.SEOA_DEFAULTVALUE IN ('Web Surfer Plus','WebSurferPlus','Web Pro Plus','WebProPlus','Web Master Plus','WebMasterPlus',
               ---     'Web Mate','WebMate','Web Surfer','WebSurfer','Web Pro','WebPro','Web Master','WebMaster','ENTREE','ENTRÉE');

            --SELECT UPPER(L.PACKAGE_NAME)
            --FROM CLARITY.LDAP_POLICY L

              V_LDAP_SPEED  CUR_LDAP_SPEED%ROWTYPE;
              V_LDAP_PKG    varchar2(200);----CUR_LDAP_PKG%ROWTYPE;


    BEGIN


        OPEN  CUR_LDAP_SPEED;
            FETCH  CUR_LDAP_SPEED INTO V_LDAP_SPEED;
        CLOSE  CUR_LDAP_SPEED;

        OPEN  CUR_LDAP_PKG;
            FETCH  CUR_LDAP_PKG INTO V_LDAP_PKG;
        CLOSE  CUR_LDAP_PKG;


        IF (V_LDAP_PKG='WEBPROPLUS' OR V_LDAP_PKG='WEB PRO PLUS') THEN
            IF (V_LDAP_SPEED.CURR_UP='64' AND (V_LDAP_SPEED.PRV_UP<>'64' OR V_LDAP_SPEED.PRV_UP <>'')) THEN
                RETURN NULL;
            ELSIF ((V_LDAP_SPEED.CURR_UP<>'64' OR V_LDAP_SPEED.PRV_UP<>'') AND V_LDAP_SPEED.PRV_UP='64') THEN
                RETURN ('webproplus_normal_up');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'webproplus_normal_up'
                where soa.SEOA_NAME = 'LDAP_UP_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            ELSIF ((V_LDAP_SPEED.CURR_UP<>'64' OR V_LDAP_SPEED.PRV_UP<>'') AND V_LDAP_SPEED.PRV_UP ='') THEN
                RETURN ('webproplus_normal_up');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'webproplus_normal_up'
                where soa.SEOA_NAME = 'LDAP_UP_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            END IF;

        ELSIF (V_LDAP_PKG='WEBMASTERPLUS' OR V_LDAP_PKG='WEB MASTER PLUS') THEN
            IF (V_LDAP_SPEED.CURR_UP='64' AND (V_LDAP_SPEED.PRV_UP<>'64' OR V_LDAP_SPEED.PRV_UP<>'')) THEN
                RETURN NULL;
            ELSIF ((V_LDAP_SPEED.CURR_UP<>'64' OR V_LDAP_SPEED.PRV_UP<>'') AND V_LDAP_SPEED.PRV_UP='64') THEN
                RETURN ('webmasterplus_normal_up');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'webmasterplus_normal_up'
                where soa.SEOA_NAME = 'LDAP_UP_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            ELSIF ((V_LDAP_SPEED.CURR_UP<>'64' OR V_LDAP_SPEED.PRV_UP<>'') AND V_LDAP_SPEED.PRV_UP='') THEN
                RETURN ('webmasterplus_normal_up');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'webmasterplus_normal_up'
                where soa.SEOA_NAME = 'LDAP_UP_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            END IF;

        ELSIF (V_LDAP_PKG='WEBMATE' OR V_LDAP_PKG='WEB MATE') THEN
            IF (V_LDAP_SPEED.CURR_UP='64' AND (V_LDAP_SPEED.PRV_UP<>'64' OR V_LDAP_SPEED.PRV_UP<>'')) THEN
                RETURN ('webmate_heavy_up');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'webmate_heavy_up'
                where soa.SEOA_NAME = 'LDAP_UP_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            ELSIF ((V_LDAP_SPEED.CURR_UP<>'64' OR V_LDAP_SPEED.PRV_UP<>'') AND V_LDAP_SPEED.PRV_UP='64') THEN
                RETURN ('webmate_normal_up');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'webmate_normal_up'
                where soa.SEOA_NAME = 'LDAP_UP_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            ELSIF ((V_LDAP_SPEED.CURR_UP<>'64' OR V_LDAP_SPEED.PRV_UP<>'') AND V_LDAP_SPEED.PRV_UP='') THEN
                RETURN ('webmate_normal_up');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'webmate_normal_up'
                where soa.SEOA_NAME = 'LDAP_UP_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            END IF;

        ELSIF (V_LDAP_PKG='WEBSURFER' OR V_LDAP_PKG='WEB SURFER') THEN
            IF (V_LDAP_SPEED.CURR_UP='64' AND (V_LDAP_SPEED.PRV_UP<>'64' OR V_LDAP_SPEED.PRV_UP<>'')) THEN
                RETURN ('websurfer_heavy_up');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'websurfer_heavy_up'
                where soa.SEOA_NAME = 'LDAP_UP_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            ELSIF ((V_LDAP_SPEED.CURR_UP<>'64' OR V_LDAP_SPEED.PRV_UP<>'') AND V_LDAP_SPEED.PRV_UP='64') THEN
                RETURN ('websurfer_normal_up');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'websurfer_normal_up'
                where soa.SEOA_NAME = 'LDAP_UP_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            ELSIF ((V_LDAP_SPEED.CURR_UP<>'64' OR V_LDAP_SPEED.PRV_UP<>'') AND V_LDAP_SPEED.PRV_UP='') THEN
                RETURN ('websurfer_normal_up');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'websurfer_normal_up'
                where soa.SEOA_NAME = 'LDAP_UP_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            END IF;

        ELSIF (V_LDAP_PKG='WEBPRO' OR V_LDAP_PKG='WEB PRO') THEN
            IF (V_LDAP_SPEED.CURR_UP='64' AND (V_LDAP_SPEED.PRV_UP<>'64' OR V_LDAP_SPEED.PRV_UP<>'')) THEN
                RETURN ('webpro_heavy_up');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'webpro_heavy_up'
                where soa.SEOA_NAME = 'LDAP_UP_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            ELSIF ((V_LDAP_SPEED.CURR_UP<>'64' OR V_LDAP_SPEED.PRV_UP<>'') AND V_LDAP_SPEED.PRV_UP='64') THEN
                RETURN ('webpro_normal_up');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'webpro_normal_up'
                where soa.SEOA_NAME = 'LDAP_UP_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            ELSIF ((V_LDAP_SPEED.CURR_UP<>'64' OR V_LDAP_SPEED.PRV_UP<>'') AND V_LDAP_SPEED.PRV_UP='') THEN
                RETURN ('webpro_normal_up');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'webpro_normal_up'
                where soa.SEOA_NAME = 'LDAP_UP_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            END IF;

        ELSIF (V_LDAP_PKG='WEBMASTER' OR V_LDAP_PKG='WEB MASTER') THEN
            IF (V_LDAP_SPEED.CURR_UP='64' AND (V_LDAP_SPEED.PRV_UP<>'64' OR V_LDAP_SPEED.PRV_UP<>'')) THEN
                RETURN ('webmaster_heavy_up');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'webmaster_heavy_up'
                where soa.SEOA_NAME = 'LDAP_UP_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            ELSIF ((V_LDAP_SPEED.CURR_UP<>'64' OR V_LDAP_SPEED.PRV_UP<>'') AND V_LDAP_SPEED.PRV_UP='64') THEN
                RETURN ('webmaster_normal_up');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'webmaster_normal_up'
                where soa.SEOA_NAME = 'LDAP_UP_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            ELSIF ((V_LDAP_SPEED.CURR_UP<>'64' OR V_LDAP_SPEED.PRV_UP<>'') AND V_LDAP_SPEED.PRV_UP='') THEN
                RETURN ('webmaster_normal_up');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'webmaster_normal_up'
                where soa.SEOA_NAME = 'LDAP_UP_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            END IF;

        ELSIF (V_LDAP_PKG='WEBSURFERPLUS' OR V_LDAP_PKG='WEB SURFER PLUS') THEN
            IF (V_LDAP_SPEED.CURR_UP='64' AND (V_LDAP_SPEED.PRV_UP<>'64' OR V_LDAP_SPEED.PRV_UP<>'')) THEN
                RETURN NULL;
            ELSIF ((V_LDAP_SPEED.CURR_UP<>'64' OR V_LDAP_SPEED.PRV_UP<>'') AND V_LDAP_SPEED.PRV_UP='64') THEN
                RETURN ('websurferplus_normal_up');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'websurferplus_normal_up'
                where soa.SEOA_NAME = 'LDAP_UP_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            ELSIF ((V_LDAP_SPEED.CURR_UP<>'64' OR V_LDAP_SPEED.PRV_UP<>'') AND V_LDAP_SPEED.PRV_UP='') THEN
                RETURN ('websurferplus_normal_up');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'websurferplus_normal_up'
                where soa.SEOA_NAME = 'LDAP_UP_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            END IF;

        ELSIF (V_LDAP_PKG='ENTREE' OR V_LDAP_PKG='ENTRÉE') THEN
            IF (V_LDAP_SPEED.CURR_UP='64' AND (V_LDAP_SPEED.PRV_UP<>'64' OR V_LDAP_SPEED.PRV_UP<>'')) THEN
                RETURN ('entree_heavy_up');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'entree_heavy_up'
                where soa.SEOA_NAME = 'LDAP_UP_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            ELSIF ((V_LDAP_SPEED.CURR_UP<>'64' OR V_LDAP_SPEED.PRV_UP<>'') AND V_LDAP_SPEED.PRV_UP='64') THEN
                RETURN ('entree_normal_up');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'entree_normal_up'
                where soa.SEOA_NAME = 'LDAP_UP_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);


            ELSIF ((V_LDAP_SPEED.CURR_UP<>'64' OR V_LDAP_SPEED.PRV_UP<>'') AND V_LDAP_SPEED.PRV_UP='') THEN
                RETURN ('entree_normal_up');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'entree_normal_up'
                where soa.SEOA_NAME = 'LDAP_UP_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);


            END IF;

        ELSE
            --THEN
            RETURN NULL;

        END IF;



       EXCEPTION
          WHEN OTHERS
          THEN
             RETURN NULL;

    END get_upload_policy;


--==================== Fayaz 10/08/2011 ========================================================

    FUNCTION get_download_policy (
          PI_SEIT_ID   IN   SERVICE_IMPLEMENTATION_TASKS.SEIT_ID%TYPE,
          PI_SOPC_ID   IN   SOP_COMMANDS.SOPC_ID%TYPE,
          PI_PARAM1    IN   VARCHAR2,
          PI_PARAM2    IN   VARCHAR2
       )
          RETURN VARCHAR2
       IS


            CURSOR CUR_LDAP_SPEED IS
            ---SELECT TRIM(SUBSTR(A.SEOA_DEFAULTVALUE,(INSTR(A.SEOA_DEFAULTVALUE,'/'))+1,3)) CURR_UP, TRIM(SUBSTR(A.SEOA_PREV_VALUE,(INSTR(A.SEOA_PREV_VALUE,'/'))+1,3)) PRV_UP
            SELECT TRIM(SUBSTR(A.SEOA_DEFAULTVALUE,0,(INSTR(A.SEOA_DEFAULTVALUE,'/'))-2)) CURR_DWN, TRIM(SUBSTR(A.SEOA_PREV_VALUE,0,(INSTR(A.SEOA_PREV_VALUE ,'/'))-2)) PRV_DWN
            FROM CLARITY.SERVICE_ORDER_ATTRIBUTES A, SERVICE_IMPLEMENTATION_TASKS I
            WHERE A.SEOA_SERO_ID=I.SEIT_SERO_ID
                AND I.SEIT_ID = PI_SEIT_ID
                AND A.SEOA_NAME='SERVICE_SPEED';

            CURSOR CUR_LDAP_PKG IS
            SELECT TRIM(UPPER(A.SEOA_DEFAULTVALUE)) CURR_PKG ---,TRIM(UPPER(A.SEOA_PREV_VALUE)) PRV_PKG
            FROM CLARITY.SERVICE_ORDER_ATTRIBUTES A, SERVICE_IMPLEMENTATION_TASKS I
            WHERE A.SEOA_SERO_ID=I.SEIT_SERO_ID
                AND I.SEIT_ID = PI_SEIT_ID
                AND A.SEOA_NAME='SA_PACKAGE_NAME';
               --- AND A.SEOA_DEFAULTVALUE IN ('Web Surfer Plus','WebSurferPlus','Web Pro Plus','WebProPlus','Web Master Plus','WebMasterPlus',
                ---    'Web Mate','WebMate','Web Surfer','WebSurfer','Web Pro','WebPro','Web Master','WebMaster','ENTREE','ENTRÉE');

            ---SELECT UPPER(L.PACKAGE_NAME)
            ---FROM CLARITY.LDAP_POLICY L

              V_LDAP_SPEED  CUR_LDAP_SPEED%ROWTYPE;
              V_LDAP_PKG    varchar2(200);--CUR_LDAP_PKG%ROWTYPE;


    BEGIN


        OPEN  CUR_LDAP_SPEED;
            FETCH  CUR_LDAP_SPEED INTO V_LDAP_SPEED;
        CLOSE  CUR_LDAP_SPEED;

        OPEN  CUR_LDAP_PKG;
            FETCH  CUR_LDAP_PKG INTO V_LDAP_PKG;
        CLOSE  CUR_LDAP_PKG;


        IF (V_LDAP_PKG='WEBPROPLUS' OR V_LDAP_PKG='WEB PRO PLUS') THEN
            IF (V_LDAP_SPEED.CURR_DWN='64' AND (V_LDAP_SPEED.PRV_DWN<>'64' OR V_LDAP_SPEED.PRV_DWN<>'')) THEN
                RETURN NULL;
            ELSIF ((V_LDAP_SPEED.CURR_DWN<>'64' OR V_LDAP_SPEED.CURR_DWN<>'') AND V_LDAP_SPEED.PRV_DWN='64') THEN
                RETURN ('webproplus_normal_down');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'webproplus_normal_down'
                where soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            ELSIF ((V_LDAP_SPEED.CURR_DWN<>'64' OR V_LDAP_SPEED.CURR_DWN<>'') AND V_LDAP_SPEED.PRV_DWN='') THEN
                RETURN ('webproplus_normal_down');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'webproplus_normal_down'
                where soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            END IF;

        ELSIF (V_LDAP_PKG='WEBMASTERPLUS' OR V_LDAP_PKG='WEB MASTER PLUS') THEN
            IF (V_LDAP_SPEED.CURR_DWN='64' AND (V_LDAP_SPEED.PRV_DWN<>'64' OR V_LDAP_SPEED.PRV_DWN<>'')) THEN
                RETURN NULL;
            ELSIF ((V_LDAP_SPEED.CURR_DWN<>'64' OR V_LDAP_SPEED.CURR_DWN<>'') AND V_LDAP_SPEED.PRV_DWN='64') THEN
                RETURN ('webmasterplus_normal_down');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'webmasterplus_normal_down'
                where soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            ELSIF ((V_LDAP_SPEED.CURR_DWN<>'64' OR V_LDAP_SPEED.CURR_DWN<>'') AND V_LDAP_SPEED.PRV_DWN='') THEN
                RETURN ('webmasterplus_normal_down');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'webmasterplus_normal_down'
                where soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            END IF;

        ELSIF (V_LDAP_PKG='WEBMATE' OR V_LDAP_PKG='WEB MATE') THEN
            IF (V_LDAP_SPEED.CURR_DWN='64' AND (V_LDAP_SPEED.PRV_DWN<>'64' OR V_LDAP_SPEED.PRV_DWN<>'')) THEN
                RETURN ('webmate_heavy_down');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'webmate_heavy_down'
                where soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            ELSIF ((V_LDAP_SPEED.CURR_DWN<>'64' OR V_LDAP_SPEED.CURR_DWN<>'') AND V_LDAP_SPEED.PRV_DWN='64') THEN
                RETURN ('webmate_normal_down');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'webmate_normal_down'
                where soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            ELSIF ((V_LDAP_SPEED.CURR_DWN<>'64' OR V_LDAP_SPEED.CURR_DWN<>'') AND V_LDAP_SPEED.PRV_DWN='') THEN
                RETURN ('webmate_normal_down');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'webmate_normal_down'
                where soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            END IF;

        ELSIF (V_LDAP_PKG='WEBSURFER' OR V_LDAP_PKG='WEB SURFER') THEN
            IF (V_LDAP_SPEED.CURR_DWN='64' AND (V_LDAP_SPEED.PRV_DWN<>'64' OR V_LDAP_SPEED.PRV_DWN<>'')) THEN
                RETURN ('websurfer_heavy_down');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'websurfer_heavy_down'
                where soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            ELSIF ((V_LDAP_SPEED.CURR_DWN<>'64' OR V_LDAP_SPEED.CURR_DWN<>'') AND V_LDAP_SPEED.PRV_DWN='64') THEN
                RETURN ('websurfer_normal_down');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'websurfer_normal_down'
                where soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            ELSIF ((V_LDAP_SPEED.CURR_DWN<>'64' OR V_LDAP_SPEED.CURR_DWN<>'') AND V_LDAP_SPEED.PRV_DWN='') THEN
                RETURN ('websurfer_normal_down');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'websurfer_normal_down'
                where soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            END IF;

        ELSIF (V_LDAP_PKG='WEBPRO' OR V_LDAP_PKG='WEB PRO') THEN
            IF (V_LDAP_SPEED.CURR_DWN='64' AND (V_LDAP_SPEED.PRV_DWN<>'64' OR V_LDAP_SPEED.PRV_DWN<>'')) THEN
                RETURN ('webpro_heavy_down');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'webpro_heavy_down'
                where soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            ELSIF ((V_LDAP_SPEED.CURR_DWN<>'64' OR V_LDAP_SPEED.CURR_DWN<>'') AND V_LDAP_SPEED.PRV_DWN='64') THEN
                RETURN ('webpro_normal_down');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'webpro_normal_down'
                where soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            ELSIF ((V_LDAP_SPEED.CURR_DWN<>'64' OR V_LDAP_SPEED.CURR_DWN<>'') AND V_LDAP_SPEED.PRV_DWN='') THEN
                RETURN ('webpro_normal_down');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'webpro_normal_down'
                where soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            END IF;

        ELSIF (V_LDAP_PKG='WEBMASTER' OR V_LDAP_PKG='WEB MASTER') THEN
            IF (V_LDAP_SPEED.CURR_DWN='64' AND (V_LDAP_SPEED.PRV_DWN<>'64' OR V_LDAP_SPEED.PRV_DWN<>'')) THEN
                RETURN ('webmaster_heavy_down');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'webmaster_heavy_down'
                where soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            ELSIF ((V_LDAP_SPEED.CURR_DWN<>'64' OR V_LDAP_SPEED.CURR_DWN<>'') AND V_LDAP_SPEED.PRV_DWN='64') THEN
                RETURN ('webmaster_normal_down');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'webmaster_normal_down'
                where soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            ELSIF ((V_LDAP_SPEED.CURR_DWN<>'64' OR V_LDAP_SPEED.CURR_DWN<>'') AND V_LDAP_SPEED.PRV_DWN='') THEN
                RETURN ('webmaster_normal_down');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'webmaster_normal_down'
                where soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            END IF;

        ELSIF (V_LDAP_PKG='WEBSURFERPLUS' OR V_LDAP_PKG='WEB SURFER PLUS') THEN
            IF (V_LDAP_SPEED.CURR_DWN='64' AND (V_LDAP_SPEED.PRV_DWN<>'64' OR V_LDAP_SPEED.PRV_DWN<>'')) THEN
                RETURN NULL;
            ELSIF ((V_LDAP_SPEED.CURR_DWN<>'64' OR V_LDAP_SPEED.CURR_DWN<>'') AND V_LDAP_SPEED.PRV_DWN='64') THEN
                RETURN ('websurferplus_normal_down');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'websurferplus_normal_down'
                where soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            ELSIF ((V_LDAP_SPEED.CURR_DWN<>'64' OR V_LDAP_SPEED.CURR_DWN<>'') AND V_LDAP_SPEED.PRV_DWN='') THEN
                RETURN ('websurferplus_normal_down');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'websurferplus_normal_down'
                where soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            END IF;

        ELSIF (V_LDAP_PKG='ENTREE' OR V_LDAP_PKG='ENTRÉE') THEN
            IF (V_LDAP_SPEED.CURR_DWN='64' AND (V_LDAP_SPEED.PRV_DWN<>'64' OR V_LDAP_SPEED.PRV_DWN<>'')) THEN
                RETURN ('entree_heavy_down');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'entree_heavy_dow'
                where soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            ELSIF ((V_LDAP_SPEED.CURR_DWN<>'64' OR V_LDAP_SPEED.CURR_DWN<>'') AND V_LDAP_SPEED.PRV_DWN='64') THEN
                RETURN ('entree_normal_down');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'entree_normal_down'
                where soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            ELSIF ((V_LDAP_SPEED.CURR_DWN<>'64' OR V_LDAP_SPEED.CURR_DWN<>'') AND V_LDAP_SPEED.PRV_DWN='') THEN
                RETURN ('entree_normal_down');

                update SERVICE_ORDER_ATTRIBUTES soa
                set soa.SEOA_DEFAULTVALUE = 'entree_normal_down'
                where soa.SEOA_NAME = 'LDAP_DOWN_POLICY'
                and soa.SEOA_SERO_ID in
                (select sit.SEIT_SERO_ID
                from SERVICE_IMPLEMENTATION_TASKS sit
                where sit.SEIT_ID = PI_SEIT_ID);

            END IF;

        ELSE
            RETURN NULL;

        END IF;



       EXCEPTION
          WHEN OTHERS
          THEN
             RETURN NULL;

    END get_download_policy;

--==============================================================================================

---------------- Jayan Liyanage  Edit 2011 08 27  ---------------------------------------------------

 FUNCTION get_dslam_rx (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS
      -- E. Son 10-02-2008 Start
      CURSOR c_seitname
      IS
         SELECT seit_taskname
           FROM service_implementation_tasks
          WHERE seit_id = pi_seit_id;

      CURSOR c_service_order
      IS
         SELECT *
           FROM service_orders, service_implementation_tasks
          WHERE seit_id = pi_seit_id AND sero_id = seit_sero_id;

      -- E. Son 10-02-2008 End
      CURSOR c_command
      IS
         SELECT sopc_command
           FROM sop_commands
          WHERE sopc_id = pi_sopc_id;

      CURSOR c_int_feature
      IS
         SELECT sofe_defaultvalue
           FROM service_order_features, service_implementation_tasks
          WHERE seit_id = pi_seit_id
            AND sofe_sero_id = seit_sero_id
            AND sofe_feature_name = 'INTERNET';

      CURSOR c_iptv_feature
      IS
         SELECT sofe_defaultvalue
           FROM service_order_features, service_implementation_tasks
          WHERE seit_id = pi_seit_id
            AND sofe_sero_id = seit_sero_id
            AND sofe_feature_name = 'IPTV';

      CURSOR c_package_name
      IS
         SELECT seoa_defaultvalue
           FROM service_order_attributes, service_implementation_tasks
          WHERE seit_id = pi_seit_id
            AND seoa_sero_id = seit_sero_id
            AND seoa_name = 'SA_PACKAGE_NAME';

      l_int_feature     service_order_features.sofe_defaultvalue%TYPE;
      l_iptv_feature    service_order_features.sofe_defaultvalue%TYPE;
      l_package_name    service_order_attributes.seoa_defaultvalue%TYPE;
      l_command         sop_commands.sopc_command%TYPE;
      -- E. Son 10-02-2008 Start
      r_service_order   c_service_order%ROWTYPE;
      l_taskname        service_implementation_tasks.seit_taskname%TYPE;
   -- E. Son 10-02-2008 End
   BEGIN
      OPEN c_iptv_feature;

      FETCH c_iptv_feature
       INTO l_iptv_feature;

      CLOSE c_iptv_feature;

      OPEN c_int_feature;

      FETCH c_int_feature
       INTO l_int_feature;

      CLOSE c_int_feature;

      OPEN c_package_name;

      FETCH c_package_name
       INTO l_package_name;

      CLOSE c_package_name;

      OPEN c_command;

      FETCH c_command
       INTO l_command;

      CLOSE c_command;

      -- E. Son 10-02-2008 Start
      OPEN c_seitname;

      FETCH c_seitname
       INTO l_taskname;

      CLOSE c_seitname;

      OPEN c_service_order;

      FETCH c_service_order
       INTO r_service_order;

      CLOSE c_service_order;

      -- E. Son 10-02-2008 End

      -- E. Son 10-02-2008 Start
      IF r_service_order.sero_ordt_type = 'MODIFY-SERVICE'
      THEN
         IF l_taskname LIKE '%IPTV SERVICE%'
         THEN
            RETURN ('IPTV');
         ELSE
            IF l_package_name = 'HOME'
            THEN
               RETURN ('HomeExpress');
            ELSIF l_package_name LIKE 'HOME PLUS'
            THEN
               RETURN ('Xcite_D');
            ELSIF l_package_name IN ('OFFICE', 'OFFICE 1IP', 'OFFICE PLUS')
            THEN
               RETURN ('OfficeExpress');
            ELSIF l_package_name LIKE 'ENTREE%'
            THEN
               --RETURN ('HomeExpress');
               RETURN ('Xcite_D');
            --------------- Jayan Liyanage ADD 2009 02 13 -----
            ELSIF l_package_name IN ('XCITE', 'XCITE PLUS')
            THEN
               RETURN ('Xcite_D');
            ELSIF l_package_name IN ('XCEL', 'XCEL 1IP', 'XCEL PLUS')
            THEN
               RETURN ('Xcel_D');
            --------------- Jayan Liyanage ADD 2009 02 13 -----

            -------------------Jayan Liyanage  2011/08/27------------------------------------------------

            ELSIF l_package_name IN ('WEB MATE')
            THEN
               RETURN ('HomeExpress');

            ELSIF l_package_name IN ('WEB PRO', 'WEB PRO PLUS')
            THEN
               RETURN ('OfficeExpress');

            ELSIF l_package_name IN ('WEB MASTER', 'WEB MASTER PLUS')
            THEN
               RETURN ('Xcel_D');

            ELSIF l_package_name IN ('WEB SURFER', 'WEB SURFER PLUS')
            THEN
               RETURN ('Xcite_D');

            -----------------------Jayan Liyanage  2011/08/27---------------------------------------------
            END IF;
         END IF;
      ELSE                                            -- E. Son 10-02-2008 End
         IF NVL (l_int_feature, 'N') = 'Y' AND NVL (l_iptv_feature, 'N') =
                                                                          'N'
         THEN                                                     -- HSI only
            IF l_package_name = 'HOME'
            THEN
               RETURN ('HomeExpress');
            ELSIF l_package_name LIKE 'HOME PLUS'
            THEN
               RETURN ('Xcite_D');
            ELSIF l_package_name IN ('OFFICE', 'OFFICE 1IP', 'OFFICE PLUS')
            THEN
               RETURN ('OfficeExpress');
            ELSIF l_package_name LIKE 'ENTREE%'
            THEN
               --RETURN ('HomeExpress');
               RETURN ('Xcite_D');
            --------------- Jayan Liyanage ADD 2009 02 13 -----
            ELSIF l_package_name IN ('XCITE', 'XCITE PLUS')
            THEN
               RETURN ('Xcite_D');
            ELSIF l_package_name IN ('XCEL', 'XCEL 1IP', 'XCEL PLUS')
            THEN
               RETURN ('Xcel_D');
            --------------- Jayan Liyanage ADD 2009 02 13 -----

            -------------------Jayan Liyanage  2011/08/27-----------------------------

            ELSIF l_package_name IN ('WEB MATE')
            THEN
               RETURN ('HomeExpress');

            ELSIF l_package_name IN ('WEB PRO', 'WEB PRO PLUS')
            THEN
               RETURN ('OfficeExpress');

            ELSIF l_package_name IN ('WEB MASTER', 'WEB MASTER PLUS')
            THEN
               RETURN ('Xcel_D');

            ELSIF l_package_name IN ('WEB SURFER', 'WEB SURFER PLUS')
            THEN
               RETURN ('Xcite_D');


            -----------------------Jayan Liyanage  2011/08/27--------------------------

            END IF;
         ELSIF NVL (l_int_feature, 'N') = 'N'
               AND NVL (l_iptv_feature, 'N') = 'Y'
         THEN                                                     -- IPTV only
            RETURN ('IPTV');
         ELSE                                                  -- HSI and IPTV
            -- E. Son 09-29-2008 start
            IF l_command = 'CRT-SERVICEPORT-IPTV'
            THEN                                  -- CRT-SERVICEPORT for IPTV
               RETURN ('IPTV');
            ELSE                                    -- CRT-SERVICEPORT for HSI
               IF l_package_name = 'HOME'
               THEN
                  RETURN ('HomeExpress');
               ELSIF l_package_name LIKE 'HOME PLUS'
               THEN
                  RETURN ('Xcite_D');
               ELSIF l_package_name IN
                                      ('OFFICE', 'OFFICE 1IP', 'OFFICE PLUS')
               THEN
                  RETURN ('OfficeExpress');
               ELSIF l_package_name LIKE 'ENTREE%'
               THEN
                  --RETURN ('HomeExpress');
                  RETURN ('Xcite_D');
               --------------- Jayan Liyanage ADD 2009 02 13 -----
               ELSIF l_package_name IN ('XCITE', 'XCITE PLUS')
               THEN
                  RETURN ('Xcite_D');
               ELSIF l_package_name IN ('XCEL', 'XCEL 1IP', 'XCEL PLUS')
               THEN
                  RETURN ('Xcel_D');
               --------------- Jayan Liyanage ADD 2009 02 13 -----

               -------------------Jayan Liyanage  2011/08/27------------------------------------------------



               ELSIF l_package_name IN ('WEB MATE')
            THEN
               RETURN ('HomeExpress');

            ELSIF l_package_name IN ('WEB PRO', 'WEB PRO PLUS')
            THEN
               RETURN ('OfficeExpress');

            ELSIF l_package_name IN ('WEB MASTER', 'WEB MASTER PLUS')
            THEN
               RETURN ('Xcel_D');

            ELSIF l_package_name IN ('WEB SURFER', 'WEB SURFER PLUS')
            THEN
               RETURN ('Xcite_D');


            -----------------------Jayan Liyanage  2011/08/27---------------------------------------------

               END IF;
            END IF;
         -- E. Son 09-29-2008 end
         END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END get_dslam_rx;

---------------- Jayan Liyanage  Edit 2011 08 27  ----------------------------------------------------

---------------- Jayan Liyanage  Edit 2011 08 27  ----------------------------------------------------

 FUNCTION get_dslam_tx (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS
      -- E. Son 10-02-2008 Start
      CURSOR c_seitname
      IS
         SELECT seit_taskname
           FROM service_implementation_tasks
          WHERE seit_id = pi_seit_id;

      CURSOR c_service_order
      IS
         SELECT *
           FROM service_orders, service_implementation_tasks
          WHERE seit_id = pi_seit_id AND sero_id = seit_sero_id;

      -- E. Son 10-02-2008 End
      CURSOR c_command
      IS
         SELECT sopc_command
           FROM sop_commands
          WHERE sopc_id = pi_sopc_id;

      CURSOR c_int_feature
      IS
         SELECT sofe_defaultvalue
           FROM service_order_features, service_implementation_tasks
          WHERE seit_id = pi_seit_id
            AND sofe_sero_id = seit_sero_id
            AND sofe_feature_name = 'INTERNET';

      CURSOR c_iptv_feature
      IS
         SELECT sofe_defaultvalue
           FROM service_order_features, service_implementation_tasks
          WHERE seit_id = pi_seit_id
            AND sofe_sero_id = seit_sero_id
            AND sofe_feature_name = 'IPTV';

      CURSOR c_package_name
      IS
         SELECT seoa_defaultvalue
           FROM service_order_attributes, service_implementation_tasks
          WHERE seit_id = pi_seit_id
            AND seoa_sero_id = seit_sero_id
            AND seoa_name = 'SA_PACKAGE_NAME';

      l_int_feature     service_order_features.sofe_defaultvalue%TYPE;
      l_iptv_feature    service_order_features.sofe_defaultvalue%TYPE;
      l_package_name    service_order_attributes.seoa_defaultvalue%TYPE;
      l_command         sop_commands.sopc_command%TYPE;
      -- E. Son 10-02-2008 Start
      r_service_order   c_service_order%ROWTYPE;
      l_taskname        service_implementation_tasks.seit_taskname%TYPE;
   -- E. Son 10-02-2008 End
   BEGIN
      OPEN c_iptv_feature;

      FETCH c_iptv_feature
       INTO l_iptv_feature;

      CLOSE c_iptv_feature;

      OPEN c_int_feature;

      FETCH c_int_feature
       INTO l_int_feature;

      CLOSE c_int_feature;

      OPEN c_package_name;

      FETCH c_package_name
       INTO l_package_name;

      CLOSE c_package_name;

      OPEN c_command;

      FETCH c_command
       INTO l_command;

      CLOSE c_command;

      -- E. Son 10-02-2008 Start
      OPEN c_seitname;

      FETCH c_seitname
       INTO l_taskname;

      CLOSE c_seitname;

      OPEN c_service_order;

      FETCH c_service_order
       INTO r_service_order;

      CLOSE c_service_order;

      -- E. Son 10-02-2008 End

      -- E. Son 10-02-2008 Start
      IF r_service_order.sero_ordt_type = 'MODIFY-SERVICE'
      THEN
         IF l_taskname LIKE '%IPTV SERVICE%'
         THEN
            RETURN ('IPTV_U');
         ELSE
            IF l_package_name = 'HOME'
            THEN
               RETURN ('HomeExpress_U');
            ELSIF l_package_name = 'HOME PLUS'
            THEN
               RETURN ('HomeExpress_U');
            ELSIF l_package_name IN ('OFFICE', 'OFFICE 1IP', 'OFFICE PLUS')
            THEN
               RETURN ('OfficeExpress_U');
            ELSIF l_package_name LIKE 'ENTREE%'
            THEN
               RETURN ('HomeExpress_U');
            --------------- Jayan Liyanage ADD 2009 02 13 -----
            ELSIF l_package_name IN ('XCITE', 'XCITE PLUS')
            THEN
               RETURN ('Xcite_U');
            ELSIF l_package_name IN ('XCEL', 'XCEL 1IP', 'XCEL PLUS')
            THEN
               RETURN ('Xcel_U');
            --------------- Jayan Liyanage ADD 2009 02 13 -----


            -------------------Jayan Liyanage  2011/08/27----------------------------------------------
            ELSIF l_package_name IN ('WEB MATE', 'WEB SURFER PLUS')
            THEN
               RETURN ('HomeExpress_U');

            ELSIF l_package_name IN ('WEB PRO', 'WEB PRO PLUS')
            THEN
               RETURN ('OfficeExpress_U');

            ELSIF l_package_name IN ('WEB MASTER', 'WEB MASTER PLUS')
            THEN
               RETURN ('Xcel_U');

            ELSIF l_package_name IN ('WEB SURFER')
            THEN
               RETURN ('Xcite_U');

            --------------------Jayan Liyanage  2011/08/27---------------------------------------------



            END IF;
         END IF;
      ELSE                                            -- E. Son 10-02-2008 End
         IF NVL (l_int_feature, 'N') = 'Y' AND NVL (l_iptv_feature, 'N') =
                                                                          'N'
         THEN                                                     -- HSI only
            IF l_package_name = 'HOME'
            THEN
               RETURN ('HomeExpress_U');
            ELSIF l_package_name = 'HOME PLUS'
            THEN
               RETURN ('HomeExpress_U');
            ELSIF l_package_name IN ('OFFICE', 'OFFICE 1IP', 'OFFICE PLUS')
            THEN
               RETURN ('OfficeExpress_U');
            ELSIF l_package_name LIKE 'ENTREE%'
            THEN
               RETURN ('HomeExpress_U');
            --------------- Jayan Liyanage ADD 2009 02 13 -----
            ELSIF l_package_name IN ('XCITE', 'XCITE PLUS')
            THEN
               RETURN ('Xcite_U');
            ELSIF l_package_name IN ('XCEL', 'XCEL 1IP', 'XCEL PLUS')
            THEN
               RETURN ('Xcel_U');
            --------------- Jayan Liyanage ADD 2009 02 13 -----

            -------------------Jayan Liyanage  2011/08/27---------------------------------------------

            ELSIF l_package_name IN ('WEB MATE', 'WEB SURFER PLUS')
            THEN
               RETURN ('HomeExpress_U');

            ELSIF l_package_name IN ('WEB PRO', 'WEB PRO PLUS')
            THEN
               RETURN ('OfficeExpress_U');

            ELSIF l_package_name IN ('WEB MASTER', 'WEB MASTER PLUS')
            THEN
               RETURN ('Xcel_U');

            ELSIF l_package_name IN ('WEB SURFER')
            THEN
               RETURN ('Xcite_U');

            -------------------Jayan Liyanage  2011/08/27---------------------------------------------

            END IF;
         ELSIF NVL (l_int_feature, 'N') = 'N'
               AND NVL (l_iptv_feature, 'N') = 'Y'
         THEN                                                     -- IPTV only
            RETURN ('IPTV_U');
         ELSE                                                  -- HSI and IPTV
            -- E. Son 09-29-2008 start
            IF l_command = 'CRT-SERVICEPORT-IPTV'
            THEN                                  -- CRT-SERVICEPORT for IPTV
               RETURN ('IPTV_U');
            ELSE                                    -- CRT-SERVICEPORT for HSI
               IF l_package_name = 'HOME'
               THEN
                  RETURN ('HomeExpress_U');
               ELSIF l_package_name = 'HOME PLUS'
               THEN
                  RETURN ('HomeExpress_U');
               ELSIF l_package_name IN
                                      ('OFFICE', 'OFFICE 1IP', 'OFFICE PLUS')
               THEN
                  RETURN ('OfficeExpress_U');
               ELSIF l_package_name LIKE 'ENTREE%'
               THEN
                  RETURN ('HomeExpress_U');
               --------------- Jayan Liyanage ADD 2009 02 13 -----
               ELSIF l_package_name IN ('XCITE', 'XCITE PLUS')
               THEN
                  RETURN ('Xcite_U');
               ELSIF l_package_name IN ('XCEL', 'XCEL 1IP', 'XCEL PLUS')
               THEN
                  RETURN ('Xcel_U');
               --------------- Jayan Liyanage ADD 2009 02 13 -----

               -------------------Jayan Liyanage  2011/08/27---------------------------------------------

               ELSIF l_package_name IN ('WEB MATE', 'WEB SURFER PLUS')
            THEN
               RETURN ('HomeExpress_U');

            ELSIF l_package_name IN ('WEB PRO', 'WEB PRO PLUS')
            THEN
               RETURN ('OfficeExpress_U');

            ELSIF l_package_name IN ('WEB MASTER', 'WEB MASTER PLUS')
            THEN
               RETURN ('Xcel_U');

            ELSIF l_package_name IN ('WEB SURFER')
            THEN
               RETURN ('Xcite_U');

               -------------------Jayan Liyanage  2011/08/27---------------------------------------------


               END IF;
            END IF;
         -- E. Son 09-29-2008 end
         END IF;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END get_dslam_tx;

---------------- Jayan Liyanage  Edit 2011 08 27  ----------------------------------------------------

---------------- Janaka 2012 02 21  ----------------------------------------------------
FUNCTION get_dslam_svlan_id (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2,
      p_ret_msg                   OUT    VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR c_svlan_id (v_seit_id Service_Implementation_Tasks.seit_id%TYPE) IS

    SELECT
    SUBSTR(SORD_VALUE,INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'SVLAN'||CHR(9))-1),CHR(9),-1,1)+1,(INSTR(SORD_VALUE,CHR(9)||'SVLAN'||CHR(9))) - (INSTR(SUBSTR(SORD_VALUE,1,INSTR(SORD_VALUE,CHR(9)||'SVLAN'||CHR(9))-1),CHR(9),-1,1)+1)) EntreeSVLAN
     FROM service_implementation_tasks,
              sop_queue,
              sop_reply_data
        WHERE seit_id = v_seit_id
          AND sopq_seit_id = seit_id
          AND sopq_sopc_command = 'LST-VLAN'
          AND sord_name = 'RAW_MESSAGES' --Changed on 25Jun2013 to support C12 SOPAgent
          AND sord_sopq_requestid = sopq_requestid;


           /* SELECT DISTINCT EQDI_VALUE
           FROM service_implementation_tasks,
                service_orders,
                circuits,
                port_links,
                port_link_ports,
                ports,
                EQUIPMENT_DETAIL_INSTANCE EQ
          WHERE seit_id = pi_seit_id
            AND sero_id = seit_sero_id
            --AND SEIT_SERO_ID='CEN200704090044197'
            AND cirt_name = sero_cirt_name
            AND porl_cirt_name = cirt_name
            AND polp_porl_id = porl_id
            AND port_id = polp_port_id
            ----AND SEIT_TIMING=95
            AND PORT_EQUP_ID = eq.EQDI_EQUP_ID;*/



      l_svlan_id         NUMBER;

    v_seit_id Service_Implementation_Tasks.seit_id%TYPE;
   BEGIN

         BEGIN
            SELECT MAX(SEIT_ID)
            INTO v_seit_id
            FROM SERVICE_IMPLEMENTATION_TASKS
            WHERE SEIT_SERO_ID = (SELECT SEIT_SERO_ID FROM SERVICE_IMPLEMENTATION_TASKS WHERE seit_id = pi_seit_id)
            AND SEIT_TASKNAME IN ('QUERY DSLAM VLAN ID','QUERY VLAN ID');
         EXCEPTION
           WHEN OTHERS THEN
              p_ret_msg  := 'Unable to get Task Id for QUERY DSLAM VLAN ID Task';
         END;


      OPEN c_svlan_id(v_seit_id);

      FETCH c_svlan_id
       INTO l_svlan_id;

      CLOSE c_svlan_id;

      RETURN l_svlan_id;

   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END get_dslam_svlan_id;

---------------- Janaka 2012 02 21  ----------------------------------------------------

---------------- Gihan 2012 12 17  ----------------------------------------------------
   FUNCTION get_next_billdate (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS
      l_next_bdate   VARCHAR2(12);
   BEGIN
    select to_char(add_months(trunc(sysdate,'MM'),1),'YYYYMMDD') into l_next_bdate from dual;

    RETURN l_next_bdate;

   END get_next_billdate;

   ---- Modified Dinesh 15-08-2013------
   --- Modified Dinesh 14-08-2014 ------
   ---- Modified Dinesh 24-02-2015 ----
FUNCTION get_ldap_password (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

   CURSOR c_sero_id IS
      SELECT seit_sero_id, seit_sero_revision
      FROM   service_implementation_tasks
      WHERE  seit_id = pi_seit_id;

    CURSOR C_ORDT_TYPE (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

        SELECT DISTINCT(SERO_ORDT_TYPE)
        FROM SERVICE_ORDERS
        WHERE SERO_ID=T_SERO_ID;


   CURSOR c_seit_id (t_sero_id service_implementation_tasks.seit_sero_id%TYPE, t_sero_revision service_implementation_tasks.seit_sero_revision%TYPE) IS
      SELECT seit_id
      FROM   service_implementation_tasks
      WHERE  seit_sero_id = t_sero_id
      AND    seit_sero_revision = t_sero_revision
      AND    seit_taskname = 'QUERY USER PASSWORD';

   CURSOR c_sord_value (t_seit_id sop_queue.sopq_seit_id%TYPE) IS
      select distinct(sord_value) FROM SOP_REPLY_DATA
      WHERE SORD_ID =
      (SELECT MAX(SORD_ID) from sop_reply_data, sop_queue
      where sord_sopq_requestid = sopq_requestid
      and SOPQ_SOPC_COMMAND = 'LDAP_QUERY_PASSWORD'
      and sord_name = 'description' ----'userpassword' CHANGED ON 14-08-2014 --Changed on 25Jun2013 to support C12 SOPAgent
      and sopq_seit_id = t_seit_id);


    CURSOR c_seit_id_N (t_sero_id service_implementation_tasks.seit_sero_id%TYPE, t_sero_revision service_implementation_tasks.seit_sero_revision%TYPE) IS
      SELECT seit_id
      FROM   service_implementation_tasks
      WHERE  seit_sero_id = t_sero_id
      AND    seit_sero_revision = t_sero_revision
      AND    SEIT_TASKNAME = 'MODIFY USER NAME';

   CURSOR c_sord_value_N (t_seit_id sop_queue.sopq_seit_id%TYPE) IS
      select distinct(sord_value) FROM SOP_REPLY_DATA
      WHERE SORD_ID =
      (SELECT MAX(SORD_ID) from sop_reply_data, sop_queue
      where sord_sopq_requestid = sopq_requestid
      and SOPQ_SOPC_COMMAND IN ('LDAP_GET_USER_PASS','LDAP_GET_USER_PASS_LTE')
      AND SORD_NAME='description'
      and sopq_seit_id = t_seit_id);

      l_sero_id   service_implementation_tasks.seit_sero_id%TYPE;
      V_SERO_ORDT_TYPE SERVICE_ORDERS.SERO_SERV_ID%TYPE;
      l_sero_revision service_implementation_tasks.seit_sero_revision%TYPE;
      l_seit_id sop_queue.sopq_seit_id%TYPE;
      l_sord_value sop_reply_data.sord_value%TYPE;

      V_TEMP_CODE     VARCHAR2(500);
      V_TEMP_CODE_1   VARCHAR2(500);
      V_ldap_password VARCHAR2(100);

   BEGIN

      OPEN c_sero_id;
      FETCH c_sero_id INTO l_sero_id, l_sero_revision;
      IF c_sero_id%NOTFOUND THEN
        CLOSE c_sero_id;
        RETURN l_sord_value;
      END IF;
      CLOSE c_sero_id;

      OPEN C_ORDT_TYPE (l_sero_id);
      FETCH C_ORDT_TYPE     INTO V_SERO_ORDT_TYPE;
      CLOSE C_ORDT_TYPE;

     IF V_SERO_ORDT_TYPE ='MODIFY-USERNAME' THEN  ----- For MODIFY-USERNAME Order Type ----

      OPEN c_seit_id_N(l_sero_id, l_sero_revision);
      FETCH c_seit_id_N INTO l_seit_id;
      IF c_seit_id_N%NOTFOUND THEN
        CLOSE c_seit_id_N;
        RETURN l_sord_value;
      END IF;
      CLOSE c_seit_id_N;

      OPEN c_sord_value_N(l_seit_id);
      FETCH c_sord_value_N INTO l_sord_value;
      IF c_sord_value_N%NOTFOUND THEN
        CLOSE c_sord_value_N;
        RETURN l_sord_value;
      END IF;
      CLOSE c_sord_value_N;

      V_TEMP_CODE:=TRIM(SUBSTR(l_sord_value,INSTR(l_sord_value,'{SSHA}'),(INSTR(l_sord_value,'1 matches')-INSTR(l_sord_value,'{SSHA}'))-1));

      IF V_TEMP_CODE IS NOT NULL THEN

        V_ldap_password:=V_TEMP_CODE;

      ELSE

        V_ldap_password:=NULL;

      END IF;

     ELSE   --- For Other Ordr Types --

      OPEN c_seit_id(l_sero_id, l_sero_revision);
      FETCH c_seit_id INTO l_seit_id;
      IF c_seit_id%NOTFOUND THEN
        CLOSE c_seit_id;
        RETURN l_sord_value;
      END IF;
      CLOSE c_seit_id;

      OPEN c_sord_value(l_seit_id);
      FETCH c_sord_value INTO l_sord_value;
      IF c_sord_value%NOTFOUND THEN
        CLOSE c_sord_value;
        RETURN l_sord_value;
      END IF;
      CLOSE c_sord_value;

      V_TEMP_CODE_1:=TRIM(SUBSTR(l_sord_value,INSTR(l_sord_value,'{SSHA}'),(INSTR(l_sord_value,'1 matches')-INSTR(l_sord_value,'{SSHA}'))-1));

      IF V_TEMP_CODE_1 IS NOT NULL THEN

        V_ldap_password:=V_TEMP_CODE_1;

      ELSE

        V_ldap_password:=NULL;

      END IF;

     END IF;


    RETURN V_ldap_password;

   END get_ldap_password;

---- Modified Dinesh 15-08-2013 ----
---- Modified Dinesh 24-02-2015 ----
---------------- Gihan 2012 12 17  ----------------------------------------------------

---------------- Gihan 2013 06 26 -----------------------------------------------------
  FUNCTION get_dslam_pvcid (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS
      CURSOR c_dslam_fn
      IS
         SELECT podi_value
           FROM service_implementation_tasks,
                service_orders,
                circuits,
                port_links,
                port_link_ports,
                ports,
                port_detail_instance
          WHERE seit_id = pi_seit_id
            AND sero_id = seit_sero_id
            AND cirt_name = sero_cirt_name
            AND porl_cirt_name = cirt_name
            AND polp_porl_id = porl_id
            AND port_id = polp_port_id
            AND podi_port_id = port_id
            AND podi_name = 'PA_DSLAM_FN';

      CURSOR c_dslam_sn
      IS
         SELECT podi_value
           FROM service_implementation_tasks,
                service_orders,
                circuits,
                port_links,
                port_link_ports,
                ports,
                port_detail_instance
          WHERE seit_id = pi_seit_id
            AND sero_id = seit_sero_id
            AND cirt_name = sero_cirt_name
            AND porl_cirt_name = cirt_name
            AND polp_porl_id = porl_id
            AND port_id = polp_port_id
            AND podi_port_id = port_id
            AND podi_name = 'PA_DSLAM_SN';

      CURSOR c_dslam_pn
      IS
         SELECT podi_value
           FROM service_implementation_tasks,
                service_orders,
                circuits,
                port_links,
                port_link_ports,
                ports,
                port_detail_instance
          WHERE seit_id = pi_seit_id
            AND sero_id = seit_sero_id
            AND cirt_name = sero_cirt_name
            AND porl_cirt_name = cirt_name
            AND polp_porl_id = porl_id
            AND port_id = polp_port_id
            AND podi_port_id = port_id
            AND podi_name = 'PA_DSLAM_PN';

      -- E. Son 10-20-2008 start
      CURSOR c_pvc_query
      IS
         SELECT SUBSTR (sord_value, INSTR (sord_value, 'ADSL-LAN'))
           FROM service_implementation_tasks, sop_queue, sop_reply_data
          WHERE seit_id = pi_seit_id - 1
            AND sopq_seit_id = seit_id
            AND sopq_sopc_command LIKE 'LST-PVC%'
        AND sord_name = 'RAW_MESSAGES' --C12Gihan
            AND sord_sopq_requestid = sopq_requestid;

      CURSOR c_command
      IS
         SELECT sopc_command
           FROM sop_commands
          WHERE sopc_id = pi_sopc_id;

      l_command              sop_commands.sopc_command%TYPE;
      l_pvc_query            VARCHAR2 (4000);
      l_pvcid_value          VARCHAR2 (500);
      l_pvcresid_end_index   NUMBER;
      l_pvcid_begin_index    NUMBER;
      l_pvcid_end_index      NUMBER;
      -- E. Son 10-20-2008 end
      l_dslam_fn             NUMBER;
      l_dslam_sn             NUMBER;
      l_dslam_pn             NUMBER;
   BEGIN
      OPEN c_dslam_fn;

      FETCH c_dslam_fn
       INTO l_dslam_fn;

      CLOSE c_dslam_fn;

      OPEN c_dslam_sn;

      FETCH c_dslam_sn
       INTO l_dslam_sn;

      CLOSE c_dslam_sn;

      OPEN c_dslam_pn;

      FETCH c_dslam_pn
       INTO l_dslam_pn;

      CLOSE c_dslam_pn;

      -- E. Son 10-20-2008 start
      OPEN c_pvc_query;

      FETCH c_pvc_query
       INTO l_pvc_query;

      CLOSE c_pvc_query;

      OPEN c_command;

      FETCH c_command
       INTO l_command;

      CLOSE c_command;

      -- E. Son 10-20-2008 end

      -- E. Son 10-20-2008 start
      IF l_command LIKE 'DEL-PVC%'
      THEN
         FOR nindex IN 10 .. LENGTH (l_pvc_query)
         LOOP                                          -- start from index 10
            IF (    (ASCII (SUBSTR (l_pvc_query, nindex, 1)) >= 48)
                AND (ASCII (SUBSTR (l_pvc_query, nindex, 1)) <= 57)
               )
            THEN
               l_pvcresid_end_index := nindex;
            ELSE
               IF (l_pvcresid_end_index > 0)
               THEN
                  EXIT;
               END IF;
            END IF;
         END LOOP;

         l_pvcid_begin_index := l_pvcresid_end_index + 2;

         FOR nindex IN l_pvcid_begin_index .. LENGTH (l_pvc_query)
         LOOP
            IF    (    (ASCII (SUBSTR (l_pvc_query, nindex, 1)) >= 48)
                   AND                                                -- [0-9]
                       (ASCII (SUBSTR (l_pvc_query, nindex, 1)) <= 57
                       )
                  )
               OR (    (ASCII (SUBSTR (l_pvc_query, nindex, 1)) >= 65)
                   AND                                                -- [A-Z]
                       (ASCII (SUBSTR (l_pvc_query, nindex, 1)) <= 90
                       )
                  )
               OR (    (ASCII (SUBSTR (l_pvc_query, nindex, 1)) >= 97)
                   AND                                                -- [a-z]
                       (ASCII (SUBSTR (l_pvc_query, nindex, 1)) <= 122
                       )
                  )
               OR (ASCII (SUBSTR (l_pvc_query, nindex, 1)) = 95)
               OR                                                       -- [_]
                  (ASCII (SUBSTR (l_pvc_query, nindex, 1)) = 47
                  )
               OR                                                       -- [/]
                  (ASCII (SUBSTR (l_pvc_query, nindex, 1)) = 45
                  )
            THEN                                                        -- [-]
               --IF NOT (l_pvcid_begin_index>0) THEN
               --   l_pvcid_begin_index := nIndex;
               --END IF;
               l_pvcid_end_index := nindex;
            ELSE
               IF (l_pvcid_end_index > 0)
               THEN
                  EXIT;
               END IF;
            END IF;
         END LOOP;

         --RETURN ('l_pvc_query:' || SUBSTR(l_pvc_query,10,20) || ' l_pvcid_begin_index:' || l_pvcid_begin_index || ' l_pvcid_end_index:' || l_pvcid_end_index);
         l_pvcid_value :=
            SUBSTR (l_pvc_query,
                    l_pvcid_begin_index,
                    l_pvcid_end_index - l_pvcid_begin_index + 1
                   );
         RETURN l_pvcid_value;
      ELSE                                                   -- CRT-ADSLLANPVC
         -- E. Son 10-20-2008 end
         RETURN (   'adsl2lan/'
                 || l_dslam_fn
                 || '_'
                 || l_dslam_sn
                 || '_'
                 || l_dslam_pn
                 || '/8/35'
                );
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END get_dslam_pvcid;

---------------- Gihan 2013 06 26 ---------------


---------------- Dinesh 2013 08 13 ---------------
FUNCTION GET_PRV_ATTR_ADSL_CIRCUIT_ID (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


      CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_PRV_ATTR_VAL (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE,T_ST_NAME SERVICE_ORDER_ATTRIBUTES.SEOA_NAME%TYPE) IS

            SELECT  MAX(SEOA_PREV_VALUE)
            FROM    SERVICE_ORDER_ATTRIBUTES
            WHERE   SEOA_SERO_ID=T_SERO_ID
            AND     SEOA_NAME=T_ST_NAME;



      V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
      V_ATTR_NAME          SERVICE_ORDER_ATTRIBUTES.SEOA_NAME%TYPE;
      V_SEOA_PREV_VALUE   SERVICE_ORDER_ATTRIBUTES.SEOA_PREV_VALUE%TYPE;
      V_PRV_ATTR_VAL      SERVICE_ORDER_ATTRIBUTES.SEOA_PREV_VALUE%TYPE;


   BEGIN

      OPEN C_SERO_ID;       FETCH C_SERO_ID
       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;

      V_ATTR_NAME    :='ADSL_CIRCUIT_ID';

      OPEN C_PRV_ATTR_VAL (V_SEIT_SERO_ID,V_ATTR_NAME);
      FETCH C_PRV_ATTR_VAL INTO V_SEOA_PREV_VALUE;
      CLOSE C_PRV_ATTR_VAL;

      IF V_SEOA_PREV_VALUE IS NOT NULL THEN


        V_PRV_ATTR_VAL:=V_SEOA_PREV_VALUE;

      ELSE

        V_PRV_ATTR_VAL:=NULL;

      END IF;


    RETURN V_PRV_ATTR_VAL;

   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END GET_PRV_ATTR_ADSL_CIRCUIT_ID;
---------------- Dinesh 2013 08 13 ---------------

---- Janaka 2013 05 17 --------------------------------------------------

FUNCTION GET_MIN (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


    CURSOR C_MIN_NUMBER       IS

    SELECT DISTINCT(SEOA_DEFAULTVALUE)
    FROM    SERVICE_IMPLEMENTATION_TASKS SI, SERVICE_ORDER_ATTRIBUTES SA
    WHERE   SI.SEIT_SERO_ID = SA.SEOA_SERO_ID
    AND     SEOA_NAME = 'SA_CDMA_NUMBER'
    AND     SEIT_ID = PI_SEIT_ID;



      L_NUMBER         SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;
      L_MIN_NUMBER        VARCHAR2(10);


   BEGIN

      OPEN C_MIN_NUMBER;

      FETCH C_MIN_NUMBER
       INTO L_NUMBER;

      CLOSE C_MIN_NUMBER;

      IF L_NUMBER IS NOT NULL THEN

        L_MIN_NUMBER:=L_NUMBER;

      END IF;

     RETURN L_MIN_NUMBER;
      --dbms_output.put_line('-- Return Value : '||l_NUCC_CODE);

   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END GET_MIN;

---- Janaka 2013 05 17 --------------------------------------------------

FUNCTION GET_NEWMIN (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


    CURSOR C_NEWMIN_NUMBER       IS

    SELECT  NUMB_NUCC_CODE,NUMB_NUMBER
    FROM    SERVICE_IMPLEMENTATION_TASKS SI, SERVICE_ORDERS SO,NUMBERS NU
    WHERE   SI.SEIT_SERO_ID=SO.SERO_ID
    AND     NU.NUMB_SERV_ID=SERO_SERV_ID
    AND     NUMB_NUMS_ID IN (3,6)
    AND     SEIT_ID = PI_SEIT_ID;



      L_NUCC_CODE         NUMBERS.NUMB_NUCC_CODE%TYPE;
      L_NUMB_NUMBER       NUMBERS.NUMB_NUMBER%TYPE;
      L_NEWMIN_NUMBER        VARCHAR2(10);


   BEGIN

      OPEN C_NEWMIN_NUMBER;

      FETCH C_NEWMIN_NUMBER
       INTO L_NUCC_CODE,L_NUMB_NUMBER;

      CLOSE C_NEWMIN_NUMBER;

      IF L_NUCC_CODE IS NOT NULL AND L_NUMB_NUMBER IS NOT NULL THEN

        L_NEWMIN_NUMBER:=L_NUCC_CODE||L_NUMB_NUMBER;

      END IF;

      RETURN L_NEWMIN_NUMBER;
      --dbms_output.put_line('-- Return Value : '||L_NEWMIN_NUMBER);

   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END GET_NEWMIN;

---- Janaka 2013 05 17 --------------------------------------------------
---- Edited Dinesh 05-09-2013 ---------------

FUNCTION GET_MDN (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


    CURSOR C_MDN_NUMBER       IS

    SELECT  NUMB_NUCC_CODE,NUMB_NUMBER,NUMB_COUNTRY_NUCC_CODE
    FROM    SERVICE_IMPLEMENTATION_TASKS SI, SERVICE_ORDERS SO,NUMBERS NU
    WHERE   SI.SEIT_SERO_ID=SO.SERO_ID
    AND     NU.NUMB_SERV_ID=SERO_SERV_ID
    AND     NUMB_NUMS_ID IN (3,4,6)
    AND     SEIT_ID = PI_SEIT_ID;



      L_NUCC_CODE               NUMBERS.NUMB_NUCC_CODE%TYPE;
      L_COUNTRY_NUCC_CODE       NUMBERS.NUMB_COUNTRY_NUCC_CODE%TYPE;
      L_NUMB_NUMBER             NUMBERS.NUMB_NUMBER%TYPE;
      L_MDN_NUMBER              VARCHAR2(13);


   BEGIN

      OPEN C_MDN_NUMBER;

      FETCH C_MDN_NUMBER
       INTO L_NUCC_CODE,L_NUMB_NUMBER,L_COUNTRY_NUCC_CODE;

      CLOSE C_MDN_NUMBER;

      IF L_NUCC_CODE IS NOT NULL AND L_NUMB_NUMBER IS NOT NULL THEN

        L_MDN_NUMBER:=L_COUNTRY_NUCC_CODE||SUBSTR(L_NUCC_CODE,-2)||L_NUMB_NUMBER;

      END IF;

      RETURN L_MDN_NUMBER;
      --dbms_output.put_line('-- Return Value : '||l_NUCC_CODE);

   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END GET_MDN;

---- Janaka 2013 05 17 --------------------------------------------------

FUNCTION GET_NEWMDN (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


    CURSOR C_NEWMDN_NUMBER       IS

    SELECT  NUMB_NUCC_CODE,NUMB_NUMBER,NUMB_COUNTRY_NUCC_CODE
    FROM    SERVICE_IMPLEMENTATION_TASKS SI, SERVICE_ORDERS SO,NUMBERS NU
    WHERE   SI.SEIT_SERO_ID=SO.SERO_ID
    AND     NU.NUMB_SERV_ID=SERO_SERV_ID
    AND     NUMB_NUMS_ID IN (3,6)
    AND     SEIT_ID = PI_SEIT_ID;



      L_NUCC_CODE               NUMBERS.NUMB_NUCC_CODE%TYPE;
      L_COUNTRY_NUCC_CODE       NUMBERS.NUMB_COUNTRY_NUCC_CODE%TYPE;
      L_NUMB_NUMBER             NUMBERS.NUMB_NUMBER%TYPE;
      L_NEWMDN_NUMBER              VARCHAR2(13);


   BEGIN

      OPEN C_NEWMDN_NUMBER;

      FETCH C_NEWMDN_NUMBER
       INTO L_NUCC_CODE,L_NUMB_NUMBER,L_COUNTRY_NUCC_CODE;

      CLOSE C_NEWMDN_NUMBER;

      IF L_NUCC_CODE IS NOT NULL AND L_NUMB_NUMBER IS NOT NULL THEN

        L_NEWMDN_NUMBER:=L_COUNTRY_NUCC_CODE||SUBSTR(L_NUCC_CODE,-2)||L_NUMB_NUMBER;

      END IF;

      RETURN L_NEWMDN_NUMBER;
      --dbms_output.put_line('-- Return Value : '||l_NUCC_CODE);

   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END GET_NEWMDN;

---- Janaka 2013 05 17 --------------------------------------------------


---- Janaka 2013 05 22 --------------------------------------------------
FUNCTION GET_OLDMIN (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


    CURSOR C_MIN_NUMBER       IS

    SELECT  NUMB_NUCC_CODE,NUMB_NUMBER
    FROM    SERVICE_IMPLEMENTATION_TASKS SI, SERVICE_ORDERS SO,NUMBERS NU
    WHERE   SI.SEIT_SERO_ID=SO.SERO_ID
    AND     NU.NUMB_SERV_ID=SERO_SERV_ID
    AND     NUMB_NUMS_ID IN (4)
    AND     SEIT_ID = PI_SEIT_ID;



      L_NUCC_CODE         NUMBERS.NUMB_NUCC_CODE%TYPE;
      L_NUMB_NUMBER       NUMBERS.NUMB_NUMBER%TYPE;
      L_OLDMIN_NUMBER        VARCHAR2(10);


   BEGIN

      OPEN C_MIN_NUMBER;

      FETCH C_MIN_NUMBER
       INTO L_NUCC_CODE,L_NUMB_NUMBER;

      CLOSE C_MIN_NUMBER;

      IF L_NUCC_CODE IS NOT NULL AND L_NUMB_NUMBER IS NOT NULL THEN

        L_OLDMIN_NUMBER:=L_NUCC_CODE||L_NUMB_NUMBER;

      END IF;

      RETURN L_OLDMIN_NUMBER;
      --dbms_output.put_line('-- Return Value : '||l_NUCC_CODE);

   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END GET_OLDMIN;


---- Janaka 2013 05 22 --------------------------------------------------


---- Janaka 2013 05 22 --------------------------------------------------
FUNCTION GET_OLDMDN (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


    CURSOR C_MDN_NUMBER       IS

    SELECT  NUMB_NUCC_CODE,NUMB_NUMBER,NUMB_COUNTRY_NUCC_CODE
    FROM    SERVICE_IMPLEMENTATION_TASKS SI, SERVICE_ORDERS SO,NUMBERS NU
    WHERE   SI.SEIT_SERO_ID=SO.SERO_ID
    AND     NU.NUMB_SERV_ID=SERO_SERV_ID
    AND     NUMB_NUMS_ID IN (4)
    AND     SEIT_ID = PI_SEIT_ID;



      L_NUCC_CODE               NUMBERS.NUMB_NUCC_CODE%TYPE;
      L_COUNTRY_NUCC_CODE       NUMBERS.NUMB_COUNTRY_NUCC_CODE%TYPE;
      L_NUMB_NUMBER             NUMBERS.NUMB_NUMBER%TYPE;
      L_OLDMDN_NUMBER              VARCHAR2(13);


   BEGIN

      OPEN C_MDN_NUMBER;

      FETCH C_MDN_NUMBER
       INTO L_NUCC_CODE,L_NUMB_NUMBER,L_COUNTRY_NUCC_CODE;

      CLOSE C_MDN_NUMBER;

      IF L_NUCC_CODE IS NOT NULL AND L_NUMB_NUMBER IS NOT NULL THEN

        L_OLDMDN_NUMBER:=L_COUNTRY_NUCC_CODE||SUBSTR(L_NUCC_CODE,-2)||L_NUMB_NUMBER;

      END IF;

      RETURN L_OLDMDN_NUMBER;
      --dbms_output.put_line('-- Return Value : '||l_NUCC_CODE);

   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END GET_OLDMDN;

---- Janaka 2013 05 22 --------------------------------------------------

---- Janaka 2013 06 11 ****HLR****

 FUNCTION GET_ACTIV_VAL (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


      CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_ATTR_VAL (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE,T_ST_NAME SERVICE_ORDER_ATTRIBUTES.SEOA_NAME%TYPE) IS

            SELECT MAX(SEOA_DEFAULTVALUE)
            FROM SERVICE_ORDER_ATTRIBUTES
            WHERE SEOA_SERO_ID=T_SERO_ID
            AND SEOA_NAME=T_ST_NAME;

      CURSOR C_COMAND_ID IS

            SELECT  SOPC_COMMAND
            FROM    sop_commands
            WHERE   SOPC_ID = pi_sopc_id;

      CURSOR C_GET_FEATURES (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE,T_FEATURE_NAME SERVICE_ORDER_FEATURES.SOFE_FEATURE_NAME%TYPE) IS

            SELECT  SOFE_FEATURE_NAME,NVL(SOFE_DEFAULTVALUE,'N') SOFE_DEFAULTVALUE ,NVL(SOFE_PREV_VALUE,'N') SOFE_PREV_VALUE
            FROM    SERVICE_ORDER_FEATURES
            WHERE   SOFE_SERO_ID=T_SERO_ID
            AND     SOFE_FEATURE_NAME =T_FEATURE_NAME
            ORDER BY SOFE_FEATURE_NAME;



        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_ATTR_VAL          SERVICE_ORDER_ATTRIBUTES.SEOA_NAME%TYPE;
        V_SOPC_COMMAND      sop_commands.SOPC_COMMAND%TYPE;
        V_FEATURE_NAME      SERVICE_ORDER_FEATURES.SOFE_FEATURE_NAME%TYPE;
        V_ST_NAME           SERVICE_ORDER_ATTRIBUTES.SEOA_NAME%TYPE;



      L_TEMP_CODE               VARCHAR2(100);
      L_FET_NUMBER              VARCHAR2(20);
      L_ACTIV_VAL               VARCHAR2(2);
      L_CF_NAME                  VARCHAR2(100);
      L_CF_FETURE_CUR         VARCHAR2(1);
      L_CF_FETURE_PRV         VARCHAR2(1);


   BEGIN

      OPEN C_SERO_ID;       FETCH C_SERO_ID
       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;

      OPEN C_COMAND_ID;       FETCH C_COMAND_ID
       INTO V_SOPC_COMMAND;
      CLOSE C_COMAND_ID;


      IF V_SOPC_COMMAND='ZTE_CDMA_MOD_CUSER_ACT_CFIMD' OR V_SOPC_COMMAND='ZTE_CDMA_MOD_CUSER_DEACT_CFIMD' THEN

        V_FEATURE_NAME:='SF_CF_IMMEDIATE';
        V_ST_NAME:=V_FEATURE_NAME||'.NUMBER';

      ELSIF V_SOPC_COMMAND='ZTE_CDMA_MOD_CUSER_ACT_CFNOA' OR V_SOPC_COMMAND='ZTE_CDMA_MOD_CUSER_DEACT_CFNOA' THEN

        V_FEATURE_NAME:='SF_CF_NO_ANSWER';
        V_ST_NAME:=V_FEATURE_NAME||'.NUMBER';

      ELSIF V_SOPC_COMMAND='ZTE_CDMA_MOD_CUSER_ACT_CFOFFLINE' OR V_SOPC_COMMAND='ZTE_CDMA_MOD_CUSER_DEACT_CFOFFLINE' THEN

        V_FEATURE_NAME:='SF_CF_OFFLINE';
        V_ST_NAME:=V_FEATURE_NAME||'.NUMBER';

      ELSIF V_SOPC_COMMAND='ZTE_CDMA_MOD_CUSER_ACT_CFBUSY' OR V_SOPC_COMMAND='ZTE_CDMA_MOD_CUSER_DEACT_CFBUSY' THEN

        V_FEATURE_NAME:='SF_CF_ON_BUSY';
        V_ST_NAME:=V_FEATURE_NAME||'.NUMBER';

      END IF;

      OPEN C_GET_FEATURES (V_SEIT_SERO_ID,V_FEATURE_NAME);
      FETCH C_GET_FEATURES     INTO L_CF_NAME,L_CF_FETURE_CUR,L_CF_FETURE_PRV;
      CLOSE C_GET_FEATURES;




    IF L_CF_FETURE_CUR ='Y' THEN

              OPEN C_ATTR_VAL (V_SEIT_SERO_ID,V_ST_NAME);
              FETCH C_ATTR_VAL     INTO L_FET_NUMBER;
              CLOSE C_ATTR_VAL;

              IF L_FET_NUMBER IS NOT NULL THEN

              L_ACTIV_VAL:='1';

              ELSE

              L_ACTIV_VAL:='0';

              END IF;

    ELSIF L_CF_FETURE_CUR ='N' THEN

    L_ACTIV_VAL:='0';

    ELSE

    L_ACTIV_VAL:=NULL;

    END IF;





    RETURN L_ACTIV_VAL;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_ACTIV_VAL;



 FUNCTION GET_BAROUT_IDD (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


      CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_ORDT_TYPE (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT DISTINCT(SERO_ORDT_TYPE)
            FROM SERVICE_ORDERS
            WHERE SERO_ID=T_SERO_ID;

      CURSOR C_GET_FEATURES IS

            SELECT  SOFE_FEATURE_NAME,NVL(SOFE_DEFAULTVALUE,'N') SOFE_DEFAULTVALUE ,NVL(SOFE_PREV_VALUE,'N') SOFE_PREV_VALUE
            FROM    SERVICE_ORDER_FEATURES,SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID
            AND     SOFE_SERO_ID=SEIT_SERO_ID
            AND     SOFE_FEATURE_NAME IN ('SF_BAR_OUTGOING_CALL','SF_IDD')
            ORDER BY SOFE_FEATURE_NAME;



        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_SERO_ORDT_TYPE    SERVICE_ORDERS.SERO_SERV_ID%TYPE;



      L_TEMP_CODE           VARCHAR2(100);
      L_BARIDD              VARCHAR2(2);
      L_BAR_OUT_CALL            VARCHAR2(100);
      L_BAR_OUT_CALL_CUR        VARCHAR2(1);
      L_BAR_OUT_CALL_PRV        VARCHAR2(1);
      L_IDD                     VARCHAR2(100);
      L_IDD_CUR                 VARCHAR2(1);
      L_IDD_PRV                 VARCHAR2(1);



   BEGIN

      OPEN C_SERO_ID;       FETCH C_SERO_ID
       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;

      OPEN C_ORDT_TYPE (V_SEIT_SERO_ID);
      FETCH C_ORDT_TYPE     INTO V_SERO_ORDT_TYPE;
      CLOSE C_ORDT_TYPE;


       FOR REC_FEATURE IN C_GET_FEATURES LOOP





        BEGIN

            IF REC_FEATURE.SOFE_FEATURE_NAME ='SF_IDD' THEN

                L_IDD:=REC_FEATURE.SOFE_FEATURE_NAME;
                L_IDD_CUR:=REC_FEATURE.SOFE_DEFAULTVALUE;
                L_IDD_PRV:=REC_FEATURE.SOFE_PREV_VALUE;



            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_BAR_OUTGOING_CALL' THEN

                L_BAR_OUT_CALL:=REC_FEATURE.SOFE_FEATURE_NAME;
                L_BAR_OUT_CALL_CUR:=REC_FEATURE.SOFE_DEFAULTVALUE;
                L_BAR_OUT_CALL_PRV:=REC_FEATURE.SOFE_PREV_VALUE;

            END IF;

        END;


       END LOOP;




        IF   L_BAR_OUT_CALL_CUR='Y' AND L_BAR_OUT_CALL_PRV='N' THEN --'SF_BAR_INCOMING_CALL'

            L_BARIDD:=2;

        ELSIF L_BAR_OUT_CALL_CUR='N' AND L_BAR_OUT_CALL_PRV='Y' THEN --'SF_BAR_OUTGOING_CALL'

            IF L_IDD_CUR='Y' THEN

             L_BARIDD:=7;

            ELSE

             L_BARIDD:=6;

            END IF;


        ELSE

        L_BARIDD:=NULL;

        END IF;





    RETURN L_BARIDD;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_BAROUT_IDD;
---- Janaka 2013 06 11 ****HLR****

---- Janaka 2013 06 26 ****IN****

 FUNCTION GET_IN_ACCOUNT (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_GET_ATTR_SP (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT  MAX(SEOA_DEFAULTVALUE)
            FROM    SERVICE_ORDER_ATTRIBUTES
            WHERE   SEOA_SERO_ID=T_SERO_ID
            AND     SEOA_NAME IN ('SA_PRE-PAID');

      CURSOR C_GET_ATTR_SR (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT  MAX(SEOA_DEFAULTVALUE)
            FROM    SERVICE_ORDER_ATTRIBUTES
            WHERE   SEOA_SERO_ID=T_SERO_ID
            AND     SEOA_NAME IN ('SPECIAL RELOAD');


        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_ATTR_SP           SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;
        V_ATTR_SR           SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;

      L_IN_ACC      VARCHAR2(20);



   BEGIN

      OPEN C_SERO_ID;       FETCH C_SERO_ID
       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;

      OPEN C_GET_ATTR_SP (V_SEIT_SERO_ID);
      FETCH C_GET_ATTR_SP     INTO V_ATTR_SP;
      CLOSE C_GET_ATTR_SP;

      OPEN C_GET_ATTR_SR (V_SEIT_SERO_ID);
      FETCH C_GET_ATTR_SR     INTO V_ATTR_SR;
      CLOSE C_GET_ATTR_SR;


      IF V_ATTR_SP='Y[PerMin]' AND V_ATTR_SR IS NULL THEN

       L_IN_ACC := '10000';

      ELSIF  V_ATTR_SP='Y[PerMin]' AND V_ATTR_SR ='TRUE' THEN

       L_IN_ACC := '25000';

      ELSIF  V_ATTR_SP='Y[PerMin]' AND V_ATTR_SR ='FALSE' THEN

       L_IN_ACC := '10000';

      ELSE

       L_IN_ACC:= NULL;

      END IF;

    RETURN L_IN_ACC;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_IN_ACCOUNT;



 FUNCTION GET_IN_FUNCT (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_GET_ATTR_SP (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT  MAX(SEOA_DEFAULTVALUE)
            FROM    SERVICE_ORDER_ATTRIBUTES
            WHERE   SEOA_SERO_ID=T_SERO_ID
            AND     SEOA_NAME IN ('SA_PRE-PAID');


      CURSOR C_GET_FEATURES (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT  SOFE_FEATURE_NAME,NVL(SOFE_DEFAULTVALUE,'N') SOFE_DEFAULTVALUE ,NVL(SOFE_PREV_VALUE,'N') SOFE_PREV_VALUE
            FROM    SERVICE_ORDER_FEATURES
            WHERE   SOFE_SERO_ID=T_SERO_ID
            AND     SOFE_FEATURE_NAME IN ('SF_CRBT')
            ORDER BY SOFE_FEATURE_NAME;


        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_ATTR_SP           SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;
        V_ATTR_SR           SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;

      L_CRBT             VARCHAR2(100);
      L_CRBT_CUR         VARCHAR2(1);
      L_CRBT_PRV         VARCHAR2(1);

      L_IN_FUNCT      VARCHAR2(20);



   BEGIN

      OPEN C_SERO_ID;       FETCH C_SERO_ID
       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;

      OPEN C_GET_ATTR_SP (V_SEIT_SERO_ID);
      FETCH C_GET_ATTR_SP     INTO V_ATTR_SP;
      CLOSE C_GET_ATTR_SP;

      OPEN C_GET_FEATURES (V_SEIT_SERO_ID);
      FETCH C_GET_FEATURES     INTO L_CRBT,L_CRBT_CUR,L_CRBT_PRV;
      CLOSE C_GET_FEATURES;


      IF L_CRBT_CUR='N' AND V_ATTR_SP='Y_Reload' THEN

       L_IN_FUNCT := '205';

      ELSIF  L_CRBT_CUR='Y' THEN

        IF V_ATTR_SP !='Y_Reload' THEN

            L_IN_FUNCT := '23';

        ELSIF V_ATTR_SP IS NULL THEN

            L_IN_FUNCT := '23';

        ELSE

            L_IN_FUNCT := NULL;

        END IF;


      ELSE

       L_IN_FUNCT:= NULL;

      END IF;

    RETURN L_IN_FUNCT;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_IN_FUNCT;

---- Janaka 2013 06 26 ****IN****

----- Dinesh 2013 07 31 ---- CDMA CRBT NUMBER-----
FUNCTION GET_CRBT_NUM (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_CDMA_NUMBER (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT SEOA_DEFAULTVALUE
            FROM SERVICE_ORDER_ATTRIBUTES
            WHERE   SEOA_SERO_ID=T_SERO_ID
            AND     SEOA_NAME='SA_CDMA_NUMBER';


        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_CDMA_NUMBER       SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;

        L_CDMA_NUMB         VARCHAR2(20);



   BEGIN

      OPEN C_SERO_ID;       FETCH C_SERO_ID
       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;

      OPEN C_CDMA_NUMBER (V_SEIT_SERO_ID);
      FETCH C_CDMA_NUMBER     INTO V_CDMA_NUMBER;
      CLOSE C_CDMA_NUMBER;



      IF V_CDMA_NUMBER IS NOT NULL THEN

        L_CDMA_NUMB:=SUBSTR(V_CDMA_NUMBER,-9);

      ELSE

        L_CDMA_NUMB:=NULL;

      END IF;

    RETURN L_CDMA_NUMB;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_CRBT_NUM;

----- Dinesh 2013 07 31 ---- CDMA CRBT NUMBER-----

FUNCTION GET_ACTTYPE (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


      CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_ORDT_TYPE (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT DISTINCT(SERO_ORDT_TYPE)
            FROM SERVICE_ORDERS
            WHERE SERO_ID=T_SERO_ID;

      CURSOR C_GET_FEATURES IS

            SELECT  SOFE_FEATURE_NAME
            FROM    SERVICE_ORDER_FEATURES,SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID
            AND     SOFE_SERO_ID=SEIT_SERO_ID
            AND     NVL(SOFE_DEFAULTVALUE,'N')='Y'
            AND     NVL(SOFE_PREV_VALUE,'N') <> NVL(SOFE_DEFAULTVALUE,'N')
            ORDER BY SOFE_FEATURE_NAME;



        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_SERO_ORDT_TYPE    SERVICE_ORDERS.SERO_SERV_ID%TYPE;



      L_TEMP_CODE         VARCHAR2(500);
      L_ACTTYPE           VARCHAR2(500);
      L_ACTTYPE_VALUE     VARCHAR2(200);
      L_LENGTH            VARCHAR2(10);



    T_CREATE_TYPE                          VARCHAR2(20);
    T_ABBREVIATED_DIAL                     VARCHAR2(20);             --1
    T_ABSENTEE_SERVICE                     VARCHAR2(20);              --2
    T_ANONYMOUS_CALL_BARRING               VARCHAR2(20);              --3
    T_CALL_BACK_ON_BUSY                    VARCHAR2(20);             --4
    T_CALL_CONFERENCE                      VARCHAR2(20);               --5
    T_CALL_FORWARDING_BY_TIME              VARCHAR2(20);               --6
    T_CALL_FORWARDING_OFFLINE              VARCHAR2(20);              --7
    T_CALL_HOLDING                         VARCHAR2(20);             --8
    T_CALL_TRANSFER_THREE_WAY              VARCHAR2(20);              --9
    T_CALL_WAITING                         VARCHAR2(20);               --10
    T_CF_IMMEDIATE                         VARCHAR2(20);               --11
    T_CF_NO_ANSWER                         VARCHAR2(20);               --12
    T_CF_OFFLINE                           VARCHAR2(20);              --13
    T_CF_ON_BUSY                           VARCHAR2(20);              --14
    T_CF_SELECTIVE                         VARCHAR2(20);             --15
    T_CLI                                  VARCHAR2(20);               --16
    T_CLI_PRE_IN_CALL_WAITING              VARCHAR2(20);     --17
    T_DO_NOT_DISTURB_SERVICE               VARCHAR2(20);              --18
    T_HOTLINE_IMMEDIATE                    VARCHAR2(20);              --19
    T_HOTLINE_TIMEDELAY                    VARCHAR2(20);              --20
    T_INCOMING_CALL_MEMORY                 VARCHAR2(20);             --21
    T_INCOMING_CALL_TRANSFER               VARCHAR2(20);              --22
    T_MCT                                  VARCHAR2(20);               --23
    T_MCT_ALL_INCOMING                     VARCHAR2(20);              --24
    T_OUTGOING_CALL_MEMORY                 VARCHAR2(20);              --25
    T_PASSWORD_CALL_BARRING                VARCHAR2(20);   --26
    T_SECRETARY_SERVICE                    VARCHAR2(20);              --27
    T_SELECTIVE_CALL_ACCEPTANCE            VARCHAR2(20);              --28
    T_SELECTIVE_CALL_REJECTION             VARCHAR2(20);             --29



   BEGIN

      OPEN C_SERO_ID;       FETCH C_SERO_ID
       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;

      OPEN C_ORDT_TYPE (V_SEIT_SERO_ID);
      FETCH C_ORDT_TYPE     INTO V_SERO_ORDT_TYPE;
      CLOSE C_ORDT_TYPE;

             T_CREATE_TYPE                          :='"18"';

       FOR REC_FEATURE IN C_GET_FEATURES LOOP


            T_ABBREVIATED_DIAL                     :='"12"';              --1
            T_ABSENTEE_SERVICE                     :='"21"';              --2
            T_ANONYMOUS_CALL_BARRING               :='"78"';              --3
            T_CALL_BACK_ON_BUSY                    :='"20"';              --4
            T_CALL_CONFERENCE                      :='"4"';               --5
            T_CALL_FORWARDING_BY_TIME              :='"0"';               --6
            T_CALL_FORWARDING_OFFLINE              :='"61"';              --7
            T_CALL_HOLDING                         :='"117"';             --8
            T_CALL_TRANSFER_THREE_WAY              :='"50"';              --9
            T_CALL_WAITING                         :='"6"';               --10
            T_CF_IMMEDIATE                         :='"0"';               --11
            T_CF_NO_ANSWER                         :='"2"';               --12
            T_CF_OFFLINE                           :='"61"';              --13
            T_CF_ON_BUSY                           :='"1"';               --14
            T_CF_SELECTIVE                         :='"102"';             --15
            T_CLI                                  :='"7"';               --16
            T_CLI_PRE_IN_CALL_WAITING              :='"6"'||'&'||'"7"';     --17
            T_DO_NOT_DISTURB_SERVICE               :='"17"';              --18
            T_HOTLINE_IMMEDIATE                    :='"13"';              --19
            T_HOTLINE_TIMEDELAY                    :='"14"';              --20
            T_INCOMING_CALL_MEMORY                 :='"96"';              --21
            T_INCOMING_CALL_TRANSFER               :='"50"';              --22
            T_MCT                                  :='"5"';               --23
            T_MCT_ALL_INCOMING                     :='"40\"';              --24
            T_OUTGOING_CALL_MEMORY                 :='"79"';              --25
            T_PASSWORD_CALL_BARRING                :='"15"'||'&'||'"42"';   --26
            T_SECRETARY_SERVICE                    :='"53"';              --27
            T_SELECTIVE_CALL_ACCEPTANCE            :='"45"';              --28
            T_SELECTIVE_CALL_REJECTION             :='"46"';              --29




        BEGIN

            IF REC_FEATURE.SOFE_FEATURE_NAME ='SF_ABBREVIATED_DIAL' THEN            --1

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_ABBREVIATED_DIAL;

                ELSE

                    L_TEMP_CODE:=T_ABBREVIATED_DIAL;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_ABSENTEE_SERVICE' THEN         --2

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_ABSENTEE_SERVICE;

                ELSE

                    L_TEMP_CODE:=T_ABSENTEE_SERVICE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_ANONYMOUS_CALL_BARRING' THEN   --3

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_ANONYMOUS_CALL_BARRING;

                ELSE

                    L_TEMP_CODE:=T_ANONYMOUS_CALL_BARRING;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CALL_BACK_ON_BUSY' THEN         --4

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CALL_BACK_ON_BUSY;

                ELSE

                    L_TEMP_CODE:=T_CALL_BACK_ON_BUSY;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CALL_CONFERENCE' THEN            --5

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CALL_CONFERENCE;

                ELSE

                    L_TEMP_CODE:=T_CALL_CONFERENCE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CF_BY_TIME' THEN      --6

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CALL_FORWARDING_BY_TIME;

                ELSE

                    L_TEMP_CODE:=T_CALL_FORWARDING_BY_TIME;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CF_OFFLINE' THEN      --7

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CALL_FORWARDING_OFFLINE;

                ELSE

                    L_TEMP_CODE:=T_CALL_FORWARDING_OFFLINE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CALL_HOLDING' THEN                 --8

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CALL_HOLDING;

                ELSE

                    L_TEMP_CODE:=T_CALL_HOLDING;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CALL_TRANSFER_THREE_WAY' THEN      --9

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CALL_TRANSFER_THREE_WAY;

                ELSE

                    L_TEMP_CODE:=T_CALL_TRANSFER_THREE_WAY;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CALL_WAITING' THEN                 --10

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CALL_WAITING;

                ELSE

                    L_TEMP_CODE:=T_CALL_WAITING;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CF_IMMEDIATE' THEN                 --11

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CF_IMMEDIATE;

                ELSE

                    L_TEMP_CODE:=T_CF_IMMEDIATE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CF_NO_ANSWER' THEN                 --12

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CF_NO_ANSWER;

                ELSE

                    L_TEMP_CODE:=T_CF_NO_ANSWER;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CF_OFFLINE' THEN                   --13

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CF_OFFLINE;

                ELSE

                    L_TEMP_CODE:=T_CF_OFFLINE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CF_ON_BUSY' THEN                   --14

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CF_ON_BUSY;

                ELSE

                    L_TEMP_CODE:=T_CF_ON_BUSY;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CF_SELECTIVE' THEN                 --15

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CF_SELECTIVE;

                ELSE

                    L_TEMP_CODE:=T_CF_SELECTIVE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CLI' THEN                          --16

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CLI;

                ELSE

                    L_TEMP_CODE:=T_CLI;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CLI_PRESENTATION_IN_CALL_WAITING' THEN   --17

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CLI_PRE_IN_CALL_WAITING;

                ELSE

                    L_TEMP_CODE:=T_CLI_PRE_IN_CALL_WAITING;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_DO_NOT_DISTURB_SERVICE' THEN         --18

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_DO_NOT_DISTURB_SERVICE;

                ELSE

                    L_TEMP_CODE:=T_DO_NOT_DISTURB_SERVICE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_HOTLINE_IMMEDIATE' THEN            --19

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_HOTLINE_IMMEDIATE;

                ELSE

                    L_TEMP_CODE:=T_HOTLINE_IMMEDIATE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_HOTLINE_TIMEDELAY' THEN         --20

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_HOTLINE_TIMEDELAY;

                ELSE

                    L_TEMP_CODE:=T_HOTLINE_TIMEDELAY;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_INCOMING_CALL_MEMORY' THEN     --21

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_INCOMING_CALL_MEMORY;

                ELSE

                    L_TEMP_CODE:=T_INCOMING_CALL_MEMORY;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_INCOMING_CALL_TRANSFER' THEN         --22

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_INCOMING_CALL_TRANSFER;

                ELSE

                    L_TEMP_CODE:=T_INCOMING_CALL_TRANSFER;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_MCT' THEN                            --23

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_MCT;

                ELSE

                    L_TEMP_CODE:=T_MCT;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_MCT_ALL_INCOMING' THEN         --24

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_MCT_ALL_INCOMING;

                ELSE

                    L_TEMP_CODE:=T_MCT_ALL_INCOMING;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_OUTGOING_CALL_MEMORY' THEN   --25

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_OUTGOING_CALL_MEMORY;

                ELSE

                    L_TEMP_CODE:=T_OUTGOING_CALL_MEMORY;

                END IF;

            ELSIF (REC_FEATURE.SOFE_FEATURE_NAME ='SF_PASSWORD_CALL_BARRING' OR REC_FEATURE.SOFE_FEATURE_NAME='SF_SECRET_CODE') THEN         --26

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_PASSWORD_CALL_BARRING;

                ELSE

                    L_TEMP_CODE:=T_PASSWORD_CALL_BARRING;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_SECRETARY_SERVICE' THEN   --27

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_SECRETARY_SERVICE ;

                ELSE

                    L_TEMP_CODE:=T_SECRETARY_SERVICE ;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_SELECTIVE_CALL_ACCEPTANCE' THEN         --28

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_SELECTIVE_CALL_ACCEPTANCE;

                ELSE

                    L_TEMP_CODE:=T_SELECTIVE_CALL_ACCEPTANCE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_SELECTIVE_CALL_REJECTION' THEN         --29

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_SELECTIVE_CALL_REJECTION;

                ELSE

                    L_TEMP_CODE:=T_SELECTIVE_CALL_REJECTION;

                END IF;

            END IF;

        END;


       END LOOP;


       IF V_SERO_ORDT_TYPE LIKE 'CREATE%' THEN

            IF L_TEMP_CODE IS NOT NULL THEN

            L_ACTTYPE:=T_CREATE_TYPE||'&'||L_TEMP_CODE;

            ELSE

            L_ACTTYPE:=T_CREATE_TYPE;

            END IF;


       ELSIF L_TEMP_CODE IS NOT NULL THEN

        L_ACTTYPE:=L_TEMP_CODE;

       ELSE

        L_ACTTYPE:=NULL;

       END IF;

      L_LENGTH:=LENGTH(L_ACTTYPE);

      IF L_LENGTH <=190 THEN

        L_ACTTYPE_VALUE:=L_ACTTYPE;

      ELSE

        --L_ACTTYPE_VALUE:=SUBSTR(L_ACTTYPE,1,190);
        L_ACTTYPE_VALUE:=SUBSTR(SUBSTR(L_ACTTYPE,1,190),1,INSTRC(SUBSTR(L_ACTTYPE,1,190),'&',-1,1));

      END IF;


    RETURN L_ACTTYPE_VALUE;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_ACTTYPE;

    FUNCTION GET_ACTTYPE2 (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


      CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_ORDT_TYPE (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT DISTINCT(SERO_ORDT_TYPE)
            FROM SERVICE_ORDERS
            WHERE SERO_ID=T_SERO_ID;

      CURSOR C_GET_FEATURES IS

            SELECT  SOFE_FEATURE_NAME
            FROM    SERVICE_ORDER_FEATURES,SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID
            AND     SOFE_SERO_ID=SEIT_SERO_ID
            AND     NVL(SOFE_DEFAULTVALUE,'N')='Y'
            AND     NVL(SOFE_PREV_VALUE,'N') <> NVL(SOFE_DEFAULTVALUE,'N')
            ORDER BY SOFE_FEATURE_NAME;



        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_SERO_ORDT_TYPE    SERVICE_ORDERS.SERO_SERV_ID%TYPE;



      L_TEMP_CODE         VARCHAR2(500);
      L_ACTTYPE           VARCHAR2(500);
      L_ACTTYPE_VALUE     VARCHAR2(200);
      L_LENGTH            VARCHAR2(10);



    T_CREATE_TYPE                          VARCHAR2(20);
    T_ABBREVIATED_DIAL                     VARCHAR2(20);             --1
    T_ABSENTEE_SERVICE                     VARCHAR2(20);              --2
    T_ANONYMOUS_CALL_BARRING               VARCHAR2(20);              --3
    T_CALL_BACK_ON_BUSY                    VARCHAR2(20);             --4
    T_CALL_CONFERENCE                      VARCHAR2(20);               --5
    T_CALL_FORWARDING_BY_TIME              VARCHAR2(20);               --6
    T_CALL_FORWARDING_OFFLINE              VARCHAR2(20);              --7
    T_CALL_HOLDING                         VARCHAR2(20);             --8
    T_CALL_TRANSFER_THREE_WAY              VARCHAR2(20);              --9
    T_CALL_WAITING                         VARCHAR2(20);               --10
    T_CF_IMMEDIATE                         VARCHAR2(20);               --11
    T_CF_NO_ANSWER                         VARCHAR2(20);               --12
    T_CF_OFFLINE                           VARCHAR2(20);              --13
    T_CF_ON_BUSY                           VARCHAR2(20);              --14
    T_CF_SELECTIVE                         VARCHAR2(20);             --15
    T_CLI                                  VARCHAR2(20);               --16
    T_CLI_PRE_IN_CALL_WAITING              VARCHAR2(20);     --17
    T_DO_NOT_DISTURB_SERVICE               VARCHAR2(20);              --18
    T_HOTLINE_IMMEDIATE                    VARCHAR2(20);              --19
    T_HOTLINE_TIMEDELAY                    VARCHAR2(20);              --20
    T_INCOMING_CALL_MEMORY                 VARCHAR2(20);             --21
    T_INCOMING_CALL_TRANSFER               VARCHAR2(20);              --22
    T_MCT                                  VARCHAR2(20);               --23
    T_MCT_ALL_INCOMING                     VARCHAR2(20);              --24
    T_OUTGOING_CALL_MEMORY                 VARCHAR2(20);              --25
    T_PASSWORD_CALL_BARRING                VARCHAR2(20);   --26
    T_SECRETARY_SERVICE                    VARCHAR2(20);              --27
    T_SELECTIVE_CALL_ACCEPTANCE            VARCHAR2(20);              --28
    T_SELECTIVE_CALL_REJECTION             VARCHAR2(20);             --29



   BEGIN

      OPEN C_SERO_ID;       FETCH C_SERO_ID
       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;

      OPEN C_ORDT_TYPE (V_SEIT_SERO_ID);
      FETCH C_ORDT_TYPE     INTO V_SERO_ORDT_TYPE;
      CLOSE C_ORDT_TYPE;

             T_CREATE_TYPE                          :='"18"';

       FOR REC_FEATURE IN C_GET_FEATURES LOOP


            T_ABBREVIATED_DIAL                     :='"12"';              --1
            T_ABSENTEE_SERVICE                     :='"21"';              --2
            T_ANONYMOUS_CALL_BARRING               :='"78"';              --3
            T_CALL_BACK_ON_BUSY                    :='"20"';              --4
            T_CALL_CONFERENCE                      :='"4"';               --5
            T_CALL_FORWARDING_BY_TIME              :='"0"';               --6
            T_CALL_FORWARDING_OFFLINE              :='"61"';              --7
            T_CALL_HOLDING                         :='"117"';             --8
            T_CALL_TRANSFER_THREE_WAY              :='"50"';              --9
            T_CALL_WAITING                         :='"6"';               --10
            T_CF_IMMEDIATE                         :='"0"';               --11
            T_CF_NO_ANSWER                         :='"2"';               --12
            T_CF_OFFLINE                           :='"61"';              --13
            T_CF_ON_BUSY                           :='"1"';               --14
            T_CF_SELECTIVE                         :='"102"';             --15
            T_CLI                                  :='"7"';               --16
            T_CLI_PRE_IN_CALL_WAITING              :='"6"'||'&'||'"7"';     --17
            T_DO_NOT_DISTURB_SERVICE               :='"17"';              --18
            T_HOTLINE_IMMEDIATE                    :='"13"';              --19
            T_HOTLINE_TIMEDELAY                    :='"14"';              --20
            T_INCOMING_CALL_MEMORY                 :='"96"';              --21
            T_INCOMING_CALL_TRANSFER               :='"50"';              --22
            T_MCT                                  :='"5"';               --23
            T_MCT_ALL_INCOMING                     :='"40"';              --24
            T_OUTGOING_CALL_MEMORY                 :='"79"';              --25
            T_PASSWORD_CALL_BARRING                :='"15"'||'&'||'"42"';   --26
            T_SECRETARY_SERVICE                    :='"53"';              --27
            T_SELECTIVE_CALL_ACCEPTANCE            :='"45"';              --28
            T_SELECTIVE_CALL_REJECTION             :='"46"';              --29




        BEGIN

            IF REC_FEATURE.SOFE_FEATURE_NAME ='SF_ABBREVIATED_DIAL' THEN            --1

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_ABBREVIATED_DIAL;

                ELSE

                    L_TEMP_CODE:=T_ABBREVIATED_DIAL;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_ABSENTEE_SERVICE' THEN         --2

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_ABSENTEE_SERVICE;

                ELSE

                    L_TEMP_CODE:=T_ABSENTEE_SERVICE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_ANONYMOUS_CALL_BARRING' THEN   --3

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_ANONYMOUS_CALL_BARRING;

                ELSE

                    L_TEMP_CODE:=T_ANONYMOUS_CALL_BARRING;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CALL_BACK_ON_BUSY' THEN         --4

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CALL_BACK_ON_BUSY;

                ELSE

                    L_TEMP_CODE:=T_CALL_BACK_ON_BUSY;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CALL_CONFERENCE' THEN            --5

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CALL_CONFERENCE;

                ELSE

                    L_TEMP_CODE:=T_CALL_CONFERENCE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CF_BY_TIME' THEN      --6

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CALL_FORWARDING_BY_TIME;

                ELSE

                    L_TEMP_CODE:=T_CALL_FORWARDING_BY_TIME;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CF_OFFLINE' THEN      --7

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CALL_FORWARDING_OFFLINE;

                ELSE

                    L_TEMP_CODE:=T_CALL_FORWARDING_OFFLINE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CALL_HOLDING' THEN                 --8

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CALL_HOLDING;

                ELSE

                    L_TEMP_CODE:=T_CALL_HOLDING;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CALL_TRANSFER_THREE_WAY' THEN      --9

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CALL_TRANSFER_THREE_WAY;

                ELSE

                    L_TEMP_CODE:=T_CALL_TRANSFER_THREE_WAY;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CALL_WAITING' THEN                 --10

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CALL_WAITING;

                ELSE

                    L_TEMP_CODE:=T_CALL_WAITING;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CF_IMMEDIATE' THEN                 --11

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CF_IMMEDIATE;

                ELSE

                    L_TEMP_CODE:=T_CF_IMMEDIATE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CF_NO_ANSWER' THEN                 --12

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CF_NO_ANSWER;

                ELSE

                    L_TEMP_CODE:=T_CF_NO_ANSWER;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CF_OFFLINE' THEN                   --13

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CF_OFFLINE;

                ELSE

                    L_TEMP_CODE:=T_CF_OFFLINE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CF_ON_BUSY' THEN                   --14

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CF_ON_BUSY;

                ELSE

                    L_TEMP_CODE:=T_CF_ON_BUSY;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CF_SELECTIVE' THEN                 --15

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CF_SELECTIVE;

                ELSE

                    L_TEMP_CODE:=T_CF_SELECTIVE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CLI' THEN                          --16

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CLI;

                ELSE

                    L_TEMP_CODE:=T_CLI;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CLI_PRESENTATION_IN_CALL_WAITING' THEN   --17

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CLI_PRE_IN_CALL_WAITING;

                ELSE

                    L_TEMP_CODE:=T_CLI_PRE_IN_CALL_WAITING;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_DO_NOT_DISTURB_SERVICE' THEN         --18

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_DO_NOT_DISTURB_SERVICE;

                ELSE

                    L_TEMP_CODE:=T_DO_NOT_DISTURB_SERVICE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_HOTLINE_IMMEDIATE' THEN            --19

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_HOTLINE_IMMEDIATE;

                ELSE

                    L_TEMP_CODE:=T_HOTLINE_IMMEDIATE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_HOTLINE_TIMEDELAY' THEN         --20

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_HOTLINE_TIMEDELAY;

                ELSE

                    L_TEMP_CODE:=T_HOTLINE_TIMEDELAY;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_INCOMING_CALL_MEMORY' THEN     --21

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_INCOMING_CALL_MEMORY;

                ELSE

                    L_TEMP_CODE:=T_INCOMING_CALL_MEMORY;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_INCOMING_CALL_TRANSFER' THEN         --22

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_INCOMING_CALL_TRANSFER;

                ELSE

                    L_TEMP_CODE:=T_INCOMING_CALL_TRANSFER;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_MCT' THEN                            --23

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_MCT;

                ELSE

                    L_TEMP_CODE:=T_MCT;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_MCT_ALL_INCOMING' THEN         --24

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_MCT_ALL_INCOMING;

                ELSE

                    L_TEMP_CODE:=T_MCT_ALL_INCOMING;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_OUTGOING_CALL_MEMORY' THEN   --25

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_OUTGOING_CALL_MEMORY;

                ELSE

                    L_TEMP_CODE:=T_OUTGOING_CALL_MEMORY;

                END IF;

            ELSIF (REC_FEATURE.SOFE_FEATURE_NAME ='SF_PASSWORD_CALL_BARRING' OR REC_FEATURE.SOFE_FEATURE_NAME='SF_SECRET_CODE') THEN         --26

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_PASSWORD_CALL_BARRING;

                ELSE

                    L_TEMP_CODE:=T_PASSWORD_CALL_BARRING;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_SECRETARY_SERVICE' THEN   --27

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_SECRETARY_SERVICE ;

                ELSE

                    L_TEMP_CODE:=T_SECRETARY_SERVICE ;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_SELECTIVE_CALL_ACCEPTANCE' THEN         --28

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_SELECTIVE_CALL_ACCEPTANCE;

                ELSE

                    L_TEMP_CODE:=T_SELECTIVE_CALL_ACCEPTANCE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_SELECTIVE_CALL_REJECTION' THEN         --29

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_SELECTIVE_CALL_REJECTION;

                ELSE

                    L_TEMP_CODE:=T_SELECTIVE_CALL_REJECTION;

                END IF;

            END IF;

        END;


       END LOOP;


       IF V_SERO_ORDT_TYPE LIKE 'CREATE%' THEN

            IF L_TEMP_CODE IS NOT NULL THEN

            L_ACTTYPE:=T_CREATE_TYPE||'&'||L_TEMP_CODE;

            ELSE

            L_ACTTYPE:=T_CREATE_TYPE;

            END IF;


       ELSIF L_TEMP_CODE IS NOT NULL THEN

        L_ACTTYPE:=L_TEMP_CODE;

       ELSE

        L_ACTTYPE:=NULL;

       END IF;

      L_LENGTH:=LENGTH(L_ACTTYPE);

      IF L_LENGTH <=190 THEN

        L_ACTTYPE_VALUE:=NULL;

      ELSE

        --L_ACTTYPE_VALUE:=SUBSTR(L_ACTTYPE,191,LENGTH(L_ACTTYPE));
        L_ACTTYPE_VALUE:=SUBSTR(L_ACTTYPE,INSTRC(SUBSTR(L_ACTTYPE,1,190),'&',-1,1)+1,LENGTH(L_ACTTYPE));

      END IF;


    RETURN L_ACTTYPE_VALUE;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_ACTTYPE2;

   FUNCTION GET_ATTRMOD (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


      CURSOR C_NUCC_CODE
      IS
            SELECT  SUBSTR(NUMB_NUCC_CODE,-2)NUCC_CODE
            FROM    SERVICE_IMPLEMENTATION_TASKS SI, SERVICE_ORDERS SO,NUMBERS NU
            WHERE   SI.SEIT_SERO_ID=SO.SERO_ID
            AND     NU.NUMB_SERV_ID=SERO_SERV_ID
            AND     SEIT_ID = PI_SEIT_ID
            AND     NUMB_NUMS_ID IN (3,4,6);



      L_NUCC_CODE         NUMBERS.NUMB_NUCC_CODE%TYPE;
      L_ATTRMOD           NUMBERS.NUMB_NUCC_CODE%TYPE;


    BEGIN

      OPEN C_NUCC_CODE;

      FETCH C_NUCC_CODE INTO L_NUCC_CODE;

      IF L_NUCC_CODE = '11' THEN L_ATTRMOD := '1';
      ELSE L_ATTRMOD := L_NUCC_CODE;
      END IF;

      CLOSE C_NUCC_CODE;

      RETURN L_ATTRMOD;

   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END GET_ATTRMOD;
   
---- Edited 17-01-2016 Dinesh ----   
FUNCTION GET_CIRCUITNO (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_GET_P_NUMBER (V_SEIT_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT DISTINCT(SERO_CIRT_NAME),SERO_SERT_ABBREVIATION
            FROM    SERVICE_ORDERS, CIRCUITS
            WHERE   CIRT_STATUS !='PENDINGDELETE'
            AND     SERO_CIRT_NAME = CIRT_NAME
            AND     SERO_ID = V_SEIT_SERO_ID;
            

      CURSOR C_GET_POTSOUT (V_CIRCUIT_ID SERVICE_ORDERS.SERO_CIRT_NAME%TYPE) IS
      
            SELECT  PO.PORT_NAME
            FROM    PORTS PO,PORT_LINKS PL,PORT_LINK_PORTS PLP
            WHERE   PO.PORT_ID=PLP.POLP_PORT_ID
            AND     PL.PORL_ID=PLP.POLP_PORL_ID
            AND     PL.PORL_CIRT_NAME = V_CIRCUIT_ID
            AND     PO.PORT_USAGE = 'SERVICE_SWITCHING_POINT'
            AND     SUBSTR(PO.PORT_NAME,1,8) = 'POTS-OUT';

      CURSOR C_GET_POTSIN (V_CIRCUIT_ID SERVICE_ORDERS.SERO_CIRT_NAME%TYPE) IS
      
            SELECT  PO.PORT_NAME
            FROM    PORTS PO,PORT_LINKS PL,PORT_LINK_PORTS PLP
            WHERE   PO.PORT_ID=PLP.POLP_PORT_ID
            AND     PL.PORL_ID=PLP.POLP_PORL_ID
            AND     PL.PORL_CIRT_NAME = V_CIRCUIT_ID
            AND     PO.PORT_USAGE = 'SERVICE_SWITCHING_POINT'
            AND     SUBSTR(PO.PORT_NAME,1,7) = 'POTS-IN';


        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_CRT_ID            SERVICE_ORDERS.SERO_SERV_ID%TYPE;
        V_SERO_TYPE         SERVICE_ORDERS.SERO_SERT_ABBREVIATION%TYPE;
        V_CIRCUIT_ID        CIRCUITS.CIRT_NAME%TYPE;
        V_PORT_NAME         PORTS.PORT_NAME%TYPE;


      L_TEMP_CODE         VARCHAR2(10);
      L_CIRCUITNO         VARCHAR2(2);



   BEGIN

      OPEN C_SERO_ID;       
      FETCH C_SERO_ID INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;

      OPEN C_GET_P_NUMBER (V_SEIT_SERO_ID);
      FETCH C_GET_P_NUMBER INTO V_CIRCUIT_ID, V_SERO_TYPE;
      CLOSE C_GET_P_NUMBER;


      IF V_SERO_TYPE = 'PSTN' THEN

          OPEN C_GET_POTSIN (V_CIRCUIT_ID);
          FETCH C_GET_POTSIN INTO V_PORT_NAME;
          CLOSE C_GET_POTSIN;

      ELSE
          OPEN C_GET_POTSOUT (V_CIRCUIT_ID);
          FETCH C_GET_POTSOUT INTO V_PORT_NAME;
          CLOSE C_GET_POTSOUT;
          
      END IF;

      IF V_PORT_NAME IS NULL THEN

          OPEN C_GET_POTSOUT (V_CIRCUIT_ID);
          FETCH C_GET_POTSOUT INTO V_PORT_NAME;
          CLOSE C_GET_POTSOUT;

      ELSE

       V_PORT_NAME:= V_PORT_NAME;   

      END IF;
      

      IF V_PORT_NAME IS NOT NULL  THEN

       L_TEMP_CODE :=  SUBSTR(V_PORT_NAME,-2);

       L_CIRCUITNO:=L_TEMP_CODE;

      ELSE

      L_CIRCUITNO:=NULL;

      END IF;


    RETURN L_CIRCUITNO;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_CIRCUITNO;
---- Edited 17-01-2016 Dinesh ----

FUNCTION GET_CODE1 (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


      CURSOR C_GET_P_NUMBER
      IS
            SELECT  NUMB_NUCC_CODE,NUMB_NUMBER
            FROM    SERVICE_IMPLEMENTATION_TASKS SI, SERVICE_ORDERS SO,NUMBERS NU
            WHERE   SI.SEIT_SERO_ID=SO.SERO_ID
            AND     NU.NUMB_SERV_ID=SERO_SERV_ID
            AND     SEIT_ID = PI_SEIT_ID
            AND     NUMB_NUMS_ID IN (3,6);



      L_NUCC_CODE         NUMBERS.NUMB_NUCC_CODE%TYPE;
      L_NUMB_NUMBER       NUMBERS.NUMB_NUMBER%TYPE;
      L_TEMP_CODE         VARCHAR2(10);
      L_CODE1             VARCHAR2(4);


   BEGIN

      OPEN C_GET_P_NUMBER;

      FETCH C_GET_P_NUMBER
       INTO L_NUCC_CODE,L_NUMB_NUMBER;

      CLOSE C_GET_P_NUMBER;

      IF L_NUCC_CODE IS NOT NULL AND  L_NUMB_NUMBER IS NOT NULL THEN

        L_TEMP_CODE:=L_NUCC_CODE||L_NUMB_NUMBER;

      END IF;

      L_CODE1:=SUBSTR(L_TEMP_CODE,4,4);


      RETURN L_CODE1;

   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END GET_CODE1;



FUNCTION GET_CODE2 (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


      CURSOR C_GET_P_NUMBER
      IS
            SELECT  NUMB_NUCC_CODE,NUMB_NUMBER
            FROM    SERVICE_IMPLEMENTATION_TASKS SI, SERVICE_ORDERS SO,NUMBERS NU
            WHERE   SI.SEIT_SERO_ID=SO.SERO_ID
            AND     NU.NUMB_SERV_ID=SERO_SERV_ID
            AND     SEIT_ID = PI_SEIT_ID
            AND     NUMB_NUMS_ID IN (3,6);



      L_NUCC_CODE         NUMBERS.NUMB_NUCC_CODE%TYPE;
      L_NUMB_NUMBER       NUMBERS.NUMB_NUMBER%TYPE;
      L_TEMP_CODE         VARCHAR2(10);
      L_CODE2             VARCHAR2(3);


   BEGIN

      OPEN C_GET_P_NUMBER;

      FETCH C_GET_P_NUMBER
       INTO L_NUCC_CODE,L_NUMB_NUMBER;

      CLOSE C_GET_P_NUMBER;

      IF L_NUCC_CODE IS NOT NULL AND  L_NUMB_NUMBER IS NOT NULL THEN

        L_TEMP_CODE:=L_NUCC_CODE||L_NUMB_NUMBER;

      END IF;

      L_CODE2:=SUBSTR(L_TEMP_CODE,4,3);


      RETURN L_CODE2;

   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END GET_CODE2;



FUNCTION GET_CODE3 (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


      CURSOR C_GET_P_NUMBER
      IS
            SELECT  NUMB_NUCC_CODE,NUMB_NUMBER
            FROM    SERVICE_IMPLEMENTATION_TASKS SI, SERVICE_ORDERS SO,NUMBERS NU
            WHERE   SI.SEIT_SERO_ID=SO.SERO_ID
            AND     NU.NUMB_SERV_ID=SERO_SERV_ID
            AND     SEIT_ID = PI_SEIT_ID
            AND     NUMB_NUMS_ID IN (3,6);



      L_NUCC_CODE         NUMBERS.NUMB_NUCC_CODE%TYPE;
      L_NUMB_NUMBER       NUMBERS.NUMB_NUMBER%TYPE;
      L_TEMP_CODE         VARCHAR2(10);
      L_TEMP_APPEND       VARCHAR2(1);
      L_CODE3             VARCHAR2(7);


   BEGIN

      OPEN C_GET_P_NUMBER;

      FETCH C_GET_P_NUMBER
      INTO L_NUCC_CODE,L_NUMB_NUMBER;

      CLOSE C_GET_P_NUMBER;

      L_TEMP_APPEND:= '1';

      IF L_NUCC_CODE IS NOT NULL AND  L_NUMB_NUMBER IS NOT NULL THEN

        L_TEMP_CODE:=L_NUCC_CODE||L_NUMB_NUMBER;

        IF L_NUCC_CODE ='011'  THEN

            L_CODE3:=SUBSTR (L_TEMP_CODE,2,6);

        ELSE

            L_CODE3:=L_TEMP_APPEND||SUBSTR (L_TEMP_CODE,2,6);

        END IF;


      END IF;

   RETURN L_CODE3;


   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END GET_CODE3;



FUNCTION GET_CODE4 (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


      CURSOR C_GET_P_NUMBER
      IS
            SELECT  NUMB_NUCC_CODE,NUMB_NUMBER
            FROM    SERVICE_IMPLEMENTATION_TASKS SI, SERVICE_ORDERS SO,NUMBERS NU
            WHERE   SI.SEIT_SERO_ID=SO.SERO_ID
            AND     NU.NUMB_SERV_ID=SERO_SERV_ID
            AND     SEIT_ID = PI_SEIT_ID
            AND     NUMB_NUMS_ID IN (3,6);



      L_NUCC_CODE         NUMBERS.NUMB_NUCC_CODE%TYPE;
      L_NUMB_NUMBER       NUMBERS.NUMB_NUMBER%TYPE;
      L_TEMP_CODE         VARCHAR2(10);
      L_TEMP_APPEND       VARCHAR2(1);
      L_CODE4            VARCHAR2(7);


   BEGIN

      OPEN C_GET_P_NUMBER;

      FETCH C_GET_P_NUMBER
      INTO L_NUCC_CODE,L_NUMB_NUMBER;

      CLOSE C_GET_P_NUMBER;

      L_TEMP_APPEND:= '1';

      IF L_NUCC_CODE IS NOT NULL AND  L_NUMB_NUMBER IS NOT NULL THEN

        L_TEMP_CODE:=L_NUCC_CODE||L_NUMB_NUMBER;

        IF L_NUCC_CODE ='011'  THEN

            L_CODE4:=SUBSTR (L_TEMP_CODE,2,5);

        ELSE

            L_CODE4:=L_TEMP_APPEND||SUBSTR (L_TEMP_CODE,2,5);

        END IF;


      END IF;

   RETURN L_CODE4;


   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END GET_CODE4;

   FUNCTION GET_DEACTTYPE (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR C_GET_FEATURES IS

            SELECT  SOFE_FEATURE_NAME
            FROM    SERVICE_ORDER_FEATURES,SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID
            AND     SOFE_SERO_ID=SEIT_SERO_ID
            AND     NVL(SOFE_DEFAULTVALUE,'N')='N'
            AND     NVL(SOFE_PREV_VALUE,'N') <> NVL(SOFE_DEFAULTVALUE,'N')
            ORDER BY SOFE_FEATURE_NAME;




      L_TEMP_CODE         VARCHAR2(500);
      L_DEACTTYPE         VARCHAR2(500);
      L_DEACTTYPE_VALUE   VARCHAR2(200);
      L_LENGTH            VARCHAR2(10);



    T_ABBREVIATED_DIAL                     VARCHAR2(20);             --1
    T_ABSENTEE_SERVICE                     VARCHAR2(20);              --2
    T_ANONYMOUS_CALL_BARRING               VARCHAR2(20);              --3
    T_CALL_BACK_ON_BUSY                    VARCHAR2(20);             --4
    T_CALL_CONFERENCE                      VARCHAR2(20);               --5
    T_CALL_FORWARDING_BY_TIME              VARCHAR2(20);               --6
    T_CALL_FORWARDING_OFFLINE              VARCHAR2(20);              --7
    T_CALL_HOLDING                         VARCHAR2(20);             --8
    T_CALL_TRANSFER_THREE_WAY              VARCHAR2(20);              --9
    T_CALL_WAITING                         VARCHAR2(20);               --10
    T_CF_IMMEDIATE                         VARCHAR2(20);               --11
    T_CF_NO_ANSWER                         VARCHAR2(20);               --12
    T_CF_OFFLINE                           VARCHAR2(20);              --13
    T_CF_ON_BUSY                           VARCHAR2(20);              --14
    T_CF_SELECTIVE                         VARCHAR2(20);             --15
    T_CLI                                  VARCHAR2(20);               --16
    T_CLI_PRE_IN_CALL_WAITING              VARCHAR2(20);     --17
    T_DO_NOT_DISTURB_SERVICE               VARCHAR2(20);              --18
    T_HOTLINE_IMMEDIATE                    VARCHAR2(20);              --19
    T_HOTLINE_TIMEDELAY                    VARCHAR2(20);              --20
    T_INCOMING_CALL_MEMORY                 VARCHAR2(20);             --21
    T_INCOMING_CALL_TRANSFER               VARCHAR2(20);              --22
    T_MCT                                  VARCHAR2(20);               --23
    T_MCT_ALL_INCOMING                     VARCHAR2(20);              --24
    T_OUTGOING_CALL_MEMORY                 VARCHAR2(20);              --25
    T_PASSWORD_CALL_BARRING                VARCHAR2(20);   --26
    T_SECRETARY_SERVICE                    VARCHAR2(20);              --27
    T_SELECTIVE_CALL_ACCEPTANCE            VARCHAR2(20);              --28
    T_SELECTIVE_CALL_REJECTION             VARCHAR2(20);             --29
    T_SF_SECRET_CODE                       VARCHAR2(20);             --30



   BEGIN


       FOR REC_FEATURE IN C_GET_FEATURES LOOP


            T_ABBREVIATED_DIAL                     :='"12"';              --1
            T_ABSENTEE_SERVICE                     :='"21"';              --2
            T_ANONYMOUS_CALL_BARRING               :='"78"';              --3
            T_CALL_BACK_ON_BUSY                    :='"20"';              --4
            T_CALL_CONFERENCE                      :='"4"';               --5
            T_CALL_FORWARDING_BY_TIME              :='"0"';               --6
            T_CALL_FORWARDING_OFFLINE              :='"61"';              --7
            T_CALL_HOLDING                         :='"117"';             --8
            T_CALL_TRANSFER_THREE_WAY              :='"50"';              --9
            T_CALL_WAITING                         :='"6"';               --10
            T_CF_IMMEDIATE                         :='"0"';               --11
            T_CF_NO_ANSWER                         :='"2"';               --12
            T_CF_OFFLINE                           :='"61"';              --13
            T_CF_ON_BUSY                           :='"1"';               --14
            T_CF_SELECTIVE                         :='"102"';             --15
            T_CLI                                  :='"7"';               --16
            T_CLI_PRE_IN_CALL_WAITING              :='"6"'||'&'||'"7"';     --17
            T_DO_NOT_DISTURB_SERVICE               :='"17"';              --18
            T_HOTLINE_IMMEDIATE                    :='"13"';              --19
            T_HOTLINE_TIMEDELAY                    :='"14"';              --20
            T_INCOMING_CALL_MEMORY                 :='"96"';              --21
            T_INCOMING_CALL_TRANSFER               :='"50"';              --22
            T_MCT                                  :='"5"';               --23
            T_MCT_ALL_INCOMING                     :='"40"';              --24
            T_OUTGOING_CALL_MEMORY                 :='"79"';              --25
            T_PASSWORD_CALL_BARRING                :='"15"'||'&'||'"42"';   --26
            T_SECRETARY_SERVICE                    :='"53"';              --27
            T_SELECTIVE_CALL_ACCEPTANCE            :='"45"';              --28
            T_SELECTIVE_CALL_REJECTION             :='"46"';              --29
            T_SF_SECRET_CODE                       :='"15"';              --30




        BEGIN

            IF REC_FEATURE.SOFE_FEATURE_NAME ='SF_ABBREVIATED_DIAL' THEN            --1

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_ABBREVIATED_DIAL;

                ELSE

                    L_TEMP_CODE:=T_ABBREVIATED_DIAL;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_ABSENTEE_SERVICE' THEN         --2

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_ABSENTEE_SERVICE;

                ELSE

                    L_TEMP_CODE:=T_ABSENTEE_SERVICE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_ANONYMOUS_CALL_BARRING' THEN   --3

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_ANONYMOUS_CALL_BARRING;

                ELSE

                    L_TEMP_CODE:=T_ANONYMOUS_CALL_BARRING;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CALL_BACK_ON_BUSY' THEN         --4

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CALL_BACK_ON_BUSY;

                ELSE

                    L_TEMP_CODE:=T_CALL_BACK_ON_BUSY;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CALL_CONFERENCE' THEN            --5

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CALL_CONFERENCE;

                ELSE

                    L_TEMP_CODE:=T_CALL_CONFERENCE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CF_BY_TIME' THEN      --6

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CALL_FORWARDING_BY_TIME;

                ELSE

                    L_TEMP_CODE:=T_CALL_FORWARDING_BY_TIME;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CF_OFFLINE' THEN      --7

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CALL_FORWARDING_OFFLINE;

                ELSE

                    L_TEMP_CODE:=T_CALL_FORWARDING_OFFLINE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CALL_HOLDING' THEN                 --8

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CALL_HOLDING;

                ELSE

                    L_TEMP_CODE:=T_CALL_HOLDING;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CALL_TRANSFER_THREE_WAY' THEN      --9

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CALL_TRANSFER_THREE_WAY;

                ELSE

                    L_TEMP_CODE:=T_CALL_TRANSFER_THREE_WAY;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CALL_WAITING' THEN                 --10

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CALL_WAITING;

                ELSE

                    L_TEMP_CODE:=T_CALL_WAITING;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CF_IMMEDIATE' THEN                 --11

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CF_IMMEDIATE;

                ELSE

                    L_TEMP_CODE:=T_CF_IMMEDIATE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CF_NO_ANSWER' THEN                 --12

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CF_NO_ANSWER;

                ELSE

                    L_TEMP_CODE:=T_CF_NO_ANSWER;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CF_OFFLINE' THEN                   --13

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CF_OFFLINE;

                ELSE

                    L_TEMP_CODE:=T_CF_OFFLINE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CF_ON_BUSY' THEN                   --14

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CF_ON_BUSY;

                ELSE

                    L_TEMP_CODE:=T_CF_ON_BUSY;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CF_SELECTIVE' THEN                 --15

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CF_SELECTIVE;

                ELSE

                    L_TEMP_CODE:=T_CF_SELECTIVE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CLI' THEN                          --16

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CLI;

                ELSE

                    L_TEMP_CODE:=T_CLI;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CLI_PRESENTATION_IN_CALL_WAITING' THEN   --17

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CLI_PRE_IN_CALL_WAITING;

                ELSE

                    L_TEMP_CODE:=T_CLI_PRE_IN_CALL_WAITING;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_DO_NOT_DISTURB_SERVICE' THEN         --18

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_DO_NOT_DISTURB_SERVICE;

                ELSE

                    L_TEMP_CODE:=T_DO_NOT_DISTURB_SERVICE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_HOTLINE_IMMEDIATE' THEN            --19

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_HOTLINE_IMMEDIATE;

                ELSE

                    L_TEMP_CODE:=T_HOTLINE_IMMEDIATE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_HOTLINE_TIMEDELAY' THEN         --20

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_HOTLINE_TIMEDELAY;

                ELSE

                    L_TEMP_CODE:=T_HOTLINE_TIMEDELAY;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_INCOMING_CALL_MEMORY' THEN     --21

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_INCOMING_CALL_MEMORY;

                ELSE

                    L_TEMP_CODE:=T_INCOMING_CALL_MEMORY;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_INCOMING_CALL_TRANSFER' THEN         --22

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_INCOMING_CALL_TRANSFER;

                ELSE

                    L_TEMP_CODE:=T_INCOMING_CALL_TRANSFER;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_MCT' THEN                            --23

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_MCT;

                ELSE

                    L_TEMP_CODE:=T_MCT;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_MCT_ALL_INCOMING' THEN         --24

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_MCT_ALL_INCOMING;

                ELSE

                    L_TEMP_CODE:=T_MCT_ALL_INCOMING;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_OUTGOING_CALL_MEMORY' THEN   --25

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_OUTGOING_CALL_MEMORY;

                ELSE

                    L_TEMP_CODE:=T_OUTGOING_CALL_MEMORY;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_PASSWORD_CALL_BARRING' THEN         --26

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_PASSWORD_CALL_BARRING;

                ELSE

                    L_TEMP_CODE:=T_PASSWORD_CALL_BARRING;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_SECRETARY_SERVICE' THEN   --27

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_SECRETARY_SERVICE ;

                ELSE

                    L_TEMP_CODE:=T_SECRETARY_SERVICE ;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_SELECTIVE_CALL_ACCEPTANCE' THEN         --28

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_SELECTIVE_CALL_ACCEPTANCE;

                ELSE

                    L_TEMP_CODE:=T_SELECTIVE_CALL_ACCEPTANCE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_SELECTIVE_CALL_REJECTION' THEN         --29

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_SELECTIVE_CALL_REJECTION;

                ELSE

                    L_TEMP_CODE:=T_SELECTIVE_CALL_REJECTION;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_SECRET_CODE' THEN         --30

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_SF_SECRET_CODE;

                ELSE

                    L_TEMP_CODE:=T_SF_SECRET_CODE;

                END IF;

            END IF;

        END;


       END LOOP;


       IF L_TEMP_CODE IS NOT NULL THEN

        L_DEACTTYPE:=L_TEMP_CODE;

       ELSE

        L_DEACTTYPE:=NULL;

       END IF;

      L_LENGTH:=LENGTH(L_DEACTTYPE);

      IF L_LENGTH <=190 THEN

        L_DEACTTYPE_VALUE:=L_DEACTTYPE;

      ELSE

        --L_DEACTTYPE_VALUE:=SUBSTR(L_DEACTTYPE,1,190);
        L_DEACTTYPE_VALUE:=SUBSTR(SUBSTR(L_DEACTTYPE,1,190),1,INSTRC(SUBSTR(L_DEACTTYPE,1,190),'&',-1,1));

      END IF;

    RETURN L_DEACTTYPE_VALUE;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_DEACTTYPE;

   FUNCTION GET_DEACTTYPE2 (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR C_GET_FEATURES IS

            SELECT  SOFE_FEATURE_NAME
            FROM    SERVICE_ORDER_FEATURES,SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID
            AND     SOFE_SERO_ID=SEIT_SERO_ID
            AND     NVL(SOFE_DEFAULTVALUE,'N')='N'
            AND     NVL(SOFE_PREV_VALUE,'N') <> NVL(SOFE_DEFAULTVALUE,'N')
            ORDER BY SOFE_FEATURE_NAME;




      L_TEMP_CODE         VARCHAR2(500);
      L_DEACTTYPE         VARCHAR2(500);
      L_DEACTTYPE_VALUE   VARCHAR2(200);
      L_LENGTH            VARCHAR2(10);



    T_ABBREVIATED_DIAL                     VARCHAR2(20);             --1
    T_ABSENTEE_SERVICE                     VARCHAR2(20);              --2
    T_ANONYMOUS_CALL_BARRING               VARCHAR2(20);              --3
    T_CALL_BACK_ON_BUSY                    VARCHAR2(20);             --4
    T_CALL_CONFERENCE                      VARCHAR2(20);               --5
    T_CALL_FORWARDING_BY_TIME              VARCHAR2(20);               --6
    T_CALL_FORWARDING_OFFLINE              VARCHAR2(20);              --7
    T_CALL_HOLDING                         VARCHAR2(20);             --8
    T_CALL_TRANSFER_THREE_WAY              VARCHAR2(20);              --9
    T_CALL_WAITING                         VARCHAR2(20);               --10
    T_CF_IMMEDIATE                         VARCHAR2(20);               --11
    T_CF_NO_ANSWER                         VARCHAR2(20);               --12
    T_CF_OFFLINE                           VARCHAR2(20);              --13
    T_CF_ON_BUSY                           VARCHAR2(20);              --14
    T_CF_SELECTIVE                         VARCHAR2(20);             --15
    T_CLI                                  VARCHAR2(20);               --16
    T_CLI_PRE_IN_CALL_WAITING              VARCHAR2(20);     --17
    T_DO_NOT_DISTURB_SERVICE               VARCHAR2(20);              --18
    T_HOTLINE_IMMEDIATE                    VARCHAR2(20);              --19
    T_HOTLINE_TIMEDELAY                    VARCHAR2(20);              --20
    T_INCOMING_CALL_MEMORY                 VARCHAR2(20);             --21
    T_INCOMING_CALL_TRANSFER               VARCHAR2(20);              --22
    T_MCT                                  VARCHAR2(20);               --23
    T_MCT_ALL_INCOMING                     VARCHAR2(20);              --24
    T_OUTGOING_CALL_MEMORY                 VARCHAR2(20);              --25
    T_PASSWORD_CALL_BARRING                VARCHAR2(20);   --26
    T_SECRETARY_SERVICE                    VARCHAR2(20);              --27
    T_SELECTIVE_CALL_ACCEPTANCE            VARCHAR2(20);              --28
    T_SELECTIVE_CALL_REJECTION             VARCHAR2(20);             --29
    T_SF_SECRET_CODE                       VARCHAR2(20);             --30



   BEGIN


       FOR REC_FEATURE IN C_GET_FEATURES LOOP


            T_ABBREVIATED_DIAL                     :='"12"';              --1
            T_ABSENTEE_SERVICE                     :='"21"';              --2
            T_ANONYMOUS_CALL_BARRING               :='"78"';              --3
            T_CALL_BACK_ON_BUSY                    :='"20"';              --4
            T_CALL_CONFERENCE                      :='"4"';               --5
            T_CALL_FORWARDING_BY_TIME              :='"0"';               --6
            T_CALL_FORWARDING_OFFLINE              :='"61"';              --7
            T_CALL_HOLDING                         :='"117"';             --8
            T_CALL_TRANSFER_THREE_WAY              :='"50"';              --9
            T_CALL_WAITING                         :='"6"';               --10
            T_CF_IMMEDIATE                         :='"0"';               --11
            T_CF_NO_ANSWER                         :='"2"';               --12
            T_CF_OFFLINE                           :='"61"';              --13
            T_CF_ON_BUSY                           :='"1"';               --14
            T_CF_SELECTIVE                         :='"102"';             --15
            T_CLI                                  :='"7"';               --16
            T_CLI_PRE_IN_CALL_WAITING              :='"6"'||'&'||'"7"';     --17
            T_DO_NOT_DISTURB_SERVICE               :='"17"';              --18
            T_HOTLINE_IMMEDIATE                    :='"13"';              --19
            T_HOTLINE_TIMEDELAY                    :='"14"';              --20
            T_INCOMING_CALL_MEMORY                 :='"96"';              --21
            T_INCOMING_CALL_TRANSFER               :='"50"';              --22
            T_MCT                                  :='"5"';               --23
            T_MCT_ALL_INCOMING                     :='"40"';              --24
            T_OUTGOING_CALL_MEMORY                 :='"79"';              --25
            T_PASSWORD_CALL_BARRING                :='"15"'||'&'||'"42"';   --26
            T_SECRETARY_SERVICE                    :='"53"';              --27
            T_SELECTIVE_CALL_ACCEPTANCE            :='"45"';              --28
            T_SELECTIVE_CALL_REJECTION             :='"46"';              --29
            T_SF_SECRET_CODE                       :='"15"';




        BEGIN

            IF REC_FEATURE.SOFE_FEATURE_NAME ='SF_ABBREVIATED_DIAL' THEN            --1

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_ABBREVIATED_DIAL;

                ELSE

                    L_TEMP_CODE:=T_ABBREVIATED_DIAL;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_ABSENTEE_SERVICE' THEN         --2

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_ABSENTEE_SERVICE;

                ELSE

                    L_TEMP_CODE:=T_ABSENTEE_SERVICE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_ANONYMOUS_CALL_BARRING' THEN   --3

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_ANONYMOUS_CALL_BARRING;

                ELSE

                    L_TEMP_CODE:=T_ANONYMOUS_CALL_BARRING;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CALL_BACK_ON_BUSY' THEN         --4

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CALL_BACK_ON_BUSY;

                ELSE

                    L_TEMP_CODE:=T_CALL_BACK_ON_BUSY;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CALL_CONFERENCE' THEN            --5

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CALL_CONFERENCE;

                ELSE

                    L_TEMP_CODE:=T_CALL_CONFERENCE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CF_BY_TIME' THEN      --6

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CALL_FORWARDING_BY_TIME;

                ELSE

                    L_TEMP_CODE:=T_CALL_FORWARDING_BY_TIME;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CF_OFFLINE' THEN      --7

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CALL_FORWARDING_OFFLINE;

                ELSE

                    L_TEMP_CODE:=T_CALL_FORWARDING_OFFLINE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CALL_HOLDING' THEN                 --8

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CALL_HOLDING;

                ELSE

                    L_TEMP_CODE:=T_CALL_HOLDING;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CALL_TRANSFER_THREE_WAY' THEN      --9

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CALL_TRANSFER_THREE_WAY;

                ELSE

                    L_TEMP_CODE:=T_CALL_TRANSFER_THREE_WAY;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CALL_WAITING' THEN                 --10

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CALL_WAITING;

                ELSE

                    L_TEMP_CODE:=T_CALL_WAITING;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CF_IMMEDIATE' THEN                 --11

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CF_IMMEDIATE;

                ELSE

                    L_TEMP_CODE:=T_CF_IMMEDIATE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CF_NO_ANSWER' THEN                 --12

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CF_NO_ANSWER;

                ELSE

                    L_TEMP_CODE:=T_CF_NO_ANSWER;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CF_OFFLINE' THEN                   --13

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CF_OFFLINE;

                ELSE

                    L_TEMP_CODE:=T_CF_OFFLINE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CF_ON_BUSY' THEN                   --14

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CF_ON_BUSY;

                ELSE

                    L_TEMP_CODE:=T_CF_ON_BUSY;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CF_SELECTIVE' THEN                 --15

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CF_SELECTIVE;

                ELSE

                    L_TEMP_CODE:=T_CF_SELECTIVE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CLI' THEN                          --16

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CLI;

                ELSE

                    L_TEMP_CODE:=T_CLI;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_CLI_PRESENTATION_IN_CALL_WAITING' THEN   --17

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_CLI_PRE_IN_CALL_WAITING;

                ELSE

                    L_TEMP_CODE:=T_CLI_PRE_IN_CALL_WAITING;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_DO_NOT_DISTURB_SERVICE' THEN         --18

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_DO_NOT_DISTURB_SERVICE;

                ELSE

                    L_TEMP_CODE:=T_DO_NOT_DISTURB_SERVICE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_HOTLINE_IMMEDIATE' THEN            --19

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_HOTLINE_IMMEDIATE;

                ELSE

                    L_TEMP_CODE:=T_HOTLINE_IMMEDIATE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_HOTLINE_TIMEDELAY' THEN         --20

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_HOTLINE_TIMEDELAY;

                ELSE

                    L_TEMP_CODE:=T_HOTLINE_TIMEDELAY;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_INCOMING_CALL_MEMORY' THEN     --21

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_INCOMING_CALL_MEMORY;

                ELSE

                    L_TEMP_CODE:=T_INCOMING_CALL_MEMORY;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_INCOMING_CALL_TRANSFER' THEN         --22

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_INCOMING_CALL_TRANSFER;

                ELSE

                    L_TEMP_CODE:=T_INCOMING_CALL_TRANSFER;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_MCT' THEN                            --23

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_MCT;

                ELSE

                    L_TEMP_CODE:=T_MCT;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_MCT_ALL_INCOMING' THEN         --24

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_MCT_ALL_INCOMING;

                ELSE

                    L_TEMP_CODE:=T_MCT_ALL_INCOMING;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_OUTGOING_CALL_MEMORY' THEN   --25

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_OUTGOING_CALL_MEMORY;

                ELSE

                    L_TEMP_CODE:=T_OUTGOING_CALL_MEMORY;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_PASSWORD_CALL_BARRING' THEN         --26

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_PASSWORD_CALL_BARRING;

                ELSE

                    L_TEMP_CODE:=T_PASSWORD_CALL_BARRING;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_SECRETARY_SERVICE' THEN   --27

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_SECRETARY_SERVICE ;

                ELSE

                    L_TEMP_CODE:=T_SECRETARY_SERVICE ;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_SELECTIVE_CALL_ACCEPTANCE' THEN         --28

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_SELECTIVE_CALL_ACCEPTANCE;

                ELSE

                    L_TEMP_CODE:=T_SELECTIVE_CALL_ACCEPTANCE;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_SELECTIVE_CALL_REJECTION' THEN         --29

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_SELECTIVE_CALL_REJECTION;

                ELSE

                    L_TEMP_CODE:=T_SELECTIVE_CALL_REJECTION;

                END IF;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_SECRET_CODE' THEN         --30

                IF L_TEMP_CODE IS NOT NULL THEN

                    L_TEMP_CODE:=L_TEMP_CODE||'&'||T_SF_SECRET_CODE;

                ELSE

                    L_TEMP_CODE:=T_SF_SECRET_CODE;

                END IF;

            END IF;

        END;


       END LOOP;


       IF L_TEMP_CODE IS NOT NULL THEN

        L_DEACTTYPE:=L_TEMP_CODE;

       ELSE

        L_DEACTTYPE:=NULL;

       END IF;

      L_LENGTH:=LENGTH(L_DEACTTYPE);

      IF L_LENGTH <=190 THEN

        L_DEACTTYPE_VALUE:=NULL;

      ELSE

        --L_DEACTTYPE_VALUE:=SUBSTR(L_DEACTTYPE,191,LENGTH(L_DEACTTYPE));
        L_DEACTTYPE_VALUE:=SUBSTR(L_DEACTTYPE,INSTRC(SUBSTR(L_DEACTTYPE,1,190),'&',-1,1)+1,LENGTH(L_DEACTTYPE));

      END IF;

    RETURN L_DEACTTYPE_VALUE;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_DEACTTYPE2;
   FUNCTION GET_DN (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_SERV_ID (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT DISTINCT(SERO_SERV_ID)
            FROM SERVICE_ORDERS
            WHERE SERO_ID=T_SERO_ID;

      CURSOR C_GET_P_NUMBER (T_SERV_ID SERVICE_ORDERS.SERO_SERV_ID%TYPE) IS

            SELECT  NUMB_NUCC_CODE,NUMB_NUMBER
            FROM    NUMBERS NU
            WHERE   NU.NUMB_SERV_ID=T_SERV_ID
            AND     NUMB_NUMS_ID IN (3,6);


        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_SERV_ID           SERVICE_ORDERS.SERO_SERV_ID%TYPE;

      L_NUCC_CODE         NUMBERS.NUMB_NUCC_CODE%TYPE;
      L_NUMB_NUMBER       NUMBERS.NUMB_NUMBER%TYPE;
      L_TEMP_CODE         VARCHAR2(10);
      L_DN               VARCHAR2(10);



   BEGIN

      OPEN C_SERO_ID;       FETCH C_SERO_ID
       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;

      OPEN C_SERV_ID (V_SEIT_SERO_ID);
      FETCH C_SERV_ID     INTO V_SERV_ID;
      CLOSE C_SERV_ID;

      OPEN C_GET_P_NUMBER (V_SERV_ID);
      FETCH C_GET_P_NUMBER INTO L_NUCC_CODE,L_NUMB_NUMBER;
      CLOSE C_GET_P_NUMBER;


      IF L_NUCC_CODE IS NOT NULL AND L_NUMB_NUMBER IS NOT NULL THEN

       L_TEMP_CODE := L_NUCC_CODE||L_NUMB_NUMBER;

       L_DN:=SUBSTR(L_TEMP_CODE,-9);


      END IF;

    RETURN L_DN;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_DN;

---- Edited 17-01-2016 Dinesh ----
 FUNCTION GET_IPADDR (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_GET_P_NUMBER (V_SEIT_SERO_ID SERVICE_ORDERS.SERO_CIRT_NAME%TYPE) IS

            SELECT DISTINCT(SERO_CIRT_NAME),SERO_SERT_ABBREVIATION
            FROM    SERVICE_ORDERS, CIRCUITS
            WHERE   CIRT_STATUS !='PENDINGDELETE'
            AND     SERO_CIRT_NAME = CIRT_NAME
            AND     SERO_ID = V_SEIT_SERO_ID;


      CURSOR C_GET_POTSOUT (V_SEIT_SERO_ID SERVICE_ORDERS.SERO_CIRT_NAME%TYPE) IS
      
            SELECT  MAX(PO.PORT_EQUP_ID)
            FROM    PORTS PO,PORT_LINKS PL,PORT_LINK_PORTS PLP
            WHERE   PO.PORT_ID=PLP.POLP_PORT_ID
            AND     PL.PORL_ID=PLP.POLP_PORL_ID
            AND     PL.PORL_CIRT_NAME = V_SEIT_SERO_ID
            AND     PO.PORT_USAGE ='SERVICE_SWITCHING_POINT'
            AND     SUBSTR(PO.PORT_NAME,1,8) = 'POTS-OUT';

      CURSOR C_GET_POTSIN (V_SEIT_SERO_ID SERVICE_ORDERS.SERO_CIRT_NAME%TYPE) IS
      
            SELECT  MAX(PO.PORT_EQUP_ID)
            FROM    PORTS PO,PORT_LINKS PL,PORT_LINK_PORTS PLP
            WHERE   PO.PORT_ID=PLP.POLP_PORT_ID
            AND     PL.PORL_ID=PLP.POLP_PORL_ID
            AND     PL.PORL_CIRT_NAME = V_SEIT_SERO_ID
            AND     PO.PORT_USAGE ='SERVICE_SWITCHING_POINT'
            AND     SUBSTR(PO.PORT_NAME,1,7) = 'POTS-IN';

      CURSOR C_GET_IPADDR (T_EQP_ID EQUIPMENT.EQUP_ID%TYPE) IS

            SELECT  EQUP_IPADDRESS
            FROM    EQUIPMENT
            WHERE   EQUP_ID = T_EQP_ID;

        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_CRT_ID            SERVICE_ORDERS.SERO_SERV_ID%TYPE;
        V_SERO_TYPE         SERVICE_ORDERS.SERO_SERT_ABBREVIATION%TYPE;
        V_CIRCUIT_ID        CIRCUITS.CIRT_NAME%TYPE;
        V_PORT_EQUP_ID      PORTS.PORT_EQUP_ID%TYPE;

      L_TEMP_CODE         VARCHAR2(20);
      L_IPADDR            VARCHAR2(20);


   BEGIN

      OPEN C_SERO_ID;       FETCH C_SERO_ID
       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;

      OPEN C_GET_P_NUMBER (V_SEIT_SERO_ID);
      FETCH C_GET_P_NUMBER INTO V_CIRCUIT_ID, V_SERO_TYPE;
      CLOSE C_GET_P_NUMBER;

      IF (V_SERO_TYPE = 'PSTN' OR V_SERO_TYPE = 'CCB') THEN

          OPEN C_GET_POTSIN (V_CIRCUIT_ID);
          FETCH C_GET_POTSIN INTO V_PORT_EQUP_ID;
          CLOSE C_GET_POTSIN;

      ELSE

          OPEN C_GET_POTSOUT (V_CIRCUIT_ID);
          FETCH C_GET_POTSOUT INTO V_PORT_EQUP_ID;
          CLOSE C_GET_POTSOUT;

      END IF;

      IF V_PORT_EQUP_ID IS NULL THEN

          OPEN C_GET_POTSOUT (V_CIRCUIT_ID);
          FETCH C_GET_POTSOUT INTO V_PORT_EQUP_ID;
          CLOSE C_GET_POTSOUT;

      ELSE

       V_PORT_EQUP_ID:= V_PORT_EQUP_ID;   

      END IF;

      OPEN C_GET_IPADDR (V_PORT_EQUP_ID);
      FETCH C_GET_IPADDR INTO L_TEMP_CODE;
      CLOSE C_GET_IPADDR;

      IF L_TEMP_CODE IS NOT NULL  THEN

       L_IPADDR :=L_TEMP_CODE;

      ELSE

      L_IPADDR:=NULL;

      END IF;


    RETURN L_IPADDR;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_IPADDR;
---- Edited 17-01-2016 Dinesh ----

FUNCTION GET_LATA (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


      CURSOR C_NUCC_CODE
      IS
            SELECT  SUBSTR(NUMB_NUCC_CODE,-2)NUCC_CODE
            FROM    SERVICE_IMPLEMENTATION_TASKS SI, SERVICE_ORDERS SO,NUMBERS NU
            WHERE   SI.SEIT_SERO_ID=SO.SERO_ID
            AND     NU.NUMB_SERV_ID=SERO_SERV_ID
            AND     SEIT_ID = PI_SEIT_ID
            AND     NUMB_NUMS_ID IN (3,4,6);



      L_NUCC_CODE         NUMBERS.NUMB_NUCC_CODE%TYPE;


   BEGIN

      OPEN C_NUCC_CODE;

      FETCH C_NUCC_CODE
       INTO L_NUCC_CODE;

      CLOSE C_NUCC_CODE;

      RETURN L_NUCC_CODE;

   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END GET_LATA;


FUNCTION GET_NEWLATA (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


      CURSOR C_NUCC_CODE
      IS
            SELECT  SUBSTR(NUMB_NUCC_CODE,-2)NUCC_CODE
            FROM    SERVICE_IMPLEMENTATION_TASKS SI, SERVICE_ORDERS SO,NUMBERS NU
            WHERE   SI.SEIT_SERO_ID=SO.SERO_ID
            AND     NU.NUMB_SERV_ID=SERO_SERV_ID
            AND     SEIT_ID = PI_SEIT_ID
            AND     NUMB_NUMS_ID IN (3,6);



      L_NUCC_CODE         NUMBERS.NUMB_NUCC_CODE%TYPE;


   BEGIN

      OPEN C_NUCC_CODE;

      FETCH C_NUCC_CODE
       INTO L_NUCC_CODE;

      CLOSE C_NUCC_CODE;


      RETURN L_NUCC_CODE;

   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END GET_NEWLATA;

 FUNCTION GET_NEWSDN (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_NUMB_TYPE (T_SEIT_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT SEOA_DEFAULTVALUE
            FROM SERVICE_ORDER_ATTRIBUTES
            WHERE   SEOA_SERO_ID=T_SEIT_ID
            AND     SEOA_NAME='SA_NUMBER_TYPE_NEW';

      CURSOR C_SERV_ID (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT DISTINCT(SERO_SERV_ID)
            FROM SERVICE_ORDERS
            WHERE SERO_ID=T_SERO_ID;

      CURSOR C_GET_P_NUMBER (T_SERV_ID SERVICE_ORDERS.SERO_SERV_ID%TYPE) IS

            SELECT  NUMB_NUCC_CODE,NUMB_NUMBER
            FROM    NUMBERS NU
            WHERE   NU.NUMB_SERV_ID=T_SERV_ID
            AND     NUMB_NUMS_ID IN (3,6);


        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_SERV_ID           SERVICE_ORDERS.SERO_SERV_ID%TYPE;
        V_NUMB_TYPE         VARCHAR2(20);

      L_NUCC_CODE         NUMBERS.NUMB_NUCC_CODE%TYPE;
      L_NUMB_NUMBER       NUMBERS.NUMB_NUMBER%TYPE;
      L_TEMP_CODE         VARCHAR2(10);
      L_NEWSDN             VARCHAR2(10);
      L_TEMP_APPEND       VARCHAR2(1);



   BEGIN

      OPEN C_SERO_ID;       FETCH C_SERO_ID
       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;


      OPEN C_NUMB_TYPE (V_SEIT_SERO_ID);
      FETCH C_NUMB_TYPE     INTO V_NUMB_TYPE;
      CLOSE C_NUMB_TYPE;

      OPEN C_SERV_ID (V_SEIT_SERO_ID);
      FETCH C_SERV_ID     INTO V_SERV_ID;
      CLOSE C_SERV_ID;

      OPEN C_GET_P_NUMBER (V_SERV_ID);
      FETCH C_GET_P_NUMBER INTO L_NUCC_CODE,L_NUMB_NUMBER;
      CLOSE C_GET_P_NUMBER;

        L_TEMP_APPEND:= '1';

      IF L_NUCC_CODE IS NOT NULL AND L_NUMB_NUMBER IS NOT NULL THEN

       L_TEMP_CODE := L_NUCC_CODE||L_NUMB_NUMBER;


        IF V_NUMB_TYPE='NON-FNR' THEN

              L_NEWSDN:=SUBSTR(L_TEMP_CODE,-7);

        ELSIF L_NUCC_CODE ='011' AND V_NUMB_TYPE='FNR' THEN

              L_NEWSDN:=SUBSTR(L_TEMP_CODE,-9);

        ELSIF L_NUCC_CODE !='011' AND V_NUMB_TYPE='FNR' THEN

              L_NEWSDN:=L_TEMP_APPEND||SUBSTR(L_TEMP_CODE,-9);
        ELSE

              L_NEWSDN:=NULL;

        END IF;


      END IF;

    RETURN L_NEWSDN;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_NEWSDN;
   FUNCTION GET_OLDLATA (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


      CURSOR C_NUCC_CODE
      IS
            SELECT  SUBSTR(NUMB_NUCC_CODE,-2)NUCC_CODE
            FROM    SERVICE_IMPLEMENTATION_TASKS SI, SERVICE_ORDERS SO,NUMBERS NU
            WHERE   SI.SEIT_SERO_ID=SO.SERO_ID
            AND     NU.NUMB_SERV_ID=SERO_SERV_ID
            AND     SEIT_ID = PI_SEIT_ID
            AND     NUMB_NUMS_ID IN (4);



      L_NUCC_CODE         NUMBERS.NUMB_NUCC_CODE%TYPE;


   BEGIN

      OPEN C_NUCC_CODE;

      FETCH C_NUCC_CODE
       INTO L_NUCC_CODE;

      CLOSE C_NUCC_CODE;

      RETURN L_NUCC_CODE;

   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END GET_OLDLATA;



 FUNCTION GET_OLDSDN (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_NUMB_TYPE (T_SEIT_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT SEOA_DEFAULTVALUE
            FROM SERVICE_ORDER_ATTRIBUTES
            WHERE   SEOA_SERO_ID=T_SEIT_ID
            AND     SEOA_NAME='SA_NUMBER_TYPE';

      CURSOR C_SERV_ID (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT DISTINCT(SERO_SERV_ID)
            FROM SERVICE_ORDERS
            WHERE SERO_ID=T_SERO_ID;

      CURSOR C_GET_P_NUMBER (T_SERV_ID SERVICE_ORDERS.SERO_SERV_ID%TYPE) IS

            SELECT  NUMB_NUCC_CODE,NUMB_NUMBER
            FROM    NUMBERS NU
            WHERE   NU.NUMB_SERV_ID=T_SERV_ID
            AND     NUMB_NUMS_ID IN (4);


        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_SERV_ID           SERVICE_ORDERS.SERO_SERV_ID%TYPE;
        V_NUMB_TYPE         VARCHAR2(20);

      L_NUCC_CODE         NUMBERS.NUMB_NUCC_CODE%TYPE;
      L_NUMB_NUMBER       NUMBERS.NUMB_NUMBER%TYPE;
      L_TEMP_CODE         VARCHAR2(10);
      L_OLDSDN            VARCHAR2(10);
      L_TEMP_APPEND       VARCHAR2(1);



   BEGIN

      OPEN C_SERO_ID;       FETCH C_SERO_ID
       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;


      OPEN C_NUMB_TYPE (V_SEIT_SERO_ID);
      FETCH C_NUMB_TYPE     INTO V_NUMB_TYPE;
      CLOSE C_NUMB_TYPE;

      OPEN C_SERV_ID (V_SEIT_SERO_ID);
      FETCH C_SERV_ID     INTO V_SERV_ID;
      CLOSE C_SERV_ID;

      OPEN C_GET_P_NUMBER (V_SERV_ID);
      FETCH C_GET_P_NUMBER INTO L_NUCC_CODE,L_NUMB_NUMBER;
      CLOSE C_GET_P_NUMBER;

        L_TEMP_APPEND:= '1';

      IF L_NUCC_CODE IS NOT NULL AND L_NUMB_NUMBER IS NOT NULL THEN

       L_TEMP_CODE := L_NUCC_CODE||L_NUMB_NUMBER;


        IF V_NUMB_TYPE='NON-FNR' THEN

              L_OLDSDN:=SUBSTR(L_TEMP_CODE,-7);

        ELSIF L_NUCC_CODE ='011' AND V_NUMB_TYPE='FNR' THEN

              L_OLDSDN:=SUBSTR(L_TEMP_CODE,-9);

        ELSIF L_NUCC_CODE !='011' AND V_NUMB_TYPE='FNR' THEN

              L_OLDSDN:=L_TEMP_APPEND||SUBSTR(L_TEMP_CODE,-9);
        ELSE

              L_OLDSDN:=NULL;

        END IF;


      END IF;


    RETURN L_OLDSDN;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_OLDSDN;
    FUNCTION GET_RMODEL (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


      CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_ORDT_TYPE (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT DISTINCT(SERO_ORDT_TYPE)
            FROM SERVICE_ORDERS
            WHERE SERO_ID=T_SERO_ID;

      CURSOR C_GET_FEATURES IS

            SELECT  SOFE_FEATURE_NAME,NVL(SOFE_DEFAULTVALUE,'N') SOFE_DEFAULTVALUE ,NVL(SOFE_PREV_VALUE,'N') SOFE_PREV_VALUE
            FROM    SERVICE_ORDER_FEATURES,SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID
            AND     SOFE_SERO_ID=SEIT_SERO_ID
            AND     SOFE_FEATURE_NAME IN ('SF_BAR_INCOMING_CALL','SF_BAR_OUTGOING_CALL','SF_IDD')
            ORDER BY SOFE_FEATURE_NAME;



        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_SERO_ORDT_TYPE    SERVICE_ORDERS.SERO_SERV_ID%TYPE;



      L_TEMP_CODE           VARCHAR2(100);
      L_RMODEL              VARCHAR2(2);
      L_BAR_IN_CALL             VARCHAR2(100);
      L_BAR_IN_CALL_CUR         VARCHAR2(1);
      L_BAR_IN_CALL_PRV         VARCHAR2(1);
      L_BAR_OUT_CALL            VARCHAR2(100);
      L_BAR_OUT_CALL_CUR        VARCHAR2(1);
      L_BAR_OUT_CALL_PRV        VARCHAR2(1);
      L_IDD                     VARCHAR2(100);
      L_IDD_CUR                 VARCHAR2(1);
      L_IDD_PRV                 VARCHAR2(1);



   BEGIN

      OPEN C_SERO_ID;       FETCH C_SERO_ID
       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;

      OPEN C_ORDT_TYPE (V_SEIT_SERO_ID);
      FETCH C_ORDT_TYPE     INTO V_SERO_ORDT_TYPE;
      CLOSE C_ORDT_TYPE;


       FOR REC_FEATURE IN C_GET_FEATURES LOOP





        BEGIN

            IF REC_FEATURE.SOFE_FEATURE_NAME ='SF_IDD' THEN

                L_IDD:=REC_FEATURE.SOFE_FEATURE_NAME;
                L_IDD_CUR:=REC_FEATURE.SOFE_DEFAULTVALUE;
                L_IDD_PRV:=REC_FEATURE.SOFE_PREV_VALUE;

            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_BAR_INCOMING_CALL' THEN

                L_BAR_IN_CALL:=REC_FEATURE.SOFE_FEATURE_NAME;
                L_BAR_IN_CALL_CUR:=REC_FEATURE.SOFE_DEFAULTVALUE;
                L_BAR_IN_CALL_PRV:=REC_FEATURE.SOFE_PREV_VALUE;


            ELSIF REC_FEATURE.SOFE_FEATURE_NAME ='SF_BAR_OUTGOING_CALL' THEN

                L_BAR_OUT_CALL:=REC_FEATURE.SOFE_FEATURE_NAME;
                L_BAR_OUT_CALL_CUR:=REC_FEATURE.SOFE_DEFAULTVALUE;
                L_BAR_OUT_CALL_PRV:=REC_FEATURE.SOFE_PREV_VALUE;


            END IF;

        END;


       END LOOP;




        /*IF  L_BAR_IN_CALL_CUR='Y' AND L_BAR_IN_CALL_PRV='N' AND L_BAR_OUT_CALL_CUR='N' THEN --'SF_BAR_INCOMING_CALL'

            L_RMODEL:=5; */

        IF L_BAR_OUT_CALL_CUR='Y' AND L_BAR_OUT_CALL_PRV='N' AND L_BAR_IN_CALL_CUR='N' THEN --'SF_BAR_OUTGOING_CALL'

            L_RMODEL:=3;

        ELSIF L_BAR_IN_CALL_CUR='N' AND L_BAR_IN_CALL_PRV='Y' AND L_BAR_OUT_CALL_CUR='Y' THEN --NOT 'SF_BAR_INCOMING_CALL'

            L_RMODEL:=3;

        /*ELSIF L_BAR_OUT_CALL_CUR='N' AND L_BAR_OUT_CALL_PRV='Y' AND L_BAR_IN_CALL_CUR='Y' THEN --NOT 'SF_BAR_OUTGOING_CALL'

            L_RMODEL:=5;

        ELSIF L_BAR_IN_CALL_CUR='Y' AND L_BAR_IN_CALL_PRV='N' AND L_BAR_OUT_CALL_CUR='N' THEN --NOT 'SF_BAR_OUTGOING_CALL'

            L_RMODEL:=5;*/
        ELSIF L_BAR_OUT_CALL_CUR='N' AND L_BAR_OUT_CALL_PRV='Y' AND L_BAR_IN_CALL_CUR='Y' AND L_IDD_CUR='N' THEN --NOT 'SF_BAR_OUTGOING_CALL'

            L_RMODEL:=5;

        ELSIF L_BAR_IN_CALL_CUR='Y' AND L_BAR_IN_CALL_PRV='N' AND L_BAR_OUT_CALL_CUR='N' AND L_IDD_CUR='N' THEN --NOT 'SF_BAR_OUTGOING_CALL'

            L_RMODEL:=5;

        ELSIF L_BAR_OUT_CALL_CUR='Y' AND L_BAR_OUT_CALL_PRV='N' AND L_BAR_IN_CALL_CUR='Y'
            AND L_BAR_IN_CALL_PRV='N'THEN --BOTH 'SF_BAR_OUTGOING_CALL'/'SF_BAR_INCOMING_CALL'

            L_RMODEL:=4;

        ELSIF L_IDD_CUR='Y' AND L_BAR_OUT_CALL_CUR='N'  AND L_BAR_IN_CALL_CUR='N' THEN --Reconnect without IDD

            L_RMODEL:=2;

        ELSIF L_IDD_CUR='Y' AND L_BAR_IN_CALL_CUR='Y' AND L_BAR_IN_CALL_PRV='N' THEN --Reconnect without IDD

            L_RMODEL:=6;

        ELSIF L_IDD_CUR='Y' AND L_BAR_IN_CALL_CUR='Y' AND L_BAR_IN_CALL_PRV='Y' THEN --Reconnect without IDD

            L_RMODEL:=6;

        ELSIF L_IDD_CUR='N' AND L_BAR_OUT_CALL_CUR='N' AND L_BAR_IN_CALL_CUR='N' THEN --Reconnect without IDD

            L_RMODEL:=1;

        ELSE

        L_RMODEL:=NULL;

        END IF;





    RETURN L_RMODEL;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_RMODEL;

----Edited 01-01-2015 -----
FUNCTION GET_SDN (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_NUMB_TYPE (T_SEIT_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT SEOA_DEFAULTVALUE
            FROM SERVICE_ORDER_ATTRIBUTES
            WHERE   SEOA_SERO_ID=T_SEIT_ID
            AND     SEOA_NAME='SA_NUMBER_TYPE';

      CURSOR C_SERV_ID (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT DISTINCT(SERO_SERV_ID)
            FROM SERVICE_ORDERS
            WHERE SERO_ID=T_SERO_ID;

      CURSOR C_GET_P_NUMBER (T_SERV_ID SERVICE_ORDERS.SERO_SERV_ID%TYPE) IS

            SELECT  NUMB_NUCC_CODE,NUMB_NUMBER
            FROM    NUMBERS NU
            WHERE   NU.NUMB_SERV_ID=T_SERV_ID
            AND     NUMB_NUMS_ID IN (3,4,6);
/* START ADDITON */
     CURSOR C_GET_SERO_ID_A IS
            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

     CURSOR C_GET_SERICE_TYPE ( IN_SERO_ID SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_ID%TYPE ) IS
            SELECT SERO_SERT_ABBREVIATION
            FROM SERVICE_ORDERS
            WHERE SERO_ID = IN_SERO_ID;

           CURSOR C_GET_P_NUMBER_A
      IS
            SELECT  NUMB_NUMBER
            FROM    SERVICE_IMPLEMENTATION_TASKS SI, SERVICE_ORDERS SO,NUMBERS NU
            WHERE   SI.SEIT_SERO_ID=SO.SERO_ID
            AND     NU.NUMB_SERV_ID=SERO_SERV_ID
            AND     SEIT_ID = PI_SEIT_ID;


        V_G_SERO_ID         SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_ID%TYPE;
        V_G_SERO_TYPE       SERVICE_ORDERS.SERO_SERT_ABBREVIATION%TYPE;
        L_NUMB_NUMBER_A     NUMBERS.NUMB_NUMBER%TYPE;
/* END ADDITION */

        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_SERV_ID           SERVICE_ORDERS.SERO_SERV_ID%TYPE;
        V_NUMB_TYPE         VARCHAR2(20);

      L_NUCC_CODE         NUMBERS.NUMB_NUCC_CODE%TYPE;
      L_NUMB_NUMBER       NUMBERS.NUMB_NUMBER%TYPE;
      L_TEMP_CODE         VARCHAR2(10);
      L_SDN               VARCHAR2(10);
      L_TEMP_APPEND       VARCHAR2(1);



   BEGIN

/* START ADDITON */
      OPEN C_GET_SERO_ID_A;
      FETCH C_GET_SERO_ID_A INTO V_G_SERO_ID;
      CLOSE C_GET_SERO_ID_A;

      OPEN C_GET_SERICE_TYPE (V_G_SERO_ID);
      FETCH C_GET_SERICE_TYPE INTO V_G_SERO_TYPE ;
      CLOSE C_GET_SERICE_TYPE ;

     IF V_G_SERO_TYPE = 'V-VOICE FTTH' THEN

       OPEN C_GET_P_NUMBER_A;
       FETCH C_GET_P_NUMBER_A INTO L_NUMB_NUMBER_A;
       CLOSE C_GET_P_NUMBER_A;


     RETURN L_NUMB_NUMBER_A;

     ELSE
/* END ADDITION */


      OPEN C_SERO_ID;       FETCH C_SERO_ID
       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;

      OPEN C_NUMB_TYPE (V_SEIT_SERO_ID);
      FETCH C_NUMB_TYPE     INTO V_NUMB_TYPE;
      CLOSE C_NUMB_TYPE;

      OPEN C_SERV_ID (V_SEIT_SERO_ID);
      FETCH C_SERV_ID     INTO V_SERV_ID;
      CLOSE C_SERV_ID;

      OPEN C_GET_P_NUMBER (V_SERV_ID);
      FETCH C_GET_P_NUMBER INTO L_NUCC_CODE,L_NUMB_NUMBER;
      CLOSE C_GET_P_NUMBER;

        L_TEMP_APPEND:= '1';

      IF L_NUCC_CODE IS NOT NULL AND L_NUMB_NUMBER IS NOT NULL THEN

       L_TEMP_CODE := L_NUCC_CODE||L_NUMB_NUMBER;


        IF V_NUMB_TYPE='NON-FNR' THEN

              L_SDN:=SUBSTR(L_TEMP_CODE,-7);

        ELSIF L_NUCC_CODE ='011' AND V_NUMB_TYPE='FNR' THEN

              L_SDN:=SUBSTR(L_TEMP_CODE,-9);

        ELSIF L_NUCC_CODE !='011' AND V_NUMB_TYPE='FNR' THEN

              L_SDN:=L_TEMP_APPEND||SUBSTR(L_TEMP_CODE,-9);
        ELSE

              L_SDN:=NULL;

        END IF;


      END IF;


    RETURN L_SDN;

    END IF;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_SDN;
----Edited 01-01-2015 -----


FUNCTION GET_SDN1 (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS



      CURSOR C_GET_P_NUMBER
      IS
            SELECT  NUMB_NUCC_CODE,NUMB_NUMBER
            FROM    SERVICE_IMPLEMENTATION_TASKS SI, SERVICE_ORDERS SO,NUMBERS NU
            WHERE   SI.SEIT_SERO_ID=SO.SERO_ID
            AND     NU.NUMB_SERV_ID=SERO_SERV_ID
            AND     SEIT_ID = PI_SEIT_ID
            AND     NUMB_NUMS_ID IN (4);



      L_NUCC_CODE         NUMBERS.NUMB_NUCC_CODE%TYPE;
      L_NUMB_NUMBER       NUMBERS.NUMB_NUMBER%TYPE;
      L_TEMP_CODE         VARCHAR2(10);
      L_SDN1              VARCHAR2(7);



   BEGIN


      OPEN C_GET_P_NUMBER;       FETCH C_GET_P_NUMBER
       INTO L_NUCC_CODE,L_NUMB_NUMBER;
      CLOSE C_GET_P_NUMBER;

      IF L_NUCC_CODE IS NOT NULL AND L_NUMB_NUMBER IS NOT NULL THEN

       L_TEMP_CODE := L_NUCC_CODE||L_NUMB_NUMBER;

      END IF;

      L_SDN1:=SUBSTR(L_TEMP_CODE,-7);

    RETURN L_SDN1;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_SDN1;


FUNCTION GET_SDN2 (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS



      CURSOR C_GET_P_NUMBER
      IS
            SELECT  NUMB_NUCC_CODE,NUMB_NUMBER
            FROM    SERVICE_IMPLEMENTATION_TASKS SI, SERVICE_ORDERS SO,NUMBERS NU
            WHERE   SI.SEIT_SERO_ID=SO.SERO_ID
            AND     NU.NUMB_SERV_ID=SERO_SERV_ID
            AND     SEIT_ID = PI_SEIT_ID
            AND     NUMB_NUMS_ID IN (4);



      L_NUCC_CODE         NUMBERS.NUMB_NUCC_CODE%TYPE;
      L_NUMB_NUMBER       NUMBERS.NUMB_NUMBER%TYPE;
      L_TEMP_CODE         VARCHAR2(10);
      L_SDN2              VARCHAR2(10);
      L_TEMP_APPEND       VARCHAR2(1);



   BEGIN


      OPEN C_GET_P_NUMBER;       FETCH C_GET_P_NUMBER
       INTO L_NUCC_CODE,L_NUMB_NUMBER;
      CLOSE C_GET_P_NUMBER;

        L_TEMP_APPEND:= '1';

      IF L_NUCC_CODE IS NOT NULL AND L_NUMB_NUMBER IS NOT NULL THEN

       L_TEMP_CODE := L_NUCC_CODE||L_NUMB_NUMBER;

        IF L_NUCC_CODE ='011' THEN

              L_SDN2:=SUBSTR(L_TEMP_CODE,-9);
        ELSE
              L_SDN2:=L_TEMP_APPEND||SUBSTR(L_TEMP_CODE,-9);

        END IF;


      END IF;


    RETURN L_SDN2;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_SDN2;

 FUNCTION GET_SDN1_NEW (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS



      CURSOR C_GET_P_NUMBER
      IS
            SELECT  NUMB_NUCC_CODE,NUMB_NUMBER
            FROM    SERVICE_IMPLEMENTATION_TASKS SI, SERVICE_ORDERS SO,NUMBERS NU
            WHERE   SI.SEIT_SERO_ID=SO.SERO_ID
            AND     NU.NUMB_SERV_ID=SERO_SERV_ID
            AND     SEIT_ID = PI_SEIT_ID
            AND     NUMB_NUMS_ID IN (3,6);



      L_NUCC_CODE         NUMBERS.NUMB_NUCC_CODE%TYPE;
      L_NUMB_NUMBER       NUMBERS.NUMB_NUMBER%TYPE;
      L_TEMP_CODE         VARCHAR2(10);
      L_SDN1              VARCHAR2(7);



   BEGIN


      OPEN C_GET_P_NUMBER;       FETCH C_GET_P_NUMBER
       INTO L_NUCC_CODE,L_NUMB_NUMBER;
      CLOSE C_GET_P_NUMBER;

      IF L_NUCC_CODE IS NOT NULL AND L_NUMB_NUMBER IS NOT NULL THEN

       L_TEMP_CODE := L_NUCC_CODE||L_NUMB_NUMBER;

      END IF;

      L_SDN1:=SUBSTR(L_TEMP_CODE,-7);

    RETURN L_SDN1;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_SDN1_NEW;


 FUNCTION GET_SDN2_NEW (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS



      CURSOR C_GET_P_NUMBER
      IS
            SELECT  NUMB_NUCC_CODE,NUMB_NUMBER
            FROM    SERVICE_IMPLEMENTATION_TASKS SI, SERVICE_ORDERS SO,NUMBERS NU
            WHERE   SI.SEIT_SERO_ID=SO.SERO_ID
            AND     NU.NUMB_SERV_ID=SERO_SERV_ID
            AND     SEIT_ID = PI_SEIT_ID
            AND     NUMB_NUMS_ID IN (3,6);



      L_NUCC_CODE         NUMBERS.NUMB_NUCC_CODE%TYPE;
      L_NUMB_NUMBER       NUMBERS.NUMB_NUMBER%TYPE;
      L_TEMP_CODE         VARCHAR2(10);
      L_SDN2              VARCHAR2(10);
      L_TEMP_APPEND       VARCHAR2(1);



   BEGIN


      OPEN C_GET_P_NUMBER;       FETCH C_GET_P_NUMBER
       INTO L_NUCC_CODE,L_NUMB_NUMBER;
      CLOSE C_GET_P_NUMBER;

        L_TEMP_APPEND:= '1';

      IF L_NUCC_CODE IS NOT NULL AND L_NUMB_NUMBER IS NOT NULL THEN

       L_TEMP_CODE := L_NUCC_CODE||L_NUMB_NUMBER;

        IF L_NUCC_CODE ='011' THEN

              L_SDN2:=SUBSTR(L_TEMP_CODE,-9);
        ELSE
              L_SDN2:=L_TEMP_APPEND||SUBSTR(L_TEMP_CODE,-9);

        END IF;


      END IF;


    RETURN L_SDN2;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_SDN2_NEW;

---- Edited 17-01-2016 Dinesh ----
FUNCTION GET_UNIT (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_GET_P_NUMBER (V_SEIT_SERO_ID SERVICE_ORDERS.SERO_CIRT_NAME%TYPE) IS

            SELECT DISTINCT(SERO_CIRT_NAME),SERO_SERT_ABBREVIATION
            FROM    SERVICE_ORDERS, CIRCUITS
            WHERE   CIRT_STATUS !='PENDINGDELETE'
            AND     SERO_CIRT_NAME = CIRT_NAME
            AND     SERO_ID = V_SEIT_SERO_ID;

      CURSOR C_GET_POTSOUT (V_SEIT_SERO_ID SERVICE_ORDERS.SERO_CIRT_NAME%TYPE) IS
      
            SELECT  PO.PORT_CARD_SLOT
            FROM    PORTS PO,PORT_LINKS PL,PORT_LINK_PORTS PLP
            WHERE   PO.PORT_ID=PLP.POLP_PORT_ID
            AND     PL.PORL_ID=PLP.POLP_PORL_ID
            AND     PL.PORL_CIRT_NAME = V_SEIT_SERO_ID
            AND     PO.PORT_USAGE='SERVICE_SWITCHING_POINT'
            AND     SUBSTR(PO.PORT_NAME,1,8)='POTS-OUT';

      CURSOR C_GET_POTSIN (V_SEIT_SERO_ID SERVICE_ORDERS.SERO_CIRT_NAME%TYPE) IS
      
            SELECT  PO.PORT_CARD_SLOT
            FROM    PORTS PO,PORT_LINKS PL,PORT_LINK_PORTS PLP
            WHERE   PO.PORT_ID=PLP.POLP_PORT_ID
            AND     PL.PORL_ID=PLP.POLP_PORL_ID
            AND     PL.PORL_CIRT_NAME = V_SEIT_SERO_ID
            AND     PO.PORT_USAGE='SERVICE_SWITCHING_POINT'
            AND     SUBSTR(PO.PORT_NAME,1,7)='POTS-IN';

        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_CRT_ID            SERVICE_ORDERS.SERO_SERV_ID%TYPE;
        V_SERO_TYPE         SERVICE_ORDERS.SERO_SERT_ABBREVIATION%TYPE;
        V_CIRCUIT_ID        CIRCUITS.CIRT_NAME%TYPE;
        V_PORT_CARD_SLOT    PORTS.PORT_CARD_SLOT%TYPE;


      L_TEMP_CODE         VARCHAR2(10);
      L_UNIT              VARCHAR2(3);


   BEGIN

      OPEN C_SERO_ID;       FETCH C_SERO_ID
       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;

      OPEN C_GET_P_NUMBER (V_SEIT_SERO_ID);
      FETCH C_GET_P_NUMBER INTO V_CIRCUIT_ID, V_SERO_TYPE;
      CLOSE C_GET_P_NUMBER;

      IF V_SERO_TYPE ='PSTN' THEN

          OPEN C_GET_POTSIN (V_CIRCUIT_ID);
          FETCH C_GET_POTSIN INTO V_PORT_CARD_SLOT;
          CLOSE C_GET_POTSIN;

      ELSE

          OPEN C_GET_POTSOUT (V_CIRCUIT_ID);
          FETCH C_GET_POTSOUT INTO V_PORT_CARD_SLOT;
          CLOSE C_GET_POTSOUT;

      END IF;

      
      IF V_PORT_CARD_SLOT IS NULL THEN

          OPEN C_GET_POTSOUT (V_CIRCUIT_ID);
          FETCH C_GET_POTSOUT INTO V_PORT_CARD_SLOT;
          CLOSE C_GET_POTSOUT;

      ELSE

       V_PORT_CARD_SLOT:= V_PORT_CARD_SLOT;   

      END IF;


      IF V_PORT_CARD_SLOT IS NOT NULL  THEN

       L_TEMP_CODE :=  SUBSTR(V_PORT_CARD_SLOT,2,4);

       L_UNIT:=REPLACE(L_TEMP_CODE,'-',NULL);

      ELSE

      L_UNIT:=NULL;

      END IF;


    RETURN L_UNIT;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_UNIT;
---- Edited 17-01-2016 Dinesh ----

---- Edited 17-01-2016 Dinesh ----
 FUNCTION GET_SUBUNIT (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_GET_P_NUMBER (V_SEIT_SERO_ID SERVICE_ORDERS.SERO_CIRT_NAME%TYPE) IS

            SELECT DISTINCT(SERO_CIRT_NAME),SERO_SERT_ABBREVIATION
            FROM    SERVICE_ORDERS, CIRCUITS
            WHERE   CIRT_STATUS !='PENDINGDELETE'
            AND     SERO_CIRT_NAME = CIRT_NAME
            AND     SERO_ID = V_SEIT_SERO_ID;

      CURSOR C_GET_POTSOUT (V_SEIT_SERO_ID SERVICE_ORDERS.SERO_CIRT_NAME%TYPE) IS
      
            SELECT  PO.PORT_CARD_SLOT
            FROM    PORTS PO,PORT_LINKS PL,PORT_LINK_PORTS PLP
            WHERE   PO.PORT_ID=PLP.POLP_PORT_ID
            AND     PL.PORL_ID=PLP.POLP_PORL_ID
            AND     PL.PORL_CIRT_NAME = V_SEIT_SERO_ID
            AND     PO.PORT_USAGE ='SERVICE_SWITCHING_POINT'
            AND     SUBSTR(PO.PORT_NAME,1,8) = 'POTS-OUT';

      CURSOR C_GET_POTSIN (V_SEIT_SERO_ID SERVICE_ORDERS.SERO_CIRT_NAME%TYPE) IS
      
            SELECT  PO.PORT_CARD_SLOT
            FROM    PORTS PO,PORT_LINKS PL,PORT_LINK_PORTS PLP
            WHERE   PO.PORT_ID=PLP.POLP_PORT_ID
            AND     PL.PORL_ID=PLP.POLP_PORL_ID
            AND     PL.PORL_CIRT_NAME = V_SEIT_SERO_ID
            AND     PO.PORT_USAGE = 'SERVICE_SWITCHING_POINT'
            AND     SUBSTR(PO.PORT_NAME,1,7) = 'POTS-IN';


        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_CRT_ID            SERVICE_ORDERS.SERO_SERV_ID%TYPE;
        V_SERO_TYPE         SERVICE_ORDERS.SERO_SERT_ABBREVIATION%TYPE;
        V_CIRCUIT_ID        CIRCUITS.CIRT_NAME%TYPE;
        V_PORT_CARD_SLOT    PORTS.PORT_CARD_SLOT%TYPE;


      L_TEMP_CODE         VARCHAR2(10);
      L_SUBUNIT         VARCHAR2(2);



   BEGIN

      OPEN C_SERO_ID;       
      FETCH C_SERO_ID INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;

      OPEN C_GET_P_NUMBER (V_SEIT_SERO_ID);
      FETCH C_GET_P_NUMBER INTO V_CIRCUIT_ID, V_SERO_TYPE;
      CLOSE C_GET_P_NUMBER;

      IF V_SERO_TYPE = 'PSTN' THEN

          OPEN C_GET_POTSIN (V_CIRCUIT_ID);
          FETCH C_GET_POTSIN INTO V_PORT_CARD_SLOT;
          CLOSE C_GET_POTSIN;

      ELSE

          OPEN C_GET_POTSOUT (V_CIRCUIT_ID);
          FETCH C_GET_POTSOUT INTO V_PORT_CARD_SLOT;
          CLOSE C_GET_POTSOUT;

      END IF;
      
      
      IF V_PORT_CARD_SLOT IS NULL THEN

          OPEN C_GET_POTSOUT (V_CIRCUIT_ID);
          FETCH C_GET_POTSOUT INTO V_PORT_CARD_SLOT;
          CLOSE C_GET_POTSOUT;

      ELSE

       V_PORT_CARD_SLOT:= V_PORT_CARD_SLOT;   

      END IF;
      

      IF V_PORT_CARD_SLOT IS NOT NULL  THEN

       L_TEMP_CODE :=  SUBSTR(V_PORT_CARD_SLOT,-2);

       L_SUBUNIT:=L_TEMP_CODE;

      ELSE

      L_SUBUNIT:=NULL;

      END IF;


    RETURN L_SUBUNIT;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_SUBUNIT;
---- Edited 17-01-2016 Dinesh ----

 FUNCTION GET_TIDNAME (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_SERV_ID (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT DISTINCT(SERO_CIRT_NAME),SERO_SERT_ABBREVIATION
            FROM SERVICE_ORDERS
            WHERE SERO_ID=T_SERO_ID;

      CURSOR C_GET_P_NUMBER (T_CRT_ID SERVICE_ORDERS.SERO_CIRT_NAME%TYPE) IS

            SELECT  MAX(CIRT_NAME)
            FROM    CIRCUITS
            WHERE   CIRT_NAME  =T_CRT_ID
            AND     CIRT_STATUS !='PENDINGDELETE';


      CURSOR C_GET_TIDNAME (T_CRT_ID SERVICE_ORDERS.SERO_CIRT_NAME%TYPE) IS

            SELECT  PO.PORT_NAME,PO.PORT_CARD_SLOT
            FROM    PORTS PO,PORT_LINKS PL,PORT_LINK_PORTS PLP
            WHERE   PO.PORT_ID=PLP.POLP_PORT_ID
            AND     PL.PORL_ID=PLP.POLP_PORL_ID
            AND     PL.PORL_CIRT_NAME= T_CRT_ID
            AND     PO.PORT_USAGE='SERVICE_SWITCHING_POINT';

        CURSOR C_GET_TIDNAME_PSTN (T_CRT_ID SERVICE_ORDERS.SERO_CIRT_NAME%TYPE) IS

            SELECT  PO.PORT_NAME,PO.PORT_CARD_SLOT
            FROM    PORTS PO,PORT_LINKS PL,PORT_LINK_PORTS PLP
            WHERE   PO.PORT_ID=PLP.POLP_PORT_ID
            AND     PL.PORL_ID=PLP.POLP_PORL_ID
            AND     PL.PORL_CIRT_NAME= T_CRT_ID
            AND     PO.PORT_USAGE='SERVICE_SWITCHING_POINT'
            AND     ((SUBSTR(PO.PORT_NAME,1,7)='POTS-IN') OR (SUBSTR(PO.PORT_NAME,1,8)='POTS-OUT'));



        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_CRT_ID            SERVICE_ORDERS.SERO_SERV_ID%TYPE;
        V_SERO_TYPE         SERVICE_ORDERS.SERO_SERT_ABBREVIATION%TYPE;
        V_CIRCUIT_ID        CIRCUITS.CIRT_NAME%TYPE;
        V_PORT_CARD_SLOT    PORTS.PORT_CARD_SLOT%TYPE;
        V_PORT_NAME         PORTS.PORT_NAME%TYPE;


      L_TEMP_CODE         VARCHAR2(20);
      L_TIDNAME           VARCHAR2(20);



   BEGIN

      OPEN C_SERO_ID;       FETCH C_SERO_ID
       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;

      OPEN C_SERV_ID (V_SEIT_SERO_ID);
      FETCH C_SERV_ID     INTO V_CRT_ID,V_SERO_TYPE;
      CLOSE C_SERV_ID;

      OPEN C_GET_P_NUMBER (V_CRT_ID);
      FETCH C_GET_P_NUMBER INTO V_CIRCUIT_ID;
      CLOSE C_GET_P_NUMBER;

      IF (V_SERO_TYPE='PSTN' OR V_SERO_TYPE='CCB') THEN

          OPEN C_GET_TIDNAME_PSTN (V_CRT_ID);
          FETCH C_GET_TIDNAME_PSTN INTO V_PORT_NAME,V_PORT_CARD_SLOT;
          CLOSE C_GET_TIDNAME_PSTN;

      ELSE

          OPEN C_GET_TIDNAME (V_CRT_ID);
          FETCH C_GET_TIDNAME INTO V_PORT_NAME,V_PORT_CARD_SLOT;
          CLOSE C_GET_TIDNAME;

      END IF;



      IF V_PORT_CARD_SLOT IS NOT NULL AND V_PORT_NAME IS NOT NULL THEN

       L_TEMP_CODE :=  REPLACE(V_PORT_CARD_SLOT,'-',NULL);


       L_TIDNAME:=L_TEMP_CODE||SUBSTR(V_PORT_NAME,-2);

      ELSE

       L_TIDNAME:=NULL;

      END IF;

    RETURN L_TIDNAME;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_TIDNAME;

---- Janaka 2013 09 16 ****SOFTSWITCH****

FUNCTION GET_CODE1_OLD (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


      CURSOR C_GET_P_NUMBER
      IS
            SELECT  NUMB_NUCC_CODE,NUMB_NUMBER
            FROM    SERVICE_IMPLEMENTATION_TASKS SI, SERVICE_ORDERS SO,NUMBERS NU
            WHERE   SI.SEIT_SERO_ID=SO.SERO_ID
            AND     NU.NUMB_SERV_ID=SERO_SERV_ID
            AND     SEIT_ID = PI_SEIT_ID
            AND     NUMB_NUMS_ID IN (4);



      L_NUCC_CODE         NUMBERS.NUMB_NUCC_CODE%TYPE;
      L_NUMB_NUMBER       NUMBERS.NUMB_NUMBER%TYPE;
      L_TEMP_CODE         VARCHAR2(10);
      L_CODE1             VARCHAR2(4);


   BEGIN

      OPEN C_GET_P_NUMBER;

      FETCH C_GET_P_NUMBER
       INTO L_NUCC_CODE,L_NUMB_NUMBER;

      CLOSE C_GET_P_NUMBER;

      IF L_NUCC_CODE IS NOT NULL AND  L_NUMB_NUMBER IS NOT NULL THEN

        L_TEMP_CODE:=L_NUCC_CODE||L_NUMB_NUMBER;

      END IF;

      L_CODE1:=SUBSTR(L_TEMP_CODE,4,4);


      RETURN L_CODE1;

   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END GET_CODE1_OLD;



FUNCTION GET_CODE2_OLD (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


      CURSOR C_GET_P_NUMBER
      IS
            SELECT  NUMB_NUCC_CODE,NUMB_NUMBER
            FROM    SERVICE_IMPLEMENTATION_TASKS SI, SERVICE_ORDERS SO,NUMBERS NU
            WHERE   SI.SEIT_SERO_ID=SO.SERO_ID
            AND     NU.NUMB_SERV_ID=SERO_SERV_ID
            AND     SEIT_ID = PI_SEIT_ID
            AND     NUMB_NUMS_ID IN (4);



      L_NUCC_CODE         NUMBERS.NUMB_NUCC_CODE%TYPE;
      L_NUMB_NUMBER       NUMBERS.NUMB_NUMBER%TYPE;
      L_TEMP_CODE         VARCHAR2(10);
      L_CODE2             VARCHAR2(3);


   BEGIN

      OPEN C_GET_P_NUMBER;

      FETCH C_GET_P_NUMBER
       INTO L_NUCC_CODE,L_NUMB_NUMBER;

      CLOSE C_GET_P_NUMBER;

      IF L_NUCC_CODE IS NOT NULL AND  L_NUMB_NUMBER IS NOT NULL THEN

        L_TEMP_CODE:=L_NUCC_CODE||L_NUMB_NUMBER;

      END IF;

      L_CODE2:=SUBSTR(L_TEMP_CODE,4,3);


      RETURN L_CODE2;

   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END GET_CODE2_OLD;



FUNCTION GET_CODE3_OLD (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


      CURSOR C_GET_P_NUMBER
      IS
            SELECT  NUMB_NUCC_CODE,NUMB_NUMBER
            FROM    SERVICE_IMPLEMENTATION_TASKS SI, SERVICE_ORDERS SO,NUMBERS NU
            WHERE   SI.SEIT_SERO_ID=SO.SERO_ID
            AND     NU.NUMB_SERV_ID=SERO_SERV_ID
            AND     SEIT_ID = PI_SEIT_ID
            AND     NUMB_NUMS_ID IN (4);



      L_NUCC_CODE         NUMBERS.NUMB_NUCC_CODE%TYPE;
      L_NUMB_NUMBER       NUMBERS.NUMB_NUMBER%TYPE;
      L_TEMP_CODE         VARCHAR2(10);
      L_TEMP_APPEND       VARCHAR2(1);
      L_CODE3             VARCHAR2(7);


   BEGIN

      OPEN C_GET_P_NUMBER;

      FETCH C_GET_P_NUMBER
      INTO L_NUCC_CODE,L_NUMB_NUMBER;

      CLOSE C_GET_P_NUMBER;

      L_TEMP_APPEND:= '1';

      IF L_NUCC_CODE IS NOT NULL AND  L_NUMB_NUMBER IS NOT NULL THEN

        L_TEMP_CODE:=L_NUCC_CODE||L_NUMB_NUMBER;

        IF L_NUCC_CODE ='011'  THEN

            L_CODE3:=SUBSTR (L_TEMP_CODE,2,6);

        ELSE

            L_CODE3:=L_TEMP_APPEND||SUBSTR (L_TEMP_CODE,2,6);

        END IF;


      END IF;

   RETURN L_CODE3;


   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END GET_CODE3_OLD;



FUNCTION GET_CODE4_OLD (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


      CURSOR C_GET_P_NUMBER
      IS
            SELECT  NUMB_NUCC_CODE,NUMB_NUMBER
            FROM    SERVICE_IMPLEMENTATION_TASKS SI, SERVICE_ORDERS SO,NUMBERS NU
            WHERE   SI.SEIT_SERO_ID=SO.SERO_ID
            AND     NU.NUMB_SERV_ID=SERO_SERV_ID
            AND     SEIT_ID = PI_SEIT_ID
            AND     NUMB_NUMS_ID IN (4);



      L_NUCC_CODE         NUMBERS.NUMB_NUCC_CODE%TYPE;
      L_NUMB_NUMBER       NUMBERS.NUMB_NUMBER%TYPE;
      L_TEMP_CODE         VARCHAR2(10);
      L_TEMP_APPEND       VARCHAR2(1);
      L_CODE4            VARCHAR2(7);


   BEGIN

      OPEN C_GET_P_NUMBER;

      FETCH C_GET_P_NUMBER
      INTO L_NUCC_CODE,L_NUMB_NUMBER;

      CLOSE C_GET_P_NUMBER;

      L_TEMP_APPEND:= '1';

      IF L_NUCC_CODE IS NOT NULL AND  L_NUMB_NUMBER IS NOT NULL THEN

        L_TEMP_CODE:=L_NUCC_CODE||L_NUMB_NUMBER;

        IF L_NUCC_CODE ='011'  THEN

            L_CODE4:=SUBSTR (L_TEMP_CODE,2,5);

        ELSE

            L_CODE4:=L_TEMP_APPEND||SUBSTR (L_TEMP_CODE,2,5);

        END IF;


      END IF;

   RETURN L_CODE4;


   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END GET_CODE4_OLD;

---- Janaka 2013 09 16 ****SOFTSWITCH****

---- Dinesh 16 09 2013 -------
FUNCTION GET_DN_MOD (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_NUMB_TYPE (T_SEIT_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT SEOA_DEFAULTVALUE
            FROM SERVICE_ORDER_ATTRIBUTES
            WHERE   SEOA_SERO_ID=T_SEIT_ID
            AND     SEOA_NAME='SA_NUMBER_TYPE';

      CURSOR C_SERV_ID (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT DISTINCT(SERO_SERV_ID)
            FROM SERVICE_ORDERS
            WHERE SERO_ID=T_SERO_ID;

      CURSOR C_GET_P_NUMBER (T_SERV_ID SERVICE_ORDERS.SERO_SERV_ID%TYPE) IS

            SELECT  NUMB_NUCC_CODE,NUMB_NUMBER
            FROM    NUMBERS NU
            WHERE   NU.NUMB_SERV_ID=T_SERV_ID
            AND     NUMB_NUMS_ID IN (4);


        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_SERV_ID           SERVICE_ORDERS.SERO_SERV_ID%TYPE;
        V_NUMB_TYPE         VARCHAR2(20);

      L_NUCC_CODE         NUMBERS.NUMB_NUCC_CODE%TYPE;
      L_NUMB_NUMBER       NUMBERS.NUMB_NUMBER%TYPE;
      L_TEMP_CODE         VARCHAR2(10);
      L_OLDSDN            VARCHAR2(10);
      L_TEMP_APPEND       VARCHAR2(1);



   BEGIN

      OPEN C_SERO_ID;       FETCH C_SERO_ID
       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;


      OPEN C_NUMB_TYPE (V_SEIT_SERO_ID);
      FETCH C_NUMB_TYPE     INTO V_NUMB_TYPE;
      CLOSE C_NUMB_TYPE;

      OPEN C_SERV_ID (V_SEIT_SERO_ID);
      FETCH C_SERV_ID     INTO V_SERV_ID;
      CLOSE C_SERV_ID;

      OPEN C_GET_P_NUMBER (V_SERV_ID);
      FETCH C_GET_P_NUMBER INTO L_NUCC_CODE,L_NUMB_NUMBER;
      CLOSE C_GET_P_NUMBER;

        L_TEMP_APPEND:= '1';

      IF L_NUCC_CODE IS NOT NULL AND L_NUMB_NUMBER IS NOT NULL THEN

       L_TEMP_CODE := L_NUCC_CODE||L_NUMB_NUMBER;


        IF V_NUMB_TYPE='NON-FNR' THEN

              L_OLDSDN:=SUBSTR(L_TEMP_CODE,-7);

        ELSIF L_NUCC_CODE ='011' AND V_NUMB_TYPE='FNR' THEN

              L_OLDSDN:=SUBSTR(L_TEMP_CODE,-9);

        ELSIF L_NUCC_CODE !='011' AND V_NUMB_TYPE='FNR' THEN

              L_OLDSDN:=SUBSTR(L_TEMP_CODE,-9);
        ELSE

              L_OLDSDN:=NULL;

        END IF;


      END IF;


    RETURN L_OLDSDN;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_DN_MOD;

---- Janaka 2013 07 30 ****ZTE_ADSL****

FUNCTION GET_PID (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_SERV_ID (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT DISTINCT(SERO_CIRT_NAME),SERO_SERT_ABBREVIATION
            FROM SERVICE_ORDERS
            WHERE SERO_ID=T_SERO_ID;

      CURSOR C_GET_P_NUMBER (T_CRT_ID SERVICE_ORDERS.SERO_CIRT_NAME%TYPE) IS

            SELECT  MAX(CIRT_NAME)
            FROM    CIRCUITS
            WHERE   CIRT_NAME  =T_CRT_ID
            AND     CIRT_STATUS !='PENDINGDELETE';

      CURSOR C_GET_TIDNAME (T_CRT_ID SERVICE_ORDERS.SERO_CIRT_NAME%TYPE) IS

            SELECT  PO.PORT_NAME,PO.PORT_CARD_SLOT
            FROM    PORTS PO,PORT_LINKS PL,PORT_LINK_PORTS PLP
            WHERE   PO.PORT_ID=PLP.POLP_PORT_ID
            AND     PL.PORL_ID=PLP.POLP_PORL_ID
            AND     PL.PORL_CIRT_NAME= T_CRT_ID
            AND     PO.PORT_USAGE='SERVICE_SWITCHING_POINT';




        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_CRT_ID            SERVICE_ORDERS.SERO_SERV_ID%TYPE;
        V_SERO_TYPE         SERVICE_ORDERS.SERO_SERT_ABBREVIATION%TYPE;
        V_CIRCUIT_ID        CIRCUITS.CIRT_NAME%TYPE;
        V_PORT_CARD_SLOT    PORTS.PORT_CARD_SLOT%TYPE;
        V_PORT_NAME         PORTS.PORT_NAME%TYPE;


      L_TEMP_CODE         VARCHAR2(20);
      L_TIDNAME           VARCHAR2(20);



   BEGIN

      OPEN C_SERO_ID;       FETCH C_SERO_ID
       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;

      OPEN C_SERV_ID (V_SEIT_SERO_ID);
      FETCH C_SERV_ID     INTO V_CRT_ID,V_SERO_TYPE;
      CLOSE C_SERV_ID;

      OPEN C_GET_P_NUMBER (V_CRT_ID);
      FETCH C_GET_P_NUMBER INTO V_CIRCUIT_ID;
      CLOSE C_GET_P_NUMBER;


      OPEN C_GET_TIDNAME (V_CRT_ID);
      FETCH C_GET_TIDNAME INTO V_PORT_NAME,V_PORT_CARD_SLOT;
      CLOSE C_GET_TIDNAME;


      IF V_PORT_CARD_SLOT IS NOT NULL AND V_PORT_NAME IS NOT NULL THEN

       IF SUBSTR(V_PORT_CARD_SLOT,1,1) = 'Z' THEN

         L_TEMP_CODE := SUBSTR(V_PORT_CARD_SLOT,INSTR(V_PORT_CARD_SLOT,'-')-1,2) || SUBSTR(V_PORT_CARD_SLOT,INSTR(V_PORT_CARD_SLOT,'-',1,2)-1,2) || SUBSTR(V_PORT_CARD_SLOT,-2) || '-';

       ELSIF SUBSTR(V_PORT_CARD_SLOT,1,1) = 'P' THEN

         L_TEMP_CODE := REPLACE(SUBSTR(V_PORT_CARD_SLOT,4),'.','-')|| '-';

       END IF;


       L_TIDNAME:=L_TEMP_CODE||SUBSTR(V_PORT_NAME,-2);

      ELSE

       L_TIDNAME:=NULL;

      END IF;

    RETURN L_TIDNAME;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_PID;



 FUNCTION GET_DNAME (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_SERV_ID (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT DISTINCT(SERO_CIRT_NAME),SERO_SERT_ABBREVIATION
            FROM SERVICE_ORDERS
            WHERE SERO_ID=T_SERO_ID;

      CURSOR C_GET_P_NUMBER (T_CRT_ID SERVICE_ORDERS.SERO_CIRT_NAME%TYPE) IS

            SELECT  MAX(CIRT_NAME)
            FROM    CIRCUITS
            WHERE   CIRT_NAME  =T_CRT_ID
            AND     CIRT_STATUS !='PENDINGDELETE';


      CURSOR C_GET_CIRCUITNO (T_CRT_ID SERVICE_ORDERS.SERO_CIRT_NAME%TYPE) IS

            SELECT  PO.PORT_EQUP_ID
            FROM    PORTS PO,PORT_LINKS PL,PORT_LINK_PORTS PLP
            WHERE   PO.PORT_ID=PLP.POLP_PORT_ID
            AND     PL.PORL_ID=PLP.POLP_PORL_ID
            AND     PL.PORL_CIRT_NAME= T_CRT_ID
            AND     PO.PORT_USAGE='SERVICE_SWITCHING_POINT';


      CURSOR C_GET_EQ_DET (T_EQP_ID EQUIPMENT.EQUP_ID%TYPE) IS

            SELECT EQUP_LOCN_TTNAME, EQUP_EQUM_MODEL,EQUP_INDEX
            FROM EQUIPMENT
            WHERE EQUP_EQUM_MODEL IN
            ('MSAG5200','MSAG5200-ISL','ZXDSL9806H','ZXDSL9806H-ISL','C300M','C350M','MA5600T','MA5603T')
            AND   EQUP_ID=T_EQP_ID;

        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_CRT_ID            SERVICE_ORDERS.SERO_SERV_ID%TYPE;
        V_SERO_TYPE         SERVICE_ORDERS.SERO_SERT_ABBREVIATION%TYPE;
        V_CIRCUIT_ID        CIRCUITS.CIRT_NAME%TYPE;
        V_PORT_EQUP_ID      PORTS.PORT_EQUP_ID%TYPE;

      L_TEMP_CODE         VARCHAR2(100);
      L_EQUP_LOCN_TTNAME            VARCHAR2(100);
      L_EQUP_EQUM_MODEL             VARCHAR2(100);
      L_EQUP_INDEX                  VARCHAR2(100);
      L_EQ_L_TNAME            VARCHAR2(20);
      L_EQ_E_MODEL            VARCHAR2(20);
      L_EQ_INDEX              VARCHAR2(20);



   BEGIN

      OPEN C_SERO_ID;       FETCH C_SERO_ID
       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;

      OPEN C_SERV_ID (V_SEIT_SERO_ID);
      FETCH C_SERV_ID     INTO V_CRT_ID,V_SERO_TYPE;
      CLOSE C_SERV_ID;

      OPEN C_GET_P_NUMBER (V_CRT_ID);
      FETCH C_GET_P_NUMBER INTO V_CIRCUIT_ID;
      CLOSE C_GET_P_NUMBER;



      OPEN C_GET_CIRCUITNO (V_CRT_ID);
      FETCH C_GET_CIRCUITNO INTO V_PORT_EQUP_ID;
      CLOSE C_GET_CIRCUITNO;


      OPEN C_GET_EQ_DET (V_PORT_EQUP_ID);
      FETCH C_GET_EQ_DET INTO L_EQUP_LOCN_TTNAME, L_EQUP_EQUM_MODEL,L_EQUP_INDEX;
      CLOSE C_GET_EQ_DET;

      IF L_EQUP_LOCN_TTNAME IS NOT NULL AND L_EQUP_EQUM_MODEL IS NOT NULL AND L_EQUP_INDEX IS NOT NULL THEN

        L_EQ_L_TNAME:=TRIM(REPLACE(L_EQUP_LOCN_TTNAME,'-NODE',' '));

        L_EQ_E_MODEL:=TRIM(REPLACE(L_EQUP_EQUM_MODEL,'-ISL',' '));

        L_EQ_INDEX:=SUBSTR(L_EQUP_INDEX,-2);

        L_TEMP_CODE:=L_EQ_L_TNAME||'_'||L_EQ_E_MODEL||'_'||L_EQ_INDEX;

      ELSE

      L_TEMP_CODE:=NULL;

      END IF;


    RETURN L_TEMP_CODE;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_DNAME;



 FUNCTION GET_UID (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_PSTN_NUMBER (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT SEOA_DEFAULTVALUE
            FROM SERVICE_ORDER_ATTRIBUTES
            WHERE   SEOA_SERO_ID=T_SERO_ID
            AND     SEOA_NAME='SA_PSTN_NUMBER';

      CURSOR C_ORDT_TYPE (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT DISTINCT(SERO_ORDT_TYPE)
            FROM SERVICE_ORDERS
            WHERE SERO_ID=T_SERO_ID;


        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_PSTN_NUMBER       SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;
        V_SERO_ORDT_TYPE    SERVICE_ORDERS.SERO_ORDT_TYPE%TYPE;

        L_PSTN_NUMB         VARCHAR2(100);



   BEGIN

      OPEN C_SERO_ID;       FETCH C_SERO_ID
       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;

      OPEN C_PSTN_NUMBER (V_SEIT_SERO_ID);
      FETCH C_PSTN_NUMBER     INTO V_PSTN_NUMBER;
      CLOSE C_PSTN_NUMBER;

      OPEN C_ORDT_TYPE (V_SEIT_SERO_ID);
      FETCH C_ORDT_TYPE     INTO V_SERO_ORDT_TYPE;
      CLOSE C_ORDT_TYPE;



      IF V_PSTN_NUMBER IS NOT NULL AND V_SERO_ORDT_TYPE='SUSPEND' THEN

        L_PSTN_NUMB:=SUBSTR(V_PSTN_NUMBER,4)||'_TOS_'||TO_CHAR(SYSDATE,'DD-MON-YYYY');

      ELSIF V_PSTN_NUMBER IS NOT NULL THEN

        L_PSTN_NUMB:=SUBSTR(V_PSTN_NUMBER,4);


      ELSE

        L_PSTN_NUMB:=NULL;

      END IF;

    RETURN L_PSTN_NUMB;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_UID;
---- Janaka 2013 07 30 ****ZTE_ADSL****

---- Janaka 2013 05 22

FUNCTION GET_PCRF_CUST_CONT (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_ORDT_TYPE (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT DISTINCT(SERO_ORDT_TYPE)
            FROM SERVICE_ORDERS
            WHERE SERO_ID=T_SERO_ID;

      CURSOR C_GET_VALUE (T_SERV_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT  SEOA_DEFAULTVALUE,SEOA_PREV_VALUE
            FROM    SERVICE_ORDER_ATTRIBUTES
            WHERE   SEOA_ID=
            (SELECT MAX(SEOA_ID)
            FROM    SERVICE_ORDER_ATTRIBUTES
            WHERE   SEOA_NAME='CUSTOMER CONTACT NO'
            AND     SEOA_SERO_ID=T_SERV_ID);


        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_SERO_ORDT_TYPE    SERVICE_ORDERS.SERO_ORDT_TYPE%TYPE;

      L_PREV_VALUE      SERVICE_ORDER_ATTRIBUTES.SEOA_PREV_VALUE%TYPE;
      L_CURR_VALUE      SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;
      L_PCRF_CONTACT      SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;



   BEGIN

      OPEN C_SERO_ID;       FETCH C_SERO_ID
       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;

      OPEN C_ORDT_TYPE (V_SEIT_SERO_ID);
      FETCH C_ORDT_TYPE     INTO V_SERO_ORDT_TYPE;
      CLOSE C_ORDT_TYPE;

      OPEN C_GET_VALUE (V_SEIT_SERO_ID);
      FETCH C_GET_VALUE INTO L_CURR_VALUE,L_PREV_VALUE;
      CLOSE C_GET_VALUE;


      IF L_CURR_VALUE IS NOT NULL THEN

       L_PCRF_CONTACT := SUBSTR(L_CURR_VALUE,INSTR(L_CURR_VALUE,0),10);


      END IF;


    RETURN L_PCRF_CONTACT;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_PCRF_CUST_CONT;

---- Janaka 2013 05 22

-----Dinesh 28-09-2013 ----------
FUNCTION GET_SUBID (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


      CURSOR C_SUBID IS
            SELECT  UPPER(SEOA_DEFAULTVALUE)
            FROM    SERVICE_ORDER_ATTRIBUTES SOA, SERVICE_IMPLEMENTATION_TASKS SI
            WHERE   SEOA_NAME = 'USER_NAME'
            AND     SI.SEIT_SERO_ID = SOA.SEOA_SERO_ID
            AND     SI.SEIT_ID = PI_SEIT_ID;
            
      CURSOR C_SUBID_FTTH IS  ------  added on 29-04-2016
            SELECT  UPPER(SEOA_DEFAULTVALUE)
            FROM    SERVICE_ORDER_ATTRIBUTES SOA, SERVICE_IMPLEMENTATION_TASKS SI
            WHERE   SEOA_NAME = 'ADSL_CIRCUIT_ID'
            AND     SI.SEIT_SERO_ID = SOA.SEOA_SERO_ID
            AND     SI.SEIT_ID = PI_SEIT_ID;
            
      CURSOR C_SERVICE_TYPE IS  ------  added on 29-04-2016
            SELECT  SERO_SERT_ABBREVIATION
            FROM    SERVICE_ORDERS SO, SERVICE_IMPLEMENTATION_TASKS SI
            WHERE   SI.SEIT_SERO_ID = SO.SERO_ID
            AND     SI.SEIT_ID = PI_SEIT_ID;


      L_SUBID        SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;
      L_SUBFTTH      SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;
      L_SERVICE      SERVICE_ORDERS.SERO_SERT_ABBREVIATION%TYPE;
      D_SUBID        VARCHAR2(100);


   BEGIN

      OPEN C_SUBID;
      FETCH C_SUBID INTO L_SUBID;
      CLOSE C_SUBID;
      
      OPEN C_SUBID_FTTH;
      FETCH C_SUBID_FTTH INTO L_SUBFTTH;
      CLOSE C_SUBID_FTTH;
      
      OPEN C_SERVICE_TYPE;
      FETCH C_SERVICE_TYPE INTO L_SERVICE;
      CLOSE C_SERVICE_TYPE;
    
        ----- followings were added to cater different attibute capturing to FTTH & ADSL ----
      IF (L_SERVICE = 'BB-INTERNET FTTH') OR (L_SERVICE = 'E-IPTV FTTH') OR (L_SERVICE = 'V-VOICE FTTH') THEN
       D_SUBID := L_SUBFTTH;
      
      ELSIF L_SERVICE = 'ADSL' THEN
       D_SUBID := L_SUBID;
      
      ELSIF (L_SERVICE = 'BB-INTERNET') THEN
       D_SUBID := L_SUBFTTH;
      
      ELSE
       D_SUBID:= NULL;

      END IF;


    RETURN D_SUBID;

   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END GET_SUBID;
-----Dinesh 28-09-2013 ----------

------Dinesh 14-10-2013----
FUNCTION GET_PRV_SUBID (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


      CURSOR C_PRV_SUBID
      IS
            SELECT  UPPER(SEOA_PREV_VALUE)
            FROM    SERVICE_ORDER_ATTRIBUTES SOA, SERVICE_IMPLEMENTATION_TASKS SI
            WHERE   SEOA_NAME = 'USER_NAME'
            AND     SI.SEIT_SERO_ID = SOA.SEOA_SERO_ID
            AND     SI.SEIT_ID = PI_SEIT_ID;


      L_PRV_SUBID        SERVICE_ORDER_ATTRIBUTES.SEOA_PREV_VALUE%TYPE;


   BEGIN

      OPEN C_PRV_SUBID;

      FETCH C_PRV_SUBID
       INTO L_PRV_SUBID;

      CLOSE C_PRV_SUBID;


      RETURN L_PRV_SUBID;

   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END GET_PRV_SUBID;
------Dinesh 14-10-2013----

----- Edited Dinesh 03-11-2013-----
------Samankula Owitipana 28-10-2013----
 FUNCTION get_so_order_type (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR c_so_order_type IS
         SELECT so.sero_id,so.SERO_ORDT_TYPE
         FROM service_implementation_tasks sit,service_orders so
         WHERE so.sero_id = sit.seit_sero_id
         AND sit.SEIT_ID = pi_seit_id;

     CURSOR C_GET_FEATURES (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

         SELECT  SOFE_FEATURE_NAME,NVL(SOFE_DEFAULTVALUE,'N') SOFE_DEFAULTVALUE ,NVL(SOFE_PREV_VALUE,'N') SOFE_PREV_VALUE
         FROM    SERVICE_ORDER_FEATURES
         WHERE   SOFE_SERO_ID=T_SERO_ID
         AND     SOFE_FEATURE_NAME IN ('SF_SISU CONNECT')
         ORDER BY SOFE_FEATURE_NAME;

      V_SERO_ID             service_orders.sero_id%TYPE;
      V_SERO_TYPE           service_orders.SERO_ORDT_TYPE%TYPE;
      V_SF_NAME             SERVICE_ORDER_FEATURES.SOFE_FEATURE_NAME%TYPE;
      V_SISU_CUR            SERVICE_ORDER_FEATURES.SOFE_DEFAULTVALUE%TYPE;
      V_SISU_PRV            SERVICE_ORDER_FEATURES.SOFE_PREV_VALUE%TYPE;

      L_RT_TYPE             VARCHAR2(50);




   BEGIN
      OPEN c_so_order_type;
      FETCH c_so_order_type    INTO V_SERO_ID,V_SERO_TYPE;
      CLOSE c_so_order_type;

      OPEN C_GET_FEATURES (V_SERO_ID);
      FETCH C_GET_FEATURES     INTO V_SF_NAME,V_SISU_CUR,V_SISU_PRV;
      CLOSE C_GET_FEATURES;



      IF V_SERO_TYPE = 'CREATE' AND V_SISU_CUR='Y' AND V_SISU_PRV='N'
      THEN
         L_RT_TYPE :='ACTIVE';

      ELSIF V_SERO_TYPE = 'DELETE'
      THEN
          L_RT_TYPE :='DELETED';

      ELSIF V_SERO_TYPE = 'MODIFY-FEATURE' AND V_SISU_CUR='Y' AND V_SISU_PRV='N'
      THEN
          L_RT_TYPE :='ACTIVE';

      ELSIF V_SERO_TYPE = 'MODIFY-FEATURE' AND V_SISU_CUR='Y' AND V_SISU_PRV='Y'
      THEN
          L_RT_TYPE :='ACTIVE';

      ELSIF V_SERO_TYPE = 'MODIFY-FEATURE' AND V_SISU_CUR='N' AND V_SISU_PRV='Y'
      THEN
          L_RT_TYPE :='DELETED';

      ELSIF V_SERO_TYPE = 'SUSPEND'
      THEN
          L_RT_TYPE :='SUSPEND';

      ELSIF V_SERO_TYPE = 'RESUME'
      THEN
          L_RT_TYPE :='RESUME';

      ELSE

          L_RT_TYPE :=NULL;

      END IF;


      RETURN L_RT_TYPE;

   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END get_so_order_type;

------Samankula Owitipana 28-10-2013----
----- Edited Dinesh 03-11-2013-----

----- Dinesh 2014 01 12 ---- SIP EID-----
FUNCTION GET_SIP_EID (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_EID (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT SEOA_DEFAULTVALUE
            FROM SERVICE_ORDER_ATTRIBUTES
            WHERE   SEOA_SERO_ID=T_SERO_ID
            AND     SEOA_NAME='SA_PSTN_NUMBER';


        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_EID               SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;

        L_EID                VARCHAR2(20);



   BEGIN

      OPEN C_SERO_ID;       FETCH C_SERO_ID
       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;

      OPEN C_EID (V_SEIT_SERO_ID);
      FETCH C_EID     INTO V_EID;
      CLOSE C_EID;



      IF V_EID IS NOT NULL THEN

        L_EID:=V_EID;

      ELSE

        L_EID:=NULL;

      END IF;

    RETURN L_EID;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_SIP_EID;

----- Dinesh 2014 01 12 ---- SIP EID-----


----- Dinesh 2014 01 14 ---- SIP D-----
FUNCTION GET_SIP_D (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_EID (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT SEOA_DEFAULTVALUE
            FROM SERVICE_ORDER_ATTRIBUTES
            WHERE   SEOA_SERO_ID=T_SERO_ID
            AND     SEOA_NAME='SA_PSTN_NUMBER';


        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_EID               SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;

        L_EID                VARCHAR2(20);



   BEGIN

      OPEN C_SERO_ID;       FETCH C_SERO_ID
       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;

      OPEN C_EID (V_SEIT_SERO_ID);
      FETCH C_EID     INTO V_EID;
      CLOSE C_EID;



      IF V_EID IS NOT NULL THEN

        L_EID:=SUBSTR(V_EID,-7);

      ELSE

        L_EID:=NULL;

      END IF;

    RETURN L_EID;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_SIP_D;
----- Dinesh 2014 01 14 ---- SIP D-----


----- Dinesh 2014 01 14 ---- SIP LP-----
FUNCTION GET_SIP_LP (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_EID (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT SEOA_DEFAULTVALUE
            FROM SERVICE_ORDER_ATTRIBUTES
            WHERE   SEOA_SERO_ID=T_SERO_ID
            AND     SEOA_NAME='SA_PSTN_NUMBER';


        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_EID               SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;

        L_EID                VARCHAR2(20);



   BEGIN

      OPEN C_SERO_ID;       FETCH C_SERO_ID
       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;

      OPEN C_EID (V_SEIT_SERO_ID);
      FETCH C_EID     INTO V_EID;
      CLOSE C_EID;



      IF V_EID IS NOT NULL THEN

        L_EID:=SUBSTR(V_EID,2,2);

      ELSE

        L_EID:=NULL;

      END IF;

    RETURN L_EID;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_SIP_LP;
----- Dinesh 2014 01 14 ---- SIP LP-----

----- Dinesh 2014 01 21 ---- SIP D OLD-----
FUNCTION GET_SIP_D_OLD (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_EID (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT SEOA_PREV_VALUE
            FROM SERVICE_ORDER_ATTRIBUTES
            WHERE   SEOA_SERO_ID=T_SERO_ID
            AND     SEOA_NAME='SA_PSTN_NUMBER';


        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_EID               SERVICE_ORDER_ATTRIBUTES.SEOA_PREV_VALUE%TYPE;

        L_EID                VARCHAR2(20);



   BEGIN

      OPEN C_SERO_ID;       FETCH C_SERO_ID
       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;

      OPEN C_EID (V_SEIT_SERO_ID);
      FETCH C_EID     INTO V_EID;
      CLOSE C_EID;



      IF V_EID IS NOT NULL THEN

        L_EID:=SUBSTR(V_EID,-7);

      ELSE

        L_EID:=NULL;

      END IF;

    RETURN L_EID;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_SIP_D_OLD;
----- Dinesh 2014 01 21 ---- SIP D OLD -----


----- Dinesh 2014 01 21 ---- SIP LP OLD -----
FUNCTION GET_SIP_LP_OLD (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_EID (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT SEOA_PREV_VALUE
            FROM SERVICE_ORDER_ATTRIBUTES
            WHERE   SEOA_SERO_ID=T_SERO_ID
            AND     SEOA_NAME='SA_PSTN_NUMBER';


        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_EID               SERVICE_ORDER_ATTRIBUTES.SEOA_PREV_VALUE%TYPE;

        L_EID                VARCHAR2(20);



   BEGIN

      OPEN C_SERO_ID;       FETCH C_SERO_ID
       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;

      OPEN C_EID (V_SEIT_SERO_ID);
      FETCH C_EID     INTO V_EID;
      CLOSE C_EID;



      IF V_EID IS NOT NULL THEN

        L_EID:=SUBSTR(V_EID,2,2);

      ELSE

        L_EID:=NULL;

      END IF;

    RETURN L_EID;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_SIP_LP_OLD;
----- Dinesh 2014 01 21 ---- SIP LP OLD -----

----- Dinesh 2014 01 21 ---- SIP EID OLD -----
FUNCTION GET_SIP_EID_OLD (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_EID (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT SEOA_PREV_VALUE
            FROM SERVICE_ORDER_ATTRIBUTES
            WHERE   SEOA_SERO_ID=T_SERO_ID
            AND     SEOA_NAME='SA_PSTN_NUMBER';


        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_EID               SERVICE_ORDER_ATTRIBUTES.SEOA_PREV_VALUE%TYPE;

        L_EID                VARCHAR2(20);



   BEGIN

      OPEN C_SERO_ID;       FETCH C_SERO_ID
       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;

      OPEN C_EID (V_SEIT_SERO_ID);
      FETCH C_EID     INTO V_EID;
      CLOSE C_EID;



      IF V_EID IS NOT NULL THEN

        L_EID:=V_EID;

      ELSE

        L_EID:=NULL;

      END IF;

    RETURN L_EID;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_SIP_EID_OLD;
----- Dinesh 2014 01 21 ---- SIP EID OLD -----

----- Dinesh 2014 01 23 ---- UID LTE OLD -----
FUNCTION GET_UID_LTE_OLD (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_EID (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT SEOA_PREV_VALUE
            FROM SERVICE_ORDER_ATTRIBUTES
            WHERE   SEOA_SERO_ID=T_SERO_ID
            AND     SEOA_NAME='ADSL_CIRCUIT_ID';


        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_EID               SERVICE_ORDER_ATTRIBUTES.SEOA_PREV_VALUE%TYPE;

        L_EID                VARCHAR2(20);



   BEGIN

      OPEN C_SERO_ID;       FETCH C_SERO_ID
       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;

      OPEN C_EID (V_SEIT_SERO_ID);
      FETCH C_EID     INTO V_EID;
      CLOSE C_EID;



      IF V_EID IS NOT NULL THEN

        L_EID:= V_EID;

      ELSE

        L_EID:=NULL;

      END IF;

    RETURN L_EID;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_UID_LTE_OLD;
----- Dinesh 2014 01 23 ---- UID LTE OLD -----

----- Dinesh 2014 01 25 ---- GET SIP PASSWORD-----
FUNCTION GET_SIP_PASSWORD (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

        CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_MSISDN_NO (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS
            SELECT TRIM(SEOA_DEFAULTVALUE)
            FROM    SERVICE_ORDER_ATTRIBUTES
            WHERE   SEOA_SERO_ID=T_SERO_ID
            AND     SEOA_NAME = 'SA_PSTN_NUMBER';

      CURSOR C_IMSI_NO (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS
            SELECT TRIM(SEOA_DEFAULTVALUE)
            FROM    SERVICE_ORDER_ATTRIBUTES
            WHERE   SEOA_SERO_ID=T_SERO_ID
            AND     SEOA_NAME = 'IMSI NO';


        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_EID               SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;

        V_MSISDN_NO     VARCHAR2(100);
        V_IMSI_NO       VARCHAR2(100);
        L_PASSWORD      VARCHAR2(100);


   BEGIN

      OPEN C_SERO_ID;       FETCH C_SERO_ID
       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;

      OPEN C_MSISDN_NO (V_SEIT_SERO_ID);
      FETCH C_MSISDN_NO     INTO V_MSISDN_NO;
      CLOSE C_MSISDN_NO;

      OPEN C_IMSI_NO (V_SEIT_SERO_ID);
      FETCH C_IMSI_NO       INTO V_IMSI_NO;
      CLOSE C_IMSI_NO;



      IF V_MSISDN_NO IS NOT NULL THEN

        SELECT trim(TO_CHAR(substr(V_IMSI_NO,-3,3)+88,'XXXXXXXX'))
        || TO_CHAR(SUBSTR(V_MSISDN_NO,6,1)+1)
        || TO_CHAR(SUBSTR(V_MSISDN_NO,8,1)+1)
        || trim(TO_CHAR(substr(V_MSISDN_NO,-2,2)+9,'XXXXXXXX'))
        || to_CHAR(nvl(SUBSTR(v_msisdn_no,11,1),'0')+1)
        || to_CHAR(SUBSTR(V_MSISDN_NO,5,1)+1)
        || to_CHAR(SUBSTR(V_MSISDN_NO,9,1)+1)
        || to_CHAR(SUBSTR(V_MSISDN_NO,7,1)+1)
        || to_CHAR(SUBSTR(V_MSISDN_NO,4,1)+1)
        || to_CHAR(SUBSTR(V_MSISDN_NO,10,1)+1)
        INTO L_PASSWORD
        FROM DUAL;

      ELSE

        L_PASSWORD:=NULL;

      END IF;

    RETURN L_PASSWORD;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_SIP_PASSWORD ;
----- Dinesh 2014 01 25 ---- GET SIP PASSWORD-----

---- Janaka 2014 04 10 --- GET_PWD_BBINTE -----
FUNCTION GET_PWD_BBINTE (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


    CURSOR C_SO       IS

        SELECT SEIT_SERO_ID, SEIT_SERO_REVISION
        FROM   SERVICE_IMPLEMENTATION_TASKS
        WHERE  SEIT_ID = PI_SEIT_ID;

    CURSOR C_FETURE   (T_SO_NO SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_ID%TYPE)    IS
        SELECT  SEOA_DEFAULTVALUE,SOFE_DEFAULTVALUE
        FROM    SERVICE_ORDER_FEATURES,SERVICE_ORDER_ATTRIBUTES
        WHERE   SEOA_SERO_ID=SOFE_SERO_ID
        AND     SOFE_ID=SEOA_SOFE_ID
        AND     SOFE_SERO_ID=T_SO_NO
        AND     SOFE_FEATURE_NAME='INTERNET';


    CURSOR C_SORD_VAL    (T_SO_NO SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_ID%TYPE,
                          T_SO_RV SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_REVISION%TYPE,
                          T_SERIAL SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE)   IS
        SELECT  SORD_VALUE
        FROM    SERVICE_IMPLEMENTATION_TASKS,SOP_QUEUE,SOP_REQUEST_DATA,SOP_REPLY_DATA
        WHERE   SEIT_SERO_ID=T_SO_NO
        AND     SEIT_SERO_REVISION=T_SO_RV
        AND     SEIT_TASKNAME='QUERY USER PASSWORD'
        AND     SOPQ_SEIT_ID=SEIT_ID
        AND     SOPQ_STATUS='COMPLETED'
        AND     SOPR_SOPQ_REQUESTID=SOPQ_REQUESTID
        AND     SORD_SOPQ_REQUESTID=SOPQ_REQUESTID
        AND     SOPR_NAME='SERIALNUMBER'
        AND     SOPR_VALUE=T_SERIAL
        AND     SORD_NAME='userpassword';


      L_SO_NO                   SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_ID%TYPE;
      L_SO_RV                   SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_REVISION%TYPE;
      L_SERIAL                  SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;
      L_INTERN                  SERVICE_ORDER_FEATURES.SOFE_DEFAULTVALUE%TYPE;
      L_PWD                     SOP_REPLY_DATA.SORD_VALUE%TYPE;



   BEGIN

      OPEN C_SO;
      FETCH C_SO
      INTO L_SO_NO,L_SO_RV;
      CLOSE C_SO;

      OPEN C_FETURE(L_SO_NO);
      FETCH C_FETURE
      INTO L_SERIAL,L_INTERN;
      CLOSE C_FETURE;


      IF L_INTERN ='Y' AND L_SERIAL IS NOT NULL THEN

          OPEN  C_SORD_VAL(L_SO_NO,L_SO_RV,L_SERIAL);
          FETCH C_SORD_VAL
          INTO  L_PWD;
          CLOSE C_SORD_VAL;



      END IF;

      RETURN L_PWD;


   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END GET_PWD_BBINTE;
---- Janaka 2014 04 10 --- GET_PWD_BBINTE -----

----- Dinesh 2014-05-23 ---- LTE/FTTH LDAP DESCRIPTION-----
---- Dinesh Updated 13-05-2016------
FUNCTION GET_LTE_DESC (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
      )
      RETURN VARCHAR2
   IS

   T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE;

      CURSOR C_DATE IS     
            SELECT TO_CHAR
            ((SYSDATE), 'MM-DD-YYYY HH:MM:SS')
            FROM DUAL;
      
      CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_EID (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT MAX(SEOA_DEFAULTVALUE)
            FROM SERVICE_ORDER_ATTRIBUTES
            WHERE   SEOA_SERO_ID = T_SERO_ID
            AND    (SEOA_NAME = 'BB CIRCUIT ID' OR SEOA_NAME = 'ADSL_CIRCUIT_ID');

      CURSOR C_SER_TYPE (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT SERO_SERT_ABBREVIATION
            FROM SERVICE_ORDERS
            WHERE   SERO_ID = T_SERO_ID;
            ----AND     SERO_SERT_ABBREVIATION = 'BB-INTERNET';

      CURSOR C_ORD_TYPE (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT SERO_ORDT_TYPE
            FROM SERVICE_ORDERS
            WHERE   SERO_ID = T_SERO_ID;
            ----AND     SERO_SERT_ABBREVIATION = 'BB-INTERNET';


        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_EID               SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;
        V_SER_TYPE          SERVICE_ORDERS.SERO_SERT_ABBREVIATION%TYPE;
        V_ORD_TYPE          SERVICE_ORDERS.SERO_ORDT_TYPE%TYPE;
        V_DATE              VARCHAR2(80);

        L_EID               VARCHAR2(1000);



   BEGIN

      OPEN C_SERO_ID;       
      FETCH C_SERO_ID  INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;


      OPEN C_EID (V_SEIT_SERO_ID);
      FETCH C_EID     INTO V_EID;
      CLOSE C_EID;


      OPEN C_SER_TYPE (V_SEIT_SERO_ID);
      FETCH C_SER_TYPE     INTO V_SER_TYPE;
      CLOSE C_SER_TYPE;



      OPEN C_ORD_TYPE (V_SEIT_SERO_ID);
      FETCH C_ORD_TYPE     INTO V_ORD_TYPE;
      CLOSE C_ORD_TYPE;
      
      
      OPEN C_DATE;
      FETCH C_DATE     INTO V_DATE;
      CLOSE C_DATE;


      IF V_EID IS NOT NULL THEN

        L_EID:= V_SEIT_SERO_ID||', '||V_ORD_TYPE||' Order Completed on '||V_DATE;

      ELSE

        L_EID:=NULL;

      END IF;

    RETURN L_EID;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_LTE_DESC;
----- Dinesh 2014-05-23 ---- LTE/FTTH LDAP DESCRIPTION-----
---- Dinesh Updated 13-05-2016------

------Samankula Owitipana 30-12-2013---- IMSI Number for HUAWEI HLR ----
 FUNCTION GET_CDMA_IMSI (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


      L_RT_CDMA_IMSI             VARCHAR2(100);




   BEGIN


    SELECT '413120' || substr(trim(SOA.SEOA_DEFAULTVALUE),-9)
    INTO L_RT_CDMA_IMSI
    FROM SERVICE_ORDER_ATTRIBUTES SOA,service_implementation_tasks sit
    WHERE sit.SEIT_ID = pi_seit_id
    AND SOA.SEOA_SERO_ID = sit.SEIT_SERO_ID
    AND SOA.SEOA_NAME = 'SA_CDMA_NUMBER';




      RETURN L_RT_CDMA_IMSI;


   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END GET_CDMA_IMSI;

------Samankula Owitipana 30-12-2013---- IMSI Number for HUAWEI HLR ----


------Samankula Owitipana 30-12-2013---- MDN Number for HUAWEI HLR ----
 FUNCTION GET_CDMA_MDN (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


      L_RT_CDMA_MDN             VARCHAR2(100);




   BEGIN


    SELECT '94' || substr(trim(SOA.SEOA_DEFAULTVALUE),-9)
    INTO L_RT_CDMA_MDN
    FROM SERVICE_ORDER_ATTRIBUTES SOA,service_implementation_tasks sit
    WHERE sit.SEIT_ID = pi_seit_id
    AND SOA.SEOA_SERO_ID = sit.SEIT_SERO_ID
    AND SOA.SEOA_NAME = 'SA_CDMA_NUMBER';




      RETURN L_RT_CDMA_MDN;

   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END GET_CDMA_MDN;

------Samankula Owitipana 30-12-2013---- MDN Number for HUAWEI HLR ----

------Samankula Owitipana 28-01-2014---- OLD MDN Number for HUAWEI HLR ----
 FUNCTION GET_CDMA_OLD_MDN (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


      L_RT_CDMA_MDN             VARCHAR2(100);




   BEGIN


    SELECT '94' || substr(trim(SOA.SEOA_PREV_VALUE ),-9)
    INTO L_RT_CDMA_MDN
    FROM SERVICE_ORDER_ATTRIBUTES SOA,service_implementation_tasks sit
    WHERE sit.SEIT_ID = pi_seit_id
    AND SOA.SEOA_SERO_ID = sit.SEIT_SERO_ID
    AND SOA.SEOA_NAME = 'SA_CDMA_NUMBER';



      RETURN L_RT_CDMA_MDN;

   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END GET_CDMA_OLD_MDN;

------Samankula Owitipana 28-01-2014---- OLD MDN Number for HUAWEI HLR ----

---- Samankula Owitipana 2014 07 28
 FUNCTION GET_ENT_CUS_NAME_WIFI (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


      L_CUST_NAME             VARCHAR2(80);

    cursor c_cus_name is
    SELECT cu.CUSR_NAME
    FROM SERVICE_ORDERS SO,service_implementation_tasks sit,customer cu
    WHERE sit.SEIT_ID = pi_seit_id
    AND SO.SERO_ID = sit.SEIT_SERO_ID
    AND cu.CUSR_ABBREVIATION = SO.SERO_CUSR_ABBREVIATION;




BEGIN

open c_cus_name;
fetch c_cus_name into L_CUST_NAME;
close c_cus_name;



      RETURN L_CUST_NAME;


EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
END GET_ENT_CUS_NAME_WIFI;
---- Samankula Owitipana 2014 07 28


---- Samankula Owitipana 2014 08 07
 FUNCTION GET_IPTV_SO_WG (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


      L_SO_WORKGROUP             VARCHAR2(80);

    cursor c_cus_name is
    SELECT so.SERO_WORG_NAME
    FROM SERVICE_ORDERS SO,service_implementation_tasks sit
    WHERE sit.SEIT_ID = pi_seit_id
    AND SO.SERO_ID = sit.SEIT_SERO_ID;




BEGIN

open c_cus_name;
fetch c_cus_name into L_SO_WORKGROUP;
close c_cus_name;



      RETURN L_SO_WORKGROUP;


EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
END GET_IPTV_SO_WG;
---- Samankula Owitipana 2014 08 07

---- Dinesh Perera 26-08-2014 -----
FUNCTION GET_CUST_ADDRESS (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


      L_SO_CUST_ADDRESS            VARCHAR2(200);

    cursor c_cus_address is
    SELECT (AD.ADDE_STREETNUMBER||', '||AD.ADDE_STRN_NAMEANDTYPE||', '||AD.ADDE_SUBURB||', '||AD.ADDE_CITY
            ||', '||AD.ADDE_POSC_CODE)
    FROM SERVICE_ORDERS SO,service_implementation_tasks sit,ADDRESSES AD
    WHERE sit.SEIT_ID = pi_seit_id
    AND SO.SERO_ID = sit.SEIT_SERO_ID
    AND SO.SERO_ADDE_ID_BEND = AD.ADDE_ID;




BEGIN

open c_cus_address;
fetch c_cus_address into L_SO_CUST_ADDRESS;
close c_cus_address;



      RETURN L_SO_CUST_ADDRESS;


EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
END GET_CUST_ADDRESS;
---- Dinesh Perera 26-08-2014 -----

------Samankula Owitipana 28-10-2013----
 FUNCTION GET_SO_TYPE_ZTE (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR c_so_order_type IS
         SELECT so.sero_id,so.SERO_ORDT_TYPE
         FROM service_implementation_tasks sit,service_orders so
         WHERE so.sero_id = sit.seit_sero_id
         AND sit.SEIT_ID = pi_seit_id;



      V_SERO_ID             service_orders.sero_id%TYPE;
      V_SERO_TYPE           service_orders.SERO_ORDT_TYPE%TYPE;
      V_SF_NAME             SERVICE_ORDER_FEATURES.SOFE_FEATURE_NAME%TYPE;
      V_SISU_CUR            SERVICE_ORDER_FEATURES.SOFE_DEFAULTVALUE%TYPE;
      V_SISU_PRV            SERVICE_ORDER_FEATURES.SOFE_PREV_VALUE%TYPE;

      L_RT_TYPE             VARCHAR2(50);




   BEGIN


      OPEN c_so_order_type;
      FETCH c_so_order_type    INTO V_SERO_ID,V_SERO_TYPE;
      CLOSE c_so_order_type;



      RETURN V_SERO_TYPE;

   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END GET_SO_TYPE_ZTE;

------Samankula Owitipana 28-10-2013----
----- Edited Dinesh 03-11-2013-----

---- Samankula Owitipana 2014 06 18 ****ZTE ADSL****
FUNCTION GET_ZTE_PID (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_SERV_ID (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT DISTINCT(SERO_CIRT_NAME),SERO_SERT_ABBREVIATION
            FROM SERVICE_ORDERS
            WHERE SERO_ID=T_SERO_ID;

      CURSOR C_GET_P_NUMBER (T_CRT_ID SERVICE_ORDERS.SERO_CIRT_NAME%TYPE) IS

            SELECT  MAX(CIRT_NAME)
            FROM    CIRCUITS
            WHERE   CIRT_NAME  =T_CRT_ID
            AND     CIRT_STATUS !='PENDINGDELETE';

      CURSOR C_GET_TIDNAME (T_CRT_ID SERVICE_ORDERS.SERO_CIRT_NAME%TYPE) IS

            SELECT  PO.PORT_NAME,PO.PORT_CARD_SLOT
            FROM    PORTS PO,PORT_LINKS PL,PORT_LINK_PORTS PLP
            WHERE   PO.PORT_ID=PLP.POLP_PORT_ID
            AND     PL.PORL_ID=PLP.POLP_PORL_ID
            AND     PL.PORL_CIRT_NAME= T_CRT_ID
            AND     PO.PORT_USAGE='SERVICE_SWITCHING_POINT';




        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_CRT_ID            SERVICE_ORDERS.SERO_SERV_ID%TYPE;
        V_SERO_TYPE         SERVICE_ORDERS.SERO_SERT_ABBREVIATION%TYPE;
        V_CIRCUIT_ID        CIRCUITS.CIRT_NAME%TYPE;
        V_PORT_CARD_SLOT    PORTS.PORT_CARD_SLOT%TYPE;
        V_PORT_NAME         PORTS.PORT_NAME%TYPE;


      L_TEMP_CODE         VARCHAR2(20);
      L_TIDNAME           VARCHAR2(20);



   BEGIN

      OPEN C_SERO_ID;       FETCH C_SERO_ID
       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;

      OPEN C_SERV_ID (V_SEIT_SERO_ID);
      FETCH C_SERV_ID     INTO V_CRT_ID,V_SERO_TYPE;
      CLOSE C_SERV_ID;

      OPEN C_GET_P_NUMBER (V_CRT_ID);
      FETCH C_GET_P_NUMBER INTO V_CIRCUIT_ID;
      CLOSE C_GET_P_NUMBER;


      OPEN C_GET_TIDNAME (V_CRT_ID);
      FETCH C_GET_TIDNAME INTO V_PORT_NAME,V_PORT_CARD_SLOT;
      CLOSE C_GET_TIDNAME;


      IF V_PORT_CARD_SLOT IS NOT NULL AND V_PORT_NAME IS NOT NULL THEN

       IF SUBSTR(V_PORT_CARD_SLOT,1,1) = 'Z' THEN

         L_TEMP_CODE := SUBSTR(V_PORT_CARD_SLOT,INSTR(V_PORT_CARD_SLOT,'-')-1,2) || '0'||SUBSTR(V_PORT_CARD_SLOT,INSTR(V_PORT_CARD_SLOT,'-',1,2)-1,2) || SUBSTR(V_PORT_CARD_SLOT,-2) || '-';

       ELSIF SUBSTR(V_PORT_CARD_SLOT,1,1) = 'P' THEN

         L_TEMP_CODE := REPLACE(SUBSTR(V_PORT_CARD_SLOT,4),'.','-')|| '-';

       END IF;


       L_TIDNAME:=L_TEMP_CODE||SUBSTR(V_PORT_NAME,-2);

      ELSE

       L_TIDNAME:=NULL;

      END IF;

    RETURN replace(L_TIDNAME,'-0','-');

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_ZTE_PID;
---- Samankula Owitipana 2014 06 18 ****ZTEX ADSL****


---- Samankula Owitipana 2014 06 18
FUNCTION GET_ADSL_IPTV_PVC (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS



v_seit_task Service_Implementation_Tasks.SEIT_TASKNAME%TYPE;

cursor c_task_name is
select sit.SEIT_TASKNAME
from service_implementation_tasks sit
where sit.SEIT_ID = pi_seit_id;




   BEGIN


      OPEN c_task_name;

      FETCH c_task_name
       INTO v_seit_task;

      CLOSE c_task_name;


      IF v_seit_task like '%IPTV%'  THEN


      RETURN '2';

      ELSE

      RETURN '1';

      END IF;

   EXCEPTION
      WHEN OTHERS
      THEN

         RETURN NULL;

   END GET_ADSL_IPTV_PVC;
---- Samankula Owitipana 2014 06 18

------Samankula Owitipana 02-05-2014
FUNCTION GET_EQUIP_IP (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR C_SERO_ID IS
            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_SERV_ID (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS
            SELECT DISTINCT(SERO_CIRT_NAME),SERO_SERT_ABBREVIATION
            FROM SERVICE_ORDERS
            WHERE SERO_ID=T_SERO_ID;


      CURSOR C_GET_TIDNAME (T_CRT_ID SERVICE_ORDERS.SERO_CIRT_NAME%TYPE) IS
            SELECT  PO.PORT_NAME,PO.PORT_CARD_SLOT,po.PORT_EQUP_ID
            FROM    PORTS PO,PORT_LINKS PL,PORT_LINK_PORTS PLP
            WHERE   PO.PORT_ID=PLP.POLP_PORT_ID
            AND     PL.PORL_ID=PLP.POLP_PORL_ID
            AND     PL.PORL_CIRT_NAME= T_CRT_ID
            AND     PO.PORT_NAME like 'DSL-IN-%'
            AND     po.PORT_CARD_SLOT <> 'NA';

            CURSOR C_GET_IP_ADDRESS (T_EQUIP_ID EQUIPMENT.EQUP_ID%TYPE) IS
            select eq.EQUP_IPADDRESS from equipment eq
            where eq.EQUP_ID = T_EQUIP_ID
            and EQUP_EQUM_MODEL like 'C3%'
            and EQUP_EQUT_ABBREVIATION like 'MSAN-%';



        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_CRT_ID            SERVICE_ORDERS.SERO_SERV_ID%TYPE;
        V_SERO_TYPE         SERVICE_ORDERS.SERO_SERT_ABBREVIATION%TYPE;
        V_CIRCUIT_ID        CIRCUITS.CIRT_NAME%TYPE;
        V_PORT_CARD_SLOT    PORTS.PORT_CARD_SLOT%TYPE;
        V_PORT_NAME         PORTS.PORT_NAME%TYPE;
        V_EQUIP_ID          EQUIPMENT.EQUP_ID%TYPE;
        V_IP_ADD            EQUIPMENT.EQUP_IPADDRESS%TYPE;


      L_TEMP_CODE         VARCHAR2(20);
      L_TIDNAME           VARCHAR2(20);



   BEGIN

      OPEN C_SERO_ID;       FETCH C_SERO_ID
       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;

      OPEN C_SERV_ID (V_SEIT_SERO_ID);
      FETCH C_SERV_ID     INTO V_CRT_ID,V_SERO_TYPE;
      CLOSE C_SERV_ID;


      OPEN C_GET_TIDNAME (V_CRT_ID);
      FETCH C_GET_TIDNAME INTO V_PORT_NAME,V_PORT_CARD_SLOT,V_EQUIP_ID;
      CLOSE C_GET_TIDNAME;

      OPEN C_GET_IP_ADDRESS (V_EQUIP_ID);
      FETCH C_GET_IP_ADDRESS INTO V_IP_ADD;
      CLOSE C_GET_IP_ADDRESS;




    RETURN V_IP_ADD;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_EQUIP_IP;
------Samankula Owitipana 02-05-2014

------Dinesh Perera 28-08-2014----
FUNCTION GET_SEVEN_DIGIT_UID (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


      CURSOR C_CUR_SUBID
      IS
            SELECT  SUBSTR(SEOA_DEFAULTVALUE,-7)
            FROM    SERVICE_ORDER_ATTRIBUTES SOA, SERVICE_IMPLEMENTATION_TASKS SI
            WHERE   SEOA_NAME = 'SA_PSTN_NUMBER'
            AND     SI.SEIT_SERO_ID = SOA.SEOA_SERO_ID
            AND     SI.SEIT_ID = PI_SEIT_ID;


      L_CUR_SUBID        SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;


   BEGIN

      OPEN C_CUR_SUBID;

      FETCH C_CUR_SUBID
       INTO L_CUR_SUBID;

      CLOSE C_CUR_SUBID;


      RETURN L_CUR_SUBID;

   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END GET_SEVEN_DIGIT_UID;
------Dinesh Perera 28-08-2014----

------Dinesh Perera 28-08-2014----
FUNCTION GET_SEVEN_DIGIT_PRV_UID (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


      CURSOR C_PRV_SUBID
      IS
            SELECT  SUBSTR(SEOA_PREV_VALUE,-7)
            FROM    SERVICE_ORDER_ATTRIBUTES SOA, SERVICE_IMPLEMENTATION_TASKS SI
            WHERE   SEOA_NAME = 'SA_PSTN_NUMBER'
            AND     SI.SEIT_SERO_ID = SOA.SEOA_SERO_ID
            AND     SI.SEIT_ID = PI_SEIT_ID;


      L_PRV_SUBID        SERVICE_ORDER_ATTRIBUTES.SEOA_PREV_VALUE%TYPE;


   BEGIN

      OPEN C_PRV_SUBID;

      FETCH C_PRV_SUBID
       INTO L_PRV_SUBID;

      CLOSE C_PRV_SUBID;


      RETURN L_PRV_SUBID;

   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END GET_SEVEN_DIGIT_PRV_UID;
------Dinesh Perera 28-08-2014----

------Samankula Owitipana 27-06-2014----
FUNCTION GET_BND_VLAN (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


    CURSOR C_SO       IS

        SELECT SEIT_SERO_ID, SEIT_SERO_REVISION,SEIT_TASKNAME
        FROM   SERVICE_IMPLEMENTATION_TASKS
        WHERE  SEIT_ID = PI_SEIT_ID;

        CURSOR C_FETURE_INT   (T_SO_NO SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_ID%TYPE)    IS
        SELECT  SOFE_DEFAULTVALUE
        FROM    SERVICE_ORDER_FEATURES,SERVICE_ORDER_ATTRIBUTES
        WHERE   SEOA_SERO_ID=SOFE_SERO_ID
        AND     SOFE_ID=SEOA_SOFE_ID
        AND     SOFE_SERO_ID=T_SO_NO
        AND     SOFE_FEATURE_NAME='INTERNET';

        CURSOR C_FETURE_IPTV   (T_SO_NO SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_ID%TYPE)    IS
        SELECT  SOFE_DEFAULTVALUE
        FROM    SERVICE_ORDER_FEATURES
        WHERE   SOFE_SERO_ID=T_SO_NO
        AND     SOFE_FEATURE_NAME='IPTV';




      L_SO_NO                   SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_ID%TYPE;
      L_SO_RV                   SERVICE_IMPLEMENTATION_TASKS.SEIT_SERO_REVISION%TYPE;
      L_SERIAL                  SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;
      L_INTERN                  SERVICE_ORDER_FEATURES.SOFE_DEFAULTVALUE%TYPE;
      L_IPTV                  SERVICE_ORDER_FEATURES.SOFE_DEFAULTVALUE%TYPE;
      L_VAL                     SOP_REPLY_DATA.SORD_VALUE%TYPE;
      L_TASK                    SERVICE_IMPLEMENTATION_TASKS.SEIT_TASKNAME%TYPE;



   BEGIN

      OPEN C_SO;
      FETCH C_SO
      INTO L_SO_NO,L_SO_RV,L_TASK ;
      CLOSE C_SO;

      OPEN C_FETURE_INT(L_SO_NO);
      FETCH C_FETURE_INT
      INTO L_INTERN;
      CLOSE C_FETURE_INT;


      OPEN C_FETURE_IPTV(L_SO_NO);
      FETCH C_FETURE_IPTV
      INTO L_IPTV;
      CLOSE C_FETURE_IPTV;


      IF L_IPTV ='Y'  THEN

        L_VAL := 'YES';

      ELSIF L_IPTV ='N'  THEN

        L_VAL := 'NO';

      ELSIF L_INTERN ='Y'  THEN

        L_VAL := 'YES';

      ELSIF L_INTERN ='N'  THEN

        L_VAL := 'NO';

      END IF;

      RETURN L_VAL;


   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN 'NO VAL';
   END GET_BND_VLAN;
------Samankula Owitipana 27-06-2014

------Samankula Owitipana 25-06-2014----
 FUNCTION GET_USR_CHECK (
      PI_SEIT_ID   IN   SERVICE_IMPLEMENTATION_TASKS.SEIT_ID%TYPE,
      PI_SOPC_ID   IN   SOP_COMMANDS.SOPC_ID%TYPE,
      PI_PARAM1    IN   VARCHAR2,
      PI_PARAM2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR C_SO_ORDER_TYPE IS
         SELECT SO.SERO_ID,SO.SERO_ORDT_TYPE
         FROM SERVICE_IMPLEMENTATION_TASKS SIT,SERVICE_ORDERS SO
         WHERE SO.SERO_ID = SIT.SEIT_SERO_ID
         AND SIT.SEIT_ID = PI_SEIT_ID;



      V_SERO_ID             SERVICE_ORDERS.SERO_ID%TYPE;
      V_SERO_TYPE           SERVICE_ORDERS.SERO_ORDT_TYPE%TYPE;


      L_RT_TYPE             VARCHAR2(50);




   BEGIN

      OPEN C_SO_ORDER_TYPE;
      FETCH C_SO_ORDER_TYPE    INTO V_SERO_ID,V_SERO_TYPE;
      CLOSE C_SO_ORDER_TYPE;




      IF V_SERO_TYPE like 'CREATE%' THEN

         L_RT_TYPE := 'NO';


      ELSE

          L_RT_TYPE := 'YES';

      END IF;


      RETURN L_RT_TYPE;

   EXCEPTION
      WHEN OTHERS
      THEN

         RETURN NULL;

   END GET_USR_CHECK;
------Samankula Owitipana 25-06-2014----

---- Samankula Owitipana 2014 07 28
 FUNCTION GET_ENT_WIFI_CUS_NAME (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


      L_CUST_NAME             VARCHAR2(80);

    cursor c_cus_name is
    SELECT cu.CUSR_NAME
    FROM SERVICE_ORDERS SO,service_implementation_tasks sit,customer cu
    WHERE sit.SEIT_ID = pi_seit_id
    AND SO.SERO_ID = sit.SEIT_SERO_ID
    AND cu.CUSR_ABBREVIATION = SO.SERO_CUSR_ABBREVIATION;




BEGIN

open c_cus_name;
fetch c_cus_name into L_CUST_NAME;
close c_cus_name;



      RETURN L_CUST_NAME;


EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
END GET_ENT_WIFI_CUS_NAME;
---- Samankula Owitipana 2014 07 28

---- Samankula Owitipana 2014 10 21
---- Edited Dinesh 2014-12-03
FUNCTION GET_HUAWEI5_SHELF (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      v_shelf          number;
      v_slot           number;
      v_port           number;
      v_card_slot      VARCHAR2(50);
      p_sero_id        VARCHAR2(50);


CURSOR c_so_order_id IS
SELECT so.sero_id
FROM service_implementation_tasks sit,service_orders so
WHERE so.sero_id = sit.seit_sero_id
AND sit.SEIT_ID = pi_seit_id;

cursor c_hu_msan_port_details is
select po.PORT_CARD_SLOT,to_number(replace(replace(substr(po.PORT_CARD_SLOT,-5,2),'-',''),'.','')),to_number(replace(replace(substr(po.PORT_CARD_SLOT,-2,2),'-',''),'.','')),
to_number(replace(po.PORT_NAME,'DSL-IN-',''))
from service_orders so,circuits ci,port_links pl,port_link_ports plp,ports po
where so.SERO_CIRT_NAME = ci.CIRT_NAME
and ci.CIRT_NAME = pl.PORL_CIRT_NAME
and pl.PORL_ID = plp.POLP_PORL_ID
and plp.POLP_PORT_ID = po.PORT_ID
and so.SERO_ID = p_sero_id
AND po.PORT_NAME LIKE 'DSL-IN-%'
AND po.PORT_CARD_SLOT like 'H%';


BEGIN

      OPEN c_so_order_id;
      FETCH c_so_order_id    INTO p_sero_id;
      CLOSE c_so_order_id;

      OPEN c_hu_msan_port_details;
      FETCH c_hu_msan_port_details INTO v_card_slot,v_shelf,v_slot,v_port;
      CLOSE c_hu_msan_port_details;


      IF v_card_slot is not null THEN


      RETURN v_shelf;

      ELSE

      RETURN null;

      END IF;



EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

END GET_HUAWEI5_SHELF;
---- Samankula Owitipana 2014 10 21

---- Samankula Owitipana 2014 10 21
---- Edited Dinesh 2014-12-03
FUNCTION GET_HUAWEI5_SLOT (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      v_shelf          number;
      v_slot           number;
      v_port           number;
      v_card_slot      VARCHAR2(50);
      p_sero_id        VARCHAR2(50);


CURSOR c_so_order_id IS
SELECT so.sero_id
FROM service_implementation_tasks sit,service_orders so
WHERE so.sero_id = sit.seit_sero_id
AND sit.SEIT_ID = pi_seit_id;

cursor c_hu_msan_port_details is
select po.PORT_CARD_SLOT,to_number(replace(replace(substr(po.PORT_CARD_SLOT,-5,2),'-',''),'.','')),to_number(replace(replace(substr(po.PORT_CARD_SLOT,-2,2),'-',''),'.','')),
to_number(replace(po.PORT_NAME,'DSL-IN-',''))
from service_orders so,circuits ci,port_links pl,port_link_ports plp,ports po
where so.SERO_CIRT_NAME = ci.CIRT_NAME
and ci.CIRT_NAME = pl.PORL_CIRT_NAME
and pl.PORL_ID = plp.POLP_PORL_ID
and plp.POLP_PORT_ID = po.PORT_ID
and so.SERO_ID = p_sero_id
AND po.PORT_NAME LIKE 'DSL-IN-%'
AND po.PORT_CARD_SLOT like 'H%';


BEGIN

      OPEN c_so_order_id;
      FETCH c_so_order_id    INTO p_sero_id;
      CLOSE c_so_order_id;

      OPEN c_hu_msan_port_details;
      FETCH c_hu_msan_port_details INTO v_card_slot,v_shelf,v_slot,v_port;
      CLOSE c_hu_msan_port_details;


      IF v_card_slot is not null THEN


      RETURN v_slot;

      ELSE

      RETURN null;

      END IF;



EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

END GET_HUAWEI5_SLOT;
---- Samankula Owitipana 2014 10 21

---- Samankula Owitipana 2014 10 21
---- Edited Dinesh 2014-12-03
FUNCTION GET_HUAWEI5_PORT (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      v_shelf          number;
      v_slot           number;
      v_port           number;
      v_card_slot      VARCHAR2(50);
      p_sero_id        VARCHAR2(50);


CURSOR c_so_order_id IS
SELECT so.sero_id
FROM service_implementation_tasks sit,service_orders so
WHERE so.sero_id = sit.seit_sero_id
AND sit.SEIT_ID = pi_seit_id;

cursor c_hu_msan_port_details is
select po.PORT_CARD_SLOT,to_number(replace(replace(substr(po.PORT_CARD_SLOT,-5,2),'-',''),'.','')),to_number(replace(replace(substr(po.PORT_CARD_SLOT,-2,2),'-',''),'.','')),
to_number(replace(po.PORT_NAME,'DSL-IN-',''))
from service_orders so,circuits ci,port_links pl,port_link_ports plp,ports po
where so.SERO_CIRT_NAME = ci.CIRT_NAME
and ci.CIRT_NAME = pl.PORL_CIRT_NAME
and pl.PORL_ID = plp.POLP_PORL_ID
and plp.POLP_PORT_ID = po.PORT_ID
and so.SERO_ID = p_sero_id
AND po.PORT_NAME LIKE 'DSL-IN-%'
AND po.PORT_CARD_SLOT like 'H%';


BEGIN

      OPEN c_so_order_id;
      FETCH c_so_order_id    INTO p_sero_id;
      CLOSE c_so_order_id;

      OPEN c_hu_msan_port_details;
      FETCH c_hu_msan_port_details INTO v_card_slot,v_shelf,v_slot,v_port;
      CLOSE c_hu_msan_port_details;


      IF v_card_slot is not null THEN


      RETURN v_port;

      ELSE

      RETURN null;

      END IF;



EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

END GET_HUAWEI5_PORT;
---- Samankula Owitipana 2014 10 21

------Dinesh Perera 23-12-2014----
FUNCTION GET_SIP_URL (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_NUMB_TYPE (T_SEIT_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT SEOA_DEFAULTVALUE
            FROM SERVICE_ORDER_ATTRIBUTES
            WHERE   SEOA_SERO_ID=T_SEIT_ID
            AND     SEOA_NAME='SA_PSTN_NUMBER';


        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_SERV_ID           SERVICE_ORDERS.SERO_SERV_ID%TYPE;
        V_NUMB_TYPE         VARCHAR2(20);


      L_URL               VARCHAR2(100);
      L_PREFIX            VARCHAR2(100) := 'sip:';   ---- Removed 94
      L_SUFFIX            VARCHAR2(100) := '@22.1.2.9';



   BEGIN

      OPEN C_SERO_ID;
      FETCH C_SERO_ID       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;


      OPEN C_NUMB_TYPE (V_SEIT_SERO_ID);
      FETCH C_NUMB_TYPE     INTO V_NUMB_TYPE;
      CLOSE C_NUMB_TYPE;


      IF V_NUMB_TYPE IS NOT NULL THEN

        L_URL:= L_PREFIX || V_NUMB_TYPE || L_SUFFIX ;

      ELSE

        L_URL:=NULL;

      END IF;

   RETURN L_URL;

     EXCEPTION
      WHEN OTHERS
      THEN
        RETURN NULL;

   END GET_SIP_URL;
------Dinesh Perera 23-12-2014----

---- Samankula Owitipana 2014 11 24

FUNCTION GET_FTTH_VIRTUAL_PORT (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      v_virt_port      number;
      v_port           number;
      v_card_slot      VARCHAR2(50);
      v_cct_name       VARCHAR2(50);
      p_sero_id        VARCHAR2(50);


CURSOR c_so_order_id IS
SELECT so.sero_id,so.SERO_CIRT_NAME
FROM service_implementation_tasks sit,service_orders so
WHERE so.sero_id = sit.seit_sero_id
AND sit.SEIT_ID = pi_seit_id;

cursor c_virtual_port_and_port is
select po.PORT_CARD_SLOT,substr(po.PORT_NAME,instr(po.PORT_NAME,'-')+1,3),substr(po.PORT_NAME,1,instr(po.PORT_NAME,'-')-1)
from port_links pl,port_link_ports plp,ports po,cards ca
where pl.PORL_CIRT_NAME = v_cct_name
and pl.PORL_ID = plp.POLP_PORL_ID
and plp.POLP_PORT_ID = po.PORT_ID
and po.PORT_EQUP_ID = ca.CARD_EQUP_ID
and po.PORT_CARD_SLOT = ca.CARD_SLOT
and (po.PORT_NAME NOT LIKE 'P%' and po.PORT_NAME NOT LIKE 'L%')
and ca.CARD_MODEL LIKE 'GPON%';



BEGIN

      OPEN c_so_order_id;
      FETCH c_so_order_id    INTO p_sero_id,v_cct_name;
      CLOSE c_so_order_id;

      OPEN c_virtual_port_and_port;
      FETCH c_virtual_port_and_port INTO v_card_slot,v_virt_port,v_port;
      CLOSE c_virtual_port_and_port;


      IF v_card_slot is not null THEN


      RETURN v_virt_port;

      ELSE

      RETURN null;

      END IF;



EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

END GET_FTTH_VIRTUAL_PORT;

---- Samankula Owitipana 2014 11 24

---- Samankula Owitipana 2014 12 12

FUNCTION GET_FTTH_ZTE_PID (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      v_slot           number;
      v_port           number;
      v_card_slot      VARCHAR2(50);
      v_cct_name       VARCHAR2(50);
      p_sero_id        VARCHAR2(50);


CURSOR c_so_order_id IS
SELECT so.sero_id,so.SERO_CIRT_NAME
FROM service_implementation_tasks sit,service_orders so
WHERE so.sero_id = sit.seit_sero_id
AND sit.SEIT_ID = pi_seit_id;

cursor c_virtual_port_and_port is
select po.PORT_CARD_SLOT,to_number(replace(replace(substr(po.PORT_CARD_SLOT,-2,2),'-',''),'.','')),
replace(substr(po.PORT_NAME,1,instr(po.PORT_NAME,'-')-1),'-0','')
from port_links pl,port_link_ports plp,ports po,cards ca
where pl.PORL_CIRT_NAME = v_cct_name
and pl.PORL_ID = plp.POLP_PORL_ID
and plp.POLP_PORT_ID = po.PORT_ID
and po.PORT_EQUP_ID = ca.CARD_EQUP_ID
and po.PORT_CARD_SLOT = ca.CARD_SLOT
and (po.PORT_NAME NOT LIKE 'P%' and po.PORT_NAME NOT LIKE 'L%')
and ca.CARD_MODEL LIKE 'GPON%';



BEGIN

      OPEN c_so_order_id;
      FETCH c_so_order_id    INTO p_sero_id,v_cct_name;
      CLOSE c_so_order_id;

      OPEN c_virtual_port_and_port;
      FETCH c_virtual_port_and_port INTO v_card_slot,v_slot,v_port;
      CLOSE c_virtual_port_and_port;


      IF v_card_slot is not null THEN

      v_card_slot := '1-1-' || v_slot  || '-' || v_port;

      RETURN v_card_slot;

      ELSE

      RETURN null;

      END IF;



EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

END GET_FTTH_ZTE_PID;

---- Samankula Owitipana 2014 12 12

---Samankula Owitipana 25-11-2014----

 FUNCTION GET_FTTH_SERVICE_TYPE (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

         CURSOR c_so_order_type IS
         SELECT so.sero_id,so.SERO_SERT_ABBREVIATION
         FROM service_implementation_tasks sit,service_orders so
         WHERE so.sero_id = sit.seit_sero_id
         AND sit.SEIT_ID = pi_seit_id;



      V_SERO_ID             service_orders.sero_id%TYPE;
      V_SERVICE_TYPE        service_orders.SERO_SERT_ABBREVIATION%TYPE;
      V_SF_NAME             SERVICE_ORDER_FEATURES.SOFE_FEATURE_NAME%TYPE;


      L_RT_TYPE             VARCHAR2(50);




   BEGIN
      OPEN c_so_order_type;
      FETCH c_so_order_type    INTO V_SERO_ID,V_SERVICE_TYPE;
      CLOSE c_so_order_type;




      IF V_SERVICE_TYPE = 'V-VOICE FTTH' THEN

         L_RT_TYPE := 'FTH_VOICE';

      ELSIF V_SERVICE_TYPE = 'BB-INTERNET FTTH'   THEN

          L_RT_TYPE := 'FTH_BB';

      ELSIF V_SERVICE_TYPE = 'E-IPTV FTTH' THEN

          L_RT_TYPE := 'FTH_IPTV';

      ELSE

          L_RT_TYPE :=NULL;

      END IF;


      RETURN L_RT_TYPE;

   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END get_ftth_service_type;

---Samankula Owitipana 25-11-2014----

---- Samankula Owitipana 2014 11 27

FUNCTION GET_FTTH_SHELF (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      v_shelf          number;
      v_slot           number;
      v_card_slot      VARCHAR2(50);
      v_cct_name       VARCHAR2(50);
      p_sero_id        VARCHAR2(50);


CURSOR c_so_order_id IS
SELECT so.sero_id,so.SERO_CIRT_NAME
FROM service_implementation_tasks sit,service_orders so
WHERE so.sero_id = sit.seit_sero_id
AND sit.SEIT_ID = pi_seit_id;

cursor c_card_shelf_and_slot is
select po.PORT_CARD_SLOT,to_number(replace(replace(substr(po.PORT_CARD_SLOT,-5,2),'-',''),'.','')),
to_number(replace(replace(substr(po.PORT_CARD_SLOT,-2,2),'-',''),'.',''))
from port_links pl,port_link_ports plp,ports po,cards ca
where pl.PORL_CIRT_NAME = v_cct_name
and pl.PORL_ID = plp.POLP_PORL_ID
and plp.POLP_PORT_ID = po.PORT_ID
and po.PORT_EQUP_ID = ca.CARD_EQUP_ID
and po.PORT_CARD_SLOT = ca.CARD_SLOT
and (po.PORT_NAME NOT LIKE 'P%' and po.PORT_NAME NOT LIKE 'L%')
and ca.CARD_MODEL like 'GPON%';



BEGIN

      OPEN c_so_order_id;
      FETCH c_so_order_id    INTO p_sero_id,v_cct_name;
      CLOSE c_so_order_id;

      OPEN c_card_shelf_and_slot;
      FETCH c_card_shelf_and_slot INTO v_card_slot,v_shelf,v_slot;
      CLOSE c_card_shelf_and_slot;


      IF v_card_slot is not null THEN


      RETURN v_shelf;

      ELSE

      RETURN null;

      END IF;



EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

END GET_FTTH_SHELF;

---- Samankula Owitipana 2014 11 27

---- Samankula Owitipana 2014 11 24

FUNCTION GET_FTTH_PORT (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      v_virt_port      number;
      v_port           number;
      v_card_slot      VARCHAR2(50);
      v_cct_name       VARCHAR2(50);
      p_sero_id        VARCHAR2(50);


CURSOR c_so_order_id IS
SELECT so.sero_id,so.SERO_CIRT_NAME
FROM service_implementation_tasks sit,service_orders so
WHERE so.sero_id = sit.seit_sero_id
AND sit.SEIT_ID = pi_seit_id;

cursor c_virtual_port_and_port is
select po.PORT_CARD_SLOT,substr(po.PORT_NAME,instr(po.PORT_NAME,'-')+1,3),substr(po.PORT_NAME,1,instr(po.PORT_NAME,'-')-1)
from port_links pl,port_link_ports plp,ports po,cards ca
where pl.PORL_CIRT_NAME = v_cct_name
and pl.PORL_ID = plp.POLP_PORL_ID
and plp.POLP_PORT_ID = po.PORT_ID
and po.PORT_EQUP_ID = ca.CARD_EQUP_ID
and po.PORT_CARD_SLOT = ca.CARD_SLOT
and (po.PORT_NAME NOT LIKE 'P%' and po.PORT_NAME NOT LIKE 'L%')
and ca.CARD_MODEL like 'GPON%';



BEGIN

      OPEN c_so_order_id;
      FETCH c_so_order_id    INTO p_sero_id,v_cct_name;
      CLOSE c_so_order_id;

      OPEN c_virtual_port_and_port;
      FETCH c_virtual_port_and_port INTO v_card_slot,v_virt_port,v_port;
      CLOSE c_virtual_port_and_port;


      IF v_card_slot is not null THEN


      RETURN v_port;

      ELSE

      RETURN null;

      END IF;



EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

END GET_FTTH_PORT;

---- Samankula Owitipana 2014 11 24

-- -- Samitha Sagara 30032015 IPTV PRV PKG
FUNCTION get_iptv_prvpkg (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


      L_PRV_IPTVPKG             VARCHAR2(40);

    cursor c_iptv_prvpkg is
    SELECT  SEOA_PREV_VALUE
            FROM   SERVICE_ORDER_ATTRIBUTES SOA,service_implementation_tasks sit
            WHERE  SOA.SEOA_SERO_ID = sit.SEIT_SERO_ID
            And SEOA_NAME='IPTV_PACKAGE'
            AND SOA.SEOA_SOFE_ID IS NULL
            AND sit.SEIT_ID = pi_seit_id;

BEGIN

open c_iptv_prvpkg;
fetch c_iptv_prvpkg into L_PRV_IPTVPKG;
close c_iptv_prvpkg;


RETURN L_PRV_IPTVPKG;


EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
END get_iptv_prvpkg;

---- Samitha Sagara 30032015  FINISH IPTV PRV PKG

---- -- LTE Voice Check Dhanushka 04042015
-- Edited by Samitha Sagara 29042015
FUNCTION GET_LTE_VOICEID (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


      V_VOICE_ID      VARCHAR2(50);

BEGIN

SELECT c.CIRT_SERT_ABBREVIATION INTO V_VOICE_ID
FROM service_implementation_tasks sit,service_orders so ,SERVICE_ORDER_ATTRIBUTES soa,circuits c
WHERE so.sero_id = sit.seit_sero_id
and c.CIRT_SERT_ABBREVIATION = 'V-VOICE'
and c.CIRT_ACCT_NUMBER = so.SERO_ACCT_NUMBER
and c.CIRT_CUSR_ABBREVIATION = so.SERO_CUSR_ABBREVIATION
and c.CIRT_DISPLAYNAME = concat(substr(soa.SEOA_DEFAULTVALUE,4,10),'(N)')
and soa.SEOA_NAME = 'ACCESS PIPE IDENTIFIER'
and so.SERO_ID =  soa.SEOA_SERO_ID
AND sit.SEIT_ID = pi_seit_id;



      RETURN V_VOICE_ID;




EXCEPTION
      WHEN OTHERS
      THEN
         RETURN 'BB-INT-null '||pi_seit_id;

END GET_LTE_VOICEID;

---- -- LTE Voice Check Dhanushka 04042015 Finish

-- Samankula Owitipana 2015 01 19 RTOM with R
FUNCTION get_so_rtom_area (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


      L_SO_RTOM             VARCHAR2(20);

    cursor c_rtom_area is
    SELECT replace(ar.AREA_AREA_CODE,'R-','')
    FROM SERVICE_ORDERS SO,service_implementation_tasks sit,areas ar
    WHERE sit.SEIT_ID = pi_seit_id
    AND SO.SERO_ID = sit.SEIT_SERO_ID
    and so.SERO_AREA_CODE = ar.AREA_CODE ;


BEGIN

open c_rtom_area;
fetch c_rtom_area into L_SO_RTOM;
close c_rtom_area;

      RETURN L_SO_RTOM;

EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
END get_so_rtom_area;

---- Samankula Owitipana 2015 01 19 Finish RTOM with R


 -- Samitha Sagara 30032015 IPTV Customer City
FUNCTION GET_CUST_CITYNAME (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


      L_SO_CUST_CITY            VARCHAR2(200);

    cursor c_cus_address is
    SELECT AD.ADDE_CITY AS "CUSTCITY"
    FROM SERVICE_ORDERS SO,service_implementation_tasks sit,ADDRESSES AD
    WHERE sit.SEIT_ID = pi_seit_id
    AND SO.SERO_ID = sit.SEIT_SERO_ID
    AND SO.SERO_ADDE_ID_BEND = AD.ADDE_ID;


BEGIN

open c_cus_address;
fetch c_cus_address into L_SO_CUST_CITY;
close c_cus_address;

      RETURN L_SO_CUST_CITY;

EXCEPTION
      WHEN OTHERS
      THEN
         RETURN 'NOVAL';
END GET_CUST_CITYNAME;

 -- Samitha Sagara 30032015 Finish IPTV Customer City

---- Samankula Owitipana 2014 11 27

FUNCTION GET_FTTH_SLOT (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      v_shelf          number;
      v_slot           number;
      v_card_slot      VARCHAR2(50);
      v_cct_name       VARCHAR2(50);
      p_sero_id        VARCHAR2(50);


CURSOR c_so_order_id IS
SELECT so.sero_id,so.SERO_CIRT_NAME
FROM service_implementation_tasks sit,service_orders so
WHERE so.sero_id = sit.seit_sero_id
AND sit.SEIT_ID = pi_seit_id;

cursor c_card_shelf_and_slot is
select po.PORT_CARD_SLOT,to_number(replace(replace(substr(po.PORT_CARD_SLOT,-5,2),'-',''),'.','')),
to_number(replace(replace(substr(po.PORT_CARD_SLOT,-2,2),'-',''),'.',''))
from port_links pl,port_link_ports plp,ports po,cards ca
where pl.PORL_CIRT_NAME = v_cct_name
and pl.PORL_ID = plp.POLP_PORL_ID
and plp.POLP_PORT_ID = po.PORT_ID
and po.PORT_EQUP_ID = ca.CARD_EQUP_ID
and po.PORT_CARD_SLOT = ca.CARD_SLOT
and (po.PORT_NAME NOT LIKE 'P%' and po.PORT_NAME NOT LIKE 'L%')
and ca.CARD_MODEL like 'GPON%';



BEGIN

      OPEN c_so_order_id;
      FETCH c_so_order_id    INTO p_sero_id,v_cct_name;
      CLOSE c_so_order_id;

      OPEN c_card_shelf_and_slot;
      FETCH c_card_shelf_and_slot INTO v_card_slot,v_shelf,v_slot;
      CLOSE c_card_shelf_and_slot;


      IF v_card_slot is not null THEN


      RETURN v_slot;

      ELSE

      RETURN null;

      END IF;



EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

END GET_FTTH_SLOT;
---- Samankula Owitipana 2014 11 27

---- Dhanushka Fernando 04-10-2015

FUNCTION GET_PSTN_VAS (

      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2

   )
      RETURN VARCHAR2
   IS

        VAL                 SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE ;
        PRE_VAL             SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE ;
        R_VAL                 VARCHAR2(5);
        SO_ID                 SERVICE_ORDERS.SERO_ID%TYPE;


   BEGIN

        SELECT  TB1.SEIT_SERO_ID  INTO SO_ID FROM SERVICE_IMPLEMENTATION_TASKS TB1 WHERE TB1.SEIT_ID = pi_seit_id;

        BEGIN
        SELECT TB2.SEOA_DEFAULTVALUE  ,  TB2.SEOA_PREV_VALUE INTO VAL,PRE_VAL  FROM SERVICE_ORDER_ATTRIBUTES TB2 WHERE TB2.SEOA_SERO_ID = SO_ID  AND TB2.SEOA_NAME = 'SA_IMS_PACKAGE';

         EXCEPTION
                            WHEN NO_DATA_FOUND  THEN VAL := 'ER';
        END;



                        IF VAL =  PRE_VAL
                         THEN    R_VAL := 'NO';
                        ELSIF   VAL= 'ER'  THEN R_VAL := 'ER';
                        ELSE   R_VAL := 'YES';
                        END IF;


          RETURN R_VAL;

   END GET_PSTN_VAS;

---- Dhanushka Fernando 04-10-2015

---- Dhanushka Fernando 29-09-2015

FUNCTION GET_PSTN_FEATURES_MODIFY (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS
    VAS_FEATURES_NAME     OSSRPT.PSTN_VAS_TEMPLATE.VAS_FEATURES_NAME %TYPE;
        PSTN_FEATURE_NAME      OSSRPT.PSTN_FEATURES.FEATURE_NAME%TYPE;
        VAL                    VARCHAR2(5);
        PRE_VAL            VARCHAR2(5);
        F_VAL                VARCHAR2(5);
        FEATURE_COMP  VARCHAR2(5);
        FINAL_RESULT    VARCHAR2(50) := '';
        VAS_PKG            VARCHAR2(20);
        T_VAL                VARCHAR2(2):='F';
        CF_ACTIVE         VARCHAR2(2):='0';
        SO_ID                 SERVICE_ORDERS.SERO_ID%TYPE;

    CURSOR PSTN_FEATURES  IS
               SELECT  FEATURE_NAME FROM OSSRPT.PSTN_FEATURES  ORDER BY ID;

        CURSOR VAS_FEATURES (PKG OSSRPT.PSTN_VAS_TEMPLATE.VAS_FEATURES_NAME %TYPE) IS
               SELECT DISTINCT VAS_FEATURES_NAME FROM OSSRPT.PSTN_VAS_TEMPLATE
               WHERE VAS_TYPE = PKG;


   BEGIN

        SELECT  TB1.SEIT_SERO_ID  INTO SO_ID FROM SERVICE_IMPLEMENTATION_TASKS TB1 WHERE TB1.SEIT_ID = pi_seit_id;
        BEGIN
        SELECT TB2.SEOA_DEFAULTVALUE INTO VAS_PKG  FROM SERVICE_ORDER_ATTRIBUTES TB2 WHERE TB2.SEOA_SERO_ID = SO_ID  AND TB2.SEOA_NAME = 'SA_IMS_PACKAGE';

         EXCEPTION
                            WHEN NO_DATA_FOUND  THEN VAS_PKG := '';
        END;


        OPEN PSTN_FEATURES;
     LOOP
        FETCH PSTN_FEATURES INTO PSTN_FEATURE_NAME;
        EXIT WHEN PSTN_FEATURES%NOTFOUND;

          FEATURE_COMP := 'F';

     OPEN VAS_FEATURES(VAS_PKG);
     LOOP

     FETCH VAS_FEATURES INTO VAS_FEATURES_NAME;
     EXIT WHEN VAS_FEATURES%NOTFOUND;

        IF VAS_FEATURES_NAME = PSTN_FEATURE_NAME
        THEN FEATURE_COMP := 'T';
                VAL := 'N';
                PRE_VAL := 'N';
                EXIT;
        END IF;

     END LOOP;
     CLOSE VAS_FEATURES;

     IF FEATURE_COMP = 'T'
     THEN GOTO SKIP_SEARCH;
     END IF;


                  BEGIN

                     SELECT NVL(TB3.SOFE_DEFAULTVALUE,'N'), NVL(TB3.SOFE_PREV_VALUE,'N') INTO VAL,PRE_VAL  FROM SERVICE_ORDER_FEATURES  TB3
                     WHERE TB3.SOFE_FEATURE_NAME =  PSTN_FEATURE_NAME
                     AND TB3.SOFE_SERO_ID = SO_ID;



                        EXCEPTION
                            WHEN NO_DATA_FOUND THEN VAL := 'N';


                    END;

                    <<SKIP_SEARCH>>

                        IF VAL =  PRE_VAL
                         THEN    F_VAL := '0';
                        ELSIF VAL = 'Y'  AND PRE_VAL = 'N'
                         THEN    F_VAL := '1';
                         T_VAL := 'A';
                          ELSIF VAL = 'N'  AND PRE_VAL = 'Y'
                         THEN    F_VAL := '2';
                         T_VAL := 'A';
                        END IF;

                        IF PSTN_FEATURE_NAME LIKE '%_CF_%'  AND CF_ACTIVE = '0'
                        THEN CF_ACTIVE :='1';
                        END IF;

                        FINAL_RESULT := FINAL_RESULT||F_VAL;


                END LOOP;
                CLOSE PSTN_FEATURES;

           RETURN T_VAL||CF_ACTIVE||FINAL_RESULT;

   END GET_PSTN_FEATURES_MODIFY;


---- Dhanushka Fernando 29-09-2015

---- Dhanushka Fernando 29-09-2015

FUNCTION GET_PSTN_FEATURES (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


        VAS_FEATURES_NAME     OSSRPT.PSTN_VAS_TEMPLATE.VAS_FEATURES_NAME %TYPE;
        PSTN_FEATURE_NAME      OSSRPT.PSTN_FEATURES.FEATURE_NAME%TYPE;
        VAL                    VARCHAR2(5);
        F_VAL                VARCHAR2(5);
        FEATURE_COMP    VARCHAR2(5);
        FINAL_RESULT    VARCHAR2(50) := '';
        VAS_PKG            VARCHAR2(20);
        T_VAL                VARCHAR2(2):='F';
        CF_ACTIVE         VARCHAR2(2):='0';
        SO_ID                 SERVICE_ORDERS.SERO_ID%TYPE;

        CURSOR PSTN_FEATURES  IS
               SELECT  FEATURE_NAME FROM OSSRPT.PSTN_FEATURES  ORDER BY ID;

        CURSOR VAS_FEATURES (PKG OSSRPT.PSTN_VAS_TEMPLATE.VAS_FEATURES_NAME %TYPE) IS
               SELECT DISTINCT VAS_FEATURES_NAME FROM OSSRPT.PSTN_VAS_TEMPLATE
               WHERE VAS_TYPE = PKG;


   BEGIN

        SELECT  TB1.SEIT_SERO_ID  INTO SO_ID FROM SERVICE_IMPLEMENTATION_TASKS TB1 WHERE TB1.SEIT_ID = pi_seit_id   ;

        BEGIN
        SELECT TB2.SEOA_DEFAULTVALUE INTO VAS_PKG  FROM SERVICE_ORDER_ATTRIBUTES TB2 WHERE TB2.SEOA_SERO_ID = SO_ID  AND TB2.SEOA_NAME = 'SA_IMS_PACKAGE';

        EXCEPTION
                            WHEN NO_DATA_FOUND  THEN VAS_PKG := '';
        END;


        OPEN PSTN_FEATURES;
     LOOP
        FETCH PSTN_FEATURES INTO PSTN_FEATURE_NAME;
        EXIT WHEN PSTN_FEATURES%NOTFOUND;

          FEATURE_COMP := 'F';

     OPEN VAS_FEATURES(VAS_PKG);
     LOOP

     FETCH VAS_FEATURES INTO VAS_FEATURES_NAME;
     EXIT WHEN VAS_FEATURES%NOTFOUND;

        IF VAS_FEATURES_NAME = PSTN_FEATURE_NAME
        THEN FEATURE_COMP := 'T';
                VAL := 'N';
        END IF;

     END LOOP;
     CLOSE VAS_FEATURES;

     IF FEATURE_COMP = 'T'
     THEN GOTO SKIP_SEARCH;
     END IF;

                  BEGIN



                     SELECT TB3.SOFE_DEFAULTVALUE INTO VAL  FROM SERVICE_ORDER_FEATURES  TB3
                     WHERE TB3.SOFE_FEATURE_NAME =  PSTN_FEATURE_NAME
                     AND TB3.SOFE_SERO_ID = SO_ID;

                     IF PSTN_FEATURE_NAME = 'SF_IDD'
                     THEN VAL := 'N';
                     END IF;



                        EXCEPTION
                            WHEN NO_DATA_FOUND THEN VAL := 'N';


                    END;


                  <<SKIP_SEARCH>>

                        IF VAL = 'Y'
                         THEN    F_VAL := '1';
                         T_VAL := 'A';
                        ELSE
                        F_VAL := '0';
                        END IF;

                        IF PSTN_FEATURE_NAME LIKE '%_CF_%'  AND CF_ACTIVE = '0'
                        THEN CF_ACTIVE :='1';
                        END IF;

                        FINAL_RESULT := FINAL_RESULT||F_VAL;


                END LOOP;
                CLOSE PSTN_FEATURES;

           RETURN T_VAL||CF_ACTIVE||FINAL_RESULT;


   END GET_PSTN_FEATURES;

---- Dhanushka Fernando 29-09-2015

---- Samitha Sagara 2015 09 07
FUNCTION GET_TP_ADSL (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS


      L_RT_PSTN_MDN             VARCHAR2(100);

   BEGIN


    SELECT '94' || substr(trim(SOA.SEOA_DEFAULTVALUE),-9)
    INTO L_RT_PSTN_MDN
    FROM SERVICE_ORDER_ATTRIBUTES SOA,service_implementation_tasks sit
    WHERE sit.SEIT_ID = pi_seit_id
    AND SOA.SEOA_SERO_ID = sit.SEIT_SERO_ID
    AND SOA.SEOA_NAME = 'SA_PSTN_NUMBER';


      RETURN L_RT_PSTN_MDN;

   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN 'ERROR ON OPERATION';

   END GET_TP_ADSL;

---- Samitha Sagara 2015 09 07

---- Samitha Sagara 2015 09 07
FUNCTION GET_IMS_PID (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_SERV_ID (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT DISTINCT(SERO_CIRT_NAME),SERO_SERT_ABBREVIATION
            FROM SERVICE_ORDERS
            WHERE SERO_ID=T_SERO_ID;

      CURSOR C_GET_P_NUMBER (T_CRT_ID SERVICE_ORDERS.SERO_CIRT_NAME%TYPE) IS

            SELECT  MAX(CIRT_NAME)
            FROM    CIRCUITS
            WHERE   CIRT_NAME  =T_CRT_ID
            AND     CIRT_STATUS !='PENDINGDELETE';

      CURSOR C_GET_TIDNAME (T_CRT_ID SERVICE_ORDERS.SERO_CIRT_NAME%TYPE) IS

            SELECT  PO.PORT_NAME,PO.PORT_CARD_SLOT
            FROM    PORTS PO,PORT_LINKS PL,PORT_LINK_PORTS PLP
            WHERE   PO.PORT_ID=PLP.POLP_PORT_ID
            AND     PL.PORL_ID=PLP.POLP_PORL_ID
            AND     PL.PORL_CIRT_NAME= T_CRT_ID
            AND     PO.PORT_USAGE='SERVICE_SWITCHING_POINT';




        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_CRT_ID            SERVICE_ORDERS.SERO_SERV_ID%TYPE;
        V_SERO_TYPE         SERVICE_ORDERS.SERO_SERT_ABBREVIATION%TYPE;
        V_CIRCUIT_ID        CIRCUITS.CIRT_NAME%TYPE;
        V_PORT_CARD_SLOT    PORTS.PORT_CARD_SLOT%TYPE;
        V_PORT_NAME         PORTS.PORT_NAME%TYPE;


      L_TEMP_CODE         VARCHAR2(20);
      L_TIDNAME           VARCHAR2(20);



   BEGIN

      OPEN C_SERO_ID;       FETCH C_SERO_ID
       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;

      OPEN C_SERV_ID (V_SEIT_SERO_ID);
      FETCH C_SERV_ID     INTO V_CRT_ID,V_SERO_TYPE;
      CLOSE C_SERV_ID;

      OPEN C_GET_P_NUMBER (V_CRT_ID);
      FETCH C_GET_P_NUMBER INTO V_CIRCUIT_ID;
      CLOSE C_GET_P_NUMBER;


      OPEN C_GET_TIDNAME (V_CRT_ID);
      FETCH C_GET_TIDNAME INTO V_PORT_NAME,V_PORT_CARD_SLOT;
      CLOSE C_GET_TIDNAME;


      IF V_PORT_CARD_SLOT IS NOT NULL AND V_PORT_NAME IS NOT NULL THEN



            L_TIDNAME:=REPLACE(SUBSTR(V_PORT_CARD_SLOT,2),'-','')||SUBSTR(V_PORT_NAME,-2);


      ELSE

       L_TIDNAME:='PORT ISSUE';

      END IF;

    RETURN L_TIDNAME;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN 'ERROR ON OPERATION';

   END GET_IMS_PID;
---- Samitha Sagara 2015 09 07

---- Samitha Sagara 2015 10 11
FUNCTION GET_IMSEQ_IP (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR C_SERO_ID IS
            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_SERV_ID (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS
            SELECT DISTINCT(SERO_CIRT_NAME),SERO_SERT_ABBREVIATION
            FROM SERVICE_ORDERS
            WHERE SERO_ID=T_SERO_ID;


      CURSOR C_GET_TIDNAME (T_CRT_ID SERVICE_ORDERS.SERO_CIRT_NAME%TYPE) IS
            SELECT  DISTINCT PO.PORT_CARD_SLOT,po.PORT_EQUP_ID
            FROM    PORTS PO,PORT_LINKS PL,PORT_LINK_PORTS PLP
            WHERE   PO.PORT_ID=PLP.POLP_PORT_ID
            AND     PL.PORL_ID=PLP.POLP_PORL_ID
            AND     PL.PORL_CIRT_NAME= T_CRT_ID
            AND     PO.PORT_NAME like 'POTS-%'
            AND     po.PORT_CARD_SLOT <> 'NA';

            CURSOR C_GET_IP_ADDRESS (T_EQUIP_ID EQUIPMENT.EQUP_ID%TYPE) IS
            select eq.EQUP_IPADDRESS from equipment eq
            where eq.EQUP_ID = T_EQUIP_ID
            and EQUP_EQUT_ABBREVIATION like 'MSAN-%';



        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_CRT_ID            SERVICE_ORDERS.SERO_SERV_ID%TYPE;
        V_SERO_TYPE         SERVICE_ORDERS.SERO_SERT_ABBREVIATION%TYPE;
        V_CIRCUIT_ID        CIRCUITS.CIRT_NAME%TYPE;
        V_PORT_CARD_SLOT    PORTS.PORT_CARD_SLOT%TYPE;
        V_PORT_NAME         PORTS.PORT_NAME%TYPE;
        V_EQUIP_ID          EQUIPMENT.EQUP_ID%TYPE;
        V_IP_ADD            EQUIPMENT.EQUP_IPADDRESS%TYPE;


      L_TEMP_CODE         VARCHAR2(20);
      L_TIDNAME           VARCHAR2(20);



   BEGIN

      OPEN C_SERO_ID;       FETCH C_SERO_ID
       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;

      OPEN C_SERV_ID (V_SEIT_SERO_ID);
      FETCH C_SERV_ID     INTO V_CRT_ID,V_SERO_TYPE;
      CLOSE C_SERV_ID;


      OPEN C_GET_TIDNAME (V_CRT_ID);
      FETCH C_GET_TIDNAME INTO V_PORT_CARD_SLOT,V_EQUIP_ID;
      CLOSE C_GET_TIDNAME;

      OPEN C_GET_IP_ADDRESS (V_EQUIP_ID);
      FETCH C_GET_IP_ADDRESS INTO V_IP_ADD;
      CLOSE C_GET_IP_ADDRESS;




    RETURN V_IP_ADD;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_IMSEQ_IP;

---- Samitha Sagara 2015 10 11

---Dhanushka Fernando 04112015

FUNCTION GET_PSTN_AREACODE (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

        PSTN_NO            VARCHAR2(4);
        SO_ID                 SERVICE_ORDERS.SERO_ID%TYPE;

   BEGIN

        SELECT  TB1.SEIT_SERO_ID  INTO SO_ID FROM SERVICE_IMPLEMENTATION_TASKS TB1 WHERE TB1.SEIT_ID = pi_seit_id    ;

        BEGIN
        SELECT SUBSTR(TB2.SEOA_DEFAULTVALUE ,2,2)  INTO PSTN_NO  FROM SERVICE_ORDER_ATTRIBUTES TB2 WHERE TB2.SEOA_SERO_ID = SO_ID  AND TB2.SEOA_NAME = 'SA_PSTN_NUMBER';

         EXCEPTION
                            WHEN NO_DATA_FOUND  THEN PSTN_NO := '';
        END;


           RETURN PSTN_NO;

   END GET_PSTN_AREACODE;


---Dhanushka Fernando 06112015

---Dhanushka Fernando 06112015

FUNCTION GET_PSTN_PHNCON (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

        VAL                     VARCHAR2(30);
        PSTN_NO            VARCHAR2(5);
        SO_ID                 SERVICE_ORDERS.SERO_ID%TYPE;

   BEGIN

        SELECT  TB1.SEIT_SERO_ID  INTO SO_ID FROM SERVICE_IMPLEMENTATION_TASKS TB1 WHERE TB1.SEIT_ID = pi_seit_id    ;

        BEGIN
        SELECT SUBSTR(TB2.SEOA_DEFAULTVALUE ,2,2)  INTO PSTN_NO  FROM SERVICE_ORDER_ATTRIBUTES TB2 WHERE TB2.SEOA_SERO_ID = SO_ID  AND TB2.SEOA_NAME = 'SA_PSTN_NUMBER';

         EXCEPTION
                            WHEN NO_DATA_FOUND  THEN PSTN_NO := '';
        END;


        BEGIN
        SELECT PHNCON INTO VAL FROM OSSPRG.PSTN_SOURCE_CODE WHERE PSTN_CODE = PSTN_NO;
             EXCEPTION
                            WHEN NO_DATA_FOUND  THEN VAL := 'UNKNOWN';
        END;

           RETURN VAL;
 END GET_PSTN_PHNCON;

---Dhanushka Fernando 06112015

---Dhanushka Fernando 06112015

FUNCTION GET_PSTN_NETINFO (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

        VAL                     VARCHAR2(30);
        PSTN_NO            VARCHAR2(5);
        SO_ID                 SERVICE_ORDERS.SERO_ID%TYPE;

   BEGIN

        SELECT  TB1.SEIT_SERO_ID  INTO SO_ID FROM SERVICE_IMPLEMENTATION_TASKS TB1 WHERE TB1.SEIT_ID = pi_seit_id    ;

        BEGIN
        SELECT SUBSTR(TB2.SEOA_DEFAULTVALUE ,2,2)  INTO PSTN_NO  FROM SERVICE_ORDER_ATTRIBUTES TB2 WHERE TB2.SEOA_SERO_ID = SO_ID  AND TB2.SEOA_NAME = 'SA_PSTN_NUMBER';

         EXCEPTION
                            WHEN NO_DATA_FOUND  THEN PSTN_NO := '';
        END;


        BEGIN
        SELECT NETINFO INTO VAL FROM OSSPRG.PSTN_SOURCE_CODE WHERE PSTN_CODE = PSTN_NO;
             EXCEPTION
                            WHEN NO_DATA_FOUND  THEN VAL := 'UNKNOWN';
        END;

           RETURN VAL;
 END GET_PSTN_NETINFO;


---Dhanushka Fernando 06112015


---- Dinesh Perera 16-09-2015 -----
FUNCTION GET_EQUIP_IP_HUAWEI (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR C_SERO_ID IS
            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_SERV_ID (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS
            SELECT DISTINCT(SERO_CIRT_NAME),SERO_SERT_ABBREVIATION
            FROM SERVICE_ORDERS
            WHERE SERO_ID = T_SERO_ID;


      CURSOR C_GET_TIDNAME (T_CRT_ID SERVICE_ORDERS.SERO_CIRT_NAME%TYPE) IS
            SELECT  PO.PORT_NAME,PO.PORT_CARD_SLOT,po.PORT_EQUP_ID
            FROM    PORTS PO,PORT_LINKS PL,PORT_LINK_PORTS PLP
            WHERE   PO.PORT_ID = PLP.POLP_PORT_ID
            AND     PL.PORL_ID = PLP.POLP_PORL_ID
            AND     PL.PORL_CIRT_NAME = T_CRT_ID
            AND     ((PO.PORT_NAME LIKE 'POTS-IN-%') OR (PO.PORT_NAME LIKE 'POTS-OUT-%'))
            AND     po.PORT_CARD_SLOT <> 'NA';

       CURSOR C_GET_IP_ADDRESS (T_EQUIP_ID EQUIPMENT.EQUP_ID%TYPE) IS
            SELECT eq.EQUP_IPADDRESS || ':2944'
            FROM equipment eq
            WHERE eq.EQUP_ID = T_EQUIP_ID
            AND EQUP_EQUT_ABBREVIATION LIKE 'MSAN-%';



        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_CRT_ID            SERVICE_ORDERS.SERO_SERV_ID%TYPE;
        V_SERO_TYPE         SERVICE_ORDERS.SERO_SERT_ABBREVIATION%TYPE;
        V_CIRCUIT_ID        CIRCUITS.CIRT_NAME%TYPE;
        V_PORT_CARD_SLOT    PORTS.PORT_CARD_SLOT%TYPE;
        V_PORT_NAME         PORTS.PORT_NAME%TYPE;
        V_EQUIP_ID          EQUIPMENT.EQUP_ID%TYPE;
        V_IP_ADD            EQUIPMENT.EQUP_IPADDRESS%TYPE;


      L_TEMP_CODE         VARCHAR2(20);
      L_TIDNAME           VARCHAR2(20);



   BEGIN

      OPEN C_SERO_ID;       FETCH C_SERO_ID
       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;

      OPEN C_SERV_ID (V_SEIT_SERO_ID);
      FETCH C_SERV_ID     INTO V_CRT_ID,V_SERO_TYPE;
      CLOSE C_SERV_ID;


      OPEN C_GET_TIDNAME (V_CRT_ID);
      FETCH C_GET_TIDNAME INTO V_PORT_NAME,V_PORT_CARD_SLOT,V_EQUIP_ID;
      CLOSE C_GET_TIDNAME;

      OPEN C_GET_IP_ADDRESS (V_EQUIP_ID);
      FETCH C_GET_IP_ADDRESS INTO V_IP_ADD;
      CLOSE C_GET_IP_ADDRESS;




    RETURN V_IP_ADD;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_EQUIP_IP_HUAWEI;
---- Dinesh Perera 16-09-2015 -----

---- Jayan Liyanage 18-02-2016 ----
 FUNCTION GET_IPTV_CCT_ID (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

         
         Cursor Cur_IPTV_Mig_ID is           
         select distinct replace(substr(soa.seoa_defaultvalue,5),'(N)')
         from service_order_attributes soa,service_implementation_tasks sit
         where soa.seoa_sero_id = sit.seit_sero_id
         and soa.seoa_name = 'CIRCUIT ID'
         and sit.seit_id = pi_seit_id;


     v_IPTV_Num   service_order_attributes.seoa_defaultvalue%TYPE;


      P_IPTV_NUM             VARCHAR2(50);


   BEGIN
      OPEN Cur_IPTV_Mig_ID;
      FETCH Cur_IPTV_Mig_ID    INTO v_IPTV_Num;
      CLOSE Cur_IPTV_Mig_ID;

      

      IF v_IPTV_Num is not null then
      
      P_IPTV_NUM := v_IPTV_Num;
      
      END IF;
 

      RETURN P_IPTV_NUM;

   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
         
   END GET_IPTV_CCT_ID;  
---- Jayan Liyanage 18-02-2016 ----

---- Dhanushka Fernando 19-03-2016 ----
FUNCTION GET_OLD_PSTN (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS
        
        PSTN_NO                 SERVICE_ORDER_ATTRIBUTES.SEOA_PREV_VALUE%TYPE;
        
   BEGIN
   
   

SELECT concat('94',substr(SEOA_PREV_VALUE,2,9))  INTO PSTN_NO
from SERVICE_ORDER_ATTRIBUTES sa,SERVICE_IMPLEMENTATION_TASKS sit
where SA.SEOA_NAME = 'SA_PSTN_NUMBER'
and SA.SEOA_SERO_ID  = SIT.SEIT_SERO_ID
and SIT.SEIT_ID = pi_seit_id;
        
      RETURN PSTN_NO;  
        
         EXCEPTION 
                            WHEN NO_DATA_FOUND  THEN PSTN_NO := 'NA';
     
       
           RETURN PSTN_NO;
           
   END GET_OLD_PSTN;
   
---- Dhanushka Fernando 19-03-2016 ----


----- Dinesh 2016 03 14 ---- UID FTTH OLD -----
FUNCTION GET_UID_FTTH_OLD (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR C_SERO_ID IS

            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_EID (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS

            SELECT SEOA_PREV_VALUE
            FROM SERVICE_ORDER_ATTRIBUTES
            WHERE   SEOA_SERO_ID=T_SERO_ID
            AND     SEOA_NAME='ADSL_CIRCUIT_ID';


        V_SEIT_SERO_ID      SERVICE_ORDERS.SERO_ID%TYPE;
        V_EID               SERVICE_ORDER_ATTRIBUTES.SEOA_PREV_VALUE%TYPE;

        L_EID                VARCHAR2(20);



   BEGIN

      OPEN C_SERO_ID;       FETCH C_SERO_ID
       INTO V_SEIT_SERO_ID;
      CLOSE C_SERO_ID;

      OPEN C_EID (V_SEIT_SERO_ID);
      FETCH C_EID     INTO V_EID;
      CLOSE C_EID;



      IF V_EID IS NOT NULL THEN

        L_EID:= V_EID;

      ELSE

        L_EID:=NULL;

      END IF;

    RETURN L_EID;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_UID_FTTH_OLD;
----- Dinesh 2016 03 14 ---- UID FTTH OLD -----

---- Dinesh Perera 25-04-2016 ----
FUNCTION GET_FTTH_PROFILE (
      pi_seit_id   IN   service_implementation_tasks.seit_id%TYPE,
      pi_sopc_id   IN   sop_commands.sopc_id%TYPE,
      pi_param1    IN   VARCHAR2,
      pi_param2    IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS

      CURSOR C_SERO_ID IS
            SELECT  DISTINCT(SEIT_SERO_ID)
            FROM    SERVICE_IMPLEMENTATION_TASKS
            WHERE   SEIT_ID = PI_SEIT_ID;

      CURSOR C_IPTV_ID (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS
            SELECT SUBSTR(SEOA_DEFAULTVALUE,16)
            FROM SERVICE_ORDER_ATTRIBUTES
            WHERE SEOA_SERO_ID = T_SERO_ID
            AND SEOA_NAME = 'CIRCUIT ID';

      CURSOR C_FTTH_PKG (T_SERO_ID SERVICE_ORDERS.SERO_ID%TYPE) IS
            SELECT SEOA_DEFAULTVALUE
            FROM SERVICE_ORDER_ATTRIBUTES
            WHERE SEOA_SERO_ID = T_SERO_ID
            AND SEOA_NAME = 'SA_FTTH_PACKAGE';

        V_SERO_ID       SERVICE_ORDERS.SERO_ID%TYPE;
        V_IPTV_ID       NUMBER:=0;
        V_FTTH_PKG      SERVICE_ORDER_ATTRIBUTES.SEOA_DEFAULTVALUE%TYPE;

      L_TEMP_CODE         VARCHAR2(20);
      L_PROFILE           VARCHAR2(20);

   BEGIN

      OPEN C_SERO_ID;       
      FETCH C_SERO_ID     INTO V_SERO_ID;
      CLOSE C_SERO_ID;

      OPEN C_IPTV_ID(V_SERO_ID);
      FETCH C_IPTV_ID     INTO V_IPTV_ID;
      CLOSE C_IPTV_ID;

      OPEN C_FTTH_PKG(V_SERO_ID);
      FETCH C_FTTH_PKG    INTO V_FTTH_PKG;
      CLOSE C_FTTH_PKG;

      IF (V_IPTV_ID = '2' AND V_FTTH_PKG = 'VOICE_INT_IPTV') THEN

          L_TEMP_CODE := 'TRIPLEPLAY_MULTIIPTV';

      ELSIF (V_IPTV_ID = '2' AND V_FTTH_PKG = 'VOICE_IPTV') THEN

          L_TEMP_CODE := 'TRIPLEPLAY_MULTIIPTV';
      
      ELSIF (V_IPTV_ID = '2' AND V_FTTH_PKG = 'VOICE_INT') THEN

          L_TEMP_CODE := 'TRIPLEPLAY_BB';
          
      ELSIF (V_IPTV_ID <> '2' AND V_FTTH_PKG = 'VOICE_INT_IPTV') THEN

          L_TEMP_CODE := 'TRIPLEPLAY_BB';

      ELSIF (V_IPTV_ID <> '2' AND V_FTTH_PKG = 'VOICE_IPTV') THEN

          L_TEMP_CODE := 'TRIPLEPLAY_BB';
      
      ELSIF (V_IPTV_ID <> '2' AND V_FTTH_PKG = 'VOICE_INT') THEN

          L_TEMP_CODE := 'TRIPLEPLAY_BB';
      
      ELSE

          L_TEMP_CODE:= NULL;

      END IF;


    RETURN L_TEMP_CODE;

     EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;

   END GET_FTTH_PROFILE;
---- Dinesh Perera 25-04-2016 ----

END p_sop_param_slt;
/
