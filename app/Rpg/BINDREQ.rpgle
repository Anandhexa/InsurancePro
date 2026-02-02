**FREE
/*********************************************************************/
/* Program     : BINDREQ                                              */
/* Description : Bind Request Processing                              */
/* Converted   : COBOL -> RPGLE Free Format                            */
/*********************************************************************/

ctl-opt dftactgrp(*no)
        actgrp(*caller)
        option(*srcstmt:*nodebugio);

/*-------------------------------------------------------------------*/
/* COPYBOOKS                                                          */
/*-------------------------------------------------------------------*/
 /copy BIND
 /copy QUOTE
 /copy BINDMAP        // Map copybook

/*-------------------------------------------------------------------*/
/* WORKING STORAGE                                                    */
/*-------------------------------------------------------------------*/
dcl-s WS_Response        int(10);
dcl-s WS_SubmissionKey  char(10);
dcl-s WS_BindCount      packed(2:0) inz(0);
dcl-s WS_SuccessCount   packed(2:0) inz(0);
dcl-s WS_BindCounter    packed(6:0) inz(100001);
dcl-s WS_HttpStatus     packed(3:0);
dcl-s WS_ApiResponse    char(500);
dcl-s WS_JsonPayload    char(1000);

/*-------------------------------------------------------------------*/
/* QUOTE TABLE                                                        */
/*-------------------------------------------------------------------*/
dcl-ds WS_QuoteTable dim(3);
   WS_QuoteID      char(10);
   WS_CarrierName  char(30);
   WS_Premium      packed(12:2);
   WS_CommMethod   char(15);
   WS_BindStatus   char(20);
   WS_ConfRef      char(20);
end-ds;

/*-------------------------------------------------------------------*/
/* LINKAGE SECTION                                                    */
/*-------------------------------------------------------------------*/
dcl-pi *n;
   DFHCOMMAREA char(100);
end-pi;

/*-------------------------------------------------------------------*/
/* MAIN LOGIC                                                         */
/*-------------------------------------------------------------------*/
WS_SubmissionKey = %subst(DFHCOMMAREA:1:10);

exec cics handle
     condition(error)
     label(SEND_MAP);
end-exec;

exec cics handle aid
     enter(SEND_BIND_REQUEST)
     pf3(RETURN_DASHBOARD)
     pf4(BINDING_LOGIC)
     pf5(COMMUNICATION_MANAGER)
     pf12(MAIN_PARA);
end-exec;

MAIN_PARA:
   exsr LOAD_AVAILABLE_QUOTES;
   exsr SEND_MAP;
   return;

/*-------------------------------------------------------------------*/
/* LOAD AVAILABLE QUOTES                                              */
/*-------------------------------------------------------------------*/
LOAD_AVAILABLE_QUOTES:
   WS_BindCount = 3;

   WS_QuoteID(1)     = 'QTE001';
   WS_CarrierName(1)= 'LLOYDS';
   WS_Premium(1)    = 125000.00;
   WS_CommMethod(1) = 'API';
   WS_BindStatus(1) = 'READY';
   WS_ConfRef(1)    = *blanks;

   WS_QuoteID(2)     = 'QTE002';
   WS_CarrierName(2)= 'ZURICH';
   WS_Premium(2)    = 135000.00;
   WS_CommMethod(2) = 'TRADING PLATFORM';
   WS_BindStatus(2) = 'READY';
   WS_ConfRef(2)    = *blanks;

   WS_QuoteID(3)     = 'QTE003';
   WS_CarrierName(3)= 'ALLIANZ';
   WS_Premium(3)    = 118000.00;
   WS_CommMethod(3) = 'EMAIL';
   WS_BindStatus(3) = 'READY';
   WS_ConfRef(3)    = *blanks;
   return;

/*-------------------------------------------------------------------*/
/* RECEIVE MAP & PROCESS SELECTIONS                                   */
/*-------------------------------------------------------------------*/
SEND_BIND_REQUEST:
   exec cics receive
        map('BINDMAP')
        mapset('BINDREQ');
   end-exec;

   exsr PROCESS_BIND_SELECTIONS;
   exsr SEND_MAP;
   return;

