%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Author: Steve Wolfman
%% Date: 2005/02/02
%% Collaborators: based partially on work by David Lowe
%% Sources: based partially on code from Amzi!, Inc. 
%%
%% Description:
%% 312 Prolog Expert System Shell, based on Amzi's "Native" shell.
%% For use with natural-language-based expert system knowledge bases.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Introduction                                                 %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% This file is broken into sections using banners like the
% "Introduction" banner that begins this section. The key sections are: 
% - Interpreter loop: defines the entry point main/0 that gives a
%   command prompt from which users can easily load files and solve
%   problems.  This is left for you to write!
% - Solving, asking, and proving: defines solve/0, which starts
%   the expert system solving whatever the current top goal is.
%   "ask" and "prove" are used to ask the user about the truth
%   of goals or reason about them, respectively. 
% - Flattening attributes: Mostly a helper section for the "prove"
%   predicate.  This defines flatten_attr/2, which takes a goal
%   (attribute) and turns it into a large (ideally exhaustive) set 
%   of implied goals.
% - Rule loading: load_rules/1 loads natural language rules from a 
%   knowledge base (file)


% Here are some helpful pieces of general code:

% Use a call like this to see your whole data structures printed:
% set_prolog_flag(toplevel_print_option, [max_depth(0)]).

% Ensure that \ will be seen as an operator (for difference lists).
:- op(900,xfx, \).

