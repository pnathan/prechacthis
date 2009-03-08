:- module(siteswap_constraints, 
	[
		siteswap/14,
		test_constraint_not_fillable,
		passesMin/2,
		passesMax/2,
		amountOfPasses/2,
		dontcontain/2
	]
).


:- use_module(helpers).
:- use_module(siteswap_helpers).
:- use_module(siteswap_preprocessing).

:- use_module(siteswap_engine).
:- use_module(siteswap_multiplex).



:- dynamic
	constraintChecked/1.

siteswap(OutputPattern, NumberOfJugglers, Objects, Length, MaxHeight, PassesMin, PassesMax, ContainString, DontContainString, ClubDoesString, ReactString, SyncString, JustString, ContainMagic) :-
	initConstraintCheck,
	constraint(Pattern, Length, NumberOfJugglers, MaxHeight, ContainString, ClubDoesString, ReactString, SyncString, JustString, ContainMagic),
	%preprocessMultiplexes(Pattern),
	constraint_fillable(Pattern, NumberOfJugglers, Objects, MaxHeight),
	siteswap(NumberOfJugglers, Objects, MaxHeight, PassesMin, PassesMax, Pattern),
	catch(
		preprocessConstraint(DontContainString, negativ, Length, NumberOfJugglers, MaxHeight, DontContain),
		constraint_unclear,
		throw(constraint_unclear('"exclude"'))
	),
	forall(member(DontContainPattern, DontContain), dontContainRotation(Pattern, DontContainPattern)),
	orderMultiplexes(Pattern, PatternM),
	rotateHighestFirst(PatternM, OutputPattern).

initConstraintCheck :- 
	retractall(constraintChecked(_)),
	forall(recorded(constraint_fillable, _, R), erase(R)),!.

constraint(Constraint, Length, _Persons, _Max, [], [], [], [], [], 0) :-
	length(Constraint, Length),!.
constraint(Constraint, Length, _Persons, _Max, "", "", "", "", "", 0) :-
	length(Constraint, Length),!.
constraint(Constraint, Length, _Persons, _Max, '', '', '', '', '', 0) :-
	length(Constraint, Length),!.
constraint(Constraint, Length, Persons, Max, Contain, ClubDoes, React, Sync, Just, ContainMagic) :-
	mergeConstraints(Constraint, Length, Persons, Max, Contain, ClubDoes, React, Sync, Just, ContainMagic),
	not(supConstraintChecked(Constraint)),
	asserta(constraintChecked(Constraint)).
constraint(_Constraint, _Length, _Persons, _Max, _Contain, _ClubDoes, _React, _Sync, _Just, _Magic) :-
	recorda(constraint_fillable, false), fail.
	
supConstraintChecked(Constraint) :-
	constraintChecked(SupConstraint),
	isRotatedSubConstraint(Constraint, SupConstraint).
	
constraint_fillable(Constraint, NumberOfJugglers, Objects, MaxHeight) :- 
	averageNumberOfClubs(Constraint, ClubsInConstraintAV),
	length(Constraint, Period),
	numberOfVars(Constraint, NumberOfVars),
	MaxToAddAV is NumberOfVars * MaxHeight / Period,
	Objects =< (ClubsInConstraintAV + MaxToAddAV) * NumberOfJugglers, !,
	recorda(constraint_fillable, true).
constraint_fillable(_Constraint, _NumberOfJugglers, _Objects, _MaxHeight) :-
	recorda(constraint_fillable, false), fail.
	
test_constraint_not_fillable :-	
	findall(B, (recorded(constraint_fillable, B, R), erase(R)), ListOfBool),
	ListOfBool \= [],
	not(
		memberchk(true, ListOfBool)
	), !.
	
	
