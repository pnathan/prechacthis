
shift_by_minuend(OldPosition, Times, NewPosition, NumberOfJugglers, Period) :-
	Minuend is Period rdiv NumberOfJugglers,
	NewPosition is OldPosition + Times * Period - truncate(Times * Minuend).
	

siteswap_position(Juggler, Position, SiteswapPosition, NumberOfJugglers, Period) :-	 
	shift_by_minuend(Position, Juggler, SiteswapPosition, NumberOfJugglers, Period).

siteswap_position_general(Position, SiteswapPosition, NumberOfJugglers, Period) :-
	siteswap_position_general(Position, SiteswapPosition, _Juggler, NumberOfJugglers, Period).
	
siteswap_position_general(Position, SiteswapPosition, Juggler, NumberOfJugglers, Period) :-
	throwing_juggler(Position, LocalPosition, Juggler, NumberOfJugglers, Period),
	siteswap_position(Juggler, LocalPosition, SiteswapPosition, NumberOfJugglers, Period).


all_club_siteswap_positions(Pattern, NumberOfJugglers, SiteswapPositions) :-
	averageNumberOfClubs(Pattern, AVClubs),
	ClubsMax is AVClubs * NumberOfJugglers - 1,
	findall(
		Position,
		(
			between(0, ClubsMax, Club),
			club_siteswap_position(Club, Pattern, Position, NumberOfJugglers)
		),
		SiteswapPositions
	).
	
all_club_siteswap_positions_and_jugglers(Pattern, NumberOfJugglers, SiteswapPositions) :-
	averageNumberOfClubs(Pattern, AVClubs),
	ClubsMax is AVClubs * NumberOfJugglers - 1,
	findall(
		[Juggler, Position],
		(
			between(0, ClubsMax, Club),
			club_siteswap_position(Club, Pattern, Position, Juggler, NumberOfJugglers)
		),
		SiteswapPositions
	).

club_siteswap_position(Club, Pattern, SiteswapPosition, NumberOfJugglers) :-
	club_siteswap_position(Club, Pattern, SiteswapPosition, _Juggler, NumberOfJugglers), !.
	
club_siteswap_position(Club, Pattern, SiteswapPosition, Juggler, NumberOfJugglers) :-
	averageNumberOfClubs(Pattern, AVClubs),
	NumberOfClubs is AVClubs * NumberOfJugglers,
	Club =< NumberOfClubs,
	orbits(Pattern, OrbitPattern),
	clubsInOrbits(Pattern, OrbitPattern, AVClubsInOrbits),
	multiply(AVClubsInOrbits, NumberOfJugglers, ClubsInOrbits),
	club_siteswap_position(Club, 0, SiteswapPosition, Juggler, NumberOfJugglers, OrbitPattern, ClubsInOrbits), !.

% !!! Multiplex ToDo	
club_siteswap_position(-1, PositionReal, SiteswapPosition, Juggler, NumberOfJugglers, OrbitPattern, _ClubsInOrbits) :-
	!,
	PositionBevor is PositionReal - 1,
	length(OrbitPattern, Period),
	siteswap_position_general(PositionBevor, SiteswapPosition, Juggler, NumberOfJugglers, Period).
club_siteswap_position(Position, PositionReal, SiteswapPosition, Juggler, NumberOfJugglers, OrbitPattern, ClubsInOrbits) :-
	length(OrbitPattern, Period),
	siteswap_position_general(PositionReal, SiteswapPosition0, _Juggler0, NumberOfJugglers, Period),
	ModPos is SiteswapPosition0 mod Period,
	nth0(ModPos, OrbitPattern, Orbit),
	club_siteswap_position_ChangeOrbits(Orbit, ClubsInOrbits, NewClubsInOrbits, Position, NextPosition),
	NextPositionReal is PositionReal + 1,
	club_siteswap_position(NextPosition, NextPositionReal, SiteswapPosition, Juggler, NumberOfJugglers, OrbitPattern, NewClubsInOrbits).

club_siteswap_position_ChangeOrbits(Orbit, ClubsInOrbits, ClubsInOrbits, Pos, Pos) :-
	number(Orbit),
	nth0(Orbit, ClubsInOrbits, 0), !.
club_siteswap_position_ChangeOrbits(Orbit, ClubsInOrbits, NewClubsInOrbits, Pos, NextPos) :-
	number(Orbit),!,
	nth0(Orbit, ClubsInOrbits, Clubs),
	ClubsNew is Clubs - 1,
	changeOnePosition(ClubsInOrbits, Orbit, ClubsNew, NewClubsInOrbits),
	NextPos is Pos - 1.
club_siteswap_position_ChangeOrbits([], ClubsInOrbits, ClubsInOrbits, Pos, NextPos) :- 
	NextPos is Pos - 1, !.
club_siteswap_position_ChangeOrbits([Orbit|MultiplexOrbits], ClubsInOrbits, NewClubsInOrbits, Pos, NextPos) :-
	club_siteswap_position_ChangeOrbits(Orbit, ClubsInOrbits, HeadClubsInOrbits, Pos, _),
	club_siteswap_position_ChangeOrbits(MultiplexOrbits, HeadClubsInOrbits, NewClubsInOrbits, Pos, NextPos).
	
zerosTillPos_general([p(0,0,0)|_Pattern], 0, _NumberOfJugglers, 1) :- !.
zerosTillPos_general(_Pattern, 0, _NumberOfJugglers, 0) :- !.
zerosTillPos_general(Pattern, Pos, NumberOfJugglers, NumberOf0) :-
	length(Pattern, Period),
	siteswap_position_general(Pos, SiteswapPosition, NumberOfJugglers, Period),
	ModPos is SiteswapPosition mod Period,
	nth0(ModPos, Pattern, p(0,0,0)),!,
	NextPos is Pos - 1,
	zerosTillPos_general(Pattern, NextPos, NumberOfJugglers, NumberOf0Befor),
	NumberOf0 is NumberOf0Befor + 1.
zerosTillPos_general(Pattern, Pos, NumberOfJugglers, NumberOf0) :-
	NextPos is Pos - 1,
	zerosTillPos_general(Pattern, NextPos, NumberOfJugglers, NumberOf0).

	

throwing_juggler(Position, LocalPosition, Juggler, NumberOfJugglers, Period) :-
	throwing_order_of_jugglers(NumberOfJugglers, Period, ThrowingOrder),
	Pos is Position mod NumberOfJugglers,
	nth0(Pos, ThrowingOrder, Juggler),
	LocalPosition is Position // NumberOfJugglers. 
	
