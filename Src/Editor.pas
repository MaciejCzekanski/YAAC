//-----------------------------------------
// Maciej Czekañski
// maves90@gmail.com
//-----------------------------------------

program Game;

uses Arkanoid, Allegro, AlBlend, Math, Utility, sysutils;
	
TYPE
	TGame = object
	public
		
		function Init: boolean;
		procedure DeInit;
		
		function Start: boolean;
		function Draw: boolean;
		procedure UpdateTime;
		function Update: boolean;
	
	private
		procedure InitBounds;
		
		procedure AddBrick;
		procedure SaveLevel;
		
		mDeltaTime: Real;
		mFps: Real;
		mFrames: longint;
		mCurrentTime, mPrevTime, mLastFpsUpdateTime, mRunningTime: Real;
		
		mBuffer: AL_BITMAPptr;
		
		mGameRunning: boolean; // je¿eli false, to wy³¹czamy grê
		mFont: AL_FONTptr;
		
		//Gra
		
		function LoadBitmaps: boolean;
		procedure FreeBitmaps;
		
		mBrickBmp: AL_BITMAPptr;
		mBrickRock1Bmp, mBrickRock2Bmp, mBrickSolidBmp: AL_BITMAPptr;
		mBackgroundBmp: AL_BITMAPptr;

		brickX, brickY: longint;
		mMouseLeft, mMouseRight: boolean;
		
		mBounds: array[0..2, 0..1] of TVector2;
		mBricks: array[0..MAX_ELEMENT_COUNT] of TBrick;
		
		mBrickCount: longint;
		
		mColors: array[0..10] of longint;
		mColorNames: array[0..10] of string;
		mCurrentColor: longint;
		
		mTypes: array[0..2] of longint;
		mTypeNames: array[0..2] of string;
		mCurrentType: longint;
	end;

//------------------------------------------------------------------------------------------------	
// F U N C T I O N S
//------------------------------------------------------------------------------------------------

// Inicjalizuje edytor
function TGame.Init: boolean;
begin	
	
	if al_init = false then
	begin
		Log('Cant init Allegro!');
		result:= false;
		exit;
	end
	else
		Log('Allegro initialised.');
		
	
	al_set_color_depth(al_desktop_color_depth);
	if al_install_keyboard = false then
	begin
		Log('Cant init keyboard.');
		result:= false;
		exit;
	end
	else
		Log('Keyboard installed.');
	
	if al_install_mouse = -1 then
	begin
		Log('Cant init mouse.');
		result:= false;
		exit;
	end
	else
		Log('Mouse installed');
		
	
	al_set_window_title('Arkanoid');
	al_set_gfx_mode(AL_GFX_AUTODETECT_WINDOWED, SCREEN_WIDTH, SCREEN_HEIGHT, 0, 0);
	
	mBuffer:= al_create_bitmap(SCREEN_WIDTH, SCREEN_HEIGHT);
	
	mFont:= al_load_bitmap_font('font.pcx', nil, nil);
	if mFont = nil then begin
		Log('Cant load font.pcx from file.');
	end;
	
	LoadBitmaps;
	InitBounds;
	
	mCurrentColor:= 0;
	mColors[0]:= al_makecol(255, 0, 0);
	mColorNames[0]:= 'Red';
	
	mColors[1]:= al_makecol(128, 0, 0);
	mColorNames[1]:= 'Maroon';
	
	mColors[2]:= al_makecol(0, 255, 0);
	mColorNames[2]:= 'Lime';
	
	mColors[3]:= al_makecol(0, 128, 0);
	mColorNames[3]:= 'Green';
	
	mColors[4]:= al_makecol(0, 0, 255);
	mColorNames[4]:= 'Blue';
	
	mColors[5]:= al_makecol(0, 0, 128);
	mColorNames[5]:= 'Navy';
	
	mColors[6]:= al_makecol(127, 127, 127);
	mColorNames[6]:= 'Grey';
	
	mColors[7]:= al_makecol(255, 0, 255);
	mColorNames[7]:= 'Pink';
	
	mColors[8]:= al_makecol(0, 255, 255);
	mColorNames[8]:= 'Cyan';
	
	mColors[9]:= al_makecol(255, 255, 0);
	mColorNames[9]:= 'Yellow';
	
	mColors[10]:= al_makecol(255, 127, 0);
	mColorNames[10]:= 'Orange';
	

	
	mCurrentType:= 0;
	mTypes[0]:= BT_NORMAL;
	mTypeNames[0]:= 'Normal';
	
	mTypes[1]:= BT_ROCK;
	mTypeNames[1]:= 'Rock';
	
	mTypes[2]:= BT_SOLID;
	mTypeNames[2]:= 'Solid';
	
