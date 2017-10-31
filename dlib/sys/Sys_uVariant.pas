unit Sys_uVariant;

interface
uses Windows,Variants,SysUtils;

function VarAsString( vInp: Variant; const IsTrim: bool=TRUE): String;

implementation

{varOleStr	Reference to a dynamically allocated UNICODE string.

varDispatch	Reference to an Automation object (an IDispatch interface pointer).
varError	Operating system error code.
varBoolean	16-bit boolean (type WordBool).
varVariant	A variant.
varUnknown	Reference to an unknown OLE object (an IInterface or IUnknown interface pointer).
varShortInt	8-bit signed integer (type ShortInt)
varByte	A Byte
varWord	unsigned 16-bit value (Word)
varLongWord	unsigned 32-bit value (LongWord)
varInt64	64-bit signed integer (Int64)

varStrArg	COM-compatible string.
varString	Reference to a dynamically allocated string (not COM compatible).
varAny	        A CORBA Any value.}

function VarAsString( vInp: Variant; const IsTrim: bool=TRUE): String;
begin
  result := VarAsType(vInp, varString);
  if (length(result) >0) and (IsTrim) then
    result := Trim(Result);
end;

end.
