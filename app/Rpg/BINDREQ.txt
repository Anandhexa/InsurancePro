**FREE
ctl-opt dftactgrp(*no) actgrp(*caller) option(*srcstmt);

/* ---------------------------
   Files
----------------------------*/
dcl-f AXABIND usage(*output);
dcl-f BINDREQ workstn;

/* ---------------------------
   COMMAREA Equivalent
----------------------------*/
dcl-pi *n;
   CommArea char(100);
end-pi;

dcl-s WS_Submission_Key char(10);

/* ---------------------------
   Working Storage
----------------------------*/
dcl-s WS_Bind_Count packed(2:0) inz(0);
dcl-s WS_Success_Count packed(2:0) inz(0);
dcl-s WS_Bind_Counter packed(6:0) inz(100001);

dcl-s WS_HTTP_Status int(10);
dcl-s WS_API_Response varchar(500);
dcl-s WS_JSON_Payload varchar(1000);

/* ---------------------------
   Quote OCCURS Table
----------------------------*/
dcl-ds QuoteTbl dim(3);
   QuoteId char(10);
   CarrierName char(30);
   Premium packed(14:2);
   CommMethod char(15);
   BindStatus char(20);
   ConfRef char(20);
end-ds;

/* ---------------------------
   Bind Record DS
----------------------------*/
dcl-ds BindRec likerec(AXABIND:*all);

/* ---------------------------
   Mainline
----------------------------*/
WS_Submission_Key = %subst(CommArea:1:10);

exsr LoadQuotes;
exsr SendScreen;

*inlr = *on;
return;

/* =======================================================
   LOAD AVAILABLE QUOTES
=======================================================*/
begsr LoadQuotes;

WS_Bind_Count = 3;

QuoteTbl(1).QuoteId     = 'QTE001';
QuoteTbl(1).CarrierName = 'LLOYDS';
QuoteTbl(1).Premium     = 125000.00;
QuoteTbl(1).CommMethod  = 'API';
QuoteTbl(1).BindStatus  = 'READY';

QuoteTbl(2).QuoteId     = 'QTE002';
QuoteTbl(2).CarrierName = 'ZURICH';
QuoteTbl(2).Premium     = 135000.00;
QuoteTbl(2).CommMethod  = 'TRADING PLATFORM';
QuoteTbl(2).BindStatus  = 'READY';

QuoteTbl(3).QuoteId     = 'QTE003';
QuoteTbl(3).CarrierName = 'ALLIANZ';
QuoteTbl(3).Premium     = 118000.00;
QuoteTbl(3).CommMethod  = 'EMAIL';
QuoteTbl(3).BindStatus  = 'READY';

endsr;

/* =======================================================
   DISPLAY SCREEN
=======================================================*/
begsr SendScreen;

QUOTEID1 = QuoteTbl(1).QuoteId;
CARRIER1 = %subst(QuoteTbl(1).CarrierName:1:8);
PREMIUM1 = QuoteTbl(1).Premium;
COMMETH1 = QuoteTbl(1).CommMethod;
STATUS1  = %subst(QuoteTbl(1).BindStatus:1:6);
CONFREF1 = QuoteTbl(1).ConfRef;

QUOTEID2 = QuoteTbl(2).QuoteId;
CARRIER2 = %subst(QuoteTbl(2).CarrierName:1:8);
PREMIUM2 = QuoteTbl(2).Premium;
COMMETH2 = QuoteTbl(2).CommMethod;
STATUS2  = %subst(QuoteTbl(2).BindStatus:1:6);
CONFREF2 = QuoteTbl(2).ConfRef;

QUOTEID3 = QuoteTbl(3).QuoteId;
CARRIER3 = %subst(QuoteTbl(3).CarrierName:1:8);
PREMIUM3 = QuoteTbl(3).Premium;
COMMETH3 = QuoteTbl(3).CommMethod;
STATUS3  = %subst(QuoteTbl(3).BindStatus:1:6);
CONFREF3 = QuoteTbl(3).ConfRef;

BINDSTS = 'BIND REQUESTS PROCESSED: ' + %char(WS_Success_Count);

exfmt BINDMAP;

/* PF3 */
if *in03;
   call 'QUOTEFULL' CommArea;
   return;
endif;

/* ENTER */
if BIND1 = 'X'; exsr ProcessBind1; endif;
if BIND2 = 'X'; exsr ProcessBind2; endif;
if BIND3 = 'X'; exsr ProcessBind3; endif;