end;

// Wczytuje wsyzstkie bitmapy z plików.
function TGame.LoadBitmaps: boolean;
begin
	
	mBrickBmp:= al_load_bitmap('gfx/brick.tga', nil);
	if mBrickBmp = nil then begin
		Log('Cant load brick.tga from file.');
	end;
	
	mBrickRock1Bmp:= al_load_bitmap('gfx/brick_rock1.tga', nil);
	if mBrickRock1Bmp = nil then begin
		Log('Cant load brick_rock1.tga from file.');
	end;
	
	mBrickRock2Bmp:= al_load_bitmap('gfx/brick_rock2.tga', nil);
	if mBrickRock2Bmp = nil then begin
		Log('Cant load brick_rock2.tga from file.');
	end;
	
	mBrickSolidBmp:= al_load_bitmap('gfx/brick_solid.tga', nil);
	if mBrickSolidBmp = nil then begin
		Log('Cant load brick_solid.tga from file.');
	end;
	
	mBackgroundBmp:= al_load_bitmap('gfx/background.tga', nil);
	if mBackgroundBmp = nil then begin
		Log('Cant load background.tga from file.');
	end;
	
	result:= true;
end;

// Zwalnia pamiêæ zajmowan¹ przez bitmapy.
procedure TGame.FreeBitmaps;
begin
		
if mBrickBmp <> nil then begin
		al_destroy_bitmap(mBrickBmp);
	end;
	
	if mBrickRock1Bmp <> nil then begin
		al_destroy_bitmap(mBrickRock1Bmp);
	end;
	
	if mBrickRock2Bmp <> nil then begin
		al_destroy_bitmap(mBrickRock2Bmp);
	end;
	
	if mBrickSolidBmp <> nil then begin
		al_destroy_bitmap(mBrickSolidBmp);
	end;	
	
	if mBackgroundBmp <> nil then begin
		al_destroy_bitmap(mBackgroundBmp);
	end;
	
end;

// Inicjalizuje granice planszy
procedure TGame.InitBounds;
begin
	mBounds[0,0].x := BOUND;
	mBounds[0,0].y := BOUND;
	mBounds[0,1].x := BOUND;
	mBounds[0,1].y := SCREEN_HEIGHT - BOUND;
	
	mBounds[1,0].x := SCREEN_WIDTH - BOUND;
	mBounds[1,0].y := BOUND;
	mBounds[1,1].x := SCREEN_WIDTH - BOUND;
	mBounds[1,1].y := SCREEN_HEIGHT - BOUND;
	
	mBounds[2,0].x := BOUND;
	mBounds[2,0].y := BOUND;
	mBounds[2,1].x := SCREEN_WIDTH - BOUND;
	mBounds[2,1].y := BOUND;
end;
//------------------------------------------------------------------------------------------------
// Zwalnia wszelkie zasoby
procedure TGame.DeInit;
begin
	if mFont <> nil then begin
		al_destroy_font(mFont);
		Log('Font destroyed');
	end;
	
	if mBuffer <> nil then begin
		al_destroy_bitmap(mBuffer);
		Log('Buffer destroyed');
	end;
	
	FreeBitmaps;
	
	al_exit;
end;
//------------------------------------------------------------------------------------------------

// Rozpoczyna g³ówn¹ pêtlê programu
function TGame.Start: boolean;
begin
	mGameRunning:= true;

	mPrevTime:= GetTime;
	mLastFpsUpdateTime:= GetTime;
	mFrames:= 0;
	
	while mGameRunning do
	begin
		UpdateTime;
		
		Update;
		Draw;
		Sleep(5);
	end;	
	
	result:= true;
end;
//------------------------------------------------------------------------------------------------

// Aktualizuje aktualny czas gry oraz licznik FPS
procedure TGame.UpdateTime;
begin
	mCurrentTime:= GetTime;
	mDeltaTime:= mCurrentTime - mPrevTime;
	mPrevTime:= mCurrentTime;
	
	mRunningTime := mRunningTime + mDeltaTime;
	
	Inc(mFrames);
	if mCurrentTime - mLastFpsUpdateTime > 1.0 then
	begin
		mFps := mFrames*(mCurrentTime - mLastFpsUpdateTime);
		mFrames:= 0;
		mLastFpsUpdateTime:= mCurrentTime;
	end;
