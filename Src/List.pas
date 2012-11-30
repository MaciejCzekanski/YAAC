//-----------------------------------------
// Maciej Czekañski
// maves90@gmail.com
//-----------------------------------------

unit List;

interface

uses Arkanoid;

TYPE
	TNodePtr_Ball = ^TNode_Ball;
	TNode_Ball = record
		prev: TNodePtr_Ball;
		next: TNodePtr_Ball;
		data: TBall;
	end;
	
	// BALLS
	TListOfBalls = object
		head: TNodePtr_Ball;
		tail: TNodePtr_Ball;
		
		procedure Init;
		procedure DeInit;
		
		function PushFront(ball: TBall): TNodePtr_Ball;
		function PushBack(ball: TBall): TNodePtr_Ball;
		
		function Front: TBall;
		function Back: TBall;
		
		function Count: longint;
		
		function Search(ball: TBall): TNodePtr_Ball;
		
		procedure PopFront;
		procedure PopBack;
		procedure Remove(node: TNodePtr_Ball);
	end;
	
	// BRICKS
	TNodePtr_Brick = ^TNode_Brick;
	TNode_Brick = record
		prev: TNodePtr_Brick;
		next: TNodePtr_Brick;
		data: TBrick;
	end;
	
	TListOfBricks = object
		head: TNodePtr_Brick;
		tail: TNodePtr_Brick;
		
		procedure Init;
		procedure DeInit;
		
		function PushFront(brick: TBrick): TNodePtr_Brick;
		function PushBack(brick: TBrick): TNodePtr_Brick;
		
		function Front: TBrick;
		function Back: TBrick;
		
		function Count: longint;
		
		function Search(brick: TBrick): TNodePtr_Brick;
		
		procedure PopFront;
		procedure PopBack;
		procedure Remove(node: TNodePtr_Brick);
	end;
	
	// POWERUPS
	TNodePtr_Powerup = ^TNode_Powerup;
	TNode_Powerup = record
		prev: TNodePtr_Powerup;
		next: TNodePtr_Powerup;
		data: TPowerup;
	end;
	
	TListOfPowerups = object
		head: TNodePtr_Powerup;
		tail: TNodePtr_Powerup;
		
		procedure Init;
		procedure DeInit;
		
		function PushFront(powerup: TPowerup): TNodePtr_Powerup;
		function PushBack(powerup: TPowerup): TNodePtr_Powerup;
		
		function Front: TPowerup;
		function Back: TPowerup;
		
		function Count: longint;
		
		function Search(powerup: TPowerup): TNodePtr_Powerup;
		
		procedure PopFront;
		procedure PopBack;
		procedure Remove(node: TNodePtr_Powerup);
	end;
	
IMPLEMENTATION

// BALLS ------------------------------------------------------------------------
procedure TlistOfBalls.Init;
begin
	head:= nil;
	tail:= nil;
end;

procedure TlistOfBalls.DeInit;
var
	node: TNodePtr_Ball;
begin
	node:= head;

	while node <> nil do begin
		node:= node^.next;
		PopFront;
	end;
end;

function TListOfBalls.PushFront(ball: TBall): TNodePtr_Ball;
var
	newNode: TNodePtr_Ball;
begin
	New(newNode);
	newNode^.prev:= nil;
	newNode^.next:= head;
	newNode^.data:= ball;
	
	if head = nil then begin
		head:= newNode;
		tail:= newNode;
	end
	else begin
		head^.prev:= newNode;
		head:= newNode;
	end;
	
	result:= newNode;
end;

function TListOfBalls.PushBack(ball: TBall): TnodePtr_Ball;
var
	newNode: TNodePtr_Ball;
begin
	New(newNode);
	newNode^.prev:= tail;
	newNode^.next:= nil;
	newNode^.data:= ball;
	
	if tail = nil then begin
		head:= newNode;
		tail:= newNode;
	end
	else begin
		tail^.next:= newNode;
		tail:= newNode;
	end;		
	
	result:= newNode;
