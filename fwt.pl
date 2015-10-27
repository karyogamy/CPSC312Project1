%
% 1 - Definitions
%

:- [wordnet/wn_s].
:- [wordnet/wn_g].

definition(Q, G) :- s(ID, _, Q, _, _, _), g(ID, G).

%
% 2 - Morphs
%

:- [schlachter/pronto_morph_engine].

word_line_morphs :- write('|: '), read_line(W), morph_atoms_bag(W, P), print(P).

% read_line/1 mimics the readln/1 built-in command except for the '|: ' printed
% Loosely based on read_sentence/1 in 312-press-grammar
read_line(_) :- peek_char(Ch), char_type(Ch, end_of_file), !, fail.
read_line(L) :- read_line_helper(L).

% decide what to do next
% fail at EOF
read_line_helper(_L) :- peek_char(Ch), char_type(Ch, end_of_file), !, fail.

% No items are present at the end of line but it should still consume the character
read_line_helper([]) :- peek_char(Ch), char_type(Ch, end_of_line), !, get_char(_).

% Consume whitespace
read_line_helper(L)  :- peek_char(Ch), char_type(Ch, space), !, get_char(Ch), read_line_helper(L).

% read an item
read_line_helper([W|L]) :- read_next(C), atom_chars(W, C), read_line_helper(L).


% choose what is the next item to be read
read_next(X) :- peek_char(Ch), char_type(Ch, punct), !, read_punct(X).
read_next(X) :- read_word(X).

% read a single punctuation mark
read_punct([P]) :- peek_char(P), char_type(P, punct), !, get_char(P).

% read non-space, non-EOL, non-punct, and non-EOF characters into a list.
read_word([]) :- peek_char(Ch), char_type(Ch, space), !.
read_word([]) :- peek_char(Ch), char_type(Ch, end_of_line), !.
read_word([]) :- peek_char(Ch), char_type(Ch, punct), !.
read_word([]) :- peek_char(Ch), char_type(Ch, end_of_file), !.
read_word([H|T]) :- get_char(H), read_word(T).