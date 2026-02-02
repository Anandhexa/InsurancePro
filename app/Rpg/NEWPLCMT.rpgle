**FREE
ctl-opt dftactgrp(*no)
        actgrp(*caller)
        option(*srcstmt:*nodebugio);

/*----------------------------------------------------------------*/
/* Files                                                          */
/*----------------------------------------------------------------*/
dcl-f AXAPLCMT usage(*output) keyed;

/*----------------------------------------------------------------*/
/* Copy books (PLACEMENT / CLIENT)                                */
/*----------------------------------------------------------------*/
 /copy PLACEMENT
 /copy CLIENT

/*----------------------------------------------------------------*/
/* Entry parameter (DFHCOMMAREA equivalent)                        */
/*----------------------------------------------------------------*/
dcl-pi *n;
   pCommArea char(100);
end-pi;

/*----------------------------------------------------------------*/
/* Working storage                                                */
/*----------------------------------------------------------------*/
dcl-s wsCurrentDate date;
dcl-s wsExpiryDate  date;

/*----------------------------------------------------------------*/
/* Main logic                                                      */
/*----------------------------------------------------------------*/
sendMap();
return;

/*----------------------------------------------------------------*/
/* ENTER – Save placement                                         */
/*----------------------------------------------------------------*/
dcl-proc savePlacement;

   /* EXFMT NEWPLMAP populates input-capable fields */

   buildPlacementRecord();
   write AXAPLCMT;

   callp BROKPIPE();

end-proc;

/*----------------------------------------------------------------*/
/* Build placement record                                         */
/*----------------------------------------------------------------*/
dcl-proc buildPlacementRecord;

   wsCurrentDate = %date();

   Placement_Name   = PLCMTNMI;
   Placement_Broker = 'RGARCIA';
   Placement_Status = 'NEW';

end-proc;

/*----------------------------------------------------------------*/
/* Send screen                                                    */
/*----------------------------------------------------------------*/
dcl-proc sendMap;

   setDefaults();

   /* EXFMT NEWPLMAP */

end-proc;

/*----------------------------------------------------------------*/
/* Set default dates                                              */
/*----------------------------------------------------------------*/
dcl-proc setDefaults;

   wsCurrentDate = %date();
   wsExpiryDate  = wsCurrentDate + %days(364);

   IncepDt = %char(wsCurrentDate:*ISO0);
   ExpirDt = %char(wsExpiryDate:*ISO0);

end-proc;

/*----------------------------------------------------------------*/
/* PF4 – Add product                                              */
/*----------------------------------------------------------------*/
dcl-proc addProduct;

   clear pCommArea;
   callp PRODUCT(pCommArea);

end-proc;

/*----------------------------------------------------------------*/
/* PF3 – Return to pipeline                                       */
/*----------------------------------------------------------------*/
dcl-proc returnPipeline;

   callp BROKPIPE();

end-proc;
