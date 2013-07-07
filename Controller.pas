unit Controller;

interface

uses Classes, Controls;

type
//====================================================================================
	IController = interface
		procedure KeyDown(var Key: Word; Shift: TShiftState);
		procedure KeyPress(var Key: Char);
		procedure KeyUp(var Key: Word; Shift: TShiftState);
		procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
		procedure MouseMove(Shift: TShiftState; X, Y: Integer);
		procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
	end;
//====================================================================================
implementation
end.
