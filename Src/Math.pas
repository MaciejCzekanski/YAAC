//-----------------------------------------
// Maciej Czeka�ski
// maves90@gmail.com
//-----------------------------------------

unit Math;

//----------------------------------------------------------------------------------------
interface
//----------------------------------------------------------------------------------------
CONST
	EPSILON = 0.000001;		// Dok�adno�� do kt�rej przybli�ane jest 0
	

TYPE	
	// Klasa reprezentuj�ca wektor 2D. Prze�adowuje podstawowe operatory takie jak dodawanie czy negacja.
	TVector2 = object
		public
		
		x, y: Real;
		
		function Len: Real;
		function SquareLen: Real;
		procedure Normalize;
	end;
	
	// Struktura opisuj�ca prostok�t. Jego boki s� zawsze r�wnoleg�e do osi X oraz Y.
	TRectF = record
		x, y, width, height: Real;
	end;

// Podstawowe operacje na wektorach
operator -(v: TVector2):TVector2;
operator +(a, b: TVector2):TVector2;
operator -(a, b: TVector2):TVector2;
operator *(s: Real; v: TVector2):TVector2;
operator *(v:TVector2; s: Real): TVector2;
operator /(v: TVector2; s: Real):TVector2;

operator =(a, b: TVector2): boolean;

operator =(a, b: TRectF): boolean;

// Iloczyn skalarny
function Dot( a, b: TVector2): Real;
// Iloczyn wektorowy
function CrossRight(a: TVector2): TVector2;
function CrossLeft(a: TVector2): TVector2;
// Odbicie
function Reflect( I, N: TVector2): TVector2;
// Projekcja wektora na wektor
function Project( a, b: TVector2): TVector2;

// Przycina podan� warto�� do danego przedzia�u
function Clamp(var x: Real; a, b: Real): Real;


//----------------------------------------------------------------------------------------
// K O L I Z J E
//----------------------------------------------------------------------------------------

// parametr outVec w poni�szych funkcjach oznacza najkr�tszy wektor o jaki nale�y przesun�� koliduj�cy obiekt
// aby kolizja nie wyst�powa�a.


// Funkcja sprawdzaj�ca czy dany punkt znajduje si� wewn�trz wielok�ta.
// Podany wielok�t musi by� wypuk�y.
function PointInPolygon(P: TVector2; Verts: array of TVector2): boolean;
// Funkcja sprawdzaj�ca czy odcinek przecina wielok�t
function SegmentToPolygon( startP, endP: TVector2; verts: array of TVector2; out nearN, farN: TVector2): boolean;

// Funkcje pomocnicze
function AxisSeparatePolygons( var axis: TVector2; polyA, polyB: array of TVector2): boolean;
function FindPushVec( pushVectors: array of TVector2; n: longint): TVector2;
procedure CalculateInterval( axis: TVector2; poly: array of TVector2; out min, max: Real);

// Funkcja sprawdzaj�ca czy wielok�t przecina wielok�t
function PolygonToPolygon( polyA, polyB: array of TVector2; out pushVec: TVector2): boolean;
// Funkcja sprawdzaj�ca czy odcinek przecina ko�o
function CircleToSegment( circlePos: TVector2; radius: Real; A, B: TVector2; out pushVec: TVector2): boolean;
// Funkcja sprawdzaj�ca czy prosta przecina okr�g
function CircleToLine( circlePos: TVector2; radius: Real; A, B: TVector2; out pushVec: TVector2 ): boolean;
// Funkcja sprawdzaj�ca czy Wielok�t przecina ko�o
function CircleToPolygon( circlePos: TVector2; radius: Real; poly: array of TVector2; out pushVec: TVector2): boolean;
//funkcja sprawdzaj�ca czy ko�o przecina ko�o
function CircleToCircle( circlePosA: TVector2; radiusA: Real; circlePosB: TVector2; radiusB: Real; out pushVec: TVector2): boolean;