mergeConstraints(ConstraintRotated, Length, Persons, Max, ContainString, ClubDoesString, ReactString, SyncString, JustString, ContainMagic) :-
	length(MagicPattern, Length),
	(ContainMagic = 1 ->	
		(
			containsMagicOrbit(MagicPattern, Persons, Max)
		);
		true
	),
	catch(
		preprocessConstraint(ContainString, positiv, Length, Persons, Max, ContainConstraints),
		constraint_unclear,
		throw(constraint_unclear('"contain"'))
	),
	catch(
		preprocessConstraint(ClubDoesString, positiv, Length, Persons, Max, ClubDoesConstraints),
		constraint_unclear,
		throw(constraint_unclear('"club does"'))
	),
	catch(
		preprocessConstraint(ReactString, positiv, Length, Persons, Max, ReactConstraints),
		constraint_unclear,
		throw(constraint_unclear('"react"'))
	),
	catch(
		preprocessConstraint(SyncString, positiv, Length, Persons, Max, SyncConstraints),
		constraint_unclear,
		throw(constraint_unclear('"sync throws"'))
	),
	catch(
		preprocessConstraint(JustString, positiv, Length, Persons, Max, ContainJustConstraints),
		constraint_unclear,
		throw(constraint_unclear('"contains just"'))
	),
	findall(Pattern, (length(Pattern, Length), member(Contain,  ContainConstraints ), contains(Pattern, Contain         )), BagContains),
	(BagContains = [] -> ContainConstraints = []; true),
	findall(Pattern, (length(Pattern, Length), member(ClubDoes, ClubDoesConstraints), clubDoes(Pattern, ClubDoes        )), BagClubDoes),
	(BagClubDoes = [] -> ClubDoesConstraints = []; true),
	findall(Pattern, (length(Pattern, Length), member(React,    ReactConstraints   ), react(Pattern, React              )), BagReact   ),
	(BagReact = [] -> ReactConstraints = []; true),
	findall(Pattern, (length(Pattern, Length), member(Sync,     SyncConstraints    ), sync_throws(Pattern, Sync, Persons)), BagSync    ),
	(BagSync = [] -> SyncConstraints = []; true),
	length(JustPattern, Length),
	(ContainJustConstraints = []; contains_just(JustPattern, ContainJustConstraints)),
	% !!!!!! ?????????????????
	append([MagicPattern, JustPattern], BagContains, BagTmp1),
	append(BagTmp1, BagClubDoes, BagTmp2),
	append(BagTmp2, BagReact, BagTmp3),
	append(BagTmp3, BagSync, BagOfConstraints),
	(BagOfConstraints = [] ->
			length(ConstraintRotated, Length);
			(
				mergeN(BagOfConstraints, Constraint),
				rotateHighestFirst(Constraint, ConstraintRotated)
			)
	).

cleanEqualConstraints(BagOfConstraints, CleanBagOfConstraints) :-
	cleanEqualConstraintsForward(BagOfConstraints, HalfCleanedBag),
	reverse(HalfCleanedBag, HalfCleanedBagInverted),
	cleanEqualConstraintsForward(HalfCleanedBagInverted, CleanBagOfConstraints).

cleanEqualConstraintsForward([], []) :- !.
cleanEqualConstraintsForward([SubConstraint|BagOfConstraints], CleanBagOfConstraints) :-
	member(Constraint, BagOfConstraints),
	isRotatedSubConstraint(SubConstraint, Constraint),!,
	cleanEqualConstraintsForward(BagOfConstraints, CleanBagOfConstraints).
cleanEqualConstraintsForward([Constraint|BagOfConstrains], [Constraint|CleanBagOfConstrains]) :-
	cleanEqualConstraintsForward(BagOfConstrains, CleanBagOfConstrains).
	
isRotatedSubConstraint(SubConstraint, Constraint) :-
	rotate(Constraint, ConstraintRotated),
	isSubConstraint(SubConstraint, ConstraintRotated),!.

isSubConstraint([], []) :- !.
isSubConstraint([SubThrow|SubConstraint], [Throw|Constraint]) :-
	nonvar(SubThrow), nonvar(Throw), !,
	SubThrow = Throw,
	isSubConstraint(SubConstraint, Constraint).
isSubConstraint([_SubThrow|SubConstraint], [Throw|Constraint]) :-
	var(Throw), !,
	isSubConstraint(SubConstraint, Constraint).


%% --- Constraints Passes ---

passesMin(Throws, PassesMin) :-
   number(PassesMin),
   amountOfPasses(Throws, Passes),
   PassesMin =< Passes.
passesMin(Throws, PassesMin) :- 
   var(PassesMin),
   passesMin(Throws, 0).          %if minimum of passes not specified require _one_ pass.

passesMax(Throws, PassesMax) :-
   number(PassesMax),
   amountOfPasses(Throws, Passes),
   Passes =< PassesMax.
passesMax(_Throws, PassesMax) :- 
   var(PassesMax).                %succeed if maximum of passes not specified

amountOfPasses([], 0).
amountOfPasses([FirstThrow|RestThrows], Passes) :-
   amountOfPasses(RestThrows, RestPasses),
   isPass(FirstThrow, ThisThrowIsPass),
   Passes is ThisThrowIsPass + RestPasses.

