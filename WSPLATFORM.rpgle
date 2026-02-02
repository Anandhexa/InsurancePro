**free
ctl-opt dftactgrp(*no) actgrp(*caller);

dcl-pi *n;
  DFHCOMMAREA char(100);
end-pi;

dcl-s WS_RESPONSE int(10) inz(0);
dcl-s WS_SUBMISSION_KEY char(10) inz(*loval);
dcl-s WS_PLATFORM_COUNT zoned(2:0) inz(0);
dcl-s WS_SUCCESS_COUNT zoned(2:0) inz(0);
dcl-s WS_BROKER_EMAIL char(50) inz('RGARCIA@AXAINSURANCE.COM');
dcl-s WS_WHITESPACE_URL char(100) inz('https://whitespace.axainsurance.com/api/v2/submissions');
dcl-s WS_AUTH_TOKEN char(100) inz('Bearer WS_PLATFORM_TOKEN_XYZ123');
dcl-s WS_HTTP_STATUS zoned(3:0) inz(0);
dcl-s WS_API_RESPONSE char(500) inz(*loval);
dcl-s WS_JSON_PAYLOAD char(1500) inz(*loval);
dcl-s WS_PAYLOAD_LEN int(10) inz(0);

dcl-s WSSEL1I char(1) inz(' ');
dcl-s WSSEL2I char(1) inz(' ');
dcl-s WSSEL3I char(1) inz(' ');

dcl-s SUBMIDO char(10) inz(*loval);
dcl-s INSNAMEO char(30) inz(*loval);
dcl-s PRODNMO char(30) inz(*loval);
dcl-s WSSTSO char(50) inz(*loval);

dcl-ds WS_PLATFORM_REQUEST qualified;
  WS_SUBMISSION_ID char(10);
  WS_SOURCE char(20);
  WS_INSURED_NAME char(30);
  WS_BROKER_EMAIL char(50);
  WS_PRODUCT char(30);
  WS_TRANSACTION char(15);
  WS_INCEPTION_DATE char(10);
  WS_EXPIRATION_DATE char(10);
  WS_PROGRAM_LIMIT zoned(17:2);
  WS_CARRIER_NAME char(30);
  WS_PLATFORM_STATUS char(20);
end-ds;

dcl-s WS_CARR_NAME char(30) dim(3) inz(*loval);
dcl-s WS_CARR_TYPE char(20) dim(3) inz(*loval);
dcl-s WS_CARR_PLATFORM char(20) dim(3) inz(*loval);
dcl-s WS_CARR_SELECTED char(1) dim(3) inz(*loval);

dcl-ds SUBMISSION_RECORD qualified;
  SUBMISSION_ID char(10);
  PRODUCT_ID char(10);
  SUBMISSION_DATE char(10);
  VALID_UNTIL_DATE char(10);
  BROKER_REF char(20);
  SUBMISSION_STATUS char(10);
  WORKFLOW_STATE char(20);
  ASSIGNED_USER char(30);
  PRIORITY_LEVEL char(10);
  VALIDATION_SCORE zoned(3:0);
  BUSINESS_RULE_STATUS char(15);
  SLA_DUE_DATE char(10);
  ESCALATION_FLAG char(1);
  LAST_MODIFIED char(26);
  CREATED_BY char(30);
end-ds;

dcl-ds PRODUCT_RECORD qualified;
  PRODUCT_ID char(10);
  PLACEMENT_ID char(10);
  PRODUCT_NAME char(30);
  PRODUCT_TYPE char(20);
  COVERAGE_LIMIT zoned(14:2);
  DEDUCTIBLE zoned(12:2);
  PREMIUM zoned(12:2);
  PRODUCT_STATUS char(10);
end-ds;

dcl-ds PLACEMENT_RECORD qualified;
  PLACEMENT_ID char(10);
  PLACEMENT_NAME char(30);
  PLACEMENT_STATUS char(15);
  PLACEMENT_PRIORITY char(10);
  PLACEMENT_DUE_DATE char(10);
  PLACEMENT_BROKER char(8);
end-ds;

dcl-proc LoadWsCarriers;
  WS_CARR_NAME(1) = 'LLOYD''S MARKET PORTAL';
  WS_CARR_TYPE(1) = 'INSURANCE MARKET';
  WS_CARR_PLATFORM(1) = 'WHITESPACE';
  WS_CARR_NAME(2) = 'ZURICH TRADING HUB';
  WS_CARR_TYPE(2) = 'DIRECT INSURER';
  WS_CARR_PLATFORM(2) = 'WHITESPACE';
  WS_CARR_NAME(3) = 'ALLIANZ MARKETPLACE';
  WS_CARR_TYPE(3) = 'REINSURER';
  WS_CARR_PLATFORM(3) = 'WHITESPACE';
end-proc;

dcl-proc BuildWsPayload;
  WS_PLATFORM_REQUEST.WS_SUBMISSION_ID = SUBMISSION_RECORD.SUBMISSION_ID;
  WS_PLATFORM_REQUEST.WS_SOURCE = 'WHITESPACE';
  WS_PLATFORM_REQUEST.WS_INSURED_NAME = PLACEMENT_RECORD.PLACEMENT_NAME;
  WS_PLATFORM_REQUEST.WS_BROKER_EMAIL = WS_BROKER_EMAIL;
  WS_PLATFORM_REQUEST.WS_PRODUCT = PRODUCT_RECORD.PRODUCT_NAME;
  WS_PLATFORM_REQUEST.WS_TRANSACTION = PRODUCT_RECORD.PRODUCT_TYPE;
  WS_PLATFORM_REQUEST.WS_INCEPTION_DATE = SUBMISSION_RECORD.SUBMISSION_DATE;
  WS_PLATFORM_REQUEST.WS_EXPIRATION_DATE = SUBMISSION_RECORD.VALID_UNTIL_DATE;
  WS_PLATFORM_REQUEST.WS_PROGRAM_LIMIT = PRODUCT_RECORD.COVERAGE_LIMIT;
  WS_PLATFORM_REQUEST.WS_PLATFORM_STATUS = 'SUBMISSION-SENT';
end-proc;

dcl-proc ProcessSelectedWsCarriers;
  if WSSEL1I = 'X';
    SendToWhitespace(1);
  endif;
  if WSSEL2I = 'X';
    SendToWhitespace(2);
  endif;
  if WSSEL3I = 'X';
    SendToWhitespace(3);
  endif;
end-proc;

*inlr = *on;
return;
