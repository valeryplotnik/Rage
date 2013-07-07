unit Painter;

interface
uses Windows, SysUtils, Graphics, ExtCtrls, Classes, dglOpenGL;
type
//====================================================================================
	IPainter = interface
		procedure BeginPaint;
		procedure DrawCircle(X, Y, Radius: LongInt; Color: TColor);
		procedure DrawRect(X1, Y1, X2, Y2: LongInt);
		procedure DrawHPLine(X, Y, Radius, HP:LongInt);
		procedure Draw2DRectangle(X1, Y1, X2, Y2: LongInt);
		procedure Draw2DPicture(X, Y: LongInt; Pic: TGraphic);
		procedure Draw2DText(X, Y: LongInt; Text: string);
		procedure EndPaint;
	end;
//------------------------------------------------------------------------------------
	COpenGLPainter = class(TInterfacedObject, IPainter)
	private
		DC: HDC;
		RC: HGLRC;

		Plane, Sphere, Cylinder: GLuint;

		procedure InitDefaultObjects;
		procedure InitView;
		procedure InitSceneProperties;
		procedure InitLights;
		procedure InitMaterials;

		procedure DrawSphere(Radius: Extended; Lats, Longs:LongInt);
		procedure DrawCylinder(numMajor, numMinor: LongInt; height, radius: Extended);
	public
		constructor Create(WorkSurface: HWND);
		destructor Destroy; override;

		procedure BeginPaint;
		procedure DrawCircle(X, Y, Radius: LongInt; Color: TColor);
		procedure DrawRect(X1, Y1, X2, Y2: LongInt);
		procedure DrawHPLine(X, Y, Radius, HP:LongInt);
		procedure Draw2DRectangle(X1, Y1, X2, Y2: LongInt);
		procedure Draw2DPicture(X, Y: LongInt; Pic: TGraphic);
		procedure Draw2DText(X, Y: LongInt; Text: string);
		procedure EndPaint;
	end;
//------------------------------------------------------------------------------------
	CSimplePainter = class(TInterfacedObject, IPainter)
	private
		fCanvas: TCanvas;
		fBufferImage: TPicture;
	public
		constructor Create(WorkSurface: HWND);
		destructor Destroy; override;

		procedure BeginPaint;
		procedure DrawCircle(X, Y, Radius: LongInt; Color: TColor);
		procedure DrawRect(X1, Y1, X2, Y2: LongInt);
		procedure DrawHPLine(X, Y, Radius, HP:LongInt);
		procedure Draw2DRectangle(X1, Y1, X2, Y2: LongInt);
		procedure Draw2DPicture(X, Y: LongInt; Pic: TGraphic);
		procedure Draw2DText(X, Y: LongInt; Text: string);
		procedure EndPaint;
	end;
//====================================================================================
implementation
//====================================================================================
constructor COpenGLPainter.Create(WorkSurface:HWND);
begin
	DC:=GetDC(WorkSurface);
	RC:=CreateRenderingContext(DC, [opDoubleBuffered], 32, 24, 32, 0, 0, 0);
	ActivateRenderingContext(DC, RC);

	InitView;
	InitSceneProperties;
	InitLights;
	InitMaterials;
	InitDefaultObjects;
end;
//------------------------------------------------------------------------------------
destructor COpenGLPainter.Destroy;
begin
	DeactivateRenderingContext;
	wglDeleteContext(RC);
	ReleaseDC(0, DC);
end;
//------------------------------------------------------------------------------------
procedure COpenGLPainter.DrawCylinder(numMajor, numMinor: LongInt; height, radius: Extended);
var
	i, j: LongInt;
	majorStep, minorStep, a: Extended;
	z0, z1, x, y: GLfloat;
