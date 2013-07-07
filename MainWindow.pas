unit MainWindow;

interface

uses
	Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
	Dialogs, MMSystem, Sockets, ExtCtrls, StdCtrls, World, Controller, View;
type
//====================================================================================
	Settings = record
		VideoMode: PainterType;
		Nickname: string[128];
	end;
//------------------------------------------------------------------------------------
	TFMainWindow = class(TForm)
		procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
		procedure FormKeyPress(Sender: TObject; var Key: Char);
		procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
		procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
		procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
		procedure FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

		procedure FormCreate(Sender: TObject);
		procedure FormDestroy(Sender: TObject);
		procedure FormPaint(Sender: TObject);
	private
		CurrentController: IController;

		procedure DrawBack;
		procedure DrawMainMenu(SelectedItem: LongInt);
		procedure DrawConnectMenu(SelectedItem: LongInt; IpTextField: string);
		procedure DrawMessage(MessageText: string);
		procedure DrawSettingsMenu(SelectedItem: LongInt; ChoosedSettings: Settings);

		procedure MainMenuItemSelected(SelectedItem: LongInt);
		procedure ConnectMenuItemSelected(SelectedItem: LongInt; IpTextField: string);
		procedure SettingsMenuItemSelected(SelectedItem: LongInt; var EditedSettings: Settings);

		procedure WorldDestroyed(Reason: string);
		procedure SwitchToMainMenu;
		procedure SwitchToConnectMenu;
		procedure SwitchToSettingsMenu;
	public
		procedure StartGame(Ip: string);
	end;
//------------------------------------------------------------------------------------
	CMainMenuController = class(TInterfacedObject, IController)
	private
		MainWindow: TFMainWindow;
		SelectedItem: LongInt;
	public
		constructor Create(NewMainWindow: TFMainWindow);

		procedure KeyDown(var Key: Word; Shift: TShiftState);
		procedure KeyPress(var Key: Char);
		procedure KeyUp(var Key: Word; Shift: TShiftState);
		procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
		procedure MouseMove(Shift: TShiftState; X, Y: Integer);
		procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
	end;
//------------------------------------------------------------------------------------
	CConnectMenuController = class(TInterfacedObject, IController)
	private
		MainWindow: TFMainWindow;
		IpTextField: string;
		SelectedItem: LongInt;
	public
		constructor Create(NewMainWindow: TFMainWindow; Ip: string);

		procedure KeyDown(var Key: Word; Shift: TShiftState);
		procedure KeyPress(var Key: Char);
		procedure KeyUp(var Key: Word; Shift: TShiftState);
		procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
		procedure MouseMove(Shift: TShiftState; X, Y: Integer);
		procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
	end;
//------------------------------------------------------------------------------------
	CMessageController = class(TInterfacedObject, IController)
	private
		MainWindow: TFMainWindow;
	public
		constructor Create(NewMainWindow: TFMainWindow);

		procedure KeyDown(var Key: Word; Shift: TShiftState);
		procedure KeyPress(var Key: Char);
		procedure KeyUp(var Key: Word; Shift: TShiftState);
		procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
		procedure MouseMove(Shift: TShiftState; X, Y: Integer);
		procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
	end;
//------------------------------------------------------------------------------------
	CSettingsMenuController = class(TInterfacedObject, IController)
	private
		MainWindow: TFMainWindow;
		EditedSettings: Settings;
		SelectedItem: LongInt;
	public
		constructor Create(NewMainWindow: TFMainWindow; NewSettings: Settings);

		procedure KeyDown(var Key: Word; Shift: TShiftState);
		procedure KeyPress(var Key: Char);
		procedure KeyUp(var Key: Word; Shift: TShiftState);
		procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
		procedure MouseMove(Shift: TShiftState; X, Y: Integer);
		procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
	end;
//====================================================================================
var
	FMainWindow: TFMainWindow;
	MainWorld: CWorld;
	CurrentSetttings: Settings;
	BackGroundPicture: TPicture;

implementation
{$R *.dfm}
//====================================================================================
procedure TFMainWindow.FormCreate(Sender: TObject);
begin
	BackGroundPicture:=TPicture.Create;
	BackGroundPicture.Bitmap.LoadFromResourceName(HInstance, 'BACKGROUND');

	CurrentController:=CMainMenuController.Create(Self);
