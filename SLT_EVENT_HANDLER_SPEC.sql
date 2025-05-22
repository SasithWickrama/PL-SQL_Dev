CREATE OR REPLACE package 
/*-------------------------------------------------------------------------------
--  Package:
--  Author: chaerry @ Synchronoss Techonology Inc
--  Date: May 1, 2015
--  Versioning:
--        1.0     March 8, 2015    ch        - initial development
--        2.0  June 3, 2015   ch      - modify procedure FaultType_Handler to support
--                                    Network Fault
---------------------------------------------------------------------------------*/
                                CLARITY.SLT_Event_Handler
is
    procedure FaultType_Handler(
        p_faultNumber       in number,
        p_linkEntityID      in varchar,
        p_linkEntityType    in varchar
    );

---- Sasith 27-07-2015  ----   
procedure FAULT_LEA_UPDATE(
        p_faultNumber       in number);


---- Sasith  28-07-2015  ----   
procedure FAULT_ESCALATION_INDEX(
        p_faultNumber       in number);
                    
end;
/