end;
//------------------------------------------------------------------------------------------------

// Aktualizuje edytor
function TGame.Update: boolean;
var
	key: longint;
	rect: TRectF;
	collide: boolean;
	i: longint;
begin
	if al_keypressed then
		key:= al_readkey;
		
	if key shr 8 = AL_KEY_ESC then
		mGameRunning:= false;
			
	brickX:= al_mouse_x;
	brickY:= al_mouse_y;
	
	if brickX < BOUND then
		brickX:= BOUND;
	
	if brickX > SCREEN_WIDTH - BOUND - 80 then
		brickX:= SCREEN_WIDTH - BOUND - 80;
		
	if brickY < BOUND then
		brickY:= BOUND;
	
	// Wyrównanie pozycji klocka do siatki
	if al_key[AL_KEY_LCONTROL] <> 0 then begin
		brickX:= brickX - (brickX mod 40);
		brickY:= brickY - (brickY mod 20);
	end;
	
	// Zmiana koloru
	if key shr 8 = AL_KEY_1 then begin
		Inc(mCurrentColor);
		if mCurrentColor > high(mColors) then
			mCurrentColor:= 0;
	end;
	
	if key shr 8 = AL_KEY_Q then begin
		Dec(mCurrentColor);
		if mCurrentColor < 0 then
			mCurrentColor:= high(mColors);
	end;
	
	// Zmiana typu klocka
	if key shr 8 = AL_KEY_2 then begin
		Inc(mCurrentType);
		if mCurrentType > high(mTypes) then
			mCurrentType:= 0;
	end;
	
	if key shr 8 = AL_KEY_W then begin
		Dec(mCurrentType);
		if mCurrentType < 0 then
			mCurrentType:= high(mTypes);
	end;
	
	// Zapisanie planszy
	if key shr 8 = AL_KEY_ENTER then begin
		SaveLevel;
	end;
	
	// Sprawdzanie kolizji z pozosta³ymi klockami
	if ((al_mouse_b and 1) <> 0) and (not mMouseLeft) then begin
		mMouseLeft:= true;
		
		collide:= false;
		
		for i:= 0 to high(mBricks) do begin
			rect.x:= brickX;
			rect.y:= brickY;
			rect.width:= BRICK_WIDTH;
			rect.height:= BRICK_HEIGHT;
			
			if mBricks[i].alive and RectToRect(rect, mBricks[i].rect) then begin
				collide:= true;
				break;
			end;
		end;
		
		if not collide then
			AddBrick;
	end;
	if (al_mouse_b and 1) = 0 then
		mMouseLeft:= false;
	
	// Kasowanie klocka
	if ((al_mouse_b and 2) <> 0) and (not mMouseRight) then begin
		for i:= 0 to high(mBricks) do begin
			if mBricks[i].alive AND PointInRect(al_mouse_x, al_mouse_y, mBricks[i].rect) then begin
				mBricks[i].alive:= false;
				Dec(mBrickCount);
				WriteLn('Removed brick');
			end;
		end;
	end;
	if (al_mouse_b and 1) = 0 then
		mMouseRight:= false;
	
	result:= true;
end;

//------------------------------------------------------------------------------------------------
function TGame.Draw: boolean;
var
	i: longint;