throwing_order_of_jugglers(NumberOfJugglers, Period, ThrowingOrder) :-
	findall(
		DelayF,
		(
			between(1, NumberOfJugglers, Juggler),	
			RealDelay is (Period rdiv NumberOfJugglers) * (Juggler - 1),
			Delay is float_fractional_part(RealDelay),
			DelayF is float(Delay)
		),
		Delays
	), 
	JugglerMax is NumberOfJugglers - 1,
	numlist(0, JugglerMax, Jugglers),
	keysort(Jugglers, Delays, ThrowingOrder).

throw_time(ThrowingJuggler, Position, Time, NumberOfJugglers, Period) :-
	JugglerMax is NumberOfJugglers - 1,
	between(0, JugglerMax, ThrowingJuggler),
	Minuend is Period rdiv NumberOfJugglers,
	TimeTmp is float_fractional_part(ThrowingJuggler * Minuend) + Position, %% Bug in Prolog: ?- A is float(1 rdiv 5), A is 0.2. --> No !?!? 
	abs(TimeTmp - Time) < 10^(-12).
	
pass_to_juggler(PassingJuggler, Index, CatchingJuggler, NumberOfJugglers) :-  %% Juggler = 0,1,2,...,NumberOfJugglers-1
	CatchingJuggler is (PassingJuggler + Index) mod NumberOfJugglers.
	

pass_to(PassingJuggler, Position, Pass, LandingSiteswapPosition, NumberOfJugglers, Period) :-
	pass_to(PassingJuggler, Position, Pass, _, _, _, LandingSiteswapPosition, NumberOfJugglers, Period).

pass_to(PassingJuggler, Position, p(Pass,Index,_), ThrowingTime, LandingTime, CatchingJuggler, LandingSiteswapPosition, NumberOfJugglers, Period) :-
	%% PassingJuggler = 0,1,2,3,...
	throw_time(PassingJuggler, Position, ThrowingTime, NumberOfJugglers, Period),
	LandingTime is ThrowingTime + Pass,
	LandingPosition is truncate(LandingTime),
	pass_to_juggler(PassingJuggler, Index, CatchingJuggler, NumberOfJugglers),
	siteswap_position(CatchingJuggler, LandingPosition, LandingSiteswapPosition, NumberOfJugglers, Period).
pass_to(_PassingJuggler, _Position, [], _ThrowingTime, [], [], [], _NumberOfJugglers, _Period) :- !.
pass_to(PassingJuggler, Position, [MultiplexHead|Multiplex], ThrowingTime, [LandingTimeHead|LandingTime], [CatchingJugglerHead|CatchingJuggler], [LandingSiteswapPositionHead|LandingSiteswapPosition], NumberOfJugglers, Period) :-
	pass_to(PassingJuggler, Position, Multiplex, ThrowingTime, LandingTime, CatchingJuggler, LandingSiteswapPosition, NumberOfJugglers, Period),
	pass_to(PassingJuggler, Position, MultiplexHead, ThrowingTime, LandingTimeHead, CatchingJugglerHead, LandingSiteswapPositionHead, NumberOfJugglers, Period).



pass_info(PassingJuggler, Position, Pass, ThrowingTime, ThrowingSiteswapPosition, LandingTime, CatchingJuggler, LandingSiteswapPosition, NumberOfJugglers, Period) :-
	pass_to(PassingJuggler, Position, Pass, ThrowingTime, LandingTime, CatchingJuggler, LandingSiteswapPosition, NumberOfJugglers, Period),
	siteswap_position(PassingJuggler, Position, ThrowingSiteswapPosition, NumberOfJugglers, Period).
	


what_happens_at_point_in_time(PointInTime, Pattern, NumberOfJugglers, Action) :-
	length(Pattern, Period),
	Position is truncate(PointInTime),
	throw_time(ThrowingJuggler, Position, PointInTime, NumberOfJugglers, Period),
	siteswap_position(ThrowingJuggler, Position, ThrowingSiteswapPosition, NumberOfJugglers, Period),
	ThrowingPositionInPattern is (ThrowingSiteswapPosition mod Period),
	nth0(ThrowingPositionInPattern, Pattern, Throw),
	pass_info(ThrowingJuggler, Position, Throw, PointInTime, ThrowingSiteswapPosition, LandingTime, CatchingJuggler, LandingSiteswapPosition, NumberOfJugglers, Period),
	Action = [PointInTime, ThrowingJuggler, ThrowingSiteswapPosition, Throw, LandingTime, CatchingJuggler, LandingSiteswapPosition].


possible_point_in_time(PointInTime, NumberOfJugglers, Period) :-
	Minuend is Period rdiv NumberOfJugglers,
	JugglerMax is NumberOfJugglers - 1,
	PositionMax is Period - 1,
	between(0, JugglerMax, Juggler),
	between(0, PositionMax, Position),
	PointInTime is Position + float_fractional_part(Juggler * Minuend).

all_points_in_time(PointsInTime, NumberOfJugglers, Period) :-
	setof(Point, possible_point_in_time(Point, NumberOfJugglers, Period), PointsInTimeR),
	sort_list_of_expr(PointsInTimeR, PointsInTime).
	
time_between_throws(NumberOfJugglers, Period, Time) :-
	all_points_in_time(PointsInTime, NumberOfJugglers, Period),
	nth0(1, PointsInTime, Time).

	
what_happens([], _, _, []).
what_happens([Point|PointsInTime], Pattern, NumberOfJugglers, Action) :-
	findall(ThisAction, what_happens_at_point_in_time(Point, Pattern, NumberOfJugglers, ThisAction), ActionBag),
	what_happens(PointsInTime, Pattern, NumberOfJugglers, RestAction),
	append(ActionBag,RestAction,Action).



shortPointInTime(PointInTime, ShortPointInTime) :-
	ShortPointInTime is truncate(PointInTime*10)/10.

hand([], []) :- !.
hand([Head|List], [Hand|Hands]) :-
	!,
	hand(Head, Hand),
	hand(List, Hands).
hand(Position, a) :- even(Position),!.
hand(Position, b) :- odd(Position),!.

	
nextPeriodActionList([], _Period, []) :- !.
nextPeriodActionList([FirstAction|FirstPeriod], Period, [SecondAction|SecondPeriod]) :-
	FirstAction = [PointInTime, ThrowingJuggler, ThrowingSiteswapPosition, Throw, LandingTime, CatchingJuggler, LandingSiteswapPosition],
	SecondPointInTime is PointInTime + Period,
	SecondThrowingSiteswapPosition is ThrowingSiteswapPosition + Period,
	add(LandingTime, Period, SecondLandingTime),
	add(LandingSiteswapPosition, Period, SecondLandingSiteswapPosition),
	SecondAction = [SecondPointInTime, ThrowingJuggler, SecondThrowingSiteswapPosition, Throw, SecondLandingTime, CatchingJuggler, SecondLandingSiteswapPosition],
	nextPeriodActionList(FirstPeriod, Period, SecondPeriod).
	

	
