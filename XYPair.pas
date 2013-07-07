unit XYPair;

interface

type
//====================================================================================
	CXYPair = class
	protected
		fX, fY: Extended;

		function GetRoundX: LongInt;
		function GetRoundY: LongInt;

		function GetX: Extended;
		function GetY: Extended;
		procedure SetX(NewX: Extended);
		procedure SetY(NewY: Extended);
	public
		property iX: LongInt read GetRoundX;
		property iY: LongInt read GetRoundY;
		property X: Extended read GetX write SetX;
		property Y: Extended read GetY write SetY;
	end;
//------------------------------------------------------------------------------------
	CCoordinates = CXYPair;
	CVector = class(CXYPair)
	private
		function GetAbs: Extended;
	public
		property Abs: Extended read GetAbs;
		procedure ExtendTo(value: Extended);
	end;
//====================================================================================
implementation
//====================================================================================
function CXYPair.GetRoundX: LongInt;
begin
	Result:=Round(fX);
end;
//------------------------------------------------------------------------------------
function CXYPair.GetRoundY: LongInt;
begin
	Result:=Round(fY);
end;
//------------------------------------------------------------------------------------
function CXYPair.GetX: Extended;
begin
	Result:=fX;
end;
//------------------------------------------------------------------------------------
function CXYPair.GetY: Extended;
begin
	Result:=fY;
end;
//------------------------------------------------------------------------------------
procedure CXYPair.SetX(NewX: Extended);
begin
	fX:=NewX;
end;
//------------------------------------------------------------------------------------
procedure CXYPair.SetY(NewY: Extended);
begin
	fY:=NewY;
end;
//====================================================================================
function CVector.GetAbs: Extended;
begin
	Result:=Sqrt(Sqr(fX)+Sqr(fY));
end;
//------------------------------------------------------------------------------------
procedure CVector.ExtendTo(value: Extended);
begin
	if GetAbs <> 0 then
	begin
		fX:=fX*(value+GetAbs)/GetAbs;
		fY:=fY*(value+GetAbs)/GetAbs;
	end;
end;
//====================================================================================
end.
