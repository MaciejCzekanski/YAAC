//-----------------------------------------
// Maciej Czekañski
// maves90@gmail.com
//-----------------------------------------

program Game;

uses Arkanoid, Allegro, AlBlend, AlFixed, Math, Utility, Sysutils, Windows;

const
	BALL_RADIUS = 8;	// œrednicaa pi³ki
	PADDLE_SPEED : TVector2 = (x:500; y:0);
	
	START_LIVES = 3;	// liczba ¿yæ
	
	MAX_HIGHSCORE_ENTRIES = 10;		// Liczba wpisów do highscore
	
	// szansa na bonus (1 = zawsze, 0 = nigdy)
	NORMAL_BRICK_POWERUP = 0.2;		// Bonus ze zwyk³ego klocka
	ROCK_BRICK_POWERUP = 0.66;		// Bonus z kamiennego klocka
	SPEED_UP_RATE = 1.4;			// Wspó³czynnik przyspieszenia pi³ki
	SLOW_DOWN_RATE = 0.75;			// Wspó³czynnik spowolnienia pi³ki
	POWERUP_SIZE = 16;				// Rozmiar obrazka z bonusem (w pikselach)
	
	FIREBALL_HIT_COUNT = 10;		// Liczba uderzeñ po których ognista kula zamienia siê w zwyk³¹
	
	EXPLOSION_TIME = 0.4;			// Czas animacji wybuchu
	EXPLOSION_SIZE = 40;			// Rozmiar obrazka wybuchu
	FIREBALL_SIZE = 16;				// Rozmiar obrazka ognistej kuli
	
	CERTYFICATE_SIZE = 150;			// Rozmiar obrazka certyfikatu
	
	MENU_TRANSPARENCY = 160;		// Wspó³czynnik przeŸroczystoœci menu
	HIGHSCORES_FILENAME = 'highscores.dat';	// Plik z najlepszymi wynikami
	
	MENU_ITEM_INC = 60;				// Wartoœæ o jakie oddalone s¹ kolejne pozycje w menu
	
	// Pozycje/wymiary niektórych elementów GUI
	
	TOP_TEXT_Y = 7;
	SCORE_POS_X = 50;
	LIVES_POS_X = 350;
	LEVEL_POS_X = 650;
	
	
	MENU_RECT_LEFT = 300;
	MENU_RECT_RIGHT = SCREEN_WIDTH - MENU_RECT_LEFT;
	MENU_RECT_TOP = 240;
	MENU_RECT_BOTTOM = 535;
	
	HIGHSCORES_RECT_LEFT = 100;
	HIGHSCORES_RECT_RIGHT = SCREEN_WIDTH - 100;
	HIGHSCORES_RECT_TOP = 200;
	HIGHSCORES_RECT_BOTTOM = 550;
	
	CREDITS_RECT_LEFT = 100;
	CREDITS_RECT_RIGHT = SCREEN_WIDTH - 100;
	CREDITS_RECT_TOP = 200;
	CREDITS_RECT_BOTTOM = 550;
	
var
	gGameRunning: boolean; // je¿eli false, to wy³¹czamy grê
	gHWND: HWND;
	
TYPE
	//Wpis w najlepszych wynikach
	THighscoreEntry = record
		score: longint;
		name: string[64];
	end;
	
	// Gra
	TGame = object
	public
		function Init: boolean;
		procedure DeInit;
		
		function Start: boolean;
		function Draw: boolean;
		procedure UpdateTime;
		function Update: boolean;
		
		procedure FadeIn(time: Real);
		procedure FadeOut(time: Real);
	
	private
		
		procedure InitGame(level: longint);
		procedure InitBounds;
		procedure HandleCollisions;
		mCurrentState: longint;
		
		procedure DrawMenu;
		procedure DrawGame;
		procedure DrawGameover;
		procedure DrawHighscores;
		procedure DrawCredits;
		
		procedure UpdateMenu;
		procedure UpdateGame;
		
		procedure AddScore(score: longint);
		procedure LoadHighscores;
		procedure SaveHighscores;
		
		mGfxMode: longint;
		
		mDeltaTime: Real;
		mFps: Real;
		mFrames: longint;
		mCurrentTime, mPrevTime, mLastFpsUpdateTime, mRunningTime: Real;
		
		mBuffer: AL_BITMAPptr;
		
		mFade: longint;
		mFading: boolean;
		mFadeStart, mFadeEnd: Real;
		
		mFont: AL_FONTptr;
		
		//Menu
		function InitMenu: boolean;
		mMenuBmp: AL_BITMAPptr;
		mMenuItems: array[0..4] of string;
		mCurrentMenuItem: longint;
		
		mKey: longint;
		
		//Gra
		
		function LoadBitmaps: boolean;
		procedure FreeBitmaps;
		function LoadSounds: boolean;
		procedure FreeSounds;
		function LoadLevel(filename: string): boolean;
		
		procedure AddPowerup(x, y: Real);
		
		mGamePaused: boolean;
		
		mShowFps: boolean;
		mPlayMusic: boolean;
		
		mLose: boolean;
		mScore: longint;
		mCurrentScore, mScoreSpeed: Real;
		mHighScores: array[1..MAX_HIGHSCORE_ENTRIES] of THighscoreEntry;
		mNewHighscore: boolean;
		mNewHighscoreId: longint;
		mName: string[64];
		mLives: longint;
		mLevel: longint;
		
		mLifeLoss: boolean;
		mLifeLossTime: Real;
		mWin: boolean;
		mWinTime: Real;
		mBrickCount, mBricksToBreak: longint;
		
		mPaddleSpeed: TVector2;

	// Bitmapy
		mPaddleBmp: AL_BITMAPptr;
		mBrickBmp: AL_BITMAPptr;
		mBrickRock1Bmp, mBrickRock2Bmp, mBrickSolidBmp: AL_BITMAPptr;
		mBallBmp: AL_BITMAPptr;
		mPowerupBmp: AL_BITMAPptr;
		mFireballBmp: AL_BITMAPptr;
		mTempBmp: AL_BITMAPptr;
		mBackgroundBmp: AL_BITMAPptr;
		mExplosionBmp: AL_BITMAPptr;
		mCertificateBmp: AL_BITMAPptr;
	
		mBounds: array[0..2] of TRectF;
		mBricks: array[0..MAX_ELEMENT_COUNT] of TBrick;
		mBalls: array[0..MAX_ELEMENT_COUNT] of TBall;
		mPowerups: array[0..MAX_ELEMENT_COUNT] of TPowerup;
		mBallsAlive: longint;
		mPaddle: TPaddle;
		
		// DŸwieki
		mHitMetalWav, mHitWoodWav, mPowerupWav, mWinWav, mMusicWav: AL_SAMPLEptr;
	end;

