unit Player;

interface

uses Classes, Graphics, XYPair, SysUtils;

type
//====================================================================================
	PlayerInfo = record
		X, Y: Extended;
		fRadius: LongInt;
		fColor: TColor;
		fNickname: string[128];

		fHP, fKills, fDeaths: LongInt;
	end;
//------------------------------------------------------------------------------------
	PlayerInfoList = array of PlayerInfo;
//------------------------------------------------------------------------------------
	KeyState = record
		left, right, up, down, score: Boolean;
	end;
//------------------------------------------------------------------------------------
	CPlayer = class
	public
		fInfo:PlayerInfo;
		fPosition:CCoordinates;
		fSpeed:CVector;

		fKeys:KeyState;
	
		constructor Create;
		destructor Destroy; override;
	end;
//------------------------------------------------------------------------------------
	Players = TList;//TList;
//====================================================================================
implementation
//====================================================================================
constructor CPlayer.Create;
begin
	fSpeed:=CVector.Create;
	fPosition:=CCoordinates.Create;
	fInfo.fColor:=clRed;
	fInfo.fRadius:=15;
	fInfo.fHP:=0;
	fInfo.fKills:=0;
	fInfo.fDeaths:=0;
end;
//------------------------------------------------------------------------------------
destructor CPlayer.Destroy;
begin
	FreeAndNil(fSpeed);
	FreeAndNil(fPosition);
end;
//====================================================================================
end.