/*-------------------------------------------------------------------*/
PROCESS_BIND_SELECTIONS:
   if BIND1I = 'X';
      WS_Response = 1;
      exsr SEND_BIND_BY_METHOD;
   endif;

   if BIND2I = 'X';
      WS_Response = 2;
      exsr SEND_BIND_BY_METHOD;
   endif;

   if BIND3I = 'X';
      WS_Response = 3;
      exsr SEND_BIND_BY_METHOD;
   endif;
   return;

/*-------------------------------------------------------------------*/
SEND_BIND_BY_METHOD:
   select;
      when WS_CommMethod(WS_Response) = 'API';
           exsr SEND_API_BIND;
      when WS_CommMethod(WS_Response) = 'TRADING PLATFORM';
           exsr SEND_PLATFORM_BIND;
      when WS_CommMethod(WS_Response) = 'EMAIL';
           exsr SEND_EMAIL_BIND;
   endsl;

   exsr CREATE_BIND_RECORD;
   WS_SuccessCount += 1;
   return;

/*-------------------------------------------------------------------*/
/* API BIND                                                           */
/*-------------------------------------------------------------------*/
SEND_API_BIND:
   WS_JsonPayload =
     '{"bindRequest":{"quoteId":"' + WS_QuoteID(WS_Response) +
     '","carrierName":"' + WS_CarrierName(WS_Response) +
     '","bindAmount":' + %char(WS_Premium(WS_Response)) +
     ',"communicationMethod":"API"}}';

   exec cics web open
        host('api.carrier.com')
        portnumber(443)
        scheme(HTTPS);
   end-exec;

   exec cics web send
        from(WS_JsonPayload)
        length(%len(%trimr(WS_JsonPayload)))
        mediatype('application/json')
        method(POST)
        path('/v1/bind')
        statuscode(WS_HttpStatus);
   end-exec;

   exec cics web close;
   end-exec;

   if WS_HttpStatus = 200 or WS_HttpStatus = 201;
      WS_BindStatus(WS_Response) = 'SENT';
      WS_ConfRef(WS_Response) =
         'API-' + %subst(%char(%timestamp()):9:6);
   else;
      WS_BindStatus(WS_Response) = 'FAILED';
   endif;
   return;

/*-------------------------------------------------------------------*/
/* PLATFORM BIND                                                      */
/*-------------------------------------------------------------------*/
SEND_PLATFORM_BIND:
   exec cics web open
        host('whitespace.axainsurance.com')
        portnumber(443)
        scheme(HTTPS);
   end-exec;

   WS_JsonPayload =
     '{"bindRequest":{"quoteId":"' + WS_QuoteID(WS_Response) +
     '","carrierName":"' + WS_CarrierName(WS_Response) +
     '","bindAmount":' + %char(WS_Premium(WS_Response)) +
     ',"communicationMethod":"TRADING_PLATFORM"}}';

   exec cics web send
        from(WS_JsonPayload)
        length(%len(%trimr(WS_JsonPayload)))
        mediatype('application/json')
        method(POST)
        path('/api/v2/bind')
        statuscode(WS_HttpStatus);
   end-exec;

   exec cics web close;
   end-exec;

   if WS_HttpStatus = 200 or WS_HttpStatus = 201;
      WS_BindStatus(WS_Response) = 'SENT';
      WS_ConfRef(WS_Response) =
         'WS-' + %subst(%char(%timestamp()):9:6);
   else;
      WS_BindStatus(WS_Response) = 'FAILED';
   endif;
   return;