//------------------------------------------------------------------------------------------------	
// F U N C T I O N S
//------------------------------------------------------------------------------------------------

// Obs³uga przycisku zamkniêcia okna
procedure CloseButtonHandler; CDECL;
begin
  gGameRunning:= false;
end;

// Inicjalizuje menu gry
function TGame.InitMenu: boolean;
begin	
	mMenuItems[0]:= 'Wznow';
	mMenuItems[1]:= 'Nowa gra';
	mMenuItems[2]:= 'Najlepsze wyniki';
	mMenuItems[3]:= 'Autorzy';
	mMenuItems[4]:= 'Wyjscie';
	
	mCurrentMenuItem:= 1;
	
	result:= true;
end;
//------------------------------------------------------------------------------------------------

// Inicjalizuje tryb graficzny i wczytuje zasoby.
// Zwraca false w przypadku niepowodzenia.
function TGame.Init: boolean;
begin
	// Ukrycie okna konsoli
	SetConsoleTitle('YAAC');
	Sleep(2);
	ShowWindow( FindWindow( nil, 'YAAC'), SW_HIDE );
	
	
	Randomize;
	mFading:= false;
	mFade:= 1;
	
	mPlayMusic:= true;

	mGamePaused:= false;
	
	if al_init = false then begin
		Log('Can''t init Allegro!');
		result:= false;
		exit;
	end
	else
		Log('Allegro initialised.');
	
	al_set_color_depth(al_desktop_color_depth);
	if al_install_keyboard = false then begin
		Log('Can''t init keyboard.');
		result:= false;
		exit;
	end
	else
		Log('Keyboard installed.');
	
	if al_install_mouse = -1 then begin
		Log('Cant init mouse.');
		result:= false;
		exit;
	end
	else
		Log('Mouse installed');
		
	
	al_set_window_title('Yet Another Arkanoid Clone');
	al_set_close_button_callback(@CloseButtonHandler);
	
	if (ParamCount = 1) and (ParamStr(1) = '-f') then
		mGfxMode:= AL_GFX_AUTODETECT
	else
		mGfxMode:= AL_GFX_AUTODETECT_WINDOWED;
	
	if al_set_gfx_mode(mGfxMode, SCREEN_WIDTH, SCREEN_HEIGHT, 0, 0) = false then begin
		Log('Can''t set gfx mode: ' + al_error);
		result:= false;
		exit;
	end
	else
		Log('Gfx mode initialised');
	
	al_set_color_conversion(AL_COLORCONV_NONE);
	mBuffer:= al_create_bitmap_ex(32, SCREEN_WIDTH, SCREEN_HEIGHT);
	
	if al_install_sound(AL_DIGI_AUTODETECT, AL_MIDI_AUTODETECT) = false then
		Log('Can''t install sound: ' + al_error)
	else
		Log('Sfx mode initialised');

	mCurrentState:= GS_MENU;
	
	InitMenu;	
	LoadBitmaps;
	LoadSounds;
	LoadHighscores;
	
	InitBounds;
	
	// Ustawiamy uchwyt do okna
	gHWND:= GetForegroundWindow;
	
	al_set_display_switch_mode(AL_SWITCH_BACKGROUND);
	
	result:= true;
end;
//------------------------------------------------------------------------------------------------

// Inicjalizuje grê i wczytuje dany poziom
procedure TGame.InitGame(level: longint);
var
	i: longint;
begin
	mLose:= false;
	mWin:= false;
	mLevel:= level;
	
	if not LoadLevel('levels/' + IntToStr(level) + '.lvl') then begin
		Log('Can''t load next level. Setting GAMEOVER state.');
		mCurrentState:= GS_GAMEOVER;
		exit;
	end;
	
	mPaddle.rect.x:= SCREEN_WIDTH/2 - BRICK_WIDTH/2;
	mPaddle.rect.y:= SCREEN_HEIGHT - 50;
	mPaddle.rect.width:= BRICK_WIDTH;
	mPaddle.rect.height:= BRICK_HEIGHT;
	
	mPaddle.shortening:= false;
	mPaddle.lenghtening:= false;

	mBalls[0].pos.x:= SCREEN_WIDTH/2;
	mBalls[0].pos.y:= SCREEN_HEIGHT-100;
	mBalls[0].alive:= true;
	mBalls[0].vel.x:= Random(20)-10;
	mBalls[0].vel.y:= -100;
	mBalls[0].radius:= BALL_RADIUS;
	mBalls[0].fireball:= false;
	mBalls[0].hitCount:= 0;
	
	 mBallsAlive:= 1;
	 mLose:= false;
	 mLives:= START_LIVES;
	
	for i:= 1 to high(mBalls) do begin
		mBalls[i].alive:= false;
		mBalls[i].fireball:= false;
	end;
	
	for i:= 0 to high(mPowerups) do begin
		mPowerups[i].alive:= false;
	end;
end;
//------------------------------------------------------------------------------------------------

// Wczytuje wszystkie bitmapy z plików.
// Zwraca false w przypadku niepowodzenia.
function TGame.LoadBitmaps: boolean;
begin
	mMenuBmp:= al_load_bitmap('gfx/menu.tga', nil);
	if mMenuBmp = nil then begin
		Log('Cant load menu.tga from file');
	end;
	
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
	
	mBallBmp:= al_load_bitmap('gfx/ball.tga', nil);
	if mBallBmp = nil then begin
		Log('Cant load ball.tga from file.');
	end;
	
	mPowerupBmp:= al_load_bitmap('gfx/powerup.tga', nil);
	if mPowerupBmp = nil then begin
		Log('Cant load powerup.tga from file.');
	end;
		
	mFireballBmp:= al_load_bitmap('gfx/fireball.tga', nil);
	if mFireballBmp = nil then begin
		Log('Cant load fireball.tga from file.');
	end;
	
	mTempBmp:= al_create_bitmap_ex(32, 160, 40);
	if mTempBmp = nil then begin
		Log('Cant create tempBmp');
	end;
	al_clear_bitmap(mTempBmp);
	
	mBackgroundBmp:= al_load_bitmap('gfx/background.tga', nil);
	if mBackgroundBmp = nil then begin
		Log('Cant load background.tga from file.');
	end;
	
	mExplosionBmp:= al_load_bitmap('gfx/explosion.tga', nil);
	if mExplosionBmp = nil then begin
		Log('Cant load explosion.tga from file.');
	end;
	
	mPaddleBmp:= al_load_bitmap('gfx/paddle.tga', nil);
	if mBrickBmp = nil then begin
		Log('Cant load brick.tga from file.');
	end;
	
	mCertificateBmp := al_load_bitmap('gfx/certificate.tga', nil);
	if mCertificateBmp  = nil then begin
		Log('Cant load certificate.tga from file.');
	end;
	
	mFont:= al_load_bitmap_font('gfx/font.pcx', nil, nil);
	if mFont = nil then begin
		Log('Cant load font.pcx from file.');
	end;
	
	result:= true;
