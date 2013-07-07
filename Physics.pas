unit Physics;

interface

uses MMSystem, Player, XYPair, Windows, SysUtils;

type
//====================================================================================
	Direction = (NOWHERE, UP, UP_RIGHT, RIGHT, DOWN_RIGHT, DOWN, DOWN_LEFT, LEFT, UP_LEFT);
//------------------------------------------------------------------------------------
	IPhysics = interface
		procedure ProcessFrame(Entities: Players);

		procedure SpawnPlayer(SpawnedEntities: Players; Entity: CPlayer);
		procedure RespawnPlayer(SpawnedEntities: Players; Entity: CPlayer);
		function CanSpawn(SpawnedEntities: Players; Entity: CPlayer): Boolean;
	end;
//------------------------------------------------------------------------------------
	CDefaultPhysics = class(TInterfacedObject, IPhysics)
	private
		fPrevTime, fTime: LongInt;

		function AddTo(Value, Delta, Dest: Extended): Extended;
		function ChangeInBorders(Value, Delta, Min, Max: Extended): Extended;
		function GetDirectionType(Entity: CPlayer): Direction;
		function GetPath(X1, Y1, X2, Y2: Extended): Extended;
		function GetProjection(Base, Vec: CVector): Extended;
		function ShouldCollide(ent1, ent2: CPlayer; dt: Extended): Boolean;
		procedure ProcessCollision(ent1, ent2: CPlayer);
		function CalculateDamage(force1, force2: Extended): Extended;
	public
		procedure ProcessFrame(Entities: Players);

		procedure SpawnPlayer(SpawnedEntities: Players; Entity: CPlayer);
		procedure RespawnPlayer(SpawnedEntities: Players; Entity: CPlayer);
		function CanSpawn(SpawnedEntities: Players; Entity: CPlayer): Boolean;
	end;
//====================================================================================
implementation
//====================================================================================
function CDefaultPhysics.AddTo(Value: Extended; Delta, Dest: Extended): Extended;
begin
	Delta:=Abs(Delta);
	if Value < Dest then
		if Value+Delta >= Dest then
			Result:=Dest
		else
			Result:=Value+Delta
	else
		if Value-Delta <= Dest then
			Result:=Dest
		else
			Result:=Value-Delta;
end;
//------------------------------------------------------------------------------------
function CDefaultPhysics.ChangeInBorders(Value: Extended; Delta, Min, Max: Extended): Extended;
begin
	if Delta > 0 then
	begin
		Result:=AddTo(Value, Delta, Max);
	end else
	if Delta < 0 then
	begin
		Result:=AddTo(Value, Delta, Min);
	end else
		Result:=Value;
end;
//------------------------------------------------------------------------------------
function CDefaultPhysics.GetDirectionType(Entity: CPlayer): Direction;
begin
	Result:=NOWHERE;

	if Entity.fKeys.left = True then
	begin
		if (Entity.fKeys.up = False) and (Entity.fKeys.down = False) then
			Result:=LEFT
		else
		if Entity.fKeys.up = True then
			Result:= UP_LEFT
		else
		if Entity.fKeys.down = True then
			Result:=DOWN_LEFT;
	end	else
	if Entity.fKeys.right = True then
	begin
		if (Entity.fKeys.up = False) and (Entity.fKeys.down = False) then
			Result:=RIGHT
		else
		if Entity.fKeys.up = True then
			Result:=UP_RIGHT
		else
		if Entity.fKeys.down = True then
			Result:=DOWN_RIGHT
	end	else
	if (Entity.fKeys.left = False) and (Entity.fKeys.right = False) then
	begin
		if Entity.fKeys.up = True then
			Result:=UP
		else
		if Entity.fKeys.down = True then
			Result:=DOWN;
	end;
end;
//------------------------------------------------------------------------------------
function CDefaultPhysics.GetPath(X1, Y1, X2, Y2: Extended): Extended;
begin
	Result:=Sqrt(Sqr(X1-X2)+Sqr(Y1-Y2));
