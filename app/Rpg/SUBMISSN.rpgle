**free
ctl-opt dftactgrp(*no) actgrp(*caller);

/*------------------------------------------------------------------*/
/* Files                                                            */
/*------------------------------------------------------------------*/
dcl-f AXASUBM   usage(*update) keyed;
dcl-f SUBMSSCR  workstn indDs(Inds);

/*------------------------------------------------------------------*/
/* Indicators                                                       */
/*------------------------------------------------------------------*/
dcl-ds Inds;
   enter   ind pos(1);
   pf1     ind pos(1);
   pf2     ind pos(2);
   pf3     ind pos(3);
   pf4     ind pos(4);
   pf5     ind pos(5);
   pf6     ind pos(6);
   pf7     ind pos(7);
   pf8     ind pos(8);
   pf9     ind pos(9);
   pf10    ind pos(10);
   pf11    ind pos(11);
   pf12    ind pos(12);
   pf13    ind pos(13);
   pf14    ind pos(14);
   pf15    ind pos(15);
   pf24    ind pos(24);
end-ds;

/*------------------------------------------------------------------*/
/* Data Structures                                                  */
/*------------------------------------------------------------------*/
dcl-ds SubmRec likerec(AXASUBM:*all);

/*------------------------------------------------------------------*/
/* Parameters (COMMAREA equivalent)                                 */
/*------------------------------------------------------------------*/
dcl-pi *n;
   pKey char(10);
end-pi;

/*------------------------------------------------------------------*/
/* Working Storage                                                  */
/*------------------------------------------------------------------*/
dcl-s updateFlag char(1) inz('N');
dcl-s today      date;
dcl-s validDate  date;

/*------------------------------------------------------------------*/
/* Initialization                                                   */
/*------------------------------------------------------------------*/
if %trim(pKey) <> '';
   chain pKey AXASUBM SubmRec;
   if %found(AXASUBM);
      updateFlag = 'Y';
   else;
      initNewSubmission();
   endif;
else;
   initNewSubmission();
endif;

/*------------------------------------------------------------------*/
/* Main Screen Loop                                                 */
/*------------------------------------------------------------------*/
dou pf3;

   loadScreen();
   exfmt SUBMSSMP;

   if pf12;
      iter;
   endif;

   if enter;
      saveSubmission();
      callp PRODDET(SubmRec.PRODUCT_ID);
      leave;
   endif;

   if pf1;
      callp QUOTEDASH(SubmRec.SUBMISSION_ID);
      leave;
   endif;

   if pf2;
      callp DOCUPLOAD(SubmRec.SUBMISSION_ID);
      leave;
   endif;

   if pf4;
      callp GTMDETAIL(SubmRec.SUBMISSION_ID);
      leave;
   endif;

   if pf5;
      callp DOCGEN(SubmRec.SUBMISSION_ID);
      leave;
   endif;

   if pf6;
      callp APISUBM(SubmRec.SUBMISSION_ID);
      leave;
   endif;

   if pf7;
      callp CARRSEL(SubmRec.SUBMISSION_ID);
      leave;
   endif;

   if pf8;
      callp WSAPI(SubmRec.SUBMISSION_ID);
      iter;
   endif;

   if pf9;
      callp RFQWS(SubmRec.SUBMISSION_ID);
      leave;
   endif;

   if pf10;
      callp EMAILSEL(SubmRec.SUBMISSION_ID);
      leave;
   endif;

   if pf11;
      callp APICARR(SubmRec.SUBMISSION_ID);
      leave;
   endif;

   if pf13;
      callp RULEENG(SubmRec.SUBMISSION_ID);
      iter;
   endif;

   if pf14;
      callp WORKFLOW(SubmRec.SUBMISSION_ID);
      iter;
   endif;

   if pf15;
      callp DATAVALID(SubmRec.SUBMISSION_ID);
      iter;
   endif;

   if pf24;
      callp WSPLATFORM(SubmRec.SUBMISSION_ID);
      leave;
   endif;

enddo;

return;

/*------------------------------------------------------------------*/
/* Initialize New Submission                                        */
/*------------------------------------------------------------------*/
dcl-proc initNewSubmission;
   clear SubmRec;
   SubmRec.PRODUCT_ID = pKey;
   updateFlag = 'N';
end-proc;

/*------------------------------------------------------------------*/
/* Save Submission                                                  */
/*------------------------------------------------------------------*/
dcl-proc saveSubmission;

   SubmRec.SUBMISSION_DATE   = SUBMDT;
   SubmRec.VALID_UNTIL_DATE  = VALIDDT;
   SubmRec.BROKER_REF        = BRKREF;
   SubmRec.SUBMISSION_STATUS = 'ACTIVE';

   if updateFlag = 'N';
      SubmRec.SUBMISSION_ID = %char(%timestamp():*iso0);
      write AXASUBM SubmRec;
   else;
      update AXASUBM SubmRec;
   endif;

end-proc;

/*------------------------------------------------------------------*/
/* Load Screen (SEND MAP)                                           */
/*------------------------------------------------------------------*/
dcl-proc loadScreen;

   today     = %date();
   validDate = today + %days(30);

   SUBMID  = SubmRec.SUBMISSION_ID;
   SUBMDT  = %char(today);
   VALIDDT = %char(validDate);

   if updateFlag = 'Y';
      SUBMDT  = SubmRec.SUBMISSION_DATE;
      VALIDDT = SubmRec.VALID_UNTIL_DATE;
      BRKREF  = SubmRec.BROKER_REF;
   endif;

end-proc;
