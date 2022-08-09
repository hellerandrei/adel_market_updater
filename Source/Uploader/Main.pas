unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls,

  IdFTP,
  System.JSON,
  System.Threading,
  System.Net.HttpClient,
  System.Net.HttpClientComponent,
  System.Net.URLClient,

  Vcl.ComCtrls,

  IdBaseComponent,
  IdComponent,
  IdTCPConnection,
  IdTCPClient,
  IdFTPCommon,
  IdExplicitTLSClientServerBase
  ;

type
  TfMain = class(TForm)
    Panel1: TPanel;
    ftp_host_e: TEdit;
    Label5: TLabel;
    Panel2: TPanel;
    Label1: TLabel;
    ftp_remotepath_e: TEdit;
    Panel3: TPanel;
    Label2: TLabel;
    ftp_localpath_e: TEdit;
    Panel4: TPanel;
    Label3: TLabel;
    ftp_pass_e: TEdit;
    Panel5: TPanel;
    Label4: TLabel;
    ftp_user_e: TEdit;
    Panel6: TPanel;
    Label6: TLabel;
    ftp_port_e: TEdit;
    Panel7: TPanel;
    upload_ftp_b: TButton;
    Log_m: TMemo;
    adelaida_version_l: TLabel;
    Button1: TButton;
    Label7: TLabel;
    mail_host_e: TEdit;
    Label8: TLabel;
    mail_port_e: TEdit;
    Label9: TLabel;
    mail_login_e: TEdit;
    Label10: TLabel;
    mail_pass_e: TEdit;
    ProgressBar1: TProgressBar;
    procedure FormCreate(Sender: TObject);
    procedure upload_ftp_bClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private


  public
    l_progressStatus : Tlabel;
    Tasks : array of ITask;
    Procedure Save_Log( text : String);

  end;

  TFtp = class
    _bytesToTransfer : Int64;
    public
      Function FTP_Upload( Ftp_host, Ftp_port, Ftp_file, Local_file,  Ftp_user, Ftp_pass : String ) : boolean;
    private
      _progress, _fileSize : Int64;
      procedure FTPWork(ASender: TObject; AWorkMode: TWorkMode;  AWorkCount: Int64);
      procedure FTPWorkBegin(ASender: TObject; AWorkMode: TWorkMode;  AWorkCountMax: Int64);
      procedure FTPWorkEnd(ASender: TObject; AWorkMode: TWorkMode);
  end;

var
  fMain: TfMain;
  sPath, sFileName, SBuild : String;

const
  Host = 'https://www.adelaida.ua/';
  ApiKey = '';

implementation

{$R *.dfm}

uses
  Operations
;




procedure TFtp.FTPWork(ASender: TObject; AWorkMode: TWorkMode;
  AWorkCount: Int64);
begin
  _progress := AWorkCount;
  TThread.Synchronize(nil,
      Procedure
      begin
        fMain.ProgressBar1.Position     := Round(AWorkCount * 100 / _fileSize);
        fmain.l_progressStatus.Caption  := FormatFloat('#,###,###.###', AWorkCount) + ' / ' + FormatFloat('#,###,###.###', _fileSize);
      end
  );
end;

procedure TFtp.FTPWorkBegin(ASender: TObject; AWorkMode: TWorkMode;
  AWorkCountMax: Int64);
begin
   TThread.Synchronize(nil,
      Procedure
      begin
        fMain.Progressbar1.Position   := 0;
        fMain.ProgressBar1.Visible    := true;
        _fileSize                     := AWorkCountMax;
        fMain.Progressbar1.Max        := 100;
      end
   );
end;

procedure TFtp.FTPWorkEnd(ASender: TObject; AWorkMode: TWorkMode);
begin
    TThread.Synchronize(nil,
      Procedure
      begin
        fMain.Progressbar1.Position     := 0;
        fmain.l_progressStatus.Caption  := '';
        fMain.ProgressBar1.Visible      := false;
      end
    );
end;


Function TFtp.FTP_Upload( Ftp_host, Ftp_port, Ftp_file, Local_file,  Ftp_user, Ftp_pass : String ) : boolean;
var
  idFTP : TIdFtp;