// Funkcja sprawdzaj�ca czy ko�o przecina prostok�t
function CircleToRect( center: TVector2; radius: Real; rect: TRectF; out N: TVector2): boolean;
// Funkcja sprwdzaj�ca czy punkt znajduje si� wewn�trz prostok�ta
function PointInRect( x, y: Real; rect: TRectF ): boolean;
// Funkcja sprawdzaj�ca czy prostok�t przecina prostok�t
function RectToRect( a, b: TRectF ): boolean;


//----------------------------------------------------------------------------------------
implementation
//----------------------------------------------------------------------------------------

operator -(v: TVector2):TVector2;
begin
	result.x := -v.x;
	result.y := -v.y;
end;

operator +(a, b: TVector2): TVector2;
begin
	result.x := a.x + b.x;
	result.y := a.y + b.y;
end;

operator -(a, b: TVector2): TVector2;
begin
	result.x := a.x - b.x;
	result.y := a.y - b.y;
end;

operator *(s: Real; v: TVector2) :TVector2;
begin
	result.x := s*v.x;
	result.y := s*v.y;
end;

operator *(v:TVector2; s: Real): TVector2;
begin
	result.x := s*v.x;
	result.y := s*v.y;
end;

operator /(v: TVector2; s: Real):TVector2;
begin
	result.x := v.x/s;
	result.y := v.y/s;
end;

operator =(a, b: TVector2): boolean;
begin
	result:= (a.x = b.x) AND (a.y = b.y);
end;

function TVector2.Len: Real;
begin
	result := sqrt((x*x) + (y*y));
end;

function TVector2.SquareLen: Real;
begin
	result := (x*x) + (y*y);
end;

procedure TVector2.Normalize;
VAR
	invLen: Real;
begin
	if Len < EPSILON then
		exit;
		
	invLen := 1.0/Len;
	x := x*invLen;
	y := y*invLen;
end;

function Dot(a, b: TVector2):Real;
begin
	result:= (a.x*b.x) + (a.y*b.y);
end;

function CrossRight(a: TVector2): TVector2;
begin
	result.x := -a.y;
	result.y := a.x;
end;

function CrossLeft(a: TVector2):TVector2;
begin
	result.x := a.y;
	result.y := -a.x;
end;

function Reflect( I, N: TVector2): TVector2;
var
	d: Real;
begin
	d:= Dot(I, N);
	result.x:= I.x - 2.0*d*N.x;
	result.y:= I.y - 2.0*d*N.y;
end;

function Project( a, b: TVector2): TVector2;
VAR
	dp: Real;
begin
	dp:= Dot(a,b);
	
	result.x:= (dp/b.SquareLen)*b.x;
	result.y:= (dp/b.SquareLen)*b.y;
end;

function Clamp(var x: Real; a, b: Real): Real;
begin
	if x < a then
		x:= a
	else if x > b then
		x:= b;
		
	result:= x;
end;


operator =(a, b: TRectF): boolean;
begin
	result:= (a.x = b.x) AND (a.y = b.y) AND (a.width = b.width) AND (a.height = b.height);
end;

// Kolizje
function PointInPolygon(P: TVector2; verts: array of TVector2): boolean;
VAR
	i, j: longint;
	vecA, vecB: TVector2;
begin	

	j:= high(verts);
	
	for i:= 0 to high(verts) do	begin
		vecA:= CrossRight(verts[i] - verts[j]);
		vecB:= P - verts[j];
		
		if Dot(vecB, vecA) > 0.0 then begin
			result:= false;
			exit;
		end;
		
		j:= i;
	end;
	
	result:= true;
end;

function SegmentToPolygon( startP, endP: TVector2; verts: array of TVector2; out nearN, farN: TVector2): boolean;
var
	i, j: longint;
	denom, numer, tclip, tnear, tfar: Real;
	xDir, En, D: TVector2;
