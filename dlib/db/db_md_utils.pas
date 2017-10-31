unit db_md_utils;

interface
uses
  Windows,RxMemDS;


implementation
uses
  SysUtils, StrUtils, DB;

function rxmdTableStrSupress(var md: TrxMemoryData; const mdFieldName,src,dst: string): integer;
var i,k: integer;
  vs: string;
  j1,j2: integer;
  fieldMatched: bool;
begin
  result := 0;
  with md do
  if Active and (recordCount >0) then     //fielddefs
  try
//  sortOnFields('');
//  first;
    for k := 0 to md.FieldDefs.Count-1 do begin // first scanning
      fieldMatched := uppercase(fieldDefs[k].Name) =upperCase(mdFieldName);
      if fieldMatched then
        break;
    end;

    if FieldMatched then
    for i:= 0 to RecordCount-1 do
    begin
      vs := fieldByName(mdFieldName).asString;

      if pos(src,vs) >0 then
      try
        vs := ansiReplaceStr(vs,src,dst);
        edit;
        fieldByName('cat_name').asString := vs;
        post;
        inc(result);
      except
        if state =dsEdit then
          cancel;
      end;
    end;
  finally

  end;
end;

end.