% theory doesn't work for Multiplexes !!!!!!!!!
clubsInHand_old(Juggler, Hand, Period, ActionList, ClubsInHand) :-
	member(Hand, [a,b]),
	numberOfThrowsUntilFirstCatch(Juggler, Hand, Period, ActionList, ActionList, NumberOfThrows, _FirstCatch),
	ClubsInHand = NumberOfThrows.

%% old
listOfCatches(_,_,_,[],[]).
listOfCatches(CatchingJuggler, Hand, Period, [Action|ActionList], [Catch|ListOfCatches]) :-	
	not(nth1(4, Action, p(0,_,_))), % Throw not 0
	nth1(6, Action, CatchingJuggler),
	((		
		nth1(7, Action, CatchingSiteswapPosition),
		hand(CatchingSiteswapPosition, Hand),
		nth1(5, Action, Catch)
	);(
		odd(Period),
		nth1(5, Action, FirstCatch),
		Catch is FirstCatch + Period		
	)),
	!,
	listOfCatches(CatchingJuggler, Hand, Period, ActionList, ListOfCatches).
listOfCatches(CatchingJuggler, Hand, Period, [_|ActionList], ListOfCatches) :-	
	listOfCatches(CatchingJuggler, Hand, Period, ActionList, ListOfCatches).

%% old
firstCatch(Juggler, Hand, Period, ActionList, FirstCatch) :-
	member(Hand, [a,b]),
	listOfCatches(Juggler, Hand, Period, ActionList, ListOfCatches),
	min_of_list(FirstCatch, ListOfCatches).


%%%                 1              2                     3               4         5              6                    7
%%%  Action = [PointInTime, ThrowingJuggler, ThrowingSiteswapPosition, Throw, LandingTime, CatchingJuggler, LandingSiteswapPosition].

numberOfThrowsUntilFirstCatch(Juggler, Hand, Period, [], OldActionList, NumberOfThrows, FirstCatch) :- 
	nextPeriodActionList(OldActionList, Period, NewActionList),
	numberOfThrowsUntilFirstCatch(Juggler, Hand, Period, NewActionList, NewActionList, NumberOfThrows, FirstCatch),
	!.
numberOfThrowsUntilFirstCatch(Juggler, Hand, _, [Action|_ActionList], _OriginalAction, 0, FirstCatch) :- 
	nonvar(FirstCatch),
	nth1(1, Action, FirstCatch), % point of time is time of first catch
	nth1(2, Action, Juggler), % Juggler is throwing
	nth1(3, Action, ThrowingSiteswapPosition),
	hand(ThrowingSiteswapPosition, Hand), % Juggler is throwing with this hand
	!. 
numberOfThrowsUntilFirstCatch(Juggler, Hand, Period, [Action|ActionList], OriginalAction, NumberOfThrows, FirstCatch) :-	
	nth1(4, Action, p(0,_,_)), % throw is a 0
	!,
	numberOfThrowsUntilFirstCatch(Juggler, Hand, Period, ActionList, OriginalAction, NumberOfThrows, FirstCatch).
numberOfThrowsUntilFirstCatch(Juggler, Hand, Period, [Action|ActionList], OriginalAction, NewNumberOfThrows, OldFirstCatch) :-	
	nth1(2, Action, Juggler),   % Juggler is throwing
	nth1(3, Action, ThrowingSiteswapPosition),
	hand(ThrowingSiteswapPosition, Hand), % Juggler is throwing with this hand
	nth1(6, Action, CatchingJugglers),   % Juggler is catching
	memberOrEqual(Juggler, CatchingJugglers, Pos),
	not(nth1(4, Action, p(0,_,_))),
	nth1(7, Action, CatchingSiteswapPositions),
	memberOrEqual(CatchingSiteswapPosition, CatchingSiteswapPositions, Pos),
	hand(CatchingSiteswapPosition, Hand),
	nth1(5, Action, Catches), % Juggler is catching with this hand
	memberOrEqual(Catch, Catches, Pos),
	!,
	earlierCatch(OldFirstCatch, Catch, NewFirstCatch),
	numberOfThrowsUntilFirstCatch(Juggler, Hand, Period, ActionList, OriginalAction, OldNumberOfThrows, NewFirstCatch),	
	NewNumberOfThrows is OldNumberOfThrows + 1.
numberOfThrowsUntilFirstCatch(Juggler, Hand, Period, [Action|ActionList], OriginalAction, NewNumberOfThrows, FirstCatch) :-	
	nth1(2, Action, Juggler),   % Juggler is throwing
	nth1(3, Action, ThrowingSiteswapPosition),
	hand(ThrowingSiteswapPosition, Hand), % Juggler is throwing with this hand
	!,
	numberOfThrowsUntilFirstCatch(Juggler, Hand, Period, ActionList, OriginalAction, OldNumberOfThrows, FirstCatch),	
	NewNumberOfThrows is OldNumberOfThrows + 1.
numberOfThrowsUntilFirstCatch(Juggler, Hand, Period, [Action|ActionList], OriginalAction, NumberOfThrows, OldFirstCatch) :-	
	nth1(6, Action, Juggler),   % Juggler is catching
	not(nth1(4, Action, p(0,_,_))),
	nth1(7, Action, CatchingSiteswapPositions),
	memberOrEqual(CatchingSiteswapPosition, CatchingSiteswapPositions, Pos),
	hand(CatchingSiteswapPosition, Hand),
	nth1(5, Action, Catches), % Juggler is catching with this hand
	memberOrEqual(Catch, Catches, Pos),
	!,
	earlierCatch(OldFirstCatch, Catch, NewFirstCatch),
	numberOfThrowsUntilFirstCatch(Juggler, Hand, Period, ActionList, OriginalAction, NumberOfThrows, NewFirstCatch).
numberOfThrowsUntilFirstCatch(Juggler, Hand, Period, [_Action|ActionList], OriginalAction, NumberOfThrows, FirstCatch) :-	
	numberOfThrowsUntilFirstCatch(Juggler, Hand, Period, ActionList, OriginalAction, NumberOfThrows, FirstCatch).
	


%% new !!


%%%                 1              2                     3               4         5              6                    7
%%%  Action = [PointInTime, ThrowingJuggler, ThrowingSiteswapPosition, Throw, LandingTime, CatchingJuggler, LandingSiteswapPosition].

