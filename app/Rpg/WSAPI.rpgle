ctl-opt dftactgrp(*no) actgrp(*new);

dcl-s RequestId          char(12);
dcl-s RequestPayload     char(1000);
dcl-s ResponsePayload    char(1000);
dcl-s ResponseCode       int(5);
dcl-s ResponseMessage    char(50);
dcl-s ApiStatus          char(15);
dcl-s RequestCounter     int(6) inz(900001);

exsr Initialize;
exsr BuildRequest;
exsr SendRequest;
exsr EvaluateResponse;
exsr DisplayResult;

*inlr = *on;
return;

begsr Initialize;

   ApiStatus       = 'NEW';
   ResponseCode    = 0;
   ResponseMessage = *blanks;
   RequestPayload  = *blanks;
   ResponsePayload = *blanks;

endsr;

begsr BuildRequest;

   RequestId = 'REQ' + %char(RequestCounter);
   RequestCounter += 1;

   RequestPayload =
      '{ "requestId": "' + RequestId +
      '", "operation": "FETCH_DATA", "source": "SYSTEM" }';

endsr;

begsr SendRequest;

   if %len(%trim(RequestPayload)) > 0;

      ResponseCode    = 200;
      ResponsePayload =
         '{ "status": "SUCCESS", "message": "DATA RECEIVED" }';

   else;

      ResponseCode    = 500;
      ResponsePayload =
         '{ "status": "FAILED", "message": "INVALID REQUEST" }';

   endif;

endsr;

begsr EvaluateResponse;

   if ResponseCode = 200;

      ApiStatus       = 'SUCCESS';
      ResponseMessage = 'REQUEST COMPLETED';

   else;

      ApiStatus       = 'FAILED';
      ResponseMessage = 'REQUEST ERROR';

   endif;

endsr;

begsr DisplayResult;

   dsply ('--------------------------------------');
   dsply ('REQUEST ID      : ' + RequestId);
   dsply ('STATUS          : ' + ApiStatus);
   dsply ('RESPONSE CODE   : ' + %char(ResponseCode));
   dsply ('MESSAGE         : ' + ResponseMessage);
   dsply ('--------------------------------------');

endsr;