begin
	xDir:= endP - startP;
	tnear:= 0.0;
	tfar:= 1.0;
	
	j:= high(verts);
	for i:= 0 to high(verts) do	begin
		En:= CrossRight(verts[i] - verts[j]);
		D:= verts[j] - startP;
		denom:= Dot(En, D);
		numer:= Dot(En, xDir);
		
		if abs(numer) < 1e-5 then begin
			if denom < 0.0 then begin
				result:= false;
				exit;
			end;
		end
		else begin
			tclip:= denom/numer;
			
			if numer < 0.0 then begin
				if tclip > tfar then begin
					result:= false;
					exit;
				end;
				
				if tclip > tnear then begin
					tnear:= tclip;
					nearN:= startP + xDir*tnear;
				end;
			end
			else begin
				if tclip < tnear then begin
					result:= false;
					exit;
				end;
				
				if tclip < tfar then begin
					tfar:= tclip;
					farN:= startP + xDir*tfar;
				end;
			end;
		end;		
		
		j:= i;
	end;
	
	result:= true;
end;

function PolygonToPolygon( polyA, polyB: array of TVector2; out pushVec: TVector2): boolean;
var
	i, j, axisCount: longint;
	En: TVector2;
	axis: array[0..64] of TVector2;
	polyAPos, polyBPos: TVector2;
begin
	axisCount:= 0;
	polyAPos.x:= 0;
	polyAPos.y:= 0;
	polyBPos.x:= 0;
	polyBPos.y:= 0;
	
	j:= high(polyA);
	for i:= 0 to high(polyA) do begin
		polyAPos := polyAPos + polyA[i];
		
		En:= CrossRight(polyA[i] - polyA[j]);
		axis[axisCount]:= En;
		
		if AxisSeparatePolygons(axis[axisCount], polyA, polyB) = true then begin
			result:= false;
			exit;
		end;
		j:= i;
		inc(axisCount);
	end;
	polyAPos:= polyAPos / length(polyA);
	
	j:= high(polyB);
	for i:= 0 to high(polyB) do begin
		polyBPos:= polyBPos + polyB[i];
		En:= CrossRight(polyB[i] - polyB[j]);
		axis[axisCount]:= En;
		
		if AxisSeparatePolygons(axis[axisCount], polyA, polyB) = true then begin
			result:= false;
			exit;
		end;
		j:= i;
		inc(axisCount);
	end;
	polyBPos:= polyBPos / length(polyB);
	
	pushVec := FindPushVec(axis, axisCount);
	
	if Dot(pushVec, polyBPos - polyAPos) < 0 then
		pushVec := -pushVec;
	
	result:= true;
end;


function AxisSeparatePolygons( var axis: TVector2; polyA, polyB: array of TVector2): boolean;
var
	minA, maxA, minB, maxB: Real;
	d0, d1, depth: Real;
	axis_len_sq: Real;
begin
	CalculateInterval(axis, polyA, minA, maxA);
	CalculateInterval(axis, polyB, minB, maxB);
	
	if (minA > maxB) or (minB > maxA) then begin
		result:= true;
		exit;
	end;
	
	d0:= maxA - minB;
	d1:= maxB - minA;
	if d0 < d1 then begin
		depth:= d0;
	end
	else begin
		depth:= d1;
	end;
		
	axis_len_sq:= Dot(axis, axis);
	
	Axis:= Axis*(depth/axis_len_sq);
	result:= false;
end;


function FindPushVec( pushVectors: array of TVector2; n: longint): TVector2;
var
	minLenSq, lenSq: Real;
	i: longint;
begin
	result:= pushVectors[0];
	minLenSq:= Dot(pushVectors[0], pushVectors[0]);
	
	
	for i:= 1 to n-1 do begin
		lenSq:= Dot(pushVectors[i], pushVectors[i]);
		if lenSq < minLenSq then begin
			minLenSq:= lenSq;
			result:= pushVectors[i];
		end;
	end;
end;


procedure CalculateInterval( axis: TVector2; poly: array of TVector2; out min, max: Real);
var
	i: longint;
	d: Real;
begin
	d:= Dot(axis, poly[0]);
	min:= d;
	max:= d;
	
	for i:= 0 to high(poly) do begin
		d:= Dot(axis, poly[i]);
		if d < min then begin
			min:= d;
		end
		else if d > max then begin
			max:= d;
		end;
	end;
