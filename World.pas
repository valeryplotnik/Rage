unit World;

interface

uses
	Windows, ExtCtrls, SysUtils, Graphics, Classes, Controller,
	Controls, IdUdpServer, IdSocketHandle,
	XYPair, Physics, Client, Player, Communicator, View;
type
//====================================================================================
	WorldType = (WorldClient, WorldServer);
//------------------------------------------------------------------------------------
	CWorld = class(TThread)
	private
		fPlayers, fSpawnedPlayers: Players;
		fPhysics: IPhysics;
		fView: IWorldView;
		fCommunicator: CCommunicator;

		fExited: Boolean;
		fKeysPressed: KeyState;
		fType: WorldType;

		function CreatePlayer: CPlayer;
		procedure DeletePlayer(Id: LongInt);

		procedure ProcessWorldFrame;
		procedure WorldChanged;

		procedure CL_WorldChangedEvent(WorldState: PlayerInfoList);
		procedure CL_DisconnectedEvent(Reason: string);

		function SV_ClientConnectedEvent(Nickname: string): CPlayer;
		procedure SV_ClientKeysChangedEvent(CurrentClient: CClient; Keys: KeyState);
		procedure SV_ClientDisconnectedEvent(CurrentClient: CClient);
	public
		WorldDestroyEvent: procedure(Reason: string) of object;

		constructor Create(WindowHandle: HWND; VideoMode: PainterType; Nickname: string; IP: string; Port: Word = 27015);
		destructor Destroy; override;

		procedure Execute; override;

		procedure LeftKeyDown;
		procedure LeftKeyUp;
		procedure UpKeyDown;
		procedure UpKeyUp;
		procedure RightKeyDown;
		procedure RightKeyUp;
		procedure DownKeyDown;
		procedure DownKeyUp;
		procedure TabKeyDown;
		procedure TabKeyUp;
	end;
//------------------------------------------------------------------------------------
	CWorldController = class(TInterfacedObject, IController)
	private
		fWorld:CWorld;
	public
		constructor Create(NewWorld:CWorld);

		procedure KeyDown(var Key: Word; Shift: TShiftState);
		procedure KeyPress(var Key: Char);
		procedure KeyUp(var Key: Word; Shift: TShiftState);
		procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
		procedure MouseMove(Shift: TShiftState; X, Y: Integer);
		procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
	end;
//====================================================================================
implementation
//====================================================================================
constructor CWorld.Create(WindowHandle: HWND; VideoMode: PainterType; Nickname: string; IP: string; Port: Word);
var
	id: LongInt;
	Handlers: PacketHandlers;
begin
	inherited Create(True);

	fPlayers:=Players.Create;
	fSpawnedPlayers:=Players.Create;
	
	fView:=CGraphicWorldView.Create(WindowHandle, VideoMode);
	fPhysics:=CDefaultPhysics.Create;

	if IP = '' then
	begin
		id:=fPlayers.Add(CPlayer.Create);
		fPhysics.SpawnPlayer(fSpawnedPlayers, CPlayer(fPlayers[id]));
		CPlayer(fPlayers[id]).fInfo.fNickname:=Nickname;

		Handlers.ClientConnectedEvent:=SV_ClientConnectedEvent;
		Handlers.ClientDisconnectedEvent:=SV_ClientDisconnectedEvent;
		Handlers.ClientKeysChangedEvent:=SV_ClientKeysChangedEvent;

		fType:=WorldServer;

		fCommunicator:=CCommunicator.Create(IP, Port, Handlers);
	end else
	begin
		Handlers.DisconnectedEvent:=CL_DisconnectedEvent;
		Handlers.WorldChangedEvent:=CL_WorldChangedEvent;

		fType:=WorldClient;

		fCommunicator:=CCommunicator.Create(IP, Port, Handlers);
		fCommunicator.CL_SendConnectionQuery(Nickname);
	end;

	Suspended:=False;
end;
//------------------------------------------------------------------------------------
destructor CWorld.Destroy;
begin
	fExited:=True;
	
	if fType = WorldClient then
		fCommunicator.CL_Disconnect
	else if fType = WorldServer then
		fCommunicator.SV_DisconnectClient(nil, 'Server is off.');

	FreeAndNil(fCommunicator);

	fPhysics:=nil;
	fView:=nil;

	FreeAndNil(fSpawnedPlayers);
	FreeAndNil(fPlayers);

	inherited Destroy;
