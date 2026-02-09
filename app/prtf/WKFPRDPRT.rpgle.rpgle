ctl-opt dftactgrp(*no) actgrp('INSURANCE');

dcl-f PRODUCT   usage(*input);
dcl-f WORKFLOW  usage(*input);
dcl-f WKFPRTF   printer;

dcl-s PrintDate      char(8);
dcl-s PrintTime      char(6);
dcl-s EndProdFile    ind inz(*off);
dcl-s EndWkfFile     ind inz(*off);

dcl-s CurrProdId     char(10);
dcl-s WkfStage       char(15);
dcl-s WkfStatus      char(12);
dcl-s LastUpdate     char(8);

exsr Initialize;
exsr PrintHeader;
exsr ProcessWorkflowProducts;
exsr PrintFooter;

*inlr = *on;
return;

begsr Initialize;

   PrintDate = %char(%date():*iso0);
   PrintTime = %char(%time():*hms0);

endsr;

begsr PrintHeader;

   RPTDATE = PrintDate;
   RPTTIME = PrintTime;

   write RPTHEADER;
   write COLHEADER;

endsr;

begsr ProcessWorkflowProducts;

   setll *loval PRODUCT;

   dow EndProdFile = *off;

      read PRODUCT;
      if %eof(PRODUCT);
         EndProdFile = *on;
      else;

         CurrProdId = PRODUCT.PRODUCT_ID;
         exsr ReadWorkflowStatus;

         if %len(%trim(WkfStage)) > 0;

            PRODID    = PRODUCT.PRODUCT_ID;
            PRODNAME  = PRODUCT.PRODUCT_NAME;
            WKFSTAGE  = WkfStage;
            WKFSTATUS = WkfStatus;
            LASTUPD   = LastUpdate;

            write DETAIL;

         endif;

      endif;

   enddo;

endsr;

begsr ReadWorkflowStatus;

   clear WkfStage;
   clear WkfStatus;
   clear LastUpdate;

   EndWkfFile = *off;
   setll CurrProdId WORKFLOW;

   reade CurrProdId WORKFLOW;
   if not %eof(WORKFLOW);

      WkfStage  = WORKFLOW.WORKFLOW_STAGE;
      WkfStatus = WORKFLOW.WORKFLOW_STATUS;
      LastUpdate= WORKFLOW.LAST_UPDATE_DATE;

   endif;

endsr;

begsr PrintFooter;

   write FOOTER;

endsr;