end;
//------------------------------------------------------------------------------------
procedure TFMainWindow.FormDestroy(Sender: TObject);
begin
	CurrentController:=nil;
	FreeAndNil(BackGroundPicture);
	FreeAndNil(MainWorld);
end;
//------------------------------------------------------------------------------------
procedure TFMainWindow.FormPaint(Sender: TObject);
begin
	DrawMainMenu(0);
end;
//------------------------------------------------------------------------------------
procedure TFMainWindow.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
	CurrentController.KeyDown(Key, Shift);
end;
//------------------------------------------------------------------------------------
procedure TFMainWindow.FormKeyPress(Sender: TObject; var Key: Char);
begin
	CurrentController.KeyPress(Key);
end;
//------------------------------------------------------------------------------------
procedure TFMainWindow.FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
	CurrentController.KeyUp(Key, Shift);
end;
//------------------------------------------------------------------------------------
procedure TFMainWindow.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
	CurrentController.MouseDown(Button, Shift, X, Y);
end;
//------------------------------------------------------------------------------------
procedure TFMainWindow.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
	CurrentController.MouseMove(Shift, X, Y);
end;
//------------------------------------------------------------------------------------
procedure TFMainWindow.FormMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
	CurrentController.MouseUp(Button, Shift, X, Y);
end;
//------------------------------------------------------------------------------------
procedure TFMainWindow.StartGame(Ip: string);
begin
	MainWorld:=CWorld.Create(Self.Handle, CurrentSetttings.VideoMode, CurrentSetttings.Nickname, Ip);
	CurrentController:=CWorldController.Create(MainWorld);
	MainWorld.WorldDestroyEvent:=WorldDestroyed;
end;
//------------------------------------------------------------------------------------
procedure TFMainWindow.WorldDestroyed(Reason: string);
begin
	DrawMessage(Reason);
	CurrentController:=CMessageController.Create(Self);
	FreeAndNil(MainWorld);
end;
//------------------------------------------------------------------------------------
procedure TFMainWindow.SwitchToMainMenu;
begin
	DrawMainMenu(0);
	CurrentController:=CMainMenuController.Create(Self);
end;
//------------------------------------------------------------------------------------
procedure TFMainWindow.SwitchToConnectMenu;
begin
	DrawConnectMenu(0, '127.0.0.1');
	CurrentController:=CConnectMenuController.Create(Self, '127.0.0.1');
end;
//------------------------------------------------------------------------------------
procedure TFMainWindow.SwitchToSettingsMenu;
begin
	DrawSettingsMenu(0, CurrentSetttings);
	CurrentController:=CSettingsMenuController.Create(Self, CurrentSetttings);
end;
//------------------------------------------------------------------------------------
procedure TFMainWindow.DrawBack;
begin
	{var
	dX, dY, i: LongInt;
	dX:=8;
	dY:=2;
	with Canvas do
	begin
		Lock;
		Pen.Width:=1;
		Brush.Color:=clWhite;
		Pen.Color:=clWhite;
		Rectangle(0, 0, ClientWidth, ClientHeight);
		for i:=1 to 32 do begin

			Pen.Width:=1;
			Pen.Color:=clBlue or $AAAAAA;

			MoveTo(i*20, 0);
			LineTo(i*20, ClientHeight);

			MoveTo(0, i*20);
			LineTo(ClientWidth, i*20);
		end;

		Pen.Width:=5;
		Pen.Color:=clRed;
		Ellipse(dX*20, dY*20, (dX+4)*20, (dY+4)*20);
		MoveTo(dX*20, (dY+2)*20);
		LineTo(dX*20, (dY+6)*20);

		MoveTo(Round((dX+2)*20-2*20/sqrt(2)), Round((dY+2)*20+2*20/sqrt(2)));
		LineTo((dX+4)*20, (dY+6)*20);

		Pen.Color:=clBlue;
		Chord((dX+12)*20, (dY+2)*20, (dX+16)*20, (dY+6)*20, (dX+16)*20, (dY+4)*20, (dX+12)*20, (dY+4)*20);
		Arc((dX+12)*20, (dY+2)*20, (dX+16)*20, (dY+6)*20, (dX+12)*20, (dY+4)*20, Round((dX+14)*20+2*20/sqrt(2)), Round((dY+4)*20+2*20/sqrt(2)));

		Pen.Color:=clYellow;
		Ellipse((dX+8)*20, (dY+2)*20, (dX+12)*20, (dY+6)*20);
		MoveTo((dX+12)*20, (dY+4)*20);
		LineTo((dX+12)*20, (dY+6)*20);
		Arc((dX+8)*20, (dY+4)*20, (dX+12)*20, (dY+8)*20, Round((dX+10)*20-2*20/sqrt(2)), Round((dY+6)*20+2*20/sqrt(2)), (dX+12)*20, (dY+6)*20);

		Pen.Color:=clGreen;
		Ellipse((dX+4)*20, (dY+2)*20, (dX+8)*20, (dY+6)*20);
		MoveTo((dX+8)*20, (dY+2)*20);
		LineTo((dX+8)*20, (dY+6)*20);

		Unlock;
	end;}
	Canvas.Draw(0, 0, BackGroundPicture.Graphic);
