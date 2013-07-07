unit Communicator;

interface

uses SysUtils, IdUDPServer, IdSocketHandle, Classes, Player, Client;

type
//====================================================================================
	Packet = record
		QueryType: Byte;
		Data: array of Byte;
	end;
//------------------------------------------------------------------------------------
	ClientPacketType = (CL_WORLD_CHANGED, CL_DISCONNECTED);
	ServerPacketType = (SV_INFO_REQUEST, SV_CLIENT_CONNECTED, SV_CLIENT_KEYS_CHANGED, SV_CLIENT_DISCONNECTED);
//------------------------------------------------------------------------------------
	CommunicatorType = (COMM_PASSIVE, COMM_CLIENT, COMM_SERVER);
//------------------------------------------------------------------------------------
	PacketHandlers = record
		WorldChangedEvent: procedure(WorldState: PlayerInfoList) of object;
		DisconnectedEvent: procedure(Reason: string) of object;

		ClientConnectedEvent: function(Nickname: string): CPlayer of object;
		ClientKeysChangedEvent: procedure(CurrentClient: CClient; Keys: KeyState) of object;
		ClientDisconnectedEvent: procedure(CurrentClient: CClient) of object;
	end;
//------------------------------------------------------------------------------------
	CCommunicator = class
	private
		fType: CommunicatorType;

		fHandlers: PacketHandlers;

		fUdpConnector: TIdUDPServer;
		fClients: Clients;

		fServerIP: string;
		fServerPort: Word;

		function ProcessPacket(var APacket: Packet; AData: TStream): Boolean;
		procedure OnUdpReadServer(Sender: TObject; AData: TStream; ABinding: TIdSocketHandle);
		procedure OnUdpReadClient(Sender: TObject; AData: TStream; ABinding: TIdSocketHandle);
	public
		constructor Create(IP:string; Port:Word; AHandlers: PacketHandlers);
		destructor Destroy; override;

		procedure SV_BroadcastWorldState(WorldState: PlayerInfoList);
		procedure SV_DisconnectClient(APlayer: CPlayer; Reason: string);

		procedure CL_SendConnectionQuery(NickName: string);
		procedure CL_SendKeyStateChanged(Keys: KeyState);
		procedure CL_Disconnect;
	end;
//====================================================================================
implementation
//====================================================================================
constructor CCommunicator.Create(IP: string; Port: Word; AHandlers: PacketHandlers);
begin
	fClients:=Clients.Create;
	fHandlers:=AHandlers;

	fUdpConnector:=TIdUDPServer.Create(nil);
	fUdpConnector.BufferSize:=32768;
	if IP = '' then
	begin
		fType:=COMM_SERVER;
		fUdpConnector.OnUDPRead:=OnUdpReadServer;
		fUdpConnector.DefaultPort:=Port;
	end	else
	begin
		fType:=COMM_CLIENT;
		fUdpConnector.OnUDPRead:=OnUdpReadClient;
		Randomize;
		fUdpConnector.DefaultPort:=27005-Random(2000);
		fServerIP:=IP;
		fServerPort:=Port;
	end;

	fUdpConnector.Active:=True;
end;
//------------------------------------------------------------------------------------
destructor CCommunicator.Destroy;
begin
	fUdpConnector.Active:=False;
	FreeAndNil(fUdpConnector);
	FreeAndNil(fClients);
end;
//------------------------------------------------------------------------------------
function CCommunicator.ProcessPacket(var APacket: Packet; AData: TStream): Boolean;
var
	StringStream: TStringStream;
	QueryType: Byte;
begin
	Result:=False;
	if AData.Size < 5 then
		Exit;

	StringStream:=TStringStream.Create('');
	StringStream.CopyFrom(AData, 4);

	if StringStream.DataString <> 'Rage' then
		Exit;

	StringStream.CopyFrom(AData, 1);
	QueryType:=Byte(StringStream.DataString[5]);

	APacket.QueryType:=QueryType;
	if AData.Size-AData.Position <> 0 then
	begin
		SetLength(APacket.Data, AData.Size-AData.Position);
	
		StringStream.CopyFrom(AData, AData.Size-AData.Position);
		StringStream.Position:=5;

		StringStream.ReadBuffer(Pointer(APacket.Data)^, StringStream.Size-StringStream.Position);
	end;

	StringStream.Free;

	Result:=True;
end;
//------------------------------------------------------------------------------------
procedure CCommunicator.OnUdpReadServer(Sender: TObject; AData: TStream; ABinding: TIdSocketHandle);
var
	APacket: Packet;
	Keys: KeyState;
	CurrentClient: CClient;
	Nickname: string;
	i: LongInt;
