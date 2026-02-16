**FREE
ctl-opt dftactgrp(*no) actgrp(*new);

/* Files */
dcl-f POLICYDSPF workstn;
dcl-f AXAPOLICY keyed;
dcl-f AXAQUOTE  keyed;
dcl-f AXASUBM   keyed;

/* Program parameter (COMMAREA equivalent) */
dcl-pi *n;
   pCommArea char(100) options(*varsize);
end-pi;

/* Variables */
dcl-s wsPolicyKey     char(15);
dcl-s wsPolicyCounter packed(8:0) inz(10000001);
dcl-s today           char(8);

/* Indicators */
dcl-s exitProgram ind inz(*off);

/* Main Logic */

wsPolicyKey = %subst(pCommArea:1:15);

if %trim(wsPolicyKey) <> '';
   chain wsPolicyKey AXAPOLICY;
   if not %found(AXAPOLICY);
      exsr NewPolicy;
   endif;
endif;

dow not exitProgram;

   exsr SendScreen;
   exfmt POLICYR;

   select;
      when *in01;  // PF1 Amendments
         pCommArea = POLICYID;
         call 'POLAMEND' pCommArea;
      when *in02;  // PF2 Renewal
         pCommArea = POLICYID;
         call 'POLRENEW' pCommArea;
      when *in03;  // PF3 Return
         call 'QUOTEDASH' pCommArea;
         exitProgram = *on;
      when *in12;  // Refresh
         iter;
      other;
         exsr SavePolicy;
   endsl;

enddo;

*inlr = *on;
return;

/* ============================== */
/* New Policy Logic               */
/* ============================== */
begsr NewPolicy;

   clear AXAPOLICY;

   // Quote ID from commarea
   chain %subst(pCommArea:1:10) AXAQUOTE;
   if %found(AXAQUOTE);
      chain SUBMISSIONID AXASUBM;
   endif;

   // Build Policy ID
   POLICYID = 'POL' + %char(wsPolicyCounter);
   wsPolicyCounter += 1;

   today = %char(%date():*iso0);

   POLNUM = 'AXA-' + today + '-' + %char(wsPolicyCounter);

   POLICYLIMIT  = LIMIT;
   PREMIUM      = TOTALPREMIUM;
   POLSTS       = 'ACTIVE';

endSr;

/* ============================== */
/* Save Policy                    */
/* ============================== */
begsr SavePolicy;

   POLICYID   = POLICYID;
   INSUREDNAME = INSNAME;
   POLICYTYPE = POLTYPE;
   INCEPTIONDATE = INCEPDT;
   EXPIRYDATE = EXPIRDT;
   BROKERNAME = BROKER;

   write AXAPOLICY;

endSr;

/* ============================== */
/* Send Screen                    */
/* ============================== */
begsr SendScreen;

   POLICYID  = POLICYID;
   POLNUM    = POLNUM;
   INSNAME   = INSUREDNAME;
   POLTYPE   = POLICYTYPE;
   INCEPDT   = INCEPTIONDATE;
   EXPIRDT   = EXPIRYDATE;
   POLIMIT   = POLICYLIMIT;
   PREMIUM   = TOTALPREMIUM;
   POLSTS    = POLICYSTATUS;

endSr;
