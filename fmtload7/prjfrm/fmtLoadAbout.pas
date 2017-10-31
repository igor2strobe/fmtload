unit fmtLoadAbout;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls;

type
  TFmtLoadAboutForm = class(TForm)
    lbCopyright: TLabel;
    bvBottom: TBevel;
    lbCompanyName: TLabel;
    lbDemoName: TLabel;
    imgIcon: TImage;
    reDemoInfo: TRichEdit;
    btnOK: TButton;
    lbVersion: TLabel;
  private
    { Private declarations }
  public
    { Public declarations }
    procedure SetData(const aVerStr: String);
  end;


implementation

{$R *.dfm}

{ TFmtLoadAboutForm }

procedure TFmtLoadAboutForm.SetData(const aVerStr: String);
begin
  lbVersion.Caption := Format('vers. %s',[aVerStr]);
end;

end.