end;
//------------------------------------------------------------------------------------
function CWorld.CreatePlayer: CPlayer;
begin
	Result:=fPlayers[fPlayers.Add(CPlayer.Create)];
end;
//------------------------------------------------------------------------------------
procedure CWorld.DeletePlayer(Id: LongInt);
begin
	if (Id >=0) and (Id <= fPlayers.Count-1) then
	begin
		fSpawnedPlayers.Extract(fPlayers[Id]);
		CPlayer(fPlayers.Extract(fPlayers[Id])).Free;
	end;
end;
//------------------------------------------------------------------------------------
procedure CWorld.CL_WorldChangedEvent(WorldState: PlayerInfoList);
var
	i: LongInt;
begin
	for i:=0 to Length(WorldState)-1 do
	begin
		if i > fPlayers.Count-1 then
		begin
			fPhysics.SpawnPlayer(fSpawnedPlayers, CreatePlayer);
		end;
		CPlayer(fPlayers[i]).fInfo:=WorldState[i];
		CPlayer(fPlayers[i]).fPosition.X:=WorldState[i].X;
		CPlayer(fPlayers[i]).fPosition.Y:=WorldState[i].Y;
	end;
end;
//------------------------------------------------------------------------------------
procedure CWorld.CL_DisconnectedEvent(Reason: string);
begin
	fExited:=True;
	if @WorldDestroyEvent <> nil then
		WorldDestroyEvent(Reason);
end;
//------------------------------------------------------------------------------------
function CWorld.SV_ClientConnectedEvent(Nickname: string): CPlayer;
var
	NewPlayer: CPlayer;
begin
	NewPlayer:=CreatePlayer;
	Randomize;
	NewPlayer.fInfo.fColor:=Random(MaxInt) and $A0A0A0;
	fPhysics.SpawnPlayer(fSpawnedPlayers, NewPlayer);
	NewPlayer.fInfo.fNickname:=Nickname;

	Result:=NewPlayer;
end;
//------------------------------------------------------------------------------------
procedure CWorld.SV_ClientKeysChangedEvent(CurrentClient: CClient; Keys: KeyState);
begin
	CurrentClient.fPlayer.fKeys:=Keys;
end;
//------------------------------------------------------------------------------------
procedure CWorld.SV_ClientDisconnectedEvent(CurrentClient: CClient);
begin
	DeletePlayer(fPlayers.IndexOf(CurrentClient.fPlayer));
end;
//------------------------------------------------------------------------------------
procedure CWorld.ProcessWorldFrame;
var
	i: LongInt;
	WorldState: PlayerInfoList;
begin
	if fType = WorldServer then
	begin
		fPhysics.ProcessFrame(fSpawnedPlayers);
		for i:=0 to fPlayers.Count-1 do
		begin
			SetLength(WorldState, Length(WorldState)+1);
			CPlayer(fPlayers[i]).fInfo.X:=CPlayer(fPlayers[i]).fPosition.X;
			CPlayer(fPlayers[i]).fInfo.Y:=CPlayer(fPlayers[i]).fPosition.Y;
			WorldState[Length(WorldState)-1]:=CPlayer(fPlayers[i]).fInfo;
		end;
		fCommunicator.SV_BroadcastWorldState(WorldState);
		SetLength(WorldState, 0);
	end;
	Synchronize(WorldChanged);
end;
//------------------------------------------------------------------------------------
procedure CWorld.WorldChanged;
begin
	fView.Update(fSpawnedPlayers, fKeysPressed.score);
end;
//------------------------------------------------------------------------------------
procedure CWorld.Execute;
begin
	fExited:=False;
	while not fExited do
	begin
		ProcessWorldFrame;
		Sleep(15);
	end;
end;
//------------------------------------------------------------------------------------
procedure CWorld.LeftKeyDown;
begin
	case fType of
		WorldServer: CPlayer(fPlayers[0]).fKeys.left:=True;
		WorldClient:
		begin
			fKeysPressed.left:=True;
			fCommunicator.CL_SendKeyStateChanged(fKeysPressed);
		end;
	end;
end;
//------------------------------------------------------------------------------------
procedure CWorld.LeftKeyUp;
begin
	case fType of
		WorldServer: CPlayer(fPlayers[0]).fKeys.left:=False;
		WorldClient:
		begin
			fKeysPressed.left:=False;
			fCommunicator.CL_SendKeyStateChanged(fKeysPressed);
		end;
	end;