Begin
  result          := false;

  idFTP := TidFTP.Create();
  try

    idFTP.Host          := Ftp_host;
    idFTP.Port          := Ftp_port.ToInteger();

    idFTP.Username      := Ftp_user;
    idFTP.Password      := Ftp_pass;

    idFTP.Passive       := True;
    idFTP.TransferType  := ftBinary;

    idFTP.OnWork        := FTPWork;
    idFTP.OnWorkBegin   := FTPWorkBegin;
    idFTP.OnWorkEnd     := FTPWorkEnd;

    try
      idFTP.Connect;
    except
      on E : Exception do
      Begin
        fMain.Save_Log('!!! FTP : Connect Error : ' + E.Message);
        exit;
      end;
    End;


    if idFTP.Connected then
    try
      fMain.Save_Log(' FTP : Соединение установленно');

      if idFTP.Size(Ftp_file) > 0 then
        idFTP.Delete(Ftp_file);

      idFTP.Put(Local_file, Ftp_file, True);
      result := true;
    except
      on E : Exception do
        fMain.Save_Log('!!! FTP : Ошибка скачивания файла: ' + E.Message);
    end;


  finally
    idFTP.Disconnect;
    idFTP.Free;
  end;

End;


procedure TfMain.Button1Click(Sender: TObject);
begin
 SPath                         := ExtractFilePath( Application.ExeName );
  SFileName                     := ExtractFileName( Application.ExeName );

  fMain.Caption := 'Аделаида Uploader [ '+GetMyVersion +' ]';
  fMain.ftp_localpath_e.Text := SPath+'Adelaida.exe';

  fMain.adelaida_version_l.Caption :=  GetFileVersion(fMain.ftp_localpath_e.Text);

  if adelaida_version_l.Caption<>'' then
  Begin
    fMain.upload_ftp_b.Enabled  := true;
    fMain.ftp_remotepath_e.Text := 'adelaida_'+ SBuild+'.exe';
  End;

end;

procedure TfMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  l_progressStatus.Free;
end;

procedure TfMain.FormCreate(Sender: TObject);

begin
  SetLength(Tasks, 0);
  SPath                         := ExtractFilePath( Application.ExeName );
  SFileName                     := ExtractFileName( Application.ExeName );

  fMain.Caption := 'Аделаида Uploader [ '+GetMyVersion +' ]';
  fMain.ftp_localpath_e.Text := SPath+'Adelaida.exe';

  fMain.adelaida_version_l.Caption :=  GetFileVersion(fMain.ftp_localpath_e.Text);

  if adelaida_version_l.Caption<>'' then
  Begin
    fMain.upload_ftp_b.Enabled  := true;
    fMain.ftp_remotepath_e.Text := 'adelaida_'+ SBuild+'.exe';
  End;

  l_progressStatus              := TLabel.Create(Self);
  l_progressStatus.Parent       := ProgressBar1;
  l_progressStatus.AutoSize     := False;
  l_progressStatus.Align        := alClient;
  l_progressStatus.Alignment    := taCenter;
  l_progressStatus.Font.Size    := 12;

  l_progressStatus.Margins.Top      := 5;
  l_progressStatus.AlignWithMargins := true;

  l_progressStatus.Transparent  := True;

  ProgressBar1.Visible          := false;


end;


Procedure TfMain.Save_Log( text : String);
Begin
  TThread.Queue(nil,
    Procedure
    begin
        OutputDebugString(PChar(text));
        fMain.Log_m.Lines.Add('[ '+timetostr(now)+' ]: ' + text);
    end);
End;


Function ThTask_UploadFtpFile(  aFtp_host, aFtp_port, aFtp_file, aLocal_file,  aFtp_user, aFtp_pass,
                                amail_host, amail_port, amail_login, amail_pass : String ) : ITask;