clubsInHand(ActionList, Period, NumberOfJugglers, NumberOfClubs, ClubsInHand) :-
	fill_lpt(ClubsInHandStart, 0, NumberOfJugglers),
	fill_lpt(LandingSitesStart, [], NumberOfJugglers),
	openActionList(ActionList, ActionListOpen),
	clubsInHand(ActionListOpen, ActionListOpen, Period, NumberOfJugglers, ClubsInHandStart, ClubsInHand, LandingSitesStart, _, 0, NumberOfClubs).

clubsInHand([], OriginalAction, Period, NumberOfJugglers, OldClubsInHand, NewClubsInHand, OldLandingSites, NewLandingSites, OldPIT, Clubs) :-
	nextPeriodActionList(OriginalAction, Period, NewActionList),
	clubsInHand(NewActionList, NewActionList, Period, NumberOfJugglers, OldClubsInHand, NewClubsInHand, OldLandingSites, NewLandingSites, OldPIT, Clubs).
clubsInHand([Action|_ActionList], _OriginalAction, _Period, _NumberOfJugglers, ClubsInHand, ClubsInHand, LandingSites, LandingSites, OldPIT, Clubs) :- %%% ????
	nth1(1, Action, PIT),
	PIT > OldPIT,
	ClubsInHand = [ClubsInHandA, ClubsInHandB],
	sumlist(ClubsInHandA, SumA),
	sumlist(ClubsInHandB, SumB),
	Clubs is SumA + SumB, !.
clubsInHand([Action|ActionList], OriginalAction, Period, NumberOfJugglers, OldClubsInHand, NewClubsInHand, OldLandingSites, NewLandingSites, _OldPIT, Clubs) :-
	calculateThrows(Action, OldClubsInHand, OldLandingSites, NumberOfJugglers, ClubsInHand),
	calculateCatches(Action, OldLandingSites, NumberOfJugglers, LandingSites),
	nth1(1, Action, PIT),
	clubsInHand(ActionList, OriginalAction, Period, NumberOfJugglers, ClubsInHand, NewClubsInHand, LandingSites, NewLandingSites, PIT, Clubs).


calculateThrows(Action, ClubsInHand, LandingSites, NumberOfJugglers, NewClubsInHand) :-
	Action = [PointInTime, ThrowingJuggler, ThrowingSiteswapPosition, Throw, _, _, _],
	hand(ThrowingSiteswapPosition, ThrowingHand),
	clubsThrown(Throw, NumberOfThrows),
	
	lpt_nth0(LandingSites, ThisLandingSites, ThrowingJuggler, ThrowingHand), 
	numberOfX(ThisLandingSites, PointInTime, NumberOfCatches),
	
	ThrowsMinusCatches is NumberOfThrows - NumberOfCatches,
	lpt_add(ClubsInHand, ThrowsMinusCatches, ThrowingJuggler, ThrowingHand, NumberOfJugglers, NewClubsInHand).
	
calculateCatches(Action, LandingSites, NumberOfJugglers, NewLandingSites) :-
	Action = [_, _, _, _, LandingTime, CatchingJuggler, LandingSiteswapPosition],
	hand(LandingSiteswapPosition, CatchingHand),
	lpt_append(LandingSites, LandingTime, CatchingJuggler, CatchingHand, NumberOfJugglers, NewLandingSites).

openActionList([], []) :- !.
openActionList([Action|ActionList], ActionListOpened) :-
	nth0(6, Action, CatchingJuggler),
	is_list(CatchingJuggler), !,
	openAction(Action, ActionOpend),
	openActionList(ActionList, ActionRestOpened), 
	append(ActionOpend, ActionRestOpened, ActionListOpened).	
openActionList([Action|ActionList], [Action|ActionListOpened]) :-
	openActionList(ActionList, ActionListOpened).

openAction(Action, ActionOpend) :-
	Action = [PointInTime, ThrowingJuggler, ThrowingSiteswapPosition, [Throw], [LandingTime], [CatchingJuggler], [LandingSiteswapPosition]],!,
	ActionOpend = [[PointInTime, ThrowingJuggler, ThrowingSiteswapPosition, Throw, LandingTime, CatchingJuggler, LandingSiteswapPosition]].
openAction(Action, [NewAction|ActionOpend]) :-
	Action = [PointInTime, ThrowingJuggler, ThrowingSiteswapPosition, Throws, LandingTimes, CatchingJugglers, LandingSiteswapPositions],
	Throws = [Throw|ThrowTail],
	LandingTimes = [LandingTime|LandingTimeTail],
	CatchingJugglers = [CatchingJuggler|CatchingJugglerTail],
	LandingSiteswapPositions = [LandingSiteswapPosition|LandingSiteswapPositionTail],
	NewAction = [PointInTime, ThrowingJuggler, ThrowingSiteswapPosition, Throw, LandingTime, CatchingJuggler, LandingSiteswapPosition],
	ActionRest = [PointInTime, ThrowingJuggler, ThrowingSiteswapPosition, ThrowTail, LandingTimeTail, CatchingJugglerTail, LandingSiteswapPositionTail],
	openAction(ActionRest, ActionOpend).


clubsThrown(Multiplex, Clubs) :-
	is_list(Multiplex), !,
	length(Multiplex, Clubs).
clubsThrown(Var, 0) :-
	var(Var), !.
clubsThrown(p(Zero,_,_), 0) :-
	number(Zero), 
	Zero = 0, !.
clubsThrown(Zero, 0) :-
	number(Zero), 
	Zero = 0, !.
clubsThrown(_, 1).

	
earlierCatch(Catch1, Catch2, Catch1) :-
	nonvar(Catch1),
	nonvar(Catch2),
	Catch1 < Catch2,!.
earlierCatch(Catch1, Catch2, Catch2) :-
	nonvar(Catch1),
	nonvar(Catch2),
	Catch1 > Catch2,!.
earlierCatch(Catch1, Catch2, Catch2) :-
	var(Catch1),
	nonvar(Catch2),!.
earlierCatch(Catch1, Catch2, Catch1) :-
	nonvar(Catch1),
	var(Catch2),!.
	
%doesn't make sense anymore!!!	
testClubDistribution(ActionList, NumberOfJugglers, Period, ClubsInPattern) :-
	JugglerMax is NumberOfJugglers - 1,
	findall(
		ClubsInHand, 
		(
			between(0, JugglerMax, Juggler),
			member(Hand, [a,b]),
			clubsInHand(Juggler, Hand, Period, ActionList, ClubsInHand)
		),
		ListOfClubs
	),
	sumlist(ListOfClubs, ClubsInPattern).
	
	
