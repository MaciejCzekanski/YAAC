//-----------------------------------------
// Maciej Czekañski
// maves90@gmail.com
//-----------------------------------------

unit Arkanoid;

interface

uses Math;

CONST
	SCREEN_WIDTH = 800;
	SCREEN_HEIGHT = 600;
	BOUND = 40;
	BRICK_WIDTH = 80;
	BRICK_HEIGHT = 20;
	PADDLE_WIDTH = 80;
	MAX_PADDLE_WIDTH = 120;
	MIN_PADDLE_WIDTH = 60;
	MAX_ELEMENT_COUNT = 100;
	LENGHTEN_SPEED = 75;
	
	//Game state
	GS_MENU = 2;
	GS_GAME = 3;
	GS_HIGHSCORES = 4;
	GS_CREDITS = 5;
	GS_GAMEOVER = 6;
	
	//Brick Type
	BT_NORMAL = 1;
	BT_ROCK = 2;
	BT_SOLID = 3;
	
	//Powerup Type
	PT_BALL = 1;
	PT_SPEED_UP = 2;
	PT_SLOW_DOWN = 3;
	PT_FIREBALL = 4;
	PT_LENGHTEN = 5;
	PT_SHORTEN = 6;
	PT_COUNT = 6;

//------------------------------------------------------------------------------------------------
// T Y P E S
//------------------------------------------------------------------------------------------------

TYPE
	// Struktura opisuj¹ca klocek/œcianê
	TBrick = object
		rect: TRectF;
		r, g, b: longint;
		alive: boolean;
		brickType: longint;
		hitsToBreak: longint;
		exploding: boolean;
		explosionStartTime: Real;
	end;
	

	
	// Struktura opisuj¹ca bonus
	TPowerup = object
		pos: TVector2;
		vel: TVector2;
		alive: boolean;
		powerupType: longint;
	end;



	// Struktura opisuj¹ca pi³kê
	TBall = object
		pos: TVector2;
		radius: Real;
		vel: TVector2;
		alive: boolean;
		fireball: boolean;
		hitCount: longint; // dla fireballa
	end;

	// Struktura opisuj¹ca paletkê
	TPaddle = object
		rect: TRectF;
		lenghtening: boolean;
		shortening: boolean;
	end;


operator =(a, b: TBrick): boolean;
operator =(a, b: TPowerup): boolean;
operator =(a, b: TBall): boolean;
operator =(a, b: TPaddle): boolean;
	
	
implementation

// :TODO:

operator =(a, b: TBrick): boolean;
begin
	result:= a.rect = b.rect;
end;
	
operator =(a, b: TPowerup): boolean;
begin
	result:= a.pos = b.pos;
end;

operator =(a, b: TBall): boolean;
begin
	result:= a.pos = b.pos;
end;

operator =(a, b: TPaddle): boolean;
begin
	result:= a.rect = b.rect;
end;


begin
end.