begin
	majorStep:=height/numMajor;
	minorStep:=2*Pi/numMinor;

	for i:=0 to numMajor do
	begin
		z0:=0.5*height-i*majorStep;
		z1:=z0-majorStep;

		glBegin(GL_TRIANGLE_STRIP);
		for j:=0 to numMinor do
		begin
			a:=j*minorStep;
			x:=radius*cos(a);
			y:=radius*sin(a);

			glNormal3f(x / radius, y / radius, 0.0);
			glVertex3f(x, y, z0);

			glNormal3f(x / radius, y / radius, 0.0);
			glVertex3f(x, y, z1);
		end;
		glEnd();
	end;
end;
//------------------------------------------------------------------------------------
procedure COpenGLPainter.DrawSphere(Radius: Extended; Lats, Longs:LongInt);
var
	i, j:LongInt;
	lat0, z0, zr0, lat1, z1, zr1, lng, x, y:Extended;
begin
	for i:=0 to lats do
	begin
		lat0:=PI*(-0.5 + (i-1)/lats);
		z0:=sin(lat0);
		zr0:=cos(lat0);

		lat1:=PI*(-0.5 + i/lats);
		z1:=sin(lat1);
		zr1:=cos(lat1);

		glBegin(GL_QUAD_STRIP);
		for j:=0 to longs do
		begin
			lng:=2*Pi * (j-1)/longs;
			x:=cos(lng);
			y:=sin(lng);

			glNormal3f(x*zr0*Radius, y*zr0*Radius, z0*Radius);
			glVertex3f(x*zr0*Radius, y*zr0*Radius, z0*Radius);
			
			glNormal3f(x*zr1*Radius, y*zr1*Radius, z1*Radius);
			glVertex3f(x*zr1*Radius, y*zr1*Radius, z1*Radius);
		end;
		glEnd();
	end;
end;
//------------------------------------------------------------------------------------
procedure COpenGLPainter.InitDefaultObjects;
var
	lists: GLuint;
begin
	lists:=glGenLists(3);
	Plane:=lists+0;
	glNewList(Plane, GL_COMPILE);
		glBegin(GL_POLYGON);
			glNormal3f(0.0, -1.0, 0.0);
			glVertex3f(0.0, 0.0, 0.0);
			glVertex3f(0.0, 0.0, 30.0);
			glVertex3f(640, 0.0, 30.0);
			glVertex3f(640, 0.0, 0.0);
		glEnd;

		glBegin(GL_POLYGON);
			glNormal3f(-1.0, 0.0, 0.0);
			glVertex3f(640, 0.0, 0.0);
			glVertex3f(640, 0.0, 30.0);
			glVertex3f(640, -480, 30.0);
			glVertex3f(640, -480, 0.0);
		glEnd;

		glBegin(GL_POLYGON);
			glNormal3f(0.0, 1.0, 0.0);
			glVertex3f(640, -480, 0.0);
			glVertex3f(640, -480, 30.0);
			glVertex3f(0.0, -480, 30.0);
			glVertex3f(0.0, -480, 0.0);
		glEnd;

		glBegin(GL_POLYGON);
			glNormal3f(1.0, 0.0, 0.0);
			glVertex3f(0.0, -480, 0.0);
			glVertex3f(0.0, -480, 30.0);
			glVertex3f(0.0, 0.0, 30.0);
			glVertex3f(0.0, 0.0, 0.0);
		glEnd;

		glBegin(GL_POLYGON);
			glNormal3f(0.0, 0.0, 1.0);
			glVertex3f(0.0, 0.0, 0.0);
			glVertex3f(640, 0.0, 0.0);
			glVertex3f(640, -480.0, 0.0);
			glVertex3f(0.0, -480.0, 0.0);
		glEnd;
	glEndList;

	Sphere:=lists+1;
	glNewList(Sphere, GL_COMPILE);
		DrawSphere(15, 50, 50);
	glEndList;

	Cylinder:=lists+2;
	glNewList(Cylinder, GL_COMPILE);
		DrawCylinder(30, 30, 5, 17);
	glEndList;