exsr SendScreen;

endsr;

/* =======================================================
   PROCESS BINDS
=======================================================*/
begsr ProcessBind1; exsr SendBindMethod1; endsr;
begsr ProcessBind2; exsr SendBindMethod2; endsr;
begsr ProcessBind3; exsr SendBindMethod3; endsr;

/* =======================================================
   Determine Method
=======================================================*/
dcl-proc SendBind;
   dcl-pi *n;
      idx int(10);
   end-pi;

   select;
      when QuoteTbl(idx).CommMethod = 'API';
         exsr SendApiBind;
      when QuoteTbl(idx).CommMethod = 'TRADING PLATFORM';
         exsr SendPlatformBind;
      when QuoteTbl(idx).CommMethod = 'EMAIL';
         exsr SendEmailBind;
   endsl;

   exsr CreateBindRecord;
   WS_Success_Count += 1;

end-proc;

/* Wrapper */
begsr SendBindMethod1; SendBind(1); endsr;
begsr SendBindMethod2; SendBind(2); endsr;
begsr SendBindMethod3; SendBind(3); endsr;

/* =======================================================
   SEND API BIND
=======================================================*/
begsr SendApiBind;

WS_JSON_Payload =
 '{ "bindRequest": {' +
 '"quoteId":"' + %trim(QuoteTbl(idx).QuoteId) + '",' +
 '"carrierName":"' + %trim(QuoteTbl(idx).CarrierName) + '",' +
 '"bindAmount":' + %char(QuoteTbl(idx).Premium) + ',' +
 '"communicationMethod":"API"}}';

exec sql
  select HTTP_STATUS_CODE, RESPONSE_MESSAGE
  into :WS_HTTP_Status, :WS_API_Response
  from table(
    QSYS2.HTTP_POST(
      url => 'https://api.carrier.com/v1/bind',
      data => :WS_JSON_Payload,
      headers => 'content-type,application/json'
    )
  );

if WS_HTTP_Status = 200 or WS_HTTP_Status = 201;
   QuoteTbl(idx).BindStatus = 'SENT';
   QuoteTbl(idx).ConfRef = 'API-' +
         %subst(%char(%timestamp()):9:6);
else;
   QuoteTbl(idx).BindStatus = 'FAILED';
endif;

endsr;

/* =======================================================
   PLATFORM BIND
=======================================================*/
begsr SendPlatformBind;

WS_JSON_Payload =
 '{ "bindRequest": {' +
 '"quoteId":"' + %trim(QuoteTbl(idx).QuoteId) + '",' +
 '"carrierName":"' + %trim(QuoteTbl(idx).CarrierName) + '",' +
 '"bindAmount":' + %char(QuoteTbl(idx).Premium) + ',' +
 '"communicationMethod":"TRADING_PLATFORM"}}';

exec sql
  select HTTP_STATUS_CODE
  into :WS_HTTP_Status
  from table(
    QSYS2.HTTP_POST(
      url => 'https://whitespace.axainsurance.com/api/v2/bind',
      data => :WS_JSON_Payload,
      headers => 'content-type,application/json'
    )
  );

if WS_HTTP_Status = 200 or WS_HTTP_Status = 201;
   QuoteTbl(idx).BindStatus = 'SENT';
   QuoteTbl(idx).ConfRef = 'WS-' +
         %subst(%char(%timestamp()):9:6);
else;
   QuoteTbl(idx).BindStatus = 'FAILED';
endif;

endsr;

/* =======================================================
   EMAIL BIND
=======================================================*/
begsr SendEmailBind;

QuoteTbl(idx).BindStatus = 'SENT';
QuoteTbl(idx).ConfRef = 'EMAIL-' +
      %subst(%char(%timestamp()):9:6);

endsr;

/* =======================================================
   CREATE BIND RECORD
=======================================================*/
begsr CreateBindRecord;

BindRec.BindId = 'BIND' + %char(WS_Bind_Counter);
WS_Bind_Counter += 1;

BindRec.QuoteId = QuoteTbl(idx).QuoteId;
BindRec.CarrierName = QuoteTbl(idx).CarrierName;
BindRec.CommunicationMethod = QuoteTbl(idx).CommMethod;
BindRec.BindStatus = QuoteTbl(idx).BindStatus;
BindRec.BindDate = %date();
BindRec.BindAmount = QuoteTbl(idx).Premium;
BindRec.ConfirmationRef = QuoteTbl(idx).ConfRef;

write AXABIND BindRec;

endsr;
