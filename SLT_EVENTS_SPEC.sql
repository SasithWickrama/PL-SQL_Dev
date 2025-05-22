CREATE OR REPLACE PACKAGE CLARITY_ADMIN.SLT_EVENTS IS
/******************************************************************************
   NAME:       SLT_EVENTS
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        30/07/2014      011192       1. Created this package.
******************************************************************************/

---- Sasith 30-07-2015  ----   
procedure FAULT_CREATE_SMS(
        p_faultNumber       IN NUMBER);

---- Sasith 12-08-2015  ----   
procedure FAULT_STATUS_CHANGE_SMS(
        p_faultNumber       IN NUMBER,
        p_statusCode        IN VARCHAR,
        p_prouId            IN VARCHAR);
              
END SLT_EVENTS;
/