isPass(Var, 0) :- var(Var), !.
isPass(p(_,Index,_), 1) :- Index > 0, !.
isPass(p(_,Index,_), 0) :- Index = 0, !.
isPass(Multiplex, NumberOfPasses) :- 
	is_list(Multiplex),!,
	amountOfPasses(Multiplex, NumberOfPasses).


%%% --- Constraints Pattern ---

contains(Pattern, Segment) :-
   insertThrows(Pattern, Segment, next).


% Pattern doesn't contain Segment
dontcontain(_, []) :- fail,!.
dontcontain([PatternHead|_Pattern], _) :-
   var(PatternHead),!. % one is var
dontcontain(_, [SegmentHead|_Segment]) :-
   var(SegmentHead),!. % one is var
dontcontain([PatternMultiplex|_Pattern], [SegmentThrow|_Segment]) :-
	is_list(PatternMultiplex), 
	not(is_list(SegmentThrow)),!, % PatternHead is Multiplex the other not
	multiplexDoesntContain(PatternMultiplex, SegmentThrow).
dontcontain([PatternThrow|_Pattern], [SegmentMultipex|_Segment]) :-
	not(is_list(PatternThrow)), 
	is_list(SegmentMultipex),!. % SegHead is Multiplex the other not
dontcontain([PatternMultiplex|_Pattern], [SegmentMultiplex|_Segment]) :-
	is_list(PatternMultiplex),
	is_list(SegmentMultiplex),!,  % both Multiplex
	multiplexDoesntContain(PatternMultiplex, SegmentMultiplex).
dontcontain([PatternHead|_Pattern], [SegmentHead|_Segment]) :-
	not_this_throw(PatternHead, SegmentHead), !. % not same head
dontcontain([_PatternHead|Pattern], [_SegmentHead|Segment]) :-
	dontcontain(Pattern, Segment),!. % not same tail

multiplexDoesntContain([], _) :- !.
multiplexDoesntContain([Head|Multiplex], p(T,I,O)) :-
	not_this_throw(Head, p(T,I,O)),
	multiplexDoesntContain(Multiplex, p(T,I,O)),!.
multiplexDoesntContain(_, []) :- fail,!.
multiplexDoesntContain(Multiplex, [Head|Tail]) :-
	multiplexDoesntContain(Multiplex, Head);
	multiplexDoesntContain(Multiplex, Tail).
	


not_this_throw(p(_Throw, Index, _Origen), p(_SegThrow, SegIndex, _SegOrigen)) :-
	var(SegIndex),
	Index = 0,!.
not_this_throw(p(Throw, Index, Origen), p(SegThrow, SegIndex, SegOrigen)) :-
	nonvar(SegIndex),
	(
		Throw \= SegThrow;
		Index \= SegIndex;
		Origen \= SegOrigen
	),!.
not_this_throw(p(Throw, Index, Origen), p(SegThrow, SegIndex, SegOrigen)) :-
	var(SegIndex),
	(		
			Throw \= SegThrow;
			Origen \= SegOrigen;
			Index \= SegIndex
	),!.


dontContainRotation(Pattern, Segment) :-
	forall(rotate(Pattern, Rotation), dontcontain(Rotation, Segment)).

clubDoes(Pattern, Seg) :-
   insertThrows(Pattern, Seg, landingSite).

react(Pattern, Seg) :-
	insertThrows(Pattern, Seg, landingSite, [delta(-2)]).


insertThrows(Pattern, Seg, Pred) :-
	insertThrows(Pattern, Seg, Pred, 0, []).

insertThrows(Pattern, Seg, Pred, Options) :-
	insertThrows(Pattern, Seg, Pred, 0, Options).

insertThrows(_Pattern, [], _Pred, _Site, _Options) :- !.
insertThrows(Pattern, [Throw | Rest], Pred, Site, Options) :-
	length(Pattern, Period),
	(select(offset(Offset), Options, NextOptions) ->
		(
			OffsetSite is Site + Offset
		);
		(
			NextOptions = Options,
			OffsetSite = Site
		)
	),
	nth0(OffsetSite, Pattern, Throw),
	memberchk(Delta, Options, [name(delta), default(0)]),
	SitePlusDelta is OffsetSite + Delta,
	%Test ob Hoehe OK!?! (react: 1 2 nicht sinnvoll) !!!!!!!!!!!!!!!!!!!!!!!
	NewNextSiteOptions = [throw(Throw), site(SitePlusDelta), period(Period)],
	append(Options, NewNextSiteOptions, NextSiteOptions),
	insertThrows_nextSite(NextSiteList, NextSiteOptions, Pred),
	(is_list(NextSiteList) ->
	   member(NextSite, NextSiteList);
	   NextSite = NextSiteList
	),!,   % doesn't work with [_ _] 1p   not all are found!!!!!!!!!!!!!!!!!!!!!!!!!!!
	insertThrows(Pattern, Rest, Pred, NextSite, NextOptions).

