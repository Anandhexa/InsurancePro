**free
ctl-opt dftactgrp(*no) actgrp(*caller);

dcl-pi *n;
  DFHCOMMAREA char(100);
end-pi;

dcl-s WS_SUBMISSION_KEY char(10) inz(*loval);
dcl-s WS_API_URL char(100) inz('https://whitespace.axainsurance.com/api/v1/submissions');
dcl-s WS_AUTH_TOKEN char(100) inz('Bearer WS_API_TOKEN_ABCD1234567890');
dcl-s WS_HTTP_STATUS int(10) inz(0);
dcl-s WS_API_RESPONSE char(500) inz(*loval);
dcl-s WS_JSON_PAYLOAD char(1000) inz(*loval);
 dcl-s WS_JSON_LEN int(10) inz(0);

dcl-c MSG_SUCCESS 'WS API SUBMISSION SUCCESSFUL';
dcl-c MSG_FAILED  'WS API SUBMISSION FAILED';
dcl-c MSG_ERROR   'WS API ERROR OCCURRED';

dcl-ds WS_API_REQUEST qualified;
  WS_SUBMISSION_ID char(10);
  WS_PLACEMENT_ID char(10);
  WS_PRODUCT_ID char(10);
  WS_CLIENT_ID char(8);
  WS_BROKER_ID char(8);
  WS_CARRIER_ID char(8);
  WS_BUSINESS_TYPE char(15);
  WS_INCEPTION_DATE char(10);
  WS_EXPIRY_DATE char(10);
  WS_CURRENCY char(3);
  WS_LIMIT_AMOUNT packed(17:2);
  WS_DEDUCTIBLE_AMT packed(14:2);
  WS_PREMIUM_AMT packed(14:2);
  WS_COMMISSION_PCT packed(5:2);
  WS_STATUS char(20);
  WS_CREATED_DATE char(10);
  WS_MODIFIED_DATE char(10);
end-ds;

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
  VALIDATION_SCORE packed(3:0);
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
  COVERAGE_LIMIT packed(14:2);
  DEDUCTIBLE packed(12:2);
  PREMIUM packed(12:2);
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

dcl-proc ReadSubmissionData;
  exec cics read
    dataset('AXASUBM')
    into(SUBMISSION_RECORD)
    ridfld(WS_SUBMISSION_KEY)
  end-exec;

  exec cics read
    dataset('AXAPROD')
    into(PRODUCT_RECORD)
    ridfld(SUBMISSION_RECORD.PRODUCT_ID)
  end-exec;

  exec cics read
    dataset('AXAPLCMT')
    into(PLACEMENT_RECORD)
    ridfld(PRODUCT_RECORD.PLACEMENT_ID)
  end-exec;
end-proc;

dcl-proc BuildWsRequest;
  WS_API_REQUEST.WS_SUBMISSION_ID = SUBMISSION_RECORD.SUBMISSION_ID;
  WS_API_REQUEST.WS_PLACEMENT_ID = PLACEMENT_RECORD.PLACEMENT_ID;
  WS_API_REQUEST.WS_PRODUCT_ID = PRODUCT_RECORD.PRODUCT_ID;
  WS_API_REQUEST.WS_CLIENT_ID = 'CLIENT01';
  WS_API_REQUEST.WS_BROKER_ID = 'RGARCIA';
  WS_API_REQUEST.WS_CARRIER_ID = 'CARR001';
  WS_API_REQUEST.WS_BUSINESS_TYPE = 'NEW BUSINESS';
  WS_API_REQUEST.WS_INCEPTION_DATE = SUBMISSION_RECORD.SUBMISSION_DATE;
  WS_API_REQUEST.WS_EXPIRY_DATE = SUBMISSION_RECORD.VALID_UNTIL_DATE;
  WS_API_REQUEST.WS_CURRENCY = 'USD';
  WS_API_REQUEST.WS_LIMIT_AMOUNT = PRODUCT_RECORD.COVERAGE_LIMIT;
  WS_API_REQUEST.WS_DEDUCTIBLE_AMT = PRODUCT_RECORD.DEDUCTIBLE;
  WS_API_REQUEST.WS_PREMIUM_AMT = PRODUCT_RECORD.PREMIUM;
  WS_API_REQUEST.WS_COMMISSION_PCT = 5.00;
  WS_API_REQUEST.WS_STATUS = 'SUBMITTED';
  WS_API_REQUEST.WS_CREATED_DATE = %char(%date():*iso0);
  WS_API_REQUEST.WS_MODIFIED_DATE = %char(%date():*iso0);