end;
//------------------------------------------------------------------------------------
procedure CWorld.UpKeyDown;
begin
	case fType of
		WorldServer: CPlayer(fPlayers[0]).fKeys.up:=True;
		WorldClient:
		begin
			fKeysPressed.up:=True;
			fCommunicator.CL_SendKeyStateChanged(fKeysPressed);
		end;
	end;
end;
//------------------------------------------------------------------------------------
procedure CWorld.UpKeyUp;
begin
	case fType of
		WorldServer: CPlayer(fPlayers[0]).fKeys.up:=False;
		WorldClient:
		begin
			fKeysPressed.up:=False;
			fCommunicator.CL_SendKeyStateChanged(fKeysPressed);
		end;
	end;
end;
//------------------------------------------------------------------------------------
procedure CWorld.RightKeyDown;
begin
	case fType of
		WorldServer: CPlayer(fPlayers[0]).fKeys.right:=True;
		WorldClient:
		begin
			fKeysPressed.right:=True;
			fCommunicator.CL_SendKeyStateChanged(fKeysPressed);
		end;
	end;
end;
//------------------------------------------------------------------------------------
procedure CWorld.RightKeyUp;
begin
	case fType of
		WorldServer: CPlayer(fPlayers[0]).fKeys.right:=False;
		WorldClient:
		begin
			fKeysPressed.right:=False;
			fCommunicator.CL_SendKeyStateChanged(fKeysPressed);
		end;
	end;
end;
//------------------------------------------------------------------------------------
procedure CWorld.DownKeyDown;
begin
	case fType of
		WorldServer: CPlayer(fPlayers[0]).fKeys.down:=True;
		WorldClient:
		begin
			fKeysPressed.down:=True;
			fCommunicator.CL_SendKeyStateChanged(fKeysPressed);
		end;
	end;
end;
//------------------------------------------------------------------------------------
procedure CWorld.DownKeyUp;
begin
	case fType of
		WorldServer: CPlayer(fPlayers[0]).fKeys.down:=False;
		WorldClient:
		begin
			fKeysPressed.down:=False;
			fCommunicator.CL_SendKeyStateChanged(fKeysPressed);
		end;
	end;
end;
//------------------------------------------------------------------------------------
procedure CWorld.TabKeyDown;
begin
	fKeysPressed.score:=True;
end;
//------------------------------------------------------------------------------------
procedure CWorld.TabKeyUp;
begin
	fKeysPressed.score:=False;
end;
//====================================================================================
//====================================================================================
constructor CWorldController.Create(NewWorld: CWorld);
begin
	fWorld:=NewWorld;
end;
//------------------------------------------------------------------------------------
procedure CWorldController.KeyDown(var Key: Word; Shift: TShiftState);
begin
	case Key of
		65, VK_LEFT: fWorld.LeftKeyDown;
		87, VK_UP: fWorld.UpKeyDown;
		68, VK_RIGHT: fWorld.RightKeyDown;
		83, VK_DOWN: fWorld.DownKeyDown;
		81: fWorld.TabKeyDown;
	end;
end;
//------------------------------------------------------------------------------------
procedure CWorldController.KeyPress(var Key: Char);
begin

end;
//------------------------------------------------------------------------------------
procedure CWorldController.KeyUp(var Key: Word; Shift: TShiftState);
begin
	case Key of
		65, VK_LEFT: fWorld.LeftKeyUp;
		87, VK_UP: fWorld.UpKeyUp;
		68, VK_RIGHT: fWorld.RightKeyUp;
		83, VK_DOWN: fWorld.DownKeyUp;
		81: fWorld.TabKeyUp;
		VK_ESCAPE:
		begin
			if fWorld.fType = WorldClient then
				fWorld.fCommunicator.CL_Disconnect
			else if fWorld.fType = WorldServer then
				fWorld.fCommunicator.SV_DisconnectClient(nil, 'Server is off.');

			fWorld.CL_DisconnectedEvent('You are exited.');
		end;
	end;
end;
//------------------------------------------------------------------------------------
procedure CWorldController.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin

end;
//------------------------------------------------------------------------------------
procedure CWorldController.MouseMove(Shift: TShiftState; X, Y: Integer);
begin

end;
//------------------------------------------------------------------------------------
procedure CWorldController.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin

end;
//====================================================================================
end.
