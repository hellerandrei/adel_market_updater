program adel_uploader;

uses
  Forms,
  Main in 'Main.pas' {fMain},
  Vcl.Themes,
  Vcl.Styles,
  operations in 'operations.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Carbon');
  Application.Title := 'Uploader';
  Application.CreateForm(TfMain, fMain);
  Application.Run;
end.