end;
//------------------------------------------------------------------------------------
procedure TFMainWindow.DrawMainMenu(SelectedItem: LongInt);
var
	dX, dY, ItemHeight, ItemWidth: LongInt;
begin
	dX:=9;
	dY:=11;
	ItemHeight:=3;
	ItemWidth:=14;
	DrawBack;
	with Canvas do
	begin
		Pen.Width:=3;
		Brush.Color:=$bbbbbb;
		if SelectedItem = 0 then
		begin
			Font.Color:=$00aeff;
			Pen.Color:=$00aeff;
		end	else
		begin
			Pen.Color:=$aa0016;
			Font.Color:=$aa0016;
		end;

		Rectangle(dX*20, dY*20, (dX+ItemWidth)*20, (dY+ItemHeight)*20);
		Font.Height:=40;
		Font.Style:=[fsBold];
		Font.Name:='Impact';
		TextOut(dX*20+Round((ItemWidth*20-TextWidth('Создать игру'))/2), dY*20+10, 'Создать игру');

		if SelectedItem = 1 then
		begin
			Font.Color:=$00aeff;
			Pen.Color:=$00aeff;
		end	else
		begin
			Pen.Color:=$aa0016;
			Font.Color:=$aa0016;
		end;

		Rectangle(dX*20, (dY+4)*20, (dX+ItemWidth)*20, (dY+ItemHeight+4)*20);
		TextOut(dX*20+Round((ItemWidth*20-TextWidth('Присоединиться'))/2), (dY+4)*20+10, 'Присоединиться');

		if SelectedItem = 2 then
		begin
			Font.Color:=$00aeff;
			Pen.Color:=$00aeff;
		end	else
		begin
			Pen.Color:=$aa0016;
			Font.Color:=$aa0016;
		end;

		Rectangle(dX*20, (dY+8)*20, (dX+ItemWidth)*20, (dY+ItemHeight+8)*20);
		TextOut(dX*20+Round((ItemWidth*20-TextWidth('Настройки'))/2), (dY+8)*20+10, 'Настройки');


		if SelectedItem = 3 then
		begin
			Font.Color:=$00aeff;
			Pen.Color:=$00aeff;
		end	else
		begin
			Pen.Color:=$aa0016;
			Font.Color:=$aa0016;
		end;

		Rectangle((dX+19)*20, (dY+9)*20, (dX+22)*20, (dY+12)*20);
		Ellipse((dX+19)*20+10, (dY+9)*20+10, (dX+22)*20-10, (dY+12)*20-10);
		MoveTo((dX+20)*20+10, (dY+10)*20+5);
		LineTo((dX+20)*20+10, (dY+9)*20+5);
	end;
end;
//------------------------------------------------------------------------------------
procedure TFMainWindow.DrawConnectMenu(SelectedItem: LongInt; IpTextField: string);
var
	dX, dY, ItemHeight, ItemWidth: LongInt;