end;
//------------------------------------------------------------------------------------------------

// Zwalnia wszystkie bitmapy
procedure TGame.FreeBitmaps;
begin
		
	al_destroy_bitmap(mMenuBmp);
	al_destroy_bitmap(mBrickBmp);
	al_destroy_bitmap(mBrickRock1Bmp);
	al_destroy_bitmap(mBrickRock2Bmp);
	al_destroy_bitmap(mBrickSolidBmp);
	al_destroy_bitmap(mBallBmp);
	al_destroy_bitmap(mPowerupBmp);
	al_destroy_bitmap(mFireballBmp);
	al_destroy_bitmap(mTempBmp);
	al_destroy_bitmap(mBackgroundBmp);
	al_destroy_bitmap(mExplosionBmp);
	al_destroy_bitmap(mPaddleBmp);	
	al_destroy_bitmap(mCertificateBmp);
	al_destroy_font(mFont);
end;
//------------------------------------------------------------------------------------------------

// Wczytuje wszystkie dŸwiêki z plików
// Zwraca false w przypadku niepowodzenia.
function TGame.LoadSounds: boolean;
begin
	mHitMetalWav:= al_load_sample('sfx/hit_metal.wav');
	if mHitMetalWav = nil then
		Log('Cant load metal_hit.wav from file');
	
	mHitWoodWav:= al_load_sample('sfx/hit_wood.wav');
	if mHitWoodWav = nil then
		Log('Cant load wood_hit.wav from file');
		
	mPowerupWav:= al_load_sample('sfx/bonus.wav');
	if mPowerupWav = nil then
		Log('Cant load bonus.wav from file');
		
	mWinWav:= al_load_sample('sfx/win.wav');
	if mWinWav = nil then
		Log('Cant load win.wav from file');
		
	mMusicWav:= al_load_sample('sfx/music.wav');
	if mMusicWav = nil then
		Log('Cant load music.wav from file');
		
	result:= true;
end;
//------------------------------------------------------------------------------------------------

// Zwalnia wszystkie dŸwiêki
procedure TGame.FreeSounds;
begin
	al_destroy_sample(mHitMetalWav);
	al_destroy_sample(mHitWoodWav);	
	al_destroy_sample(mPowerupWav);
	al_destroy_sample(mWinWav);
	al_destroy_sample(mMusicWav);
end;
//------------------------------------------------------------------------------------------------

// Wczytuje dany poziom z pliku.
// Zwraca false w przypadku niepowodzenia.
function TGame.LoadLevel(filename: string): boolean;
var
	f: Text;
	i, brickToRead: longint;
	col: longint;	
	temp: longint;
begin
	if not FileExists(filename) then begin
		Log('Can''t load level "' + filename +' from file');
		result:= false;
		exit;
	end;
	
	Assign(f, filename);
	Reset(f);
	
	ReadLn(f, brickToRead);
	ReadLn(f, temp);
	ReadLn(f, temp);
	
	mBrickCount:= brickToRead;
	mBricksToBreak:= mBrickCount;
	
	// Wczytanie danych o wszystkich klockach
	for i:= 0 to brickToRead - 1 do begin
		mBricks[i].alive:= true;
		ReadLn(f, mBricks[i].rect.x);
		ReadLn(f, mBricks[i].rect.y);
		mBricks[i].rect.width:= BRICK_WIDTH;
		mBricks[i].rect.height:= BRICK_HEIGHT;
		
		ReadLn(f, col);
		mBricks[i].r:= al_getr(col);
		mBricks[i].g:= al_getg(col);
		mBricks[i].b:= al_getb(col);
		
		ReadLn(f, mBricks[i].brickType);
		
		if mBricks[i].brickType = BT_SOLID then
			Dec(mBricksToBreak)
		else if mBricks[i].brickType = BT_ROCK then
			mBricks[i].hitsToBreak:= 2
		else
			mBricks[i].hitsToBreak:= 1;
	end;
	
	for i:= mBrickCount to high(mBricks) do
		mBricks[i].alive:= false;
		
	Close(f);
	
	result:= true;
end;
//------------------------------------------------------------------------------------------------

// Inicjalizuje granice planszy
procedure TGame.InitBounds;
begin
	mBounds[0].x := 0;
	mBounds[0].y := 0;
	mBounds[0].width := BOUND;
	mBounds[0].height := SCREEN_HEIGHT;
	
	mBounds[1].x := SCREEN_WIDTH - BOUND;
	mBounds[1].y := 0;
	mBounds[1].width := BOUND;
	mBounds[1].height := SCREEN_HEIGHT;
	
	mBounds[2].x := 0;
	mBounds[2].y := 0;
	mBounds[2].width := SCREEN_WIDTH;
	mBounds[2].height := BOUND;
end;
//------------------------------------------------------------------------------------------------

// Zwalnia wszelkie zasoby
procedure TGame.DeInit;
begin
	if mBuffer <> nil then begin
		al_destroy_bitmap(mBuffer);
		Log('Buffer destroyed');
	end;
	
	FreeBitmaps;
	FreeSounds;
	
	al_exit;
end;
//------------------------------------------------------------------------------------------------

// Rozpoczyna grê
function TGame.Start: boolean;
begin
	gGameRunning:= true;

	mPrevTime:= GetTime;
	mLastFpsUpdateTime:= GetTime;
	mFrames:= 0;
	
	al_play_sample(mMusicWav, 200, 127, 1000, 1);
	
	// G³ówna, nieskoñczona pêtla
	
	while gGameRunning do
	begin
		UpdateTime;
		Update;
		Draw;
		Sleep(1); // Aby oddaæ trochê czasu procesora dla systemu
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

// Aktualizuje grê w zale¿noœci od danego stanu
function TGame.Update: boolean;
var
	c: char;