begin
	al_clear_bitmap(mBuffer);
	
	al_draw_sprite(mBuffer, mBackgroundBmp, 0, 0);
	
	// Rysowanie klocków
	for i:= 0 to high(mBricks) do begin
		if (mBricks[i].alive = true) then begin
			with mBricks[i] do begin
				al_set_trans_blender(r, g, b, 255);
				
				if brickType = BT_NORMAL then
					al_draw_lit_sprite(mBuffer, mBrickBmp, Round(rect.x), Round(rect.y), 127)
				else if brickType = BT_ROCK then begin
					if hitsToBreak = 2 then
						al_draw_lit_sprite(mBuffer, mBrickRock1Bmp, Round(rect.x), Round(rect.y), 127)
					else
						al_draw_lit_sprite(mBuffer, mBrickRock2Bmp, Round(rect.x), Round(rect.y), 127);
				end
				else if brickType = BT_SOLID then
					al_draw_lit_sprite(mBuffer, mBrickSolidBmp, Round(rect.x), Round(rect.y), 127);
			end;
		end;
	end;
	
	al_set_trans_blender(al_getr(mColors[mCurrentColor]), al_getg(mColors[mCurrentColor]), al_getb(mColors[mCurrentColor]), 255);
	if mTypes[mCurrentType] = BT_NORMAL then
		al_draw_lit_sprite(mBuffer, mBrickBmp, brickX, brickY, 127)
	else if mTypes[mCurrentType] = BT_ROCK then begin
		al_draw_lit_sprite(mBuffer, mBrickRock1Bmp, brickX, brickY, 127);
	end
	else if mTypes[mCurrentType] = BT_SOLID then
		al_draw_lit_sprite(mBuffer, mBrickSolidBmp, brickX, brickY, 127);
	
	al_textout_ex(mBuffer, mFont, 'Type: ' + mTypeNames[mCurrentType], 50, 10, al_makecol(255, 255, 255), -1);
	al_textout_ex(mBuffer, mFont, 'Color: ' + mColorNames[mCurrentColor], 250, 10, al_makecol(255, 255, 255), -1);	
	al_textout_ex(mbuffer, mFont, 'BrickCount: ' + IntToStr(mBrickCount), 450, 10, al_makecol(255, 255, 255), -1);
	
	al_textout_ex(mbuffer, al_font, 'Press 1/Q to change color, 2/W to change type. Enter - save map. ', 10, SCREEN_HEIGHT - 50, al_makecol(255, 255, 255), -1);
	
	al_blit(mBuffer, al_screen, 0, 0, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
	
	result:= true;
end;
//------------------------------------------------------------------------------------------------
// Dodanie nowego klocka na planszê
procedure TGame.AddBrick;
var
	i: longint;
begin
	for i:= 0 to high(mBricks) do begin
		if mBricks[i].alive = false then begin
			mBricks[i].alive:= true;
			mBricks[i].rect.x:= brickX;
			mBricks[i].rect.y:= brickY;
			mBricks[i].rect.width:= BRICK_WIDTH;
			mBricks[i].rect.height:= BRICK_HEIGHt;
			mBricks[i].r:= al_getr(mColors[mCurrentColor]);
			mBricks[i].g:= al_getg(mColors[mCurrentColor]);
			mBricks[i].b:= al_getb(mColors[mCurrentColor]);
			mBricks[i].brickType:= mTypes[mCurrentType];
			if mCurrentType = BT_NORMAL then
				mBricks[i].hitsToBreak:= 1
			else
				mBricks[i].hitsToBreak:= 2;
			
			Inc(mBrickCount);
			
			WriteLn('Added brick number ' + IntToStr(mBrickCount) + ' at (' + IntToStr(brickX) + ', ' + IntToStr(brickY) + ')');

			break;
		end;
	end;
	
end;

// Zapisuje obecn¹ mapê do pliku o nazwie %d.lvl w folderze Levels,
// gdzie %d oznacza numer planszy.
// Przyk³ad: przyjmijmy, ¿e folder Levels jest pusty. Zapisanie planszy
// utworzy w tym folderze plik 1.lvl. Zapisanie kolejnej utworzy plik 2.lvl itd
procedure TGame.SaveLevel;
var
	f: Text;
	i, level: longint;
begin
	level:= 0;
	{$i-}
	repeat
		Inc(level);
		Assign(f, 'levels/' + 
		IntToStr(level) + '.lvl');
		Reset(f);
		Close(f);
	until IOResult <> 0;
	{$i+}

	Rewrite(f);
	
	WriteLn(f, mBrickCount);
	WriteLn(f, Round(BRICK_WIDTH));
	WriteLn(f, Round(BRICK_HEIGHT));
	
	
	for i:= 0 to high(mBricks) do begin
		with mBricks[i] do begin
			if not alive then
				continue;
				
			WriteLn(f, Round(rect.x));
			WriteLn(f, Round(rect.y));

			WriteLn(f, al_makecol(r, g, b) );
			WriteLn(f, brickType);
		end;
	end;
	
	Close(f);
end;

VAR
	gGame: TGame;

//------------------------------------------------------------------------------------------------
// M A I N   P R O G R A M
//------------------------------------------------------------------------------------------------

BEGIN
	gGame.Init;
	gGame.Start;
	gGame.DeInit;
END.














