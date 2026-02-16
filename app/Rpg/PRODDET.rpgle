**FREE
ctl-opt dftactgrp(*no) actgrp(*new);

/* Files */
dcl-f PRODDETDSPF workstn;
dcl-f AXAPROD  keyed;
dcl-f AXASUBM  keyed;

/* COMMAREA equivalent */
dcl-pi *n;
   pCommArea char(100) options(*varsize);
end-pi;

/* Variables */
dcl-s wsProductKey char(10);
dcl-s wsSubmCount  packed(3:0) inz(0);
dcl-s exitProgram  ind inz(*off);

/* ===================== */
/* Main Logic            */
/* ===================== */

wsProductKey = %subst(pCommArea:1:10);

exsr ReadProduct;
exsr ReadSubmissions;

dow not exitProgram;

   exsr SendScreen;
   exfmt PRODR;

   select;
      when *in02;  // PF2 New Submission
         pCommArea = wsProductKey;
         *inlr = *on;
         call 'SUBMISSN' pCommArea;

      when *in05;  // PF5 Generate Document
         pCommArea = SUBMISSIONID;
         *inlr = *on;
         call 'DOCGEN' pCommArea;

      when *in03;  // PF3 Exit
         exitProgram = *on;

      when *in12;  // Refresh
         exsr ReadSubmissions;

   endsl;

enddo;

*inlr = *on;
return;

/* ===================== */
/* Read Product          */
/* ===================== */
begsr ReadProduct;

   chain wsProductKey AXAPROD;

   if %found(AXAPROD);
      PRODNM = PRODUCTNAME;
   else;
      PRODNM = ' ';
   endif;

endsr;

/* ===================== */
/* Read Submissions      */
/* ===================== */
begsr ReadSubmissions;

   wsSubmCount = 0;
   clear NOSUBM;

   setll wsProductKey AXASUBM;
   reade wsProductKey AXASUBM;

   if %found(AXASUBM);

      wsSubmCount += 1;

      SUBMNAME   = PRODUCTNAME;
      SUBMDATE   = SUBMISSIONDATE;
      VALIDUNTL  = VALIDUNTIL;
      BROKERREF  = BROKERREFERENCE;

   else;
      NOSUBM = 'NO SUBMISSIONS FOUND';
      clear SUBMNAME;
      clear SUBMDATE;
      clear VALIDUNTL;
      clear BROKERREF;
   endif;

endsr;

/* ===================== */
/* Send Screen           */
/* ===================== */
begsr SendScreen;

   // Fields already loaded into display buffer

endsr;
