unit Unit1;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.UIConsts,
  System.Classes,
  System.Variants,
  System.Generics.Collections,
  System.Hash,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  FMX.Objects,
  FMX.Layouts,
  FMX.ListBox,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  Net.Socket,
  Net.StreamSocket;

type
  TForm1 = class(TForm)
    ServerClientsListBox: TListBox;
    Circle2: TCircle;
    Button1: TButton;
    ClientsListBox: TListBox;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    ComboBox1: TComboBox;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    Button8: TButton;
    Timer1: TTimer;
    Label1: TLabel;
    Label2: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    FServerClientsReceive: Integer;
    Server: TTCPSocket;
    ServerClients: TObjectList<TStreamSocket>;
    procedure OnServerClientsListChange(Sender: TObject; const Client: TStreamSocket; Action: TCollectionNotification);
    procedure OnServerStart(Sender: TObject);
    procedure OnServerClose(Sender: TObject);
    procedure OnServerExcept(Sender: TObject);
    procedure OnServerAccept(Sender: TObject);
    procedure OnServerClientConnect(Sender: TObject);
    procedure OnServerClientReceived(Sender: TObject);
    procedure OnServerClientClose(Sender: TObject);
    procedure OnServerClientExcept(Sender: TObject);
    procedure UpdateServerClients;
  private
    FClientsReceive: Integer;
    Clients: TObjectList<TStreamSocket>;
    procedure OnClientsListChange(Sender: TObject; const Client: TStreamSocket; Action: TCollectionNotification);
    procedure OnClientConnect(Sender: TObject);
    procedure OnClientReceived(Sender: TObject);
    procedure OnClientClose(Sender: TObject);
    procedure OnClientExcept(Sender: TObject);
    procedure UpdateClients;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

const
  ConnectedString: array[Boolean] of string = ('Disconnected','Connected');

function ClientToString(C: TTCPSocket): string;
begin
  Result:=C.ClassName+' '+C.RemoteAddress+' '+ConnectedString[C.Connected]+' '+C.TagString;
end;

constructor TForm1.Create(AOwner: TComponent);
begin
  inherited;

  ServerClients:=TObjectList<TStreamSocket>.Create;
  ServerClients.OnNotify:=OnServerClientsListChange;

  Server:=TTCPSocket.Create;
  Server.OnConnect:=OnServerStart;
  Server.OnClose:=OnServerClose;
  Server.OnExcept:=OnServerExcept;
  Server.OnAccept:=OnServerAccept;

  Clients:=TObjectList<TStreamSocket>.Create;
  Clients.OnNotify:=OnClientsListChange;

end;

destructor TForm1.Destroy;
begin

  Server.Terminate;

  Clients.Free;
  ServerClients.Free;
  Server.Free;

  inherited;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  C: TStreamSocket;
  B: TBytes;
begin

  B:=TEncoding.ANSI.GetBytes(THash.GetRandomString(10));

  SetLength(B,100000);//1024*4);//65536);

  for C in Clients do if C.Connected then C.SendPackage(B,1111);

  for C in ServerClients do if C.Connected then C.SendPackage(B,1111);

end;

procedure TForm1.OnServerClientsListChange(Sender: TObject;
  const Client: TStreamSocket; Action: TCollectionNotification);
begin
  if Action=TCollectionNotification.cnRemoved then Client.Terminate;
  UpdateServerClients;
end;

procedure TForm1.UpdateServerClients;
var C: TTCPSocket;
begin

  if ServerClients=nil then Exit;

  ServerClientsListBox.BeginUpdate;

  ServerClientsListBox.Clear;

  for C in ServerClients do
  ServerClientsListBox.Items.Add(ClientToString(C));

  ServerClientsListBox.EndUpdate;

end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  Server.Start(4444);
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  ServerClients.Delete(ServerClientsListBox.Selected.Index);
  UpdateServerClients;
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  ServerClients[ServerClientsListBox.Selected.Index].Disconnect;
  UpdateServerClients;
end;

procedure TForm1.Button7Click(Sender: TObject);
begin
  ServerClients.Clear;
  UpdateServerClients;
end;

procedure TForm1.OnServerAccept(Sender: TObject);
var Client: TStreamSocket;
begin

  Client:=TStreamSocket.Create(Server.Accept);

  Client.OnConnect:=OnServerClientConnect;
  Client.OnReceived:=OnServerClientReceived;
  Client.OnClose:=OnServerClientClose;
  Client.OnExcept:=OnServerClientExcept;
  Client.Connect;

  ServerClients.Add(Client);

end;

procedure TForm1.OnServerClose(Sender: TObject);
begin
  Circle2.Fill.Color:=claRed;
end;

procedure TForm1.OnServerExcept(Sender: TObject);
begin
  ApplicationHandleException(Server.E);
end;

procedure TForm1.OnServerStart(Sender: TObject);
begin
  Circle2.Fill.Color:=claGreen;
end;

procedure TForm1.OnServerClientClose(Sender: TObject);
begin
  UpdateServerClients;
end;

procedure TForm1.OnServerClientExcept(Sender: TObject);
begin
  TTCPSocket(Sender).TagString:=TTCPSocket(Sender).E.Message;
  UpdateServerClients;
end;

procedure TForm1.OnServerClientConnect(Sender: TObject);
begin
  UpdateServerClients;
end;

procedure TForm1.OnServerClientReceived(Sender: TObject);
begin
  Inc(FServerClientsReceive,TStreamSocket(Sender).DataStream.Size);
  Label2.Text:=IntToStr(FServerClientsReceive);
end;

{ Clients }

procedure TForm1.Button2Click(Sender: TObject);
var Client: TStreamSocket;
begin

  Client:=TStreamSocket.Create;

  Client.OnConnect:=OnClientConnect;
  Client.OnReceived:=OnClientReceived;
  Client.OnClose:=OnClientClose;
  Client.OnExcept:=OnClientExcept;

  Clients.Add(Client);

  Client.Connect(ComboBox1.Items[ComboBox1.ItemIndex],4444);

end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  Clients.Delete(ClientsListBox.Selected.Index);
end;

procedure TForm1.Button6Click(Sender: TObject);
begin
  Clients[ClientsListBox.Selected.Index].Disconnect;
  UpdateClients;
end;

procedure TForm1.Button8Click(Sender: TObject);
begin
  Clients.Clear;
  UpdateClients;
end;

procedure TForm1.OnClientsListChange(Sender: TObject; const Client: TStreamSocket; Action: TCollectionNotification);
begin
  if Action=TCollectionNotification.cnRemoved then Client.Terminate;
  UpdateClients;
end;

procedure TForm1.UpdateClients;
var C: TTCPSocket;
begin

  if Clients=nil then Exit;

  ClientsListBox.BeginUpdate;

  ClientsListBox.Clear;

  for C in Clients do
  ClientsListBox.Items.Add(ClientToString(C));

  ClientsListBox.EndUpdate;

end;

procedure TForm1.OnClientClose(Sender: TObject);
begin
  UpdateClients;
end;

procedure TForm1.OnClientConnect(Sender: TObject);
begin
  UpdateClients;
end;

procedure TForm1.OnClientExcept(Sender: TObject);
begin
  TTCPSocket(Sender).TagString:=TTCPSocket(Sender).E.Message;
  UpdateClients;
end;

procedure TForm1.OnClientReceived(Sender: TObject);
begin
  Inc(FClientsReceive,TStreamSocket(Sender).DataStream.Size);
  Label1.Text:=IntToStr(FClientsReceive);
end;

end.