end;
//------------------------------------------------------------------------------------
function CDefaultPhysics.GetProjection(Base, Vec: CVector): Extended;
begin
	Result:=0;
	if Base.Abs <> 0 then
		Result:=(Base.X*Vec.X+Base.Y*Vec.Y)/Base.Abs;
end;
//------------------------------------------------------------------------------------
function CDefaultPhysics.ShouldCollide(ent1, ent2: CPlayer; dt: Extended): Boolean;
var
	Distanse: Extended;
begin
	Result:=False;

	Distanse:=GetPath
	(
		ChangeInBorders(ent1.fPosition.X, ent1.fSpeed.X*dt, ent1.fInfo.fRadius, 640-ent1.fInfo.fRadius),
		ChangeInBorders(ent1.fPosition.Y, ent1.fSpeed.Y*dt, ent1.fInfo.fRadius, 480-ent1.fInfo.fRadius),
		ChangeInBorders(ent2.fPosition.X, ent2.fSpeed.X*dt, ent2.fInfo.fRadius, 640-ent2.fInfo.fRadius),
		ChangeInBorders(ent2.fPosition.Y, ent2.fSpeed.Y*dt, ent2.fInfo.fRadius, 480-ent2.fInfo.fRadius)
	);
	
	if (Distanse < ent1.fInfo.fRadius+ent2.fInfo.fRadius) then
		Result:=True;
end;
//------------------------------------------------------------------------------------
procedure CDefaultPhysics.SpawnPlayer(SpawnedEntities: Players; Entity: CPlayer);
begin
	repeat
		Randomize;
		Entity.fPosition.X:=15+Random(640-30);
		Entity.fPosition.Y:=15+Random(480-30);
	until CanSpawn(SpawnedEntities, Entity);
	Entity.fInfo.fHP:=100;
	SpawnedEntities.Add(Entity);
end;
//------------------------------------------------------------------------------------
procedure CDefaultPhysics.RespawnPlayer(SpawnedEntities: Players; Entity: CPlayer);
begin
	repeat
		Randomize;
		Entity.fPosition.X:=15+Random(640-30);
		Entity.fPosition.Y:=15+Random(480-30);
	until CanSpawn(SpawnedEntities, Entity);
	Entity.fInfo.fHP:=100;
	Entity.fSpeed.X:=0;
	Entity.fSpeed.Y:=0;
end;
//------------------------------------------------------------------------------------
function CDefaultPhysics.CanSpawn(SpawnedEntities: Players; Entity: CPlayer): Boolean;
var
	i: LongInt;
	Distance: Extended;
begin
	Result:=True;

	for i:=0 to SpawnedEntities.Count-1 do
	begin
		if CPlayer(SpawnedEntities[i]) <> Entity then
		begin
			Distance:=GetPath
			(
				CPlayer(SpawnedEntities[i]).fPosition.X,
				CPlayer(SpawnedEntities[i]).fPosition.Y,
				Entity.fPosition.X,
				Entity.fPosition.Y
			);

			if Distance < CPlayer(SpawnedEntities[i]).fInfo.fRadius+Entity.fInfo.fRadius then
				Result:=False;
		end;
	end;
end;
//------------------------------------------------------------------------------------
procedure CDefaultPhysics.ProcessCollision(ent1, ent2: CPlayer);
var
	damage1, damage2: LongInt;
	Normal, NewSpeed1, NewSpeed2: CVector;
	Substraction: Extended;
