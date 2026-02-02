**free
ctl-opt dftactgrp(*no) actgrp(*caller);

/*------------------------------------------------------------------*/
/* Files                                                            */
/*------------------------------------------------------------------*/
dcl-f AXAGTM  usage(*update) keyed;
dcl-f VIEWGTM workstn indDs(Inds);

/*------------------------------------------------------------------*/
/* Indicators                                                       */
/*------------------------------------------------------------------*/
dcl-ds Inds;
   exit        ind pos(3);   // PF3
   refresh     ind pos(12);  // PF12
end-ds;

/*------------------------------------------------------------------*/
/* Data Structures                                                  */
/*------------------------------------------------------------------*/
dcl-ds GTMRec likerec(AXAGTM:*all);

/*------------------------------------------------------------------*/
/* Parameters (COMMAREA equivalent)                                 */
/*------------------------------------------------------------------*/
dcl-pi *n;
   pRFQKey char(10);
end-pi;

/*------------------------------------------------------------------*/
/* Main Logic                                                       */
/*------------------------------------------------------------------*/
chain pRFQKey AXAGTM GTMRec;
if not %found(AXAGTM);
   return;
endif;

// Load screen fields
loadScreen();

dou exit;

   exfmt VIEWMAP;

   if exit;
      leave;
   endif;

   if refresh;
      loadScreen();
      iter;
   endif;

   // ENTER pressed → update GTM request
   buildUpdatedRequest();
   update AXAGTM GTMRec;

   // Return to GTM details
   callp GTMDETAIL(GTMRec.GTM_SUBMISSION_ID);
   leave;

enddo;

return;

/*------------------------------------------------------------------*/
/* Load Screen (SEND MAP)                                           */
/*------------------------------------------------------------------*/
dcl-proc loadScreen;

   SUBMID     = GTMRec.GTM_SUBMISSION_ID;
   RFQID      = GTMRec.GTM_RFQ_ID;
   DISTTYPE   = GTMRec.GTM_DISTRIBUTION;
   CARRNAME   = GTMRec.GTM_CARRIER_NAME;
   ORGTYPE    = GTMRec.GTM_CARRIER_TYPE;
   STATUS     = GTMRec.GTM_STATUS;

end-proc;

/*------------------------------------------------------------------*/
/* Build Updated Request                                            */
/*------------------------------------------------------------------*/
dcl-proc buildUpdatedRequest;

   GTMRec.GTM_DISTRIBUTION  = DISTTYPE;
   GTMRec.GTM_CARRIER_NAME = CARRNAME;

   select;
      when CARRNAME = 'LLOYDS';
         GTMRec.GTM_CARRIER_TYPE = 'INSURANCE MARKET';

      when CARRNAME = 'ZURICH';
         GTMRec.GTM_CARRIER_TYPE = 'DIRECT INSURER';

      when CARRNAME = 'ALLIANZ';
         GTMRec.GTM_CARRIER_TYPE = 'REINSURER';

      when CARRNAME = 'AXA';
         GTMRec.GTM_CARRIER_TYPE = 'DIRECT INSURER';

      when CARRNAME = 'CHUBB';
         GTMRec.GTM_CARRIER_TYPE = 'DIRECT INSURER';

      other;
         GTMRec.GTM_CARRIER_TYPE = 'CARRIER';
   endsl;

   GTMRec.GTM_STATUS = 'UPDATED';

end-proc;