insertThrows_nextSite(NextSite, Options, next) :-
	memberchk(site(Site), Options),
	memberchk(period(Period), Options),
	NextSite is (Site + 1) mod Period, !.
insertThrows_nextSite(NextSite, Options, landingSite) :-
	memberchk(site(Site), Options),
	memberchk(throw(Throw), Options),
	memberchk(period(Period), Options),
	landingSite(Site, Throw, Period, NextSite), !.



sync_throws(Pattern, Seg, NumberOfJugglers) :-
	length(Pattern, Length),
	0 is Length mod NumberOfJugglers,
	sync_throws_fill(Pattern, Seg, 0, NumberOfJugglers).

sync_throws_fill(_Pattern, _Seg, NumberOfJugglers, NumberOfJugglers) :- !.
sync_throws_fill(Pattern, Seg, Juggler, NumberOfJugglers) :-
	length(Pattern, Length),
	Offset is Juggler * (Length / NumberOfJugglers),
	insertThrows(Pattern, Seg, next, [offset(Offset)]),
	NextJuggler is Juggler + 1,
	sync_throws_fill(Pattern, Seg, NextJuggler, NumberOfJugglers).


contains_just([], _ListOfSegs) :- !.
contains_just(Pattern, ListOfSegs) :-
	member(Seg, ListOfSegs),
	append(Seg, RestPattern, Pattern),
	contains_just(RestPattern, ListOfSegs).



containsMagicOrbit(Pattern, NumberOfJugglers, MaxHeight) :-
	length(Pattern, Length),
	Prechator is Length rdiv NumberOfJugglers,
	MagicMaxHeight is min(MaxHeight, Prechator),
	possibleThrows(NumberOfJugglers, Length, MagicMaxHeight, [p(0,0,0)|PossibleThrows]),
	searchMagicThrows(PossibleThrows, MagicThrows, Prechator, Length, Length),
	clubDoes(Pattern, MagicThrows).
	
%% 1 = Clubs = SumThrows * Jugglers / Length ==> SumThrows = Prechator
%%
%% Orbit ==> SumOrig = N * Length
%% Orig = Throw + IndexDown * Prechator 
%% ==>
%% N = SumOrig / Length
%%   = Sum(Throw + IndexDown * Prechator) / Length
%%   = (Prechator + Sum(IndexDown * Prechator))/ Length
%%   = (Prechator + Prechator * Sum(IndexDown)) / Length
%%   = (1 + Sum(IndexDown)) / Jugglers
searchMagicThrows(_PossibleThrows, [], 0, 0, _) :- !.
searchMagicThrows(PossibleThrows, MagicThrows, Prechator, Length, OrigLength) :-
	Length =< 0,
	NextLength is OrigLength + Length,
	searchMagicThrows(PossibleThrows, MagicThrows, Prechator, NextLength, OrigLength).
searchMagicThrows(PossibleThrows, [MagicThrow|MagicThrows], Prechator, Length, OrigLength) :-
	member(MagicThrow, PossibleThrows),
	MagicThrow = p(Throw, _Index, Origen),
	Throw > 0,
	Throw =< Prechator,
	%Origen =< Length,
	PrechatorMinus is Prechator - Throw,
	LengthMinus is Length - Origen,
	searchMagicThrows(PossibleThrows, MagicThrows, PrechatorMinus, LengthMinus, OrigLength).
	
	
	
possibleThrows(NumberOfJugglers, Length, MaxHeight, PossibleThrows) :-
	findall(
		Throw,
		possibleThrow(NumberOfJugglers, Length, MaxHeight, Throw),
		PossibleThrows
	).
possibleThrow(_NumberOfJugglers, _Length, MaxHeight, p(Throw, 0, Throw)) :-
	MaxHeightI is truncate(MaxHeight),
	between(0, MaxHeightI, Throw).
possibleThrow(NumberOfJugglers, Length, MaxHeight, p(Throw, Index, Origen)) :-
	Prechator is Length rdiv NumberOfJugglers,
	IndexMax is NumberOfJugglers - 1,
	between(1, IndexMax, Index),
	MaxHeightSolo is truncate(MaxHeight + (NumberOfJugglers - Index) * Prechator),
	between(1, MaxHeightSolo, Origen),
    Throw is Origen - (NumberOfJugglers - Index) * Prechator,
	Throw >= 1,
	Throw =< MaxHeight.