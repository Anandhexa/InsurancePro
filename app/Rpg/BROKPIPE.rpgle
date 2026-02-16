ctl-opt dftactgrp(*no) actgrp(*new);

dcl-f PIPESCR   workstn;

dcl-s BrokerId           char(10);
dcl-s PlacementCount     int(5) inz(0);
dcl-s HasPlacements      ind inz(*off);

dcl-s PlacementId        char(10);
dcl-s PlacementName      char(30);
dcl-s PlacementStatus    char(15);

exsr InitializeData;
exsr ReadPlacements;
exsr DecideNextStep;
exsr DisplayResult;

*inlr = *on;
return;

begsr InitializeData;

   BrokerId = 'RGARCIA';
   PlacementCount = 0;
   HasPlacements = *off;

endsr;

begsr ReadPlacements;
   if BrokerId = 'RGARCIA';

      PlacementId     = 'PLC001';
      PlacementName   = 'PROPERTY INSURANCE';
      PlacementStatus = 'ACTIVE';

      PlacementCount = PlacementCount + 1;
      HasPlacements = *on;
    
    endif;

endsr;