end;
//------------------------------------------------------------------------------------
procedure COpenGLPainter.InitView;
begin
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity;
	gluPerspective(45, 640/480, 1, 2800);
	glTranslatef(-320, 240, -630);
	glRotatef(30.5, 1.0, 1.0, 0.0);
end;
//------------------------------------------------------------------------------------
procedure COpenGLPainter.InitSceneProperties;
begin
	glEnable(GL_DEPTH_TEST);

	glEnable(GL_BLEND);
	glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glClearColor (0.0, 0.0, 0.0, 1.0);

	glEnable(GL_LINE_SMOOTH);
	glHint(GL_LINE_SMOOTH_HINT, GL_NICEST);
	glLineWidth(1.5);

	glEnable(GL_POINT_SMOOTH);
	glHint(GL_POINT_SMOOTH_HINT, GL_NICEST);
	glPointSize(1.5);
end;
//------------------------------------------------------------------------------------
procedure COpenGLPainter.InitLights;
const
	LightPosition:TGLArrayf4 = (320.0, -240.0, 120.0, 1.0);
	LightAmbient:TGLArrayf4 = (0.3, 0.3, 0.3, 1.0);
	LightDiffuse:TGLArrayf4 = (1.0, 1.0, 1.0, 1.0);
	LightSpecular:TGLArrayf4 = (0.6, 0.6, 0.6, 1.0);
begin
	glEnable(GL_LIGHTING);
	glShadeModel(GL_SMOOTH);

	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity;
	glLightfv(GL_LIGHT0, GL_POSITION, @LightPosition);
	glLightfv(GL_LIGHT0, GL_AMBIENT, @LightAmbient);
	glLightfv(GL_LIGHT0, GL_DIFFUSE, @LightDiffuse);
	glLightfv(GL_LIGHT0, GL_SPECULAR, @LightSpecular);
	glEnable(GL_LIGHT0);
end;
//------------------------------------------------------------------------------------
procedure COpenGLPainter.InitMaterials;
const
	mat_spec:TGLArrayf3 = (0.6,0.6,0.6);
	mat_amb:TGLArrayf3 = (0.2,0.2,0.2);
	mat_dif:TGLArrayf3 = (0.9,0.9,0.9);
begin
	glEnable(GL_COLOR_MATERIAL);
	//glColorMaterial(GL_FRONT_AND_BACK, GL_E);
	//glMaterialfv(GL_FRONT_AND_BACK,GL_AMBIENT,@mat_amb);
	//glMaterialfv(GL_FRONT_AND_BACK,GL_DIFFUSE,@mat_dif);
	//glMaterialfv(GL_FRONT_AND_BACK,GL_SPECULAR,@mat_spec);
	//glMaterialf(GL_FRONT_AND_BACK,GL_SHININESS,0.7*128);
end;
//------------------------------------------------------------------------------------
procedure COpenGLPainter.BeginPaint;
begin
	glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);
end;
//------------------------------------------------------------------------------------
procedure COpenGLPainter.DrawCircle(X, Y, Radius: LongInt; Color:TColor);
begin
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity;

	glTranslatef(x, -y, Radius);
	glColor4ub((ColorToRGB(Color) and $ff0000) shr 16, (ColorToRGB(Color) and $00ff00) shr 8, (ColorToRGB(Color) and $0000ff), 255);

	glCallList(Sphere);
end;
//------------------------------------------------------------------------------------
procedure COpenGLPainter.DrawHPLine(X, Y, Radius, HP:LongInt);

begin
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity;

	glColor3f(1-HP/100, HP/100, 0.0);

	glTranslatef(X, -Y, Radius);
	glRotatef(90, 1.0, 0.0, 0.0);

	glCallList(Cylinder);
end;
//------------------------------------------------------------------------------------
procedure COpenGLPainter.DrawRect(X1, Y1, X2, Y2:LongInt);
begin
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity;

	glColor4ub(90, 90, 90, 255);

	glCallList(Plane);
end;
//------------------------------------------------------------------------------------
procedure COpenGLPainter.Draw2DRectangle(X1, Y1, X2, Y2: LongInt);
begin