end;

function TlistOfBalls.Front: TBall;
begin
	result:= head^.data;
end;

function TListOfBalls.Back: TBall;
begin
	result:= tail^.data;
end;

function TListOfBalls.Count: longint;
var
	node: TNodePtr_Ball;
	num: longint = 0;
begin
	node:= head;

	while node <> nil do begin
		Inc(num);
		node:= node^.next;
	end;
	
	result:= num;
end;

function TListOfBalls.Search(ball: TBall): TNodePtr_Ball;
var
	node: TNodePtr_Ball;
begin
	node:= head;
	result:= nil;
	
	while node <> nil do begin
		if node^.data = ball then begin
			result:= node;
			break;
		end;
		
		node:= node^.next;
	end;
end;

procedure TListOfBalls.PopFront;
begin
	if head = tail then begin
		Dispose(head);
		head:= nil;
		tail:= nil;
	end
	else begin
		head:= head^.next;
		Dispose(head^.prev);
		head^.prev:= nil;
	end;
end;

procedure TListOfBalls.PopBack;
var
	node: TNodePtr_Ball;
begin
	node:= tail;
	
	if head = tail then begin
		Dispose(tail);
		head:= nil;
		tail:= nil;
	end
	else begin
		tail:= tail^.prev;
		tail^.next:= nil;	
		Dispose(node);
	end;
end;

procedure TListOfBalls.Remove(node: TNodePtr_Ball);
begin
	if node = head then
		PopFront
	else if node = tail then
		PopBack
	else begin
		node^.prev^.next := node^.next;
		node^.next^.prev := node^.prev;
		Dispose(node);
	end;
end;

// BRICKS-------------------------------------------------------------------

procedure TlistOfBricks.Init;
begin
	head:= nil;
	tail:= nil;
end;

procedure TlistOfBricks.DeInit;
var
	node: TNodePtr_Brick;
begin
	node:= head;

	while node <> nil do begin
		node:= node^.next;
		PopFront;
	end;
	
	head:= nil;
	tail:= nil;
end;

function TlistOfBricks.PushFront(brick: TBrick): TNodePtr_Brick;
var
	newNode: TNodePtr_Brick;
begin
	New(newNode);
	newNode^.prev:= nil;
	newNode^.next:= head;
	newNode^.data:= brick;
	
	if head = nil then begin
		head:= newNode;
		tail:= newNode;
	end
	else begin
		head^.prev:= newNode;
		head:= newNode;
	end;
	
	result:= newNode;
end;

function TlistOfBricks.PushBack(brick: TBrick): TNodePtr_Brick;
var
	newNode: TNodePtr_Brick;
begin
	New(newNode);
	newNode^.prev:= tail;
	newNode^.next:= nil;
	newNode^.data:= brick;
	
	if tail = nil then begin
		head:= newNode;
		tail:= newNode;
	end
	else begin
		tail^.next:= newNode;
		tail:= newNode;
	end;		
	
	result:= newNode;
end;

function TlistOfBricks.Front: TBrick;
begin
	result:= head^.data;
end;

function TlistOfBricks.Back: TBrick;
begin
	result:= tail^.data;
end;

function TlistOfBricks.Count: longint;
var
	node: TNodePtr_Brick;
	num: longint = 0;
begin
	node:= head;

	while node <> nil do begin
		Inc(num);
		node:= node^.next;
	end;
	
	result:= num;
end;

function TlistOfBricks.Search(brick: TBrick): TNodePtr_Brick;
var
	node: TNodePtr_Brick;
begin
	node:= head;
	result:= nil;
	
	while node <> nil do begin
		if node^.data = brick then begin
			result:= node;
			break;
		end;
		
		node:= node^.next;
	end;
end;