begin
	Normal:=CVector.Create;
	Normal.X:=ent1.fPosition.X-ent2.fPosition.X;
	Normal.Y:=ent1.fPosition.Y-ent2.fPosition.Y;
	if Normal.Abs <> 0 then
	begin
		NewSpeed1:=CVector.Create;
		NewSpeed2:=CVector.Create;

		Substraction:=GetProjection(Normal, ent1.fSpeed)-GetProjection(Normal, ent2.fSpeed);

		NewSpeed1.X:=ent1.fSpeed.X + Substraction*-Normal.X/Normal.Abs;
		NewSpeed1.Y:=ent1.fSpeed.Y + Substraction*-Normal.Y/Normal.Abs;

		NewSpeed2.X:=ent2.fSpeed.X + Substraction*Normal.X/Normal.Abs;
		NewSpeed2.Y:=ent2.fSpeed.Y + Substraction*Normal.Y/Normal.Abs;

		ent1.fSpeed.X:=NewSpeed1.X;
		ent1.fSpeed.Y:=NewSpeed1.Y;

		ent2.fSpeed.X:=NewSpeed2.X;
		ent2.fSpeed.Y:=NewSpeed2.Y;

		NewSpeed1.Destroy;
		NewSpeed2.Destroy;

		damage1:=Round(CalculateDamage(Abs(GetProjection(Normal, ent1.fSpeed)), Abs(GetProjection(Normal, ent2.fSpeed))));
		damage2:=Round(CalculateDamage(Abs(GetProjection(Normal, ent2.fSpeed)), Abs(GetProjection(Normal, ent1.fSpeed))));

		ent1.fInfo.fHP:=Round(AddTo(ent1.fInfo.fHP, damage1, 0));
		ent2.fInfo.fHP:=Round(AddTo(ent2.fInfo.fHP, damage2, 0));
	end;
	Normal.Destroy;
end;
//------------------------------------------------------------------------------------
function CDefaultPhysics.CalculateDamage(force1, force2: Extended): Extended;
begin
	Result:=Abs(force1-force2)*force1*50;
end;
//------------------------------------------------------------------------------------
procedure CDefaultPhysics.ProcessFrame(Entities: Players);
var
	i, j: LongInt;
	NewX, NewY, dt: Extended;
const
	delta = 0.005; divider = 4;
	max = 1;
