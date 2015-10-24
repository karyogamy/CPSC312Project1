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

word_line_morphs :- readln(W), morph_atoms_bag(W, P), print(P).
