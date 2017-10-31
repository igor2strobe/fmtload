unit db_RefUtils;

interface
uses DB, Variants;

function FGetDataSetField( ds: TDataSet; const sFieldName: string;
                                       const vartype: TVarType): Variant;

function FSetDataSetField( aDS: TDataSet; const aFieldName: string;
                                       const vValue: Variant): integer;


implementation
uses DBUtils;

function GetFieldValue(const aFieldName,aTable,aParamStr: string;
                        const aDefault:string): Variant;
begin

end;


function FGetDataSetField( ds: TDataSet; const sFieldName: string; const varType: TVarType): Variant;
begin
  result := Unassigned;
  if (not IsDataSetEmpty(Ds)) and assigned( ds.FindField(sFieldName)) then
  try
    result := VarAsType(ds[sFieldName], varType);
  except
  end;
end;


function FSetDataSetField( aDS: TDataSet; const aFieldName: string;
             const vValue: Variant): integer;
begin
  result := -2;
  if (not IsDataSetEmpty(aDS)) and assigned( aDS.FindField(aFieldName)) then
  try
    aDS.Edit;
    aDS.FieldByName(aFieldName).Value := vValue;
    aDS.Post;
    result := 0;
  except
    result := -1;
  end;
end;


end.