begin
	dX:=9;
	dY:=11;
	ItemHeight:=3;
	ItemWidth:=14;
	DrawBack;
	with Canvas do
	begin
		Pen.Width:=3;
		Pen.Color:=clBlue;
		Brush.Color:=$bbbbbb;

		Rectangle((dX-2)*20, dY*20, (dX+ItemWidth+2)*20, (dY+ItemHeight)*20);
		Font.Color:=clBlack;
		Font.Height:=20;
		Font.Style:=[fsBold];
		Font.Name:='Impact';
		TextOut((dX-2)*20+Round(((ItemWidth+4)*20-TextWidth(IpTextField))/2), (dY+1)*20, IpTextField);

		Font.Height:=40;

		if SelectedItem = 0 then
		begin
			Font.Color:=$00aeff;
			Pen.Color:=$00aeff;
		end	else
		begin
			Pen.Color:=$aa0016;
			Font.Color:=$aa0016;
		end;

		Rectangle(dX*20, (dY+4)*20, (dX+ItemWidth)*20, (dY+ItemHeight+4)*20);
		TextOut(dX*20+Round((ItemWidth*20-TextWidth('Присоединиться'))/2), (dY+4)*20+10, 'Присоединиться');

		if SelectedItem = 1 then
		begin
			Font.Color:=$00aeff;
			Pen.Color:=$00aeff;
		end	else
		begin
			Pen.Color:=$aa0016;
			Font.Color:=$aa0016;
		end;

		Rectangle(dX*20, (dY+8)*20, (dX+ItemWidth)*20, (dY+ItemHeight+8)*20);
		TextOut(dX*20+Round((ItemWidth*20-TextWidth('Назад'))/2), (dY+8)*20+10, 'Назад');
	end;
end;
//------------------------------------------------------------------------------------
procedure TFMainWindow.DrawSettingsMenu(SelectedItem: LongInt; ChoosedSettings: Settings);
var
	dX, dY, ItemHeight, ItemWidth: LongInt;
begin
	dX:=9;
	dY:=11;
	ItemHeight:=3;
	ItemWidth:=14;
	DrawBack;
	with Canvas do
	begin
		Pen.Width:=3;
		Pen.Color:=$aa0016;
		Brush.Color:=$bbbbbb;

		if SelectedItem = 0 then
		begin
			Font.Color:=$00aeff;
			Pen.Color:=$00aeff;
		end	else
		begin
			Pen.Color:=$aa0016;
			Font.Color:=$aa0016;
		end;

		Rectangle((dX-2)*20, dY*20, (dX+ItemWidth+2)*20, (dY+ItemHeight)*20);
		Font.Color:=clBlack;
		Font.Height:=25;
		Font.Style:=[fsBold];
		Font.Name:='Impact';
		TextOut((dX-2)*20+Round(((ItemWidth+4)*20-TextWidth(ChoosedSettings.Nickname))/2), (dY+1)*20-5, ChoosedSettings.Nickname);

		if SelectedItem = 1 then
		begin
			Font.Color:=$00aeff;
			Pen.Color:=$00aeff;
		end	else
		begin
			Pen.Color:=$aa0016;
			Font.Color:=$aa0016;
		end;

		Rectangle((dX-2)*20, (dY+4)*20, (dX+ItemWidth+2)*20, (dY+4+ItemHeight)*20);
		if ChoosedSettings.VideoMode = SimplePainter then
			TextOut((dX-2)*20+Round(((ItemWidth+4)*20-TextWidth('Software'))/2), (dY+5)*20-5, 'Software')
		else
			TextOut((dX-2)*20+Round(((ItemWidth+4)*20-TextWidth('OpenGL'))/2), (dY+5)*20-5, 'OpenGL');

		Font.Height:=40;

		if SelectedItem = 2 then
		begin
			Font.Color:=$00aeff;
			Pen.Color:=$00aeff;
		end	else
		begin
			Pen.Color:=$aa0016;
			Font.Color:=$aa0016;
		end;

		Rectangle((dX-8)*20, (dY+8)*20, (dX-8+ItemWidth)*20, (dY+ItemHeight+8)*20);
		TextOut((dX-8)*20+Round((ItemWidth*20-TextWidth('Применить'))/2), (dY+8)*20+10, 'Применить');

		if SelectedItem = 3 then
		begin
			Font.Color:=$00aeff;
			Pen.Color:=$00aeff;
		end	else
		begin
			Pen.Color:=$aa0016;
			Font.Color:=$aa0016;
		end;

		Rectangle((dX+8)*20, (dY+8)*20, (dX+8+ItemWidth)*20, (dY+ItemHeight+8)*20);
		TextOut((dX+8)*20+Round((ItemWidth*20-TextWidth('Назад'))/2), (dY+8)*20+10, 'Назад');
	end;