Begin
  fMain.upload_ftp_b.Enabled := false;
  result := TTask.Run(
    Procedure
    var
        FStream              : TMemoryStream;
        HTTP_R               : TNetHTTPRequest;
        HTTP_C               : TNetHTTPClient;
        Resp                 : IHTTPResponse;
        FJSON                : TJSONObject;

        FIndex, i, j         : Integer;

        FRespons,
        FAction,
        FUrl,
        FOperation,
        FResp_status,
        FResp_action,
        f_tempString,

        fFtp_host,
        fFtp_port,
        fFtp_file,
        fLocal_file,
        fFtp_user,
        fFtp_pass,

        fmail_host,
        fmail_port,
        fmail_login,
        fmail_pass
                            : String;
        Ftp                 : TFtp;
    Begin
      fFtp_host   := aFtp_host;
      fFtp_port   := aFtp_port;
      fFtp_file   := aFtp_file;
      fLocal_file := aLocal_file;
      fFtp_user   := aFtp_user;
      fFtp_pass   := aFtp_pass;

      fmail_host  := amail_host;
      fmail_port  := amail_port;
      fmail_login := amail_login;
      fmail_pass  := amail_pass;

      fmain.Save_Log('Выгружаем файл: ' + fFtp_file + '...');

      Ftp :=  TFtp.Create;
      try

        if Ftp.FTP_Upload( fFtp_host, fFtp_port, fFtp_file, fLocal_file,  fFtp_user, fFtp_pass) then
        Begin
          fMain.Save_Log(' FTP : Файл ''' + fFtp_file + ''' успешно загружен.');

          FAction     := 'add_new_fileversion';
          FOperation  := URLEncode( Base64Encode(fFtp_file+'||'+fFtp_user+'||'+ Base64Encode(fFtp_pass)+'||'+fFtp_host+'||'+fFtp_port+'||'+
                                    fmail_host+'||'+fmail_port+'||'+ fmail_login+'||'+Base64Encode(fmail_pass)));
          FUrl        := Host + 'api.php?action=' + FAction + '&key=' + fFtp_file + '&operation=' + FOperation;

          fMain.Save_Log(' HTTPS : Отправляем изменение в базу данных');
          FStream   := TMemoryStream.Create;
          HTTP_R    := TNetHTTPRequest.Create(nil);
          HTTP_C    := TNetHTTPClient.Create(nil);

          try
            HTTP_C.Accept             := 'text/html';
            HTTP_C.AcceptEncoding     := 'gzip';
            HTTP_R.ContentStream      := FStream;

            HTTP_C.ConnectionTimeout  := 5000;
            HTTP_C.ResponseTimeout    := 12000;

            HTTP_R.CLient             := HTTP_C;
            HTTP_R.MethodString       := 'GET';
            HTTP_R.URL                := FUrl;

            fMain.Save_Log('HTTPS : FUrl = ' + FUrl);

            try
             Resp  := HTTP_R.Execute();
            except on E : Exception do
              Begin
                fMain.Save_Log(E.ClassName+' HTTPS : [ ' + inttostr(FIndex) + ' ] поднята ошибка, с сообщением : '+E.Message);
                exit;
              End;
            end;



              case Resp.StatusCode of
                200 : Begin

                        FRespons := Resp.ContentAsString();

                        FJSON   := TJSONObject.Create;
                        try
                          FJSON := TJSONObject.ParseJSONValue(FRespons) as TJSONObject;

                          if FJSON <> nil then
                          Begin

                            fMain.Save_Log(' HTTPS : JSON = ' + FJSON.ToString);

                            FJSON.TryGetValue('status', FResp_status);
                            FJSON.TryGetValue('action', FResp_action);
                          End;
                        finally
                          FreeAndNil(FJSON);
                        end;
                End;
              end;
          finally
            FreeAndNil(FStream);
            FreeAndNil(HTTP_R);
            FreeAndNil(HTTP_C);
          end;

        End
        else
        Begin
          fmain.Save_Log(' HTTPS : Ошибка отправки изменений в базу данных' );
        End;
      finally
        FreeAndNil(Ftp);
      end;
    End
  );
End;

Procedure ThTask_UploadFtpFile_Completed( AAction : String );
Begin
  TTask.Run(
            procedure
            var FAction : String;
            begin
              FAction := AAction;

              if FAction = 'add_new_fileversion' then
              Begin
                TTask.WaitForAll(fMain.Tasks);
              End;

              TThread.Synchronize(nil,
                procedure
                begin

                   fMain.Save_Log('Все задачи add_new_fileversion завершены') ;

                   if FAction = 'add_new_fileversion' then
                   Begin
                     SetLength(fMain.Tasks, 0);
                     fMain.upload_ftp_b.Enabled := true;
                   End;
                end
                );
            end
            );

End;

procedure TfMain.upload_ftp_bClick(Sender: TObject);
Begin

  SetLength(fMain.Tasks, length(fMain.Tasks)+1);

  fMain.Tasks[length(fMain.Tasks)-1] :=   ThTask_UploadFtpFile( fMain.ftp_host_e.Text, fMain.ftp_port_e.Text, fMain.ftp_remotepath_e.Text,
                                                    fMain.ftp_localpath_e.Text, fMain.ftp_user_e.Text, fMain.ftp_pass_e.Text,
                                                    fMain.mail_host_e.Text, fMain.mail_port_e.Text, fMain.mail_login_e.Text, fMain.mail_pass_e.Text);

  ThTask_UploadFtpFile_Completed('add_new_fileversion');
end;



end.