applyNewSwaps(OldSwapList, NewSwaps, SwapList) :-
	intersection(OldSwapList, NewSwaps, Intersection),
	subtract(OldSwapList, Intersection, RemainingOld),
	subtract(NewSwaps, Intersection, RemainingNew),
	union(RemainingOld, RemainingNew, SwapList).
	

club_distribution(Pattern, NumberOfJugglers, ClubDistribution) :-
	all_club_siteswap_positions_and_jugglers(Pattern, NumberOfJugglers, SiteswapPositions),
	siteswapPosition2ClubDistribution(SiteswapPositions, NumberOfJugglers, ClubDistribution).

siteswapPosition2ClubDistribution([], NumberOfJugglers, ClubDistribution) :-
	listOf([0,0], NumberOfJugglers, ClubDistribution), !.
siteswapPosition2ClubDistribution([[Juggler|Position]|SiteswapPositions], NumberOfJugglers, ClubDistribution) :-	
	siteswapPosition2ClubDistribution(SiteswapPositions, NumberOfJugglers, OldClubDistribution),
	Hand is Position mod 2,
	nth0(Juggler, OldClubDistribution, OldHands),
	nth0(Hand, OldHands, OldClubs),
	Clubs is OldClubs + 1,
	changeOnePosition(OldHands, Hand, Clubs, NewHands),
	changeOnePosition(OldClubDistribution, Juggler, NewHands, ClubDistribution).
	
	
	
	
%%% --- print ---

print_pattern_info(Pattern, NumberOfJugglers) :-
	print_pattern_info(Pattern, NumberOfJugglers, [], [], '').
print_pattern_info(PatternWithShortPasses, NumberOfJugglers, OldSwapList, NewSwaps, BackURL) :-
	applyNewSwaps(OldSwapList, NewSwaps, SwapList),
	length(PatternWithShortPasses, Period),
	maxHeight(PatternWithShortPasses, ShortMaxHeight),
	MaxHeight is truncate(ShortMaxHeight) + 1,
	convertShortPasses(PatternWithShortPasses,Period,NumberOfJugglers,MaxHeight,Pattern),
	all_points_in_time(PointsInTime, NumberOfJugglers, Period),
	what_happens(PointsInTime, Pattern, NumberOfJugglers, ActionList),
	writePattern(Pattern, PatternWithShortPasses, NumberOfJugglers, BackURL),
	writePatternInfo(PatternWithShortPasses, PointsInTime, ActionList, NumberOfJugglers, Period, BackURL),
	writeOrbitInfo(Pattern, PatternWithShortPasses, NumberOfJugglers, BackURL),
	%averageNumberOfClubs(Pattern, AverageNumberOfClubs),
	%NumberOfClubs is AverageNumberOfClubs * NumberOfJugglers,
	%(testClubDistribution(ActionList, NumberOfJugglers, Period, NumberOfClubs) ->
	%	true;
	%	format("<p class='info_clubdistri'>Not a possible starting point without extra throws ahead.<br>Number of clubs not correct!<br>Try to turn pattern.</p>\n\n")
	%),
	club_distribution(Pattern, NumberOfJugglers, ClubDistribution),
	JugglerMax is NumberOfJugglers - 1,
	forall(between(0, JugglerMax, Juggler), writeJugglerInfo(Juggler, ActionList, SwapList, ClubDistribution, NumberOfJugglers, Period, PatternWithShortPasses, BackURL)),
	writeJoepassLink(PatternWithShortPasses, NumberOfJugglers, SwapList).

	
writePatternInfo(PatternWithShortPasses, PointsInTime, ActionList, NumberOfJugglers, Period, BackURL) :-
	format("<table class='info_pattern_table' align='center'>\n"),
/*	
	format("<td class='info_lable_swap'>point in time:</td>\n"),
	forall(member(Point, PointsInTime), (shortPointInTime(Point, ShortPoint), format("<td class='info_pointintime'>~w</td>\n", [ShortPoint]))),
	format("</tr>\n"),
*/
	JugglerMax is NumberOfJugglers - 1,
	forall(between(0, JugglerMax, Juggler), print_jugglers_throws(Juggler, ActionList, PointsInTime, NumberOfJugglers, Period)),
	(amountOfPasses(PatternWithShortPasses, 0) ->
		(
			NumberOfJugglersPlus is NumberOfJugglers + 1,
			NumberOfJugglersMinus is NumberOfJugglers - 1,
			pattern_to_string(PatternWithShortPasses, PatternString),
			format("<tr>"),
			format("<td class='info_lable'><a href='./info.php?pattern=~s&persons=~w&back=~w' class='small'>add</a>", [PatternString, NumberOfJugglersPlus, BackURL]),
			format("&nbsp;|&nbsp;"),
			format("<a href='./info.php?pattern=~s&persons=~w&back=~w' class='small'>sub</a></td>\n", [PatternString, NumberOfJugglersMinus, BackURL]),
			format("<td colspan='~w'>&nbsp;</td>", [Period]),
			format("</tr>")
		); true
	),
	format("</table>\n\n").


writeJugglerInfo(Juggler, ActionList, SwapList, ClubDistribution, NumberOfJugglers, Period, Pattern, BackURL) :-
	ColspanLong is Period,
	ColspanShort is Period - 1,
	jugglerShown(Juggler, JugglerShown),
	nth0(Juggler, ClubDistribution, [ClubsHandA, ClubsHandB]),
	handShown(Juggler, a, SwapList, HandShownA),
	handShownLong(HandShownA, HandShownALong),
	handShown(Juggler, b, SwapList, HandShownB),
	handShownLong(HandShownB, HandShownBLong),
	format("<table class='info_juggler_table'>"),
	format("<tr>\n"),
	writeSwapLink(Juggler, SwapList, NumberOfJugglers, Pattern, BackURL),
	format("<th class='info_title' colspan=~w>juggler ~w</th>\n", [ColspanLong, JugglerShown]),
	format("</tr>\n"),
	format("<tr>\n"),
	format("<td class='info_lable'>clubs in ~w hand:</td>\n", [HandShownALong]),	
	format("<td class='info_clubs'>~w</td>\n", [ClubsHandA]),
	format("<td class='info_clubs' colspan=~w>&nbsp;</th>\n", [ColspanShort]),
	format("</tr>\n"),
	format("<tr>\n"),
	format("<td class='info_lable'>clubs in ~w hand:</td>\n", [HandShownBLong]),	
	format("<td class='info_clubs'>~w</td>\n", [ClubsHandB]),
	format("<td class='info_clubs' colspan=~w>&nbsp;</th>\n", [ColspanShort]),
	format("</tr>\n"),
	format("<tr>\n"),
	format("<td class='info_lable'>throwing hand:</td>\n"),
	forall(member(Action, ActionList), print_throwing_hand(Juggler, Action, SwapList)),
	format("</tr>\n"),
	format("<tr>\n"),
	format("<td class='info_lable'>throw:</td>\n"),
	forall(member(Action, ActionList), print_throw(Juggler, Action, NumberOfJugglers, Period)),
	format("</tr>\n"),
	format("<tr>\n"),
	format("<td class='info_lable'>cross/tramline:</td>\n"),
	forall(member(Action, ActionList), print_cross_tramline(Juggler, Action, SwapList)),
	format("</tr>\n"),
	format("<tr>\n"),
	format("<td class='info_lable'>catching juggler:</td>\n"),
	forall(member(Action, ActionList), print_catching_juggler(Juggler, Action)),
	format("</tr>\n"),
	format("<tr>\n"),
	format("<td class='info_lable'>catching hand:</td>\n"),
	forall(member(Action, ActionList), print_catching_hand(Juggler, Action, SwapList)),
	format("</tr>\n"),