/*-------------------------------------------------------------------*/
/* EMAIL BIND                                                         */
/*-------------------------------------------------------------------*/
SEND_EMAIL_BIND:
   WS_JsonPayload =
     'BIND REQUEST FOR QUOTE ' + WS_QuoteID(WS_Response) +
     ' CARRIER: ' + WS_CarrierName(WS_Response) +
     ' AMOUNT: ' + %char(WS_Premium(WS_Response)) +
     ' METHOD: EMAIL';

   exec cics send text
        from(WS_JsonPayload)
        length(%len(%trimr(WS_JsonPayload)))
        print;
   end-exec;

   WS_BindStatus(WS_Response) = 'SENT';
   WS_ConfRef(WS_Response) =
      'EMAIL-' + %subst(%char(%timestamp()):9:6);
   return;

/*-------------------------------------------------------------------*/
/* CREATE BIND RECORD                                                 */
/*-------------------------------------------------------------------*/
CREATE_BIND_RECORD:
   BIND_ID = 'BIND' + %char(WS_BindCounter);
   WS_BindCounter += 1;

   QUOTE_ID               = WS_QuoteID(WS_Response);
   CARRIER_NAME           = WS_CarrierName(WS_Response);
   COMMUNICATION_METHOD   = WS_CommMethod(WS_Response);
   BIND_STATUS            = WS_BindStatus(WS_Response);
   BIND_DATE              = %subst(%char(%date()):1:8);
   BIND_AMOUNT            = WS_Premium(WS_Response);
   CONFIRMATION_REF       = WS_ConfRef(WS_Response);

   AUDIT_LOG =
      'BIND REQUEST SENT VIA ' + COMMUNICATION_METHOD +
      ' FOR QUOTE ' + QUOTE_ID +
      ' ON ' + BIND_DATE;

   exec cics write
        dataset('AXABIND')
        from(BIND_REQUEST_RECORD)
        ridfld(BIND_ID);
   end-exec;
   return;

/*-------------------------------------------------------------------*/
/* SEND MAP                                                          */
/*-------------------------------------------------------------------*/
SEND_MAP:
   QUOTEID1O = WS_QuoteID(1);
   CARRIER1O = %subst(WS_CarrierName(1):1:8);
   PREMIUM1O = WS_Premium(1);
   COMMETH1O = WS_CommMethod(1);
   STATUS1O  = %subst(WS_BindStatus(1):1:6);
   CONFREF1O = WS_ConfRef(1);

   QUOTEID2O = WS_QuoteID(2);
   CARRIER2O = %subst(WS_CarrierName(2):1:8);
   PREMIUM2O = WS_Premium(2);
   COMMETH2O = WS_CommMethod(2);
   STATUS2O  = %subst(WS_BindStatus(2):1:6);
   CONFREF2O = WS_ConfRef(2);

   QUOTEID3O = WS_QuoteID(3);
   CARRIER3O = %subst(WS_CarrierName(3):1:8);
   PREMIUM3O = WS_Premium(3);
   COMMETH3O = WS_CommMethod(3);
   STATUS3O  = %subst(WS_BindStatus(3):1:6);
   CONFREF3O = WS_ConfRef(3);

   BINDSTSO = 'BIND REQUESTS PROCESSED: ' + %char(WS_SuccessCount);

   exec cics send
        map('BINDMAP')
        mapset('BINDREQ')
        erase;
   end-exec;
   return;

/*-------------------------------------------------------------------*/
/* NAVIGATION                                                         */
/*-------------------------------------------------------------------*/
RETURN_DASHBOARD:
   exec xctl
        program('QUOTEFULL')
        commarea(DFHCOMMAREA);
   end-exec;

BINDING_LOGIC:
   DFHCOMMAREA = WS_QuoteID(1);
   exec link
        program('BINDLOGIC')
        commarea(DFHCOMMAREA);
   end-exec;
   exsr LOAD_AVAILABLE_QUOTES;
   exsr SEND_MAP;
   return;

COMMUNICATION_MANAGER:
   DFHCOMMAREA = WS_QuoteID(1);
   exec link
        program('BINDCOMM')
        commarea(DFHCOMMAREA);
   end-exec;
   exsr SEND_MAP;
   return;