end;
//------------------------------------------------------------------------------------
procedure TFMainWindow.DrawMessage(MessageText: string);
var
	dX, dY, ItemHeight, ItemWidth: LongInt;
begin
	dX:=9;
	dY:=11;
	ItemHeight:=3;
	ItemWidth:=14;
	DrawBack;
	with Canvas do
	begin
		Pen.Width:=3;
		Pen.Color:=clBlue;
		Brush.Color:=$bbbbbb;

		Rectangle((dX-2)*20, (dY+2)*20, (dX+ItemWidth+2)*20, (dY+ItemHeight+2)*20);
		Font.Color:=clBlack;
		Font.Height:=20;
		Font.Style:=[fsBold];
		Font.Name:='Impact';
		TextOut((dX-2)*20+Round(((ItemWidth+4)*20-TextWidth(MessageText))/2), (dY+3)*20, MessageText);

		Font.Color:=$00aeff;
		Pen.Color:=$00aeff;

		Font.Height:=40;

		Rectangle(dX*20, (dY+7)*20, (dX+ItemWidth)*20, (dY+ItemHeight+7)*20);
		TextOut(dX*20+Round((ItemWidth*20-TextWidth('Назад'))/2), (dY+7)*20+10, 'Назад');
	end;
end;
//------------------------------------------------------------------------------------
procedure TFMainWindow.MainMenuItemSelected(SelectedItem: LongInt);
begin
	case SelectedItem of
		0: StartGame('');
		1: SwitchToConnectMenu;
		2: SwitchToSettingsMenu;
		3: Application.Terminate;
	end;
end;
//------------------------------------------------------------------------------------
procedure TFMainWindow.ConnectMenuItemSelected(SelectedItem: LongInt; IpTextField: string);
begin
	case SelectedItem of
		0: StartGame(IpTextField);
		1: SwitchToMainMenu;
	end;
end;
//------------------------------------------------------------------------------------
procedure TFMainWindow.SettingsMenuItemSelected(SelectedItem: LongInt; var EditedSettings: Settings);
begin
	case SelectedItem of
		1:
		begin
			if EditedSettings.VideoMode = OpenGLPainter then
				EditedSettings.VideoMode:=SimplePainter
			else
				EditedSettings.VideoMode:=OpenGLPainter;
			DrawSettingsMenu(SelectedItem, EditedSettings);
		end;
		2:
		begin
			CurrentSetttings:=EditedSettings;
			SwitchToMainMenu;
		end;
		3: SwitchToMainMenu;
	end;
end;
//====================================================================================
//====================================================================================
constructor CMainMenuController.Create(NewMainWindow: TFMainWindow);
begin
	MainWindow:=NewMainWindow;
	SelectedItem:=0;
end;
//------------------------------------------------------------------------------------
procedure CMainMenuController.KeyDown(var Key: Word; Shift: TShiftState);
begin
	case Key of
		VK_UP:
		begin
			if SelectedItem-1 >= 0 then
				SelectedItem:=SelectedItem-1;
			MainWindow.DrawMainMenu(SelectedItem);
		end;
		VK_DOWN:
		begin
			if SelectedItem+1 <= 3 then
				SelectedItem:=SelectedItem+1;
			MainWindow.DrawMainMenu(SelectedItem);
		end;
		VK_RETURN: MainWindow.MainMenuItemSelected(SelectedItem);
	end;
end;
//------------------------------------------------------------------------------------
procedure CMainMenuController.KeyPress(var Key: Char);
begin

end;
//------------------------------------------------------------------------------------
procedure CMainMenuController.KeyUp(var Key: Word; Shift: TShiftState);
begin

end;
//------------------------------------------------------------------------------------
procedure CMainMenuController.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin

end;
//------------------------------------------------------------------------------------
procedure CMainMenuController.MouseMove(Shift: TShiftState; X, Y: Integer);
var
	dX, dY, ItemHeight, ItemWidth: LongInt;