begin
	fPrevTime:=fTime;
	fTime:=GetCurrentTime;
	dt:=fTime-fPrevTime;

	for i:=0 to Entities.Count-1 do
	begin
		for j:=i+1 to Entities.Count-1 do
		begin
			if ShouldCollide(CPlayer(Entities[i]), CPlayer(Entities[j]), dt) then
			begin
				sndPlaySound('STRONGHIT', SND_NODEFAULT or SND_ASYNC or SND_RESOURCE);
				ProcessCollision(CPlayer(Entities[i]), CPlayer(Entities[j]));
				
				if CPlayer(Entities[i]).fInfo.fHP = 0 then
				begin
					RespawnPlayer(Entities, CPlayer(Entities[i]));
					Inc(CPlayer(Entities[i]).fInfo.fDeaths);
					Inc(CPlayer(Entities[j]).fInfo.fKills);
				end;

				if CPlayer(Entities[j]).fInfo.fHP = 0 then
				begin
					RespawnPlayer(Entities, CPlayer(Entities[j]));
					Inc(CPlayer(Entities[j]).fInfo.fDeaths);
					Inc(CPlayer(Entities[i]).fInfo.fKills);
				end;
			end;
		end;
		
		NewX:=ChangeInBorders
		(
			CPlayer(Entities[i]).fPosition.X,
			CPlayer(Entities[i]).fSpeed.X*dt,
			CPlayer(Entities[i]).fInfo.fRadius,
			640-CPlayer(Entities[i]).fInfo.fRadius
		);
		if (NewX = CPlayer(Entities[i]).fInfo.fRadius) or (NewX = 640-CPlayer(Entities[i]).fInfo.fRadius) then
			CPlayer(Entities[i]).fSpeed.X:=-CPlayer(Entities[i]).fSpeed.X/1.01;
		CPlayer(Entities[i]).fPosition.X:=NewX;

		NewY:=ChangeInBorders
		(
			CPlayer(Entities[i]).fPosition.Y,
			CPlayer(Entities[i]).fSpeed.Y*dt,
			CPlayer(Entities[i]).fInfo.fRadius,
			480-CPlayer(Entities[i]).fInfo.fRadius
		);
		if (NewY = CPlayer(Entities[i]).fInfo.fRadius) or (NewY = 480-CPlayer(Entities[i]).fInfo.fRadius) then
			CPlayer(Entities[i]).fSpeed.Y:=-CPlayer(Entities[i]).fSpeed.Y/1.01;
		CPlayer(Entities[i]).fPosition.Y:=NewY;
	end;

	for i:=0 to Entities.Count-1 do
	begin
		case GetDirectionType(Entities[i]) of
			NOWHERE:	begin
							CPlayer(Entities[i]).fSpeed.X:=AddTo(CPlayer(Entities[i]).fSpeed.X, dt*delta/divider, 0);
							CPlayer(Entities[i]).fSpeed.Y:=AddTo(CPlayer(Entities[i]).fSpeed.Y, dt*delta/divider, 0);
						end;
			UP: 		begin
							CPlayer(Entities[i]).fSpeed.X:=AddTo(CPlayer(Entities[i]).fSpeed.X, dt*delta/divider, 0);
							CPlayer(Entities[i]).fSpeed.Y:=AddTo(CPlayer(Entities[i]).fSpeed.Y, dt*delta, -max);
						end;
			UP_RIGHT:	begin
							CPlayer(Entities[i]).fSpeed.X:=AddTo(CPlayer(Entities[i]).fSpeed.X, dt*delta, max/sqrt(2));
							CPlayer(Entities[i]).fSpeed.Y:=AddTo(CPlayer(Entities[i]).fSpeed.Y, dt*delta, -max/sqrt(2));
						end;
			RIGHT:		begin
							CPlayer(Entities[i]).fSpeed.X:=AddTo(CPlayer(Entities[i]).fSpeed.X, dt*delta, max);
							CPlayer(Entities[i]).fSpeed.Y:=AddTo(CPlayer(Entities[i]).fSpeed.Y, dt*delta/divider, 0);
						end;
			DOWN_RIGHT: begin
							CPlayer(Entities[i]).fSpeed.X:=AddTo(CPlayer(Entities[i]).fSpeed.X, dt*delta, max/sqrt(2));
							CPlayer(Entities[i]).fSpeed.Y:=AddTo(CPlayer(Entities[i]).fSpeed.Y, dt*delta, max/sqrt(2));
						end;
			DOWN: 		begin
							CPlayer(Entities[i]).fSpeed.X:=AddTo(CPlayer(Entities[i]).fSpeed.X, dt*delta/divider, 0);
							CPlayer(Entities[i]).fSpeed.Y:=AddTo(CPlayer(Entities[i]).fSpeed.Y, dt*delta, max);
						end;
			DOWN_LEFT: 	begin
							CPlayer(Entities[i]).fSpeed.X:=AddTo(CPlayer(Entities[i]).fSpeed.X, dt*delta, -max/sqrt(2));
							CPlayer(Entities[i]).fSpeed.Y:=AddTo(CPlayer(Entities[i]).fSpeed.Y, dt*delta, max/sqrt(2));
						end;
			LEFT: 		begin
							CPlayer(Entities[i]).fSpeed.X:=AddTo(CPlayer(Entities[i]).fSpeed.X, dt*delta, -max);
							CPlayer(Entities[i]).fSpeed.Y:=AddTo(CPlayer(Entities[i]).fSpeed.Y, dt*delta/divider, 0);
						end;
			UP_LEFT: 	begin
							CPlayer(Entities[i]).fSpeed.X:=AddTo(CPlayer(Entities[i]).fSpeed.X, dt*delta, -max/sqrt(2));
							CPlayer(Entities[i]).fSpeed.Y:=AddTo(CPlayer(Entities[i]).fSpeed.Y, dt*delta, -max/sqrt(2));
						end;
		end;
	end;
end;
//====================================================================================
end.