end;
//------------------------------------------------------------------------------------
procedure COpenGLPainter.Draw2DPicture(X, Y: LongInt; Pic: TGraphic);
begin

end;
//------------------------------------------------------------------------------------
procedure COpenGLPainter.Draw2DText(X, Y: LongInt; Text: string);
begin

end;
//------------------------------------------------------------------------------------
procedure COpenGLPainter.EndPaint;
begin
	SwapBuffers(wglGetCurrentDC);
end;
//====================================================================================
constructor CSimplePainter.Create(WorkSurface:HWND);
begin
	fCanvas:=TCanvas.Create;
	fCanvas.Handle:=GetDC(WorkSurface);

	fBufferImage:=TPicture.Create;
	fBufferImage.Bitmap.LoadFromResourceName(HInstance, 'BACKGROUND');
end;
//------------------------------------------------------------------------------------
destructor CSimplePainter.Destroy;
begin
	ReleaseDC(0, fCanvas.Handle);
	FreeAndNil(fCanvas);
	FreeAndNil(fBufferImage);

	inherited Destroy;
end;
//------------------------------------------------------------------------------------
procedure CSimplePainter.BeginPaint;
begin
	with fBufferImage.Bitmap.Canvas do
	begin
		Pen.Width:=1;
		Pen.Color:=clBlack;
		Brush.Color:=clWhite;
		Rectangle(0, 0, 640, 480);
	end;
end;
//------------------------------------------------------------------------------------
procedure CSimplePainter.DrawCircle(X, Y, Radius: LongInt; Color:TColor);
begin
	with fBufferImage.Bitmap.Canvas do
	begin
		Pen.Width:=1;
		Pen.Color:=clBlack;
		Brush.Color:=Color;
		Ellipse(X-Radius, Y-Radius, X+Radius, Y+Radius);
	end;
end;
//------------------------------------------------------------------------------------
procedure CSimplePainter.DrawRect(X1, Y1, X2, Y2:LongInt);
begin
	with fBufferImage.Bitmap.Canvas do
	begin
		Pen.Width:=1;
		Pen.Color:=clBlack;
		Brush.Color:=clWhite;
		Rectangle(X1, Y1, X2, Y2);
	end;
end;
//------------------------------------------------------------------------------------
procedure CSimplePainter.DrawHPLine(X, Y, Radius, HP:LongInt);
begin
	with fBufferImage.Bitmap.Canvas do
	begin
		Pen.Width:=1;
		Pen.Color:=clBlack;
		Brush.Color:=(Round(255-HP*2.55) or (Round(HP*2.55) shl 8));
		Rectangle(X-Round(Radius*HP*0.01), Y-2, X+Round(Radius*HP*0.01), Y+2);
	end;
end;
//------------------------------------------------------------------------------------
procedure CSimplePainter.Draw2DRectangle(X1, Y1, X2, Y2: LongInt);
begin
	fBufferImage.Bitmap.Canvas.Rectangle(X1, Y1, X2, Y2);
end;
//------------------------------------------------------------------------------------
procedure CSimplePainter.Draw2DPicture(X, Y: LongInt; Pic: TGraphic);
begin
	fBufferImage.Bitmap.Canvas.Draw(X, Y, Pic);
end;
//------------------------------------------------------------------------------------
procedure CSimplePainter.Draw2DText(X, Y: LongInt; Text: string);
begin
	with fBufferImage.Bitmap.Canvas do
	begin
		Pen.Color:=$aa0016;
		Font.Color:=$aa0016;
		Brush.Color:=clWhite;
		Font.Height:=30;
		Font.Style:=[fsBold];
		Font.Name:='Impact';
		TextOut(X, Y, Text);
	end;
end;
//------------------------------------------------------------------------------------
procedure CSimplePainter.EndPaint;
begin
	fCanvas.Draw(0, 0, fBufferImage.Graphic);
end;
//====================================================================================
end.
