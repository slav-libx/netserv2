program setserv2;

uses
  System.StartUpCopy,
  FMX.Forms,
  Net.Socket in '..\relictum.node\Library\Net.Socket.pas',
  Net.StreamSocket in '..\relictum.node\Library\Net.StreamSocket.pas',
  UCustomMemoryStream in '..\relictum.node\Library\UCustomMemoryStream.pas',
  Unit1 in 'Unit1.pas' {Form1};

{$R *.res}

begin

  ReportMemoryLeaksOnShutdown:=True;

  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;

end.
