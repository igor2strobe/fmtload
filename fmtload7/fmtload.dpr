program fmtload;

uses
  ShareMem,
  Windows,
  SysUtils,
  RxStrUtils,
  Forms,
  Dialogs,
  sys_uLog,
  Sys_iStrUtils,
  fmtloadmain in 'fmtloadmain.pas' {MainForm},
  Sys_CmdParam in '..\..\dlib\sys\Sys_CmdParam.pas',
  PaymClass in 'prjlib\PaymClass.pas',
  DataSrcPathForm in 'prjfrm\DataSrcPathForm.pas' {frmDataSrcPath},
  fmtlDataSrcParamForm in 'prjfrm\fmtlDataSrcParamForm.pas' {frmDataSrcParam},
  fmtloadDMSVC in 'prjlib\fmtloadDMSVC.pas',
  fmtLoadAbout in 'prjfrm\fmtLoadAbout.pas' {FmtLoadAboutForm},
  paymStorage in 'prjlib\PaymStorage.pas',
  ConverDLL in 'prjlib\ConverDll.pas',
  PaymMDIntrface in 'prjlib\PaymMDIntrface.pas',
  xmlStatement in 'prjlib\xmlStatement.pas',
  fmtCurrNameSvc in 'prjlib\fmtCurrNameSvc.pas',
  dmodsvc in 'prjlib\dmodsvc.pas',
  datamodule in 'datamodule.pas' {dm: TDataModule};

{$R *.res}

var
  iprm: inputStrParams;
begin
  if GrepCommandParams(iprm, ['CFG']) =0 then
  begin
    Application.Initialize;
    Application.Title := 'fmt stmt loader';
//    Application.CreateForm(TfrmDataSrcParam, frmDataSrcParam);
  Application.CreateForm(Tdm, dm);
  if dm.loadparams(iprm) then
    begin
      Application.CreateForm(TMainForm, MainForm);
      dm.SetLogList( MainForm.memLog.Lines);
      Application.Run;
    end;
  end;
end.



