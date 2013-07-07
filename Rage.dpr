program Rage;

{$R 'resources\multimedia.res' 'resources\multimedia.rc'}

uses
	Forms,
	MainWindow in 'MainWindow.pas' {FMainWindow},
	World in 'World.pas',
	Controller in 'Controller.pas',
	XYPair in 'XYPair.pas',
	Player in 'Player.pas',
	Client in 'Client.pas',
	Physics in 'Physics.pas',
	Communicator in 'Communicator.pas',
	Painter in 'Painter.pas',
	View in 'View.pas',
  	dglOpenGL in 'dglOpenGL.pas';

{$R *.res}

begin
	Application.Initialize;
	Application.Title := 'Rage';
	Application.CreateForm(TFMainWindow, FMainWindow);
	Application.Run;
end.
