**FREE
/*********************************************************************/
/* Program : BROKPIPE                                                */
/* Purpose : Broker Pipeline – Placement Listing                     */
/* Source  : Mainframe COBOL Migration                                */
/*********************************************************************/

ctl-opt dftactgrp(*no)
        actgrp('INSURANCE')
        option(*srcstmt : *nodebugio);

/*-------------------------------------------------------------------*/
/* FILES                                                             */
/*-------------------------------------------------------------------*/
dcl-f AXAPLCMT usage(*input) keyed;

/*-------------------------------------------------------------------*/
/* COPYBOOKS                                                         */
/*-------------------------------------------------------------------*/
 /copy QRPGLESRC,PLACEMENT

/*-------------------------------------------------------------------*/
/* WORKING STORAGE                                                   */
/*-------------------------------------------------------------------*/
dcl-s WS_Response        int(10);
dcl-s WS_PlacementCount packed(3:0) inz(0);

/*-------------------------------------------------------------------*/
/* LINKAGE SECTION (DFHCOMMAREA)                                      */
/*-------------------------------------------------------------------*/
dcl-pi *n;
   DFHCOMMAREA char(100);
end-pi;

/*-------------------------------------------------------------------*/
/* MAIN LOGIC                                                        */
/*-------------------------------------------------------------------*/

/* Handle file and runtime errors */
exec cics handle
     condition(notfnd)
     label(SEND_EMPTY)
     condition(error)
     label(SEND_EMPTY);
end-exec;

/* PF key handling */
exec cics handle aid
     pf2(NEW_PLACEMENT)
     pf3(EXIT_PROGRAM)
     pf12(MAIN_PARA);
end-exec;

/* Read placements */
exsr READ_PLACEMENTS;

/* Decide what to display */
if WS_PlacementCount = 0;
   exsr SEND_EMPTY;
else;
   exsr SEND_DATA;
endif;

/* Return to CICS */
exec cics return;
end-exec;

/*-------------------------------------------------------------------*/
/* NEW PLACEMENT                                                     */
/*-------------------------------------------------------------------*/
NEW_PLACEMENT:
   exec cics xctl
        program('NEWPLCMT');
   end-exec;
   return;

/*-------------------------------------------------------------------*/
/* EXIT PROGRAM                                                      */
/*-------------------------------------------------------------------*/
EXIT_PROGRAM:
   exec cics return;
   end-exec;
   return;

/*-------------------------------------------------------------------*/
/* READ PLACEMENTS                                                   */
/*-------------------------------------------------------------------*/
READ_PLACEMENTS:

   /* Hardcoded broker as per COBOL logic */
   PLACEMENT_BROKER = 'RGARCIA';

   chain PLACEMENT_BROKER AXAPLCMT;
   if %found(AXAPLCMT);
      WS_PlacementCount += 1;
   endif;

   return;

/*-------------------------------------------------------------------*/
/* SEND EMPTY PIPELINE SCREEN                                        */
/*-------------------------------------------------------------------*/
SEND_EMPTY:
   exec cics send
        map('PIPEMAP')
        mapset('PIPESCR')
        erase;
   end-exec;
   return;

/*-------------------------------------------------------------------*/
/* SEND PIPELINE DATA                                                */
/*-------------------------------------------------------------------*/
SEND_DATA:
   exec cics send
        map('PIPEMAP')
        mapset('PIPESCR')
        erase;
   end-exec;
   return;
