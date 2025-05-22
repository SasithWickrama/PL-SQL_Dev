CREATE OR REPLACE PACKAGE GCI_MIG.P_SLT_FUNCTIONS_V2 AS
/******************************************************************************
   NAME:       P_SLT_FUNCTIONS_V2
   PURPOSE: Clarity Product Enhancement

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        11/1/2011             1. Created this package.
******************************************************************************/

-- Jayan Liyanage  2011/11/01

PROCEDURE SIP_TRUNK_CREATE_SO (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2) ;

-- Jayan Liyanage  2011/11/01

-- Jayan Liyanage  2011/11/01

PROCEDURE SIP_TRUNK_MODIFY_SO (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);

-- Jayan Liyanage  2011/11/01

-- Jayan Liyanage  2011/11/01

PROCEDURE SIP_TRUNK_MODIFY_LO (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);

-- Jayan Liyanage  2011/11/01

-- Jayan Liyanage  2011/11/16

PROCEDURE SIP_TRUNK_DEL(
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);

-- Jayan Liyanage  2011/11/16


PROCEDURE SIP_TRUNK_CREATE_OR (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2
);

-- Jayan Liyanage  2011/12/15
PROCEDURE SIP_TRUNK_MODIFY_MSAN_SUB_CHG (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2
);

-- Jayan Liyanage  2011/12/15