begin
	if al_keypressed then
		mKey:= al_readkey
	else
		mKey:= 0;
	
	if GetForegroundWindow() <> gHWND then begin
		if mCurrentState = GS_GAME then begin
			mGamePaused:= true;
			mCurrentMenuItem:= 0;
			mCurrentState:= GS_MENU;
		end;
	end;
		
	if mKey shr 8 = AL_KEY_F1 then
		mShowFPS:= not mShowFPS;
		
	if mKey shr 8 = AL_KEY_F2 then begin
		if mPlayMusic = false then
			al_play_sample(mMusicWav, 200, 127, 1000, 1)
		else
			al_stop_sample(mMusicWav);
			
		mPlayMusic:= not mPlayMusic;
	end;
		
	if mCurrentState = GS_MENU then
	begin
		UpdateMenu;
	end
	else if mCurrentState = GS_HIGHSCORES then
	begin
		if mKey shr 8 = AL_KEY_ESC then
			mCurrentState:= GS_MENU;
	end
	else if mCurrentState = GS_CREDITS then
	begin
		if mKey shr 8 = AL_KEY_ESC then
			mCurrentState:= GS_MENU;
	end
	else if (mCurrentState = GS_GAME) then begin
		if not mGamePaused then
			UpdateGame;
	end
	else if mCurrentState = GS_GAMEOVER then begin
	
		if mKey shr 8 = AL_KEY_ESC then
			mCurrentState:= GS_MENU;
		
		if mKey <> 0 then begin
			c:= Chr(mKey and 255);
				
			if ((mKey shr 8) = AL_KEY_BACKSPACE) then begin
				if Length(mName) > 0 then begin
					mName[Length(mName)]:= Chr(0);
					SetLength(mName, Length(mName)-1);
				end;
			end
			else if (mKey shr 8) = AL_KEY_ENTER then begin
				mHighscores[mNewHighscoreId].name:= mName;
				SaveHighscores;
				mCurrentState:= GS_HIGHSCORES;
				mCurrentMenuItem:= 1;
			end
			else if (Length(mName) < 32) and (not (Ord(c) < 32)) then begin
				SetLength(mName, Length(mName)+1);
				mName[Length(mName)]:= c;
			end
		end
	end;
	
	result:= true;
end;
//------------------------------------------------------------------------------------------------

// Aktualizuje menu
procedure TGame.UpdateMenu;
begin
	if mFade > 0 then
		FadeIn(1.0);
	
	if mKey shr 8 = AL_KEY_ESC then begin
		if mGamePaused then begin
			mCurrentState:= GS_GAME;
			mGamePaused:= false;
			Log('Game resumed');
		end
		else begin
			gGameRunning:= false;
		end;
	end;
	
	if mKey shr 8 = AL_KEY_DOWN then begin
		mCurrentMenuItem:= mCurrentMenuItem + 1;
		if mCurrentMenuItem > 4 then begin
			if mGamePaused then
				mCurrentMenuItem:= 0
			else
				mCurrentMenuItem:= 1;
		end;
	end;
	if mKey shr 8 = AL_KEY_UP then begin
		mCurrentMenuItem:= mCurrentMenuItem - 1;
		if mGamePaused then begin
			if mCurrentMenuItem < 0 then
				mCurrentMenuItem:= 4;
		end
		else begin // Gra trwa
			if mCurrentMenuItem < 1 then
				mCurrentMenuItem:= 4;
		end;
	end;
	
	if mKey shr 8 = AL_KEY_ENTER then begin // RESUME
		if mCurrentMenuItem = 0 then begin
			mCurrentState:= GS_GAME;
			mGamePaused:= false;
		end
		else if mCurrentMenuItem = 1 then begin  // NEW GAME
			mCurrentState:= GS_GAME;
			mGamePaused:= false;
			mScore:= 0;
			mCurrentScore:= 0;
			InitGame(1);
		end
		else if mCurrentMenuItem = 2 then begin  // OPTIONS
			mCurrentState:= GS_HIGHSCORES;
		end
		else if mCurrentMenuItem = 3 then begin // CREDITS
			mCurrentState:= GS_CREDITS;
		end
		else if mCurrentMenuItem = 4 then begin // EXIT
			mCurrentState:= GS_GAME;
			gGameRunning:= false;
		end
	end;
end;
//------------------------------------------------------------------------------------------------

// Obs³uga kolizji i zdarzeñ z nimi zwi¹zanych
procedure TGame.HandleCollisions;
	
	// Pomocnicza funkcja znajduj¹ca indeks pi³eczki o najmniejszej wspó³rzêdnej Y
	function FindLowestY: longint;
	var
		i: longint;
		yMin: Real = SCREEN_HEIGHT;
	begin
		result:= -1;
		for i:= 0 to high(mBalls) do begin
			if mBalls[i].alive and (mBalls[i].pos.y < yMin) then begin
				yMin:= mBalls[i].pos.y;
				result:= i;
			end;
		end;
	end;

var
	pushVec, left, right: TVector2;
	circlePos: TVector2;
	i, j: longint;
	yMinId: longint;
	collide: boolean = false;