end;
{
function CircleToPolygon( circlePos: TVector2; radius: Real; poly: array of TVector2; out pushVec: TVector2): boolean;
var
	i: longint;
	closestPoint: TVector2;
	dist, distSq, newDistSq: Real;
	polyPos: TVector2;
begin
	polyPos.x:= 0;
	polyPos.y:= 0;
	
	closestPoint:= poly[0];
	distSq:= (circlePos - poly[0]).SquareLen;
	polyPos:= poly[0];
	
	for i:= 1 to high(poly) do begin
		polyPos := polyPos + poly[i];
		
		newDistSq:= (circlePos - poly[i]).SquareLen;
		if newDistSq < distSq then begin
			distSq:= newDistSq;
			closestPoint:= poly[i];
		end;
	end;
	polyPos:= polyPos / length(poly);
	
	if distSq > radius*radius then begin
		result:= false;
		exit;
	end;
	
	dist:= sqrt(distSq);
	
	pushVec:= (circlePos - closestPoint) * ((radius - dist) / dist);
	
	if Dot(pushVec, circlePos - polyPos) < 0 then
		pushVec := -pushVec;
	
	result:= true;
end;
}

// Kolizja z prost� wygl�da podobnie, tylko bez clamp
function CircleToSegment( circlePos: TVector2; radius: Real; A, B: TVector2; out pushVec: TVector2): boolean;
var
	dir, diff, D, closest: TVector2;
	t, dist: Real;
begin
	dir:= B - A;
	diff:= circlePos - A;
	
	t:= Dot(diff, dir) / Dot(dir, dir);
	Clamp(t, 0.0, 1.0);
	
	closest:= A + t*dir;
	D:= circlePos - closest;
	
	dist:= d.Len;
	
	if dist <= radius then
	begin
		result:= true;
		pushVec:= d;
		pushVec.Normalize;
		pushVec:= (radius-dist)*pushVec;
		pushVec:=pushVec/5; //? :| :TODO:
		exit;
	end;
	result:= false;
	
end;

function CircleToLine( circlePos: TVector2; radius: Real; A, B: TVector2; out pushVec: TVector2 ): boolean;
var
	dir, diff, d, closest: TVector2;
	t, dist: Real;
begin
	dir:= B - A;
	diff:= circlePos - A;
	
	t:= Dot(diff, dir) / Dot(dir, dir);
	
	closest:= A + t*dir;
	D:= circlePos - closest;
	
	dist:= d.Len;
	
	if dist <= radius then
	begin
		result:= true;
		pushVec:= d;
		pushVec.Normalize;
		pushVec:= (radius-dist)*pushVec;
		pushVec:=pushVec/5; //? :| :TODO:
		exit;
	end;
	result:= false;
end;

// Sprawdzam po kt�rej stronie �ciany znajduje si� �rodek okr�gu. S� 3 przypadki:
//1. Dla ka�dej �ciany �rodek le�y po lewej stronie - NIE DOPU�CI� do takiej sytuacji
//2. Dla jednej �ciany �rodek lezy po prawej - kolizja okr�g-odcinek
//		odleg�o�� okr�g-prosta na kt�rej le�y �ciana < 0
//		nie musiby sprawdza� czy rzut znajduje si� na kraw�dzi bo wtedy zachodzi przypadek 3.
//3. Dla dw�ch �cian �rodek le�y po prawej - kolizja okr�g-punkt z najbli�szym wierzcho�kiem

function CircleToPolygon( circlePos: TVector2; radius: Real; poly: array of TVector2; out pushVec: TVector2): boolean;
var
	i, j: longint;
	N, V, closestVertex: TVector2;
	numEdges: longint;
	newDist, distToEdge, distToVertex: Real;
