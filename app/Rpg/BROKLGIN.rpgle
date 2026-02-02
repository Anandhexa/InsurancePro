**FREE
/*********************************************************************/
/* Program : BROKLGIN                                                 */
/* Purpose : Broker Login Validation                                  */
/* Source  : Mainframe COBOL Migration                                 */
/*********************************************************************/

ctl-opt dftactgrp(*no)
        actgrp('INSURANCE')
        option(*srcstmt : *nodebugio);

/*-------------------------------------------------------------------*/
/* COPYBOOKS                                                         */
/*-------------------------------------------------------------------*/
 /copy QRPGLESRC,BROKER

/*-------------------------------------------------------------------*/
/* WORKING STORAGE                                                   */
/*-------------------------------------------------------------------*/
dcl-s WS_Response     int(10);
dcl-s WS_Login_Flag   char(1) inz('N');

/*-------------------------------------------------------------------*/
/* LINKAGE SECTION (DFHCOMMAREA)                                      */
/*-------------------------------------------------------------------*/
dcl-pi *n;
   DFHCOMMAREA char(100);
end-pi;

/*-------------------------------------------------------------------*/
/* MAIN LOGIC                                                        */
/*-------------------------------------------------------------------*/

/* Handle map and runtime errors */
exec cics handle
     condition(mapfail)
     label(SEND_MAP)
     condition(error)
     label(SEND_MAP);
end-exec;

/* Receive Login Screen */
exec cics receive
     map('LOGINMAP')
     mapset('LOGINSCR');
end-exec;

/* Validate credentials */
exsr VALIDATE_LOGIN;

/* Navigate based on login result */
if WS_Login_Flag = 'Y';

   exec cics xctl
        program('BROKPIPE');
   end-exec;

else;

   exsr SEND_MAP;

endif;

/* Return control to CICS */
exec cics return;
end-exec;

/*-------------------------------------------------------------------*/
/* VALIDATE LOGIN                                                    */
/*-------------------------------------------------------------------*/
VALIDATE_LOGIN:
   if USERIDI = 'RGARCIA'
      and PASSWORDI = 'BROKER01';

      WS_Login_Flag = 'Y';

   endif;
   return;

/*-------------------------------------------------------------------*/
/* SEND LOGIN MAP                                                    */
/*-------------------------------------------------------------------*/
SEND_MAP:
   exec cics send
        map('LOGINMAP')
        mapset('LOGINSCR')
        erase;
   end-exec;
   return;
