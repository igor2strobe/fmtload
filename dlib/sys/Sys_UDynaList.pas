unit Sys_UDynaList;

interface
uses Windows,Classes, SysUtils;

type
  TDynaList = class(TStringList)

  private
    FFileName: TFileName;
  public
    constructor InitFile(const dlFileName: TFileName);
  end;

function ReadDynaListFromFile(const dlFName: TFileName; var lst: TStringList): integer;


implementation


constructor TDynaList.InitFile(const dlFileName: TFileName);
begin

end;


function ReadDynaListFromFile;
begin

end;

end.
 