begin
	// Sprawdzanie czy kulka nie wylecia³a poza planszê
	for i:= 0 to high(mBalls) do begin
		if mBalls[i].alive then begin
			if mBalls[i].pos.y > SCREEN_HEIGHT then begin
				// Strata ¿ycia
				if mBallsAlive = 1 then begin
					mBalls[i].vel.y:= -mBalls[i].vel.y;
					mLifeLoss:= true;
					mLifeLossTime:= mCurrentTime;
					mFading:= false;
					mFade:= 0;
					Dec(mLives);
					al_play_sample(mHitMetalWav, 255, 127, 1000, 0);
					
					// Przegrana gracza
					if mLives = 0 then begin
						mLose:= true;
						mCurrentState:= GS_GAMEOVER;
						mBalls[i].alive:= false;
						Dec(mBallsAlive);
						
						// Aktualizacja najlepszych wyników
						for j:= 1 to MAX_HIGHSCORE_ENTRIES do begin
							if mScore > mHighscores[j].score then begin
								mNewHighscore:= true;
								mNewHighscoreId:= j;
								break;
							end;
						end;
						
						if mNewHighscore = true then begin
							for j:= 0 to MAX_HIGHSCORE_ENTRIES - mNewHighscoreId do begin
								mHighscores[MAX_HIGHSCORE_ENTRIES - j]:= mHighscores[MAX_HIGHSCORE_ENTRIES - j - 1];
							end;
							
							mHighscores[mNewHighscoreId].score:= mScore;
							mHighscores[mNewHighscoreId].name:= '???';
						end;
						
					end;
				end
				else
				begin
					mBalls[i].alive:= false;
					Dec(mBallsAlive);
				end;
			end;
		end;
	end;
	
	// Kolizje kulki-œciany
	for i:= 0 to high(mBounds) do begin
		for j:= 0 to high(mBalls) do begin
			if not mBalls[j].alive then
				continue;
			
			if CircleToRect( mBalls[j].pos, mBalls[j].radius, mBounds[i], pushVec ) = true then begin
				mBalls[j].pos:= mBalls[j].pos + pushVec;
				pushVec.Normalize;
				mBalls[j].vel:= Reflect(mBalls[j].vel, pushVec);
				
				al_play_sample(mHitMetalWav, 255, 127, 1000, 0);
			end;
		end;
	end;
	
	// Kolizje kulki-prostok¹ty
	for i:= 0 to high(mBricks) do begin
		for j:= 0 to high(mBalls) do begin
			if (mBricks[i].alive = true) and(mBalls[j].alive = true) and (CircleToRect(mBalls[j].pos, mBalls[j].radius, mBricks[i].rect, pushVec) = true) then
			begin
					if mBalls[j].fireball then begin
						Dec(mBalls[j].hitCount);
						if mBalls[j].hitCount <= 0 then
							mBalls[j].fireball:= false;
					end;
					
					if (mBalls[j].fireball = false) or (mBricks[i].brickType = BT_SOLID) then begin
						mBalls[j].pos:= mBalls[j].pos + pushVec;
						pushVec.Normalize;
						mBalls[j].vel:= Reflect(mBalls[j].vel, pushVec);
					end;
					
					with mBricks[i] do begin
						if brickType = BT_SOLID then begin
							al_play_sample(mHitMetalWav, 255, 127, 1000, 0);
							continue;
						end
						else if brickType = BT_NORMAL then
							al_play_sample(mHitWoodWav, 255, 127, 1000, 0)
						else if brickType = BT_ROCK then
							al_play_sample(mHitMetalWav, 255, 127, 1000, 0);
							
						Dec(hitsToBreak);
						if hitsToBreak <= 0 then begin
							alive:= false;
							exploding:= true;
							explosionStartTime:= mCurrentTime;
							
							Dec(mBricksToBreak);
							
							// Dodanie punktów za zburzenie œciany
							if brickType = BT_NORMAL then begin
								AddScore(10);
								if Random < NORMAL_BRICK_POWERUP then
									AddPowerup(rect.x + rect.width/2, rect.y + rect.height);
							end
							else if brickType = BT_ROCK then begin
								AddScore(50);
								if Random < ROCK_BRICK_POWERUP then
									AddPowerup(rect.x + rect.width/2, rect.y + rect.height);
							end;
						end;
					end;
					
			end;
		end;
	end;

	
	
	//Kolizja kulki-paletka
	for i:= 0 to high(mBalls) do begin
		if (mBalls[i].alive = true) then begin
			
			collide := CircleToRect(mBalls[i].pos, mBalls[i].radius, mPaddle.rect, pushVec);
			//	mBalls[i].pos:= mBalls[i].pos + pushVec;
			//	
			//	pushVec.Normalize;
			//	mBalls[i].vel:= Reflect(mBalls[i].vel, pushVec);
			//	mBalls[i].vel:= mBalls[i].vel + 40*mPaddleSpeed;
			//	al_play_sample(mHitMetalWav, 255, 127, 1000, 0);
			//	continue;
			//end
			
			if collide = false then begin
				circlePos.x := mPaddle.rect.x + mPaddle.rect.height/2;
				circlePos.y := mPaddle.rect.y + mPaddle.rect.height/2;
				collide:= CircleToCircle(mBalls[i].pos, mBalls[i].radius, circlePos, mPaddle.rect.height/2, pushVec);
			end;
			
			if collide = false then begin
				circlePos.x := mPaddle.rect.x + mPaddle.rect.width - mPaddle.rect.height/2;
				circlePos.y := mPaddle.rect.y + mPaddle.rect.height/2;
				collide:= CircleToCircle(mBalls[i].pos, mBalls[i].radius, circlePos, mPaddle.rect.height/2, pushVec);
			end;
			
			if collide = true then begin
				mBalls[i].pos:= mBalls[i].pos + pushVec;
				
				pushVec.Normalize;
				mBalls[i].vel:= Reflect(mBalls[i].vel, pushVec);
				mBalls[i].vel:= mBalls[i].vel + 40*mPaddleSpeed;
				al_play_sample(mHitMetalWav, 255, 127, 1000, 0);
			end;
			
			// Poprzedni sposób odbijania pi³ki. Wystêpuje w klasycznym arkanoidzie.
			// Je¿eli pi³eczka leci do góry, to znaczy trafi³a paletkê z do³u (np. po stracie ¿ycia)
			// Odbijamy j¹ zgodnie z zasad¹ "k¹t padania == k¹t odbicia"
			//if mBalls[i].vel.y < 0 then begin
			//pushVec.Normalize;
			//mBalls[i].vel:= Reflect(mBalls[i].vel, pushVec);
			//mBalls[i].vel:= mBalls[i].vel + 40*mPaddleSpeed;
			//end
			// W przeciwnym wypadku k¹t odbicia zale¿y od miejsca odbicia (tak jak ma to miejsce w klasycznym Arkanoidzie z konsoli NES)
			//else begin
			//	newVel.x:= mPaddle.rect.x + mPaddle.rect.width/2;
			//	newVel.y:= mPaddle.rect.y + mPaddle.rect.width/2;
			//	
			//	newVel:= mBalls[i].pos - newVel;
			//	newVel.Normalize;
			//	newVel:= newVel* mBalls[i].vel.Len;
			//	mBalls[i].vel:= newVel;
			//end;
			
			
		end;
	end;
	

	//Powerupy - paletka
	for i:= 0 to high(mPowerups) do begin
		if (mPowerups[i].alive = true) and (CircleToRect(mPowerups[i].pos, 8, mPaddle.rect, pushVec) = true) then begin
			with mPowerups[i] do begin
				alive:= false;
				
				// Rozdzielenie jednej z pi³ek
				if powerupType = PT_BALL then begin
					yMinId:= FindLowestY;
	
					for j:= 0 to high(mBalls) do begin
						if mBalls[j].alive = false then begin
							left:= CrossLeft(mBalls[yMinId].vel);
							right:= CrossRight(mBalls[yMinId].vel);
							
							// Pi³ki siê rozdzielaj¹ i lec¹ w dwóch kierunkach przy zachowanu poprzedniej prêdkoœci
							mBalls[j].alive:= true;
							mBalls[j].pos:= mBalls[yMinId].pos;
							mBalls[j].vel:= mBalls[yMinId].vel;
							mBalls[j].vel:= mBalls[yMinId].vel + right;
							mBalls[j].vel.x:= mBalls[j].vel.x / sqrt(2);
							mBalls[j].vel.y:= mBalls[j].vel.y / sqrt(2);
							mBalls[j].fireball:= false;
							
							mBalls[yMinId].vel:= mBalls[yMinId].vel + left;
							mBalls[yMinId].vel.x:= mBalls[yMinId].vel.x / sqrt(2);
							mBalls[yMinId].vel.y:= mBalls[yMinId].vel.y / sqrt(2);

							mBalls[j].radius:= BALL_RADIUS;
							Inc(mBallsAlive);
							break;
						end;
					end;
				end
				// Zwiêkszenie prêdkoœci jednej z pi³ek
				else if powerupType = PT_SPEED_UP then begin
					yMinId:= FindLowestY;
					mBalls[yMinId].vel:= SPEED_UP_RATE*mBalls[yMinId].vel;
				end
				// Zmniejszenie prêdkoœci jednej z pi³ek
				else if powerupType = PT_SLOW_DOWN then begin
					yMinId:= FindLowestY;
					mBalls[yMinId].vel:= SLOW_DOWN_RATE*mBalls[yMinId].vel;
				end
				// Zamiana jednej z pi³eczek w ognist¹ kulê
				else if powerupType = PT_FIREBALL then begin
					yMinId:= FindLowestY;
					mBalls[yMinId].fireball:= true;
					Inc(mBalls[yMinId].hitCount, FIREBALL_HIT_COUNT);
				end
				// Wyd³u¿enie paletki
				else if powerupType = PT_LENGHTEN then begin
					mPaddle.lenghtening:= true;
					mPaddle.shortening:= false;
				end
				// Skrócenie paletki
				else if powerupType = PT_SHORTEN then begin
					mPaddle.shortening:= true;
					mPaddle.lenghtening:= false;
				end;
				
				al_play_sample(mPowerupWav, 255, 127, 1000, 0);
			end;
		end;
	end;
