unit View;

interface

uses Windows, Painter, Player, ExtCtrls, Graphics, SysUtils;

type
//====================================================================================
	IWorldView = interface
		procedure Update(Entities:Players; DrawScore: Boolean);
	end;
//------------------------------------------------------------------------------------
	PainterType = (OpenGLPainter, SimplePainter);
//------------------------------------------------------------------------------------
	CGraphicWorldView = class(TInterfacedObject, IWorldView)
	private
		fPainter:IPainter;
		ScorePicture: TPicture;
	public
		constructor Create(WorkSurface:HWND; ChoosenPainter: PainterType = OpenGLPainter);
		destructor Destroy; override;

		procedure Update(Entities:Players; DrawScore: Boolean);
	end;
//------------------------------------------------------------------------------------
	{CStatisticWorldView = class(TInterfacedObject, IWorldView)
	private
		fPainter:IPainter;
	public
		constructor Create;
		procedure Update(Entities:Players);
	end;}
//====================================================================================
implementation
//====================================================================================
constructor CGraphicWorldView.Create(WorkSurface:HWND; ChoosenPainter: PainterType);
begin
	case ChoosenPainter of
		OpenGLPainter: fPainter:=COpenGLPainter.Create(WorkSurface);
		SimplePainter: fPainter:=CSimplePainter.Create(WorkSurface);
	end;

	ScorePicture:=TPicture.Create;
	ScorePicture.Bitmap.LoadFromResourceName(HInstance, 'SCORE');
end;
//------------------------------------------------------------------------------------
destructor CGraphicWorldView.Destroy;
begin
	fPainter:=nil;
	ScorePicture.Free;
end;
//------------------------------------------------------------------------------------
procedure CGraphicWorldView.Update(Entities:Players; DrawScore: Boolean);
var
	i:LongInt;
begin
	fPainter.BeginPaint;
	fPainter.DrawRect(0, 0, 640, 480);

	for i:=0 to Entities.Count-1 do
	begin
		if DrawScore then
		begin
			fPainter.Draw2DText(120+8, 91+8+i*40, IntToStr(i));
			fPainter.Draw2DText(410, 91+8+i*40, IntToStr(CPlayer(Entities[i]).fInfo.fKills));
			fPainter.Draw2DText(480, 91+8+i*40, IntToStr(CPlayer(Entities[i]).fInfo.fDeaths));
			fPainter.Draw2DText(160, 91+8+i*40, CPlayer(Entities[i]).fInfo.fNickname);
		end;

		fPainter.DrawCircle
		(
			CPlayer(Entities[i]).fPosition.iX,
			CPlayer(Entities[i]).fPosition.iY,
			CPlayer(Entities[i]).fInfo.fRadius,
			CPlayer(Entities[i]).fInfo.fColor
		);

		fPainter.DrawHPLine
		(
			CPlayer(Entities[i]).fPosition.iX,
			CPlayer(Entities[i]).fPosition.iY,
			CPlayer(Entities[i]).fInfo.fRadius,
			CPlayer(Entities[i]).fInfo.fHP
		);
	end;

	if DrawScore then
	begin
		ScorePicture.Bitmap.TransparentMode:=tmAuto;
		ScorePicture.Bitmap.TransparentColor:=$9d9d9d;
		ScorePicture.Bitmap.Transparent:=True;
		fPainter.Draw2DPicture(120, 40, ScorePicture.Graphic);
	end;

	fPainter.EndPaint;
end;
//====================================================================================
end.
