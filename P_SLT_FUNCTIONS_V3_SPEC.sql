CREATE OR REPLACE PACKAGE GCI_MIG.P_SLT_FUNCTIONS_V3 AS


--- Jayan Liyanage 2013/04/22

PROCEDURE SLT_IDD_ACC (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2) ;

--- Jayan Liyanage 2013/04/22


--- Duilp Fernando 2013-03-08
 
PROCEDURE D_BIL_MODIFY_SPEED (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
--- Duilp Fernando 2013-03-08

--- Indika de silva 14/04/2013   

PROCEDURE D_BIL_MOD_LOC_WF1 (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

--- Indika de silva 14/04/2013

--- Indika de silva 14/04/2013   

PROCEDURE D_BIL_MOD_LOC_WF2 (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

--- Indika de silva 14/04/2013

-- Indika de silva 04/04/2013

  PROCEDURE MODIFY_CPE_EQUI_DSP_MAP (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- Indika de silva 04/04/2013

---Dulip Fernando 2012/03/12
 
PROCEDURE D_BIL_MODIFY_EQUIP_WF1 (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
 
---Dulip Fernando  2012/03/12

--- Jayan Liyanage 2013/04/02

PROCEDURE D_SIP_CREA_UPGRADE (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
--- Jayan Liyanage 2013/04/02


--- Jayan Liyanage 2013/04/02
 
PROCEDURE D_SIP_CREA_UPGRDE_X_CONNE (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

--- Jayan Liyanage 2013/04/02

--- 23-03-2013  Samankula Owitipana
 
PROCEDURE SMART_DIAL_ACC_GP_ID (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
--- 23-03-2013  Samankula Owitipana

-- Samankula Owitipana 2013/05/16

PROCEDURE SISU_CON_TASK_CON_FUNCTION (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2) ;
      
-- Samankula Owitipana 2013/05/16

--- 25-06-2013  Samankula Owitipana  
 
PROCEDURE SISUCON_FEATURE_ATTRIB_BLANK (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
--- 25-06-2013  Samankula Owitipana

--- 19-06-2013  Samankula Owitipana  
 
PROCEDURE IPTV_TITANIUM_PKG_OPMC_EMAIL (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);
   
--- 19-06-2013  Samankula Owitipana

--Indika de Silva 30/06/2013

PROCEDURE D_BIL_M_LOC_PRE_X_CONNE_1 (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

--Indika de Silva 30/06/2013

--Indika de Silva 30/06/2013

PROCEDURE D_BIL_M_LOC_PRE_X_CONNE_2 (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

--Indika de Silva 30/06/2013

--- Jayan Liyanage 2013/07/05

PROCEDURE SLT_SISI_ACC (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);
      
--- Jayan Liyanage 2013/07/05



--- 25-06-2013  Samankula Owitipana  
 
PROCEDURE CDMA_CHK_SISU_CON_FEATURECON (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
--- 25-06-2013  Samankula Owitipana

--- 16-07-2013  Samankula Owitipana  
 
PROCEDURE D_BDL_MDF_X_CONNE (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
--- 16-07-2013  Samankula Owitipana

--- 05-03-2013  Samankula Owitipana
 
PROCEDURE ADSL_COPY_PSTN_CIRCUIT (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
--- 05-03-2013  Samankula Owitipana

--- 19-03-2013  Samankula Owitipana
 
PROCEDURE ADSL_CHK_PSTN_SO_SOP_CLOSE (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
--- 19-03-2013  Samankula Owitipana

------JANAKA 2013-06-20 ---- HLR-----------------

PROCEDURE PROCESS_UPDATE_HLR_ATTR (      p_serv_id                IN     

Services.serv_id%TYPE,
      p_sero_id                IN     Service_Orders.sero_id%TYPE,
      p_seit_id                IN     

Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname          IN     

Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                IN     work_order.woro_id%TYPE,
      p_ret_char                  OUT    VARCHAR2,
      p_ret_number                OUT    NUMBER,
      p_ret_msg                   OUT    VARCHAR2);
------JANAKA 2013-06-20 ---- HLR-----------------

------JANAKA 2013-07-05 ---- HUAWEI-IN-----------------

PROCEDURE UPDATE_SA_PRE_PAID (      p_serv_id                IN     Services.serv_id%TYPE,
      p_sero_id                IN     Service_Orders.sero_id%TYPE,
      p_seit_id                IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname          IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                IN     work_order.woro_id%TYPE,
      p_ret_char                  OUT    VARCHAR2,
      p_ret_number                OUT    NUMBER,
      p_ret_msg                   OUT    VARCHAR2);
      
------JANAKA 2013-07-05 ---- HUAWEI-IN-----------------

--- 22-08-2013  Samankula Owitipana  
 
PROCEDURE ADSL_COPY_PSTN_REMOVE (
    p_serv_id        IN     Services.serv_id%type,
    p_sero_id        IN     Service_Orders.sero_id%type,
    p_seit_id        IN     Service_Implementation_Tasks.seit_id%type,
    p_impt_taskname  IN     Implementation_Tasks.impt_taskname%type,
    p_srbt_id        IN     service_rollback_tasks.srbt_id%TYPE,
    p_ret_char       OUT    varchar2,
    p_ret_number     OUT    number,
    p_ret_msg        OUT    Varchar2);
   
--- 22-08-2013  Samankula Owitipana

--- 15-08-2013  Samankula Owitipana  
 
PROCEDURE ADSL_COPY_PSTN_REPLACE (
    p_serv_id        IN     Services.serv_id%type,
    p_sero_id        IN     Service_Orders.sero_id%type,
    p_seit_id        IN     Service_Implementation_Tasks.seit_id%type,
    p_impt_taskname  IN     Implementation_Tasks.impt_taskname%type,
    p_srbt_id        IN     service_rollback_tasks.srbt_id%TYPE,
    p_ret_char       OUT    varchar2,
    p_ret_number     OUT    number,
    p_ret_msg        OUT    Varchar2);
   
--- 15-08-2013  Samankula Owitipana 

--- 21-02-2013  Samankula Owitipana
 
PROCEDURE ADSL_DELETE_CCT_REARRANGEMENT (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
--- 21-02-2013  Samankula Owitipana

-- 18-01-2013 Samankula Owitipana
 PROCEDURE ADSL_BEARER_CREATION_AUTO (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 18-01-2013 Samankula Owitipana

-- Jayan Liyanage 2012/08/16

PROCEDURE D_PREMIUM_VPN_X_CONNE_WG_CHG (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- Jayan Liyanage 2012/08/16

------JANAKA 2013-07-17 ----SOFSWITCH-----------------

PROCEDURE UPDATE_SOP_PROV_FET_STS(      p_serv_id                IN     Services.serv_id%TYPE,
      p_sero_id                IN     Service_Orders.sero_id%TYPE,
      p_seit_id                IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname          IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                IN     work_order.woro_id%TYPE,
      p_ret_char                  OUT    VARCHAR2,
      p_ret_number                OUT    NUMBER,
      p_ret_msg                   OUT    VARCHAR2);
      
------JANAKA 2013-07-17 ---- SOFSWITCH-----------------

------JANAKA 2013-06-04 ---- SOFTSWITCH-----------------

PROCEDURE UPDATE_NUMBER_TYPE(      p_serv_id                IN     Services.serv_id%TYPE,
      p_sero_id                IN     Service_Orders.sero_id%TYPE,
      p_seit_id                IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname          IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                IN     work_order.woro_id%TYPE,
      p_ret_char                  OUT    VARCHAR2,
      p_ret_number                OUT    NUMBER,
      p_ret_msg                   OUT    VARCHAR2);
      
      
PROCEDURE UPDATE_ZTE_MSAN_NODEID (      p_serv_id                IN     Services.serv_id%TYPE,
      p_sero_id                IN     Service_Orders.sero_id%TYPE,
      p_seit_id                IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname          IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                IN     work_order.woro_id%TYPE,
      p_ret_char                  OUT    VARCHAR2,
      p_ret_number                OUT    NUMBER,
      p_ret_msg                   OUT    VARCHAR2);

---@@@@ Task Condition@@@-----
PROCEDURE SLT_NEMS_SOFTSWITCH_CHECK (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
---@@@@ Task Condition@@@-----      
------JANAKA 2013-06-04 ---- SOFTSWITCH-----------------

---- Janaka 2013 07 29 ****ZTE_ADSL****
PROCEDURE UPDATE_VLANCOM_ATTR(      p_serv_id                IN     Services.serv_id%TYPE,
      p_sero_id                IN     Service_Orders.sero_id%TYPE,
      p_seit_id                IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname          IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                IN     work_order.woro_id%TYPE,
      p_ret_char                  OUT    VARCHAR2,
      p_ret_number                OUT    NUMBER,
      p_ret_msg                   OUT    VARCHAR2);

PROCEDURE UPDATE_ZTE_ADSL_ATTR(      p_serv_id                IN     Services.serv_id%TYPE,
      p_sero_id                IN     Service_Orders.sero_id%TYPE,
      p_seit_id                IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname          IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                IN     work_order.woro_id%TYPE,
      p_ret_char                  OUT    VARCHAR2,
      p_ret_number                OUT    NUMBER,
      p_ret_msg                   OUT    VARCHAR2);
---- Janaka 2013 07 29 ****ZTE_ADSL****

--- Jayan Liyanage 2013/04/03

PROCEDURE D_EDL_CONNE(
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2
);

--- Jayan Liyanage 2013/04/03

--- Jayan Liyanage 2013/04/02 

PROCEDURE D_ETHERNET_DL_CP_ATTR_AB (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

--- Jayan Liyanage 2013/04/02

--- Jayan Liyanage 2013/04/03


PROCEDURE D_EDL_NETWORK_NTU_EL_NOTIFY(
      p_serv_id             IN     Services.serv_id%TYPE,
      p_sero_id             IN     Service_Orders.sero_id%TYPE,
      p_seit_id             IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname       IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id             IN     work_order.woro_id%TYPE,
      p_ret_char               OUT    VARCHAR2,
      p_ret_number             OUT    NUMBER,
      p_ret_msg                OUT    VARCHAR2) ;

--- Jayan Liyanage 2013/04/03

--- Jayan Liyanage 2013/04/03

PROCEDURE D_EDL_CREATE_BEA_AT_MAP (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

--- Jayan Liyanage 2013/04/03

--- Jayan Liyanage 2013/05/27
PROCEDURE D_EDL_ACT_TX(
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

--- Jayan Liyanage 2013/05/27

--- Jayan Liyanage 2013/04/02 

PROCEDURE D_BL_CREATE (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

--- Jayan Liyanage 2013/04/02

PROCEDURE BEARER_DSP_DATE_UPDATE_4_EDL (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);

--- Jayan Liyanage 2013/04/03
PROCEDURE  BEARER_CP_EDL(
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

--- Jayan Liyanage 2013/04/03

PROCEDURE ACCESS_BEARER_ID_BLANK(
      p_serv_id                IN     Services.serv_id%TYPE,
      p_sero_id                IN     Service_Orders.sero_id%TYPE,
      p_seit_id                IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname          IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                IN     work_order.woro_id%TYPE,
      p_ret_char               OUT    VARCHAR2,
      p_ret_number             OUT    NUMBER,
      p_ret_msg                OUT    VARCHAR2);
-- Dulip Fernando 2013 07 31

--Indika de silva 18-08-2013
PROCEDURE SIP_TRUNK_CONFIR_NO_LEVEL (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2) ;
   
--Indika de silva 18-08-2013

--- 10-10-2013  Dulip Fernando 
PROCEDURE PROV_CDMA_TASK_LOAD(
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
--- 10-10-2013  Dulip Fernando 

--  Jayan Liyanage 2013/07/19

PROCEDURE DATA_PROD_ACC_ID_SET (
   p_serv_id         IN     Services.serv_id%TYPE,
   p_sero_id         IN     Service_Orders.sero_id%TYPE,
   p_seit_id         IN     Service_Implementation_Tasks.seit_id%TYPE,
   p_impt_taskname   IN     Implementation_Tasks.impt_taskname%TYPE,
   p_woro_id         IN     work_order.woro_id%TYPE,
   p_ret_char           OUT VARCHAR2,
   p_ret_number         OUT NUMBER,
   p_ret_msg            OUT VARCHAR2);
   
--  Jayan Liyanage 2013/07/19

--Indika de Silva 15-10-2013
PROCEDURE  CP_SER_ID(
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

--Indika de Silva 15-10-2013

--Indika de Silva 15-10-2013

PROCEDURE ENTER_NEW_SO_NO_MSG_MAP(
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2 );

--Indika de Silva 15-10-2013

-- 16-10-2013 Gihan Amarasinghe and Janaka Rathnayaka
PROCEDURE copy_CIRCUIT_details_slt2 (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2) ;
-- 16-10-2013 Gihan Amarasinghe and Janaka Rathnayaka

--- 21-10-2013  Janaka Ratnayake 

PROCEDURE UPDATE_ADSL_CIRCUIT_LOC (      p_serv_id                IN     Services.serv_id%TYPE,
      p_sero_id                IN     Service_Orders.sero_id%TYPE,
      p_seit_id                IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname          IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                IN     work_order.woro_id%TYPE,
      p_ret_char                  OUT    VARCHAR2,
      p_ret_number                OUT    NUMBER,
      p_ret_msg                   OUT    VARCHAR2);

--- 21-10-2013  Janaka Ratnayake

-- 16-11-2013 Samankula Owitipana
PROCEDURE SISU_CONNECT_SET_NEW_TP(
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 16-11-2013 Samankula Owitipana

--- 02-10-2013  Samankula Owitipana  
PROCEDURE ADSL_WAIT_SOP_TSK_CLOSE (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
--- 02-10-2013  Samankula Owitipan

--- 29-09-2013  Samankula Owitipana  
PROCEDURE PSTN_WAIT_SOP_ADSL_TSK_CLOSE (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
--- 29-09-2013  Samankula Owitipan

-- Jayan Liyanage 2013/11/12
PROCEDURE IPTV_PROV_MIS_COM(
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);
-- Jayan Liyanage 2013/11/12

-- Jayan Liyanage 2013/12/11
PROCEDURE DATA_PRO_STATUS_CHG (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
 -- Jayan Liyanage 2013/12/11
 
 -- 06-11-2013 Samankula Owitipana
 
PROCEDURE D_ENTERPRIZE_IPTV_BEA_ATT_CP (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 06-11-2013 Samankula Owitipana

-- 06-11-2013 Samankula Owitipana
 
PROCEDURE D_ENTERPRISE_IPTV_CREATE (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 06-11-2013 Samankula Owitipana

-- 28-11-2013 Samankula Owitipana
 
PROCEDURE d_enterprize_IPTV_dsp_map (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 28-11-2013 Samankula Owitipana

-- 15-11-2013 Samankula Owitipana
 
PROCEDURE D_ENTERPRIZE_IPTV_DELETE (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 15-11-2013 Samankula Owitipana

---Dulip Fernando 2013-11-06
 
PROCEDURE NBN_CH_WO_ACTIVITY_WG(
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
---Dulip Fernando 2013-11-06

-- Indika De Silva 2013-Dec-03

PROCEDURE D_BIL_CREATE_BKP_WF (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- Indika De Silva 2013-Dec-03

-- Indika De Silva 2013/03/04
PROCEDURE D_BIL_VPN_BEA_AT_MAP (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);
-- Indika De Silva 2013/03/04

-- Jayan Liyanage 2014/01/01

PROCEDURE BEARER_DSP_DATE_MOD_SPEED (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
   -- Jayan Liyanage 2014/01/01

-- 15-11-2013 Samankula Owitipana
 
PROCEDURE SISU_CDMA_SET_BILL_NUMBBER (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 15-11-2013 Samankula Owitipana
   
--- 19-12-2013 Samankula Owitipana
 
PROCEDURE LTE_FORMAT_MSISDN_NUMBER (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
--- 19-12-2013 Samankula Owitipana
 
--- 19-12-2013 Samankula Owitipana
 
PROCEDURE LTE_UPDATE_AB_WIRELESS_ACCESS (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
--- 19-12-2013 Samankula Owitipana
 
--- 13-01-2014 Samankula Owitipana

PROCEDURE LTE_CLOSE_WAIT_BB_PROV (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);

--- 13-01-2014 Samankula Owitipana

--- Dinesh Perera 16-01-2014

PROCEDURE CHANGE_ATTRIB_TO_94 (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);

--- Dinesh Perera 16-01-2014

--- Dinesh Perera 16-01-2014

PROCEDURE CHANGE_ATTRIB_94_TO_NORM (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);

--- Dinesh Perera 16-01-2014

-- 13-01-2014 Samankula Owitipana
 
PROCEDURE LTE_HASH_ID_GENERATION (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 13-01-2014 Samankula Owitipana

-- 21-01-2014 Samankula Owitipana

PROCEDURE LTE_UPDATE_PW_INVENTORY (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);

-- 21-01-2014 Samankula Owitipana

--- Dinesh Perera 03-02-2014 

PROCEDURE PE_DRAW_FIBER_WG_CHG (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);

--- Dinesh Perera 03-02-2014 

--- Dinesh Perera 03-02-2014 

PROCEDURE PE_UPLOAD_OSS_WG_CHG (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);

--- Dinesh Perera 03-02-2014 

--- Dinesh Perera 2013-11-12
PROCEDURE PLANNED_EVENTS_AUTO_APPROVED
(     p_serv_id                IN     Services.serv_id%TYPE,
      p_sero_id                IN     Service_Orders.sero_id%TYPE,
      p_seit_id                IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname          IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                IN     work_order.woro_id%TYPE,
      p_ret_char              OUT     VARCHAR2,
      p_ret_number            OUT     NUMBER,
      p_ret_msg               OUT     VARCHAR2);
--- Dinesh Perera 2013-11-12

--- Dinesh Perera 2014-02-06
PROCEDURE PLANNED_EVENTS_AUTO_COMPLETE
(     p_serv_id                IN     Services.serv_id%TYPE,
      p_sero_id                IN     Service_Orders.sero_id%TYPE,
      p_seit_id                IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname          IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                IN     work_order.woro_id%TYPE,
      p_ret_char              OUT     VARCHAR2,
      p_ret_number            OUT     NUMBER,
      p_ret_msg               OUT     VARCHAR2);
--- Dinesh Perera 2014-02-06

-- 06-02-2014 Samankula Owitipana

PROCEDURE PSTN_IDD_PROVISION_Y
(     p_serv_id                IN     Services.serv_id%TYPE,
      p_sero_id                IN     Service_Orders.sero_id%TYPE,
      p_seit_id                IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname          IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                IN     work_order.woro_id%TYPE,
      p_ret_char              OUT     VARCHAR2,
      p_ret_number            OUT     NUMBER,
      p_ret_msg               OUT     VARCHAR2);
      
      
-- 06-02-2014 Samankula Owitipana

--- 06-03-2014  Ruwan Ranasinghe 
PROCEDURE UPDATE_ADSL_LINE_PROFILE_ATTR (
      p_serv_id                IN     Services.serv_id%TYPE,
      p_sero_id                IN     Service_Orders.sero_id%TYPE,
      p_seit_id                IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname          IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                IN     work_order.woro_id%TYPE,
      p_ret_char                  OUT    VARCHAR2,
      p_ret_number                OUT    NUMBER,
      p_ret_msg                   OUT    VARCHAR2);
--- 06-03-2014  Ruwan Ranasinghe 

--- 28-02-2013  Samankula Owitipana
 
PROCEDURE ADSL_SET_NAS_PORTID_ATTRIBUTE (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
--- 28-02-2013  Samankula Owitipana

-- 28-03-2011 Samankula Owitipana

  PROCEDURE FAULT_WF_SET_CCT_DATA (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- 28-03-2011 Samankula Owitipana

-- 10-05-2011 Samankula Owitipana

  PROCEDURE FAULT_WF_SET_ATTRIBUTES (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- 10-05-2011 Samankula Owitipana 

-- 28-03-2011 Samankula Owitipana

  PROCEDURE FAULT_WF_DELETE_ADSL (
      p_serv_id            IN     Services.serv_id%TYPE,
      p_sero_id            IN     Service_Orders.sero_id%TYPE,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              OUT VARCHAR2,
      p_ret_number            OUT NUMBER,
      p_ret_msg               OUT VARCHAR2);

-- 28-03-2011 Samankula Owitipana

--- 12-03-2013  Samankula Owitipana
 
PROCEDURE FAULT_WF_CREATE_ADSL_XCON_AUTO (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
--- 12-03-2013  Samankula Owitipana

--- 27-03-2014 Dinesh Perera
 
PROCEDURE FTTH_CCT_ID_UPDATE (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
--- 27-03-2014 Dinesh Perera

-- 24-03-2014 Samankula Owitipana

PROCEDURE FTTH_COPY_PSTN_NO_TO_ALL
(     p_serv_id                IN     Services.serv_id%TYPE,
      p_sero_id                IN     Service_Orders.sero_id%TYPE,
      p_seit_id                IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname          IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                IN     work_order.woro_id%TYPE,
      p_ret_char              OUT     VARCHAR2,
      p_ret_number            OUT     NUMBER,
      p_ret_msg               OUT     VARCHAR2);
         
-- 24-03-2014 Samankula Owitipana

-- 28-02-2014 Samankula Owitipana

PROCEDURE BEARER_SEQ_ATTR_SET
(     p_serv_id                IN     Services.serv_id%TYPE,
      p_sero_id                IN     Service_Orders.sero_id%TYPE,
      p_seit_id                IN     Service_Implementation_Tasks.seit_id%TYPE,
      p_impt_taskname          IN     Implementation_Tasks.impt_taskname%TYPE,
      p_woro_id                IN     work_order.woro_id%TYPE,
      p_ret_char              OUT     VARCHAR2,
      p_ret_number            OUT     NUMBER,
      p_ret_msg               OUT     VARCHAR2);
           
-- 28-02-2014 Samankula Owitipana

--- 27-03-2014 Dinesh Perera
 
PROCEDURE FTTH_PW_GENERATION (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
--- 27-03-2014 Dinesh Perera

-- 28-03-2014 Samankula Owitipana
 
PROCEDURE FTTH_CLOSE_WAIT_VOICE_NUMBER (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 28-03-2014 Samankula Owitipana

-- 28-03-2014 Samankula Owitipana
 
PROCEDURE FTTH_ACCESS_PIPE_ID_ATTR_SET (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 28-03-2014 Samankula Owitipana

-- 03-04-2014 Samankula Owitipana
 
PROCEDURE FTTH_INTERNET_CREATION_AUTO (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 03-04-2014 Samankula Owitipana

-- 03-04-2014 Samankula Owitipana
 
PROCEDURE FTTH_IPTV_CREATION_AUTO (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 03-04-2014 Samankula Owitipana

-- 03-04-2014 Samankula Owitipana
 
PROCEDURE FTTH_VOICE_CREATION_AUTO (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 03-04-2014 Samankula Owitipana

--- 26-03-2014 Janaka -----

PROCEDURE SLT_CHK_FET_INTERNET (
      p_serv_id            IN     Services.serv_id%type,
      p_sero_id            IN     Service_Orders.sero_id%type,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%type,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%type,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              out varchar2,
      p_ret_number            OUT number,
      p_ret_msg               OUT Varchar2);
--- 26-03-2014 Janaka ------

-- 07-04-2014 Samankula Owitipana
 
PROCEDURE PSTN_DEL_SAME_NUM_HIERARCHY (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 07-04-2014 Samankula Owitipana

-- Jayan Liyanage 2014/01/07
  
  PROCEDURE D_EDL_MODFY_SPE_ATT_CP (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

 -- Jayan Liyanage 2014/01/07
 

-- Jayan Liyanage 2014/01/07
PROCEDURE D_EDL_MODIFY_SPEED (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

-- Jayan Liyanage 2014/01/07

-- Jayan Liyanage 2014/01/07
 
 PROCEDURE BEARER_DSP_UPD_4_EDL_MSP (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
 -- Jayan Liyanage 2014/01/07
 
--Indika De Silva 04/05/2014
 PROCEDURE MSG_PLANNED_MIGRATION_DATE(
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);

--Indika De Silva 04/05/2014

--- Jayan Liyanage 2014/01/24
   
 PROCEDURE D_EDL_DELETE_CP_ATT (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

--- Jayan Liyanage 2014/01/24

--- Jayan Liyanage 2014/01/24
   
    PROCEDURE D_EDL_DELETE (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
--- Jayan Liyanage 2014/01/24
   
--- Jayan Liyanage 2014/01/24

PROCEDURE D_EDL_MODIFY_OTHERS_CP_ATT (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2
);
--- Jayan Liyanage 2014/01/24


--- Jayan Liyanage 2014/01/24

PROCEDURE D_EDL_MODIFY_OTHERS (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

--- Jayan Liyanage 2014/01/24

--Samankula Owitipana  26-03-2014
PROCEDURE VALUE_VPN_CHK_CCT_XCONN (
      p_serv_id            IN     Services.serv_id%type,
      p_sero_id            IN     Service_Orders.sero_id%type,
      p_seit_id            IN     Service_Implementation_Tasks.seit_id%type,
      p_impt_taskname      IN     Implementation_Tasks.impt_taskname%type,
      p_woro_id            IN     work_order.woro_id%TYPE,
      p_ret_char              out varchar2,
      p_ret_number            OUT number,
      p_ret_msg               OUT Varchar2);
      
--Samankula Owitipana 26-03-2014

--- 12-05-2014 Dinesh Perera

PROCEDURE IPTV_NEW_ATT_UPDATE(

   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
--- 12-05-2014 Dinesh Perera

-- 08-05-2014 Samankula Owitipana
 
PROCEDURE SET_SO_COMPLETION_DATE_BLANK (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 08-05-2014 Samankula Owitipana

--Indika de Silva 09/05/2014
PROCEDURE PRE_IPVPN_CREATE_FOX_CP_ATT (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

--Indika de Silva 09/05/2014

-- Indika de Silva 14-05-2014
PROCEDURE REMV_SUFFIX_N_FROM_ACC_BEAR_ID (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);

-- Indika de Silva 14-05-2014

-- 09-05-2014 Samankula Owitipana
 
PROCEDURE D_FOX_WAIT_4DAB (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 09-05-2014 Samankula Owitipana


-- 10-04-2014 Sudheera Jayathilaka
 
PROCEDURE ATTCH_ALL_PRO_TO_NEW_CIRCUIT (
   p_serv_id         IN       services.serv_id%TYPE,
   p_sero_id         IN       service_orders.sero_id%TYPE,
   p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
   p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
   p_woro_id         IN       work_order.woro_id%TYPE,
   p_ret_char        OUT      VARCHAR2,
   p_ret_number      OUT      NUMBER,
   p_ret_msg         OUT      VARCHAR2);
   
-- 10-04-2014 Sudheera Jayathilaka

--- Jayan Liyanage 2014/ 07 / 02
 
 PROCEDURE D_IPVPN_WG_CHANGE_MDIFY_SPD (
p_serv_id         IN       services.serv_id%TYPE,
p_sero_id         IN       service_orders.sero_id%TYPE,
p_seit_id         IN       service_implementation_tasks.seit_id%TYPE,
p_impt_taskname   IN       implementation_tasks.impt_taskname%TYPE,
p_woro_id         IN       work_order.woro_id%TYPE,
p_ret_char        OUT      VARCHAR2,
p_ret_number      OUT      NUMBER,
p_ret_msg         OUT      VARCHAR2);

-- Jayan Liyanage 2014/ 07 / 02


END P_SLT_FUNCTIONS_V3;
/