begin
	dX:=9;
	dY:=11;
	ItemHeight:=3;
	ItemWidth:=14;
	if (X >= dX*20) and (X <= (dX+ItemWidth)*20) then
	begin
		if (Y >= dY*20) and (Y <= (dY+ItemHeight)*20) and (SelectedItem <> 0) then
		begin
			SelectedItem:=0;
			MainWindow.DrawMainMenu(SelectedItem);
		end
		else if (Y >= (dY+4)*20) and (Y <= (dY+ItemHeight+4)*20) and (SelectedItem <> 1) then
		begin
			SelectedItem:=1;
			MainWindow.DrawMainMenu(SelectedItem);
		end
		else if (Y >= (dY+8)*20) and (Y <= (dY+ItemHeight+8)*20) and (SelectedItem <> 2) then
		begin
			SelectedItem:=2;
			MainWindow.DrawMainMenu(SelectedItem);
		end;
	end;

	if (X >= (dX+19)*20) and (X <= (dX+22)*20) and (Y >= (dY+9)*20) and (Y <= (dY+12)*20) and (SelectedItem <> 3) then
	begin
		SelectedItem:=3;
		MainWindow.DrawMainMenu(SelectedItem);
	end;
end;
//------------------------------------------------------------------------------------
procedure CMainMenuController.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
	dX, dY, ItemHeight, ItemWidth: LongInt;
begin
	dX:=9;
	dY:=11;
	ItemHeight:=3;
	ItemWidth:=14;
	if (X >= dX*20) and (X <= (dX+ItemWidth)*20) then
	begin
		if (Y >= dY*20) and (Y <= (dY+ItemHeight)*20) then
		begin
			sndPlaySound('MENUCLICK', SND_ASYNC or SND_RESOURCE or SND_NODEFAULT);
			MainWindow.MainMenuItemSelected(0);
		end
		else if (Y >= (dY+4)*20) and (Y <= (dY+ItemHeight+4)*20) then
		begin
			sndPlaySound('MENUCLICK', SND_ASYNC or SND_RESOURCE or SND_NODEFAULT);
			MainWindow.MainMenuItemSelected(1);
		end
		else if (Y >= (dY+8)*20) and (Y <= (dY+ItemHeight+8)*20) then
		begin
			sndPlaySound('MENUCLICK', SND_ASYNC or SND_RESOURCE or SND_NODEFAULT);
			MainWindow.MainMenuItemSelected(2);
		end;
	end;

	if (X >= (dX+19)*20) and (X <= (dX+22)*20) and (Y >= (dY+9)*20) and (Y <= (dY+12)*20) then
	begin
		sndPlaySound('MENUCLICK', SND_ASYNC or SND_RESOURCE or SND_NODEFAULT);
		MainWindow.MainMenuItemSelected(3);
	end;
end;
//====================================================================================
//====================================================================================
constructor CConnectMenuController.Create(NewMainWindow: TFMainWindow; Ip: string);
begin
	MainWindow:=NewMainWindow;
	SelectedItem:=0;
	IpTextField:=Ip;
end;
//------------------------------------------------------------------------------------
procedure CConnectMenuController.KeyDown(var Key: Word; Shift: TShiftState);
begin
	case Key of
		VK_BACK:
		begin
			SetLength(IpTextField, Length(IpTextField)-1);
			MainWindow.DrawBack;
			MainWindow.DrawConnectMenu(SelectedItem, IpTextField);
		end;
		VK_UP:
		begin
			if SelectedItem-1 >= 0 then
				SelectedItem:=SelectedItem-1;
			MainWindow.DrawConnectMenu(SelectedItem, IpTextField);
		end;
		VK_DOWN:
		begin
			if SelectedItem+1 <= 1 then
				SelectedItem:=SelectedItem+1;
			MainWindow.DrawConnectMenu(SelectedItem, IpTextField);
		end;
		VK_RETURN: MainWindow.ConnectMenuItemSelected(SelectedItem, IpTextField);
	end;
end;
//------------------------------------------------------------------------------------
procedure CConnectMenuController.KeyPress(var Key: Char);
begin
	case Key of
		'0'..'9','.':
		begin
			IpTextField:=IpTextField+Key;
			MainWindow.DrawConnectMenu(SelectedItem, IpTextField);
		end;
	end;
end;
//------------------------------------------------------------------------------------
procedure CConnectMenuController.KeyUp(var Key: Word; Shift: TShiftState);
begin

end;
//------------------------------------------------------------------------------------
procedure CConnectMenuController.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin

end;
//------------------------------------------------------------------------------------
procedure CConnectMenuController.MouseMove(Shift: TShiftState; X, Y: Integer);
var
	dX, dY, ItemHeight, ItemWidth: LongInt;
