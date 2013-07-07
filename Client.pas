unit Client;

interface

uses Player, IdSocketHandle, Classes;

type
//====================================================================================
	CClient = class
	public
		fPlayer:CPlayer;
		fIP:string;
		fPort:Word;

		constructor Create(APlayer:CPlayer; IP:string; Port:Word);
	end;
//------------------------------------------------------------------------------------
	Clients = TList;//TList;
//====================================================================================
implementation
//====================================================================================
constructor CClient.Create(APlayer:CPlayer; IP:string; Port:Word);
begin
	fPlayer:=APlayer;
	fIP:=IP;
	fPort:=Port;
end;
//====================================================================================
end.