-- Jayan Liyanage  2011/12/16
PROCEDURE SIP_TRUNK_BANDWITH_SET (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
-- Jayan Liyanage  2011/12/16

-- 05-01-2012 Samankula Owitipana

PROCEDURE ADSL_LINE_PROFILE_TO_SPEED (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);

-- 05-01-2012 Samankula Owitipana


--- 30-01-2012  Samankula Owitipana

PROCEDURE ADSL_MODSPEED_FUP_N (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

--- 30-01-2012  Samankula Owitipana


-- Dulip Frenando  2012/01/30

PROCEDURE PE_TITLE_TO_SO_COMMENTS (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- Dulip Frenando  2012/01/30


--- 10-02-2012  Samankula Owitipana

PROCEDURE DIDO_PROVISION_DETAIL_EMAIL (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

--- 10-02-2012  Samankula Owitipana

-- 01-03-2012 jayan Liyanage
PROCEDURE SIP_TRUNK_MODIFY_NUM_SO (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);

-- 01-03-2012 jayan Liyanage

-- Jayan Liyanage  2012/01/12

PROCEDURE SIM_CALL_FWD_WO_CHANGE(
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2) ;
      
-- Jayan Liyanage  2012/01/12 

-- 31-05-2012 Samankula Owitipana
 
PROCEDURE MS_VIDEO_SET_PRODUCT_LABLE (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 31-05-2012 Samankula Owitipana

-- 24-05-2012 Samankula Owitipana
 
PROCEDURE MS_VIDEO_SET_VCON_ID (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 24-05-2012 Samankula Owitipana

-- Jayan Liyanage 2012/05/23

PROCEDURE MS_VIDEO_MET (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- Jayan Liyanage 2012/05/23


-- 16-02-2012 jayan Liyanage 

PROCEDURE VIDEO_CONFE_EN_DATE_MAPPING (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 16-02-2012 jayan Liyanage

-- 24-05-2012 Samankula Owitipana
 
PROCEDURE MS_DSP_SET_NULL (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 24-05-2012 Samankula Owitipana

-- 24-05-2012 Samankula Owitipana
 
PROCEDURE MS_BIZAPP_WGCH_FUNCTION (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 24-05-2012 Samankula Owitipana 

-- Jayan Liyanage 2012/05/31

PROCEDURE slt_ms_resu_feature_mapping (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- Jayan Liyanage 2012/05/31

-- 08-06-2012 Samankula Owitipana
 
PROCEDURE MS_BIZAPP_SET_CCT_ID (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 08-06-2012 Samankula Owitipana

-- 04-04-2012 Samankula Owitipana
 
  PROCEDURE M3VPN_WG_CHANGE (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 04-04-2012 Samankula Owitipana 

-- 04-04-2012 Samankula Owitipana
 
  PROCEDURE M3VPN_SET_SERVICE_IDENTIFIER (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 04-04-2012 Samankula Owitipana 

-- 11-05-2012 Samankula Owitipana
 
  PROCEDURE M3VPN_NEW_TOKEN_ATTR_NULL (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 11-05-2012 Samankula Owitipana 

-- 14-05-2012 Samankula Owitipana
 
  PROCEDURE M3VPN_HAND_OVER_TOKEN (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 14-05-2012 Samankula Owitipana 

-- 16-05-2012 Samankula Owitipana
 
PROCEDURE M3VPN_TASK_CON_FUNCTION (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 16-05-2012 Samankula Owitipana

--- Jayan Liyanage 2012/03/12

PROCEDURE D_ETHERNET_VPN_CREATE (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
--- Jayan Liyanage 2012/03/12


--- Jayan Liyanage 2012/03/20

PROCEDURE D_ETHERNET_VPN_CP_BEARER_ATTR (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
 --- Jayan Liyanage 2012/03/20

--- Jayan Liyanage 2012/03/12

PROCEDURE D_ETHERNET_VPN_BEAR_AT_MAP (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
--- Jayan Liyanage 2012/03/12

--- Jayan Liyanage 2012/03/12

PROCEDURE D_ETHERNET_VPN_CREATE_TRSF (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
--- Jayan Liyanage 2012/03/12

--- Jayan Liyanage 2012/04/02
  
PROCEDURE D_ETHERNET_X_CONNE_WG_CHG (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- Jayan Liyanage 2012/04/02


-- 13-08-2012 Samankula Owitipana
 
PROCEDURE D_ETHER_UPDAT_SERIALNO_NOTIFY (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 13-08-2012 Samankula Owitipana

-- Jayan Liyanage 2012/04/05
   
PROCEDURE BEARER_DSP_DATE_UPDATE (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- Jayan Liyanage 2012/04/05

-- Jayan Liyanage 2012/04/05

PROCEDURE D_ETHE_COMPL_RULE (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- Jayan Liyanage 2012/04/05


-- 13-08-2012 Samankula Owitipana
 
PROCEDURE D_ETHER_PLAN_MIG_DATE_NOTIFY (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 13-08-2012 Samankula Owitipana


-- Jayan Liyanage 2012/08/15

PROCEDURE D_PREMIUM_VPN_BEA_ATT_CP (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

-- Jayan Liyanage 2012/08/15

-- Jayan Liyanage 2012/08/15

PROCEDURE D_PREMIUM_VPN_BEA_AT_MAP (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

-- Jayan Liyanage 2012/08/15

-- Jayan Liyanage 2012/08/14

PROCEDURE D_PREMIUM_VPN_CREATE (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

-- Jayan Liyanage 2012/08/14



-- Jayan Liyanage 2012/08/15

PROCEDURE D_PREMIUM_VPN_CREATE_TRSF (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2
);
-- Jayan Liyanage 2012/08/15

--- Dulip 2012/04/04
  
 PROCEDURE DAB_UPDATE_SO_BITRATE (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
--- Dulip 2012/04/04

-- 04-07-2012 Samankula Owitipana
 
PROCEDURE ACCESS_NW_INT_TYPE_SET (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 04-07-2012 Samankula Owitipana


-- 23-03-2012 Samankula Owitipana
 
  PROCEDURE DAB_SEQ_ATTR_SET (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
 -- 23-03-2012 Samankula Owitipana  
 
 -- 26-03-2012 Samankula Owitipana
 
  PROCEDURE DAB_BEARER_ID_ATTR_SET (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
 -- 26-03-2012 Samankula Owitipana  
 
-- Dulip Fernando  2012/02/29 
PROCEDURE VEY_PRICING_WG_CHANGE(
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2); 
      
-- Dulip Fernando  2012/02/29 

-- Dulip Fernando  2012/02/29 

PROCEDURE SET_SECTION_HANDLE_WG_FO(
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- Dulip Fernando  2012/02/29


-- Jayan Liyanage 2012/08/20

PROCEDURE D_PREMIUM_VPN_CHG (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2 );

-- Jayan Liyanage 2012/08/20

-- Jayan Liyanage 2012/08/22

PROCEDURE D_ACC_BEARER_ID_POPUP (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2 );

-- Jayan Liyanage 2012/08/22

-- 21-09-2012 Samankula Owitipana
 
PROCEDURE DAB_UPDATE_SPEED_TO_ATTRIBUTE (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 21-09-2012 Samankula Owitipana

-- 21-09-2012 Samankula Owitipana
 
PROCEDURE DAB_UPDATE_SPEED_TO_SERVICE (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 21-09-2012 Samankula Owitipana



-- 04-10-2012 Samankula Owitipana
 
PROCEDURE SIP_CONFIRM_NUMBER_WG_CH (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 04-10-2012 Samankula Owitipana


-- 24-03-2011 Gihan Amarasinghe

PROCEDURE SET_SO_STATUS_TO_APPROVED (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- 24-03-2011 Gihan Amarasinghe


-- 24-03-2011 Gihan Amarasinghe

PROCEDURE SET_TASK_STATUS_TO_COMPLETED (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- 24-03-2011 Gihan Amarasinghe

-- 19-04-2011 Gihan Amarasinghe

PROCEDURE SET_SO_FEATURE_PROV_DATETIME (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- 19-04-2011 Gihan Amarasinghe

-- 21-04-2011 Gihan Amarasinghe

PROCEDURE SET_SO_FEATURE_PROV_STATUS (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- 21-04-2011 Gihan Amarasinghe

-- 29-04-2011 Gihan Amarasinghe

PROCEDURE ASSOCIATE_CIRCUITS_ADSL (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- 29-04-2011 Gihan Amarasinghe

-- 26-03-2012 Samankula Owitipana

  PROCEDURE DIDO_MOD_UPDATE_PILOT_NUM (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- 26-03-2012 Samankula Owitipana

-- 21-06-2011 Gihan Amarasinghe

  PROCEDURE ASSOCIATE_RECON_NUMBERS (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);
        
-- 21-06-2011 Gihan Amarasinghe

-- 04-05-2011 Gihan Amarasinghe

PROCEDURE Call_RF_reservefacilityNGN (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- 04-05-2011 Gihan Amarasinghe

-- 15-03-2012 Samankula Owitipana

  PROCEDURE IPLC_INT_SET_DATACCT_ID (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- 15-03-2012 Samankula Owitipana

-- 26-03-2012 Samankula Owitipana

  PROCEDURE CDMA_MOD_LOCATION_DSP (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- 26-03-2012 Samankula Owitipana

-- 26-03-2012 Samankula Owitipana

  PROCEDURE SPLIT_CHARGE_SET_DSP (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- 26-03-2012 Samankula Owitipana

-- 12-06-2012 Samankula Owitipana

  PROCEDURE TRANSFER_AC_DSP_SET (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- 12-06-2012 Samankula Owitipana

-- 20-06-2012 Samankula Owitipana

  PROCEDURE NON_DIALUP_SET_SERVICE_IDENTIY (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- 20-06-2012 Samankula Owitipana

-- 21-06-2012 Samankula Owitipana

  PROCEDURE IPLC_LOCAL_SO_TSK_COMPLETE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- 21-06-2012 Samankula Owitipana

-- 22-06-2012 Samankula Owitipana

  PROCEDURE PSTN_FACILITY_ADSL_TSK_CLOSE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- 22-06-2012 Samankula Owitipana

-- 26-06-2012 Samankula Owitipana

  PROCEDURE SET_SERVICE_COMP_DATE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- 26-06-2012 Samankula Owitipana

-- 28-06-2012 Samankula Owitipana

  PROCEDURE IPLC_DSP_TASK_CLOSE_FORIGN (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- 28-06-2012 Samankula Owitipana

-- 04-07-2012 Samankula Owitipana

  PROCEDURE DSP_SYS_DATE_SET (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- 04-07-2012 Samankula Owitipana

-- 05-07-2012 Samankula Owitipana

  PROCEDURE CONF_TESTLINK_WGCH_FUNCTION (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- 05-07-2012 Samankula Owitipana

-- 10-07-2012 Samankula Owitipana

  PROCEDURE PSTN_SET_EXCODE_ALLOCATEDNUM (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- 10-07-2012 Samankula Owitipana

-- 13-07-2012 Samankula Owitipana

  PROCEDURE IPLC_CLOSE_ADD_FORIGN_TSK (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- 13-07-2012 Samankula Owitipana

-- 13-07-2012 Samankula Owitipana

  PROCEDURE SET_NULL_SERVICE_COMP_DATE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- 13-07-2012 Samankula Owitipana

-- 26-03-2012 Samankula Owitipana

  PROCEDURE VMS_MAILBOX_SIZE_AUTO (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- 26-03-2012 Samankula Owitipana

-- 24-07-2012 Samankula Owitipana

  PROCEDURE APPROVE_SO_WGCH_FUNCTION (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- 24-07-2012 Samankula Owitipana

-- 03-08-2012 Samankula Owitipana

  PROCEDURE MIDC_ACTIVE_TERMINATE_DATE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- 03-08-2012 Samankula Owitipana

-- 03-08-2012 Samankula Owitipana

  PROCEDURE MS_BIZA_DSP_NULL_CHK_PROVISION (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- 03-08-2012 Samankula Owitipana

-- 03-08-2012 Samankula Owitipana

  PROCEDURE DNR_ISSUE_INVOICE_WGCH (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- 03-08-2012 Samankula Owitipana

-- 03-08-2012 Samankula Owitipana

  PROCEDURE DNR_DOMAIN_EXP_SET (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- 03-08-2012 Samankula Owitipana

-- 22-08-2012 Samankula Owitipana

  PROCEDURE PSTN_MODFEATURE_PARASO_UPDATE (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- 22-08-2012 Samankula Owitipana

-- 22-08-2012 Samankula Owitipana

  PROCEDURE DIDO_DATACCT_NUM_NULL_SERVID (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- 22-08-2012 Samankula Owitipana

-- 22-08-2012 Samankula Owitipana

  PROCEDURE PSTN_MEGALINE_PKG_SET_OLD (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- 22-08-2012 Samankula Owitipana

--- 01-10-2012  Samankula Owitipana
PROCEDURE ASSOCIATE_CIRCUITS_MOD_LOC (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2 );

--- 01-10-2012  Samankula Owitipana

--2012_07_19 Jayan Liyanage

PROCEDURE ATTRIBUTE_MAPPING (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
--2012_07_19 Jayan Liyanage

-- 11-07-2012 Samankula Owitipana

PROCEDURE ADSL_TRANSFER_SET_DSP (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);

-- 11-07-2012 Samankula Owitipana   

-- 02-11-2012 Samankula Owitipana
 
PROCEDURE Call_RF_NGN_CHK_SUCCESS_Y (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 02-11-2012 Samankula Owitipana

-- 02-11-2012 Samankula Owitipana
 
PROCEDURE IPTV_FEATURES_U2Y (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 02-11-2012 Samankula Owitipana

--- 18-11-2012  Samankula Owitipana
PROCEDURE Call_RF_NGN_CHK_SUCCESS_Y_KS (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2 );

--- 18-11-2012  Samankula Owitipana

-- 11-12-2012 Samankula Owitipana
 
PROCEDURE adsl_check_x_connections (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 11-12-2012 Samankula Owitipana

-- 18-12-2012 Samankula Owitipana
 PROCEDURE adsl_check_x_con_update_cct (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 18-12-2012 Samankula Owitipana

-- Jayan Liyanage 2012/12/10

PROCEDURE D_PREMIUM_VPN_MODIFY_SPEED (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

-- Jayan Liyanage 2012/12/10

--Dulip Fernando 2012-04-23
PROCEDURE RESERVER_RELEASE_PORT(
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2) ;

--Dulip Fernando 2012-04-23

-- 24-05-2012 Samankula Owitipana
 
PROCEDURE I_MYWEB_SET_SERVICE_IDENTIY (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 24-05-2012 Samankula Owitipana 

-- 06-03-2012 jayan Liyanage 

PROCEDURE I_MYWEB_WG_CHANGE (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);

-- 06-03-2012 jayan Liyanage 

--- 21-01-2013  Janaka
PROCEDURE SLT_SET_DSLAM_SVLAN_ID(      p_serv_id                IN     Services.serv_id%TYPE,
      p_sero_id                IN     Service_Orders.sero_id%TYPE,
      p_seit_id                IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname          IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                IN     work_order.woro_id%TYPE,
      p_ret_char                  OUT    VARCHAR2,
      p_ret_number                OUT    NUMBER,
      p_ret_msg                   OUT    VARCHAR2);

--- 21-01-2013  Janaka

--- Jayan Liyanage 2013/01/30

PROCEDURE D_PREMIUM_VPN_MODIFY_CPE (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2
);
--- Jayan Liyanage 2013/01/30

--- Jayan Liyanage 2013/01/30
 PROCEDURE D_PREMIUM_VPN_MODIFY_EQUIP (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

--- Jayan Liyanage 2013/01/30

--- Jayan Liyanage 2013/02/11   

PROCEDURE D_PREMIUM_VPN_SUSPEND (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2
);

--- Jayan Liyanage 2013/02/11   

--- Jayan Liyanage 2013/01/30

PROCEDURE D_DAB_UPDAT_SERIALNO_NOTIFY(
      p_serv_id             IN     Services.serv_id%TYPE,
      p_sero_id             IN     Service_Orders.sero_id%TYPE,
      p_seit_id             IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname       IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id             IN     work_order.woro_id%TYPE,
      p_ret_char               OUT    VARCHAR2,
      p_ret_number             OUT    NUMBER,
      p_ret_msg                OUT    VARCHAR2);
      
--- Jayan Liyanage 2013/01/30      

--- Jayan Liyanage 2013/02/11   

PROCEDURE D_PREMIUM_VPN_RESUME (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
--- Jayan Liyanage 2013/02/11 

--- Jayan Liyanage 2012/03/16

PROCEDURE D_ETHERNET_VPN_MODIFY_CPE (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);

--- Jayan Liyanage 2012/03/16

--- Jayan Liyanage 2012/03/16

PROCEDURE D_ETHERNET_VPN_MODIFY_EQUIP (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
--- Jayan Liyanage 2012/03/16

--- Jayan Liyanage 2012/03/16

PROCEDURE D_ETHERNET_VPN_SUS_RES (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);

--- Jayan Liyanage 2012/03/16

PROCEDURE APPROVE_SO_WG_CHANGE (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
   
-- Dulip Fernando  2012/04/09 

-- Dulip Fernando  2012/04/11

PROCEDURE UPLOAD_LAN_PRO_WG_CHANGE(
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char           OUT VARCHAR2,
      p_ret_number         OUT NUMBER,
      p_ret_msg            OUT VARCHAR2);
   
-- Dulip Fernando  2012/04/11 

-- Jayan Liyanage 2012/05/14

  PROCEDURE BEARER_CPE_EQUI_MAP (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- Jayan Liyanage 2012/05/14

--- 08-02-2013  Samankula Owitipana
 
PROCEDURE ADSL_PSTN_CARD_PORT_CHK (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
--- 08-02-2013  Samankula Owitipana

--- Jayan Liyanage 2013/02/21

PROCEDURE D_ETHERNET_VPN_MODIFY_SPEED (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);

--- Jayan Liyanage 2013/02/21
 
--- Jayan Liyanage 2013/03/08

PROCEDURE D_PREMIUM_VPN_DELETE (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
   --- Jayan Liyanage 2013/03/08
      --- Jayan Liyanage 2013/03/08
   PROCEDURE D_PREMIUM_VPN_DELETE_OR (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
      --- Jayan Liyanage 2013/03/08
 

--- Jayan Liyanage 2013/03/07
PROCEDURE D_PRE_NOTIFY_MSG(
      p_serv_id             IN     Services.serv_id%TYPE,
      p_sero_id             IN     Service_Orders.sero_id%TYPE,
      p_seit_id             IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname       IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id             IN     work_order.woro_id%TYPE,
      p_ret_char               OUT    VARCHAR2,
      p_ret_number             OUT    NUMBER,
      p_ret_msg                OUT    VARCHAR2);
      
  
--- Jayan Liyanage 2013/03/08  
--- Jayan Liyanage 2013/03/08  

PROCEDURE D_PREMIUM_VPN_CREATE_OR (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);


--- Jayan Liyanage 2013/03/08 
--- Jayan Liyanage 2013/03/08 

PROCEDURE BER_DEL (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
--- Jayan Liyanage 2013/03/08 

--- Jayan Liyanage 2013/03/08 

PROCEDURE  SEC_HAN_PSM_OR_MGR(

      p_serv_id                      IN     Services.serv_id%TYPE,
      p_sero_id                      IN     Service_Orders.sero_id%TYPE,
      p_seit_id                      IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname                IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                      IN     work_order.woro_id%TYPE,
      p_ret_char                     OUT    VARCHAR2,
      p_ret_number                   OUT    NUMBER,
      p_ret_msg                      OUT    VARCHAR2);
      
--- Jayan Liyanage 2013/03/08 

PROCEDURE D_ETHERNET_VPN_CREATE_OR (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);

--- Jayan Liyanage 2013/03/08

-- Dulip Fernando  2012/05/15

PROCEDURE DEL_OR_WG_CHNAGE(
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char           OUT VARCHAR2,
      p_ret_number         OUT NUMBER,
      p_ret_msg            OUT VARCHAR2);
   
-- Dulip Fernando  2012/05/15

--- Jayan Liyanage 2013/03/11

PROCEDURE D_E_VPN_CREATE_TR_ID (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

--- Jayan Liyanage 2013/03/11

--- Jayan Liyanage 2013/03/12
PROCEDURE  BEARER_CP(
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

--- Jayan Liyanage 2013/03/12

--- Jayan Liyanage 2013/03/12

PROCEDURE D_PREMIUM_VPN_BEA_ATT_CP_DEL (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

--- Jayan Liyanage 2013/03/12

--- Jayan Liyanage 2013/03/12

PROCEDURE D_PREM_VPN_X_CONNE_WG_CHG_DEL (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

--- Jayan Liyanage 2013/03/12

--- Jayan Liyanage 2013/03/12

PROCEDURE D_ETH_VPN_CP_BEARER_ATT_DEL (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

--- Jayan Liyanage 2013/03/12

--- Jayan Liyanage 2013/03/12

PROCEDURE D_ETH_X_CONNE_WG_CHG_DEL (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

--- Jayan Liyanage 2013/03/12


--- Jayan Liyanage 2013/03/12

PROCEDURE D_ETHERNET_VPN_DELETE (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

--- Jayan Liyanage 2013/03/12

--- Jayan Liyanage 2013/03/12
PROCEDURE D_ETHERNET_VPN_DELETE_OR (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

--- Jayan Liyanage 2013/03/12

--- 25-03-2013 Dinesh
PROCEDURE SLT_SET_PLANNED_EVENTS_ATTR(
      p_serv_id                IN     Services.serv_id%TYPE,
      p_sero_id                IN     Service_Orders.sero_id%TYPE,
      p_seit_id                IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname          IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                IN     work_order.woro_id%TYPE,
      p_ret_char              OUT     VARCHAR2,
      p_ret_number            OUT     NUMBER,
      p_ret_msg               OUT     VARCHAR2);

--- 25-03-2013 Dinesh


---- Jayan Liyanage 2012/08/16
PROCEDURE D_PRE_VPN_TRS (
      p_serv_id             IN     Services.serv_id%TYPE,
      p_sero_id             IN     Service_Orders.sero_id%TYPE,
      p_seit_id             IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname       IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id             IN     work_order.woro_id%TYPE,
      p_ret_char               OUT    VARCHAR2,
      p_ret_number             OUT    NUMBER,
      p_ret_msg                OUT    VARCHAR2);

---- Jayan Liyanage 2012/08/16

--- Jayan Liyanage 2013/03/11   

PROCEDURE D_PREMUIM_VPN_MODIFY_LOC (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2
);
--- Jayan Liyanage 2013/03/11  

--- Jayan Liyanage 2012/03/21
 
 PROCEDURE D_ETHERNET_VPN_MODIFY_LOC (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
 --- Jayan Liyanage 2012/03/21
 
 ------ Jayan Liyanage  2013/04/08
   
PROCEDURE D_ET_MDF_LOC_APP (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);

----- Jayan Liyanage  2013/04/08


---01-04-2013 Dulip Fernando 

PROCEDURE D_BIL_TST_SVC_ALTR_WF (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);

---04-2013 Dulip Fernando

---- Dulip Fernando 2013/03/01

PROCEDURE D_BIL_CONNE_WG_CHG(
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);

---- Dulip Fernando 2013/03/01

-- Indika De Silva 2013/03/04
PROCEDURE D_BIL_VPN_CHG (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2 );

-- Indika De Silva 2013/03/04

----- Dulip Fernando 2013/02/27

PROCEDURE D_BIL_CON_CREATE(
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);

---- Dulip Fernando 2013/02/27

---- Dulip Fernando 2013/03/01

PROCEDURE D_BIL_BEA_ATT_CP(
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);

---- Dulip Fernando 2013/03/01

---- Dinesh 22-04-2013 ------  

PROCEDURE SLT_PROVISION_FEATURE_CHECK (
      P_SERV_ID                IN     SERVICES.SERV_ID%TYPE,
      P_SERO_ID                IN     SERVICE_ORDERS.SERO_ID%TYPE,
      P_SEIT_ID                IN     SERVICE_IMPLEMENTATION_TASKS.SEIT_ID%TYPE,
      P_IMPT_TASKNAME          IN     IMPLEMENTATION_TASKS.IMPT_TASKNAME%TYPE,
      P_WORO_ID                IN     WORK_ORDER.WORO_ID%TYPE,
      P_RET_CHAR               OUT    VARCHAR2,
      P_RET_NUMBER             OUT    NUMBER,
      P_RET_MSG                OUT    VARCHAR2
);
--- Dinesh 22-04-2013 ------

--- 24-04-2013 Samankula Owitipana
PROCEDURE DATA_OLD_SERVICE_PRIORITY_SET (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2) ;
      
--- 24-04-2013 Samankula Owitipana

---Dulip Fernando 2012/03/18

PROCEDURE D_BIL_CP_ATT_FROM_BEA_DEL (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
 
---Dulip Fernando  2012/03/18

---Dulip Fernando 2012/03/21

PROCEDURE D_BIL_CRE_TRNS_BEA_ATT_CP1 (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
 
---Dulip Fernando  2012/03/21

---Dulip Fernando 2012/03/21

PROCEDURE D_BIL_CRE_TRNS_BEA_ATT_CP2 (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
 
---Dulip Fernando  2012/03/21

--- 14-03-2013  Dulip Fernando
 
PROCEDURE D_BIL_CREATE_OR_WF1 (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
 
--- 14-03-2013  Dulip Fernando

---Dulip Fernando 2012/03/21

PROCEDURE D_BIL_CREATE_TRSF_WF1_1 (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
 
---Dulip Fernando  2012/03/21

---Dulip Fernando 2012/03/21

PROCEDURE D_BIL_CREATE_TRSF_WF2 (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
 
---Dulip Fernando  2012/03/21

---Dulip Fernando 2012/03/19
 
PROCEDURE D_BIL_DELETE_WF1 (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
 
---Dulip Fernando  2012/03/19

---Dulip Fernando 2012/03/19

PROCEDURE D_BIL_DELETE_OR_WF1 (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
 
---Dulip Fernando  2012/03/19

--- 15-03-2013  Dulip Fernando

PROCEDURE D_BIL_MODIFY_CPE_WF1 (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
 
--- 15-03-2013  Dulip Fernando

-- Indika De Silva 10/04/2013
PROCEDURE D_BIL_M_CPE_EQUI_TO_BEA_ATT_CP (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

-- Indika De Silva 10/04/2013

---Dulip Fernando 2012/03/19
 
PROCEDURE SEC_HAN_PSM_SIU_MGR (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
 
---Dulip Fernando  2012/03/19

---31-03-2013 Indika de silva

PROCEDURE D_DAB_SEC_HAN_PSM_OR_MGR (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);

---31-03-2013 Indika de silva


END P_SLT_FUNCTIONS_V2;
/