procedure TlistOfBricks.PopFront;
begin
	if head = tail then begin
		Dispose(head);
		head:= nil;
		tail:= nil;
	end
	else begin
		head:= head^.next;
		Dispose(head^.prev);
		head^.prev:= nil;
	end;
end;

procedure TlistOfBricks.PopBack;
var
	node: TNodePtr_Brick;
begin
	node:= tail;
	
	if head = tail then begin
		Dispose(tail);
		head:= nil;
		tail:= nil;
	end
	else begin
		tail:= tail^.prev;
		tail^.next:= nil;	
		Dispose(node);
	end;
end;

procedure TlistOfBricks.Remove(node: TNodePtr_Brick);
begin
	if node = head then
		PopFront
	else if node = tail then
		PopBack
	else begin
		node^.prev^.next := node^.next;
		node^.next^.prev := node^.prev;
		Dispose(node);
	end;
end;


// POWERUPS -------------------------------------------------------------


procedure TlistOfPowerups.Init;
begin
	head:= nil;
	tail:= nil;
end;

procedure TlistOfPowerups.DeInit;
var
	node: TNodePtr_Powerup;
begin
	node:= head;

	while node <> nil do begin
		node:= node^.next;
		PopFront;
	end;
	
	head:= nil;
	tail:= nil;
end;

function TlistOfPowerups.PushFront(powerup: TPowerup): TNodePtr_Powerup;
var
	newNode: TNodePtr_Powerup;
begin
	New(newNode);
	newNode^.prev:= nil;
	newNode^.next:= head;
	newNode^.data:= powerup;
	
	if head = nil then begin
		head:= newNode;
		tail:= newNode;
	end
	else begin
		head^.prev:= newNode;
		head:= newNode;
	end;
	
	result:= newNode;
end;

function TlistOfPowerups.PushBack(powerup: TPowerup): TNodePtr_Powerup;
var
	newNode: TNodePtr_Powerup;
begin
	New(newNode);
	newNode^.prev:= tail;
	newNode^.next:= nil;
	newNode^.data:= powerup;
	
	if tail = nil then begin
		head:= newNode;
		tail:= newNode;
	end
	else begin
		tail^.next:= newNode;
		tail:= newNode;
	end;		
	
	result:= newNode;
end;

function TlistOfPowerups.Front: TPowerup;
begin
	result:= head^.data;
end;

function TlistOfPowerups.Back: TPowerup;
begin
	result:= tail^.data;
end;

function TlistOfPowerups.Count: longint;
var
	node: TNodePtr_Powerup;
	num: longint = 0;
begin
	node:= head;

	while node <> nil do begin
		Inc(num);
		node:= node^.next;
	end;
	
	result:= num;
end;

function TlistOfPowerups.Search(powerup: TPowerup): TNodePtr_Powerup;
var
	node: TNodePtr_Powerup;
begin
	node:= head;
	result:= nil;
	
	while node <> nil do begin
		if node^.data = powerup then begin
			result:= node;
			break;
		end;
		
		node:= node^.next;
	end;
end;

procedure TlistOfPowerups.PopFront;
begin
	if head = tail then begin
		Dispose(head);
		head:= nil;
		tail:= nil;
	end
	else begin
		head:= head^.next;
		Dispose(head^.prev);
		head^.prev:= nil;
	end;
end;

procedure TlistOfPowerups.PopBack;
var
	node: TNodePtr_Powerup;
begin
	node:= tail;
	
	if head = tail then begin
		Dispose(tail);
		head:= nil;
		tail:= nil;
	end
	else begin
		tail:= tail^.prev;
		tail^.next:= nil;	
		Dispose(node);
	end;
end;

procedure TlistOfPowerups.Remove(node: TNodePtr_Powerup);
begin
	if node = head then
		PopFront
	else if node = tail then
		PopBack
	else begin
		node^.prev^.next := node^.next;
		node^.next^.prev := node^.prev;
		Dispose(node);
	end;
end;


BEGIN
END.

Lubie placki