end;
//------------------------------------------------------------------------------------------------

// Aktualizacja punktów
procedure TGame.AddScore(score: longint);
begin
	if 2*score > mScoreSpeed then begin
		mScoreSpeed:= 2*score;
	end;
	Inc(mScore, score);
end;
//------------------------------------------------------------------------------------------------

// Zapisanie najlepszych wyników do pliku.
procedure TGame.SaveHighscores;
var
	f: file of THighscoreEntry;
	i: longint;
begin
	Assign(f, HIGHSCORES_FILENAME);
	Rewrite(f);
	
	for i:= 1 to MAX_HIGHSCORE_ENTRIES do begin
		Write(f, mHighscores[i]);
	end;
	
	Close(f);
end;
//------------------------------------------------------------------------------------------------

// Wczytanie najlepszych wyników z pliku.
procedure TGame.LoadHighscores;
var
	f: file of THighscoreEntry;
	i: longint;
begin
	if not FileExists(HIGHSCORES_FILENAME) then begin
		// Tworzymy plik z domyœlnymi wynikami
		
		for i:= 1 to MAX_HIGHSCORE_ENTRIES do
			mHighscores[i].score:= (MAX_HIGHSCORE_ENTRIES - (i-1))*1000;
		
		mHighscores[1].name:= 'Janitor';
		mHighscores[2].name:= 'Cox';
		mHighscores[3].name:= 'Bob';
		mHighscores[4].name:= 'J.D.';
		mHighscores[5].name:= 'Turk';
		mHighscores[6].name:= 'Elliot';
		mHighscores[7].name:= 'Ted';
		mHighscores[8].name:= 'Carla';
		mHighscores[9].name:= 'The Todd';
		mHighscores[10].name:= 'Jordan';
		
		SaveHighscores;
	end
	else begin
		Assign(f, HIGHSCORES_FILENAME);
		Reset(f);
		for i:= 1 to MAX_HIGHSCORE_ENTRIES do begin
			Read(f, mHighscores[i]);
		end;
		Close(f);
	end;
end;
//------------------------------------------------------------------------------------------------

// Dodaje losowy bonus na planszy
// Parametry:
//		x, y: wspó³rzêdne w których ma siê pojawiæ bonus
procedure TGame.AddPowerup(x, y: Real);
var
	i: longint;
begin
	for i:= 0 to high(mPowerups) do begin
		if not mPowerups[i].alive then begin
			with mPowerups[i] do begin
				powerupType:= Random(PT_COUNT) + 1;
				vel.x:= 0;
				vel.y:= Random(100)+50;
				pos.x:= x;
				pos.y:= y;
				alive:= true;
			end;
			break;
		end;
	end;
end;
//------------------------------------------------------------------------------------------------

// Aktualizujê grê: liczy punkty, sprawdza kolizjê, przesuwa obiekty itp.
procedure TGame.UpdateGame;
var
	i: longint;
begin

	// Aktualizacja punktów
	mCurrentScore:= mCurrentScore + mScoreSpeed*mDeltaTime;
	if mCurrentScore > mScore then begin
		mCurrentScore:= mScore;
		mScoreSpeed:= 0;
	end;

	// Wygrana gracza na danej planszy
	if mWin then begin
		if mCurrentTime > mWinTime + 2.0 then begin
			Inc(mLevel);
			InitGame(mLevel);
		end;
		exit;
	end;
	
	// Przejœcie do stanu MENU
	if mKey shr 8 = AL_KEY_ESC then begin
		mGamePaused:= true;
		mCurrentState:= GS_MENU;
		mCurrentMenuItem:= 0;
	end;	

	// Rozci¹ganie/skurczanie paletki w wyniku dzia³ania bonusu
	if mPaddle.lenghtening then begin
		mPaddle.rect.x:= mPaddle.rect.x - LENGHTEN_SPEED*mDeltaTime;
		mPaddle.rect.width:= mPaddle.rect.width + 2*LENGHTEN_SPEED*mDeltaTime;
		
		if mPaddle.rect.width > MAX_PADDLE_WIDTH then begin
			mPaddle.rect.width:= MAX_PADDLE_WIDTH;
			mPaddle.lenghtening:= false;
		end;
	end;
	
	if mPaddle.shortening then begin
		mPaddle.rect.x:= mPaddle.rect.x + LENGHTEN_SPEED*mDeltaTime;
		mPaddle.rect.width:= mPaddle.rect.width - 2*LENGHTEN_SPEED*mDeltaTime;
		
		if mPaddle.rect.width < MIN_PADDLE_WIDTH then begin
			mPaddle.rect.width:= MIN_PADDLE_WIDTH;
			mPaddle.shortening:= false;
		end;
	end;
	
	// P³ynny zatrzymanie paletki po skoñczonym ruchu
	mPaddleSpeed.x:= mPaddleSpeed.x * 0.8;
	mPaddleSpeed.y:= mPaddleSpeed.y * 0.8;
	
	if al_key[AL_KEY_LEFT] <> 0 then begin
		mPaddleSpeed.x:= mPaddleSpeed.x - 75*mDeltaTime;
		if mPaddleSpeed.x < -PADDLE_SPEED.x then
			mPaddleSpeed.x:= -PADDLE_SPEED.x;
	end;
	
	if al_key[AL_KEY_RIGHT] <> 0 then begin
		mPaddleSpeed.x:= mPaddleSpeed.x + 75*mDeltaTime;
		if mPaddleSpeed.x > PADDLE_SPEED.x then
			mPaddleSpeed.x:= PADDLE_SPEED.x;
	end;
	
	mPaddle.rect.x:= mPaddle.rect.x + mPaddleSpeed.x;
	
	for i:= 0 to high(mBalls) do begin
		if mBalls[i].alive then begin
			if mBalls[i].vel.Len < 200 then
				mBalls[i].vel:= mBalls[i].vel*1.1;
			mBalls[i].pos := mBalls[i].pos + mBalls[i].vel*mDeltaTime;
		end;
	end;
	
	for i:= 0 to high(mPowerups) do begin
		if mPowerups[i].alive then
			mPowerups[i].pos := mPowerups[i].pos + mPowerups[i].vel*mDeltaTime;
	end;
	
	if mPaddle.rect.x < BOUND then
		mPaddle.rect.x:= BOUND;
		
	if mPaddle.rect.x > SCREEN_WIDTH - BOUND - mPaddle.rect.width then
		mPaddle.rect.x:= SCREEN_WIDTH - BOUND - mPaddle.rect.width;
	
	if mLose then begin
		mGamePaused:= true;
	end;
	
	if (mBricksToBreak = 0) and (not mWin) then begin
		mWinTime:= mCurrentTime;
		mWin:= true;
		AddScore(500*mLevel);
		al_play_sample(mWinWav, 255, 127, 1000, 0);
	end;
	HandleCollisions;