/*
	format("<tr>\n"),
	format("<td class='info_lable'>throwing time:</td>\n"),
	forall(member(Action, ActionList), print_throwing_time(Juggler, Action)),
	format("</tr>\n"),
	format("<tr>\n"),
	format("<td class='info_lable'>landing time:</td>\n"),
	forall(member(Action, ActionList), print_landing_time(Juggler, Action)),
	format("</tr>\n"),
*/
	format("</table>\n\n").
	
writePattern(Pattern, PatternWithShortPasses, NumberOfJugglers, BackURL) :-
	format("<table class='info_bigSwap_table' align='center'>\n"),
	writePrechacThisLinks(Pattern, up, NumberOfJugglers, BackURL),
	writeBigSwapAndRotations(Pattern, PatternWithShortPasses, NumberOfJugglers, BackURL),
	writePrechacThisLinks(Pattern, down, NumberOfJugglers, BackURL),
	format("</table>\n\n").
	
writeSwapLink(Juggler, SwapList, NumberOfJugglers, Pattern, BackURL) :-
	NewSwaps = [Juggler],
	pattern_to_string(Pattern, PatternStr),
	format("<td class='info_swaplink'><a href='info.php?pattern=~s&persons=~w&swap=~w&newswap=~w&back=~w' class='small'>swap hands</a></td>\n", [PatternStr, NumberOfJugglers, SwapList, NewSwaps, BackURL]).

writeBigSwapAndRotations(Pattern, PatternWithShortPasses, NumberOfJugglers, BackURL) :-
	rotate_left(PatternWithShortPasses, PatternRotatedLeft),
	pattern_to_string(PatternRotatedLeft, PatternRotatedLeftStr),
	rotate_right(PatternWithShortPasses, PatternRotatedRight),
	pattern_to_string(PatternRotatedRight, PatternRotatedRightStr),
	format(string(ArrowLeft), "<img src='./images/left_arrow.png' alt='rotate left' border=0>", []),
	format(string(ArrowRight), "<img src='./images/right_arrow.png' alt='rotate right' border=0>", []),
	format("<tr>\n"),
	format("<td class='info_left_arrow'><a href='./info.php?pattern=~s&persons=~w&back=~w' title='rotate left'>~w</a></td>\n", [PatternRotatedLeftStr,NumberOfJugglers,BackURL,ArrowLeft]),
	writeBigSwap(Pattern, NumberOfJugglers),
	format("<td class='info_right_arrow'><a href='./info.php?pattern=~s&persons=~w&back=~w' title='rotate right'>~w</a></td>\n", [PatternRotatedRightStr,NumberOfJugglers,BackURL,ArrowRight]),
	format("</tr>\n").
	
writeBigSwap(Throws) :-
	concat_atom(Throws, '</h1></td><td class="big_swap"><h1 class="big_swap">', Swap),
	format("<td class='big_swap'><h1 class='big_swap'>"),
	format(Swap),
	format("</h1></td>\n").

writeBigSwap(Throws, Persons) :-
	length(Throws, Length),
    convertP(Throws, ThrowsP, Length, Persons),
	magicPositions(Throws, Persons, MagicPositions),
	convertMagic(ThrowsP, MagicPositions, ThrowsPM),
	convertMultiplex(ThrowsPM, ThrowsPMM, '</h1></td><td class="big_swap"><h1 class="big_swap">'),
    writeBigSwap(ThrowsPMM).
	

writePrechacThisLinks(Pattern, UpDown, NumberOfJugglers, BackURL) :-
	posList(Pattern, PosList),
	format("<tr><td>&nbsp;</td>\n"),
	forall(member(Pos, PosList), 
		(
			prechacThis(Pattern, Pos, UpDown, NumberOfJugglers, NewPattern),
			writePrechacThisLink(NewPattern, UpDown, NumberOfJugglers, BackURL)
		)
	),
	format("<td>&nbsp;</td></tr>\n").
	
writePrechacThisLink(false, _UpDown, _NumberOfJugglers, _BackURL) :-
	!,
	format("<td class='prechacthis_link'>"),
	format("&nbsp;"),
	format("</td>\n").
writePrechacThisLink(Pattern, UpDown, NumberOfJugglers, BackURL) :-
	float_to_shortpass(Pattern, PatternShort),
	pattern_to_string(PatternShort, PatternString),
	arrowUpDown(UpDown, ArrowUpDown),
	format("<td class='prechacthis_link'>"),
	format("<a href='./info.php?pattern=~s&persons=~w&back=~w' title='PrechacThis ~w'>~s</a>", [PatternString, NumberOfJugglers, BackURL, UpDown, ArrowUpDown]),
	format("</td>\n").

arrowUpDown(up, String) :-
	format(string(String), "<img src='./images/up.png' alt='up' border=0>", []).
arrowUpDown(down, String) :-
	format(string(String), "<img src='./images/down.png' alt='down' border=0>", []).
	