begin
	distToEdge:= 10e4;
	distToVertex:= 10e4;
	numEdges:= 0;
	
	closestVertex := poly[0];
	j:= high(poly);
	for i:= 0 to high(poly) do begin
		N:= CrossRight(poly[i] - poly[j]); // normalna �ciany
		N.Normalize;
		V:= circlePos - poly[i];	// wektor wierzcho�ek-�rodekOkr�gu
		newDist:= Dot(N, V);
		if newDist > 0.0 then begin
			Inc(numEdges);
		end;
		
		if abs(newDist) < distToEdge then begin
			distToEdge:= abs(newDist);
			pushVec:= N;
		end;
		
		newDist:= (circlePos - poly[i]).Len;
		if newDist < distToVertex then begin
			distToVertex := newDist;
			closestVertex:= poly[i];
		end;
		
		j:= i;
	end;
	
	if numEdges = 1 then begin // kolizja okr�g-prosta
		//WriteLn(1);
		if distToEdge < radius then begin
			result:= true;
			
			exit;
		end
	end
	else if numEdges = 2 then begin // kolizja okr�g-punkt
		//WriteLn(2);
		if PointInPolygon( circlePos, closestVertex) = true then begin
			result:= true;
			pushVec:= (circlePos-closestVertex);
			exit;
		end;
	end;
	
	result:= false;
end;

function CircleToCircle( circlePosA: TVector2; radiusA: Real; circlePosB: TVector2; radiusB: Real; out pushVec: TVector2): boolean;
var
	diff: TVector2;
	dist: Real;
begin
	diff:= circlePosB - circlePosA;
	
	dist:= diff.Len;
	if dist < radiusA + radiusB then begin
		pushVec:= diff;
		pushVec.Normalize;
		pushVec:= (dist - radiusA - radiusB)*pushVec;
		result:= true;
		exit;
	end;
	result:= false;
end;

function CircleToRect( center: TVector2; radius: Real; rect: TRectF; out N: TVector2): boolean;
var
	distX, distY, absDistX, absDistY, halfW, halfH: Real;
	cornerDistSq: Real;
	temp, tempN: TVector2;
begin
	halfW:= rect.width * 0.5;
	halfH:= rect.height * 0.5;
	distX:= center.x - rect.x - halfW;
	distY:= center.y - rect.y - halfH;
	absDistX:= abs(distX);
	absDistY:= abs(distY);
	
	if absDistX > (halfW + radius) then begin
		result:= false;
		exit;
	end;
	if absDistY > (halfH + radius) then begin
		result:= false;
		exit;
	end;
	
	if absDistX <= halfW then begin
		result:= true;
		if distY < 0 then // okr�g ponad prostok�tem
			N.y:= rect.y -radius - center.y
		else
			N.y:= rect.y + rect.height + radius - center.y;
		N.x:= 0;
		exit;
	end;
	if absDistY <= halfH then begin
		result:= true;
		if distX < 0 then
			N.x:= rect.x - radius - center.x
		else
			N.x:= rect.x + rect.width + radius - center.x;
		N.y:=0;
		exit;
	end;
	
	cornerDistSq:= ((absDistX - halfW)*(absDistX - halfW))
				 + ((absDistY - halfH)*(absDistY - halfH));
		
	result:= cornerDistSq <= radius*radius;
	
	if (distX > 0) and (distY > 0) then begin
		N.x:= center.x - rect.x - rect.width;
		N.y:= center.y - rect.y - rect.height;
	end
	else if (distX > 0) and (distY < 0) then begin
		N.x:= center.x - rect.x - rect.width;
		N.y:= center.y - rect.y;
	end
	else if (distX < 0) and (distY > 0) then begin
		N.x:= center.x - rect.x;
		N.y:= center.y - rect.y - rect.height;
	end
	else if (distX < 0) and (distY < 0) then begin
		N.x:= center.x - rect.x;
		N.y:= center.y - rect.y;
	end;
	tempN:= n;
	tempN.Normalize;
	
	temp:= center - tempN*radius;
	N:= (center-N) - temp;
end;

function PointInRect( x, y: Real; rect: TRectF): boolean;
begin
	result:= (x >= rect.x) AND
      (x <= rect.x + rect.width) AND
      (y >= rect.y) AND
      (y <= rect.y + rect.height);
end;

function RectToRect( a, b: TRectF ): boolean;
begin
   result:= (a.x < b.x + b.width) AND
      (a.x + a.width > b.x) AND
      (a.y < b.y + b.height) AND
      (a.y + a.height > b.y);
end;

//-----------------------------------------
begin
end.