begin
	dX:=9;
	dY:=11;
	ItemHeight:=3;
	ItemWidth:=14;
	if (X >= dX*20) and (X <= (dX+ItemWidth)*20) then
	begin
		if (Y >= (dY+4)*20) and (Y <= (dY+ItemHeight+4)*20) and (SelectedItem <> 0) then
		begin
			SelectedItem:=0;
			MainWindow.DrawConnectMenu(SelectedItem, IpTextField);
		end
		else if (Y >= (dY+8)*20) and (Y <= (dY+ItemHeight+8)*20) and (SelectedItem <> 1) then
		begin
			SelectedItem:=1;
			MainWindow.DrawConnectMenu(SelectedItem, IpTextField);
		end;
	end;
end;
//------------------------------------------------------------------------------------
procedure CConnectMenuController.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
	dX, dY, ItemHeight, ItemWidth: LongInt;
begin
	dX:=9;
	dY:=11;
	ItemHeight:=3;
	ItemWidth:=14;
	if (X >= dX*20) and (X <= (dX+ItemWidth)*20) then
	begin
		if (Y >= (dY+4)*20) and (Y <= (dY+ItemHeight+4)*20) then
		begin
			sndPlaySound('MENUCLICK', SND_ASYNC or SND_RESOURCE or SND_NODEFAULT);
			MainWindow.ConnectMenuItemSelected(0, IpTextField);
		end
		else if (Y >= (dY+8)*20) and (Y <= (dY+ItemHeight+8)*20) then
		begin
			sndPlaySound('MENUCLICK', SND_ASYNC or SND_RESOURCE or SND_NODEFAULT);
			MainWindow.ConnectMenuItemSelected(1, IpTextField);
		end;
	end;
end;
//====================================================================================
//====================================================================================
constructor CMessageController.Create(NewMainWindow: TFMainWindow);
begin
	MainWindow:=NewMainWindow;
end;
//------------------------------------------------------------------------------------
procedure CMessageController.KeyDown(var Key: Word; Shift: TShiftState);
begin
	case Key of
		VK_RETURN: MainWindow.SwitchToMainMenu;
	end;
end;
//------------------------------------------------------------------------------------
procedure CMessageController.KeyPress(var Key: Char);
begin

end;
//------------------------------------------------------------------------------------
procedure CMessageController.KeyUp(var Key: Word; Shift: TShiftState);
begin

end;
//------------------------------------------------------------------------------------
procedure CMessageController.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin

end;
//------------------------------------------------------------------------------------
procedure CMessageController.MouseMove(Shift: TShiftState; X, Y: Integer);
begin

end;
//------------------------------------------------------------------------------------
procedure CMessageController.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
	dX, dY, ItemHeight, ItemWidth: LongInt;
begin
	dX:=9;
	dY:=11;
	ItemHeight:=3;
	ItemWidth:=14;
	if (X >= dX*20) and (X <= (dX+ItemWidth)*20) and (Y >= (dY+7)*20) and (Y <= (dY+ItemHeight+7)*20) then
	begin
		sndPlaySound('MENUCLICK', SND_ASYNC or SND_RESOURCE or SND_NODEFAULT);
		MainWindow.SwitchToMainMenu;
	end;
end;
//====================================================================================
//====================================================================================
constructor CSettingsMenuController.Create(NewMainWindow: TFMainWindow; NewSettings: Settings);
begin
	MainWindow:=NewMainWindow;
	SelectedItem:=0;
	EditedSettings:=NewSettings;
end;
//------------------------------------------------------------------------------------
procedure CSettingsMenuController.KeyDown(var Key: Word; Shift: TShiftState);
begin
	case Key of
		VK_BACK:
		begin
			if Length(EditedSettings.Nickname) <> 0 then
				SetLength(EditedSettings.Nickname, Length(EditedSettings.Nickname)-1);
			MainWindow.DrawSettingsMenu(SelectedItem, EditedSettings);
		end;
		VK_UP:
		begin
			if SelectedItem-1 >= 0 then
				SelectedItem:=SelectedItem-1;
			MainWindow.DrawSettingsMenu(SelectedItem, EditedSettings);
		end;
		VK_DOWN:
		begin
			if SelectedItem+1 <= 3 then
				SelectedItem:=SelectedItem+1;
			MainWindow.DrawSettingsMenu(SelectedItem, EditedSettings);
		end;
		VK_RETURN: MainWindow.SettingsMenuItemSelected(SelectedItem, EditedSettings);
	end;