% Import the grammar.
:- consult('312-pess-grammar.pl').

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Interpreter loop                                             %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%% TODO!! %%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Solving, asking, and proving                                 %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% This section includes the solve, ask, and prove predicates which 
% together form the heart of the expert system shell.  solve initiates 
% an interaction with the shell (in which it tries to solve the user's 
% top goal), 'ask' asks the user whether a given assertion is true or
% false, and 'prove' recursively proves assertions (essentially using
% Prolog's own depth-first, backtracking search solution scheme).

% Although this section does NOT reason about natural language
% representations of rules, the ask predicate does use plain_gloss/2 to
% transform internal rule/goal representations into human-readable
% representations for printing.

% Rules and goals take the following form:
% - a rule is an instance of the rule/2 functor; its first argument is
%   the rule's head (a single instance of attr/3) while its second
%   argument is the rule's body (a list of instances of attr/3). Rules
%   "mean" the same thing that they do in normal Prolog statements,
%   e.g., a rule with a head meaning "it is sunny" and a body meaning
%   "the sky is cloudless and it is daytime" means "if the sky is
%   cloudless and it is daytime, then it is sunny". Similarly, rules
%   with empty bodies are facts.
% - a goal (including the body elements and head of rules) is an
%   instance of the attr/3 predicate. The first argument of attr is a
%   type, which must be an atom (and, for now, is one of is_a, has_a,
%   is_like, and is_how); the second argument of attr is the
%   attribute's value and may be any atom; and the third argument of
%   attr is a list of attached attributes, each of which is itself an
%   instance of attr/3.

% At a basic level, solving a goal (attr/3 instance) means finding rules
% that connect that goal to other goals until the goals bottom out
% (i.e., there is no rule whose head matches a goal). At this point,
% PESS's algorithm differs from Prolog's in that it asks the user
% whether the goal is true or false rather than concluding (by the
% closed world assumption) that the goal is definitely false.


%%%%%%%%%%%%%%%%%%% solve %%%%%%%%%%%%%%%%%%%%%%%%%%

% Solve clears out working memory (the known/1 predicate) and then
% attempts to prove a canonical "top goal".
% Currently, the top goal is set by hand at the same time the database is
% emptied (in clear_db).
% Answers are also of a fairly simple form and could be more complex,
% reflecting the structure of the knowledge base.
solve :-
        abolish(known,1), dynamic(known/1),
        prove([top_goal(X)], []),
        write('The answer is '),write(X),nl.
solve :-
        write('No answer found.'),nl.

%%%%%%%%%%%%%% prove and related %%%%%%%%%%%%%%%%%%


% prove/2 notes that an empty resolvent ("todo list") is true
% and otherwise passes all the work to prove_one, which proves
% each goal one at a time.
prove([], _).
prove([Goal|Rest], Hist) :- prove_one(Goal, [Goal|Hist]),
                            prove(Rest, Hist).


% prove_one(X) is true if X is known directly, implied by the DB, or 
% supplied by the user.  To avoid pestering the user, prove_one(X) fails
% if X is already known to be false (or the database implies that it is
% false).
prove_one(true, _) :- !.                   % Facts give a body of 'true'.
prove_one(X, _) :- known(X), !.            % Note: would be found w/implied.
prove_one(X, _) :- known(not(X)), !, fail. % Note: would be found w/implied.
prove_one(X, _) :- implied(X), !.          % Known or implied: proven
prove_one(X, _) :- implied(not(X)), 
        !, fail.                           % Known/implied NOT: disproven
prove_one(X, Hist) :-                      % Where the action is.  There's
        rule(X, Body),                     % some goal that can prove 
        prove(Body, Hist).                 % this; so, give it a shot.
prove_one(X, Hist) :- \+ rule(X, _),       % If there's no goal to prove 
                      ask(X, Hist), !,     % this, ask the user and
                      known(X).            % trust the answer.

% Note: a really clever version of prove would recognize that
% portions of the query to be proven may already be known.  For example,
% we may want to ask whether it has long, sharp claws, but we may
% already know that its claws are sharp. In that case, we could get away
% with just asking whether it has long claws. The current version does
% NOT do this.

% implied(X) is true if X is known directly or implied by the database.
% Note: implied assumes that "not", if it appears, appears only as the 
% outermost predicate of its argument.
implied(not(X)) :- !, flatten_attr(X, Y), prove_not_some(Y).
implied(X)      :-    flatten_attr(X, Y), prove_all(Y).

% Note that, as facts are added to the database, they are also
% flattened, and their flattened forms added to the dabatase. Therefore,
% all the data necessary for implied to work should by available.

% prove_all(Asserts) is true if every element of Asserts is known to be true
prove_all([]).
prove_all([Assert|Asserts]) :- known(Assert), prove_all(Asserts).

% prove_not_some(Asserts) is true if any element of Asserts is known to 
% be false.  The cut is for efficiency (and to avoid redundant solns).
prove_not_some([Assert|_]) :- known(not(Assert)), !.
prove_not_some([_|Asserts]) :- prove_not_some(Asserts).



%%%%%%%%%%%%%%% ask and related %%%%%%%%%%%%%%%%%%%

% Ask the user whether the fact X is true.
% Uses Hist to tell the user (or, more likely, the developer) how 
% the system got to its current state.
ask(X, Hist) :- plain_gloss([X], Y), !,       % Accept only the first gloss.
                write('Would you say that '), % Prompt for..
                write_sentence(Y),            % the glossed knowledge
                write('?'),
                get_user(Answer,Hist),        % Get the user's answer
                update(Answer, X).            % Update the knowledge base to
                                              % reflect the user's answer

% Update the knowledge base to reflect a user's assertion.
update(yes, X) :- !,          
      asserta(known(X)),      % Add X and all its implied knowledge
      flatten_attr(X, Y),     % to the knowledge database. 
      assert_all(Y).          % (Note: tough to get this back out. Could
                              % use a unique ID for later reference.)
update(_, X)   :-         
      retract(known(X)),      % Pull out known(X).
      !, fail.                % Then, fail to backtrack to next rule.
                              % Note: does NOT retract everything based on X.
                              % and probably should not, either 
                              % (De Morgan's!)
update(_, X)   :- 
      asserta(known(not(X))). % Put in known(not(X)).  As above,
                              % does not put in everything flattened
                              % out of not(X) b/c these facts are not 
                              % necessarily true (not implied!)

% Assert a list of knowledge using the known/1 predicate.
assert_all([]).                     
assert_all([Assert|Asserts]) :-     
          asserta(known(Assert)),   
          assert_all(Asserts).      

% Get the user's response to a question, handling "why" questions.
get_user(X,Hist) :-
        repeat,                  
        write('> '),             % Ask for the user's answer
        read(Y),
        process_ans(Y,Hist,X),   % Either read answer or field question
                                 % (in which case, backtrack to repeat).
        !.                       % Finish with user's single answer.

% Handle yes, no, and why.
% It might be better if "why" used glosses rather than raw data.
process_ans(why,Hist,_) :-
        write_list(4,Hist), !, fail.  % Show history & fail
                                      % (to get new answer)
process_ans(y,_,yes) :- !.            % Successful answers
process_ans(yes,_,yes) :- !.          % Successful answers
process_ans(X,_,X).                   % Unsuccessful answers

% Write out a list of goals, tabbed.
write_list(_,[]).
write_list(N,[H|T]) :-
        tab(N),plain_gloss([H], Text), write_sentence(Text),nl,
        write_list(N,T).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Compound attribute flattening.                      %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Attribute structures (as described above) can be quite complex.
% Furthermore, certain attributes imply other attributes. For example,
% if it has long, sharp claws, then it surely has long claws, and has
% sharp claws, and has claws.

% flatten_attr calculates the list of smaller attributes 
% corresponding to one larger attribute (all those attributes
% that are NOT conjunctive that are implied by the original
% attribute; that is, for each attr(Type, Value, SubAttributes) 
% in the flattened attribute list, SubAttributes is either empty or
% has one element.)
% This is useful for a few reasons:
% - each of these "flattened" attributes is implied by the original
% - conversely, if any of these flattened attributes is false, the
%   original is also false
% - finally, if all of these flattened attributes can be proven, 
%   so too can the original.
% In fact, that last requirement is too strong in a sense. Only the
% "deepest" attributes need to be proven; the shallower ones are implied
% as they are flattened versions of the deeper ones. On the other hand,
% the last requirement is also too weak. The following example
% illustrates..
%
% For example, it slowly eats small insects and worms.
% The flattened version includes:
% - it eats
% - it slowly eats
% - it eats insects
% - it eats small insects
% - it eats worms
% Each of these is clearly implied by the overall statement.
% Furthermore, if any of them are false, the overall statement is false.
% However, as long as we have "it eats small insects", we clearly don't
% need "it eats insects" to prove the overall statement.  Unfortunately,
% the handling of adverbs is not quite right.  "it slowly eats" and
% "it eats insects" does NOT imply that "it slowly eats insects".
%
% Some notes about fixing the flattened true -> original true assertion:
% - There's really no need to fix the fact that the statement is too 
%   strong.  As long as the flattened attributes are proven IN REVERSE
%   ORDER, each implied attribute will already have been proven (and
%   so be in the knowledge base) by the time the proof process reaches
%   it.
% - To fix the fact that the statement is too weak, I would NOT change
%   flatten_attr.  Instead, I would change the way the parser represents
%   rules and goals.  For example, "it slowly eats insects" might become
%   something like:
%     attr(does, eats, [attr(is_how, slowly, [attr(is_a, insects, [])])]) 
%   rather than:
%     attr(does, eats, [attr(is_how, slowly,  []),
%                       attr(is_a,   insects, []) ])
%   so that it's clearly that "insects" is dependent on "slowly eats",
%   not just on "eats".  That would require changes both to the parser
%   and to the glosser.
flatten_attr(X, Y) :- flatten_attr_dl(X, Y\[]).

% flatten_attr_dl does flatten_attr's job, but using difference lists
% for efficiency.
% The algorithm is:
% - for a list of attributes, flatten each element into its own list
%   and join the sublists together.
% - for an attribute attr(Type, Value, SubAttributes),
%   include the bare attribute (i.e., attr(Type, Value, [])) plus
%   the attribute with paired with each flattened sub attribute
%   (i.e., attr(Type, Value, FlattenedSubAttrsListElt)) 
flatten_attr_dl([], Soln\Soln) :- !.         % Empty list produces nothing.

flatten_attr_dl([X|Xs], Soln\Rest) :- !,     % A list gets 
        flatten_attr_dl(X, Soln\Mid),        % flattened inside and
        flatten_attr_dl(Xs, Mid\Rest).       % joined together.

flatten_attr_dl(attr(Type, Value, Subs), 
                [attr(Type, Value, [])|RestSoln]\Rest) :- !, 
        flatten_attr(Subs, FlatSubs),  % Note the base attribute was added. 
        prepend_attr(attr(Type, Value, []), 
                     FlatSubs,         % Flatten the sub attributes, and
                     RestSoln\Rest).   % prepend the base attribute to each.

flatten_attr_dl(X, [X|Rest]\Rest).   % Base case and catchall for
                                     % non-attributes.  Anything else is
                                     % the list of itself.

% prepend_attr transforms the input list into a list of attributes.
% prepend_attr(attr(Type, Val, _), SubAttrs, Attrs\Attrr) is true 
% if Attrss\Attrr is SubAttrs except each element SubAttr of SubAttrs
% corresponds to attr(Type, Val, [SubAttr]) in Attrs\Attrr.
prepend_attr(_, [], Soln\Soln).
prepend_attr(attr(Type, Val, _), 
             [Sub|Subs], 
             [attr(Type, Val, [Sub])|RestSoln]\Rest) :-
        prepend_attr(attr(Type, Val, _), Subs, RestSoln\Rest).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Rule loading (based on Amzi's Clam shell)           %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Load rules from the given file (clearing the rule DB first).
load_rules(F) :-
        clear_db,
        see(F),
        load_rules,
        write('rules loaded'),nl,
        seen, !.

% Load rules from default input.
load_rules :-
        read_sentence(L),   % Read a rule.
%       bug(L),
        process(L),         % Insert the rule into the DB.
        load_rules.         % Tail recursive loop.
load_rules :- !.            % Cut avoids backtracking (and re-processing!)

% Process rules (usually means putting them in the database).
% If I were going to add new types of statements in knowledge base
% files, I might do it by writing extra process clauses below.
process([]) :- !.           % Ignore empty rules.
process(['rule:'|L]) :-     % Found a rule.
        rule(R,L,[]),       % Parse the rule.
        bug(R),             % Print it for debugging.
        assert_rules(R), !. % Assert it (them, potentially) in the DB.
process(L) :-
        write('trans error on:'),nl,
        write(L),nl.

% Assert a list of rules.
assert_rules([]).
assert_rules([R|Rs]) :- assertz(R), assert_rules(Rs).

% Delete the contents of the database (the rules, not the knowledge).
% Also establishes the default top goal (to find out what "it" is).
clear_db :-
        abolish(rule,2),
        dynamic(rule/2),
        %% For now, top_goal is set manually.
        assertz(rule(top_goal(X), [attr(is_a, X, [])])).

% Gloss a rule for debugging output.
bug(X) :- write('Understood: '), 
        plain_gloss(X, Text), 
        write_sentence(Text), nl.
bug(X) :- write(X).

%% NOTE: to improve modularity, read_sentence/1 is defined in
%% 312pess-grammar.pl (which allows that file to run independently of
%% 312pess.pl).