begin
	if not ProcessPacket(APacket, AData) then
		Exit;

	CurrentClient:=nil;
	for i:=0 to fClients.Count-1 do
		if (CClient(fClients[i]).fIP = ABinding.PeerIP) and (CClient(fClients[i]).fPort = ABinding.PeerPort) then
			CurrentClient:=CClient(fClients[i]);

	if CurrentClient = nil then
	begin
		case ServerPacketType(APacket.QueryType) of
			SV_INFO_REQUEST:
			begin

			end;
			SV_CLIENT_CONNECTED:
			begin
				SetLength(Nickname, Length(APacket.Data));
				Move(Pointer(Pointer(APacket.Data)^), Pointer(Pointer(Nickname)^), Length(APacket.Data));
				if @fHandlers.ClientConnectedEvent <> nil then
					fClients.Add(CClient.Create(fHandlers.ClientConnectedEvent(Nickname), ABinding.PeerIP, ABinding.PeerPort));
			end;
		end;
	end else
	begin
		case ServerPacketType(APacket.QueryType) of
			SV_CLIENT_KEYS_CHANGED:
			begin
				Move(Pointer(Pointer(APacket.Data)^), Keys, Length(APacket.Data));

				if @fHandlers.ClientKeysChangedEvent <> nil then
					fHandlers.ClientKeysChangedEvent(CurrentClient, Keys);
			end;
			SV_CLIENT_DISCONNECTED:
			begin
				if @fHandlers.ClientDisconnectedEvent <> nil then
					fHandlers.ClientDisconnectedEvent(CurrentClient);

				CCLient(fClients.Extract(CurrentClient)).Free;
			end;
		end;
	end;
end;
//------------------------------------------------------------------------------------
procedure CCommunicator.OnUdpReadClient(Sender: TObject; AData: TStream; ABinding: TIdSocketHandle);
var
	WorldState: PlayerInfoList;
	APacket: Packet;
	Reason: string;
begin
	if (ABinding.PeerIP <> fServerIP) or (ABinding.PeerPort <> fServerPort) then
		Exit;

	if not ProcessPacket(APacket, AData) then
		Exit;

	case ClientPacketType(APacket.QueryType) of
		CL_WORLD_CHANGED:
		begin
			SetLength(WorldState, Round(Length(APacket.Data)/SizeOf(PlayerInfo)));
			Move(Pointer(Pointer(APacket.Data)^), Pointer(Pointer(WorldState)^), Length(APacket.Data));

			if @fHandlers.WorldChangedEvent <> nil then
				fHandlers.WorldChangedEvent(WorldState);

			SetLength(WorldState, 0);
		end;
		CL_DISCONNECTED:
		begin
			SetLength(Reason, Length(APacket.Data));
			Move(Pointer(Pointer(APacket.Data)^), Pointer(Pointer(Reason)^), Length(APacket.Data));

			if @fHandlers.DisconnectedEvent <> nil then
				fHandlers.DisconnectedEvent(Reason);

			Reason:='';
		end;
	end;
end;
//------------------------------------------------------------------------------------
procedure CCommunicator.SV_BroadcastWorldState(WorldState: PlayerInfoList);
var
	i: LongInt;
	StringStream: TStringStream;
begin
	if fClients.Count = 0 then
		Exit;

	StringStream:=TStringStream.Create('');
	StringStream.WriteString('Rage'+Char(CL_WORLD_CHANGED));
	StringStream.WriteBuffer(Pointer(WorldState)^, Length(WorldState)*SizeOf(PlayerInfo));

	for i:=0 to fClients.Count-1 do
	begin
		fUdpConnector.Send
		(
			CClient(fClients[i]).fIP,
			CClient(fClients[i]).fPort,
			StringStream.DataString
		);
	end;
	SetLength(WorldState, 0);
	StringStream.Free;
end;
//------------------------------------------------------------------------------------
procedure CCommunicator.SV_DisconnectClient(APlayer: CPlayer; Reason: string);
var
	i:LongInt;
begin
	if APlayer = nil then
	begin
		for i:=0 to fClients.Count-1 do
		begin
			fUdpConnector.Send
			(
				CClient(fClients[i]).fIP,
				CClient(fClients[i]).fPort,
				'Rage'+Char(CL_DISCONNECTED)+Reason
			);
			fClients.Delete(i);
		end;
	end else
	begin
		for i:=0 to fClients.Count-1 do
		begin
			if CClient(fClients[i]).fPlayer = APlayer then
			begin
				fUdpConnector.Send
				(
					CClient(fClients[i]).fIP,
					CClient(fClients[i]).fPort,
					'Rage'+Char(CL_DISCONNECTED)+Reason
				);
				fClients.Delete(i);
				Break;
			end;
		end;
	end;
end;
//------------------------------------------------------------------------------------
procedure CCommunicator.CL_SendConnectionQuery(NickName: string);
begin
	fUdpConnector.Send(fServerIP, fServerPort, 'Rage'+Char(SV_CLIENT_CONNECTED)+Nickname);
end;
//------------------------------------------------------------------------------------
procedure CCommunicator.CL_SendKeyStateChanged(Keys: KeyState);
var
	StringStream: TStringStream;
begin
	StringStream:=TStringStream.Create('');
	StringStream.WriteString('Rage'+Char(SV_CLIENT_KEYS_CHANGED));
	StringStream.WriteBuffer(Keys, SizeOf(KeyState));

	fUdpConnector.Send(fServerIP, fServerPort, StringStream.DataString);
	
	StringStream.Free;
end;
//------------------------------------------------------------------------------------
procedure CCommunicator.CL_Disconnect;
begin
	fUdpConnector.Send(fServerIP, fServerPort, 'Rage'+Char(SV_CLIENT_DISCONNECTED));
end;
//====================================================================================
end.