end;
//------------------------------------------------------------------------------------
procedure CSettingsMenuController.KeyPress(var Key: Char);
begin
	case Key of
		'a'..'z','A'..'Z','0'..'9':
		begin
			EditedSettings.Nickname:=EditedSettings.Nickname+Key;
			MainWindow.DrawSettingsMenu(SelectedItem, EditedSettings);
		end;
	end;
end;
//------------------------------------------------------------------------------------
procedure CSettingsMenuController.KeyUp(var Key: Word; Shift: TShiftState);
begin

end;
//------------------------------------------------------------------------------------
procedure CSettingsMenuController.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin

end;
//------------------------------------------------------------------------------------
procedure CSettingsMenuController.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
	dX, dY, ItemHeight, ItemWidth: LongInt;
begin
	dX:=9;
	dY:=11;
	ItemHeight:=3;
	ItemWidth:=14;
	if (X >= (dX-2)*20) and (X <= (dX+2+ItemWidth)*20) then
	begin
		if (Y >= (dY+0)*20) and (Y <= (dY+ItemHeight+0)*20) then
		begin
			sndPlaySound('MENUCLICK', SND_ASYNC or SND_RESOURCE or SND_NODEFAULT);
			MainWindow.SettingsMenuItemSelected(SelectedItem, EditedSettings);
		end
		else if (Y >= (dY+4)*20) and (Y <= (dY+ItemHeight+4)*20) then
		begin
			sndPlaySound('MENUCLICK', SND_ASYNC or SND_RESOURCE or SND_NODEFAULT);
			MainWindow.SettingsMenuItemSelected(SelectedItem, EditedSettings);
		end;
	end;
	
	if (Y >= (dY+8)*20) and (Y <= (dY+ItemHeight+8)*20) then
	begin
		if (X >= (dX-7)*20) and (X <= (dX+ItemWidth-7)*20) then
		begin
			sndPlaySound('MENUCLICK', SND_ASYNC or SND_RESOURCE or SND_NODEFAULT);
			MainWindow.SettingsMenuItemSelected(SelectedItem, EditedSettings);
		end
		else if (X >= (dX+7)*20) and (X <= (dX+ItemWidth+7)*20) then
		begin
			sndPlaySound('MENUCLICK', SND_ASYNC or SND_RESOURCE or SND_NODEFAULT);
			MainWindow.SettingsMenuItemSelected(SelectedItem, EditedSettings);
		end;
	end;
end;
//------------------------------------------------------------------------------------
procedure CSettingsMenuController.MouseMove(Shift: TShiftState; X, Y: Integer);
var
	dX, dY, ItemHeight, ItemWidth: LongInt;
begin
	dX:=9;
	dY:=11;
	ItemHeight:=3;
	ItemWidth:=14;
	if (X >= (dX-2)*20) and (X <= (dX+2+ItemWidth)*20) then
	begin
		if (Y >= (dY+0)*20) and (Y <= (dY+ItemHeight+0)*20) and (SelectedItem <> 0) then
		begin
			SelectedItem:=0;
			MainWindow.DrawSettingsMenu(SelectedItem, EditedSettings);
		end
		else if (Y >= (dY+4)*20) and (Y <= (dY+ItemHeight+4)*20) and (SelectedItem <> 1) then
		begin
			SelectedItem:=1;
			MainWindow.DrawSettingsMenu(SelectedItem, EditedSettings);
		end;
	end;
	
	if (Y >= (dY+8)*20) and (Y <= (dY+ItemHeight+8)*20) then
	begin
		if (X >= (dX-7)*20) and (X <= (dX+ItemWidth-7)*20) and (SelectedItem <> 2) then
		begin
			SelectedItem:=2;
			MainWindow.DrawSettingsMenu(SelectedItem, EditedSettings);
		end
		else if (X >= (dX+7)*20) and (X <= (dX+ItemWidth+7)*20) and (SelectedItem <> 3) then
		begin
			SelectedItem:=3;
			MainWindow.DrawSettingsMenu(SelectedItem, EditedSettings);
		end;
	end;
end;
//====================================================================================
end.