end;
//------------------------------------------------------------------------------------------------

// Odrysowanie ekranu gry w zale¿noœci od aktualnego stanu
function TGame.Draw: boolean;
begin
	if not gGameRunning then
		exit;
		
	al_clear_bitmap(mBuffer);

	if mCurrentState = GS_MENU then
		DrawMenu
	else if mCurrentState = GS_HIGHSCORES then
		DrawHighscores
	else if mCurrentState = GS_CREDITS then
		DrawCredits
	else if mCurrentState = GS_GAME then
		DrawGame
	else if mCurrentState = GS_GAMEOVER then begin
		DrawGame;
		DrawGameover;
	end;
	
	if mShowFps then begin
		al_textout_ex(mBuffer, al_font, 'FPS:', 5, SCREEN_HEIGHT - 40, al_makecol(255, 255, 255), -1);
		al_textout_ex(mBuffer, al_font, IntToStr(Round(mFps)), 5, SCREEN_HEIGHT - 20, al_makecol(255, 255, 255), -1);
	end;
		
	al_blit(mBuffer, al_screen, 0, 0, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
	
	result:= true;
end;
//------------------------------------------------------------------------------------------------

// Odrysowanie menu
procedure TGame.DrawMenu;
var
	i, r, g, b: longint;
	y : longint = 250;
	rect_bottom: longint;
begin
	al_set_trans_blender(0, 0, 0, 0);
	al_draw_lit_sprite(mBuffer, mMenubmp, 0, 0, mFade);
	
	if mGamePaused then begin
		i:= 0;
		rect_bottom:= MENU_RECT_BOTTOM;
	end
	else begin
		i:= 1;
		rect_bottom:= MENU_RECT_BOTTOM - MENU_ITEM_INC;
	end;
		
	al_drawing_mode(AL_DRAW_MODE_TRANS, nil, 0, 0);
	al_set_trans_blender(0, 0, 0, MENU_TRANSPARENCY);
	al_rectfill(mBuffer, MENU_RECT_LEFT, MENU_RECT_TOP, MENU_RECT_RIGHT, rect_bottom, 0 );
	al_solid_mode;
		
	for i:=i to High(mMenuItems) do begin
		r:= 150; g:= 150; b:= 255;
		if i = mCurrentMenuItem then begin
			r:= 255; g:= 255; b:= 255;
			al_textout_ex(mBuffer, mFont, '-> ' + mMenuItems[i], SCREEN_WIDTH div 2 - 90, y, al_makecol(r, g, b), -1);
		end
		else begin
			r:= 120; g:= 120; b:= 200;
			al_textout_ex(mBuffer, mFont, mMenuItems[i], SCREEN_WIDTH div 2 - 90, y, al_makecol(r, g, b), -1);
			
		end;
		
		Inc(y, MENU_ITEM_INC);
	end;
end;
//------------------------------------------------------------------------------------------------

// Odrysowuje ekran gry
procedure TGame.DrawGame;
var
	i: longint;
begin
	al_clear_bitmap(mTempBmp);
	
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
		end
		// Animacja wybuchu
		else if mBricks[i].exploding = true then begin
			with mBricks[i] do begin
				if mCurrentTime-explosionStartTime > EXPLOSION_TIME then
					exploding:= false;
					
				al_set_alpha_blender;					
				al_blit(mExplosionBmp, mTempBmp, EXPLOSION_SIZE*Round( (((mCurrentTime - explosionStartTime)/EXPLOSION_TIME)*7)  ), 0, 0, 0, EXPLOSION_SIZE, EXPLOSION_SIZE);
				al_draw_trans_sprite(mBuffer, mTempBmp, Round(rect.x + rect.width/2 - EXPLOSION_SIZE div 2), Round(rect.y + rect.height/2 - EXPLOSION_SIZE div 2))
			
			end;
		end;
	end;
	al_clear_bitmap(mTempBmp);
	
	//Rysowanie kulek
	for i:= 0 to high(mBalls) do begin
		if mBalls[i].alive then begin
			al_set_alpha_blender;
			if mBalls[i].fireball then begin
				al_blit(mFireballBmp, mTempbmp, FIREBALL_SIZE*(Round(mCurrentTime*10) mod 4), 0, 0, 0, FIREBALL_SIZE, FIREBALL_SIZE);
				al_draw_trans_sprite(mBuffer, mTempBmp, Round(mBalls[i].pos.x - mBalls[i].radius), Round(mBalls[i].pos.y - mBalls[i].radius))
			end
			else
				al_draw_trans_sprite(mBuffer, mBallBmp, Round(mBalls[i].pos.x - mBalls[i].radius), Round(mBalls[i].pos.y - mBalls[i].radius));
		end;
	end;
	
	// Rysowanie powerupów
	for i:= 0 to high(mPowerups) do begin
		if mPowerups[i].alive then begin
			al_set_alpha_blender;
			al_blit(mPowerupBmp, mTempBmp, POWERUP_SIZE*(mPowerups[i].powerupType - 1), 0, 0, 0, POWERUP_SIZE, POWERUP_SIZE);
			al_draw_trans_sprite(mBuffer, mTempBmp, Round(mPowerups[i].pos.x) - POWERUP_SIZE div 2, Round(mPowerups[i].pos.y) - POWERUP_SIZE div 2);
		end;
	end;
	
	al_stretch_sprite(mTempBmp, mPaddleBmp, 0, 0, Round(mPaddle.rect.width), Round(mPaddle.rect.height));
	al_draw_trans_sprite(mBuffer, mTempBmp, Round(mPaddle.rect.x), Round(mPaddle.rect.y) );
	
	al_textout_ex(mBuffer, mFont, 'Punkty: ' + IntToStr(Round(mCurrentScore)), SCORE_POS_X, TOP_TEXT_Y, al_makecol(255, 255, 255), -1);
	al_textout_ex(mBuffer, mFont, 'Zycia: ' + IntToStr(mLives), LIVES_POS_X, TOP_TEXT_Y, al_makecol(255, 255, 255), -1);
	al_textout_ex(mBuffer, mFont, 'Poziom: ' + IntToStr(mLevel), LEVEL_POS_X, TOP_TEXT_Y, al_makecol(255, 255, 255), -1);
	
	// Czerwony ekran po stracie ¿ycia
	if mLifeLoss then begin
		FadeIn(1.0);
		al_set_trans_blender(255, 0, 0, 255);
		al_draw_lit_sprite(mBuffer, mBuffer, 0, 0, mFade);
		
		if mCurrentTime > mLifeLossTime + 1.0 then
			mLifeLoss:= false;
	end;
end;
//------------------------------------------------------------------------------------------------

// Odrysowuje ekran przegranej
procedure TGame.DrawGameover;
var
	y : longint = SCREEN_HEIGHT div 2 - MENU_ITEM_INC;
begin	
	al_drawing_mode(AL_DRAW_MODE_TRANS, nil, 0, 0);
	al_set_trans_blender(0, 0, 0, MENU_TRANSPARENCY);
	al_rectfill(mBuffer, 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, 0 );
	al_solid_mode;
	
	al_textout_centre_ex(mBuffer, mFont, 'Koniec gry!', SCREEN_WIDTH div 2, y, al_makecol(255, 0, 0), -1);
	
	if mNewHighscore then begin
		Inc(y, MENU_ITEM_INC);
		al_textout_centre_ex(mBuffer, mFont, 'Gratulacje! Twoj wynik znajdzie sie na liscie najlepszych wynikow!', SCREEN_WIDTH div 2, y, al_makecol(255, 255, 255), -1);
		Inc(y, MENU_ITEM_INC);
		al_textout_centre_ex(mBuffer, mFont, 'Podaj swoje imie: ' + mName, SCREEN_WIDTH div 2, y, al_makecol(255, 255, 255), -1);
	end;
end;
//------------------------------------------------------------------------------------------------

// Odrysowuje ekran najlepszych wyników
procedure TGame.DrawHighscores;
var
	i: longint;
begin
	al_set_trans_blender(0, 0, 0, 0);
	al_draw_lit_sprite(mBuffer, mMenubmp, 0, 0, mFade);
	
	al_drawing_mode(AL_DRAW_MODE_TRANS,nil,0,0);
	al_set_trans_blender(0, 0, 0, MENU_TRANSPARENCY);
	al_rectfill(mBuffer, HIGHSCORES_RECT_LEFT, HIGHSCORES_RECT_TOP, HIGHSCORES_RECT_RIGHT, HIGHSCORES_RECT_BOTTOM, 0 );
	al_solid_mode;
	
	al_textout_centre_ex(mBuffer, mFont, 'Najlepsze wyniki', SCREEN_WIDTH div 2, 200, al_makecol(255, 255, 255), -1);
	for i:= 1 to MAX_HIGHSCORE_ENTRIES do begin
		al_textout_right_ex(mBuffer, mFont, mHighscores[i].name + ' :', SCREEN_WIDTH div 2, 240 + (i-1)*30, al_makecol(255, 255, 255), -1);
		al_textout_ex(mBuffer, mFont, ' ' + IntToStr(mHighscores[i].score), SCREEN_WIDTH div 2, 240 + (i-1)*30, al_makecol(255, 255, 255), -1);
	end;
end;
//------------------------------------------------------------------------------------------------

// Odrysowuje ekran "Autorzy"
procedure TGame.DrawCredits;
var
	y: longint = 200;
begin
	al_set_trans_blender(0, 0, 0, 0);
	al_draw_lit_sprite(mBuffer, mMenubmp, 0, 0, mFade);
	
	al_drawing_mode(AL_DRAW_MODE_TRANS, nil, 0, 0);
	al_set_trans_blender(0, 0, 0, MENU_TRANSPARENCY);
	al_rectfill(mBuffer, CREDITS_RECT_LEFT, CREDITS_RECT_TOP, CREDITS_RECT_RIGHT, CREDITS_RECT_BOTTOM, 0 );
	al_solid_mode;
	
	al_textout_centre_ex(mBuffer, mFont, 'Autorzy', SCREEN_WIDTH div 2, y, al_makecol(255, 255, 255), -1);
	Inc(y, MENU_ITEM_INC);
	al_textout_centre_ex(mBuffer, mFont, 'Maciej Czekanski', SCREEN_WIDTH div 2, y, al_makecol(255, 255, 255), -1);
	Inc(y, MENU_ITEM_INC div 2);
	al_textout_centre_ex(mBuffer, mFont, 'IS2009 @ EAIiE, AGH', SCREEN_WIDTH div 2, y, al_makecol(255, 255, 255), -1);
	Inc(y, MENU_ITEM_INC);
	al_textout_centre_ex(mBuffer, mFont, 'Ta gra posiada certyfikat ''Works on My Machine'':', SCREEN_WIDTH div 2, y, al_makecol(255, 255, 255), -1);
	Inc(y, MENU_ITEM_INC div 2 + 10);

	al_set_alpha_blender;
	al_draw_trans_sprite(mBuffer, mCertificateBmp, SCREEN_WIDTH div 2 - CERTYFICATE_SIZE div 2, y);
end;
//------------------------------------------------------------------------------------------------

// Funkcja pomocnicza do stworzenia p³ynnego przejœcia do danego ekranu
procedure TGame.FadeIn(time: Real);
begin		
	if (mFading = false) then begin
		mFadeStart:= mCurrentTime;
		mFadeEnd:= mFadeStart + time;
		mFading:= true;
	end
	else begin
		if mCurrentTime >= mFadeEnd then begin
			mFading:= false;
			mFade:= 0;
			exit;
		end;
		
		mFade:= Round(255 - 255*((mCurrentTime - mFadeStart)/(mFadeEnd - mFadeStart)));
	end;
end;
//------------------------------------------------------------------------------------------------

// Funkcja pomocnicza do stworzenia p³ynnego przejœcia do danego ekranu
procedure TGame.FadeOut(time: Real);
begin		
	if (mFading = false) then begin
		mFadeStart:= mCurrentTime;
		mFadeEnd:= mFadeStart + time;
		mFading:= true;
	end
	else begin
		if mCurrentTime >= mFadeEnd then begin
			mFading:= false;
			mFade:= 255;
			exit;
		end;
		
		mFade:= Round(255*((mCurrentTime - mFadeStart)/(mFadeEnd - mFadeStart)));
	end;
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