writeOrbitInfo(Pattern, PatternWithShortPasses, NumberOfJugglers, BackURL) :-
	orbits(Pattern, OrbitPattern),
	magicPositions(Pattern, NumberOfJugglers, MagicPositions),
	length(Pattern, Period),
	convertP(PatternWithShortPasses, PatternP, Period, NumberOfJugglers),
	convertMagic(PatternP, MagicPositions, PatternPM),
	flatten(OrbitPattern, OrbitsFlat),
	list_to_set(OrbitsFlat, OrbitsSet),
	sort(OrbitsSet, Orbits),
	format("<table class='info_pattern_table' align='center'>\n"),
	Colspan is Period,
	averageNumberOfClubs(Pattern, AVClubs),
	Clubs is AVClubs * NumberOfJugglers,
	format("<td class='info_title' colspan=~w>orbits</td><td class='info_right_info'>~w clubs</td><td>&nbsp;</td>\n", [Colspan, Clubs]),
	forall(member(Orbit, Orbits), writeThisOrbitInfo(OrbitPattern, Orbit, Pattern, NumberOfJugglers, PatternPM, BackURL)),
	format("</table>\n\n").
	
writeThisOrbitInfo(OrbitPattern, Orbit, Pattern, NumberOfJugglers, PatternPM, BackURL) :-	
	clubsInOrbit(Pattern, OrbitPattern, Orbit, ClubsAV),
	Clubs is ClubsAV * NumberOfJugglers,
	justThisOrbit(PatternPM, OrbitPattern, Orbit, PatternPrint, print),
	convertMultiplex(PatternPrint, PatternPrintM, '&nbsp;'),
	concat_atom(PatternPrintM, '</td><td class="info_throw">', Swap),
	format("<tr>\n"),
	format("<td class='info_throw'>"),
	format(Swap),
	format("</td><td class='info_right_info'>~w</td>\n", [Clubs]),
	(Clubs > 0 -> 
		(
			killOrbit(Pattern, Orbit, PatternK),
			float_to_shortpass(PatternK, PatternKShort),
			pattern_to_string(PatternKShort, PatternKString),
			format("<td><a href='./info.php?pattern=~s&persons=~w&back=~w' class='small'>kill</a></td>\n", [PatternKString, NumberOfJugglers, BackURL])
		);
		format("<td>&nbsp;</td>\n")
	),
	format("</tr>\n").

writeOrbits(Pattern, NumberOfJugglers) :-
	orbits(Pattern, Orbits),
	orbitShown(Orbits, OrbitsShown),
	clubsInOrbits(Pattern, Orbits, AvClubs),
	multiply(AvClubs, NumberOfJugglers, Clubs),	
	concat_atom(OrbitsShown, '</td><td class="info_orbits">', OrbitsTDs),
	format("<tr>\n<td class='info_lable'>Orbits:</td>\n<td class='info_orbits'>"),
	format(OrbitsTDs),
	format("</td>\n<td>&nbsp;</td>\n</tr>\n"),
	length(Pattern, Length),
	Colspan is Length + 2,
	format("<tr><td colspan='~w'>", [Colspan]),
	print(Clubs),
	format("</td></tr>\n").
	
writeJoepassLink(Pattern, NumberOfJugglers, SwapList) :-
	pattern_to_string(Pattern, PatternStr),
	jp_filename(Pattern, FileName),
	format("<div class='jp_link'>\n"),
	format("<form action='./joepass.php' method='post'>\n"),
	format("<input type='hidden' name='pattern' value='~s'>\n", [PatternStr]),
	format("<input type='hidden' name='persons' value='~w'>\n", [NumberOfJugglers]),
	format("<input type='hidden' name='file' value='~w'>\n", [FileName]),
	format("<input type='hidden' name='swap' value='~w'>\n", [SwapList]),
	format("JoePass! file:&nbsp;\n"),
	format("<select name='download' size='1'>"),
	format("<option value='on'>download</option>"),
	format("<option value='off'>show</option>"),
	format("</select>\n"),
	format("&nbsp;"),
	format("<select name='style' size='1'>"),
	format("<option value='normal'>face to face</option>"),
	format("<option value='shortdistance'>short distance</option>"),
	format("<option value='sidebyside'>side by side</option>"),
	format("</select>\n"),
	format("&nbsp;"),
	format("<input type='submit' value='go'>\n"),
	format("</form>\n"),
	%format("<a href='joepass.php?pattern=~s&persons=~w&file=~w&swap=~w'>show</a>", [PatternStr, NumberOfJugglers, FileName, SwapList]),
	%format("/"),
	%format("<a href='joepass.php?pattern=~s&persons=~w&file=~w&swap=~w&download=on'>download</a>", [PatternStr, NumberOfJugglers, FileName, SwapList]),
	%format(" JoePass! file\n"),
	format("</div>\n").
	
	
print_jugglers_throws(Juggler, ActionList, PointsInTime, NumberOfJugglers, Period) :-
	format("<tr>\n"),
	jugglerShown(Juggler, JugglerShown),
	format("<td class='info_lable_swap'>juggler ~w:</td>\n", [JugglerShown]),
	forall(member(Point, PointsInTime), print_jugglers_point_in_time(Juggler, Point, ActionList, NumberOfJugglers, Period)),
	format("</tr>\n").

print_jugglers_point_in_time(Juggler, PointInTime, ActionList, NumberOfJugglers, Period) :-
	member(Action, ActionList),
	nth1(2, Action, Juggler),
	nth1(1, Action, PointInTime),!,
	nth1(4, Action, Throw),
	convertP(Throw, ThrowP, Period, NumberOfJugglers),
	format("<td class='info_throw'>"),
	format_list(ThrowP),
	format("</td>\n").
print_jugglers_point_in_time(_, _, _, _, _) :-
	format("<td class='info_throw'>&nbsp;</td>\n").



%%%  Action = [PointInTime, ThrowingJuggler, ThrowingSiteswapPosition, Throw, LandingTime, CatchingJuggler, LandingSiteswapPosition].



print_throw(ThrowingJuggler, Action, NumberOfJugglers, Period) :-	
	nth1(2, Action, ThrowingJuggler),!,
	nth1(4, Action, Throw),
	convertP(Throw, ThrowP, Period, NumberOfJugglers),
	format("<td class='info_throw'>"),
	format_list(ThrowP),
	format("</td>\n").
print_throw(_, _, _, _).
	
print_throwing_time(ThrowingJuggler, Action) :-
	nth1(2, Action, ThrowingJuggler),!,
	nth1(1, Action, Time),
	shortPointInTime(Time, ShortTime),
	format("<td class='info_pointintime'>~w</td>\n", [ShortTime]).
print_throwing_time(_, _).

print_throwing_hand(ThrowingJuggler, Action, SwapList) :-
	nth1(2, Action, ThrowingJuggler),!,
	nth1(3, Action, ThrowingSiteswapPosition),
	hand(ThrowingSiteswapPosition, Hand),
	handShown(ThrowingJuggler, Hand, SwapList, HandShown),
	format("<td class='info_hand'>~w</td>\n", [HandShown]).
