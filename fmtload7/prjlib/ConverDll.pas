unit ConverDLL;

interface
uses
  Sharemem,
  Windows,Classes;


type
  TRemoteLogProc = procedure(const aMsg: String; const lstLog: TStrings=nil;
                              const iLevel: word=$01);far;

  TConversionFunc= function( iAgentID: integer;
                          // var aStatm: TCustStatement;
                             lstMatch: TStringList;
                             aSession: TComponent;
                             LogFn: TRemoteLogProc;
                             sVars: array of string): integer; stdcall;


const
  sstAccountNotDetailed = $10;

implementation


end.