end-proc;

dcl-proc BuildJsonPayload;
  WS_JSON_PAYLOAD =
    '{' +
    '"submissionId":"' + %trimr(WS_API_REQUEST.WS_SUBMISSION_ID) + '",' +
    '"placementId":"' + %trimr(WS_API_REQUEST.WS_PLACEMENT_ID) + '",' +
    '"productId":"' + %trimr(WS_API_REQUEST.WS_PRODUCT_ID) + '",' +
    '"clientId":"' + %trimr(WS_API_REQUEST.WS_CLIENT_ID) + '",' +
    '"brokerId":"' + %trimr(WS_API_REQUEST.WS_BROKER_ID) + '",' +
    '"carrierId":"' + %trimr(WS_API_REQUEST.WS_CARRIER_ID) + '",' +
    '"businessType":"' + %trimr(WS_API_REQUEST.WS_BUSINESS_TYPE) + '",' +
    '"inceptionDate":"' + %trimr(WS_API_REQUEST.WS_INCEPTION_DATE) + '",' +
    '"expiryDate":"' + %trimr(WS_API_REQUEST.WS_EXPIRY_DATE) + '",' +
    '"currency":"' + %trimr(WS_API_REQUEST.WS_CURRENCY) + '",' +
    '"limitAmount":' + %trim(%char(WS_API_REQUEST.WS_LIMIT_AMOUNT)) + ',' +
    '"deductibleAmount":' + %trim(%char(WS_API_REQUEST.WS_DEDUCTIBLE_AMT)) + ',' +
    '"premiumAmount":' + %trim(%char(WS_API_REQUEST.WS_PREMIUM_AMT)) + ',' +
    '"commissionPct":' + %trim(%char(WS_API_REQUEST.WS_COMMISSION_PCT)) + ',' +
    '"status":"' + %trimr(WS_API_REQUEST.WS_STATUS) + '",' +
    '"createdDate":"' + %trimr(WS_API_REQUEST.WS_CREATED_DATE) + '",' +
    '"modifiedDate":"' + %trimr(WS_API_REQUEST.WS_MODIFIED_DATE) + '"' +
    '}';

  WS_JSON_LEN = %len(%trimr(WS_JSON_PAYLOAD));
end-proc;

dcl-proc CallWhitespaceApi;
  exec cics web open
    host('whitespace.axainsurance.com')
    portnumber(443)
    scheme(HTTPS)
  end-exec;

  exec cics web send
    from(WS_JSON_PAYLOAD)
    length(WS_JSON_LEN)
    mediatype('application/json')
    method(POST)
    path('/api/v1/submissions')
    statuscode(WS_HTTP_STATUS)
  end-exec;

  exec cics web receive
    into(WS_API_RESPONSE)
    length(%size(WS_API_RESPONSE))
  end-exec;

  exec cics web close
  end-exec;
end-proc;

dcl-proc ProcessResponse;
  dcl-s Msg char(30);

  if (WS_HTTP_STATUS = 200) or (WS_HTTP_STATUS = 201);
    Msg = MSG_SUCCESS;
  else;
    Msg = MSG_FAILED;
  endif;

  exec cics send text
    from(Msg)
    length(%len(%trimr(Msg)))
  end-exec;
end-proc;

exec cics handle condition
  error(ErrorHandler)
end-exec;

WS_SUBMISSION_KEY = %subst(DFHCOMMAREA:1:10);

ReadSubmissionData();
BuildWsRequest();
BuildJsonPayload();
CallWhitespaceApi();
ProcessResponse();

exec cics return
end-exec;

ErrorHandler:
  exec cics send text
    from(MSG_ERROR)
    length(%len(%trimr(MSG_ERROR)))
  end-exec;

  exec cics return
  end-exec;

  *inlr = *on;
  return;