print_throwing_hand(_, _, _).

print_cross_tramline(ThrowingJuggler, Action, SwapList) :-
	nth1(2, Action, ThrowingJuggler),!,
	format("<td class='info_cross'>"),
	print_the_cross(ThrowingJuggler, Action, SwapList),
	format("</td>\n").
print_cross_tramline(_, _, _).



print_the_cross(ThrowingJuggler, Action, _SwapList) :-
	nth1(6, Action, ThrowingJuggler),!, % self
	format("&nbsp;").
print_the_cross(ThrowingJuggler, Action, SwapList) :-
	nth1(6, Action, CatchingJugglers),
	is_list(CatchingJugglers), !,  % Multiplex
	nth1(3, Action, ThrowingSiteswapPosition),
	nth1(7, Action, CatchingSiteswapPositions),
	hand(ThrowingSiteswapPosition, ThrowingHand),
	hand(CatchingSiteswapPositions, CatchingHands),
	handShown(ThrowingJuggler, ThrowingHand, SwapList, ThrowingHandShown),
	handShown(CatchingJugglers, CatchingHands, SwapList, CatchingHandsShown),
	findall(
		CrossOrTram,
		(
			nth0(Pos, CatchingJugglers, CatchingJuggler),
			nth0(Pos, CatchingHandsShown, CatchingHandShown),
			cross_or_tramline(ThrowingJuggler, CatchingJuggler, ThrowingHandShown, CatchingHandShown, CrossOrTram)
		),
		CrossOrTramList
	),
	format_list(CrossOrTramList, w).
print_the_cross(ThrowingJuggler, Action, SwapList) :-
	nth1(3, Action, ThrowingSiteswapPosition),
	nth1(6, Action, CatchingJuggler),
	nth1(7, Action, CatchingSiteswapPosition),
	hand(ThrowingSiteswapPosition, ThrowingHand),
	hand(CatchingSiteswapPosition, CatchingHand),
	handShown(ThrowingJuggler, ThrowingHand, SwapList, ThrowingHandShown),
	handShown(CatchingJuggler, CatchingHand, SwapList, CatchingHandShown),
	cross_or_tramline(ThrowingJuggler, CatchingJuggler, ThrowingHandShown, CatchingHandShown, CrossOrTram),
	format(CrossOrTram).


cross_or_tramline(Juggler, Juggler, _HandA, _HandB, '&nbsp;') :- !.
cross_or_tramline(_TJuggler, _CJuggler, Hand, Hand, 'X') :- !.
cross_or_tramline(_TJuggler, _CJuggler, _HandA, _HandB, '||') :- !.


print_catching_juggler(ThrowingJuggler, Action) :-
	nth1(2, Action, ThrowingJuggler),!,
	nth1(6, Action, CatchingJuggler),
	jugglerShown(CatchingJuggler, JugglerShown),
	format("<td class='info_juggler'>"),
	format_list(JugglerShown),
	format("</td>\n").
print_catching_juggler(_, _).
	
print_catching_hand(ThrowingJuggler, Action, SwapList) :-
	nth1(2, Action, ThrowingJuggler),!,
	nth1(6, Action, CatchingJuggler),
	nth1(7, Action, CatchingSiteswapPosition),
	hand(CatchingSiteswapPosition, Hand),
	handShown(CatchingJuggler, Hand, SwapList, HandShown),
	format("<td class='info_hand'>"),
	format_list(HandShown),
	format("</td>\n").
print_catching_hand(_, _, _).


print_landing_time(ThrowingJuggler, Action) :-
	nth1(2, Action, ThrowingJuggler),!,
	nth1(5, Action, Time),
	shortPointInTime(Time, ShortTime),
	format("<td class='info_pointintime'>~w</td>\n", [ShortTime]).
print_landing_time(_, _).


jugglerShown([], []) :- !.
jugglerShown([Juggler|ListJuggler], [Shown|ListShown]) :-
	!,
	jugglerShown(Juggler, Shown),
	jugglerShown(ListJuggler, ListShown).
jugglerShown(Juggler, JugglerShown) :-
	JugglerList = ['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'],
	nth0(Juggler, JugglerList, JugglerShown).

orbitShown([], []) :- !.
orbitShown([Orbit|ListOrbit], [Shown|ListShown]) :-
	!,
	orbitShown(Orbit, Shown),
	orbitShown(ListOrbit, ListShown).
orbitShown(Orbit, OrbitShown) :-
	OrbitList = ['a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z'],
	nth0(Orbit, OrbitList, OrbitShown).	
	
	
%% handShown(number, char, _List, char)	  
%% handShown(number, List, _List, List)  - throwing Juggler
%% handShown(List, List, _List, List)    - catching Jugglers

handShown(Juggler, [], _, []) :- number(Juggler), !.
handShown(Juggler, [Hand|HandList], SwapList, [HandShown|ShownList]) :-
	number(Juggler),!,
	handShown(Juggler, Hand, SwapList, HandShown),
	handShown(Juggler, HandList, SwapList, ShownList).
handShown([], [], _, []) :- !.
handShown([Juggler|Jugglers], [Hand|Hands], SwapList, [Shown|ShownList]) :-
	handShown(Juggler, Hand, SwapList, Shown),
	handShown(Jugglers, Hands, SwapList, ShownList).
handShown(Juggler, a, SwapList, l) :-
	member(Juggler, SwapList), !.
handShown(Juggler, a, SwapList, r) :-	
	not(member(Juggler, SwapList)), !.
handShown(Juggler, b, SwapList, r) :-
	member(Juggler, SwapList), !.
handShown(Juggler, b, SwapList, l) :- 
	not(member(Juggler, SwapList)), !.

handShownLong(r, right) :- !.
handShownLong(l, left) :- !.

format_list(List) :- format_list(List, w).

% ToDo !!!
format_list(List, _) :-
	is_list(List),
	justSpaces(List),!,
	format("&nbsp;").
format_list([], _) :- !.
format_list([Head|List], w) :-
	!,
	format("[~w", [Head]),
	format_restOfList(List, w),
	format("]").
format_list(X, w) :-
	format("~w", [X]).
format_list([Head|List], s) :-
	!,
	format("[~s", [[Head]]),
	format_restOfList(List, s),
	format("]").
format_list(X, s) :-
	format("~s", [[X]]).

format_restOfList([], _) :- !.
format_restOfList([Head|Tail], Mode) :-
	format("&nbsp;"),
	format_list(Head, Mode),
	format_restOfList(Tail, Mode).
	
